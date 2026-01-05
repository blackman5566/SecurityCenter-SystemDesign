//
//  KeychainManager.swift
//  SwiftUI_Wallet
//
//  Created by 許佳豪 on 2025/12/26.
//

class KeychainManager {
    /// UserDefaults key：用來標記「這個 App 是否曾經啟動過」
    ///
    /// 注意：這不是存在 Keychain，而是存在 UserDefaults。
    /// 目的：用一個「容易存在且不會被 keychain 刪掉影響」的標記，
    /// 來判斷是否是第一次啟動。
    private let keyDidLaunchOnce = "did_launch_once_key"

    /// Keychain 存取封裝
    /// - 在錢包 App 內通常用來存：passcode、seed/encrypted data、token、設定值等
    private let keychainStorage: KeychainStorage

    /// UserDefaults 存取封裝
    /// - 用來存一些非敏感設定/狀態，例如：didLaunchOnce
    private let userDefaultsStorage: UserDefaultsStorage

    init(keychainStorage: KeychainStorage, userDefaultsStorage: UserDefaultsStorage) {
        self.keychainStorage = keychainStorage
        self.userDefaultsStorage = userDefaultsStorage
    }
}

extension KeychainManager {

    /// App 啟動時呼叫（例如 AppDelegate / SceneDelegate / App init）
    ///
    /// 這段的目的：處理「第一次啟動」的 keychain 清理。
    ///
    /// 為什麼錢包 App 會這樣做？
    /// - iOS Keychain 有一個特性：某些情況下 App 被刪掉再裝回來，
    ///   Keychain 內容可能還留著（取決於 keychain item 的屬性/群組/設定）。
    /// - 對錢包/安全 App 來說，這可能造成：
    ///   1) 新安裝卻讀到舊的 passcode / seed 資料（狀態錯亂）
    ///   2) 使用者以為是全新開始，其實沿用舊資料（安全與 UX 都危險）
    ///
    /// 所以：在「第一次啟動」時，主動清空 keychain，確保狀態一致。
    func handleLaunch() {
        /// 從 UserDefaults 讀取是否曾啟動過
        let didLaunchOnce = userDefaultsStorage.value(for: keyDidLaunchOnce) ?? false

        /// 如果是第一次啟動（或 UserDefaults 被清掉導致判斷為第一次）
        if !didLaunchOnce {
            /// 清空 keychain，避免殘留敏感資料造成錯亂
            ///
            /// try?：這裡選擇「失敗也不讓 App 崩潰」
            /// - 代表清理是 best-effort
            /// - 如果你想更嚴謹，可能會記 log 或上報錯誤
            try? keychainStorage.clear()

            /// 設定已啟動過，避免下次又清一次
            userDefaultsStorage.set(value: true, for: keyDidLaunchOnce)
        }
    }
}
