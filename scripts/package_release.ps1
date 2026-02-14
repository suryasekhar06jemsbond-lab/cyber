param(
    [string]$Target,
    [string]$BinaryPath,
    [string]$OutDir
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path $OutDir)) {
    New-Item -ItemType Directory -Path $OutDir | Out-Null
}

$zipName = "nyx-$Target.zip"
$zipPath = Join-Path $OutDir $zipName
$tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) ("ny_pkg_" + [guid]::NewGuid().ToString('N'))

New-Item -ItemType Directory -Path $tmpDir | Out-Null

try {
    # Copy binary
    Copy-Item -LiteralPath $BinaryPath -Destination (Join-Path $tmpDir 'nyx.exe')

    # Copy scripts
    $scriptsDir = Join-Path $tmpDir 'scripts'
    New-Item -ItemType Directory -Path $scriptsDir | Out-Null
    Copy-Item -LiteralPath 'scripts/nypm.ps1' -Destination $scriptsDir
    Copy-Item -LiteralPath 'scripts/nyfmt.ps1' -Destination $scriptsDir
    Copy-Item -LiteralPath 'scripts/nylint.ps1' -Destination $scriptsDir
    Copy-Item -LiteralPath 'scripts/nydbg.ps1' -Destination $scriptsDir
    
    # Copy stdlib
    $stdlibDir = Join-Path $tmpDir 'stdlib'
    New-Item -ItemType Directory -Path $stdlibDir | Out-Null
    Copy-Item -LiteralPath 'stdlib/types.ny' -Destination $stdlibDir
    Copy-Item -LiteralPath 'stdlib/class.ny' -Destination $stdlibDir

    # Copy compiler
    $compilerDir = Join-Path $tmpDir 'compiler'
    New-Item -ItemType Directory -Path $compilerDir | Out-Null
    Copy-Item -LiteralPath 'compiler/bootstrap.ny' -Destination $compilerDir
    
    # Copy examples
    $examplesDir = Join-Path $tmpDir 'examples'
    New-Item -ItemType Directory -Path $examplesDir | Out-Null
    Copy-Item -LiteralPath 'examples/fibonacci.ny' -Destination $examplesDir

    # Copy README
    Copy-Item -LiteralPath 'README.md' -Destination $tmpDir

    if (Test-Path $zipPath) { Remove-Item $zipPath }
    Compress-Archive -Path "$tmpDir\*" -DestinationPath $zipPath
    
    $hash = (Get-FileHash $zipPath -Algorithm SHA256).Hash.ToLower()
    Set-Content -Path "$zipPath.sha256" -Value "$hash  $zipName"
    
    Write-Host "Created $zipPath"
    Write-Host "Created $zipPath.sha256"
}
finally {
    Remove-Item -Recurse -Force $tmpDir -ErrorAction SilentlyContinue
}