//
//  AppUnlockViewModel.swift
//  SwiftUI_Wallet
//
//  Created by 許佳豪 on 2025/12/26.
//

import Combine

/// AppUnlockViewModel（App 啟動/回到前景時的解鎖 ViewModel）
///
/// 繼承 BaseUnlockViewModel 來共用：
/// - passcode 輸入流程（輸入滿 6 位自動驗證）
/// - lockout（錯誤次數/限制）
/// - biometry 可用性計算與自動觸發（onAppear）
///
/// 本類只負責定義「App 解鎖」這個情境下：
/// 1) 什麼叫做密碼正確（isValid）
/// 2) 密碼正確後要做什麼（onEnterValid）
/// 3) 生物辨識成功後要做什麼（onBiometryUnlock）
class AppUnlockViewModel: BaseUnlockViewModel {

    /// App 層級的 Lock 管理（控制整個 App 的鎖定/解鎖狀態）
    /// - 目前從 AppCore.shared 取得（之後可改成 init 注入以提升可測試性）
    private let lockManager = AppCore.shared.security.lockManager

    /// 判斷輸入的 passcode 是否有效
    ///
    /// App 解鎖的規則：
    /// - 只要 passcode 存在於 passcodes 任一層，就視為有效
    ///
    /// 注意：
    /// - 這裡用 `has`（contains）代表允許「輸入任何一層的 passcode 都能解鎖」
    /// - 若你想更嚴格（只允許 currentPasscodeLevel 那層解鎖），就應改用 isValid(passcode:)
    override func isValid(passcode: String) -> Bool {
        passcodeManager.has(passcode: passcode)
    }

    /// 使用者輸入 passcode 且驗證成功後的處理
    ///
    /// 行為：
    /// 1) 把「輸入的 passcode」設成 currentPasscodeLevel（切換目前生效的主密碼層）
    /// 2) 呼叫 lockManager.unlock() 解鎖 App
    override func onEnterValid(passcode: String) {
        /// 將目前主密碼層切到使用者輸入的那一層
        /// - 這讓後續的「主密碼驗證」以這一層為準
        passcodeManager.set(currentPasscode: passcode)

        /// 解鎖 App（通常會解除遮罩/回到主畫面）
        lockManager.unlock()
    }

    /// 生物辨識解鎖成功後的處理
    ///
    /// 行為：
    /// 1) 直接把 currentPasscodeLevel 切到最後一層（視為目前生效主密碼）
    /// 2) 解鎖 App
    ///
    /// 注意：
    /// - 這裡的策略是「biometry 成功 → 使用最後一層作為主密碼」
    /// - 這個策略需與 PasscodeManager 的模型一致（你前面也預設 last 為主）
    override func onBiometryUnlock() {
        passcodeManager.setLastPasscode()
        lockManager.unlock()
    }
}
