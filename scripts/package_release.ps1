param(
    [Parameter(Mandatory = $true)]
    [string]$Target,
    [string]$BinaryPath = '.\\build\\nyx.exe',
    [string]$OutDir = '.\\dist'
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$binaryAbs = if ([System.IO.Path]::IsPathRooted($BinaryPath)) { $BinaryPath } else { Join-Path $root $BinaryPath }
$outDirAbs = if ([System.IO.Path]::IsPathRooted($OutDir)) { $OutDir } else { Join-Path $root $OutDir }

if (-not (Test-Path -LiteralPath $binaryAbs)) {
    throw "Binary not found: $binaryAbs"
}

New-Item -ItemType Directory -Force -Path $outDirAbs | Out-Null

$archiveName = "nyx-$Target.zip"
$archivePath = Join-Path $outDirAbs $archiveName
$hashPath = "$archivePath.sha256"

$tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ("cy_pkg_" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmpDir | Out-Null

try {
    $stageBinary = Join-Path $tmpDir 'nyx.exe'
    Copy-Item -Force -LiteralPath $binaryAbs -Destination $stageBinary

    $stageScripts = Join-Path $tmpDir 'scripts'
    $stageCompiler = Join-Path $tmpDir 'compiler'
    New-Item -ItemType Directory -Force -Path $stageScripts, $stageCompiler | Out-Null

    $scriptFiles = @(
        'cydbg.sh', 'cyfmt.sh', 'cylint.sh', 'cypm.sh',
        'cydbg.ps1', 'cyfmt.ps1', 'cylint.ps1', 'cypm.ps1'
    )
    foreach ($name in $scriptFiles) {
        $src = Join-Path $root ("scripts/" + $name)
        if (Test-Path -LiteralPath $src) {
            Copy-Item -Force -LiteralPath $src -Destination (Join-Path $stageScripts $name)
        }
    }

    $compilerFiles = @('bootstrap.nx', 'v3_seed.nx')
    foreach ($name in $compilerFiles) {
        $src = Join-Path $root ("compiler/" + $name)
        if (Test-Path -LiteralPath $src) {
            Copy-Item -Force -LiteralPath $src -Destination (Join-Path $stageCompiler $name)
        }
    }

    $copyDirs = @('stdlib', 'examples')
    foreach ($dirName in $copyDirs) {
        $src = Join-Path $root $dirName
        $dst = Join-Path $tmpDir $dirName
        if (Test-Path -LiteralPath $src) {
            Copy-Item -Recurse -Force -LiteralPath $src -Destination $dst
        }
    }

    $copyFiles = @('README.md', 'docs/LANGUAGE_SPEC.md')
    foreach ($relPath in $copyFiles) {
        $src = Join-Path $root $relPath
        if (Test-Path -LiteralPath $src) {
            $dst = Join-Path $tmpDir $relPath
            $dstDir = Split-Path -Parent $dst
            if ($dstDir -and -not (Test-Path -LiteralPath $dstDir)) {
                New-Item -ItemType Directory -Force -Path $dstDir | Out-Null
            }
            Copy-Item -Force -LiteralPath $src -Destination $dst
        }
    }

    if (Test-Path -LiteralPath $archivePath) {
        Remove-Item -Force -LiteralPath $archivePath
    }
    Compress-Archive -Path (Join-Path $tmpDir '*') -DestinationPath $archivePath -Force

    $hash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
    Set-Content -NoNewline -LiteralPath $hashPath -Value ("{0}  {1}" -f $hash, $archiveName)

    Write-Host ("Created {0}" -f $archivePath)
    Write-Host ("Created {0}" -f $hashPath)
}
finally {
    Remove-Item -Recurse -Force $tmpDir -ErrorAction SilentlyContinue
}
