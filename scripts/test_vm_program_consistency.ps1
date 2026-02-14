param(
    [int]$Seed = 5150,
    [int]$Cases = 120
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

Write-Host "[vm-prog-consistency-win] building native runtime..."
$compiler = Resolve-CCompiler
$runtimeExe = Join-Path $root ("nyx" + $exeExt)
$nativeSource = Join-Path $root 'native/nyx.c'
Build-C -Compiler $compiler -Output $runtimeExe -Source $nativeSource

$rng = [System.Random]::new($Seed)
$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("cy_vm_prog_" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null

try {
    Write-Host ("[vm-prog-consistency-win] seed={0} cases={1}" -f $Seed, $Cases)
    for ($i = 1; $i -le $Cases; $i++) {
        $n = $rng.Next(3, 9)
        $skip = $rng.Next(1, $n + 1)
        $offset = $rng.Next(-2, 3)
        $threshold = $rng.Next(1, 4)
        $factor = $rng.Next(1, 5)

        $path = Join-Path $tmp ("case_{0}.ny" -f $i)
@"
fn mul(a, b) {
    return a * b;
}

module Math {
    fn inc(x) {
        return x + 1;
    }
}

class Box {
    fn init(self, v) {
        object_set(self, "v", v);
    }
    fn get(self) {
        return object_get(self, "v");
    }
}

let acc = 0;
let i = 0;
while (i < $n) {
    i = i + 1;
    if (i == $skip) {
        continue;
    }
    acc = acc + i;
}

let arr = [x + $offset for x in [1, 2, 3, 4, 5] if x > $threshold];
let sum = 0;
for (v in arr) {
    sum = sum + v;
}

try {
    if (sum > 0) {
        throw "boom";
    }
} catch (e) {
    acc = acc + 1;
}

let b = new(Box, acc);
print(mul(Math.inc(b.get()), $factor) + sum + len(arr));
"@ | Set-Content -NoNewline -LiteralPath $path

        $outAst = Run-ProcessText -Exe $runtimeExe -Args @($path)
        $outVm = Run-ProcessText -Exe $runtimeExe -Args @('--vm-strict', $path)

        if ($outAst -ne $outVm) {
            throw "AST/VM strict mismatch on case $i`nAST: $outAst`nVM:  $outVm"
        }
    }

    Write-Host '[vm-prog-consistency-win] PASS'
}
finally {
    Remove-Item -Recurse -Force $tmp
}
