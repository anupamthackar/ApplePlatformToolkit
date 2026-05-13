# Core Architecture Principles

1. **4-Layer Separation**:
   - `ToolkitCore`: Foundation, Logging, Event Bus.
   - `ToolkitServices`: Networking, Database, Auth.
   - `ToolkitUI` & Features: Visual components and specific domain logic.
   - `ToolkitPlugins`: Extensibility hooks.

2. **SOLID & Dependency Injection**:
   - Favor protocol-oriented programming.
   - Inject dependencies via `ToolkitCore` dependency registry.

3. **Concurrency**:
   - Strictly follow Swift 6 Concurrency (Sendable, Actor isolation).
