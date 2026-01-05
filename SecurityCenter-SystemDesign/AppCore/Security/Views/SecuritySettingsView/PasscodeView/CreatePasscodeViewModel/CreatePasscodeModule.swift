//
//  CreatePasscodeModule.swift
//  SwiftUI_Wallet
//
//  Created by 許佳豪 on 2025/12/26.
//

import SwiftUI

/// CreatePasscodeModule（建立 Passcode 的組裝入口 / 統一工廠）
///
/// 角色定位：
/// - 封裝「建立主 passcode」的畫面組裝：
///   - 建立 CreatePasscodeViewModel（注入依賴與 callback）
///   - 回傳共用的 SetPasscodeView
/// - 對外提供乾淨 API，呼叫端不用知道 ViewModel 需要哪些依賴
///
/// 你說的「統一入口、清楚地依賴帶進去」就是這一層在做的事情：
/// - View / ViewModel 不需要碰 AppCore.shared 的路徑
/// - 依賴從 Module 集中注入，未來要替換/測試會更容易
enum CreatePasscodeModule {

    /// 建立「新增主 Passcode」的畫面
    ///
    /// - Parameters:
    ///   - reason: 建立 passcode 的原因（一般/啟用生物辨識/duress 模式）
    ///   - showParentSheet: 控制上層 sheet 是否要一起關閉
    ///   - onCreate: passcode 建立成功後的 callback（由呼叫端決定後續行為）
    ///   - onCancel: 使用者取消建立流程的 callback
    ///
    /// - Returns: SetPasscodeView（已組裝好對應的 CreatePasscodeViewModel）
    static func createPasscodeView(
        reason: CreatePasscodeReason,
        showParentSheet: Binding<Bool>,
        onCreate: @escaping () -> Void,
        onCancel: @escaping () -> Void
    ) -> some View {

        /// 在 Module 層完成依賴注入與流程 callback 組裝
        let viewModel = CreatePasscodeViewModel(
            passcodeManager: AppCore.shared.security.passcodeManager,
            reason: reason,
            onCreate: onCreate,
            onCancel: onCancel
        )

        /// SetPasscodeView 是共用 UI：
        /// - Create/Edit/Duress 透過不同 ViewModel 來定義流程與文案
        return SetPasscodeView(viewModel: viewModel, showParentSheet: showParentSheet)
    }

    // MARK: - (Optional) Duress Passcode
    //
    // 未來若要支援「建立 Duress Passcode」
    // 可以沿用相同的組裝方式：
    // - 建 CreateDuressPasscodeViewModel
    // - 仍用 SetPasscodeView 呈現
    // - 依賴注入集中在 Module
    //
    // static func createDuressPasscodeView(accountIds: [String], showParentSheet: Binding<Bool>) -> some View { ... }

    // MARK: - CreatePasscodeReason

    /// 建立 passcode 的觸發原因（提供 UI 文案與流程語意）
    ///
    /// 用途：
    /// - 讓「同一個建立 passcode 流程」可以因情境不同而顯示不同文案/行為
    /// - ViewModel 可以依據 reason 決定：建立完要不要順便開 biometry、或進 duress 模式等
    enum CreatePasscodeReason: Hashable, Identifiable {

        /// 一般情境：使用者主動去安全設定建立密碼
        case regular

        /// 因為使用者要啟用生物辨識而要求先建立主密碼
        /// - enabledType: biometry 開關型別（on/auto 等）
        /// - type: FaceID / TouchID
        case biometry(
            enabledType: BiometryManager.BiometryEnabledType,
            type: BiometryType
        )

        /// 因為要開啟 duress 模式而建立 duress passcode（壓力密碼）
        case duress

        /// 依 reason 產生對應的 UI 描述文字
        /// - 放在 enum 內可以集中管理文案規則，避免散落在 View / VM
        var description: String {
            switch self {
            case .regular:
                return "Your passcode will be used to unlock your wallet"
            case let .biometry(_, type):
                /// 依 biometry 類型顯示 FaceID/TouchID 文案
                return "Set a passcode to enable \(type.title) "
            case .duress:
                return "Set a passcode to enable Duress Mode"
            }
        }

        /// Identifiable：讓 reason 可以用在 SwiftUI 的 sheet/item 等 API
        /// - 直接用 self 當 id（因為 enum 是 Hashable）
        var id: Self { self }
    }
}
