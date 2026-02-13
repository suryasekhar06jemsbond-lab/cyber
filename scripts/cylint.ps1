param(
    [switch]$Strict,
    [string]$Target = '.'
)

$ErrorActionPreference = 'Stop'

$isWin = $false
if ($null -ne (Get-Variable -Name IsWindows -ErrorAction SilentlyContinue)) {
    $isWin = [bool]$IsWindows
} elseif ($env:OS -eq 'Windows_NT') {
    $isWin = $true
}

$runtime = $null
if ($isWin) {
    if (Test-Path '.\cy.exe') { $runtime = '.\cy.exe' }
    elseif (Test-Path '.\cy') { $runtime = '.\cy' }
} else {
    if (Test-Path './cy') { $runtime = './cy' }
    elseif (Test-Path './cy.exe') { $runtime = './cy.exe' }
}

if (-not $runtime) {
    throw 'cy runtime not found (expected .\cy.exe or .\cy)'
}

function Lint-CyFile {
    param([string]$Path)
    & $runtime --parse-only $Path | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "Lint failed for $Path"
    }
    if ($Strict) {
        $fmtScript = Join-Path $PSScriptRoot 'cyfmt.ps1'
        & $fmtScript -Check $Path | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Formatting check failed for $Path"
        }
    }
}

if (Test-Path $Target -PathType Leaf) {
    Lint-CyFile -Path $Target
} else {
    Get-ChildItem -Path $Target -Recurse -Filter '*.cy' -File | ForEach-Object {
        Lint-CyFile -Path $_.FullName
    }
}

Write-Host 'Lint complete'
