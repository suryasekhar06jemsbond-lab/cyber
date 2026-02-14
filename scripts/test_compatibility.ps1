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

    $raw = (& $Exe @Args 2>&1 | Out-String)
    if ($LASTEXITCODE -ne 0) {
        throw "Command failed ($LASTEXITCODE): $Exe $($Args -join ' ')`n$raw"
    }
    $normalized = $raw -replace "`r`n", "`n" -replace "`r", "`n"
    return $normalized.TrimEnd("`n")
}

Write-Host "[compat-win] building native runtime..."
$compiler = Resolve-CCompiler
$runtimeExe = Join-Path $root ("nyx" + $exeExt)
$nativeSource = Join-Path $root 'native/nyx.c'
Build-C -Compiler $compiler -Output $runtimeExe -Source $nativeSource

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("cy_compat_" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null

try {
    $version = Run-ProcessText -Exe $runtimeExe -Args @('--version')
    if ([string]::IsNullOrWhiteSpace($version)) {
        throw "--version returned empty output"
    }
    
    # Patch compiler template to match runtime version
    $templatePath = Join-Path $root 'compiler/v3_compiler_template.c'
    if (Test-Path $templatePath) {
        $tmplContent = Get-Content -Raw $templatePath
        $newTmpl = $tmplContent -replace '#define NYX_LANG_VERSION "[^"]+"', "#define NYX_LANG_VERSION `"$version`""
        Set-Content -NoNewline -Path $templatePath -Value $newTmpl
    }

    $okPath = Join-Path $tmp 'ok.ny'
@"
print(lang_version());
require_version(lang_version());
print("ok");
"@ | Set-Content -NoNewline -LiteralPath $okPath

    $badPath = Join-Path $tmp 'bad.ny'
@"
require_version("999.0.0");
print("unreachable");
"@ | Set-Content -NoNewline -LiteralPath $badPath

    $outOk = Run-ProcessText -Exe $runtimeExe -Args @($okPath)
    $expected = "$version`nok"
    if ($outOk -ne $expected) {
        throw "runtime version contract mismatch: expected '$expected', got '$outOk'"
    }

    & $runtimeExe $badPath *> (Join-Path $tmp 'bad_runtime.log')
    if ($LASTEXITCODE -eq 0) {
        throw "require_version mismatch should fail in runtime"
    }
    $badRuntime = Get-Content -Raw -LiteralPath (Join-Path $tmp 'bad_runtime.log')
    if ($badRuntime -notmatch 'language version mismatch') {
        throw "missing runtime version mismatch error message"
    }

    Write-Host "[compat-win] verifying compiled runtime compatibility..."
    $seedPath = Join-Path $root 'compiler/v3_seed.ny'
    $seedPathCy = $seedPath -replace '\\', '/'
    $stage1C = Join-Path $tmp 'compiler_stage1.c'
    $stage1Exe = Join-Path $tmp ("compiler_stage1" + $exeExt)
    Invoke-Checked -Exe $runtimeExe -Args @($seedPathCy, $seedPathCy, $stage1C)
    Build-C -Compiler $compiler -Output $stage1Exe -Source $stage1C

    $okC = Join-Path $tmp 'ok.c'
    $okExe = Join-Path $tmp ("ok_bin" + $exeExt)
    Invoke-Checked -Exe $stage1Exe -Args @($okPath, $okC)
    Build-C -Compiler $compiler -Output $okExe -Source $okC
    $outCompiledOk = Run-ProcessText -Exe $okExe
    if ($outCompiledOk -ne $expected) {
        throw "compiled version contract mismatch: expected '$expected', got '$outCompiledOk'"
    }

    $badC = Join-Path $tmp 'bad.c'
    $badExe = Join-Path $tmp ("bad_bin" + $exeExt)
    Invoke-Checked -Exe $stage1Exe -Args @($badPath, $badC)
    Build-C -Compiler $compiler -Output $badExe -Source $badC

    & $badExe *> (Join-Path $tmp 'bad_compiled.log')
    if ($LASTEXITCODE -eq 0) {
        throw "require_version mismatch should fail in compiled runtime"
    }
    $badCompiled = Get-Content -Raw -LiteralPath (Join-Path $tmp 'bad_compiled.log')
    if ($badCompiled -notmatch 'language version mismatch') {
        throw "missing compiled version mismatch error message"
    }

    Write-Host "[compat-win] PASS"
}
finally {
    Remove-Item -Recurse -Force $tmp
}
