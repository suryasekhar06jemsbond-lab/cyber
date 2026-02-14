param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$CliArgs
)

$ErrorActionPreference = 'Stop'

if ($null -eq $CliArgs) { $CliArgs = @() }

$isWin = $false
if ($null -ne (Get-Variable -Name IsWindows -ErrorAction SilentlyContinue)) {
    $isWin = [bool]$IsWindows
} elseif ($env:OS -eq 'Windows_NT') {
    $isWin = $true
}

function Show-Usage {
    [Console]::Out.WriteLine('Usage: cydbg [--break line1,line2] [--step] [--step-count N] <file.nx> [args...]')
}

if ($CliArgs.Count -lt 1) {
    Show-Usage
    exit 1
}

foreach ($arg in $CliArgs) {
    if ($arg -eq '--help' -or $arg -eq '-h') {
        Show-Usage
        exit 0
    }
}

function Resolve-RuntimePath {
    if ($env:NYX_RUNTIME -and (Test-Path -LiteralPath $env:NYX_RUNTIME)) {
        return $env:NYX_RUNTIME
    }

    $candidates = @(
        (Join-Path $PSScriptRoot 'nyx.exe'),
        (Join-Path $PSScriptRoot 'nyx'),
        '.\nyx.exe',
        './nyx.exe',
        '.\nyx',
        './nyx'
    )
    foreach ($p in $candidates) {
        if (Test-Path -LiteralPath $p) {
            return $p
        }
    }

    $cmd = Get-Command nyx -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $cmdExe = Get-Command nyx.exe -ErrorAction SilentlyContinue
    if ($cmdExe) { return $cmdExe.Source }

    return $null
}

$runtime = Resolve-RuntimePath
if (-not $runtime) {
    throw 'nyx runtime not found (set NYX_RUNTIME or add nyx to PATH)'
}

$hasMode = $false
foreach ($arg in $CliArgs) {
    if ($arg -eq '--break' -or $arg -eq '--step' -or $arg -eq '--step-count') {
        $hasMode = $true
        break
    }
}

if ($hasMode) {
    & $runtime @CliArgs
} else {
    & $runtime --debug @CliArgs
}
exit $LASTEXITCODE
