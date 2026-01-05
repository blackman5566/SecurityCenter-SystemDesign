//
//  BaseUnlockViewModel.swift
//  SwiftUI_Wallet
//
//  Created by 許佳豪 on 2025/12/26.
//

import Combine
import HsExtensions
import LocalAuthentication
import UIKit

/// BaseUnlockViewModel（解鎖流程的共用基底 ViewModel）
///
/// 角色定位：
/// - 共用「輸入 passcode → 驗證 → 成功/失敗」的流程
/// - 整合：
///   - Lockout（嘗試次數 / 鎖定狀態）
///   - Biometry（FaceID/TouchID 顯示與自動觸發）
/// - 讓子類只要提供「驗證規則」與「解鎖成功後的行為」
///
/// 典型使用：
/// - AppUnlockViewModel / ModuleUnlockViewModel…
///   只覆寫 `isValid`、`onEnterValid`、`onBiometryUnlock`
class BaseUnlockViewModel: ObservableObject {

    /// Passcode 長度（例如 6 位）
    /// - UI 會用它來畫圓點 / 限制輸入
    let passcodeLength = 6

    /// 主提示文字（例如：請輸入密碼）
    @Published var description: String = "Enter Passcode"

    /// 錯誤提示文字（例如：剩餘嘗試次數）
    @Published var errorText: String = ""

    /// 使用者目前輸入的 passcode（由 NumPadView 累積）
    ///
    /// didSet 行為：
    /// - 當輸入達到 passcodeLength
    ///   延遲 200ms 觸發驗證（讓 UI 先顯示最後一顆點，體感更順）
    @Published var passcode: String = "" {
        didSet {
            let passcode = passcode

            if passcode.count == passcodeLength {
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(200)) { [weak self] in
                    self?.handleEntered(passcode: passcode)
                }
            }
        }
    }

    /// 最終「要顯示給 UI 的」生物辨識型別
    /// - nil：不顯示 FaceID/TouchID 按鈕
    /// - 非 nil：顯示對應按鈕
    @Published var resolvedBiometryType: BiometryType?

    /// 裝置支援的生物辨識型別（FaceID / TouchID / none）
    /// - raw 狀態，是否顯示要看 resolvedBiometryType
    var biometryType: BiometryType?

    /// 使用者設定的生物辨識開關狀態（off / on / auto …）
    /// - isEnabled: 是否開啟
    /// - isAuto: 是否允許 onAppear 自動觸發
    var biometryEnabledType: BiometryManager.BiometryEnabledType

    /// Lockout 狀態（未鎖定 / 鎖定到某時間 / 嘗試中...）
    ///
    /// didSet：
    /// - lockoutState 變動時同步 errorText（例如顯示剩餘次數）
    @Published var lockoutState: LockoutState {
        didSet { syncErrorText() }
    }

    /// UI 抖動觸發器（輸錯時 +1）
    @Published var shakeTrigger: Int = 0

    /// 解鎖完成事件（View / Coordinator 可 subscribe 後 dismiss / pop）
    let finishSubject = PassthroughSubject<Void, Never>()

    /// 請求「用生物辨識解鎖」的事件
    /// - BaseUnlockViewModel 只決定何時觸發
    /// - 真正呼叫 LAContext.evaluatePolicy 可能在 View 或 Coordinator 層
    let unlockWithBiometrySubject = PassthroughSubject<Void, Never>()

    // MARK: - Dependencies（目前從 AppCore.shared 取得，可再往上抽 DI）

    /// Passcode 管理器（驗證/切換/設定 passcode）
    let passcodeManager = AppCore.shared.security.passcodeManager

    /// 生物辨識管理器（取得 biometryType、是否啟用）
    private let biometryManager = AppCore.shared.security.biometryManager

    /// Lockout 管理器（錯誤次數、鎖定策略）
    private let lockoutManager = AppCore.shared.security.lockoutManager

    /// 此畫面情境是否允許 biometry（外部決定）
    private let biometryAllowed: Bool

    /// Combine 訂閱集合（避免 sink 被釋放）
    private var cancellables = Set<AnyCancellable>()

    /// 專案自訂的 task 集合（如果有 async 工作可放這裡管理）
    private var tasks = Set<AnyTask>()

    // MARK: - Init

    init(biometryAllowed: Bool) {
        self.biometryAllowed = biometryAllowed

        /// 初始化：讀取當前安全系統狀態，避免畫面一開始空值
        biometryType = biometryManager.biometryType
        biometryEnabledType = biometryManager.biometryEnabledType
        lockoutState = lockoutManager.lockoutState

        /// 監聽：biometryType 變動（例如系統權限/裝置狀態改變）
        biometryManager.$biometryType
            .sink { [weak self] in
                self?.biometryType = $0
                self?.syncBiometryType()
            }
            .store(in: &cancellables)

        /// 監聽：使用者切換生物辨識開關（on/off/auto）
        biometryManager.$biometryEnabledType
            .sink { [weak self] in
                self?.biometryEnabledType = $0
                self?.syncBiometryType()
            }
            .store(in: &cancellables)

        /// 監聽：lockoutState 變動（例如輸錯次數改變、進入鎖定）
        lockoutManager.$lockoutState
            .sink { [weak self] in
                self?.lockoutState = $0
                self?.syncBiometryType()
            }
            .store(in: &cancellables)

        /// 初始化同步 UI 狀態
        syncErrorText()
        syncBiometryType()
    }

    // MARK: - State Sync

    /// 根據目前條件決定 UI 是否顯示 biometry 按鈕
    ///
    /// 顯示條件（全部都要成立）：
    /// - 使用者有啟用 biometry（biometryEnabledType.isEnabled）
    /// - 此情境允許 biometry（biometryAllowed）
    /// - 目前不是 lockout 嘗試限制狀態（!lockoutState.isAttempted）
    ///
    /// 只要任一條件不成立 → resolvedBiometryType = nil（UI 不顯示）
    private func syncBiometryType() {
        resolvedBiometryType =
            biometryEnabledType.isEnabled
            && biometryAllowed
            && !lockoutState.isAttempted
            ? biometryType
            : nil
    }

    // MARK: - Hooks（子類覆寫）

    /// 子類覆寫：passcode 是否正確
    func isValid(passcode _: String) -> Bool { false }

    /// 子類覆寫：passcode 正確後要做什麼（例如：解鎖 App、finishSubject.send）
    func onEnterValid(passcode _: String) {}

    /// 子類覆寫：生物辨識成功後要做什麼（例如：解鎖 App、切到最後一層 passcode）
    func onBiometryUnlock() {}

    // MARK: - Internal flow

    /// 當使用者輸入滿 passcodeLength 位後呼叫
    private func handleEntered(passcode: String) {
        if isValid(passcode: passcode) {
            /// 驗證成功：交給子類處理成功行為
            onEnterValid(passcode: passcode)

            /// 告知 lockout：成功解鎖（通常會 reset attempts）
            lockoutManager.didUnlock()
        } else {
            /// 驗證失敗：清空輸入並累積失敗次數
            self.passcode = ""
            lockoutManager.didFailUnlock()

            /// UI 回饋：抖動 + 震動
            shakeTrigger += 1
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }

    /// 依 lockoutState 同步 errorText（顯示剩餘次數等）
    private func syncErrorText() {
        switch lockoutState {
        case let .unlocked(attemptsLeft, maxAttempts):
            /// 若 attemptsLeft 還是滿的（尚未輸錯）就不顯示提示
            errorText = attemptsLeft == maxAttempts
                ? ""
                : "Attempts left: \(attemptsLeft)"

        default:
            /// 其他狀態目前不顯示文案
            /// - 若你想顯示鎖定倒數/原因，可在這裡擴充
            errorText = ""
        }
    }

    // MARK: - Lifecycle

    /// View 的 onAppear 會呼叫
    ///
    /// 若：
    /// - biometry 按鈕可顯示（resolvedBiometryType != nil）
    /// - 使用者設定為 auto（biometryEnabledType.isAuto）
    ///
    /// 則主動發送 unlockWithBiometrySubject
    /// - 由 View/Coordinator 觸發真正的 FaceID/TouchID 驗證流程
    func onAppear() {
        //如果是自動觸發,就乎叫 FaceID/TouchID 驗證流程
        if resolvedBiometryType != nil, biometryEnabledType.isAuto {
            unlockWithBiometrySubject.send()
        }
    }
}
