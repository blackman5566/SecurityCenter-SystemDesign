//
//  AppCore.swift
//  SecurityCenter-SystemDesign
//
//  Created by 許佳豪 on 2026/1/5.
//


import Foundation

class AppCore {
    /// Core 的單例容器（initApp() 之後才會有值）
    static var instance: AppCore?

    /// App 啟動時呼叫：建立並注入所有服務（通常在 AppDelegate/SceneDelegate）
    static func initApp() throws {
        instance = try AppCore()
    }

    /// 全域存取點（注意：若 initApp 未執行，這裡會 crash）
    static var shared: AppCore {
        instance!
    }
    
    // MARK: - [2] Persistence Layer（本地儲存）
    let storage: CoreStorage
    let security: CoreSecurity
    
    let passcodeManager:PasscodeManager
    let biometryManager:BiometryManager
    
    init() throws {
        // Core 的本地儲存容器：把 UserDefaults / LocalStorage / Keychain 統一包起
        self.storage = CoreStorage(keychainService: "io.wallet.dev")
        
        //生物功能管理
        self.biometryManager = BiometryManager(userDefaultsStorage: storage.userDefaultsStorage)
        
        //管理 App 的 Passcode
        self.passcodeManager = PasscodeManager(
            biometryManager: biometryManager,
            keychainStorage: storage.keychainStorage
        )
        
        //安全相關功能
        self.security = CoreSecurity(storage: storage, biometryManager: biometryManager, passcodeManager: passcodeManager)
        
    }
}

