//
//  LockManager.swift
//  SwiftUI_Wallet
//
//  Created by 許佳豪 on 2025/12/26.
//

import Combine
import Foundation
import HsExtensions
import SwiftUI

/// 管理 App 自動上鎖 / 解鎖的流程（通常用於錢包等敏感 App）
///
/// 核心概念：
/// 1) 當 App 進入背景時，記錄「離開時間」
/// 2) 當 App 回到前景時，檢查距離離開是否超過 autoLockPeriod
///    - 若超過：顯示解鎖畫面（鎖定）
/// 3) 解鎖成功後：移除覆蓋用 Window
class LockManager {
    /// UserDefaults key：記錄上次離開 App 的時間（unix timestamp）
    private let lastExitDateKey = "last_exit_date_key"

    /// UserDefaults key：使用者設定的自動上鎖時間區間
    private let autoLockPeriodKey = "auto-lock-period"

    /// 管理密碼/解鎖能力（是否設定 passcode、驗證 passcode 等）
    private let passcodeManager: PasscodeManager

    /// 封裝 UserDefaults 的 storage（方便替換、測試或做統一的 get/set）
    private let userDefaultsStorage: UserDefaultsStorage

    /// 對外只讀：目前是否處於鎖定狀態
    ///
    /// @DistinctPublished：代表這是一個「只有在值真的改變時才會發送」的 Publisher
    /// 避免重複 assign 相同的值造成 UI / 監聽者重複刷新
    @DistinctPublished private(set) var isLocked: Bool

    /// 需要拿到 windowScene 才能建立一個新的 UIWindow 來覆蓋全畫面（顯示解鎖頁）
    ///
    /// didSet 立刻 lock()：
    /// - 一旦 scene 可用，就嘗試把解鎖 overlay 架起來（若有設定 passcode）
    /// - 這樣能確保「畫面一出現就先鎖住」，避免短暫露出敏感內容
    var windowScene: UIWindowScene? {
        didSet {
            lock()
        }
    }

    /// 用來覆蓋整個 App 的 overlay window（顯示 AppUnlockView）
    ///
    /// 注意：用「額外 window」來鎖是很常見的錢包做法：
    /// - 不依賴你當前導航/頁面狀態
    /// - 直接用最高層覆蓋，避免敏感畫面閃一下
    private var window: UIWindow?

    /// 使用者設定的自動上鎖時間
    ///
    /// didSet 立刻存入 UserDefaults：
    /// - 讓下次啟動 app 能恢復此設定
    var autoLockPeriod: AutoLockPeriod {
        didSet {
            userDefaultsStorage.set(value: autoLockPeriod.rawValue, for: autoLockPeriodKey)
        }
    }

    init(passcodeManager: PasscodeManager, userDefaultsStorage: UserDefaultsStorage) {
        self.passcodeManager = passcodeManager
        self.userDefaultsStorage = userDefaultsStorage

        /// 初始鎖定狀態：
        /// - 如果使用者有設定 passcode，那一開始就視為 locked（需要解鎖）
        isLocked = passcodeManager.isPasscodeSet

        /// 讀取使用者設定的 autoLockPeriod；若沒有就預設 1 分鐘
        let autoLockPeriodRaw: String? = userDefaultsStorage.value(for: autoLockPeriodKey)
        autoLockPeriod = autoLockPeriodRaw.flatMap { AutoLockPeriod(rawValue: $0) } ?? .minute1
    }
}

extension LockManager {

    /// App 進入背景（sceneDidEnterBackground / applicationDidEnterBackground）時呼叫
    ///
    /// 目的：記錄「離開的時間點」，等回前景再判斷是否需要鎖
    func didEnterBackground() {
        /// 如果本來就鎖著了，就不用再記錄時間（避免干擾）
        guard !isLocked else {
            return
        }

        /// 用 unix timestamp 記錄離開時間
        userDefaultsStorage.set(value: Date().timeIntervalSince1970, for: lastExitDateKey)
    }

    /// App 準備回到前景（sceneWillEnterForeground / applicationWillEnterForeground）時呼叫
    ///
    /// 目的：檢查距離離開多久，超過設定就 lock()
    func willEnterForeground() {
        /// 如果已經鎖著，就不用重複 lock
        guard !isLocked else {
            return
        }

        /// 讀取上次離開時間；若沒有就用 0（會讓 now - 0 很大 → 幾乎必鎖）
        /// 這是一種「偏安全」的 default：缺資料就當作很久沒用 → 直接鎖
        let exitTimestamp: TimeInterval = userDefaultsStorage.value(for: lastExitDateKey) ?? 0
        let now = Date().timeIntervalSince1970

        /// 若尚未超過 autoLockPeriod，就不鎖，讓使用者直接回到 app
        guard now - exitTimestamp > autoLockPeriod.period else {
            return
        }

        /// 超過指定時間 → 立刻鎖
        lock()
    }

    /// 進入鎖定狀態：顯示解鎖 UI（覆蓋整個 app）
    private func lock() {
        /// 若使用者根本沒設定 passcode，就不做鎖定（沒有解鎖依據）
        guard passcodeManager.isPasscodeSet else {
            return
        }

        /// 先把狀態設成 locked（外部監聽者可立刻知道進入鎖定）
        isLocked = true

        /// 防呆：
        /// 1) 必須要有 windowScene 才能建立 UIWindow
        /// 2) window == nil 才需要建立新的 overlay window（避免重複建立好幾個）
        guard let windowScene, window == nil else {
            return
        }

        /// 建立 overlay window，掛在同一個 windowScene 下
        let window = UIWindow(windowScene: windowScene)

        /// windowLevel 設成 alert - 1：
        /// - 讓它比一般 app window 高（能覆蓋）
        /// - 但又略低於系統最頂層 alert（避免蓋掉系統級提示）
        window.windowLevel = UIWindow.Level.alert - 1

        /// 顯示這個 window（一旦 isHidden = false，就會出現在畫面上）
        window.isHidden = false

        /// 使用 SwiftUI 畫面當作 rootViewController
        /// AppUnlockView：你的解鎖畫面（輸入 passcode / biometric 等）
        let hostingController = UIHostingController(rootView: AppUnlockView())
        window.rootViewController = hostingController

        /// 持有 window，讓它不會被釋放（否則會立刻消失）
        self.window = window
    }

    /// 解鎖成功後呼叫：移除 overlay window，回到原本 app
    func unlock() {
        /// 先更新狀態
        isLocked = false

        /// 沒有 overlay window 就不用處理
        guard window != nil else {
            return
        }

        /// 淡出動畫（0.15 秒），讓解鎖過渡更自然
        UIView.animate(withDuration: 0.15, animations: {
            self.window?.alpha = 0
        }) { _ in
            /// 釋放 window：移除覆蓋，畫面回到原 app window
            self.window = nil
        }
    }
}
