# 📦 BundlBe SDK

`BundlBe` is a lightweight iOS SDK for subscription activation and paywall management.
It provides three main functions:

1. **Login** — authenticate and verify subscription
2. **Logout** — clear session and reset state
3. **Paywall Suppressor** — check whether paywall should be hidden

---

## 🚀 Installation

### Swift Package Manager

Add the package in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/mpiatrou/BundlBe-SDK", from: "1.0")
]
```

Or in Xcode:
`File` → `Add Packages...` → paste repository URL → `Add Package`.

---

### CocoaPods

Add to your `Podfile`:

```ruby
pod 'BundlBe', '~> 1.0'
```

Then run:

```bash
pod install
```

---

## ⚡ Usage

### 1. Login

Use when a user enters an activation code **or** when the app launches (to check subscription status).

```swift
import BundlBe

BundlBe.login(
    code: "USER_CODE",
    appID: "APP_ID",
    deviceID: "DEVICE_ID"
) { result in
    switch result {
    case .success(let response):
        print("✅ Login success:", response)
        
        if BundlBe.isPaywallSuppressed {
            print("Paywall hidden")
        } else {
            print("Paywall visible")
        }
        
    case .failure(let error):
        print("❌ Login error:", error.localizedDescription)
    }
}
```

---

### 2. Logout

Calls `/logout` and resets suppress state.

```swift
BundlBe.logout(
    code: "USER_CODE",
    appID: "APP_ID",
    deviceID: "DEVICE_ID"
) { result in
    switch result {
    case .success:
        print("✅ Logged out")
    case .failure(let error):
        print("❌ Logout error:", error.localizedDescription)
    }
}
```

---

### 3. Paywall Suppressor

Use to check UI state:

```swift
if BundlBe.isPaywallSuppressed {
    // show content without paywall
} else {
    // show paywall
}
```

---
