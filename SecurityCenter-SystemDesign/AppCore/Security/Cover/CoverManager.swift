//
//  CoverManager.swift
//  SwiftUI_Wallet
//
//  Created by 許佳豪 on 2025/12/26.
//

import SwiftUI

/// CoverManager：
/// 用「額外 UIWindow」在 App 即將進入非活躍狀態時（例如切到背景、叫出 App Switcher）
/// 蓋上一層 CoverView，避免敏感畫面被系統截圖/在多工畫面被看到。
///
/// 跟 LockManager 的差別：
/// - LockManager：是真的「上鎖」，需要解鎖才能回到 app
/// - CoverManager：只是「遮罩」，回到前景就移除，不涉及解鎖
class CoverManager {
    /// 需要 scene 才能建立 overlay window
    var windowScene: UIWindowScene?

    /// 覆蓋用的 window（只用來遮畫面）
    private var window: UIWindow?

    /// 依賴 LockManager：
    /// - 如果 app 已經鎖住（有解鎖畫面），就不需要再加一層 cover
    private let lockManager: LockManager

    init(lockManager: LockManager) {
        self.lockManager = lockManager
    }

    /// App 即將失去 active（例如按 Home、切 app、進 App Switcher、來電等）時呼叫
    ///
    /// 目的：在系統切換畫面/截圖之前，先把敏感畫面蓋掉
    func willResignActive() {
        /// guard 防呆：
        /// 1) 必須有 windowScene 才能建立 UIWindow
        /// 2) window == nil：避免重複建立 cover window
        /// 3) !lockManager.isLocked：如果已經鎖住（顯示解鎖 overlay）就不用再蓋 cover
        guard let windowScene, window == nil, !lockManager.isLocked else {
            return
        }

        /// 建立 cover window
        let window = UIWindow(windowScene: windowScene)

        /// windowLevel = alert - 2：
        /// - 讓它比一般 app window 高（能覆蓋）
        /// - 但又低於 LockManager 的解鎖 overlay（LockManager 用 alert - 1）
        ///   => 這樣「鎖 > 遮罩」
        window.windowLevel = UIWindow.Level.alert - 2

        /// 顯示 window
        window.isHidden = false

        /// 初始透明，用淡入動畫讓切換更自然
        window.alpha = 0

        /// 用 SwiftUI 畫面當作遮罩（通常是一張品牌圖、模糊、純色背景）
        let hostingController = UIHostingController(rootView: CoverView())
        window.rootViewController = hostingController

        /// 淡入動畫
        UIView.animate(withDuration: 0.15) {
            window.alpha = 1
        }

        /// 持有 window，避免被釋放
        self.window = window
    }

    /// App 回到 active 時呼叫（從背景/切回來）
    /// 目的：把遮罩淡出移除，回到正常畫面
    func didBecomeActive() {
        /// 沒有 cover window 就不用處理
        guard window != nil else {
            return
        }

        /// 淡出動畫後釋放 window
        UIView.animate(withDuration: 0.15, animations: {
            self.window?.alpha = 0
        }) { _ in
            self.window = nil
        }
    }

    /// App 即將進入前景時呼叫
    ///
    /// 直接把 window 設 nil：
    /// - 這是個保險：避免在某些狀態切換順序下，cover window 還殘留
    /// - 但注意：這樣會「瞬間移除」而非動畫（不過通常看不到）
    func willEnterForeground() {
        window = nil
    }
}

struct CoverView: View {
    var body: some View {
            VStack(spacing:24) {
                Text("SecurityCenter-SystemDesign")
                    .font(.system(size: 34, weight: .bold))
                    .multilineTextAlignment(.center)
        }
    }
}
