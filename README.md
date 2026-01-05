<div align="left">
  <a href="README_CN.md"><img alt="中文" src="https://img.shields.io/badge/Documentation-中文-blue"></a>
</div>

# Security Center – Modular Security Subsystem (SwiftUI)

## Overview

**Security is not a screen — it’s a system.**

This project is a **wallet-style Security Center subsystem** built with SwiftUI.
Instead of treating security as a collection of UI settings, it is designed as a **first-class subsystem** with clear ownership, explicit boundaries, and state-driven behavior.

The UI is intentionally simple — it is merely a **projection of system state**.
The real complexity lives underneath, where security rules, state transitions, and policies are modeled explicitly.

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

## Key Features

- **Passcode lifecycle**
  - Create / Edit / Disable passcode
- **Biometric authentication**
  - Face ID / Touch ID support
- **Randomized keypad**
  - Protects against shoulder-surfing attacks
- **Auto-lock policies**
  - Immediate / 1 min / 5 min / 15 min / 30 min / 1 hour
- **Retry limits & lockout**
  - Limited attempts
  - Temporary lock after excessive failures
- **Secure background protection**
  - Automatic cover view when app enters background
- **Unified unlock flow**
  - Centralized handling for passcode, biometric, and fallback paths

---

## Architecture

This project models security as an independent **domain layer**, not UI-driven logic.

```
Security
├─ PasscodeManager        // Passcode creation, validation, lifecycle
├─ BiometryManager        // Face ID / Touch ID handling
├─ LockManager            // Lock / unlock state
├─ LockoutManager         // Retry limits & cooldown policy
├─ CoverManager           // Background privacy overlay
├─ CoreSecurity           // Central security gate & policy coordinator
└─ Views / ViewModels     // State-driven UI layer
```

---

## Design Principles

- **Single Responsibility**
  - Each security capability owns its own behavior and state
- **Explicit Boundaries via Dependency Injection**
  - Managers communicate through injected protocols
- **State-driven UI**
  - Views react to security state instead of deciding behavior
- **Centralized Policy Control**
  - All sensitive actions flow through `CoreSecurity`

---

## Why This Matters

Security features tend to grow organically and become fragile over time.
By treating security as a subsystem:

- New policies can be added without touching existing UI
- Rules remain consistent across the app
- Behavior stays predictable as complexity increases
- The system becomes easier to test and reason about

---

## Key Takeaway

> With AI accelerating implementation, **system boundaries and responsibility design**
> are becoming the real differentiators.

---

## Notes

- This repository focuses on **system design and architecture**
- UI is kept intentionally minimal to highlight behavioral correctness
- Designed for wallet / finance-style security requirements

---
