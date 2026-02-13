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
