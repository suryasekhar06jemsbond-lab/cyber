param(
    [int]$Seed = 1337,
    [int]$Cases = 300
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

$script:Rng = [System.Random]::new($Seed)

function New-RandInt {
    return ($script:Rng.Next(41) - 20)
}

function New-IntExpr {
    param([Parameter(Mandatory = $true)] [int]$Depth)

    if ($Depth -le 0) {
        return [string](New-RandInt)
    }

    $choice = $script:Rng.Next(5)
    switch ($choice) {
        0 { return [string](New-RandInt) }
        1 {
            $inner = New-IntExpr -Depth ($Depth - 1)
            return "(-$inner)"
        }
        2 {
            $inner = New-IntExpr -Depth ($Depth - 1)
            return "($inner)"
        }
        default {
            $ops = @('+', '-', '*')
            $op = $ops[$script:Rng.Next($ops.Length)]
            $left = New-IntExpr -Depth ($Depth - 1)
            $right = New-IntExpr -Depth ($Depth - 1)
            return "(($left) $op ($right))"
        }
    }
}

function New-BoolExpr {
    param([Parameter(Mandatory = $true)] [int]$Depth)

    if ($Depth -le 0) {
        $ops = @('==', '!=', '<', '>', '<=', '>=')
        $op = $ops[$script:Rng.Next($ops.Length)]
        $left = New-IntExpr -Depth 0
        $right = New-IntExpr -Depth 0
        return "(($left) $op ($right))"
    }

    $choice = $script:Rng.Next(5)
    switch ($choice) {
        0 {
            $ops = @('==', '!=', '<', '>', '<=', '>=')
            $op = $ops[$script:Rng.Next($ops.Length)]
            $left = New-IntExpr -Depth ($Depth - 1)
            $right = New-IntExpr -Depth ($Depth - 1)
            return "(($left) $op ($right))"
        }
        1 {
            $inner = New-BoolExpr -Depth ($Depth - 1)
            return "(!$inner)"
        }
        2 {
            $inner = New-BoolExpr -Depth ($Depth - 1)
            return "($inner)"
        }
        default {
            $ops = @('==', '!=')
            $op = $ops[$script:Rng.Next($ops.Length)]
            $left = New-BoolExpr -Depth ($Depth - 1)
            $right = New-BoolExpr -Depth ($Depth - 1)
            return "(($left) $op ($right))"
        }
    }
}

function New-Expr {
    param([Parameter(Mandatory = $true)] [int]$Depth)
    if ($script:Rng.Next(2) -eq 0) {
        return New-IntExpr -Depth $Depth
    }
    return New-BoolExpr -Depth $Depth
}

Write-Host "[vm-consistency] building native runtime..."
$compiler = Resolve-CCompiler
$runtimeExe = Join-Path $root ("nyx" + $exeExt)
$nativeSource = Join-Path $root 'native/nyx.c'
Build-C -Compiler $compiler -Output $runtimeExe -Source $nativeSource

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("ny_vm_" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null

try {
    Write-Host ("[vm-consistency] seed={0} cases={1}" -f $Seed, $Cases)
    for ($i = 1; $i -le $Cases; $i++) {
        $depth = $script:Rng.Next(1, 5)
        $expr = New-Expr -Depth $depth
        $path = Join-Path $tmp ("case_{0}.ny" -f $i)
        Set-Content -NoNewline -LiteralPath $path -Value "$expr;"

        $outAst = Run-ProcessText -Exe $runtimeExe -Args @($path)
        $outVm = Run-ProcessText -Exe $runtimeExe -Args @('--vm', $path)

        if ($outAst -ne $outVm) {
            throw "AST/VM mismatch on case $i`nexpr: $expr`nAST: $outAst`nVM:  $outVm"
        }
    }

    Write-Host "[vm-consistency] PASS"
}
finally {
    Remove-Item -Recurse -Force $tmp
}
