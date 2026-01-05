//
//  SecuritySettingsView.swift
//  SwiftUI_Wallet
//
//  Created by 許佳豪 on 2025/12/26.
//

import SwiftUI

struct SecuritySettingsView: View {
    @ObservedObject var viewModel: SecuritySettingsViewModel

    var body: some View {
            List {
                //密碼相關設定
                passcodeSection()
                
                //自動上鎖設定時間
                autoLockSection()
                
                //如果有指紋或是faseid
                biometryRow()
                
                }.navigationTitle("Security")
        }
    
    @ViewBuilder
    private func passcodeSection() -> some View {
        Section {
            //如果有設定密碼了
            if viewModel.isPasscodeSet {
                //顯示編輯密碼按鈕
                Button {
                    //先去解鎖
                    Coordinator.shared.presentAfterUnlock { isPresented in
                        //呼叫編輯流程
                        NavigationStack {
                            EditPasscodeModule.editPasscodeView(showParentSheet: isPresented)
                        }
                    }
                } label: {
                    Text("Edit Passcode").foregroundStyle(.primary)
                }

                //顯示取消密碼按鈕
                Button {
                    Coordinator.shared.performAfterUnlock {
                        viewModel.removePasscode()
                    }
                } label: {
                    Text("Disable Passcode").foregroundStyle(.primary)
                }
            } else {
                //啟用密碼按鈕
                Button {
                    presentCreatePasscode(reason: .regular)
                } label: {
                    Text("Enable Passcode").foregroundStyle(.primary)
                }
            }
        }
    }
    
    @ViewBuilder
    private func autoLockSection() -> some View {
        if viewModel.isPasscodeSet {
            Section {
                NavigationLink {
                    AutoLockView(period: $viewModel.autoLockPeriod)
                } label: {
                    HStack(spacing: 16) {
                        Text("Auto-Lock").foregroundStyle(.primary)
                        Text(viewModel.autoLockPeriod.title).foregroundStyle(.primary)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func biometryRow() -> some View {
        if let biometryType = viewModel.biometryType {
            Button {
                Coordinator.shared.present(type: .alert) { isPresented in
                    OptionAlertView(
                        title: biometryType.title,
                        viewItems: BiometryManager.BiometryEnabledType.allCases.map {
                            .init(
                                text: $0.title,
                                description: $0.description,
                                selected: $0 == viewModel.biometryEnabledType
                            )
                        },
                        onSelect: { index in
                            viewModel.biometryEnabledType = BiometryManager.BiometryEnabledType.allCases[index]
                        },
                        isPresented: isPresented
                    )
                }
            } label: {
                HStack(spacing: 16) {
                    Text(biometryType.title)
                    Spacer()
                    Text(viewModel.biometryEnabledType.title)
                }
            }
            .onChange(of: viewModel.biometryEnabledType) { _, type in
                if !viewModel.isPasscodeSet, type.isEnabled {
                    presentCreatePasscode(reason: .biometry(enabledType: type, type: biometryType))
                }
            }
        }
    }
}

//綁定相關頁面
extension SecuritySettingsView {
    //包裝新增密碼相關行為
    /// 1. regular 一般情境：使用者主動去安全設定建立密碼
    /// 2. 因為使用者要啟用生物辨識而要求先建立主密碼
    /// - enabledType: biometry 開關型別（on/auto 等）
    /// - type: FaceID / TouchID
    /// 3. 因為要開啟 duress 模式而建立 duress passcode（壓力密碼）
    fileprivate func presentCreatePasscode(reason: CreatePasscodeModule.CreatePasscodeReason) {
        Coordinator.shared.present { isPresented in
            NavigationStack {
                //產生 createPasscodeView 
                CreatePasscodeModule.createPasscodeView(
                    reason: reason,
                    showParentSheet: isPresented,
                    onCreate: {
                        //新增了,要設定對應行為
                        switch reason {
                        //FaceID / TouchID
                        case let .biometry(enabledType, _):
                            viewModel.set(biometryEnabledType: enabledType)
                        default: ()
                        }
                    },
                    onCancel: {
                        //取消了
                        switch reason {
                        case .biometry: viewModel.biometryEnabledType = .off
                        default: ()
                        }
                    }
                )
            }
        }
    }
}

