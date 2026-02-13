$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root
$isWin = $IsWindows
$exeExt = if ($isWin) { '.exe' } else { '' }

function Resolve-CCompiler {
    $clangCmd = Get-Command clang -ErrorAction SilentlyContinue
    if ($clangCmd) { return @{ Kind = 'clang'; Exe = $clangCmd.Source } }

    $llvmClang = 'C:\Program Files\LLVM\bin\clang.exe'
    if (Test-Path $llvmClang) { return @{ Kind = 'clang'; Exe = $llvmClang } }

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
    return $raw.TrimEnd("`r", "`n")
}

$Compiler = Resolve-CCompiler
Write-Host "[v4-win] building native runtime..."
$runtimeExe = Join-Path $root ("cy" + $exeExt)
$nativeSource = Join-Path $root 'native/cy.c'
Build-C -Compiler $Compiler -Output $runtimeExe -Source $nativeSource

$tmp = Join-Path $env:TEMP ("cy_v4_" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null

try {
    $programPath = Join-Path $tmp 'v4.cy'
@"
require_version(lang_version());

typealias IntType = "int";
print(IntType);

module Math {
    fn add(a, b) {
        return a + b;
    }
    let tag = "math";
}

print(Math.add(40, 2));

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

let obj = {a: 1, b: 2};
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

import "cy:math";
import "cy:arrays";
import "cy:objects";

print(Math.pow(2, 5));
print(Arrays.first([9, 8, 7]));
print(Arrays.last([9, 8, 7]));
let em = Arrays.enumerate([4, 5, 6]);
print(em[1][0]);
print(em[1][1]);
let merged = Objects.merge({a: 1}, {b: 2});
print(len(keys(merged)));
print(Objects.get_or(merged, "a", 0));
print(Objects.get_or(merged, "z", 9));
"@ | Set-Content -NoNewline $programPath

    $expected = "int`n42`n7`n12`n6`nelif`n63`n9`n5`n3`n42`n99`ntrue`n2`n2`n2`n6`n2`n1`n11`n5`n8`n10`n10`ntrue`ntrue`n32`n9`n7`n1`n5`n2`n1`n9"

    Write-Host "[v4-win] running interpreter path..."
    $outAst = Run-ProcessText -Exe $runtimeExe -Args @($programPath)
    if ($outAst -ne $expected) {
        throw "v4 interpreter output mismatch: expected '$expected', got '$outAst'"
    }

    Write-Host "[v4-win] running vm path..."
    $outVm = Run-ProcessText -Exe $runtimeExe -Args @('--vm', $programPath)
    if ($outVm -ne $expected) {
        throw "v4 vm output mismatch: expected '$expected', got '$outVm'"
    }

    Write-Host "[v4-win] running vm strict path..."
    $outVmStrict = Run-ProcessText -Exe $runtimeExe -Args @('--vm-strict', $programPath)
    if ($outVmStrict -ne $expected) {
        throw "v4 vm-strict output mismatch: expected '$expected', got '$outVmStrict'"
    }

    Write-Host "[v4-win] lint check..."
    $lintScript = Join-Path $root 'scripts/cylint.ps1'
    Invoke-Checked -Exe $lintScript -Args @('-Strict', $programPath)

    Write-Host "[v4-win] PASS"
}
finally {
    Remove-Item -Recurse -Force $tmp
}
