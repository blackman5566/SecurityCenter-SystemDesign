//
//  SetPasscodeView.swift
//  SwiftUI_Wallet
//
//  Created by 許佳豪 on 2025/12/26.
//

import SwiftUI

/// SetPasscodeView（設定 / 編輯 Passcode 的共用畫面）
///
/// 角色定位：
/// - 提供「輸入 passcode」的共用 UI（數字鍵盤、圓點、錯誤提示、shake 動畫）
/// - 不關心 passcode 要拿來做什麼（建立 / 編輯 / duress）
/// - 行為與流程完全交由 `SetPasscodeViewModel`（或其子類）決定
///
/// 資料流概念：
/// - View ⇄ ViewModel：
///   - Passcode 輸入、錯誤、描述文字、完成事件
/// - View → 上層 Sheet：
///   - 透過 `showParentSheet` 控制整個流程是否結束（dismiss）
///
/// 為什麼用 `SetPasscodeView`：
/// - Create / Edit / Duress 都可以共用這個 View
/// - 只要換 ViewModel，就能換行為與文案
struct SetPasscodeView: View {

    /// 控制整個設定流程的 ViewModel
    /// - 使用 ObservedObject：由外部（Module）建立並持有
    @ObservedObject var viewModel: SetPasscodeViewModel

    /// 控制「上層 sheet 是否顯示」
    /// - 設定完成或取消時，會被設為 false 來關閉整個流程
    @Binding var showParentSheet: Bool

    var body: some View {
        /// 共用的 Passcode 輸入畫面
        /// - SetPasscodeView 本身不處理任何解鎖/驗證邏輯
        /// - 所有狀態都由 ViewModel 提供與接收
        PasscodeView(
            maxDigits: viewModel.passcodeLength,

            /// 主提示文字（例如：請輸入新密碼 / 再次確認密碼）
            description: $viewModel.description,

            /// 錯誤提示（例如：密碼不一致）
            errorText: $viewModel.errorText,

            /// 使用者目前輸入的 passcode
            passcode: $viewModel.passcode,

            /// 本流程不支援生物辨識（建立/編輯 passcode 時）
            /// - 因此傳入一個固定為 nil 的 Binding
            biometryType: Binding(
                get: { nil },
                set: { _ in }
            ),

            /// 本流程不使用 lockout 機制
            /// - PasscodeView 需要 lockoutState，但這裡只給一個「永遠解鎖」的假值
            lockoutState: Binding(
                get: { .unlocked(attemptsLeft: Int.max, maxAttempts: Int.max) },
                set: { _ in }
            ),

            /// 用來觸發錯誤時的 shake 動畫
            shakeTrigger: $viewModel.shakeTrigger,

            /// 是否啟用亂數鍵盤（這裡關閉）
            randomEnabled: false
        )
        .navigationTitle(viewModel.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {

            /// 取消按鈕
            /// - 呼叫 ViewModel 的 onCancel（讓 VM 處理業務邏輯）
            /// - 同時關閉上層 sheet
            Button("Cancel") {
                viewModel.onCancel()
                showParentSheet = false
            }
        }

        /// 監聽設定流程完成事件
        /// - 當 ViewModel 發送 finishSubject 時，關閉上層 sheet
        .onReceive(viewModel.finishSubject) {
            showParentSheet = false
        }
    }
}
