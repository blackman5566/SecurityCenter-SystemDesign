//
//  EditPasscodeViewModel.swift
//  SwiftUI_Wallet
//
//  Created by 許佳豪 on 2025/12/26.
//

import Combine

/// 編輯「主 Passcode」的 ViewModel
///
/// 這個類別採用「共用流程 + 覆寫文案/行為」的方式：
/// - SetPasscodeViewModel：負責整個輸入流程（輸入舊密碼 → 輸入新密碼 → 確認新密碼 → 完成）
/// - EditPasscodeViewModel：只負責
///   1) 提供本頁的文案（title/description）
///   2) 定義「如何驗證目前密碼」
///   3) 定義「輸入完成後要做什麼」（寫入 passcode、通知完成）
///
/// 好處：
/// - UI（SetPasscodeView）可以共用
/// - 流程狀態機可以共用（在父類）
/// - 不同情境（新增/編輯/duress）只要做小量覆寫即可
class EditPasscodeViewModel: SetPasscodeViewModel {

    /// 導航標題：編輯密碼
    /// - 由子類提供情境文案，讓共用 UI 不需要寫 if/else
    override var title: String {
        "Edit Passcode"
    }

    /// 使用者輸入新密碼時的提示文字
    override var passcodeDescription: String {
        "Enter new passcode"
    }

    /// 使用者確認新密碼時的提示文字
    override var confirmDescription: String {
        "Confirm"
    }

    /// 驗證「目前密碼」是否正確
    ///
    /// - Parameter passcode: 使用者輸入的「舊密碼」
    /// - Returns: 是否與目前生效的主密碼一致
    ///
    /// 用途：SetPasscodeViewModel 的流程中通常會先要求輸入「目前密碼」
    /// 才能進入「輸入新密碼」的步驟，這裡就是定義那個驗證規則。
    override func isCurrent(passcode: String) -> Bool {
        passcodeManager.isValid(passcode: passcode)
    }

    /// 使用者已完成「輸入新密碼」並通過確認後的 callback
    ///
    /// - Parameter passcode: 最終確認過的新密碼
    ///
    /// 行為：
    /// 1) 呼叫 passcodeManager 更新主密碼（持久化到 keychain）
    /// 2) 成功後發送 finishSubject，通知 View 關閉或導回上一頁
    ///
    /// 注意：
    /// - 這裡用 do/catch 是因為 set(passcode:) 可能丟出 keychain 寫入失敗等錯誤
    override func onEnter(passcode: String) {
        do {
            /// 寫入新主密碼（更新 currentPasscodeLevel 指向的那層）
            try passcodeManager.set(passcode: passcode)

            /// 通知流程完成（通常 View 會收到後 dismiss / pop）
            finishSubject.send()
        } catch {
            /// TODO: 正式產品建議改成：
            /// - 顯示錯誤 Toast / Alert
            /// - 或透過 errorSubject / state 發給 View 呈現
            print("Edit Passcode Error: \(error)")
        }
    }
}
