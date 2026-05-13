# MyToolkit — AI Agent System

Welcome to the **MyToolkit** engineering ecosystem. This project is a highly modular, enterprise-grade Apple Platform SDK designed to be managed and extended by specialized AI agents working alongside human architects.

## Core Architecture Principles
- **Strict Modularity**: Features, Services, Core, and Plugins are strictly isolated. No cross-pollution.
- **Concurrency First**: Full Swift 6 concurrency compliance. Enforce `MainActor` for UI and `Sendable` thread-safe networking/auth interceptors.
- **Standardized Access**: Always use facade access patterns and the `.tk` namespace utility extensions.
- **Plugin Extensibility**: Ensure thread-safe, isolated lifecycle hooks within the `ToolkitPlugins` architecture.

## Agent Roles & Responsibilities

### 🏗️ Core Architect Agent
- **Focus**: SDK Infrastructure, Dependency Injection, and SOLID principles.
- **Skill**: [.agent/skills/architecture-principles.md](.agent/skills/architecture-principles.md)
- **Responsibility**: Ensuring the `ToolkitCore` layer remains stable, standardizing logging, concurrency, and event management.

### 🔐 Security & Network Agent
- **Focus**: Authentication, Cryptography, and Thread-Safe Networking.
- **Skill**: [.agent/skills/networking-auth.md](.agent/skills/networking-auth.md)
- **Responsibility**: Managing `ToolkitAuth` and `ToolkitNetworking`, ensuring interceptors and data flow remain highly secure and performant.

### 🧩 Plugin System Agent
- **Focus**: Extensibility and Lifecycle Hooks.
- **Skill**: [.agent/skills/plugin-system.md](.agent/skills/plugin-system.md)
- **Responsibility**: Developing and integrating new plugins seamlessly without breaking core SDK functionality.

### 🎨 UI & Demo Agent
- **Focus**: `ToolkitDemo`, `ToolkitUI`, and Developer Experience.
- **Skill**: [.agent/skills/ui-guidelines.md](.agent/skills/ui-guidelines.md)
- **Responsibility**: Building structured, scenario-based interactive examples. Using `ThemeManager` exclusively for all styling. 

## Component Development Workflow
1. **Define Architecture**: Identify whether the addition belongs in Core, Service, Feature, or Plugin layer.
2. **Implement Logic**: Write the thread-safe, Swift 6 compliant logic.
3. **Facade Integration**: Update the facade access patterns to expose the new functionality cleanly.
4. **Demo Implementation**: Create a comprehensive, scenario-based view in `ToolkitDemo` (e.g., `AuthDemoView.swift`).
5. **Documentation**: Write DocC-compliant documentation highlighting the enterprise-grade capabilities.

## Mandatory Rules
- **No Hardcoded Values**: Always route UI styling through `ThemeManager`.
- **Thread Safety**: Never write non-isolated state without explicit `Sendable` or `Actor` wrappers.
- **Namespace Consistency**: Utilize the `.tk` namespace for all utility extensions.
