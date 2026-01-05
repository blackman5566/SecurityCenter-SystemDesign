//
//  AppSceneDelegate.swift
//  SecurityCenter-SystemDesign
//
//  Created by 許佳豪 on 2026/1/5.
//

import Foundation
import SwiftUI

/// App 的 `UIWindowSceneDelegate`，負責將 UIKit 的 Scene 生命週期
/// 橋接（bridge）到 Core 層的各個 Manager。
///
/// 為什麼在 SwiftUI App 架構下仍然需要這個類別：
/// - 專案使用 SwiftUI 的 `@main App` 作為入口，但某些系統生命週期事件
///   以及 `UIWindowScene` 的存取，在 UIKit 的 delegate 中仍然最穩定、最直接。
/// - 此類別主要負責：
///   1. 取得並保存目前的 `UIWindowScene`，提供給需要操作 window / overlay 的 manager
///   2. 將 scene 前後台、啟用/停用事件轉交給 `Core.shared.appManager`
///   3. 在進入背景時啟動 background task，確保關鍵流程能安全完成
///
/// 注意事項：
/// - 本 delegate 是由 `AppDelegate` 中的
///   `application(_:configurationForConnecting:options:)` 指定使用。
/// - 在 iPad 多視窗（multi-scene）環境下，可能會同時存在多個 scene，
///   manager 端需自行確保行為正確。
class AppSceneDelegate: NSObject, UIWindowSceneDelegate {

    /// 背景任務識別碼，用來向系統請求額外的背景執行時間
    /// `.invalid` 代表目前沒有正在執行的背景任務
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid

    /// 當系統建立並連接新的 Scene 時呼叫
    ///
    /// 此時可以安全地取得 `UIWindowScene`，並交給需要操作視窗層級的 manager。
    ///
    /// 常見用途：
    /// - 顯示/隱藏全畫面遮罩（例如隱私保護、鎖定畫面）
    /// - 控制跨 scene 的 UI 行為
    ///
    /// - 重要提醒：
    ///   在支援多視窗的裝置上，可能會被呼叫多次。
    func scene(_ scene: UIScene,
               willConnectTo _: UISceneSession,
               options _: UIScene.ConnectionOptions) {
        let windowScene = scene as? UIWindowScene

        // 將目前的 UIWindowScene 提供給需要 window 操作權限的 manager
        AppCore.shared.security.coverManager.windowScene = windowScene
        AppCore.shared.security.lockManager.windowScene = windowScene
    }

    /// 當 Scene 進入背景（background）時呼叫
    ///
    /// 在這裡我們會：
    /// 1. 通知 appManager 進入背景狀態（例如儲存資料、停止計時器）
    /// 2. 啟動 background task，向系統請求短暫的額外時間，
    ///    以確保重要工作能在 App 被暫停前完成
    func sceneDidEnterBackground(_: UIScene) {
        AppCore.shared.security.lockManager.didEnterBackground()
        
//        這段是在 App 進入背景（Home 鍵、切到別的 App、鎖屏）那一刻，跟 iOS 「借一點時間」 讓你把「收尾工作」做完，不要立刻被系統停掉。
//        你可以把它想成：
//        App 要被請出場了，你跟系統說：「等一下，我還要 10~30 秒（不保證）把事情收一收。」
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            guard let self else { return }
            UIApplication.shared.endBackgroundTask(self.backgroundTask)
            self.backgroundTask = .invalid
        }
    }

    /// 當 Scene 從背景即將回到前景時呼叫
    ///
    /// 在這裡我們會：
    /// 1. 通知 appManager 準備回到前景
    /// 2. 主動結束背景任務，避免背景時間被無意義佔用
    func sceneWillEnterForeground(_: UIScene) {
        AppCore.shared.security.coverManager.willEnterForeground()
        AppCore.shared.security.lockManager.willEnterForeground()
        AppCore.shared.security.passcodeLockManager.handleForeground()
        AppCore.shared.security.lockManager.willEnterForeground()
        
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }

    /// 當 Scene 變成可互動狀態（active）時呼叫
    ///
    /// 常見用途：
    /// - 恢復動畫與計時器
    /// - 重新整理 UI 或敏感狀態
    func sceneDidBecomeActive(_: UIScene) {
        AppCore.shared.security.coverManager.didBecomeActive()
    }

    /// 當 Scene 即將從 active 變為 inactive 時呼叫
    ///
    /// 可能發生的情境：
    /// - 來電或系統彈窗
    /// - 使用者切換 App
    ///
    /// 常見用途：
    /// - 暫停進行中的任務
    /// - 為即將的中斷做準備
    func sceneWillResignActive(_: UIScene) {
        AppCore.shared.security.coverManager.willResignActive()
    }
}
