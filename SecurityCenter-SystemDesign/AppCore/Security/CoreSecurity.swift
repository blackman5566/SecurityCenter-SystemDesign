//
//  CoreSecurity.swift
//  SwiftUI_Wallet
//
//  Created by 許佳豪 on 2025/12/26.
//

import Foundation

/// Core 的安全/鎖定子系統容器（只做建立與持有，不放業務邏輯）
struct CoreSecurity {
    let biometryManager: BiometryManager
    let passcodeManager: PasscodeManager
    let lockManager: LockManager
    let lockoutManager: LockoutManager
    let coverManager:CoverManager
    let passcodeLockManager:PasscodeLockManager
    init(storage:CoreStorage,biometryManager:BiometryManager,passcodeManager:PasscodeManager) {

        // ✅ 生物辨識狀態/設定（FaceID/TouchID 開關、狀態）
        self.biometryManager = biometryManager
        
        
        // ✅ App 內 passcode（依賴 biometry + keychain）
        self.passcodeManager = passcodeManager

        // ✅ App lock（前景鎖、超時鎖，依賴 passcode + UserDefaults）
        self.lockManager = LockManager(
            passcodeManager: passcodeManager,
            userDefaultsStorage: storage.userDefaultsStorage
        )

        // ✅ 前景/背景遮罩（避免背景截圖露出敏感資訊）
        self.coverManager = CoverManager(lockManager: self.lockManager)
        
        // ✅ 防爆破 / 鎖定策略（通常放 keychain）
        self.lockoutManager = LockoutManager(keychainStorage: storage.keychainStorage)
        
        ///✅  管理「裝置安全性」的狀態：
        /// - iOS 裝置是否有啟用系統鎖（Passcode / FaceID / TouchID）
        /// - 若發現使用者把系統鎖關掉（passcodeNotSet），就清掉本機敏感資料
        self.passcodeLockManager = PasscodeLockManager()
        
    }
}
