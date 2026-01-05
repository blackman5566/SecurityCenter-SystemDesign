//
//  PasscodeView.swift
//  SwiftUI_Wallet
//
//  Created by 許佳豪 on 2025/12/26.
//

import SwiftUI

/// PasscodeView（共用 Passcode UI）
///
/// 角色定位：
/// - 純 UI 元件：
///   - 顯示提示文字（description）
///   - 顯示輸入圓點（依 passcode.count）
///   - 顯示錯誤文字（errorText）
///   - 顯示 lockout 狀態（locked/unlocked）
///   - 顯示數字鍵盤（NumPadView）
/// - 不做任何「密碼驗證」或「流程決策」
///   - 驗證/完成/錯誤次數等交由 ViewModel（BaseUnlockViewModel / SetPasscodeViewModel）處理
///
/// 依賴資料：
/// - `passcode`、`errorText`、`lockoutState`、`biometryType` 都是 Binding
///   => 由上層 VM 控制狀態，PasscodeView 只做呈現 & 回傳使用者輸入
struct PasscodeView: View {

    /// 密碼位數（例如 6）
    let maxDigits: Int

    /// 顯示在上方的描述文字（例如：請輸入密碼 / 請再次確認）
    @Binding var description: String

    /// 顯示在下方的錯誤文字（例如：密碼錯誤、剩餘嘗試次數）
    @Binding var errorText: String

    /// 使用者目前輸入的密碼字串（由 NumPad 點擊累積）
    ///
    /// didSet:
    /// - 只要 passcode 非空就顯示 backspace（讓 UI 能刪除）
    /// - 注意：@Binding 本身不太建議用 didSet 做邏輯，因為觸發時機可能受 SwiftUI 更新策略影響
    ///   但若只是同步 UI 小狀態（backspaceVisible）通常可接受
    @Binding var passcode: String {
        didSet {
            backspaceVisible = !passcode.isEmpty
        }
    }

    /// FaceID/TouchID 型別（nil 代表不顯示生物辨識按鈕）
    @Binding var biometryType: BiometryType?

    /// 鎖定狀態（輸錯太多次 -> locked 到某個時間）
    @Binding var lockoutState: LockoutState

    /// 錯誤時觸發 shake 動畫的 trigger（上層每次錯誤 +1）
    @Binding var shakeTrigger: Int

    /// 是否允許「亂數鍵盤」功能
    let randomEnabled: Bool

    /// 點擊生物辨識按鈕時的 callback（由上層處理真正的 FaceID/TouchID 流程）
    var onTapBiometry: (() -> Void)? = nil

    // MARK: - Local UI State

    /// 數字鍵盤排列（預設 1...9 + 0）
    @State var digits: [Int] = (1 ... 9) + [0]

    /// 是否顯示 backspace（與 passcode 是否為空同步）
    @State var backspaceVisible: Bool = false

    /// 是否啟用亂數鍵盤
    /// - didSet 會切換 digits 排列（固定/亂數）
    @State var randomized: Bool = false {
        didSet {
            if randomized {
                digits = (0 ... 9).shuffled()
            } else {
                digits = (1 ... 9) + [0]
            }
        }
    }

    var body: some View {
        VStack {
            /// 上半部：描述文字 / 圓點 / 錯誤 / lockout 狀態
            VStack {
                switch lockoutState {
                case .unlocked:
                    /// ✅ 未鎖定：顯示正常輸入 UI
                    /// 上方提示文字（description）
                    Text(description)
                        .padding(.horizontal, 48)
                        .multilineTextAlignment(.center)
                        .frame(maxHeight: .infinity, alignment: .bottom)
                        .transition(.opacity.animation(.easeOut))
                        .id(description)

                    /// 密碼圓點顯示（依 passcode.count 決定填滿幾顆）
                    HStack(spacing: 12) {
                        ForEach(0 ..< maxDigits, id: \.self) { index in
                            Circle()
                                /// index < passcode.count => 已輸入的位數 -> 填滿
                                .fill(index < passcode.count ? Color(.label) : Color(.tertiaryLabel))
                                .frame(width: 12, height: 12)
                        }
                    }
                    /// 錯誤時抖動動畫（shakeTrigger 改變就會抖）
                    .modifier(Shake(animatableData: CGFloat(shakeTrigger)))
                    .padding(.vertical, 16)
                    /// 對 shakeTrigger 與 passcode 變動做動畫
                    .animation(.linear(duration: 0.3), value: shakeTrigger)
                    .animation(.easeOut(duration: 0.1), value: passcode)

                    /// 下方錯誤文字（errorText）
                    Text(errorText)
                        .padding(.horizontal, 48)
                        .multilineTextAlignment(.center)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .transition(.opacity.animation(.easeOut))
                        .id(errorText)

                case let .locked(unlockDate):
                    /// 🔒 鎖定中：顯示鎖定提示與解除時間
                    VStack(spacing: 16) {
                        Image("lock_48")
                            .foregroundColor(.gray)

                        /// 顯示直到某個時間才能再嘗試
                        /// - DateFormatter.cachedFormatter(...) 應該是你們的 formatter cache helper
                        Text(
                            "Disabled until: \(DateFormatter.cachedFormatter(format: "hh:mm:ss").string(from: unlockDate))")
                        .padding(.horizontal, 48)
                        .multilineTextAlignment(.center)
                    }
                }
            }
            .frame(maxHeight: .infinity)

            /// 下半部：數字鍵盤 + 亂數鍵盤按鈕
            VStack(spacing: 24) {

                /// NumPadView：實際的按鍵區
                /// - digits：鍵盤排列（可能亂數）
                /// - biometryType：控制是否顯示 FaceID/TouchID 按鈕
                /// - disabled：locked 狀態時禁用輸入
                /// - onTapDigit：累積 passcode
                /// - onTapBackspace：刪除最後一位
                NumPadView(
                    digits: $digits,
                    biometryType: $biometryType,
                    disabled: Binding(get: { lockoutState.isLocked }, set: { _ in }),
                    onTapDigit: { digit in
                        //點擊密碼按鈕
                        guard passcode.count < maxDigits else { return }
                        passcode = passcode + "\(digit)"
                    },
                    onTapBackspace: {
                        /// 刪除最後一位
                        passcode = String(passcode.dropLast())
                    },
                    //點擊生物識別功能
                    onTapBiometry: onTapBiometry
                )

                /// 亂數鍵盤切換按鈕（randomEnabled = true 才顯示）
                /// - randomized 狀態決定 digits 是否 shuffled
                randomButton()
            }
            .padding(.bottom, 32)
        }
    }

    /// 顯示/隱藏「亂數鍵盤」按鈕
    /// - randomEnabled == false：不顯示任何東西
    /// - randomEnabled == true：顯示切換按鈕，locked 時禁用
    @ViewBuilder func randomButton() -> some View {
        if randomEnabled {
            Button(action: {
                randomized.toggle()
            }) {
                Text("Random")
            }
            .disabled(lockoutState.isLocked)
        } else {
            EmptyView()
        }
    }
    
    private struct Shake: GeometryEffect {
        var amount: CGFloat = 8
        var shakesPerUnit = 4
        var animatableData: CGFloat

        func effectValue(size _: CGSize) -> ProjectionTransform {
            ProjectionTransform(CGAffineTransform(translationX: amount * sin(animatableData * .pi * CGFloat(shakesPerUnit)), y: 0))
        }
    }
}
