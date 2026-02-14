$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("ny_reg_" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null

try {
    New-Item -ItemType Directory -Force -Path (Join-Path $tmp 'pkgs/core') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $tmp 'pkgs/util') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $tmp 'pkgs/app') | Out-Null

    'module Core { let v = 1; }' | Set-Content -NoNewline -LiteralPath (Join-Path $tmp 'pkgs/core/core.ny')
    'module Util { let v = 2; }' | Set-Content -NoNewline -LiteralPath (Join-Path $tmp 'pkgs/util/util.ny')
    'module App { let v = 3; }' | Set-Content -NoNewline -LiteralPath (Join-Path $tmp 'pkgs/app/app.ny')

    $registryPath = Join-Path $tmp 'ny.registry'
@"
# name|version|source|deps
core|1.0.0|./pkgs/core|
core|1.2.0|./pkgs/core|
util|2.1.0|./pkgs/util|core@^1.0.0
"@ | Set-Content -NoNewline -LiteralPath $registryPath

    Push-Location $tmp
    try {
        $nypm = Join-Path $root 'scripts/nypm.ps1'
        function Invoke-Nypm {
            param([string[]]$CommandArgs)
            & $nypm @CommandArgs
            if (-not $?) {
                throw "nypm failed: $($CommandArgs -join ' ')"
            }
        }

        Invoke-Nypm @('init', 'demo')
        Invoke-Nypm @('registry', 'set', $registryPath)

        $searchOut = (& $nypm search core | Out-String)
        if ($searchOut -notmatch 'core version=1.2.0') {
            throw "nypm search missing expected registry entry: $searchOut"
        }

        Invoke-Nypm @('add-remote', 'core', '^1.0.0')
        $listOut = (& $nypm list | Out-String)
        if ($listOut -notmatch [regex]::Escape("core=" + (Join-Path $tmp 'pkgs/core') + " version=1.2.0")) {
            throw "nypm add-remote did not select highest core version: $listOut"
        }

        Invoke-Nypm @('add-remote', 'util', '>=2.0.0')
        $resolvedRaw = (& $nypm resolve util | Out-String)
        $resolved = ($resolvedRaw -replace "`r`n", "`n" -replace "`r", "`n").TrimEnd("`n")
        $expected = "core`nutil"
        if ($resolved -ne $expected) {
            throw "nypm resolve mismatch: expected '$expected', got '$resolved'"
        }

        Invoke-Nypm @('install', 'util', './.nydeps')
        if (-not (Test-Path -LiteralPath (Join-Path $tmp '.nydeps/core'))) {
            throw 'nypm install missing core dependency dir'
        }
        if (-not (Test-Path -LiteralPath (Join-Path $tmp '.nydeps/util'))) {
            throw 'nypm install missing util dependency dir'
        }

        Invoke-Nypm @('publish', 'app', '0.1.0', (Join-Path $tmp 'pkgs/app'), 'util@>=2.0.0')
        Invoke-Nypm @('add-remote', 'app', '0.1.0')
        $listOut2 = (& $nypm list | Out-String)
        if ($listOut2 -notmatch [regex]::Escape("app=" + (Join-Path $tmp 'pkgs/app') + " version=0.1.0 deps=util@>=2.0.0")) {
            throw "nypm publish/add-remote app failed: $listOut2"
        }
    }
    finally {
        Pop-Location
    }

    Write-Host '[registry-win] PASS'
}
finally {
    Remove-Item -Recurse -Force $tmp
}
