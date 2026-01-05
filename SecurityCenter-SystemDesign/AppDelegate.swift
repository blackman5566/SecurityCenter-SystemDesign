//
//  AppDelegate.swift
//  SecurityCenter-SystemDesign
//
//  Created by 許佳豪 on 2026/1/5.
//

import Foundation
import UIKit

/// App 的 `UIApplicationDelegate`（在 SwiftUI `@main App` 架構下以 adaptor 方式掛載）。
///
/// 為什麼 SwiftUI 專案仍需要 AppDelegate：
/// - 某些系統級的 callback 只能透過 `UIApplicationDelegate` 取得（或在這裡處理最穩）
/// - 例如：限制 Extension Point（禁用第三方鍵盤）、Scene 設定與指定 SceneDelegate…等
///
/// 在本專案中，AppDelegate 主要負責兩件事：
/// 1) 禁用第三方鍵盤（安全/風控需求）
/// 2) 指定每個 Scene 連線時使用的 `UIWindowSceneDelegate`（AppSceneDelegate）
class AppDelegate: NSObject, UIApplicationDelegate {

    /// 是否允許某些系統 Extension Point（例如：第三方鍵盤）。
    ///
    /// 目的：
    /// - 基於安全性或資料保護需求（例如：防止第三方鍵盤記錄輸入）
    /// - 因此在此回傳 `false` 來禁用自訂鍵盤，只允許系統鍵盤。
    ///
    /// 注意：
    /// - 這個控制點屬於 UIKit delegate 層級，SwiftUI 本身沒有對等的入口。
    func application(_ application: UIApplication,
                     shouldAllowExtensionPointIdentifier extensionPointIdentifier: UIApplication.ExtensionPointIdentifier) -> Bool {
        // 禁用第三方鍵盤（.keyboard）
        if extensionPointIdentifier == .keyboard {
            return false
        }
        return true
    }

    /// 當系統要建立/連線一個新的 Scene（UIWindowScene）時，要求 App 回傳要使用的 Scene 設定。
    ///
    /// 目的：
    /// - 明確指定 Scene 生命週期由 `AppSceneDelegate` 處理
    /// - 讓我們能在 Scene 層級接到前後台/活躍狀態變化，並取得 `UIWindowScene`
    ///   以提供給 Core 的 manager（例如 cover/lock overlay）
    ///
    /// 注意：
    /// - 在 iPad 多視窗（multi-scene）環境下，這個方法可能會被呼叫多次。
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {

        // 建立 Scene 設定（sessionRole 由系統給定，通常是 .windowApplication）
        let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        // 強制指定 SceneDelegate，讓 Scene lifecycle 能進到 AppSceneDelegate
        sceneConfig.delegateClass = AppSceneDelegate.self
        return sceneConfig
    }
}
