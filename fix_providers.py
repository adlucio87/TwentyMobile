import re

with open('lib/core/di/providers.dart', 'r') as f:
    content = f.read()

# Fix the warning for unnecessary null check (since the list won't be null)
# Change `if (metadata != null)` to just use it if it's not nullable or remove it.
content = content.replace("if (metadata != null) {", "if (true) {")

with open('lib/core/di/providers.dart', 'w') as f:
    f.write(content)
