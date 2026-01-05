//
//  ModuleUnlockView.swift
//  SwiftUI_Wallet
//
//  Created by 許佳豪 on 2025/12/26.
//

import SwiftUI

/// ModuleUnlockView（解鎖流程的「模組入口 View」）
///
/// 角色定位：
/// - 這個 View 主要扮演「組裝入口」：
///   - 建立對應的 ViewModel（ModuleUnlockViewModel）
///   - 把它丟給共用的 `UnlockView` 來呈現 UI
/// - 對外只暴露兩個參數：
///   - `biometryAllowed`：此情境是否允許 FaceID/TouchID
///   - `onUnlock`：解鎖成功要做什麼（由呼叫者決定）
///
/// 為什麼要用 ModuleUnlockView：
/// - 讓外部呼叫者不用知道 UnlockViewModel 需要哪些依賴/初始化參數
/// - 把「初始化與依賴組裝」集中在入口，呼叫端只管行為（onUnlock）
struct ModuleUnlockView: View {

    /// ViewModel 生命週期由 View 持有（只建立一次）
    /// - 使用 StateObject 確保 View 重繪不會重新 init ViewModel
    @StateObject private var viewModel: ModuleUnlockViewModel

    /// 用於關閉當前畫面（dismiss / pop）
    @Environment(\.dismiss) private var dismiss

    /// 初始化入口
    ///
    /// - Parameter biometryAllowed:
    ///   是否允許使用生物辨識（FaceID/TouchID）
    ///   （例如：一般解鎖允許，但某些高敏感操作可能不允許）
    ///
    /// - Parameter onUnlock:
    ///   解鎖成功後要執行的 callback
    ///   （例如：dismiss 上層、繼續導航、執行某段受保護操作）
    init(biometryAllowed: Bool = false, onUnlock: @escaping () -> Void) {
        /// 在 init 時建立 ViewModel，並交由 StateObject 管理生命週期
        _viewModel = StateObject(
            wrappedValue: ModuleUnlockViewModel(
                biometryAllowed: biometryAllowed,
                onUnlock: onUnlock
            )
        )
    }

    var body: some View {
        /// 使用共用的 UnlockView 來呈現 UI
        /// - ModuleUnlockView 本身不關心 UI 細節，只負責「入口組裝」
        UnlockView(viewModel: viewModel)
            .navigationTitle("Unlock")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                /// 取消按鈕：直接關閉此解鎖頁
                /// - 適用於「使用者不想解鎖、放棄操作」的情境
                Button("Cancel") {
                    dismiss()
                }
            }
    }
}
