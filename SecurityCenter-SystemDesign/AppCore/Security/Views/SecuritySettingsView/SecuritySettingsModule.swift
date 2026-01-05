//
//  SecuritySettingsModule.swift
//  SwiftUI_Wallet
//
//  Created by 許佳豪 on 2025/12/26.
//

import SwiftUI

/// SecuritySettingsModule（安全設定頁的組裝入口 / Composition Root）
///
/// 角色定位：
/// - 統一建立「安全設定頁」所需的 ViewModel 與依賴
/// - 將依賴注入集中在這一層，讓 View / ViewModel 不需要知道 AppCore.shared 的細節
///
/// 好處：
/// - **單一入口**：外部只要呼叫 `SecuritySettingsModule.view()`
/// - **邊界清楚**：
///   - View：只顯示 UI
///   - ViewModel：只處理安全設定的行為邏輯
///   - Module：負責把依賴組裝起來（DI / wiring）
/// - **可維護/可測試**：未來要換實作（mock、不同 storage、不同 security policy）
///   只需要改這個組裝層，不用動 UI 與 VM
enum SecuritySettingsModule {

    /// 建立安全設定頁面（已完成依賴注入）
    ///
    /// - Returns: SecuritySettingsView（內含已配置好的 SecuritySettingsViewModel）
    static func view() -> some View {

        /// 在 module 層完成依賴注入：
        /// - passcodeManager：管理主/duress passcode（設定/移除/驗證）
        /// - biometryManager：FaceID/TouchID 開關與型別管理
        /// - lockManager：App 鎖定/解鎖狀態控制（例如切到背景、自動鎖定等）
        let viewModel = SecuritySettingsViewModel(
            passcodeManager: AppCore.shared.security.passcodeManager,
            biometryManager: AppCore.shared.security.biometryManager,
            lockManager: AppCore.shared.security.lockManager
        )

        /// 回傳真正的 UI（View 不用關心依賴怎麼來）
        return SecuritySettingsView(viewModel: viewModel)
    }
}
