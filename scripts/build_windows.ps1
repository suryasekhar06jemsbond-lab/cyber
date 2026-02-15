param(
    [string]$Output = 'nyx.exe',
    [switch]$SmokeTest,
    [switch]$NoIcon,
    [string]$LangVersion = $env:NYX_LANG_VERSION
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

if (-not $isWin) {
    throw 'scripts/build_windows.ps1 is intended for Windows environments.'
}

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

function Resolve-ResourceCompiler {
    $llvmRcCmd = Get-Command llvm-rc -ErrorAction SilentlyContinue
    if ($llvmRcCmd) { return @{ Kind = 'llvm-rc'; Exe = $llvmRcCmd.Source } }

    $llvmRc = 'C:\Program Files\LLVM\bin\llvm-rc.exe'
    if (Test-Path -LiteralPath $llvmRc) { return @{ Kind = 'llvm-rc'; Exe = $llvmRc } }

    $rcCmd = Get-Command rc -ErrorAction SilentlyContinue
    if ($rcCmd) { return @{ Kind = 'rc'; Exe = $rcCmd.Source } }

    $windresCmd = Get-Command windres -ErrorAction SilentlyContinue
    if ($windresCmd) { return @{ Kind = 'windres'; Exe = $windresCmd.Source } }

    return $null
}

function Compile-Resource {
    param(
        [Parameter(Mandatory = $true)] [hashtable] $Tool,
        [Parameter(Mandatory = $true)] [string] $RcPath,
        [Parameter(Mandatory = $true)] [string] $ResPath
    )

    if (Test-Path -LiteralPath $ResPath) {
        Remove-Item -Force -LiteralPath $ResPath
    }

    if ($Tool.Kind -eq 'llvm-rc') {
        & $Tool.Exe '/fo' $ResPath $RcPath
    } elseif ($Tool.Kind -eq 'rc') {
        & $Tool.Exe /nologo /fo $ResPath $RcPath
    } elseif ($Tool.Kind -eq 'windres') {
        & $Tool.Exe $RcPath -O coff -o $ResPath
    } else {
        throw "Unsupported resource compiler kind: $($Tool.Kind)"
    }

    if ($null -ne $LASTEXITCODE -and $LASTEXITCODE -ne 0) {
        throw "Resource compilation failed: $RcPath -> $ResPath"
    }
    if (-not (Test-Path -LiteralPath $ResPath)) {
        throw "Resource compilation did not produce output: $ResPath"
    }
}

function Build-Runtime {
    param(
        [Parameter(Mandatory = $true)] [hashtable] $Compiler,
        [Parameter(Mandatory = $true)] [string] $OutputPath,
        [Parameter(Mandatory = $true)] [string] $SourcePath,
        [Parameter()] [string] $ResPath,
        [Parameter(Mandatory = $true)] [string] $LangVersion
    )

    if (Test-Path -LiteralPath $OutputPath) {
        Remove-Item -Force -LiteralPath $OutputPath
    }

    $versionHeader = Join-Path ([System.IO.Path]::GetTempPath()) ("ny_lang_version_" + [guid]::NewGuid().ToString('N') + '.h')
    @(
        '#ifndef NYX_LANG_VERSION'
        ('#define NYX_LANG_VERSION "{0}"' -f $LangVersion)
        '#endif'
    ) | Set-Content -Encoding ascii -LiteralPath $versionHeader

    try {
        if ($Compiler.Kind -eq 'cl') {
            $args = @('/nologo', '/W4', '/WX', "/FI$versionHeader", $SourcePath)
            if ($ResPath) { $args += $ResPath }
            $args += "/Fe:$OutputPath"
            & $Compiler.Exe @args | Out-Null
            if ($null -ne $LASTEXITCODE -and $LASTEXITCODE -ne 0) { throw "C compilation failed: $SourcePath -> $OutputPath" }
            if (-not (Test-Path -LiteralPath $OutputPath)) { throw "C compilation did not produce output: $OutputPath" }
            return
        }

        $args = @('-O2', '-std=c99', '-Wall', '-Wextra', '-Werror', '-include', $versionHeader, '-o', $OutputPath, $SourcePath)
        if ($ResPath) { $args += $ResPath }
        & $Compiler.Exe @args
        if ($null -ne $LASTEXITCODE -and $LASTEXITCODE -ne 0) { throw "C compilation failed: $SourcePath -> $OutputPath" }
        if (-not (Test-Path -LiteralPath $OutputPath)) { throw "C compilation did not produce output: $OutputPath" }
    }
    finally {
        Remove-Item -Force -LiteralPath $versionHeader -ErrorAction SilentlyContinue
    }
}

function Write-CompatAlias {
    param([string]$PrimaryPath)

    $name = [System.IO.Path]::GetFileName($PrimaryPath).ToLowerInvariant()
    if ($name -ne 'nyx.exe') { return }
}

function Normalize-Text {
    param([string]$Text)
    $normalized = $Text -replace "`r`n", "`n" -replace "`r", "`n"
    return $normalized.TrimEnd("`n")
}

$compiler = Resolve-CCompiler
Write-Host ("[build-win] compiler: {0} ({1})" -f $compiler.Kind, $compiler.Exe)

if ([string]::IsNullOrWhiteSpace($LangVersion)) {
    $LangVersion = '0.10.0'
}
Write-Host ("[build-win] language version: {0}" -f $LangVersion)

$outputPath = if ([System.IO.Path]::IsPathRooted($Output)) {
    $Output
} else {
    Join-Path $root $Output
}
$outputDir = Split-Path -Parent $outputPath
if ($outputDir -and -not (Test-Path -LiteralPath $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir | Out-Null
}

$sourcePath = Join-Path $root 'native/nyx.c'
$rcPath = Join-Path $root 'native/nyx.rc'
$resPath = $null

try {
    if (-not $NoIcon -and (Test-Path -LiteralPath $rcPath)) {
        $resCompiler = Resolve-ResourceCompiler
        if ($resCompiler) {
            $buildDir = Join-Path $root 'build'
            if (-not (Test-Path -LiteralPath $buildDir)) {
                New-Item -ItemType Directory -Path $buildDir | Out-Null
            }
            $resPath = Join-Path $buildDir 'nyx_icon.res'
            Write-Host ("[build-win] embedding icon using {0} ({1})" -f $resCompiler.Kind, $resCompiler.Exe)
            try {
                Compile-Resource -Tool $resCompiler -RcPath $rcPath -ResPath $resPath
            }
            catch {
                Write-Warning ("[build-win] icon embedding failed: {0}" -f $_.Exception.Message)
                $resPath = $null
            }
        } else {
            Write-Warning '[build-win] no resource compiler found; building runtime without icon embedding'
        }
    }

    Write-Host ("[build-win] building {0}..." -f $outputPath)
    Build-Runtime -Compiler $compiler -OutputPath $outputPath -SourcePath $sourcePath -ResPath $resPath -LangVersion $LangVersion
    Write-CompatAlias -PrimaryPath $outputPath

    if ($SmokeTest) {
        $mainPath = Join-Path $root 'main.ny'
        $raw = (& $outputPath $mainPath | Out-String)
        if ($null -ne $LASTEXITCODE -and $LASTEXITCODE -ne 0) {
            throw "Smoke test failed while running: $outputPath $mainPath"
        }
        $out = Normalize-Text -Text $raw
        if ($out -ne '3') {
            throw "Smoke test output mismatch: expected '3', got '$out'"
        }
        Write-Host '[build-win] smoke test PASS'
    }

    Write-Host '[build-win] PASS'
}
finally {
    if ($resPath -and (Test-Path -LiteralPath $resPath)) {
        Remove-Item -Force -LiteralPath $resPath
    }
}
