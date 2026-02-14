$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
$isWin = $false
if ($null -ne (Get-Variable -Name IsWindows -ErrorAction SilentlyContinue)) {
    $isWin = [bool]$IsWindows
} elseif ($env:OS -eq 'Windows_NT') {
    $isWin = $true
}
$exeExt = if ($isWin) { '.exe' } else { '' }

function Resolve-CCompiler {
    $clangCmd = Get-Command clang -ErrorAction SilentlyContinue
    if ($clangCmd) { return @{ Kind = 'clang'; Exe = $clangCmd.Source } }

    $llvmClang = 'C:\Program Files\LLVM\bin\clang.exe'
    if (Test-Path -LiteralPath $llvmClang) { return @{ Kind = 'clang'; Exe = $llvmClang } }

    $gccCmd = Get-Command gcc -ErrorAction SilentlyContinue
    if ($gccCmd) { return @{ Kind = 'gcc'; Exe = $gccCmd.Source } }

    $clCmd = Get-Command cl -ErrorAction SilentlyContinue
    if ($clCmd) { return @{ Kind = 'cl'; Exe = $clCmd.Source } }

    throw "No C compiler found. Install LLVM (clang), MinGW (gcc), or run in Visual Studio Developer PowerShell (cl)."
}

function Build-C {
    param(
        [Parameter(Mandatory = $true)] [hashtable] $Compiler,
        [Parameter(Mandatory = $true)] [string] $Output,
        [Parameter(Mandatory = $true)] [string] $Source
    )

    if ($Compiler.Kind -eq 'cl') {
        & $Compiler.Exe /nologo /W4 /WX $Source /Fe:$Output | Out-Null
        if ($LASTEXITCODE -ne 0) { throw "C compilation failed: $Source -> $Output" }
        return
    }

    & $Compiler.Exe -O2 -std=c99 -Wall -Wextra -Werror -o $Output $Source
    if ($LASTEXITCODE -ne 0) { throw "C compilation failed: $Source -> $Output" }
}

function Run-ProcessText {
    param(
        [Parameter(Mandatory = $true)] [string] $Exe,
        [Parameter()] [string[]] $Args = @()
    )

    $raw = (& $Exe @Args 2>&1 | Out-String)
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed ($LASTEXITCODE): $Exe $($Args -join ' ')`n$raw"
    }
    $normalized = $raw -replace "`r`n", "`n" -replace "`r", "`n"
    return $normalized.TrimEnd("`n")
}

Write-Host "[hardening-win] building native runtime..."
$compiler = Resolve-CCompiler
$runtimeExe = Join-Path $root ("nyx" + $exeExt)
$nativeSource = Join-Path $root 'native/nyx.c'
Build-C -Compiler $compiler -Output $runtimeExe -Source $nativeSource

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("cy_hard_" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null

try {
    $stepPath = Join-Path $tmp 'step_limit.ny'
@"
let i = 0;
while (true) {
    i = i + 1;
}
"@ | Set-Content -NoNewline -LiteralPath $stepPath

    & $runtimeExe '--max-steps' '120' $stepPath *> (Join-Path $tmp 'step.err')
    if ($LASTEXITCODE -eq 0) {
        throw "--max-steps should fail on infinite loop"
    }
    $stepErr = Get-Content -Raw -LiteralPath (Join-Path $tmp 'step.err')
    if ($stepErr -notmatch 'max step count exceeded') {
        throw "missing max step count error"
    }

    $callPath = Join-Path $tmp 'call_limit.ny'
@"
fn dive(n) {
    return dive(n + 1);
}

dive(0);
"@ | Set-Content -NoNewline -LiteralPath $callPath

    & $runtimeExe '--max-call-depth' '64' $callPath *> (Join-Path $tmp 'call.err')
    if ($LASTEXITCODE -eq 0) {
        throw "--max-call-depth should fail on unbounded recursion"
    }
    $callErr = Get-Content -Raw -LiteralPath (Join-Path $tmp 'call.err')
    if ($callErr -notmatch 'max call depth exceeded') {
        throw "missing max call depth error"
    }

    $okPath = Join-Path $tmp 'ok.ny'
@"
fn add(a, b) {
    return a + b;
}

print(add(40, 2));
"@ | Set-Content -NoNewline -LiteralPath $okPath

    $out = Run-ProcessText -Exe $runtimeExe -Args @('--max-steps', '200', '--max-call-depth', '64', $okPath)
    if ($out -ne '42') {
        throw "limited runtime produced unexpected output: $out"
    }

    Write-Host '[hardening-win] PASS'
}
finally {
    Remove-Item -Recurse -Force $tmp
}
