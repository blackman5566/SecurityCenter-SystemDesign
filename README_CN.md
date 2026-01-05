# Security Center－模組化安全子系統（SwiftUI）

## 專案概覽

**Security 不是一個畫面，而是一個系統。**

本專案是一套以 SwiftUI 實作的 **錢包型應用 Security Center 安全子系統**。  
設計時刻意避免將安全邏輯分散在各個 UI 畫面，而是把「安全」視為一個 **一級系統（first-class subsystem）**，具備清楚的責任邊界、可擴充的架構，以及狀態驅動的行為模型。

UI 刻意保持簡單，它只是 **系統狀態的投影**。  
真正的複雜度存在於底層：安全規則、狀態轉換與策略協調。

---

## Demo  

<p align="center">
  <img 
    src="https://github.com/blackman5566/SecurityCenter-SystemDesign/blob/main/demo.gif" 
    alt="SecurityCenter-SystemDesign Demo" 
    width="320"
  />
</p>

---

## 核心功能

- **密碼（Passcode）生命週期**
  - 建立 / 修改 / 停用密碼
- **生物識別解鎖**
  - 支援 Face ID / Touch ID
- **隨機鍵盤**
  - 防止側錄與偷看（Shoulder Surfing）
- **自動上鎖策略**
  - 立即 / 1 分鐘 / 5 分鐘 / 15 分鐘 / 30 分鐘 / 1 小時
- **錯誤次數限制與鎖定**
  - 可設定嘗試次數
  - 超過限制後暫時鎖定
- **背景保護機制**
  - App 進入背景時自動顯示遮罩（Cover View）
- **統一解鎖流程**
  - 密碼、生物識別與 fallback 流程集中處理

---

## 架構設計

本專案將安全邏輯建模為獨立的 **Domain Layer**，而非 UI 導向實作。

```
Security
├─ PasscodeManager        // 密碼建立、驗證與生命週期
├─ BiometryManager        // Face ID / Touch ID 管理
├─ LockManager            // 上鎖 / 解鎖狀態管理
├─ LockoutManager         // 嘗試次數與冷卻鎖定策略
├─ CoverManager           // 背景遮罩與隱私保護
├─ CoreSecurity           // 中央安全 Gate 與策略協調者
└─ Views / ViewModels     // 狀態驅動的 UI 呈現層
```

---

## 設計原則

- **單一責任（Single Responsibility）**
  - 每一項安全能力由獨立 Manager 負責
- **依賴注入（Dependency Injection）**
  - 模組之間透過 protocol 與注入互動，避免隱性耦合
- **狀態驅動 UI（State-driven UI）**
  - UI 只訂閱狀態，不自行推導安全行為
- **集中式策略控管**
  - 所有敏感操作統一經過 `CoreSecurity`

---

## 為什麼這樣設計？

安全需求往往會隨產品成長而持續堆疊，若缺乏邊界與 ownership，系統將快速變得脆弱且難以維護。

透過將安全視為一個子系統，可以：

- 在不修改既有 UI 的情況下新增安全策略
- 確保規則一致，避免各頁自行實作導致漏洞
- 讓系統在複雜度提升時仍保持可預期行為
- 提升測試性與可理解性

---

## 核心體會

> 在 AI 大幅加速實作的時代，  
> **系統邊界與責任劃分的設計能力，才是真正的差異化。**

---

## 備註

- 本專案重點在於 **系統設計與架構思維**
- UI 僅作為狀態呈現，非設計重點
- 架構設計以錢包 / 金融級安全需求為目標

---

