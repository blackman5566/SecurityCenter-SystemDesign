//
//  PasscodeManager.swift
//  SwiftUI_Wallet
//
//  Created by 許佳豪 on 2025/12/26.
//
import Combine
import HsExtensions

/// 管理 App 的 Passcode（以及 Duress Passcode）
///
/// 設計重點：
/// - 支援「多層 passcode」（用 currentPasscodeLevel 指向當前生效的那一組）
/// - 支援「duress passcode」（在當前 passcode 層級的下一層）
/// - passcode 存在 Keychain（比 UserDefaults 安全）
///
/// 注意：這裡 passcode 以「明文」存到 keychain（透過 join 分隔符字串）
/// - Keychain 本身有一定保護，但若你要更硬派安全，通常會再 hash + salt。
class PasscodeManager {
    /// Keychain 裡存的字串格式：passcode0|passcode1|passcode2...
    /// 用 "|" 當分隔符
    private let separator = "|"

    /// Keychain 的 key
    private let passcodeKey = "pin_keychain_key"

    /// 生物辨識管理（FaceID/TouchID 啟用狀態）
    private let biometryManager: BiometryManager

    /// Keychain 存取封裝
    private let keychainStorage: KeychainStorage

    /// passcodes 陣列：
    /// - index = level（層級）
    /// - value = passcode（字串）
    ///
    /// 範例：
    /// passcodes = ["1234"]                  -> 只有一層
    /// passcodes = ["1234", "9999"]          -> 0: normal, 1: duress（如果 currentPasscodeLevel = 0）
    /// passcodes = ["1111", "2222", "3333"]  -> 可切換 currentPasscodeLevel 指向不同主 passcode
    private var passcodes = [String]()

    /// 目前正在使用哪一層 passcode（哪一個 index 是「主密碼」）
    @DistinctPublished private(set) var currentPasscodeLevel: Int

    /// 是否有設定 passcode（主密碼是否非空）
    @DistinctPublished private(set) var isPasscodeSet = false

    /// 是否有設定 duress passcode（主密碼下一層是否存在）
    @DistinctPublished private(set) var isDuressPasscodeSet = false

    init(biometryManager: BiometryManager, keychainStorage: KeychainStorage) {
        self.biometryManager = biometryManager
        self.keychainStorage = keychainStorage

        /// 從 keychain 讀取 passcodes（格式："1234|9999|...."）
        /// - 有值：切成陣列
        /// - 沒值：預設給一個空字串（代表「目前這層還沒設 passcode」）
        if let rawPasscodes: String = keychainStorage.value(for: passcodeKey), !rawPasscodes.isEmpty {
            passcodes = rawPasscodes.components(separatedBy: separator)
        } else {
            passcodes = [""]
        }

        /// 預設 currentPasscodeLevel = 最後一層
        /// - 代表「最後一筆」是目前生效的主 passcode
        currentPasscodeLevel = passcodes.count - 1

        /// 同步狀態（isPasscodeSet / isDuressPasscodeSet / biometry 開關）
        syncState()
    }

    /// 根據目前 passcodes / currentPasscodeLevel 重新計算狀態
    private func syncState() {
        /// 主 passcode 是否有設定：
        /// - 取目前層級（最後一層）是否為非空
        isPasscodeSet = passcodes.last.map { !$0.isEmpty } ?? false

        /// duress passcode 是否有設定：
        /// - duress 定義：在「currentPasscodeLevel 的下一層」
        /// - 如果 passcodes.count > currentPasscodeLevel + 1 代表存在下一層
        isDuressPasscodeSet = passcodes.count > currentPasscodeLevel + 1

        /// 安全保護：
        /// 如果根本沒有 passcode，卻開了生物辨識，這是矛盾的（biometry 沒有主密碼作為 fallback/基底）
        /// 所以主密碼不存在時，強制把 biometry 關掉
        if !isPasscodeSet, biometryManager.biometryEnabledType.isEnabled {
            biometryManager.biometryEnabledType = .off
        }
    }

    /// 寫入 keychain
    /// - 把 passcodes join 成一個字串存起來
    private func save(passcodes: [String]) throws {
        try keychainStorage.set(value: passcodes.joined(separator: separator), for: passcodeKey)
    }
}

extension PasscodeManager {

    /// 驗證「主 passcode」是否正確（以 currentPasscodeLevel 指向的那層為準）
    func isValid(passcode: String) -> Bool {
        passcodes[currentPasscodeLevel] == passcode
    }

    /// 驗證「duress passcode」是否正確
    ///
    /// duress 的位置：currentPasscodeLevel + 1
    /// - 代表「主密碼下一層」是壓力密碼
    ///
    /// duress passcode 的用途（概念）：
    /// - 使用者被逼迫輸入密碼時，輸入 duress passcode
    /// - App 表面上解鎖成功，但暗地裡可能做一些防護動作（例如：顯示假資產、清除敏感資料、上報事件等）
    func isValid(duressPasscode: String) -> Bool {
        let duressLevel = currentPasscodeLevel + 1

        /// 沒有 duress 那層就直接 false
        guard passcodes.count > duressLevel else {
            return false
        }

        return passcodes[duressLevel] == duressPasscode
    }

    /// 檢查某 passcode 是否已經存在於任何層（避免重複使用）
    func has(passcode: String) -> Bool {
        passcodes.contains(passcode)
    }

    /// 把「主 passcode 層級」切換到最後一層
    /// - 用途：例如新增完 passcode/調整 passcode 結構後，把最新的設定當作主密碼
    func setLastPasscode() {
        guard !passcodes.isEmpty else {
            return
        }

        let level = passcodes.count - 1

        /// 已經是最後一層就不用做事
        guard currentPasscodeLevel != level else {
            return
        }

        currentPasscodeLevel = level
        syncState()
    }

    /// 依照輸入的 currentPasscode 來切換主層級（找到它在 passcodes 的 index）
    ///
    /// 用途：如果產品允許「多組主密碼」的概念（或 migration / 多 profile），可以切換目前生效的主密碼是哪一組
    func set(currentPasscode: String) {
        guard let level = passcodes.firstIndex(of: currentPasscode) else {
            return
        }

        guard currentPasscodeLevel != level else {
            return
        }

        currentPasscodeLevel = level
        syncState()
    }

    /// 設定/更新「主 passcode」
    /// - 只更新 currentPasscodeLevel 指向的那一格
    /// - 寫入 keychain 後再更新記憶體 passcodes
    func set(passcode: String) throws {
        var newPasscodes = passcodes

        newPasscodes[currentPasscodeLevel] = passcode

        try save(passcodes: newPasscodes)
        passcodes = newPasscodes
        syncState()
    }

    /// 移除「主 passcode」
    ///
    /// 這裡不只是把當前 passcode 清空：
    /// - 還會把陣列截斷到 currentPasscodeLevel + 1
    /// - 意味著：主 passcode 被移除時，後面的層級（包含 duress）也一起移除
    func removePasscode() throws {
        var newPasscodes = passcodes

        newPasscodes[currentPasscodeLevel] = ""
        newPasscodes = Array(newPasscodes.prefix(currentPasscodeLevel + 1))

        try save(passcodes: newPasscodes)
        passcodes = newPasscodes
        syncState()
    }

    /// 設定/更新 duress passcode
    ///
    /// duress 的位置固定是 currentPasscodeLevel + 1：
    /// - 如果已經存在下一層：覆寫它
    /// - 如果不存在：append 一個新層級
    func set(duressPasscode: String) throws {
        var newPasscodes = passcodes

        if newPasscodes.count > currentPasscodeLevel + 1 {
            newPasscodes[currentPasscodeLevel + 1] = duressPasscode
        } else {
            newPasscodes.append(duressPasscode)
        }

        try save(passcodes: newPasscodes)
        passcodes = newPasscodes
        syncState()
    }

    /// 移除 duress passcode
    ///
    /// 做法：直接把陣列截斷到 currentPasscodeLevel + 1
    /// - 也就是「只保留主 passcode 那層（含之前的層）」
    /// - 下一層（duress）直接被砍掉
    func removeDuressPasscode() throws {
        var newPasscodes = passcodes

        newPasscodes = Array(newPasscodes.prefix(currentPasscodeLevel + 1))

        try save(passcodes: newPasscodes)
        passcodes = newPasscodes
        syncState()
    }
}

