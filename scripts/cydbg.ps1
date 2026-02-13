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

if ($CliArgs.Count -lt 1) {
    [Console]::Error.WriteLine('Usage: cydbg [--break line1,line2] [--step] [--step-count N] <file.cy> [args...]')
    exit 1
}

function Resolve-RuntimePath {
    if ($env:CY_RUNTIME -and (Test-Path -LiteralPath $env:CY_RUNTIME)) {
        return $env:CY_RUNTIME
    }

    $candidates = @(
        (Join-Path $PSScriptRoot 'cy.exe'),
        (Join-Path $PSScriptRoot 'cy'),
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

    $cmd = Get-Command cy -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $cmdExe = Get-Command cy.exe -ErrorAction SilentlyContinue
    if ($cmdExe) { return $cmdExe.Source }

    return $null
}

$runtime = Resolve-RuntimePath
if (-not $runtime) {
    throw 'cy runtime not found (set CY_RUNTIME or add cy to PATH)'
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
