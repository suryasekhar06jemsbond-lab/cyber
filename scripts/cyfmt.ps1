param(
    [switch]$Check,
    [string]$Target = '.',
    [switch]$Help,
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$CliArgs
)

$ErrorActionPreference = 'Stop'

if ($null -eq $CliArgs) { $CliArgs = @() }

function Show-Usage {
@"
Usage: cyfmt [--check] [target]
"@
}

foreach ($arg in $CliArgs) {
    switch ($arg) {
        '--help' { $Help = $true; continue }
        '-h' { $Help = $true; continue }
        '-help' { $Help = $true; continue }
        '--check' { $Check = $true; continue }
        '-check' { $Check = $true; continue }
        default {
            if ($arg.StartsWith('-')) {
                throw "Unknown option: $arg"
            }
            if ($Target -eq '.') {
                $Target = $arg
                continue
            }
            if ($arg -eq $Target) {
                # PowerShell may include already-bound positional args in remaining args.
                continue
            }
            throw "Multiple targets are not supported"
        }
    }
}

if ($Help) {
    Show-Usage
    exit 0
}

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
