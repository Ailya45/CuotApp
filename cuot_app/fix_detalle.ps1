# Repair missing closing braces and Observaciones header in detalle_credito_page.dart
# Current state (problem):
# Line 898 (idx 897): ],    <- this closes the 'if (condNuevas abono)' spread
# Line 899 (idx 898):           style: TextStyle(    <- WRONG! Missing Card closing + if(observaciones) opening
#
# Expected state:
# Line 898: ],
# Line 899:                           ],  (closes Column children)
# Line 900:                         ),   (closes Padding)
# Line 901:                       ),     (closes Card)
# Line 902:
# Line 903:                     if (renovacion.observaciones != null &&
# Line 904:                         renovacion.observaciones!.isNotEmpty) ...[
# Line 905:                       const SizedBox(height: 16),
# Line 906:                       const Text('Observaciones',   <- this was line 899

$dartFile = 'lib\ui\pages\detalle_credito_page.dart'
$lines = [IO.File]::ReadAllLines($dartFile, [Text.Encoding]::UTF8)

Write-Host "Total lines:" $lines.Length
Write-Host "Line 898 (idx 897):" $lines[897]
Write-Host "Line 899 (idx 898):" $lines[898]

# At idx 898 (line 899) we need to INSERT the missing lines BEFORE the current content
# The current line 899 starts with '                           style: TextStyle('
# which was originally:
# '                       const Text(''Observaciones'',' + newline + '                           style: ...'

# Lines to insert at index 898 (before current line 899):
$insertLines = @(
    "                          ],",
    "                        ),",
    "                      ),",
    "                    ),",
    "",
    "                    if (renovacion.observaciones != null &&",
    "                        renovacion.observaciones!.isNotEmpty) ...[",
    "                      const SizedBox(height: 16),",
    "                      const Text('Observaciones',"
)

# Build new file content
$before = $lines[0..897]
$after = $lines[898..($lines.Length - 1)]

$result = $before + $insertLines + $after

Write-Host "New total lines:" $result.Length

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[IO.File]::WriteAllLines($dartFile, $result, $utf8NoBom)
Write-Host "SUCCESS: Inserted missing lines"
