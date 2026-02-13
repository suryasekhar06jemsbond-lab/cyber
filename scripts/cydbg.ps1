param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$CliArgs
)

$ErrorActionPreference = 'Stop'

if ($null -eq $CliArgs) { $CliArgs = @() }

if ($CliArgs.Count -lt 1) {
    [Console]::Error.WriteLine('Usage: cydbg [--break line1,line2] [--step] [--step-count N] <file.cy> [args...]')
    exit 1
}

$runtime = $null
if ($IsWindows) {
    if (Test-Path './cy.exe') {
        $runtime = './cy.exe'
    } elseif (Test-Path './cy') {
        $runtime = './cy'
    }
} else {
    if (Test-Path './cy') {
        $runtime = './cy'
    } elseif (Test-Path './cy.exe') {
        $runtime = './cy.exe'
    }
}

if (-not $runtime) {
    throw 'cy runtime not found (expected ./cy or ./cy.exe)'
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
