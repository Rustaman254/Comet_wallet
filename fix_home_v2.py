
import re

file_path = '/home/masterchiefff/Documents/Mamlaka/comet_wallet/lib/screens/home_screen.dart'

with open(file_path, 'r') as f:
    content = f.read()

# Fix _buildTransactionList - it currently has a missing line after line 1305
pattern = r'Widget _buildTransactionList\(List<Transaction> transactions\) \{\s*\n\s*\n\s*if \(recentTransactions\.isEmpty\)'
replacement = 'Widget _buildTransactionList(List<Transaction> transactions) {\n    final recentTransactions = transactions.take(6).toList();\n\n    if (recentTransactions.isEmpty)'

new_content = re.sub(pattern, replacement, content, flags=re.MULTILINE)

if new_content != content:
    with open(file_path, 'w') as f:
        f.write(new_content)
    print("Fix applied successfully")
else:
    # Try another pattern if the first one fails
    pattern2 = r'Widget _buildTransactionList\(List<Transaction> transactions\) \{\s*\n\s*if \(recentTransactions\.isEmpty\)'
    new_content2 = re.sub(pattern2, replacement, content, flags=re.MULTILINE)
    if new_content2 != content:
        with open(file_path, 'w') as f:
            f.write(new_content2)
        print("Fix applied successfully (pattern 2)")
    else:
        print("Pattern not found")
