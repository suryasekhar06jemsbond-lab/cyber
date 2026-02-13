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

    throw "pwsh executable not found"
}

function Has-Cmd {
    param([Parameter(Mandatory = $true)] [string]$Name)
    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

$hasSh = Has-Cmd -Name 'sh'
$hasMake = Has-Cmd -Name 'make'
$pwshExe = Resolve-PwshExe

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
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("cy_prod_" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null
try {
    $minPath = Join-Path $tmp 'min.cy'
@"
let x = 1;
print(x);
"@ | Set-Content -NoNewline -LiteralPath $minPath

    Run-Checked -Exe $pwshExe -Args @('-NoLogo', '-NoProfile', '-File', './scripts/cyfmt.ps1', $minPath)
    Run-Checked -Exe $pwshExe -Args @('-NoLogo', '-NoProfile', '-File', './scripts/cyfmt.ps1', '-Check', $minPath)
    Run-Checked -Exe $pwshExe -Args @('-NoLogo', '-NoProfile', '-File', './scripts/cydbg.ps1', $minPath)

    Push-Location $tmp
    try {
        New-Item -ItemType Directory -Force -Path './core' | Out-Null
        New-Item -ItemType Directory -Force -Path './app' | Out-Null
        $cypm = Join-Path $root 'scripts/cypm.ps1'
        Run-Checked -Exe $pwshExe -Args @('-NoLogo', '-NoProfile', '-File', $cypm, 'init', 'demo')
        Run-Checked -Exe $pwshExe -Args @('-NoLogo', '-NoProfile', '-File', $cypm, 'add', 'core', './core', '1.2.3')
        Run-Checked -Exe $pwshExe -Args @('-NoLogo', '-NoProfile', '-File', $cypm, 'add', 'app', './app', '0.1.0', 'core@^1.0.0')
        Run-Checked -Exe $pwshExe -Args @('-NoLogo', '-NoProfile', '-File', $cypm, 'resolve', 'app')
        Run-Checked -Exe $pwshExe -Args @('-NoLogo', '-NoProfile', '-File', $cypm, 'lock', 'app')
        Run-Checked -Exe $pwshExe -Args @('-NoLogo', '-NoProfile', '-File', $cypm, 'verify-lock')
        Run-Checked -Exe $pwshExe -Args @('-NoLogo', '-NoProfile', '-File', $cypm, 'install', 'app', './.cydeps')
        Run-Checked -Exe $pwshExe -Args @('-NoLogo', '-NoProfile', '-File', $cypm, 'doctor')
    }
    finally {
        Pop-Location
    }
}
finally {
    Remove-Item -Recurse -Force $tmp
}

Write-Host "[prod-win] PASS"
