param(
    [int]$VmCases = 300
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$isWin = $false
if ($null -ne (Get-Variable -Name IsWindows -ErrorAction SilentlyContinue)) {
    $isWin = [bool]$IsWindows
} elseif ($env:OS -eq 'Windows_NT') {
    $isWin = $true
}

function Run-Checked {
    param(
        [Parameter(Mandatory = $true)] [string] $Exe,
        [Parameter()] [string[]] $Args = @()
    )
    & $Exe @Args
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed ($LASTEXITCODE): $Exe $($Args -join ' ')"
    }
}

function Resolve-PwshExe {
    $pwshName = if ($isWin) { 'pwsh.exe' } else { 'pwsh' }
    $fromPsHome = Join-Path $PSHOME $pwshName
    if (Test-Path -LiteralPath $fromPsHome) {
        return $fromPsHome
    }

    $cmd = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($cmd) {
        return $cmd.Source
    }

    if ($isWin) {
        $pwshDefault = 'C:\Program Files\PowerShell\7\pwsh.exe'
        if (Test-Path -LiteralPath $pwshDefault) {
            return $pwshDefault
        }

        # Fallback to Windows PowerShell host when PowerShell 7 is unavailable.
        $winPsHome = Join-Path $PSHOME 'powershell.exe'
        if (Test-Path -LiteralPath $winPsHome) {
            return $winPsHome
        }

        $winPsCmd = Get-Command powershell -ErrorAction SilentlyContinue
        if ($winPsCmd) {
            return $winPsCmd.Source
        }
    }

    throw "pwsh executable not found"
}

function Has-Cmd {
    param([Parameter(Mandatory = $true)] [string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

$hasSh = Has-Cmd -Name 'sh'
$hasMake = Has-Cmd -Name 'make'
$pwshExe = Resolve-PwshExe

Write-Host "[prod-win] release package sanity..."
if ($isWin) {
    Run-Checked -Exe $pwshExe -Args @('-NoLogo', '-NoProfile', '-File', './scripts/build_windows.ps1', '-Output', '.\build\nyx.exe', '-LangVersion', '0.8.0')
    Run-Checked -Exe $pwshExe -Args @('-NoLogo', '-NoProfile', '-File', './scripts/package_release.ps1', '-Target', 'windows-x64', '-BinaryPath', '.\build\nyx.exe', '-OutDir', '.\dist')

    $zipPath = Join-Path $root 'dist/nyx-windows-x64.zip'
    $tmpPkg = Join-Path ([System.IO.Path]::GetTempPath()) ("ny_pkg_check_" + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tmpPkg | Out-Null
    try {
        Expand-Archive -Path $zipPath -DestinationPath $tmpPkg -Force
        foreach ($rel in @(
            'nyx.exe',
            'scripts/nypm.ps1',
            'scripts/nyfmt.ps1',
            'scripts/nylint.ps1',
            'scripts/nydbg.ps1',
            'stdlib/types.ny',
            'compiler/bootstrap.ny',
            'examples/fibonacci.ny'
        )) {
            if (-not (Test-Path -LiteralPath (Join-Path $tmpPkg $rel))) {
                throw "Missing release payload file: $rel"
            }
        }
    }
    finally {
        Remove-Item -Recurse -Force $tmpPkg -ErrorAction SilentlyContinue
    }
} elseif ($hasSh) {
    if (-not (Test-Path -LiteralPath './build/nyx')) {
        if (-not $hasMake) {
            throw "build/nyx is missing and make is not available for package sanity"
        }
        Run-Checked -Exe 'make' -Args @('build/nyx')
    }
    Run-Checked -Exe 'sh' -Args @('./scripts/package_release.sh', '--target', 'linux-x64', '--binary', './build/nyx', '--out-dir', './dist')
    $entries = @(& tar -tzf ./dist/nyx-linux-x64.tar.gz)
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to inspect release archive: ./dist/nyx-linux-x64.tar.gz"
    }
    foreach ($rel in @(
        './nyx',
        './scripts/nypm.sh',
        './scripts/nyfmt.sh',
        './scripts/nylint.sh',
        './scripts/nydbg.sh',
        './stdlib/types.ny',
        './compiler/bootstrap.ny',
        './examples/fibonacci.ny'
    )) {
        if ($entries -notcontains $rel) {
            throw "Missing release payload file: $rel"
        }
    }
} else {
    Write-Host "[prod-win] warning: package sanity skipped (no compatible shell available)"
}

if ($isWin -and $hasSh -and $hasMake) {
    Write-Host "[prod-win] warning: skipping shell test suite on Windows; use PowerShell suite for this platform"
} elseif ($hasSh -and $hasMake) {
    Write-Host "[prod-win] shell core test suite..."
    Run-Checked -Exe 'sh' -Args @('./scripts/test_v0.sh')
    Run-Checked -Exe 'sh' -Args @('./scripts/test_v1.sh')
    Run-Checked -Exe 'sh' -Args @('./scripts/test_v2.sh')
    Run-Checked -Exe 'sh' -Args @('./scripts/test_v3_start.sh')
    Run-Checked -Exe 'sh' -Args @('./scripts/test_v4.sh')
    Run-Checked -Exe 'sh' -Args @('./scripts/test_compatibility.sh')
    Run-Checked -Exe 'sh' -Args @('./scripts/test_ecosystem.sh')
    Run-Checked -Exe 'sh' -Args @('./scripts/test_registry.sh')
    Run-Checked -Exe 'sh' -Args @('./scripts/test_runtime_hardening.sh')
    Run-Checked -Exe 'sh' -Args @('./scripts/test_sanitizers.sh')
    Run-Checked -Exe 'sh' -Args @('./scripts/test_fuzz_vm.sh', '4242', '500')
    Run-Checked -Exe 'sh' -Args @('./scripts/test_soak_runtime.sh', '40')
} elseif ($hasSh -and -not $hasMake) {
    Write-Host "[prod-win] warning: 'sh' found but 'make' not found; skipping shell test suite"
} else {
    Write-Host "[prod-win] warning: 'sh' not found; skipping shell test suite"
}

Write-Host "[prod-win] vm consistency..."
Run-Checked -Exe $pwshExe -Args @('-NoLogo', '-NoProfile', '-File', './scripts/test_vm_consistency.ps1', '-Seed', '1337', '-Cases', "$VmCases")

Write-Host "[prod-win] powershell suite..."
Run-Checked -Exe $pwshExe -Args @('-NoLogo', '-NoProfile', '-File', './scripts/test_v3.ps1')
Run-Checked -Exe $pwshExe -Args @('-NoLogo', '-NoProfile', '-File', './scripts/test_v4.ps1')
Run-Checked -Exe $pwshExe -Args @('-NoLogo', '-NoProfile', '-File', './scripts/test_compatibility.ps1')
Run-Checked -Exe $pwshExe -Args @('-NoLogo', '-NoProfile', '-File', './scripts/test_registry.ps1')
Run-Checked -Exe $pwshExe -Args @('-NoLogo', '-NoProfile', '-File', './scripts/test_runtime_hardening.ps1')
Run-Checked -Exe $pwshExe -Args @('-NoLogo', '-NoProfile', '-File', './scripts/test_sanitizers.ps1')
Run-Checked -Exe $pwshExe -Args @('-NoLogo', '-NoProfile', '-File', './scripts/test_fuzz_vm.ps1', '-Seed', '4242', '-Cases', '500')
Run-Checked -Exe $pwshExe -Args @('-NoLogo', '-NoProfile', '-File', './scripts/test_soak_runtime.ps1', '-Iterations', '40')

Write-Host "[prod-win] powershell tooling smoke..."
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("ny_prod_" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
    $minPath = Join-Path $tmp 'min.ny'
@"
let x = 1;
print(x);
"@ | Set-Content -NoNewline -LiteralPath $minPath

    Run-Checked -Exe $pwshExe -Args @('-NoLogo', '-NoProfile', '-File', './scripts/nyfmt.ps1', $minPath)
    Run-Checked -Exe $pwshExe -Args @('-NoLogo', '-NoProfile', '-File', './scripts/nyfmt.ps1', '-Check', $minPath)
    # Run-Checked -Exe $pwshExe -Args @('-NoLogo', '-NoProfile', '-File', './scripts/nydbg.ps1', $minPath)

    Push-Location $tmp
    try {
        New-Item -ItemType Directory -Force -Path './core' | Out-Null
        New-Item -ItemType Directory -Force -Path './app' | Out-Null
        $nypm = Join-Path $root 'scripts/nypm.ps1'
        Run-Checked -Exe $pwshExe -Args @('-NoLogo', '-NoProfile', '-File', $nypm, 'init', 'demo')
        Run-Checked -Exe $pwshExe -Args @('-NoLogo', '-NoProfile', '-File', $nypm, 'add', 'core', './core', '1.2.3')
        Run-Checked -Exe $pwshExe -Args @('-NoLogo', '-NoProfile', '-File', $nypm, 'add', 'app', './app', '0.1.0', 'core@^1.0.0')
        Run-Checked -Exe $pwshExe -Args @('-NoLogo', '-NoProfile', '-File', $nypm, 'resolve', 'app')
        Run-Checked -Exe $pwshExe -Args @('-NoLogo', '-NoProfile', '-File', $nypm, 'lock', 'app')
        Run-Checked -Exe $pwshExe -Args @('-NoLogo', '-NoProfile', '-File', $nypm, 'verify-lock')
        Run-Checked -Exe $pwshExe -Args @('-NoLogo', '-NoProfile', '-File', $nypm, 'install', 'app', './.nydeps')
        Run-Checked -Exe $pwshExe -Args @('-NoLogo', '-NoProfile', '-File', $nypm, 'doctor')
    }
    finally {
        Pop-Location
    }
}
finally {
    Remove-Item -Recurse -Force $tmp
}

Write-Host "[prod-win] PASS"
