//
//  EditPasscodeModule.swift
//  SwiftUI_Wallet
//
//  Created by 許佳豪 on 2025/12/26.
//

import SwiftUI

/// EditPasscodeModule（組裝入口 / 統一工廠）
///
/// 目的：
/// - 提供「編輯 Passcode 相關畫面」的單一建立入口（Single Entry Point）
/// - 把依賴注入（Dependency Injection）集中在這一層做完
/// - 讓 View / ViewModel 不需要知道 AppCore / Shared Singleton 等全域細節
///
/// 為什麼需要 Module：
/// - **清楚責任邊界**：
///   - View：只管 UI
///   - ViewModel：只管行為/流程
///   - Module：只管「怎麼把依賴組起來」
///
/// - **可維護性**：
///   - 當依賴變動（passcodeManager 換實作、加 service、加 analytics）
///     只需要改這裡，不用改 UI 與 VM
///
/// - **可測試性/可替換性**：
///   - 未來可以在這裡注入 mock / stub（例如 Preview、Unit Test）
enum EditPasscodeModule {

    /// 建立「編輯主 Passcode」的畫面
    ///
    /// - Parameter showParentSheet:
    ///   用來控制上層 sheet 是否關閉的 Binding
    ///   （常見情境：此頁是解鎖後才出現，完成後要順便關掉上層 sheet）
    ///
    /// - Returns: 組裝完成的 View（已帶入 ViewModel 與依賴）
    static func editPasscodeView(showParentSheet: Binding<Bool>) -> some View {

        /// 在 Module 內完成依賴注入：
        /// - EditPasscodeViewModel 需要 passcodeManager
        /// - passcodeManager 的來源由 AppCore 統一管理
        /// - ViewModel 不需要知道「AppCore.shared.security...」這種全域路徑
        let viewModel = EditPasscodeViewModel(
            passcodeManager: AppCore.shared.security.passcodeManager
        )

        /// 回傳真正的 UI
        /// - SetPasscodeView 是共用 UI（可搭配不同 ViewModel 來做：新增/編輯/duress...）
        return SetPasscodeView(
            viewModel: viewModel,
            showParentSheet: showParentSheet
        )
    }

    // MARK: - (Optional) Duress Passcode
    //
    // 如果未來要支援「編輯 Duress Passcode」
    // 可以用同樣的組裝方式：
    // - 建一個 EditDuressPasscodeViewModel
    // - 仍共用 SetPasscodeView
    // - 依賴注入仍集中在 Module
    //
    // static func editDuressPasscodeView(showParentSheet: Binding<Bool>) -> some View {
    //     let viewModel = EditDuressPasscodeViewModel(passcodeManager: AppCore.shared.security.passcodeManager)
    //     return SetPasscodeView(viewModel: viewModel, showParentSheet: showParentSheet)
    // }
}
