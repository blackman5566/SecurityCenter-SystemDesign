//
//  PasscodeLockManager.swift
//  SwiftUI_Wallet
//
//  Created by 許佳豪 on 2025/12/26.
//

//
//  PasscodeLockManager.swift
//  SwiftUI_Wallet
//
//  Created by 許佳豪 on 2025/12/26.
//

import HsExtensions
import LocalAuthentication

/// 裝置層級鎖定狀態（Device Passcode / FaceID/TouchID 是否可用）
///
/// 注意：這裡的「passcode」指的是 **iPhone 系統的裝置密碼**，不是 App 內的 passcode。
/// 用途：
/// - 當裝置沒有設定系統鎖（或生物辨識/裝置認證不可用）時，
///   視為裝置安全性不足，應採取保護措施（例如清除敏感資料、要求重新登入/重設錢包）。
enum PasscodeLockState {
    /// 裝置可進行 device owner authentication（通常代表有設定系統密碼，且能使用 FaceID/TouchID/裝置密碼）
    case passcodeSet

    /// 明確判定「裝置沒有設定系統密碼」
    case passcodeNotSet

    /// 無法判定（可能是系統錯誤、政策限制、或 LAError 非預期狀況）
    case unknown
}

/// 監測「裝置是否仍維持安全狀態」的管理者
///
/// 核心概念：
/// - App 內敏感資料（錢包 seed / key reference / session 等）
///   的安全前提之一，是裝置本身必須有基本鎖定能力（device passcode）。
/// - 一旦裝置層級的 passcode 被移除（或裝置認證不可用），
///   App 應該將其視為「Secure Storage Invalidation」並做出反應。
///
/// 實作方式：
/// - 透過 `LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, ...)`
///   判斷是否能做 device owner authentication
/// - 若不行，再從 `LAError` 判斷是否為 `.passcodeNotSet`
///
/// 更新時機：
/// - init 時檢查一次
/// - App 回到前景時重新檢查（handleForeground）
final class PasscodeLockManager {

    /// 以 Published 方式提供狀態給 UI / 上層協調者觀察
    /// - 使用 DistinctPublished 避免重複相同狀態造成不必要的更新
    @DistinctPublished private(set) var state: PasscodeLockState = .passcodeSet {
        didSet {
            // 裝置層級安全性不足時的保護反應：
            // 只有在明確判定「裝置未設定系統密碼」時才觸發清理。
            // 其他 unknown 狀態先不要做破壞性行為（避免誤判造成資料被清）。
            switch state {
            case .passcodeNotSet:
                onSecureStorageInvalidation()
            default:
                break
            }
        }
    }

    init() {
        // 初始化時先檢查一次裝置鎖狀態，確保一開始狀態就正確
        state = resolveState()
    }

    // MARK: - Security Reaction

    /// 當裝置不再安全（例如系統密碼被移除）時，做資料保護措施
    ///
    /// 範例反應（依產品需求擇一或組合）：
    /// - 清除本地敏感狀態（帳戶列表、解鎖狀態）
    /// - 清除/失效化 Keychain reference（或要求重新登入/重新匯入）
    /// - 將 App 轉入 locked / onboarding 狀態
    ///
    /// 注意：不要在 unknown 狀態就清，避免誤判導致使用者資料被刪。
    private func onSecureStorageInvalidation() {
        // accountManager.clear()
        // walletManager.clearWallets()
    }

    /// 解析目前裝置是否具備 device owner authentication 能力
    ///
    /// `.deviceOwnerAuthentication` 意義：
    /// - 允許使用 FaceID/TouchID
    /// - 也允許在需要時 fallback 到「iPhone 裝置密碼」
    /// - 因此若 canEvaluatePolicy 成功，通常代表裝置有設定 passcode（或至少可完成裝置認證）
    ///
    /// 回傳：
    /// - `.passcodeSet`：可進行 device owner authentication
    /// - `.passcodeNotSet`：明確判斷裝置沒有設定系統密碼
    /// - `.unknown`：其他不可判定情況
    private func resolveState() -> PasscodeLockState {
        var error: NSError?

        // 只做能力檢查，不進行實際驗證（evaluate）
        // 這裡只需要知道「裝置是否具備基本鎖定能力」，以決定是否要保護資料。
        if LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            return .passcodeSet
        }

        // 若不能 evaluate，嘗試從 error 判斷原因
        if let laError = error as? LAError {
            switch laError.code {
            case .passcodeNotSet:
                return .passcodeNotSet
            default:
                break
            }
        }

        return .unknown
    }
}

// MARK: - Lifecycle Hook

extension PasscodeLockManager {

    /// App 回到前景時呼叫，用來重新檢查裝置鎖定能力
    ///
    /// 背景期間使用者可能：
    /// - 進設定把 iPhone passcode 移除
    /// - 變更 FaceID/TouchID 設定
    /// 因此需要在 foreground 時同步狀態
    func handleForeground() {
        state = resolveState()
    }
}
