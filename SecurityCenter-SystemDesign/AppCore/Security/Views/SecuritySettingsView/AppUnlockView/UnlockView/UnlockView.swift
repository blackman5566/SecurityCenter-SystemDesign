//
//  UnlockView.swift
//  SwiftUI_Wallet
//
//  Created by 許佳豪 on 2025/12/26.
//

import LocalAuthentication
import SwiftUI

struct UnlockView: View {
    @ObservedObject var viewModel: BaseUnlockViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
            PasscodeView(
                maxDigits: viewModel.passcodeLength,
                description: $viewModel.description,
                errorText: $viewModel.errorText,
                passcode: $viewModel.passcode,
                biometryType: $viewModel.resolvedBiometryType,
                lockoutState: $viewModel.lockoutState,
                shakeTrigger: $viewModel.shakeTrigger,
                randomEnabled: true,
                onTapBiometry: {
                    unlockWithBiometry()
                }
            )
        .onAppear {
            viewModel.onAppear()
        }
        .onReceive(viewModel.finishSubject) {
            dismiss()
        }
        .onReceive(viewModel.unlockWithBiometrySubject) {
            unlockWithBiometry()
        }
    }

    private func unlockWithBiometry() {
        //解鎖流程
        let localAuthenticationContext = LAContext()
        localAuthenticationContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Unlock wallet") { success, _ in
            if success {
                DispatchQueue.main.async {
                    viewModel.onBiometryUnlock()
                }
            }
        }
    }
}
