# UI & Demo Guidelines

1. **ThemeManager**:
   - Do NOT use hardcoded SwiftUI colors (`.blue`, `.red`).
   - Always reference `ThemeManager.shared` for colors, fonts, and spacing.

2. **MainActor Isolation**:
   - All UI Views and view models must be decorated with `@MainActor`.

3. **Demo App Scenarios**:
   - When building in `ToolkitDemo`, group demos by functionality (e.g., `AuthDemoView`, `PluginsDemoView`).
   - Provide clear, interactive examples showing how an SDK consumer would use the APIs.
