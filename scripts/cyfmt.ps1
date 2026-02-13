param(
    [string]$Target = '.'
)

$ErrorActionPreference = 'Stop'

function Format-CyFile {
    param([string]$Path)

    $text = Get-Content -Raw -LiteralPath $Path
    $text = $text -replace "`r", ''
    $text = $text -replace "`t", '    '
    $lines = $text -split "`n", -1 | ForEach-Object { $_ -replace '[ \t]+$','' }
    $out = ($lines -join "`n")
    Set-Content -NoNewline -LiteralPath $Path $out
}

if (Test-Path -LiteralPath $Target -PathType Leaf) {
    Format-CyFile -Path $Target
} else {
    Get-ChildItem -LiteralPath $Target -Recurse -Filter '*.cy' -File | ForEach-Object {
        Format-CyFile -Path $_.FullName
    }
}

Write-Host 'Formatting complete'
