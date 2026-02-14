param(
    [int]$Iterations = 60
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

Write-Host "[soak-win] building native runtime..."
$compiler = Resolve-CCompiler
$runtimeExe = Join-Path $root ("nyx" + $exeExt)
$nativeSource = Join-Path $root 'native/nyx.c'
Build-C -Compiler $compiler -Output $runtimeExe -Source $nativeSource

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("cy_soak_" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null

try {
    $programPath = Join-Path $tmp 'soak.ny'
@"
fn fib(n) {
    if (n < 2) {
        return n;
    }
    return fib(n - 1) + fib(n - 2);
}

let total = 0;
for (x in [1, 2, 3, 4, 5]) {
    total = total + fib(x);
}

let ys = [n * 2 for n in [1, 2, 3, 4, 5] if n > 2];
print(total + ys[0] + len(ys));
"@ | Set-Content -NoNewline -LiteralPath $programPath

    $expected = '21'
    Write-Host ("[soak-win] iterations={0}" -f $Iterations)
    for ($i = 1; $i -le $Iterations; $i++) {
        $outAst = Run-ProcessText -Exe $runtimeExe -Args @('--max-steps', '500000', $programPath)
        $outVm = Run-ProcessText -Exe $runtimeExe -Args @('--vm-strict', '--max-steps', '500000', $programPath)

        if ($outAst -ne $expected) {
            throw "AST soak output mismatch at iteration ${i}: expected '$expected', got '$outAst'"
        }
        if ($outVm -ne $expected) {
            throw "VM soak output mismatch at iteration ${i}: expected '$expected', got '$outVm'"
        }
    }

    Write-Host '[soak-win] PASS'
}
finally {
    Remove-Item -Recurse -Force $tmp
}
