//
//  CoreStorage.swift
//  SwiftUI_Wallet
//
//  Created by 許佳豪 on 2025/12/26.
//
import Foundation

/// Core 的本地儲存容器：把 UserDefaults / LocalStorage / Keychain 統一包起來
/// 這一包只做「建立與持有」，不放任何業務邏輯。
class CoreStorage {
    let userDefaultsStorage: UserDefaultsStorage
    let keychainStorage: KeychainStorage
    let keychainManager:KeychainManager
    init(keychainService: String) {
        /// ✅ 很簡單設定 UserDefaults 而已
        self.userDefaultsStorage = UserDefaultsStorage()
        
        /// ✅ Keychain：存敏感資料（passcode、seed、token…）
        self.keychainStorage = KeychainStorage(service: keychainService)
        
        // ✅ Keychain 高階管理（包裝 keychainStorage + UserDefaults）
        self.keychainManager = KeychainManager(keychainStorage: self.keychainStorage, userDefaultsStorage: self.userDefaultsStorage)
    }
}
