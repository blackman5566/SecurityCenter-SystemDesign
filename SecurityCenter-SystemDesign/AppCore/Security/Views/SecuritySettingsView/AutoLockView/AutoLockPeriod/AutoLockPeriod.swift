//
//  AutoLockPeriod.swift
//  SwiftUI_Wallet
//
//  Created by 許佳豪 on 2025/12/26.
//

import Foundation

/// AutoLockPeriod 定義 App 自動上鎖的時間策略
///
/// 設計目的：
/// - 將「自動鎖定時間」收斂成明確、有限的選項
/// - 作為 Security / Lock Policy 的一部分，避免散落 magic number
/// - 同時服務 UI 顯示（title）與實際邏輯（period）
///
/// 使用情境：
/// - App 進入背景
/// - 使用者一段時間未互動
/// - 依據設定時間決定是否進入鎖定狀態
///
/// 注意：
/// - `.immediate` 表示立即鎖定（TimeInterval = 0）
/// - 實際鎖定判斷通常由 LockManager / SecurityManager 負責
enum AutoLockPeriod: String, CaseIterable {

    /// 立即鎖定
    case immediate

    /// 1 分鐘後自動鎖定
    case minute1

    /// 5 分鐘後自動鎖定
    case minute5

    /// 15 分鐘後自動鎖定
    case minute15

    /// 30 分鐘後自動鎖定
    case minute30

    /// 1 小時後自動鎖定
    case hour1

    /// 顯示在 UI 上的標題文字（對應 Localizable.strings）
    ///
    /// 例：
    /// - auto_lock.immediate
    /// - auto_lock.minute1
    /// - auto_lock.hour1
    var title: String {
        lockMinute
    }

    /// 對應的鎖定時間（秒）
    ///
    /// 此值僅表示「多久後應該鎖定」，不直接負責鎖定行為
    /// 實際比較時間、判斷是否需要鎖定，應由上層管理者處理
    var period: TimeInterval {
        switch self {
        case .immediate: return 0
        case .minute1:   return 60
        case .minute5:   return 5 * 60
        case .minute15:  return 15 * 60
        case .minute30:  return 30 * 60
        case .hour1:     return 60 * 60
        }
    }
    
    var lockMinute: String {
        switch self {
        case .immediate: return "Immediate"
        case .minute1:   return "1 minute"
        case .minute5:   return "5 minutes"
        case .minute15:  return "15 minutes"
        case .minute30:  return "30 minutes"
        case .hour1:     return "1 hour"
        }
    }
}
