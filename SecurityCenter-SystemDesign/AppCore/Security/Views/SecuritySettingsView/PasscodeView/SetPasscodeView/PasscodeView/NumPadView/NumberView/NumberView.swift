//
//  NumberView.swift
//  SwiftUI_Wallet
//
//  Created by 許佳豪 on 2025/12/30.
//

import SwiftUI

/// NumberView（數字鍵盤的單一按鍵）
///
/// 角色定位：
/// - 只負責顯示一個 digit（0~9）
/// - 點擊時呼叫外部傳入的 onTap（不在這裡拼接 passcode）
/// - disabled 由外部控制（例如 lockout 時整個鍵盤禁用）
///
/// 設計重點：
/// - View 很薄：
///   - 視覺風格交給 ButtonStyle（NumPadButtonStyle）
///   - 行為交給 onTap
struct NumberView: View {
    /// 要顯示的數字
    let digit: Int

    /// 是否禁用按鍵（例如 lockout / 不可輸入狀態）
    let disabled: Bool

    /// 點擊時要做的事（例如把 digit append 到 passcode）
    let onTap: () -> Void

    var body: some View {
        /// Button 本身只負責觸發 onTap
        Button(action: {
            onTap()
        }) {
            /// label：顯示數字
            /// - 這裡給一個 frame 讓可點擊區域變大（更好點）
            Text(String(digit))
                .frame(width: 72, height: 72)
        }
        /// 套用自訂樣式（統一鍵盤外觀：圓形、背景、按壓回饋…）
        .buttonStyle(NumPadButtonStyle())

        /// 依 disabled 狀態禁用（同時也會影響 ButtonStyle 裡的 @Environment(\.isEnabled)）
        .disabled(disabled)

        /// 當 digit 改變時做動畫
        /// - 注意：digit 通常不會變（固定按鍵），所以這個 animation 大多情況不會觸發
        /// - 若你的 digits 會 shuffle（random keypad），更有意義的是對「排列變動」做動畫
        .animation(.easeOut(duration: 0.2), value: digit)
    }
}

/// NumPadButtonStyle（數字鍵盤按鍵的統一外觀）
///
/// 目的：
/// - 統一所有 numpad 按鈕的視覺：
///   - 文字顏色（enabled/disabled）
///   - 背景（正常/按下/disabled）
///   - 圓形裁切 + 邊框
///   - 按壓回饋（縮放）
///
/// 特色：
/// - 使用 semantic/system colors（label / separator / systemBackground）
///   => 自動跟隨 Dark/Light Mode，不用自己判斷
struct NumPadButtonStyle: ButtonStyle {
    /// SwiftUI 會把 .disabled(...) 的狀態往環境裡傳
    /// - 這裡用 @Environment(\.isEnabled) 取得「目前按鈕是否可用」
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        /// configuration.label 是你 Button 的 label（NumberView 裡的 Text）
        /// configuration.isPressed 代表目前是否正在按壓中（按住不放）
        configuration.label
            /// 文字顏色：enabled 用 label、disabled 用 secondaryLabel
            .foregroundStyle(foreground(isEnabled: isEnabled))

            /// 按鍵尺寸（建議跟 label 的 frame 一致，避免點擊區域與外觀不一致）
            .frame(width: 64, height: 64)

            /// 背景：使用 semantic colors + pressed overlay
            .background(background(isPressed: configuration.isPressed, isEnabled: isEnabled))

            /// 圓形按鍵
            .clipShape(Circle())

            /// 圓形邊框：使用 separator（系統分隔線顏色）
            .overlay(Circle().strokeBorder(stroke(isEnabled: isEnabled), lineWidth: 1))

            /// 按下去縮小一點，增加「按鍵感」
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)

            /// 讓按壓狀態變化有動畫（按下/放開）
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    /// 文字顏色（自動跟隨 Dark/Light）
    /// - label：淺色模式接近黑、深色模式接近白
    /// - secondaryLabel：disabled 時降對比
    private func foreground(isEnabled: Bool) -> Color {
        isEnabled ? Color(.label) : Color(.secondaryLabel)
    }

    /// 邊框顏色（自動跟隨 Dark/Light）
    /// - separator：系統分隔線顏色
    /// - disabled 時再降低透明度
    private func stroke(isEnabled: Bool) -> Color {
        isEnabled ? Color(.separator) : Color(.separator).opacity(0.4)
    }

    /// 背景（自動跟隨 Dark/Light）
    ///
    /// 這裡的策略：
    /// - base：secondarySystemBackground（很像 iOS 原生鍵盤/卡片的底色）
    /// - pressedOverlay：用 label + 低透明度疊一層，讓按下去「更實/更有重量」
    /// - disabledOverlay：禁用時稍微降低存在感
    private func background(isPressed: Bool, isEnabled: Bool) -> some View {
        // semantic colors：自動跟隨 Dark/Light
        let base = Color(.secondarySystemBackground)

        /// 按壓時的 overlay（用 label 當基底，深淺模式都會自然）
        let pressedOverlay = Color(.label).opacity(0.06)

        /// disabled 時的 overlay（更淡）
        let disabledOverlay = Color(.label).opacity(0.02)

        return base
            .overlay(
                Circle().fill(
                    isEnabled
                    ? (isPressed ? pressedOverlay : Color.clear)
                    : disabledOverlay
                )
            )
    }
}
