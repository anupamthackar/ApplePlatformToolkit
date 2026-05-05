# Apple Platform Toolkit

A production-grade modular Apple Platform Toolkit using Swift Package Manager.

## Architecture

This package uses a strict Multi-Product Swift Package (BOM-style) architecture.
It features a 4-layer architecture with inward-only dependencies (Feature -> Service -> Core -> Plugin).

Modules:
- **Core Layer:** `ToolkitCore`, `ToolkitUtility`, `ToolkitCrypto`, `ToolkitCompression`
- **Service Layer:** `ToolkitNetworking`, `ToolkitAuth`
- **Feature Layer:** `ToolkitUI`
- **Plugin Layer:** `ToolkitPlugins`
- **Umbrella Module:** `ToolkitAll` (re-exports all modules for single-import usage)

## Integration

Consumers can import modules individually without importing the entire toolkit:
```swift
import ToolkitAuth
import ToolkitNetworking
```

Or they can import the entire toolkit using the umbrella module:
```swift
import ToolkitAll
```

## Features

- **Protocol-Oriented Programming**
- **Dependency Injection** (`DependencyContainer`)
- **SOLID** and **Open/Closed Principle**
- **Testability-first design**
- **Unified Semantic Versioning** across all modules
- **`tk` proxy namespace** for Foundation extensions

## Setup & Code Generation

This project uses `Sourcery` for generating mocks and API clients, and implements CI/CD via GitHub Actions.

To run code generation:
```bash
sh scripts/generate.sh
```

## Documentation

Full DocC documentation is generated in CI/CD, or can be generated locally:
```bash
swift package --allow-writing-to-directory ./docs \\
  generate-documentation --target ToolkitAll \\
  --disable-indexing \\
  --transform-for-static-hosting \\
  --hosting-base-path MyToolkit \\
  --output-path ./docs
```

## Requirements
- iOS 15.0+
- macOS 12.0+
- Swift 6.0+
