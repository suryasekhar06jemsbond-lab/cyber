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
    [Console]::Out.WriteLine('Usage: cydbg [--break line1,line2] [--step] [--step-count N] <file.cy> [args...]')
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
    if ($env:CYPER_RUNTIME -and (Test-Path -LiteralPath $env:CYPER_RUNTIME)) {
        return $env:CYPER_RUNTIME
    }
    if ($env:CY_RUNTIME -and (Test-Path -LiteralPath $env:CY_RUNTIME)) {
        return $env:CY_RUNTIME
    }

    $candidates = @(
        (Join-Path $PSScriptRoot 'cyper.exe'),
        (Join-Path $PSScriptRoot 'cyper'),
        (Join-Path $PSScriptRoot 'cy.exe'),
        (Join-Path $PSScriptRoot 'cy'),
        '.\cyper.exe',
        './cyper.exe',
        '.\cyper',
        './cyper',
        '.\cy.exe',
        './cy.exe',
        '.\cy',
        './cy'
    )
    foreach ($p in $candidates) {
        if (Test-Path -LiteralPath $p) {
            return $p
        }
    }

    $cmdCyper = Get-Command cyper -ErrorAction SilentlyContinue
    if ($cmdCyper) { return $cmdCyper.Source }
    $cmdCyperExe = Get-Command cyper.exe -ErrorAction SilentlyContinue
    if ($cmdCyperExe) { return $cmdCyperExe.Source }

    $cmd = Get-Command cy -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $cmdExe = Get-Command cy.exe -ErrorAction SilentlyContinue
    if ($cmdExe) { return $cmdExe.Source }

    return $null
}

$runtime = Resolve-RuntimePath
if (-not $runtime) {
    throw 'cyper runtime not found (set CYPER_RUNTIME/CY_RUNTIME or add cyper to PATH)'
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
