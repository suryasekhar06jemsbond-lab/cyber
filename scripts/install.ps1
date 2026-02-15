param(
    [string]$Repo = 'suryasekhar06jemsbond-lab/cyber',
    [string]$Version = 'latest',
    [string]$InstallRoot = "$HOME\\AppData\\Local\\Programs\\nyx",
    [string]$InstallDir,
    [string]$Asset,
    [string]$BinaryName = 'nyx.exe',
    [switch]$Force
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

if ($PSBoundParameters.ContainsKey('InstallDir') -and -not $PSBoundParameters.ContainsKey('InstallRoot')) {
    $InstallRoot = Split-Path -Parent $InstallDir
}

if ([string]::IsNullOrWhiteSpace($InstallDir)) {
    $InstallDir = Join-Path $InstallRoot 'bin'
}

$supportRoot = Join-Path $InstallRoot 'support'
$statePath = Join-Path $supportRoot 'install-state.txt'
$destPath = Join-Path $InstallDir $BinaryName

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
    $Asset = "nyx-windows-$arch.zip"
}

if ($Version -eq 'latest') {
    $baseUrl = "https://github.com/$Repo/releases/latest/download"
} else {
    $baseUrl = "https://github.com/$Repo/releases/download/$Version"
}
$url = "$baseUrl/$Asset"
$hashUrl = "$url.sha256"

$tmpRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("ny_install_" + [guid]::NewGuid().ToString('N'))
$zipPath = Join-Path $tmpRoot $Asset
$hashPath = Join-Path $tmpRoot ($Asset + '.sha256')
$unpackPath = Join-Path $tmpRoot 'unpack'

New-Item -ItemType Directory -Path $tmpRoot | Out-Null

function Invoke-WebDownload {
    param(
        [Parameter(Mandatory = $true)] [string] $Uri,
        [Parameter(Mandatory = $true)] [string] $OutFile,
        [int]$Retries = 2,
        [switch]$Quiet
    )

    $attempt = 0
    while ($attempt -le $Retries) {
        try {
            $params = @{
                Uri     = $Uri
                OutFile = $OutFile
            }
            if ($PSVersionTable.PSVersion.Major -lt 6) {
                $params.UseBasicParsing = $true
            }
            Invoke-WebRequest @params
            return $true
        }
        catch {
            if ($attempt -ge $Retries) {
                if ($Quiet) { return $false }
                throw
            }
            Start-Sleep -Seconds ([Math]::Min(2 + $attempt, 5))
        }
        $attempt++
    }
    return $false
}

function Resolve-ReleaseAssetUrl {
    param(
        [Parameter(Mandatory = $true)] [string] $RepoName,
        [Parameter(Mandatory = $true)] [string] $TagName,
        [Parameter(Mandatory = $true)] [string] $AssetName
    )

    $api = "https://api.github.com/repos/$RepoName/releases/tags/$TagName"
    try {
        $params = @{
            Uri     = $api
            Headers = @{ 'User-Agent' = 'nyx-installer' }
        }
        if ($PSVersionTable.PSVersion.Major -lt 6) {
            $params.UseBasicParsing = $true
        }
        $release = Invoke-RestMethod @params
        $assetObj = $release.assets | Where-Object { $_.name -eq $AssetName } | Select-Object -First 1
        if ($assetObj -and $assetObj.browser_download_url) {
            return [string]$assetObj.browser_download_url
        }
    }
    catch {
        return ''
    }
    return ''
}

function Get-ReleaseHash {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return '' }
    $line = (Get-Content -LiteralPath $Path -ErrorAction SilentlyContinue | Select-Object -First 1)
    if (-not $line) { return '' }
    $parts = ($line.Trim() -split '\s+')
    if ($parts.Count -lt 1) { return '' }
    return $parts[0].Trim().ToLowerInvariant()
}

function Get-InstalledHash {
    if (-not (Test-Path -LiteralPath $statePath)) { return '' }
    foreach ($lineRaw in Get-Content -LiteralPath $statePath -ErrorAction SilentlyContinue) {
        if ($lineRaw -match '^sha256=(.+)$') {
            return $Matches[1].Trim().ToLowerInvariant()
        }
    }
    return ''
}

function Get-InstalledValue {
    param([string]$Key)
    if (-not (Test-Path -LiteralPath $statePath)) { return '' }
    foreach ($lineRaw in Get-Content -LiteralPath $statePath -ErrorAction SilentlyContinue) {
        if ($lineRaw -match ("^" + [Regex]::Escape($Key) + "=(.+)$")) {
            return $Matches[1].Trim()
        }
    }
    return ''
}

function Copy-DirReplace {
    param(
        [string]$Source,
        [string]$Destination
    )
    if (-not (Test-Path -LiteralPath $Source)) { return }
    if (Test-Path -LiteralPath $Destination) {
        Remove-Item -Recurse -Force -LiteralPath $Destination
    }
    $parent = Split-Path -Parent $Destination
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
    Copy-Item -Recurse -Force -LiteralPath $Source -Destination $Destination
}

function New-CmdShim {
    param([string]$Name)
    $scriptPath = Join-Path (Join-Path $supportRoot 'scripts') "$Name.ps1"
    if (-not (Test-Path -LiteralPath $scriptPath)) { return }

    $shimPath = Join-Path $InstallDir ($Name + '.cmd')
    $scriptEscaped = $scriptPath -replace '"', '""'
    $shim = @"
@echo off
setlocal
set "NYX_SCRIPT=$scriptEscaped"
if not exist "%NYX_SCRIPT%" (
  echo Missing support script: %NYX_SCRIPT%
  exit /b 1
)
where pwsh >nul 2>nul
if %errorlevel%==0 (
  pwsh -NoProfile -ExecutionPolicy Bypass -File "%NYX_SCRIPT%" %*
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%NYX_SCRIPT%" %*
)
exit /b %errorlevel%
"@
    Set-Content -NoNewline -Encoding ascii -LiteralPath $shimPath -Value $shim
}

try {
    $installedHash = Get-InstalledHash
    $installedVersion = Get-InstalledValue -Key 'version'
    $installedAsset = Get-InstalledValue -Key 'asset'

    if (-not $Force -and $Version -ne 'latest' -and (Test-Path -LiteralPath $destPath) -and $installedVersion -eq $Version -and $installedAsset -eq $Asset) {
        Write-Host ("Nyx {0} is already installed at {1}" -f $Version, $destPath)
        & $destPath --version
        exit 0
    }

    $remoteHash = ''
    if (-not $Force) {
        try {
            if (Invoke-WebDownload -Uri $hashUrl -OutFile $hashPath -Retries 1 -Quiet) {
                $remoteHash = Get-ReleaseHash -Path $hashPath
            } else {
                $remoteHash = ''
            }
        }
        catch {
            $remoteHash = Get-ReleaseHash -Path $hashPath
        }
    }

    if (-not $Force -and $remoteHash -and (Test-Path -LiteralPath $destPath) -and ($remoteHash -eq $installedHash)) {
        Write-Host ("Nyx is already up to date at {0} (sha256={1})" -f $destPath, $remoteHash)
        & $destPath --version
        exit 0
    }

    Write-Host ("Downloading {0}" -f $url)
    $downloaded = Invoke-WebDownload -Uri $url -OutFile $zipPath -Retries 2 -Quiet

    if (-not $downloaded -and $Version -ne 'latest') {
        $resolvedUrl = Resolve-ReleaseAssetUrl -RepoName $Repo -TagName $Version -AssetName $Asset
        if (-not [string]::IsNullOrWhiteSpace($resolvedUrl)) {
            Write-Host ("Retrying via release API URL: {0}" -f $resolvedUrl)
            $downloaded = Invoke-WebDownload -Uri $resolvedUrl -OutFile $zipPath -Retries 2 -Quiet
        }
    }

    if (-not $downloaded) {
        $releaseUrl = if ($Version -eq 'latest') {
            "https://github.com/$Repo/releases/latest"
        } else {
            "https://github.com/$Repo/releases/tag/$Version"
        }
        throw ((
            "Failed to download release asset '{0}' for version '{1}' from repo '{2}'. " +
            "Expected URL: {3}. " +
            "If this is a fresh tag, wait for the Release workflow to finish and confirm assets on {4}, then retry."
        ) -f $Asset, $Version, $Repo, $url, $releaseUrl)
    }

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
    New-Item -ItemType Directory -Force -Path $supportRoot | Out-Null

    $supportBinary = Join-Path $supportRoot $BinaryName
    Copy-Item -Force -LiteralPath $binaryPath -Destination $supportBinary
    Copy-Item -Force -LiteralPath $supportBinary -Destination $destPath

    Copy-DirReplace -Source (Join-Path $unpackPath 'scripts') -Destination (Join-Path $supportRoot 'scripts')
    Copy-DirReplace -Source (Join-Path $unpackPath 'stdlib') -Destination (Join-Path $supportRoot 'stdlib')
    Copy-DirReplace -Source (Join-Path $unpackPath 'compiler') -Destination (Join-Path $supportRoot 'compiler')
    Copy-DirReplace -Source (Join-Path $unpackPath 'examples') -Destination (Join-Path $supportRoot 'examples')
    Copy-DirReplace -Source (Join-Path $unpackPath 'docs') -Destination (Join-Path $supportRoot 'docs')

    $readmeSrc = Join-Path $unpackPath 'README.md'
    $readmeDst = Join-Path $supportRoot 'README.md'
    if (Test-Path -LiteralPath $readmeSrc) {
        Copy-Item -Force -LiteralPath $readmeSrc -Destination $readmeDst
    }

    New-CmdShim -Name 'nypm'
    New-CmdShim -Name 'nyfmt'
    New-CmdShim -Name 'nylint'
    New-CmdShim -Name 'nydbg'

    if (-not $remoteHash) {
        $remoteHash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
    }
    if ($remoteHash) {
        @(
            "repo=$Repo"
            "version=$Version"
            "asset=$Asset"
            "sha256=$remoteHash"
            ("installed_at=" + [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ'))
        ) | Set-Content -LiteralPath $statePath
    }

    Write-Host ("Installed {0}" -f $destPath)
    Write-Host ("Installed support files to {0}" -f $supportRoot)

    $pathUpdatedNow = $false
    $pathParts = ($env:Path -split ';')
    if ($pathParts -notcontains $InstallDir) {
        $env:Path = "$InstallDir;$env:Path"
        $pathUpdatedNow = $true
    }

    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if ([string]::IsNullOrWhiteSpace($userPath)) {
        [Environment]::SetEnvironmentVariable('Path', $InstallDir, 'User')
        $pathUpdatedNow = $true
    } else {
        $userParts = ($userPath -split ';')
        if ($userParts -notcontains $InstallDir) {
            [Environment]::SetEnvironmentVariable('Path', "$userPath;$InstallDir", 'User')
            $pathUpdatedNow = $true
        }
    }

    if ($pathUpdatedNow) {
        Write-Host ("Added to PATH: {0}" -f $InstallDir)
    }

    & $destPath --version
}
finally {
    Remove-Item -Recurse -Force $tmpRoot -ErrorAction SilentlyContinue
}
