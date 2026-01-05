
//
//  KeychainStorage.swift
//  SwiftUI_Wallet
//
//  Created by 許佳豪 on 2025/12/18.
//

import Foundation
import KeychainAccess

/// KeychainStorage：
/// 封裝第三方套件 KeychainAccess，提供專案統一的 Keychain 讀寫介面
///
/// 使用情境：
/// - 存敏感資料：passcode、加密後的 seed、token、設定值（敏感）
/// - 與 UserDefaults 不同：Keychain 適合安全資料
class KeychainStorage {
    private let keychain: Keychain

    init(service: String) {
        /// 建立一個以 service 區隔的 keychain namespace（不同 app/模組可用不同 service）
        ///
        /// accessibility(.whenPasscodeSetThisDeviceOnly) 是重點：
        /// - whenPasscodeSet：裝置必須有設定「系統 Passcode」才允許存取
        /// - ThisDeviceOnly：此 keychain item 不會被備份/搬到其他裝置（偏硬派安全）
        ///
        /// 對錢包的意義：
        /// - 使用者把手機的系統密碼關掉 -> 這些資料會變得不可用（或無法寫入）
        /// - 可以避免在弱安全狀態下仍能讀取私密資料
        keychain = Keychain(service: service).accessibility(.whenPasscodeSetThisDeviceOnly)
    }
}

extension KeychainStorage {

    /// 讀取字串型的值，並轉成 LosslessStringConvertible（例如：String / Int / Double / Bool(不算)）
    ///
    /// 注意：
    /// - 底層是 keychain[key] 取出 String?
    /// - 再用 T(string) 轉型（例如 Int("123") -> 123）
    ///
    /// 常用來存：
    /// - String
    /// - 數字（Int/Double）等可以用字串轉回的型別
    func value<T: LosslessStringConvertible>(for key: String) -> T? {
        guard let string = keychain[key] else {
            return nil
        }
        return T(string)
    }

    /// 設定字串型（LosslessStringConvertible）資料
    ///
    /// - value != nil：寫入 keychain（以字串形式存）
    /// - value == nil：移除 key（等於 delete）
    ///
    /// throws：KeychainAccess 的 set/remove 可能丟錯（例如：權限/狀態/不可存取）
    func set(value: (some LosslessStringConvertible)?, for key: String) throws {
        if let value {
            try keychain.set(value.description, key: key)
        } else {
            try keychain.remove(key)
        }
    }

    /// 讀取 Data（適合存 JSON / encoded struct / binary）
    ///
    /// 這裡用 try?：讀不到或出錯就回 nil
    func value(for key: String) -> Data? {
        try? keychain.getData(key)
    }

    /// 設定 Data
    ///
    /// - value != nil：寫入 Data
    /// - value == nil：移除 key
    func set(value: Data?, for key: String) throws {
        if let value {
            try keychain.set(value, key: key)
        } else {
            try keychain.remove(key)
        }
    }

    /// 移除某個 key
    func removeValue(for key: String) throws {
        try keychain.remove(key)
    }

    /// 清空該 service 下的所有 key/value
    ///
    /// 注意：這會把「同 service」的所有資料都刪掉（包含 passcode、加密 seed 等）
    /// 你前面的 KeychainManager.handleLaunch() 就會呼叫 clear() 來做首次啟動清理
    func clear() throws {
        try keychain.removeAll()
    }
}
