import os

def replace_in_file(filepath, replacements):
    with open(filepath, 'r') as f:
        content = f.read()
    for old, new in replacements:
        content = content.replace(old, new)
    with open(filepath, 'w') as f:
        f.write(content)

replace_in_file("Sources/ToolkitPlugins/ToolkitPlugins.swift", [
    ("public class LoggingPlugin: ToolkitPlugin {", "public final class LoggingPlugin: ToolkitPlugin, @unchecked Sendable {"),
    ("public class AnalyticsPlugin: ToolkitPlugin {", "public final class AnalyticsPlugin: ToolkitPlugin, @unchecked Sendable {"),
    ("public class SecurityPlugin: ToolkitPlugin {", "public final class SecurityPlugin: ToolkitPlugin, @unchecked Sendable {"),
    ("public class NetworkingPlugin: ToolkitPlugin {", "public final class NetworkingPlugin: ToolkitPlugin, @unchecked Sendable {")
])
