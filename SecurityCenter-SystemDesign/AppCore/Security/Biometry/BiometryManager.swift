//
//  Biometry.swift
//  SwiftUI_Wallet
//
//  Created by 許佳豪 on 2025/12/26.
//

import Combine
import HsExtensions
import LocalAuthentication

/// BiometryManager：
/// 1) 偵測裝置支援的生物辨識類型（FaceID / TouchID / none）
/// 2) 管理使用者的生物辨識啟用設定（off/manual/on）
/// 3) 將設定持久化到 UserDefaults
class BiometryManager {
    ///只存 Bool（true/false）代表是否開啟生物辨識
    /// 新版 key：存 enum 的 rawValue（off/manual/on）
    private let biometricEnabledTypeKey = "biometric_enabled_type_key"

    private let userDefaultsStorage: UserDefaultsStorage

    /// 用來持有 async Task（避免 Task 被釋放/取消）
    /// AnyTask 是 HsExtensions 裡常見的 Task wrapper（用於 store(in:) 管理生命週期）
    private var tasks = Set<AnyTask>()

    /// 目前裝置支援的生物辨識型別（FaceID/TouchID/none）
    /// @PostPublished：通常代表「會在主執行緒發送」，適合 UI 綁定（類似 @Published + main thread）
    @PostPublished var biometryType: BiometryType?

    /// 生物辨識啟用模式（off/manual/on）
    /// didSet：每次改變都寫入 UserDefaults
    @PostPublished var biometryEnabledType: BiometryEnabledType {
        didSet {
            userDefaultsStorage.set(value: biometryEnabledType.rawValue, for: biometricEnabledTypeKey)
        }
    }

    init(userDefaultsStorage: UserDefaultsStorage) {
        self.userDefaultsStorage = userDefaultsStorage

        // MARK: - Load 設定
        // 從新 key 讀取 enum rawValue；沒有就預設 off
        let value: String? = userDefaultsStorage.value(for: biometricEnabledTypeKey)
        biometryEnabledType = value.flatMap { BiometryEnabledType(rawValue: $0) } ?? .off

        // MARK: - 偵測裝置支援的 biometry 類型
        refreshBiometry()
    }

    /// 重新偵測裝置的生物辨識能力（FaceID/TouchID/none）
    ///
    /// 這裡使用 LocalAuthentication：
    /// - canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, ...)
    ///   可以評估 -> 表示裝置支援且可用生物辨識
    ///   不行 -> none
    private func refreshBiometry() {
        Task { [weak self] in
            var authError: NSError?
            let localAuthenticationContext = LAContext()

            if localAuthenticationContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
                switch localAuthenticationContext.biometryType {
                case .faceID:
                    self?.biometryType = .faceId
                case .touchID:
                    self?.biometryType = .touchId
                default:
                    /// 有些情況下 canEvaluatePolicy true，但 biometryType 仍可能是 none/unknown
                    self?.biometryType = .none
                }
            } else {
                /// 無法使用生物辨識（可能未設定、被限制、暫時不可用）
                self?.biometryType = .none
            }
        }.store(in: &tasks)  // 持有 Task 的生命週期，避免被取消
    }
}

extension BiometryManager {

    /// 生物辨識啟用模式（比單純 Bool 更有產品彈性）
    enum BiometryEnabledType: String, CaseIterable {
        /// 完全關閉生物辨識
        case off

        /// 手動：通常代表「需要我在某個操作時手動觸發」，不是自動跳出
        /// 例：使用者按解鎖按鈕才用 FaceID
        case manual

        /// 自動：通常代表「進入需要解鎖的流程就自動嘗試生物辨識」
        case on

        /// 是否有啟用（manual/on 都算）
        var isEnabled: Bool {
            self != .off
        }

        /// 是否屬於自動模式（只有 on 算）
        var isAuto: Bool {
            self == .on
        }

        /// UI 顯示用標題（走 localization key）
        var title: String {
            switch self {
            case .off: return "Off"
            case .manual: return "Manual"
            case .on: return "On"
            }
        }

        /// UI 顯示用描述（走 localization key）
        var description: String {
            switch self {
            case .off: return "Disabled in all cases"
            case .manual: return "Scanning with the button"
            case .on: return "Automatic scanning"
            }
        }
    }
}
