param(
    [switch]$Check,
    [string]$Target = '.',
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

$CliArgs = @($args)

function Show-Usage {
@"
Usage: cyfmt [--check] [target]
"@
}

function Resolve-NormalizedPath {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return '' }
    try {
        if (Test-Path -LiteralPath $Path) {
            return (Resolve-Path -LiteralPath $Path).ProviderPath.ToLowerInvariant()
        }
    }
    catch {
    }
    return ($Path -replace '/', '\').Trim().ToLowerInvariant()
}

foreach ($arg in $CliArgs) {
    switch ($arg) {
        '--help' { $Help = $true; continue }
        '-h' { $Help = $true; continue }
        '-help' { $Help = $true; continue }
        '--check' { $Check = $true; continue }
        '-check' { $Check = $true; continue }
        default {
            if ([string]::IsNullOrWhiteSpace($arg)) {
                continue
            }
            if ($arg -eq 'True' -or $arg -eq 'False') {
                continue
            }
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
            if ((Resolve-NormalizedPath -Path $arg) -eq (Resolve-NormalizedPath -Path $Target)) {
                continue
            }
            throw "Multiple targets are not supported (target='$Target', extra='$arg')"
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
