param(
    [switch]$Check,
    [string]$Target = '.'
)

$ErrorActionPreference = 'Stop'

function Get-FormattedCyText {
    param([string]$Path)

    $text = Get-Content -Raw -LiteralPath $Path
    $text = $text -replace "`r", ''
    $lines = $text -split "`n", -1 | ForEach-Object {
        ($_ -replace "`t", '    ') -replace '[ \t]+$', ''
    }
    return ($lines -join "`n")
}

if (-not (Test-Path -LiteralPath $Target)) {
    throw "Target not found: $Target"
}

$files = @()
if (Test-Path -LiteralPath $Target -PathType Leaf) {
    $files = @($Target)
} else {
    $files = @(Get-ChildItem -LiteralPath $Target -Recurse -Filter '*.cy' -File | ForEach-Object { $_.FullName })
}

$checkFailed = $false
foreach ($file in $files) {
    $formatted = Get-FormattedCyText -Path $file
    if ($Check) {
        $current = Get-Content -Raw -LiteralPath $file
        if ($current -ne $formatted) {
            Write-Host "Needs formatting: $file"
            $checkFailed = $true
        }
    } else {
        Set-Content -NoNewline -LiteralPath $file $formatted
    }
}

if ($Check) {
    if ($checkFailed) {
        exit 1
    }
    Write-Host 'Formatting OK'
} else {
    Write-Host 'Formatting complete'
}
