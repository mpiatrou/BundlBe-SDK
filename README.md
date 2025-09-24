# BundlBe SDK

[![CocoaPods](https://img.shields.io/cocoapods/v/BundlBe)](https://cocoapods.org/pods/BundlBe)
![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen)
![Platform](https://img.shields.io/badge/platform-iOS-lightgrey)
![Swift](https://img.shields.io/badge/Swift-5.9-orange)
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

`BundlBe` is a lightweight iOS SDK for subscription activation and paywall management.

It provides three main features:

1. **Login** — authenticate and verify subscription (cached for 24h)
2. **Logout** — clear session and reset state
3. **Paywall Suppressor** — check whether paywall should be hidden

---

## Installation

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

## Usage

### 1. Login

Call `login` when:

* the user enters an activation code (manual activation),
* the app launches (to validate subscription status).

**Logic:**

* If the last successful verification was **less than 24 hours ago** → cached result is returned immediately.
* Otherwise → `/login` request is sent to the backend.

#### 1. Example: Manual activation

```swift
import BundlBe

// Save the code after first activation
let userCode = "USER_CODE"
UserDefaults.standard.set(userCode, forKey: "USER_CODE")

// Call login
BundlBe.login(
    code: userCode,
    appID: "APP_ID",
    deviceID: "DEVICE_ID"
) { result in
    print("Login result:", result)
}
```

#### 2. Example: AppDelegate

Call `login` at startup if the activation code was previously saved (e.g. in `UserDefaults`).
This ensures subscription status is checked automatically once per day.

```swift
import BundlBe

func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
) -> Bool {

    if let userCode = UserDefaults.standard.string(forKey: "USER_CODE") {
        BundlBe.login(
            code: userCode,
            appID: "APP_ID",
            deviceID: UIDevice.current.identifierForVendor?.uuidString ?? ""
        ) { result in
            print("Login result:", result)
        }
    }

    return true
}
```

---

### 2. Logout

Calls `/logout` on the backend and **always** resets the suppress state locally.

```swift
BundlBe.logout(
    code: "USER_CODE",
    appID: "APP_ID",
    deviceID: "DEVICE_ID"
) { result in
    switch result {
    case .success:
        print("Logged out")
    case .failure(let error):
        print("Logout error:", error.localizedDescription)
    }
}
```

---

### 3. Paywall Suppressor

Check whether the paywall should be displayed:

```swift
if BundlBe.isPaywallSuppressed {
    // show content without paywall
} else {
    // show paywall
}
```

---
