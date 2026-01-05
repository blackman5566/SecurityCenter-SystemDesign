//
//  UserDefaultsStorage.swift
//  SwiftUI_Wallet
//
//  Created by 許佳豪 on 2025/12/26.
//
import Foundation

class UserDefaultsStorage {

    /// 讀取指定 key 的值，並嘗試轉成泛型 T
    ///
    /// 用法例子：
    /// let didLaunchOnce: Bool? = storage.value(for: "did_launch_once_key")
    /// let exitTimestamp: TimeInterval? = storage.value(for: "last_exit_date_key")
    ///
    /// 注意：
    /// - UserDefaults.standard.value(forKey:) 回傳 Any?
    /// - 這裡用 as? T 轉型：轉得過就回傳，轉不過就 nil
    /// - 如果你 key 存的是 Double，但你用 Int 去取，就會拿到 nil
    func value<T>(for key: String) -> T? {
        UserDefaults.standard.value(forKey: key) as? T
    }

    /// 寫入或刪除指定 key 的值
    ///
    /// - 如果 value != nil：set
    /// - 如果 value == nil：removeObject
    ///
    /// 參數用 `(some Any)?`：
    /// - 代表「可以傳入任何型別的值」，但仍要符合 UserDefaults 支援的型別
    ///   (例如：String/Bool/Int/Double/Data/Date/Array/Dictionary...)
    ///
    /// 注意：UserDefaults 不適合存敏感資訊（錢包私鑰/助記詞/密碼都不要放這）
    func set(value: (some Any)?, for key: String) {
        if let value {
            UserDefaults.standard.set(value, forKey: key)
        } else {
            UserDefaults.standard.removeObject(forKey: key)
        }

        /// 強制同步寫入磁碟
        ///
        /// 但：Apple 早就不建議手動呼叫 synchronize()
        /// - 它是舊時代 API，通常不需要
        /// - 可能造成不必要的 I/O、影響效能
        /// - 系統本來就會在適當時機自動同步
        ///
        /// 你這邊用在「最後離開時間」這種資料，確實想要更即時落盤，
        /// 但通常也不需要 synchronize()；真的要保證落盤，會用更明確的設計（或檔案寫入）。
        UserDefaults.standard.synchronize()
    }
}

