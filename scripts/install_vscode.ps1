param(
    [string]$Repo = 'suryasekhar06jemsbond-lab/cyber',
    [string]$Version = 'latest',
    [string]$Asset = 'nyx-language.vsix',
    [string]$ExtensionId = 'suryasekhar06jemsbond-lab.nyx-language',
    [string]$CodeCmd
)

$ErrorActionPreference = 'Stop'

$isWin = $false
if ($null -ne (Get-Variable -Name IsWindows -ErrorAction SilentlyContinue)) {
    $isWin = [bool]$IsWindows
} elseif ($env:OS -eq 'Windows_NT') {
    $isWin = $true
}

if (-not $isWin) {
    throw 'scripts/install_vscode.ps1 is intended for Windows environments.'
}

function Invoke-WebDownload {
    param(
        [Parameter(Mandatory = $true)] [string]$Uri,
        [Parameter(Mandatory = $true)] [string]$OutFile,
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
        [Parameter(Mandatory = $true)] [string]$RepoName,
        [Parameter(Mandatory = $true)] [string]$TagName,
        [Parameter(Mandatory = $true)] [string]$AssetName
    )

    $api = "https://api.github.com/repos/$RepoName/releases/tags/$TagName"
    try {
        $params = @{
            Uri     = $api
            Headers = @{ 'User-Agent' = 'nyx-vscode-installer' }
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

function Resolve-CodeCommand {
    param([string]$RequestedPath)

    if (-not [string]::IsNullOrWhiteSpace($RequestedPath) -and (Test-Path -LiteralPath $RequestedPath)) {
        return $RequestedPath
    }

    # Prefer invoking through command name to avoid path+space quoting edge cases.
    $cmdCode = Get-Command code -ErrorAction SilentlyContinue
    if ($cmdCode) { return 'code' }

    $candidates = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\bin\code.cmd'),
        'C:\Program Files\Microsoft VS Code\bin\code.cmd'
    )
    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    return ''
}

$codePath = Resolve-CodeCommand -RequestedPath $CodeCmd
if ([string]::IsNullOrWhiteSpace($codePath)) {
    throw 'VS Code CLI not found. Install VS Code and ensure `code` command is available.'
}

if ($Version -eq 'latest') {
    $baseUrl = "https://github.com/$Repo/releases/latest/download"
} else {
    $baseUrl = "https://github.com/$Repo/releases/download/$Version"
}
$url = "$baseUrl/$Asset"

$tmpRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("nyx_vscode_" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path $tmpRoot | Out-Null
$vsixPath = Join-Path $tmpRoot $Asset

try {
    Write-Host ("Downloading {0}" -f $url)
    $downloaded = Invoke-WebDownload -Uri $url -OutFile $vsixPath -Retries 2 -Quiet

    if (-not $downloaded -and $Version -ne 'latest') {
        $resolvedUrl = Resolve-ReleaseAssetUrl -RepoName $Repo -TagName $Version -AssetName $Asset
        if (-not [string]::IsNullOrWhiteSpace($resolvedUrl)) {
            Write-Host ("Retrying via release API URL: {0}" -f $resolvedUrl)
            $downloaded = Invoke-WebDownload -Uri $resolvedUrl -OutFile $vsixPath -Retries 2 -Quiet
        }
    }

    if (-not $downloaded) {
        $releaseUrl = if ($Version -eq 'latest') {
            "https://github.com/$Repo/releases/latest"
        } else {
            "https://github.com/$Repo/releases/tag/$Version"
        }
        throw ((
            "Failed to download VS Code extension asset '{0}' for version '{1}' from repo '{2}'. " +
            "Expected URL: {3}. " +
            "If this is a fresh tag, wait for the Release workflow to finish and verify assets on {4}, then retry."
        ) -f $Asset, $Version, $Repo, $url, $releaseUrl)
    }

    if ($codePath -eq 'code') {
        $installCmd = 'code --install-extension "' + $vsixPath + '" --force'
    } else {
        $installCmd = '"' + $codePath + '" --install-extension "' + $vsixPath + '" --force'
    }
    & cmd.exe /c $installCmd
    if ($null -ne $LASTEXITCODE -and $LASTEXITCODE -ne 0) {
        throw "VS Code extension install failed (exit code $LASTEXITCODE)"
    }

    if ($codePath -eq 'code') {
        $listCmd = 'code --list-extensions'
    } else {
        $listCmd = '"' + $codePath + '" --list-extensions'
    }
    $exts = @(& cmd.exe /c $listCmd)
    if ($null -ne $LASTEXITCODE -and $LASTEXITCODE -ne 0) {
        throw "Failed to list VS Code extensions (exit code $LASTEXITCODE)"
    }

    $hasListed = $exts -contains $ExtensionId
    if (-not $hasListed) {
        $extHome = Join-Path $HOME '.vscode\extensions'
        $diskMatch = @()
        if (Test-Path -LiteralPath $extHome) {
            $diskMatch = @(Get-ChildItem -LiteralPath $extHome -Directory -ErrorAction SilentlyContinue |
                Where-Object { $_.Name -like ($ExtensionId + '-*') -or $_.Name -eq $ExtensionId })
        }
        if ($diskMatch.Count -eq 0) {
            throw "Extension installed but not found in extension list or extension directory: $ExtensionId"
        }
    }

    Write-Host ("Installed VS Code extension: {0}" -f $ExtensionId)
}
finally {
    Remove-Item -Recurse -Force -LiteralPath $tmpRoot -ErrorAction SilentlyContinue
}
