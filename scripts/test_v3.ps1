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
    if ($clangCmd) {
        return @{ Kind = 'clang'; Exe = $clangCmd.Source }
    }

    $llvmClang = 'C:\Program Files\LLVM\bin\clang.exe'
    if (Test-Path $llvmClang) {
        return @{ Kind = 'clang'; Exe = $llvmClang }
    }

    $gccCmd = Get-Command gcc -ErrorAction SilentlyContinue
    if ($gccCmd) {
        return @{ Kind = 'gcc'; Exe = $gccCmd.Source }
    }

    $clCmd = Get-Command cl -ErrorAction SilentlyContinue
    if ($clCmd) {
        return @{ Kind = 'cl'; Exe = $clCmd.Source }
    }

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

function Invoke-Checked {
    param(
        [Parameter(Mandatory = $true)] [string] $Exe,
        [Parameter()] [string[]] $Args = @()
    )
    & $Exe @Args
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed ($LASTEXITCODE): $Exe $($Args -join ' ')"
    }
}

function Run-ProcessText {
    param(
        [Parameter(Mandatory = $true)] [string] $Exe,
        [Parameter()] [string[]] $Args = @()
    )

    $raw = (& $Exe @Args | Out-String)
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed ($LASTEXITCODE): $Exe $($Args -join ' ')"
    }
    $normalized = $raw -replace "`r`n", "`n" -replace "`r", "`n"
    return $normalized.TrimEnd("`n")
}

$Compiler = Resolve-CCompiler
Write-Host ("[v3-win] using compiler: {0} ({1})" -f $Compiler.Kind, $Compiler.Exe)

Write-Host "[v3-win] building native runtime..."
$runtimeExe = Join-Path $root ("nyx" + $exeExt)
$nativeSource = Join-Path $root 'native/nyx.c'
Build-C -Compiler $Compiler -Output $runtimeExe -Source $nativeSource

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("ny_v3_" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null

try {
    $libPath = Join-Path $tmp 'lib.ny'
    $libPathNy = $libPath.Replace('\', '/')
@"
fn add(a, b) {
    return a + b;
}

fn inc(self, n) {
    return self.x + n;
}

fn point_ctor(self, x, y) {
    object_set(self, "x", x);
    object_set(self, "y", y);
    return null;
}
"@ | Set-Content -NoNewline $libPath

    $programPath = Join-Path $tmp 'program.ny'
@"
import "$libPathNy";

require_version(lang_version());
typealias IntType = "int";
print(IntType);

module Math {
    fn add2(a, b) {
        return a + b;
    }
    let tag = "math";
}
print(Math.add2(40, 2));
print(Math.tag);

class Point {
    fn init(self, x, y) {
        object_set(self, "x", x);
        object_set(self, "y", y);
    }
    fn sum(self) {
        return object_get(self, "x") + object_get(self, "y");
    }
}
let p = new(Point, 3, 4);
print(p.sum());
p.y = 9;
print(p.sum());

let i = 0;
let acc = 0;
while (i < 5) {
    i = i + 1;
    if (i == 3) {
        continue;
    }
    acc = acc + i;
}
print(acc);

let total = 0;
for (n in [1, 2, 3]) {
    total = total + n;
}
print(total);

if (false) {
    print("bad");
} else if (true) {
    print("elif");
} else {
    print("bad");
}

let pair_sum = 0;
for (i, n in [10, 20, 30]) {
    pair_sum = pair_sum + i + n;
}
print(pair_sum);

let obj2 = {x: 4, y: 5};
let obj_sum = 0;
for (k, v in obj2) {
    obj_sum = obj_sum + v;
}
print(obj_sum);

let pair_comp = [i + n for i, n in [1, 2, 3]];
print(pair_comp[2]);
print(len(range(1, 8, 3)));
print(int("42"));
print(str(99));
print(has(obj2, "x"));
print(len(values(obj2)));
print(len(items(obj2)));

let obj = {x: 40, inc: inc};
obj["y"] = 2;
print(obj.inc(obj["y"]));
print(len(keys(obj)));
let keys_arr = [k for k in obj];
print(len(keys_arr));

let ys = [n * 2 for n in [1, 2, 3, 4] if n > 2];
print(ys[0]);
print(len(ys));

print(10 % 3);
print(abs(-11));
print(min(5, 8));
print(max(5, 8));
print(clamp(15, 0, 10));
print(sum([1, 2, 3, 4]));
print(all([1, true, 3]));
print(any([0, false, 7]));

import "nymath";
import "nyarrays";
import "nyobjects";

print(nymath.pow(2, 5));
print(nyarrays.first([9, 8, 7]));
print(nyarrays.last([9, 8, 7]));
let em = nyarrays.enumerate([4, 5, 6]);
print(em[1][0]);
print(em[1][1]);
let merged = nyobjects.merge({a: 1}, {b: 2});
print(len(keys(merged)));
print(nyobjects.get_or(merged, "a", 0));
print(nyobjects.get_or(merged, "z", 9));
if (true && true) {
    print("and");
}
if (false || true) {
    print("or");
}

try {
    throw "boom";
} catch (e) {
    print(e);
}
"@ | Set-Content -NoNewline $programPath

    $stage1C = Join-Path $tmp 'compiler_stage1.c'
    $stage1Exe = Join-Path $tmp ("compiler_stage1" + $exeExt)
    $stage2C = Join-Path $tmp 'compiler_stage2.c'
    $stage2Exe = Join-Path $tmp ("compiler_stage2" + $exeExt)
    $stage3C = Join-Path $tmp 'compiler_stage3.c'
    $seedPath = Join-Path $root 'compiler/v3_seed.ny'
    $seedPathNy = $seedPath -replace '\\', '/'

    Write-Host "[v3-win] compiling compiler source with output path..."
    Invoke-Checked -Exe $runtimeExe -Args @($seedPathNy, $seedPathNy, $stage1C)
    Build-C -Compiler $Compiler -Output $stage1Exe -Source $stage1C

    Write-Host "[v3-win] compiling rich program with rebuilt compiler..."
    $programC = Join-Path $tmp 'program.c'
    $programExe = Join-Path $tmp ("program" + $exeExt)
    Invoke-Checked -Exe $stage1Exe -Args @($programPath, $programC)
    Build-C -Compiler $Compiler -Output $programExe -Source $programC
    $programOut = Run-ProcessText -Exe $programExe
    $expected = "int`n42`nmath`n7`n12`n12`n6`nelif`n63`n9`n5`n3`n42`n99`ntrue`n2`n2`n42`n3`n3`n6`n2`n1`n11`n5`n8`n10`n10`ntrue`ntrue`n32`n9`n7`n1`n5`n2`n1`n9`nand`nor`nboom"
    if ($programOut -ne $expected) {
        throw "compiled rich program output mismatch: expected '$expected', got '$programOut'"
    }

    Write-Host "[v3-win] deterministic rebuild loop..."
    Invoke-Checked -Exe $stage1Exe -Args @($seedPathNy, $stage2C, '--emit-self')
    Build-C -Compiler $Compiler -Output $stage2Exe -Source $stage2C
    Invoke-Checked -Exe $stage2Exe -Args @($seedPathNy, $stage3C, '--emit-self')

    $h1 = (Get-FileHash $stage1C -Algorithm SHA256).Hash
    $h2 = (Get-FileHash $stage2C -Algorithm SHA256).Hash
    $h3 = (Get-FileHash $stage3C -Algorithm SHA256).Hash

    if ($h1 -ne $h2 -or $h2 -ne $h3) {
        throw "determinism mismatch: stage hashes differ"
    }

    Write-Host "[v3-win] PASS"
}
finally {
    Remove-Item -Recurse -Force $tmp
}
