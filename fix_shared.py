import os

def fix_file(filepath):
    if not os.path.exists(filepath): return
    with open(filepath, 'r') as f:
        content = f.read()
    content = content.replace("public static let shared", "public nonisolated(unsafe) static let shared")
    with open(filepath, 'w') as f:
        f.write(content)

for root, _, files in os.walk('Sources'):
    for file in files:
        if file.endswith('.swift'):
            fix_file(os.path.join(root, file))
