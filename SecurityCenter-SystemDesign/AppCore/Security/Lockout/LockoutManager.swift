//
//  Lockout.swift
//  SwiftUI_Wallet
//
//  Created by 許佳豪 on 2025/12/26.
//
import Foundation
import HsExtensions

/// LockoutManager：
/// 管理解鎖失敗次數與「暫時鎖定」(lockout) 的狀態
///
/// 目的：
/// - 防暴力破解（連猜 6 位數密碼）
/// - 輸錯到一定次數後，強制等待一段時間才能再試
///
/// 特點：
/// - unlockAttempts / lockTimestamp 都存 Keychain（非 UserDefaults）
///   → App 重開也會保留錯誤次數與鎖定狀態（更安全）
/// - 用 monotonic uptime（CLOCK_MONOTONIC_RAW）計時
///   → 避免使用者改系統時間來繞過鎖定
class LockoutManager {
    /// Keychain key：儲存解鎖失敗次數
    private let unlockAttemptsKey = "unlock_attempts_keychain_key"

    /// Keychain key：儲存上次「失敗/鎖定」的時間戳（使用 uptime）
    private let lockTimestampKey = "lock_timestamp_keychain_key"

    /// 允許的最大嘗試次數（未到這個數字前都不會 lockout）
    private let maxAttempts = 5

    private var keychainStorage: KeychainStorage

    /// 用 Timer 讓 UI 在 lockout 結束時自動更新狀態
    private var timer: Timer?

    /// 對外發布 lockout 狀態，UI 會依據它顯示：
    /// - unlocked：顯示輸入框/剩餘次數
    /// - locked：顯示「解鎖停用直到 XX:XX:XX」，並禁用輸入
    @PostPublished private(set) var lockoutState: LockoutState = .unlocked(attemptsLeft: 0, maxAttempts: 0)

    /// 解鎖失敗次數
    /// didSet：每次更新就寫入 Keychain
    private var unlockAttempts: Int {
        didSet {
            try? keychainStorage.set(value: unlockAttempts, for: unlockAttemptsKey)
        }
    }

    /// 上次失敗的時間（用 uptime 記錄，而不是 Date()）
    /// didSet：每次更新就寫入 Keychain
    private var lockTimestamp: TimeInterval {
        didSet {
            try? keychainStorage.set(value: lockTimestamp, for: lockTimestampKey)
        }
    }

    init(keychainStorage: KeychainStorage) {
        self.keychainStorage = keychainStorage

        /// 從 Keychain 讀取之前記錄的失敗次數 / lock timestamp
        /// - 沒有就預設 0 次
        /// - lockTimestamp 沒有就用目前 uptime（等於「現在」）
        unlockAttempts = keychainStorage.value(for: unlockAttemptsKey) ?? 0
        lockTimestamp = keychainStorage.value(for: lockTimestampKey) ?? Self.uptime

        /// 初始化後立刻計算並發布 lockoutState
        syncState()
    }

    /// uptime：取得「單調遞增」的裝置運行時間（秒）
    ///
    /// 為什麼不用 Date()？
    /// - Date() 受系統時間影響，使用者改時間可繞過 lockout
    /// - uptime 不受改時間影響（只跟裝置運行時間有關），更安全
    private static var uptime: TimeInterval {
        var uptime = timespec()
        clock_gettime(CLOCK_MONOTONIC_RAW, &uptime)
        return TimeInterval(uptime.tv_sec)
    }

    /// 根據 unlockAttempts 決定要鎖多久（退避策略）
    ///
    /// 規則：
    /// - 第 5 次（剛好等於 maxAttempts）：鎖 5 分鐘
    /// - 第 6 次：鎖 10 分鐘
    /// - 第 7 次：鎖 15 分鐘
    /// - 第 8 次以上：鎖 30 分鐘（最嚴格）
    private var lockoutInterval: TimeInterval {
        if unlockAttempts == maxAttempts {
            return 5 * 60
        } else if unlockAttempts == maxAttempts + 1 {
            return 10 * 60
        } else if unlockAttempts == maxAttempts + 2 {
            return 15 * 60
        } else {
            return 30 * 60
        }
    }
}

extension LockoutManager {

    /// 重新計算 lockoutState（核心）
    ///
    /// 你會在這些時機呼叫：
    /// - init 時
    /// - 每次輸入錯誤 didFailUnlock()
    /// - 解鎖成功 didUnlock()
    /// - Timer 到期（lockout 結束）
    func syncState() {
        /// 先停掉舊 Timer，避免重複排程
        timer?.invalidate()

        /// 1) 還沒達到 maxAttempts：不鎖
        if unlockAttempts < maxAttempts {
            /// attemptsLeft：還剩幾次可以錯
            lockoutState = .unlocked(attemptsLeft: maxAttempts - unlockAttempts, maxAttempts: maxAttempts)
        } else {
            /// 2) 已達 maxAttempts：開始 lockout
            /// timePast：距離上次失敗已經過了多久（用 uptime）
            let timePast = max(0, Self.uptime - lockTimestamp)
            let lockoutInterval = lockoutInterval

            /// 如果已經超過鎖定時間：恢復成 unlocked
            /// 注意：這裡 attemptsLeft = 1 的設計有點特別
            /// 代表「雖然解鎖了，但再錯一次可能又立刻進 lockout」
            if timePast > lockoutInterval {
                lockoutState = .unlocked(attemptsLeft: 1, maxAttempts: maxAttempts)
            } else {
                /// 尚未到期：仍 locked，計算解鎖時間點
                let timeInterval = lockoutInterval - timePast
                lockoutState = .locked(unlockDate: Date().addingTimeInterval(timeInterval))

                /// 排一個 Timer：到期時自動 refresh state（讓 UI 自動解除鎖定）
                timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
                    self?.syncState()
                }
            }
        }
    }

    /// 解鎖成功時呼叫：把錯誤次數歸零
    func didUnlock() {
        unlockAttempts = 0
        syncState()
    }

    /// 解鎖失敗時呼叫：錯誤次數 +1，並更新 lockTimestamp
    func didFailUnlock() {
        unlockAttempts += 1
        lockTimestamp = Self.uptime
        syncState()
    }
}

/// UI / ViewModel 會用到的 lockout 狀態
enum LockoutState {
    /// unlocked：可輸入，並告知還剩幾次可錯
    case unlocked(attemptsLeft: Int, maxAttempts: Int)

    /// locked：鎖到某個時間點（UI 顯示倒數/時間）
    case locked(unlockDate: Date)

    /// 是否鎖住（給 UI disable 按鍵用）
    var isLocked: Bool {
        switch self {
        case .unlocked: return false
        case .locked: return true
        }
    }

    /// 是否已經嘗試過（UI 可以用來決定要不要顯示提示/錯誤）
    var isAttempted: Bool {
        switch self {
        case let .unlocked(attemptsLeft, maxAttempts):
            return attemptsLeft != maxAttempts
        case .locked:
            return true
        }
    }
}
