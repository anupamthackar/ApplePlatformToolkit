# Apple Platform Toolkit 🍎

[![Swift 6.0](https://img.shields.io/badge/Swift-6.0-orange.svg?style=flat-square)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platforms-iOS_16%2B_|_macOS_13%2B-blue.svg?style=flat-square)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=flat-square)](LICENSE)

**Apple Platform Toolkit** is an enterprise-grade, highly modular SDK designed to accelerate modern Swift development. Built from the ground up for **Swift 6 Concurrency**, it provides a rock-solid, decoupled foundation for high-performance applications.

---

## 🏗 Modular Architecture

The toolkit is divided into 10 specialized modules, allowing you to import only what you need.

### Core Modules
- **`ToolkitCore`**: The foundation. Provides thread-safe Dependency Injection, standardized logging, and task management.
- **`ToolkitUtility`**: Hardware and system-level utilities including connectivity monitoring and device information.
- **`ToolkitCrypto`**: High-level abstractions over CryptoKit for AES-GCM, ChaChaPoly, and secure key management.
- **`ToolkitCompression`**: High-performance data compression using LZFSE, LZ4, and ZLIB algorithms.
- **`ToolkitFormatter`**: Advanced formatting pipelines for dates, currencies, and complex string transformations.

### Service & Logic Modules
- **`ToolkitNetworking`**: A robust networking layer with interceptors, circuit breakers, and auto-retry logic.
- **`ToolkitAuth`**: Identity management with support for Biometrics, Keychain storage, and session lifecycle.

### Extension & UI Modules
- **`ToolkitUI`**: A fully customizable, scalable UI framework with dynamic theming and reusable professional components.
- **`ToolkitPlugins`**: An extensibility layer featuring a high-performance EventBus and modular plugin registry.
- **`ToolkitAll`**: The umbrella module that exports the entire SDK for streamlined integration.

---

## 🎨 Customizable UI Framework (`ToolkitUI`)

The `ToolkitUI` module is designed to be a scalable design system. By modifying the `ThemeConfig`, you can completely transform the look and feel of your application without changing a single line of component code.

```swift
var customTheme = ThemeConfig()
customTheme.primaryColor = .indigo
customTheme.cornerRadius = 24
ThemeManager.shared.apply(customTheme)
```

### Key Components
- **Buttons**: Multi-style, loading states, and scale animations.
- **Inputs**: Secure entry, validation states, and icon integration.
- **Containers**: Standardized cards with configurable shadows and gradients.
- **Feedback**: Global HUD and non-blocking toast notifications.

---

## 🚀 Getting Started

### Installation
Add via **Swift Package Manager**:
`https://github.com/anupamthackar/ApplePlatformToolkit.git`

### Simple Usage
```swift
import ToolkitAll

// Use the global facade for all modules
Toolkit.ui.showSuccess("Welcome to the Toolkit!")
let key = Toolkit.crypto.generateKey()
```

---

## 📱 Toolkit Demo App

The project includes a comprehensive **ToolkitDemo.swiftpm** application to showcase every module in action.

> [!IMPORTANT]
> **Running the Demo**: For the best experience and full architecture visualization, please run the demo using the **"My Mac"** destination in Xcode. The demo is intended for exploration, understanding the modular architecture, and code performance evaluation. It is not currently optimized for iOS Simulator execution.

---

---

## 📄 License
Distributed under the **MIT License**. See `LICENSE` for more information.
