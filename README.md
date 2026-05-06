# Apple Platform Toolkit

A highly modular, extensible, and configuration-driven enterprise SDK for Apple platforms. This toolkit is divided into focused modules to ensure strict separation of concerns while offering deep customization via Builders, Strategy patterns, and Injectable Managers.

## Table of Contents
1. [Installation](#installation)
2. [Module Overview](#module-overview)
3. [Usage by Module](#usage-by-module)
   - [ToolkitCore & ToolkitPlugins](#toolkitcore--toolkitplugins)
   - [ToolkitUtility](#toolkitutility)
   - [ToolkitCrypto](#toolkitcrypto)
   - [ToolkitNetworking](#toolkitnetworking)
   - [ToolkitAuth](#toolkitauth)
   - [ToolkitCompression](#toolkitcompression)

---

## Installation

You can integrate individual modules or the entire toolkit via **Swift Package Manager**.

```swift
dependencies: [
    .package(url: "https://github.com/your-repo/MyToolkit.git", from: "1.0.0")
]

targets: [
    .target(name: "YourApp", dependencies: [
        .product(name: "ToolkitAll", package: "MyToolkit") // or import specific modules
    ])
]
```

---

## Module Overview

| Module | Description |
|---|---|
| **`ToolkitCore`** | Foundation of the SDK. Contains `BaseManager`, logging, and DI interfaces. |
| **`ToolkitPlugins`** | Exposes the `PluginRegistry` for cross-cutting observability and life-cycle hooks. |
| **`ToolkitUtility`** | 50+ features covering Connectivity, Device Stats, WatchOS integration, and Data Formatting pipelines. |
| **`ToolkitCrypto`** | Configurable Cryptography with AES/ChaCha strategies, Hashing builders, and Key Management. |
| **`ToolkitNetworking`** | Network request builders, circuit breakers, offline queues, and interceptor chains. |
| **`ToolkitAuth`** | Session management, biometric integration, OAuth strategies, and network adaptation. |
| **`ToolkitCompression`** | Pluggable compression strategies (Zip, LZFSE) and streaming Archive Builders. |
| **`ToolkitUI`** | Shared SwiftUI components and views (e.g., standard Login configurations). |
| **`ToolkitAll`** | Umbrella target exporting all modules for convenience. |

---

## Usage by Module

### ToolkitCore & ToolkitPlugins
The core layer establishes a plugin-based lifecycle and base classes ensuring thread-safety and extension capabilities.

```swift
import ToolkitCore
import ToolkitPlugins

// Create a custom plugin
class AnalyticsPlugin: PluginProtocol {
    var id: String = "com.analytics.plugin"
    func onLoad() { print("Plugin loaded") }
    func onExecute() { print("Plugin executing") }
    func onUnload() { print("Plugin unloaded") }
}

// Register across the registry
PluginRegistry.shared.register(AnalyticsPlugin())
```

### ToolkitUtility
Provides deep system observers and formatters via the `ToolkitUtilityManager`. 

```swift
import ToolkitUtility

let manager = ToolkitUtilityManager.shared

// Check Network Quality
let networkType = manager.connectivity.currentNetworkType()
let isFast = manager.connectivity.connectionQuality() > 0.8

// Device Information
let battery = manager.device.batteryLevel()
let memory = manager.device.freeMemory()

// Flexible String Pipeline Builder
let formatter = FormatPipelineBuilder()
    .trim()
    .uppercase()
    .replace("-", with: " ")
    .build()

let result = formatter("   hello-world   ") // "HELLO WORLD"
```

### ToolkitCrypto
Allows you to build hashes dynamically or apply interchangeable encryption strategies.

```swift
import ToolkitCrypto

let crypto = ToolkitCryptoManager.shared

// Dynamic Hashing
let hashResult = HashBuilder()
    .setAlgorithm(.sha256)
    .append(string: "secure_payload")
    .applySalt(mySaltData)
    .finalizeHex()

// Encryption Strategies
let strategy = crypto.resolveStrategy(for: .chachaPoly)
let encrypted = try strategy.encrypt(data, key: myKey, iv: myIV)

// Manage Keys securely
let newKey = crypto.keyManager.generate(size: .bits256)
try crypto.keyManager.store(key: newKey, tag: "com.app.master", in: .secureEnclave)
```

### ToolkitNetworking
Replaces raw REST calls with a robust Request Builder and Resiliency protocols (Circuit Breakers).

```swift
import ToolkitNetworking

// Build a highly configured network request
let request = NetworkRequestBuilder()
    .url("https://api.example.com/v1/data")
    .method(.post)
    .addHeader("X-Custom-Auth", "token")
    .jsonBody(myCodableObject)
    .priority(.high)
    .cachePolicy(.memoryOnly)
    .retryCount(3)
    .build()

// Circuit breaker capabilities
let networkManager = ToolkitNetworkingManager.shared
if networkManager.circuitBreaker.canExecute() {
    let response = try await networkManager.execute(request)
}
```

### ToolkitAuth
Handles Session lifecycles, account routing, and UI-integration strategies.

```swift
import ToolkitAuth

let auth = ToolkitAuthManager.shared

// Trigger dynamic authentication types
try await auth.authenticate(method: .biometric)

// State driven observation
if auth.state == .authenticated {
    let token = auth.session.currentToken()
}

// Automatically adapt URLRequests (Interceptor)
let safeRequest = auth.adapt(rawRequest)
```

### ToolkitCompression
Offers abstraction over Zip, LZFSE, and allows archive construction.

```swift
import ToolkitCompression

let compression = ToolkitCompressionManager.shared

// Strategy-based compression
let zipStrategy = compression.strategy(for: .zip)
let compressedData = try zipStrategy.compress(data: rawData, level: .best)

// Build an archive dynamically
let archiveData = try ArchiveBuilder()
    .addFile(path: "docs/readme.txt", data: textData)
    .addFile(path: "images/logo.png", data: imgData)
    .setPassword("super_secure")
    .build(format: .lzfse)
```
