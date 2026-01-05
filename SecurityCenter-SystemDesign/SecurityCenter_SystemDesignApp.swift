//
//  SecurityCenter_SystemDesignApp.swift
//  SecurityCenter-SystemDesign
//
//  Created by 許佳豪 on 2026/1/1.
//

import SwiftUI

@main
struct SecurityCenter_SystemDesignApp: App {
    @UIApplicationDelegateAdaptor var appDelegate: AppDelegate
    private let initResult: Result<Void, Error>
    
    init() {
        do {
            // 核心初始化：建立 Core singleton、讀取設定、準備 services 等
            try AppCore.initApp()

            // 通知 appManager：啟動完成（相當於 didFinishLaunching 之後的自家流程）
            AppCore.shared.storage.keychainManager.handleLaunch()
            
            initResult = .success(())
        } catch {
            // 初始化失敗：記錄錯誤狀態，交由 UI 顯示錯誤頁
            initResult = .failure(error)
        }
    }
    
    var body: some Scene {
        WindowGroup {
            switch initResult {
            case .success:
                // 初始化成功 → 進入 App 主流程
                NavigationStack {
                    SecuritySettingsModule.view()
                }.modifier(CoordinatorViewModifier())
            case let .failure(error):
                // 初始化失敗 → 顯示錯誤畫面（可加入 retry / 診斷資訊）
                Text("初始化失敗 → 顯示錯誤畫面（可加入 retry / 診斷資訊）")
            }
        }
    }
}
