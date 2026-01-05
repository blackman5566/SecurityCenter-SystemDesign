//
//  AppUnlockView.swift
//  SwiftUI_Wallet
//
//  Created by 許佳豪 on 2025/12/30.
//

import SwiftUI

/// AppUnlockView（App 層級解鎖頁的最薄一層 View）
///
/// 角色定位：
/// - 只負責「建立 AppUnlockViewModel」並交給共用的 UnlockView 呈現
/// - 不在這裡放任何商業邏輯，避免 View 變胖
///
/// 設計理由：
/// - `UnlockView` 是共用 UI（輸入 passcode、顯示錯誤、biometry 按鈕、shake 動畫等）
/// - `AppUnlockViewModel` 封裝 App 解鎖的規則（密碼/biometry 成功後如何解鎖 App）
/// - AppUnlockView 只是把兩者接起來，讓結構清楚（入口乾淨、可重用）
struct AppUnlockView: View {

    /// App 解鎖的 ViewModel
    /// - 使用 `@StateObject`：確保 View 重繪時不會重建 ViewModel
    /// - `biometryAllowed: true`：App 解鎖情境允許 FaceID/TouchID
    @StateObject private var viewModel = AppUnlockViewModel(biometryAllowed: true)

    var body: some View {
        /// 使用共用的 UnlockView 呈現解鎖 UI
        UnlockView(viewModel: viewModel)
    }
}
