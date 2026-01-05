//
//  AutoLockView.swift
//  SwiftUI_Wallet
//
//  Created by 許佳豪 on 2025/12/26.
//

import SwiftUI

/// Auto Lock 設定頁（選單式）
///
/// 職責：
/// - 顯示所有 AutoLockPeriod 選項
/// - 點選後立即更新外部綁定的 `period`
/// - 更新完成後自動 dismiss（回到上一頁）
///
/// 設計理由：
/// - `@Binding`：這個畫面本身不持有狀態，狀態由上層（設定頁/VM）擁有；這裡只是「編輯器」
/// - `dismiss()`：選完就退出，符合設定頁的 UX（像 iOS 系統設定）
struct AutoLockView: View {

    /// 由上層傳入的目前自動鎖定時間
    /// - 綁定讓此頁對 period 的修改會直接同步回上層狀態
    @Binding var period: AutoLockPeriod

    /// 用於關閉目前頁面（pop / dismiss）
    /// - NavigationStack push 進來時，dismiss() 會回上一頁
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                /// 顯示所有可選的時間區間
                /// - `id: \.self`：因為 AutoLockPeriod 通常是 enum 且 Hashable，可直接用 self 當識別
                ForEach(AutoLockPeriod.allCases, id: \.self) { option in

                    /// 每一個 option 用 Button，點一下就完成選取
                    Button {
                        /// 更新上層狀態：把選到的 option 設為目前 period
                        period = option

                        /// 選完就關閉本頁（回上一頁）
                        dismiss()
                    } label: {
                        HStack {
                            /// 顯示選項名稱
                            /// - `title` 建議是 AutoLockPeriod 的 computed property，集中管理顯示文案
                            Text(option.title)
                                .foregroundStyle(.primary)

                            Spacer()

                            /// 若目前 period 等於此 option，顯示 checkmark
                            /// - 讓使用者知道當前選到哪個
                            if period == option {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }

        /// 導航列標題：Auto Lock
        /// - 若已做多語系，用 localized key
        .navigationTitle("Auto-Lock")

        /// 顯示 inline 樣式（跟 iOS 設定頁一致）
        .navigationBarTitleDisplayMode(.inline)
    }
}
