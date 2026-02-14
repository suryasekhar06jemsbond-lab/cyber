param(
    [switch]$Strict,
    [string]$Target = '.',
    [switch]$Help
)

$ErrorActionPreference = 'Stop'

$CliArgs = @($args)

# Some hosts can bind a switch-like token into the first positional string parameter.
switch ($Target.ToLowerInvariant()) {
    '-strict' { $Strict = $true; $Target = '.' }
    '--strict' { $Strict = $true; $Target = '.' }
    '-h' { $Help = $true; $Target = '.' }
    '--help' { $Help = $true; $Target = '.' }
    '-help' { $Help = $true; $Target = '.' }
}

function Show-Usage {
@"
Usage: cylint [--strict] [target(.nx|.cy)]
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
        '--strict' { $Strict = $true; continue }
        '-strict' { $Strict = $true; continue }
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
            # Ignore additional positional args to avoid host-specific switch-binding quirks.
            continue
        }
    }
}

if ($Help) {
    Show-Usage
    exit 0
}

$isWin = $false
if ($null -ne (Get-Variable -Name IsWindows -ErrorAction SilentlyContinue)) {
    $isWin = [bool]$IsWindows
} elseif ($env:OS -eq 'Windows_NT') {
    $isWin = $true
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
    Get-ChildItem -Path $Target -Recurse -File | Where-Object { $_.Extension -in @('.nx', '.cy') } | ForEach-Object {
        Lint-CyFile -Path $_.FullName
    }
}

Write-Host 'Lint complete'
