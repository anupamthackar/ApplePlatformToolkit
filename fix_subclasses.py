import os

def replace_in_file(filepath, replacements):
    with open(filepath, 'r') as f:
        content = f.read()
    for old, new in replacements:
        content = content.replace(old, new)
    with open(filepath, 'w') as f:
        f.write(content)

# Fix ToolkitPlugins
replace_in_file("Sources/ToolkitPlugins/ToolkitPlugins.swift", [
    ("public protocol EventListener {", "public protocol EventListener: Sendable {"),
    ("public class EventBus {", "public final class EventBus: @unchecked Sendable {"),
    ("public class PluginManager {", "public final class PluginManager: @unchecked Sendable {")
])

# Fix subclasses of BaseManager requiring restated @unchecked Sendable
for f in ["ToolkitCompressionManager.swift", "ToolkitCryptoManager.swift", "ToolkitUtilityManager.swift", "ToolkitNetworkingManager.swift", "ToolkitAuthManager.swift"]:
    path = ""
    for root, dirs, files in os.walk("Sources"):
        if f in files:
            path = os.path.join(root, f)
            break
    if path:
        replace_in_file(path, [
            ("open class ToolkitCompressionManager: BaseManager {", "open class ToolkitCompressionManager: BaseManager, @unchecked Sendable {"),
            ("open class ToolkitCryptoManager: BaseManager {", "open class ToolkitCryptoManager: BaseManager, @unchecked Sendable {"),
            ("open class ToolkitUtilityManager: BaseManager {", "open class ToolkitUtilityManager: BaseManager, @unchecked Sendable {"),
            ("open class ToolkitNetworkingManager: BaseManager {", "open class ToolkitNetworkingManager: BaseManager, @unchecked Sendable {"),
            ("open class ToolkitAuthManager: BaseManager, BaseNetworkInterceptor {", "open class ToolkitAuthManager: BaseManager, BaseNetworkInterceptor, @unchecked Sendable {")
        ])
