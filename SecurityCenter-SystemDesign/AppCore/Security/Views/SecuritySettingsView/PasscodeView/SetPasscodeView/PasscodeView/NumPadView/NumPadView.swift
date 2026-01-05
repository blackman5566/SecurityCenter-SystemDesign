//
//  NumPadView.swift
//  SwiftUI_Wallet
//
//  Created by 許佳豪 on 2025/12/26.
//

import SwiftUI

struct NumPadView: View {
    @Binding var digits: [Int]
    @Binding var biometryType: BiometryType?
    @Binding var disabled: Bool

    let onTapDigit: (Int) -> Void
    let onTapBackspace: () -> Void
    var onTapBiometry: (() -> Void)? = nil

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            
            //新增上方的數字 1-9
            ForEach(Array(digits.prefix(9).enumerated()), id: \.offset) { _, digit in
                NumberView(digit: digit, disabled: disabled) { onTapDigit(digit) }
            }

            //是否有開啟手勢或是faceide功能驗證
            if let biometryType {
                Button(action: {
                    //呼叫 Biometry 功能驗證
                    onTapBiometry?()
                }) {
                    Image(biometryType.iconName).renderingMode(.template)
                }
                .disabled(disabled)
            } else {
                Text("")
            }

            //新增最下面數字
            if let digit = digits.last {
                NumberView(digit: digit, disabled: disabled) { onTapDigit(digit) }
            }

            Button(action: {
                //刪除數入的密碼
                onTapBackspace()
            }) {
                Image("backspace_24").renderingMode(.template)
            }
            .disabled(disabled)
        }
        .frame(width: 280)
    }
}
