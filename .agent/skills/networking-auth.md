# Networking & Authentication

1. **Thread-Safe Networking**:
   - All networking requests must be handled via `ToolkitNetworkingManager`.
   - Ensure URLSessions are configured securely.

2. **Interceptors**:
   - Use Auth interceptors to inject Bearer tokens automatically.
   - Refresh tokens gracefully via `ToolkitAuth`.

3. **Cryptography**:
   - Use secure enclaves for storing sensitive data.
   - Do not log PII or raw authentication tokens in `ToolkitCore` logs.
