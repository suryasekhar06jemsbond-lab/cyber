param(
    [string]$Repo = 'suryasekhar06jemsbond-lab/cyber',
    [string]$Version = 'latest',
    [string]$InstallDir = "$HOME\\AppData\\Local\\Programs\\cy\\bin",
    [string]$Asset,
    [string]$BinaryName = 'cy.exe'
)

$ErrorActionPreference = 'Stop'

$isWin = $false
if ($null -ne (Get-Variable -Name IsWindows -ErrorAction SilentlyContinue)) {
    $isWin = [bool]$IsWindows
} elseif ($env:OS -eq 'Windows_NT') {
    $isWin = $true
}

if (-not $isWin) {
    throw 'scripts/install.ps1 is intended for Windows environments.'
}

function Get-Arch {
    $archVars = @($env:PROCESSOR_ARCHITECTURE, $env:PROCESSOR_ARCHITEW6432)
    foreach ($a in $archVars) {
        if ($a -and $a.ToUpperInvariant().Contains('ARM64')) {
            return 'arm64'
        }
    }
    return 'x64'
}

if ([string]::IsNullOrWhiteSpace($Asset)) {
    $arch = Get-Arch
    $Asset = "cy-windows-$arch.zip"
}

if ($Version -eq 'latest') {
    $url = "https://github.com/$Repo/releases/latest/download/$Asset"
} else {
    $url = "https://github.com/$Repo/releases/download/$Version/$Asset"
}

$tmpRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("cy_install_" + [guid]::NewGuid().ToString('N'))
$zipPath = Join-Path $tmpRoot $Asset
$unpackPath = Join-Path $tmpRoot 'unpack'

New-Item -ItemType Directory -Path $tmpRoot | Out-Null

try {
    Write-Host ("Downloading {0}" -f $url)
    Invoke-WebRequest -Uri $url -OutFile $zipPath

    New-Item -ItemType Directory -Path $unpackPath | Out-Null
    Expand-Archive -Path $zipPath -DestinationPath $unpackPath -Force

    $binaryPath = Join-Path $unpackPath $BinaryName
    if (-not (Test-Path -LiteralPath $binaryPath)) {
        $found = Get-ChildItem -Path $unpackPath -Recurse -File -Filter $BinaryName | Select-Object -First 1
        if ($found) {
            $binaryPath = $found.FullName
        }
    }

    if (-not (Test-Path -LiteralPath $binaryPath)) {
        throw "Binary '$BinaryName' not found in downloaded archive"
    }

    New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
    $destPath = Join-Path $InstallDir $BinaryName
    Copy-Item -Force -LiteralPath $binaryPath -Destination $destPath

    Write-Host ("Installed {0}" -f $destPath)

    $pathParts = ($env:Path -split ';')
    if ($pathParts -notcontains $InstallDir) {
        Write-Host ("Add to PATH (current user): [Environment]::SetEnvironmentVariable('Path', \$env:Path + ';{0}', 'User')" -f $InstallDir)
    }

    & $destPath --version
}
finally {
    Remove-Item -Recurse -Force $tmpRoot -ErrorAction SilentlyContinue
}
