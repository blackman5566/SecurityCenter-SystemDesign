//
//  SetPasscodeViewModel.swift
//  SwiftUI_Wallet
//
//  Created by 許佳豪 on 2025/12/26.
//

import Combine
import UIKit

/// SetPasscodeViewModel（設定 Passcode 流程的共用 ViewModel）
///
/// 角色定位：
/// - 提供「輸入新密碼 → 再輸入一次確認」的共用流程（兩段式）
/// - 管理 UI 狀態：description / errorText / passcode / shakeTrigger
/// - 子類只需要覆寫：
///   - 文案（title / passcodeDescription / confirmDescription）
///   - 規則（isCurrent）
///   - 成功後要做什麼（onEnter）
///   - 取消時要做什麼（onCancel）
///
/// 這是一個典型的 Template Method Pattern：
/// - 基底類處理流程狀態機
/// - 子類提供差異化文案與行為
class SetPasscodeViewModel: ObservableObject {

    /// Passcode 長度（UI 通常會畫 6 顆點）
    let passcodeLength = 6

    /// 目前提示文字（會在「輸入新密碼」與「確認密碼」之間切換）
    @Published var description: String = ""

    /// 錯誤提示（密碼重複、確認不一致等）
    @Published var errorText: String = ""

    /// 使用者目前輸入的 passcode（例如鍵盤累積的字串）
    ///
    /// 行為：
    /// - 當輸入長度達到 passcodeLength → 延遲 200ms 驗證（讓 UI 有時間顯示最後一顆點）
    /// - 當使用者開始重新輸入（passcode.count != 0）→ 清掉 errorText（避免錯誤訊息一直留著）
    @Published var passcode: String = "" {
        didSet {
            //檢查密碼邏輯
            let passcode = passcode
            if passcode.count == passcodeLength {
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) { [weak self] in
                    self?.handleEntered(passcode: passcode)
                }
            } else if passcode.count != 0 {
                /// 使用者正在重新輸入時先把錯誤清掉，讓介面乾淨
                errorText = ""
            }
        }
    }

    /// 觸發 UI 抖動動畫用的 trigger（每次錯誤 +1）
    @Published var shakeTrigger: Int = 0

    /// Passcode 管理器（用於檢查是否重複、寫入等）
    /// - 由 Module 層注入，SetPasscodeViewModel 不自己去碰 AppCore.shared
    let passcodeManager: PasscodeManager

    /// 流程完成事件（通知 View 關閉頁面 / dismiss）
    var finishSubject = PassthroughSubject<Void, Never>()

    /// 第一段輸入的新密碼暫存
    /// - nil：目前在「輸入新密碼」階段
    /// - non-nil：目前在「確認密碼」階段
    private var enteredPasscode: String?

    init(passcodeManager: PasscodeManager) {
        self.passcodeManager = passcodeManager

        /// 初始化時根據目前階段同步提示文字
        syncDescription()
    }

    // MARK: - Hooks (override points)

    /// 子類提供：頁面標題
    var title: String { "" }

    /// 子類提供：第一段輸入時的描述文字（例如：請輸入新密碼）
    var passcodeDescription: String { "" }

    /// 子類提供：第二段確認時的描述文字（例如：請再次輸入確認）
    var confirmDescription: String { "" }

    /// 子類覆寫：判斷某 passcode 是否為「目前正在使用的 passcode」
    /// - 用來允許「編輯 passcode」時可輸入同一組（或避免被判定為重複）
    func isCurrent(passcode _: String) -> Bool { false }

    /// 子類覆寫：當新密碼確認成功後要做什麼（寫入 keychain、送 finishSubject 等）
    func onEnter(passcode _: String) {}

    /// 子類覆寫：使用者取消流程要做什麼（可能要還原狀態/呼叫 callback）
    func onCancel() {}

    // MARK: - Flow

    /// 核心流程狀態機：處理使用者「輸入滿 6 位」後的行為
    ///
    /// 狀態（由 enteredPasscode 是否為 nil 決定）：
    /// - enteredPasscode == nil：第一段「輸入新密碼」
    /// - enteredPasscode != nil：第二段「確認密碼」
    private func handleEntered(passcode: String) {

        // 目前在「確認密碼」階段
        if let enteredPasscode {

            /// 第二次輸入要與第一次一致才算成功
            if enteredPasscode == passcode {
                /// 子類決定成功後要做什麼（例如：passcodeManager.set + finishSubject.send）
                onEnter(passcode: passcode)
            } else {
                /// 確認不一致：
                /// - 清掉第一次輸入
                /// - 清空目前輸入
                /// - 回到第一段狀態並更新提示文字
                self.enteredPasscode = nil
                self.passcode = ""
                syncDescription()
                errorText = "Invalid confirmation"
            }

        // 目前在「輸入新密碼」階段
        } else if passcodeManager.has(passcode: passcode), !isCurrent(passcode: passcode) {

            /// 第一段輸入時，若 passcode 已存在於任何層級，且不是目前密碼（例如編輯情境）
            /// -> 拒絕使用（避免重複使用同一組密碼）
            self.passcode = ""
            errorText = "This passcode is already being used"

            /// 提供 UI 回饋（抖動 + 震動）
            shakeTrigger += 1
            UINotificationFeedbackGenerator().notificationOccurred(.error)

        } else {
            /// 第一段輸入合法：
            /// - 暫存第一次輸入
            /// - 清空輸入框，進入第二段「確認密碼」
            enteredPasscode = passcode
            self.passcode = ""
            syncDescription()
        }
    }

    /// 同步 description（提示文字）：
    /// - 尚未輸入第一次：顯示 passcodeDescription
    /// - 已輸入第一次：顯示 confirmDescription
    private func syncDescription() {
        description = (enteredPasscode == nil) ? passcodeDescription : confirmDescription
    }
}
