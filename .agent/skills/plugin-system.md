# Plugin System

1. **Lifecycle Hooks**:
   - Plugins must implement `ToolkitPlugin` protocol.
   - Respect `onInit`, `onStart`, `onStop` lifecycle methods.

2. **Isolation**:
   - Plugins should not have direct hard dependencies on other plugins.
   - Use the Event Bus from `ToolkitCore` to communicate between plugins.
