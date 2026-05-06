import os

def fix_file(filepath):
    if not os.path.exists(filepath): return
    with open(filepath, 'r') as f:
        content = f.read()
    content = content.replace("public class BaseManager", "open class BaseManager")
    with open(filepath, 'w') as f:
        f.write(content)

fix_file('Sources/ToolkitCore/CoreSDK.swift')
