param(
    [Parameter(Mandatory = $true)]
    [string]$Target,
    [string]$BinaryPath = '.\\build\\cy.exe',
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

$archiveName = "cy-$Target.zip"
$archivePath = Join-Path $outDirAbs $archiveName
$hashPath = "$archivePath.sha256"

$tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ("cy_pkg_" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmpDir | Out-Null

try {
    $stageBinary = Join-Path $tmpDir 'cy.exe'
    Copy-Item -Force -LiteralPath $binaryAbs -Destination $stageBinary

    if (Test-Path -LiteralPath $archivePath) {
        Remove-Item -Force -LiteralPath $archivePath
    }

    Compress-Archive -Path $stageBinary -DestinationPath $archivePath -Force

    $hash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
    Set-Content -NoNewline -LiteralPath $hashPath -Value ("{0}  {1}" -f $hash, $archiveName)

    Write-Host ("Created {0}" -f $archivePath)
    Write-Host ("Created {0}" -f $hashPath)
}
finally {
    Remove-Item -Recurse -Force $tmpDir -ErrorAction SilentlyContinue
}
