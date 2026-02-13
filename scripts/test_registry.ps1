$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("cy_reg_" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null

try {
    New-Item -ItemType Directory -Force -Path (Join-Path $tmp 'pkgs/core') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $tmp 'pkgs/util') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $tmp 'pkgs/app') | Out-Null

    'module Core { let v = 1; }' | Set-Content -NoNewline -LiteralPath (Join-Path $tmp 'pkgs/core/core.cy')
    'module Util { let v = 2; }' | Set-Content -NoNewline -LiteralPath (Join-Path $tmp 'pkgs/util/util.cy')
    'module App { let v = 3; }' | Set-Content -NoNewline -LiteralPath (Join-Path $tmp 'pkgs/app/app.cy')

    $registryPath = Join-Path $tmp 'cy.registry'
@"
# name|version|source|deps
core|1.0.0|./pkgs/core|
core|1.2.0|./pkgs/core|
util|2.1.0|./pkgs/util|core@^1.0.0
"@ | Set-Content -NoNewline -LiteralPath $registryPath

    Push-Location $tmp
    try {
        $cypm = Join-Path $root 'scripts/cypm.ps1'
        function Invoke-Cypm {
            param([string[]]$CommandArgs)
            & $cypm @CommandArgs
            if (-not $?) {
                throw "cypm failed: $($CommandArgs -join ' ')"
            }
        }

        Invoke-Cypm @('init', 'demo')
        Invoke-Cypm @('registry', 'set', $registryPath)

        $searchOut = (& $cypm search core | Out-String)
        if ($searchOut -notmatch 'core version=1.2.0') {
            throw "cypm search missing expected registry entry: $searchOut"
        }

        Invoke-Cypm @('add-remote', 'core', '^1.0.0')
        $listOut = (& $cypm list | Out-String)
        if ($listOut -notmatch [regex]::Escape("core=" + (Join-Path $tmp 'pkgs/core') + " version=1.2.0")) {
            throw "cypm add-remote did not select highest core version: $listOut"
        }

        Invoke-Cypm @('add-remote', 'util', '>=2.0.0')
        $resolved = (& $cypm resolve util | Out-String).TrimEnd("`r", "`n")
        $expected = "core`nutil"
        if ($resolved -ne $expected) {
            throw "cypm resolve mismatch: expected '$expected', got '$resolved'"
        }

        Invoke-Cypm @('install', 'util', './.cydeps')
        if (-not (Test-Path -LiteralPath (Join-Path $tmp '.cydeps/core'))) {
            throw 'cypm install missing core dependency dir'
        }
        if (-not (Test-Path -LiteralPath (Join-Path $tmp '.cydeps/util'))) {
            throw 'cypm install missing util dependency dir'
        }

        Invoke-Cypm @('publish', 'app', '0.1.0', (Join-Path $tmp 'pkgs/app'), 'util@>=2.0.0')
        Invoke-Cypm @('add-remote', 'app', '0.1.0')
        $listOut2 = (& $cypm list | Out-String)
        if ($listOut2 -notmatch [regex]::Escape("app=" + (Join-Path $tmp 'pkgs/app') + " version=0.1.0 deps=util@>=2.0.0")) {
            throw "cypm publish/add-remote app failed: $listOut2"
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
