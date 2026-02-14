param(
    [Parameter(Mandatory = $true)]
    [string]$Target,
    [string]$BinaryPath = '.\\build\\cyper.exe',
    [string]$OutDir = '.\\dist'
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$binaryAbs = if ([System.IO.Path]::IsPathRooted($BinaryPath)) { $BinaryPath } else { Join-Path $root $BinaryPath }
$outDirAbs = if ([System.IO.Path]::IsPathRooted($OutDir)) { $OutDir } else { Join-Path $root $OutDir }

if (-not (Test-Path -LiteralPath $binaryAbs)) {
    if ($BinaryPath -eq '.\build\cyper.exe') {
        $legacy = Join-Path $root '.\build\cy.exe'
        if (Test-Path -LiteralPath $legacy) {
            $binaryAbs = $legacy
        }
    }
}

if (-not (Test-Path -LiteralPath $binaryAbs)) {
    throw "Binary not found: $binaryAbs"
}

New-Item -ItemType Directory -Force -Path $outDirAbs | Out-Null

$archiveName = "cyper-$Target.zip"
$archivePath = Join-Path $outDirAbs $archiveName
$hashPath = "$archivePath.sha256"
$legacyArchiveName = "cy-$Target.zip"
$legacyArchivePath = Join-Path $outDirAbs $legacyArchiveName
$legacyHashPath = "$legacyArchivePath.sha256"

$tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ("cy_pkg_" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmpDir | Out-Null

try {
    $stageBinary = Join-Path $tmpDir 'cyper.exe'
    Copy-Item -Force -LiteralPath $binaryAbs -Destination $stageBinary
    Copy-Item -Force -LiteralPath $stageBinary -Destination (Join-Path $tmpDir 'cy.exe')

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

    $compilerFiles = @('bootstrap.cy', 'v3_seed.cy', 'bootstrap.nx', 'v3_seed.nx')
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
    if (Test-Path -LiteralPath $legacyArchivePath) {
        Remove-Item -Force -LiteralPath $legacyArchivePath
    }

    Compress-Archive -Path (Join-Path $tmpDir '*') -DestinationPath $archivePath -Force

    $hash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
    Set-Content -NoNewline -LiteralPath $hashPath -Value ("{0}  {1}" -f $hash, $archiveName)

    Copy-Item -Force -LiteralPath $archivePath -Destination $legacyArchivePath
    $legacyHash = (Get-FileHash -LiteralPath $legacyArchivePath -Algorithm SHA256).Hash.ToLowerInvariant()
    Set-Content -NoNewline -LiteralPath $legacyHashPath -Value ("{0}  {1}" -f $legacyHash, $legacyArchiveName)

    Write-Host ("Created {0}" -f $archivePath)
    Write-Host ("Created {0}" -f $hashPath)
    Write-Host ("Created {0}" -f $legacyArchivePath)
    Write-Host ("Created {0}" -f $legacyHashPath)
}
finally {
    Remove-Item -Recurse -Force $tmpDir -ErrorAction SilentlyContinue
}
