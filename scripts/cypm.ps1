param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$CliArgs
)

$ErrorActionPreference = 'Stop'

if ($null -eq $CliArgs) { $CliArgs = @() }

$manifest = 'ny.pkg'
$lockfile = 'ny.lock'
$registryConfig = 'nypm.config'

function Show-Usage {
@"
Usage: nypm <command> [args]
Commands:
  init [project]
  add <name> <path> [version] [deps_csv]
  add-remote <name> [constraint]
  dep <name> <deps_csv>
  version <name> <version>
  remove <name>
  list
  path <name>
  search [pattern]
  publish <name> <version> <path> [deps_csv]
  registry [get|set <path_or_url>]
  resolve [roots_csv]
  lock [roots_csv]
  verify-lock
  install [roots_csv] [target_dir]
  doctor

Version examples:
  1.2.3
Dependency examples:
  core@^1.0.0,util@>=2.1.0,fmt@1.4.2
Note:
  in POSIX shells, quote constraints containing > or <
"@
}

function Ensure-Manifest {
    if (-not (Test-Path $manifest)) {
        throw "Manifest '$manifest' not found. Run: nypm init"
    }
}

function Normalize-Csv([string]$value) {
    if ($null -eq $value) { return '' }
    return (($value -replace '\s+', '').Trim())
}

function Is-Semver([string]$value) {
    if ($null -eq $value) { return $false }
    return $value -match '^[0-9]+\.[0-9]+\.[0-9]+$'
}

function Parse-Semver([string]$version) {
    if (-not (Is-Semver $version)) {
        throw "Invalid semver '$version'"
    }
    $parts = $version.Split('.')
    return @([int]$parts[0], [int]$parts[1], [int]$parts[2])
}

function Compare-Semver([string]$a, [string]$b) {
    $A = Parse-Semver $a
    $B = Parse-Semver $b
    for ($i = 0; $i -lt 3; $i++) {
        if ($A[$i] -lt $B[$i]) { return -1 }
        if ($A[$i] -gt $B[$i]) { return 1 }
    }
    return 0
}

function Next-Major([string]$v) {
    $S = Parse-Semver $v
    return "{0}.0.0" -f ($S[0] + 1)
}

function Next-Minor([string]$v) {
    $S = Parse-Semver $v
    return "{0}.{1}.0" -f $S[0], ($S[1] + 1)
}

function Constraint-Ok([string]$version, [string]$constraint) {
    $c = $constraint.Trim()
    if ($c -eq '') { return $true }

    if ($c.StartsWith('>=')) {
        $base = $c.Substring(2)
        if (-not (Is-Semver $base)) { return $false }
        return (Compare-Semver $version $base) -ge 0
    }
    if ($c.StartsWith('<=')) {
        $base = $c.Substring(2)
        if (-not (Is-Semver $base)) { return $false }
        return (Compare-Semver $version $base) -le 0
    }
    if ($c.StartsWith('>')) {
        $base = $c.Substring(1)
        if (-not (Is-Semver $base)) { return $false }
        return (Compare-Semver $version $base) -gt 0
    }
    if ($c.StartsWith('<')) {
        $base = $c.Substring(1)
        if (-not (Is-Semver $base)) { return $false }
        return (Compare-Semver $version $base) -lt 0
    }
    if ($c.StartsWith('=')) {
        $base = $c.Substring(1)
        if (-not (Is-Semver $base)) { return $false }
        return (Compare-Semver $version $base) -eq 0
    }
    if ($c.StartsWith('^')) {
        $base = $c.Substring(1)
        if (-not (Is-Semver $base)) { return $false }
        $S = Parse-Semver $base
        $lo = $base
        if ($S[0] -gt 0) {
            $hi = Next-Major $base
        } elseif ($S[1] -gt 0) {
            $hi = "0.{0}.0" -f ($S[1] + 1)
        } else {
            $hi = "0.0.{0}" -f ($S[2] + 1)
        }
        return (Compare-Semver $version $lo) -ge 0 -and (Compare-Semver $version $hi) -lt 0
    }
    if ($c.StartsWith('~')) {
        $base = $c.Substring(1)
        if (-not (Is-Semver $base)) { return $false }
        $lo = $base
        $hi = Next-Minor $base
        return (Compare-Semver $version $lo) -ge 0 -and (Compare-Semver $version $hi) -lt 0
    }

    if (-not (Is-Semver $c)) { return $false }
    return (Compare-Semver $version $c) -eq 0
}

function Get-RegistrySource {
    if (Test-Path -LiteralPath $registryConfig) {
        foreach ($lineRaw in Get-Content -LiteralPath $registryConfig) {
            $line = $lineRaw.Trim()
            if ($line -match '^registry=(.*)$') {
                $src = $Matches[1].Trim()
                if ($src -ne '') { return $src }
            }
        }
    }
    return 'ny.registry'
}

function Set-RegistrySource([string]$src) {
    @(
        '# nypm configuration'
        "registry=$src"
    ) | Set-Content -LiteralPath $registryConfig
}

function Is-Url([string]$v) {
    if ($null -eq $v) { return $false }
    return $v -match '^(https?)://'
}

function Read-RegistryEntries([string]$src) {
    $lines = @()
    if (Is-Url $src) {
        try {
            $resp = Invoke-WebRequest -Uri $src -UseBasicParsing
            $lines = $resp.Content -split "`r?`n"
        } catch {
            throw "Failed to fetch registry '$src': $($_.Exception.Message)"
        }
    } else {
        if (-not (Test-Path -LiteralPath $src)) {
            throw "Registry source not found: $src"
        }
        $lines = Get-Content -LiteralPath $src
    }

    $out = New-Object System.Collections.Generic.List[hashtable]
    foreach ($lineRaw in $lines) {
        $line = $lineRaw.Trim()
        if ($line -eq '' -or $line.StartsWith('#')) { continue }

        $parts = $line -split '\|', 4
        if ($parts.Count -lt 3) { continue }

        $name = $parts[0].Trim()
        $version = $parts[1].Trim()
        $entrySource = $parts[2].Trim()
        $deps = ''
        if ($parts.Count -ge 4) {
            $deps = Normalize-Csv $parts[3]
        }

        if ($name -eq '' -or $version -eq '' -or $entrySource -eq '') { continue }
        if (-not (Is-Semver $version)) { continue }

        [void]$out.Add(@{
            Name = $name
            Version = $version
            Source = $entrySource
            Deps = $deps
        })
    }
    return $out
}

function Resolve-RegistryEntrySource([string]$registrySource, [string]$entrySource) {
    if (Is-Url $entrySource) { return $entrySource }
    if ([System.IO.Path]::IsPathRooted($entrySource)) { return $entrySource }

    if (Is-Url $registrySource) {
        $base = [Uri]::new($registrySource)
        $resolved = [Uri]::new($base, $entrySource)
        return $resolved.ToString()
    }

    $registryDir = Split-Path -Parent $registrySource
    if ([string]::IsNullOrWhiteSpace($registryDir)) {
        $registryDir = (Get-Location).Path
    }
    return [System.IO.Path]::GetFullPath((Join-Path $registryDir $entrySource))
}

function Read-Manifest {
    Ensure-Manifest

    $data = @{
        Project = 'ny-project'
        Packages = @{}
        Versions = @{}
        Deps = @{}
    }

    foreach ($lineRaw in Get-Content $manifest) {
        $line = $lineRaw.Trim()
        if ($line -eq '' -or $line.StartsWith('#')) { continue }

        if ($line -match '^project=(.*)$') {
            $data.Project = $Matches[1]
            continue
        }

        if ($line -match '^pkg\.([^=]+)=(.*)$') {
            $name = $Matches[1]
            $path = $Matches[2]
            $data.Packages[$name] = $path
            continue
        }

        if ($line -match '^ver\.([^=]+)=(.*)$') {
            $name = $Matches[1]
            $version = $Matches[2]
            $data.Versions[$name] = $version
            continue
        }

        if ($line -match '^deps\.([^=]+)=(.*)$') {
            $name = $Matches[1]
            $deps = Normalize-Csv $Matches[2]
            $data.Deps[$name] = $deps
            continue
        }

        # Legacy format: name=path
        if ($line -match '^([A-Za-z_][A-Za-z0-9_]*)=(.*)$') {
            $name = $Matches[1]
            $value = $Matches[2]
            if ($name -ne 'project') {
                $data.Packages[$name] = $value
            }
            continue
        }
    }

    foreach ($name in $data.Packages.Keys) {
        if (-not $data.Versions.ContainsKey($name) -or [string]::IsNullOrWhiteSpace($data.Versions[$name])) {
            $data.Versions[$name] = '0.0.0'
        }
        if (-not $data.Deps.ContainsKey($name)) {
            $data.Deps[$name] = ''
        }
    }

    return $data
}

function Write-Manifest($data) {
    $lines = @()
    $lines += '# ny package manifest'
    $lines += ("project={0}" -f $data.Project)

    foreach ($name in ($data.Packages.Keys | Sort-Object)) {
        $path = $data.Packages[$name]
        $version = $data.Versions[$name]
        $deps = Normalize-Csv $data.Deps[$name]
        $lines += ("pkg.{0}={1}" -f $name, $path)
        $lines += ("ver.{0}={1}" -f $name, $version)
        $lines += ("deps.{0}={1}" -f $name, $deps)
    }

    $lines | Set-Content $manifest
}

function Resolve-Order($data, [string]$rootsCsv) {
    foreach ($name in $data.Packages.Keys) {
        if (-not (Is-Semver $data.Versions[$name])) {
            throw "Package '$name' has invalid version '$($data.Versions[$name])'"
        }
    }

    $state = @{}
    $order = New-Object System.Collections.Generic.List[string]

    function Visit([string]$name) {
        $name = $name.Trim()
        if ($name -eq '') { return }

        if (-not $data.Packages.ContainsKey($name)) {
            throw "Package '$name' not found"
        }

        if ($state.ContainsKey($name)) {
            if ($state[$name] -eq 1) {
                throw "Dependency cycle detected at '$name'"
            }
            if ($state[$name] -eq 2) {
                return
            }
        }

        $state[$name] = 1

        $depsCsv = Normalize-Csv $data.Deps[$name]
        if ($depsCsv -ne '') {
            foreach ($spec in ($depsCsv -split ',')) {
                $token = $spec.Trim()
                if ($token -eq '') { continue }

                $depName = $token
                $constraint = ''
                $atIndex = $token.IndexOf('@')
                if ($atIndex -ge 0) {
                    $depName = $token.Substring(0, $atIndex).Trim()
                    $constraint = $token.Substring($atIndex + 1).Trim()
                }

                if (-not $data.Packages.ContainsKey($depName)) {
                    throw "Package '$name' depends on missing package '$depName'"
                }

                $depVersion = $data.Versions[$depName]
                if ($constraint -ne '' -and -not (Constraint-Ok $depVersion $constraint)) {
                    throw "Version conflict: $name requires $depName@$constraint but $depName is $depVersion"
                }

                Visit $depName
            }
        }

        $state[$name] = 2
        if (-not $order.Contains($name)) {
            [void]$order.Add($name)
        }
    }

    $rootsCsv = Normalize-Csv $rootsCsv
    if ($rootsCsv -eq '') {
        foreach ($name in ($data.Packages.Keys | Sort-Object)) {
            Visit $name
        }
    } else {
        foreach ($name in ($rootsCsv -split ',')) {
            if ($name.Trim() -eq '') { continue }
            Visit $name
        }
    }

    return $order
}

function Verify-LockfileData($data) {
    if (-not (Test-Path -LiteralPath $lockfile)) {
        throw "Lockfile '$lockfile' not found. Run: nypm lock"
    }

    foreach ($lineRaw in Get-Content -LiteralPath $lockfile) {
        $line = $lineRaw.Trim()
        if ($line -eq '' -or $line.StartsWith('#') -or $line.StartsWith('roots=')) { continue }

        if ($line -match '^pkg\.([^=]+)=(.*)$') {
            $name = $Matches[1]
            $lockedPath = $Matches[2]
            if (-not $data.Packages.ContainsKey($name)) {
                throw "Lock references missing package '$name'"
            }
            $manifestPath = $data.Packages[$name]
            if ($manifestPath -ne $lockedPath) {
                throw "Lock path mismatch for '$name': lock=$lockedPath manifest=$manifestPath"
            }
            if (-not (Test-Path -LiteralPath $lockedPath)) {
                throw "Locked path does not exist for '$name': $lockedPath"
            }
            continue
        }

        if ($line -match '^ver\.([^=]+)=(.*)$') {
            $name = $Matches[1]
            $lockedVer = $Matches[2]
            if (-not $data.Versions.ContainsKey($name)) {
                throw "Lock references missing package version '$name'"
            }
            $manifestVer = $data.Versions[$name]
            if ($manifestVer -ne $lockedVer) {
                throw "Lock version mismatch for '$name': lock=$lockedVer manifest=$manifestVer"
            }
            continue
        }
    }
}

$cmd = if ($CliArgs.Count -gt 0) { $CliArgs[0] } else { '' }

switch ($cmd) {
    'init' {
        $project = if ($CliArgs.Count -gt 1) { $CliArgs[1] } else { 'ny-project' }
        if (Test-Path $manifest) {
            Write-Host "$manifest already exists"
            exit 0
        }

        @(
            '# ny package manifest'
            "project=$project"
        ) | Set-Content $manifest

        Write-Host "Created $manifest"
    }

    'add' {
        Ensure-Manifest
        if ($CliArgs.Count -lt 3) { Show-Usage; exit 1 }

        $name = $CliArgs[1]
        $path = $CliArgs[2]
        $arg3 = if ($CliArgs.Count -gt 3) { $CliArgs[3] } else { '' }
        $arg4 = if ($CliArgs.Count -gt 4) { $CliArgs[4] } else { '' }

        $version = '0.0.0'
        $deps = ''
        if ($arg3 -ne '') {
            if (Is-Semver $arg3) {
                $version = $arg3
                $deps = $arg4
            } else {
                $deps = $arg3
                if ($arg4 -ne '') {
                    if (Is-Semver $arg4) {
                        $version = $arg4
                    } else {
                        throw 'Fourth argument must be semver when third argument is deps'
                    }
                }
            }
        }

        $deps = Normalize-Csv $deps

        $data = Read-Manifest
        $data.Packages[$name] = $path
        $data.Versions[$name] = $version
        $data.Deps[$name] = $deps
        Write-Manifest $data

        Write-Host "Added $name -> $path (version $version)"
    }

    'add-remote' {
        Ensure-Manifest
        if ($CliArgs.Count -lt 2) { Show-Usage; exit 1 }

        $name = $CliArgs[1]
        $constraint = if ($CliArgs.Count -gt 2) { $CliArgs[2] } else { '' }
        $registrySource = Get-RegistrySource
        $entries = Read-RegistryEntries $registrySource

        $best = $null
        foreach ($entry in $entries) {
            if ($entry.Name -ne $name) { continue }
            if (-not (Constraint-Ok $entry.Version $constraint)) { continue }
            if ($null -eq $best -or (Compare-Semver $entry.Version $best.Version) -gt 0) {
                $best = $entry
            }
        }

        if ($null -eq $best) {
            if ([string]::IsNullOrWhiteSpace($constraint)) {
                throw "No registry match for $name"
            }
            throw "No registry match for $name@$constraint"
        }

        $resolvedSource = Resolve-RegistryEntrySource $registrySource $best.Source
        $args = @('add', $name, $resolvedSource, $best.Version)
        if (-not [string]::IsNullOrWhiteSpace($best.Deps)) {
            $args += $best.Deps
        }
        & $PSCommandPath @args
        if (-not $?) {
            throw "Failed to add remote package '$name'"
        }
    }

    'dep' {
        Ensure-Manifest
        if ($CliArgs.Count -lt 3) { Show-Usage; exit 1 }

        $name = $CliArgs[1]
        $deps = Normalize-Csv $CliArgs[2]

        $data = Read-Manifest
        if (-not $data.Packages.ContainsKey($name)) {
            throw "Package '$name' not found"
        }

        $data.Deps[$name] = $deps
        Write-Manifest $data
        Write-Host "Updated dependencies for $name"
    }

    'version' {
        Ensure-Manifest
        if ($CliArgs.Count -lt 3) { Show-Usage; exit 1 }

        $name = $CliArgs[1]
        $version = $CliArgs[2]
        if (-not (Is-Semver $version)) {
            throw 'Version must match MAJOR.MINOR.PATCH'
        }

        $data = Read-Manifest
        if (-not $data.Packages.ContainsKey($name)) {
            throw "Package '$name' not found"
        }

        $data.Versions[$name] = $version
        Write-Manifest $data
        Write-Host "Updated version for $name to $version"
    }

    'remove' {
        Ensure-Manifest
        if ($CliArgs.Count -lt 2) { Show-Usage; exit 1 }

        $name = $CliArgs[1]
        $data = Read-Manifest

        [void]$data.Packages.Remove($name)
        [void]$data.Versions.Remove($name)
        [void]$data.Deps.Remove($name)
        Write-Manifest $data

        Write-Host "Removed $name"
    }

    'list' {
        Ensure-Manifest
        $data = Read-Manifest

        foreach ($name in ($data.Packages.Keys | Sort-Object)) {
            $path = $data.Packages[$name]
            $version = $data.Versions[$name]
            $deps = Normalize-Csv $data.Deps[$name]

            if ($deps -ne '') {
                Write-Output ("{0}={1} version={2} deps={3}" -f $name, $path, $version, $deps)
            } else {
                Write-Output ("{0}={1} version={2}" -f $name, $path, $version)
            }
        }
    }

    'path' {
        Ensure-Manifest
        if ($CliArgs.Count -lt 2) { Show-Usage; exit 1 }

        $name = $CliArgs[1]
        $data = Read-Manifest
        if (-not $data.Packages.ContainsKey($name)) {
            throw "Package '$name' not found"
        }

        Write-Output $data.Packages[$name]
    }

    'registry' {
        $subcmd = if ($CliArgs.Count -gt 1) { $CliArgs[1] } else { 'get' }
        switch ($subcmd) {
            'get' {
                Write-Output (Get-RegistrySource)
            }
            'set' {
                if ($CliArgs.Count -lt 3) {
                    throw 'registry set expects <path_or_url>'
                }
                $src = $CliArgs[2]
                Set-RegistrySource $src
                Write-Host "Registry set to $src"
            }
            default {
                throw "Unknown registry subcommand '$subcmd'"
            }
        }
    }

    'search' {
        $pattern = if ($CliArgs.Count -gt 1) { $CliArgs[1] } else { '' }
        $registrySource = Get-RegistrySource
        $entries = Read-RegistryEntries $registrySource
        foreach ($entry in $entries) {
            if (-not [string]::IsNullOrWhiteSpace($pattern)) {
                $hay = "{0} {1} {2}" -f $entry.Name, $entry.Version, $entry.Source
                if ($hay -notmatch [regex]::Escape($pattern)) {
                    continue
                }
            }
            if ([string]::IsNullOrWhiteSpace($entry.Deps)) {
                Write-Output ("{0} version={1} source={2}" -f $entry.Name, $entry.Version, $entry.Source)
            } else {
                Write-Output ("{0} version={1} source={2} deps={3}" -f $entry.Name, $entry.Version, $entry.Source, $entry.Deps)
            }
        }
    }

    'publish' {
        if ($CliArgs.Count -lt 4) { Show-Usage; exit 1 }

        $name = $CliArgs[1]
        $version = $CliArgs[2]
        $srcPath = $CliArgs[3]
        $deps = if ($CliArgs.Count -gt 4) { Normalize-Csv $CliArgs[4] } else { '' }

        if (-not (Is-Semver $version)) {
            throw 'Version must match MAJOR.MINOR.PATCH'
        }
        if (-not (Test-Path -LiteralPath $srcPath)) {
            throw "Publish path not found: $srcPath"
        }

        $registrySource = Get-RegistrySource
        if (Is-Url $registrySource) {
            throw 'publish supports only file registry sources'
        }

        $registryDir = Split-Path -Parent $registrySource
        if (-not [string]::IsNullOrWhiteSpace($registryDir)) {
            New-Item -ItemType Directory -Force -Path $registryDir | Out-Null
        }
        if (-not (Test-Path -LiteralPath $registrySource)) {
            Set-Content -LiteralPath $registrySource -Value ''
        }

        $lines = New-Object System.Collections.Generic.List[string]
        foreach ($lineRaw in Get-Content -LiteralPath $registrySource) {
            $line = $lineRaw.TrimEnd("`r", "`n")
            if ($line -eq '' -or $line.StartsWith('#')) {
                [void]$lines.Add($line)
                continue
            }
            $parts = $line -split '\|', 4
            if ($parts.Count -ge 2 -and $parts[0].Trim() -eq $name -and $parts[1].Trim() -eq $version) {
                continue
            }
            [void]$lines.Add($line)
        }

        [void]$lines.Add(("{0}|{1}|{2}|{3}" -f $name, $version, $srcPath, $deps))
        $lines | Set-Content -LiteralPath $registrySource
        Write-Host "Published $name $version to $registrySource"
    }

    'resolve' {
        Ensure-Manifest
        $roots = if ($CliArgs.Count -gt 1) { $CliArgs[1] } else { '' }
        $data = Read-Manifest
        $order = Resolve-Order $data $roots
        $order
    }

    'lock' {
        Ensure-Manifest
        $roots = if ($CliArgs.Count -gt 1) { Normalize-Csv $CliArgs[1] } else { '' }
        $data = Read-Manifest
        $order = Resolve-Order $data $roots

        $lines = @()
        $lines += '# ny lockfile v1'
        if ($roots -ne '') {
            $lines += ("roots={0}" -f $roots)
        } else {
            $lines += 'roots=*'
        }

        foreach ($name in $order) {
            if (-not $data.Packages.ContainsKey($name)) { continue }
            $path = $data.Packages[$name]
            $version = $data.Versions[$name]
            $lines += ("pkg.{0}={1}" -f $name, $path)
            $lines += ("ver.{0}={1}" -f $name, $version)
        }

        $lines | Set-Content -LiteralPath $lockfile
        Write-Host "Wrote $lockfile"
    }

    'verify-lock' {
        Ensure-Manifest
        $data = Read-Manifest
        Verify-LockfileData -data $data
        Write-Host 'Lockfile verified'
    }

    'install' {
        Ensure-Manifest
        $roots = if ($CliArgs.Count -gt 1) { Normalize-Csv $CliArgs[1] } else { '' }
        $target = if ($CliArgs.Count -gt 2) { $CliArgs[2] } else { '.nydeps' }
        $data = Read-Manifest
        $order = Resolve-Order $data $roots

        New-Item -ItemType Directory -Force -Path $target | Out-Null
        $logPath = Join-Path $target '.install-log'
        Set-Content -LiteralPath $logPath -Value ''

        foreach ($name in $order) {
            if (-not $data.Packages.ContainsKey($name)) {
                throw "Package '$name' not found"
            }
            $src = $data.Packages[$name]
            if (-not (Test-Path -LiteralPath $src)) {
                throw "Package path for '$name' does not exist: $src"
            }

            $dest = Join-Path $target $name
            if (Test-Path -LiteralPath $dest) {
                Remove-Item -Recurse -Force -LiteralPath $dest
            }

            if (Test-Path -LiteralPath $src -PathType Container) {
                Copy-Item -Recurse -Force -LiteralPath $src -Destination $dest
            } else {
                Copy-Item -Force -LiteralPath $src -Destination $dest
            }

            $ver = $data.Versions[$name]
            Add-Content -LiteralPath $logPath -Value ("{0} {1} {2}" -f $name, $ver, $src)
        }

        Write-Host "Installed packages to $target"
    }

    'doctor' {
        Ensure-Manifest
        $data = Read-Manifest
        $errors = New-Object System.Collections.Generic.List[string]

        foreach ($name in ($data.Packages.Keys | Sort-Object)) {
            $path = $data.Packages[$name]
            $version = $data.Versions[$name]
            $deps = Normalize-Csv $data.Deps[$name]

            if ([string]::IsNullOrWhiteSpace($path)) {
                [void]$errors.Add("Package '$name' has no path entry")
            } elseif (-not (Test-Path -LiteralPath $path)) {
                [void]$errors.Add("Package '$name' path does not exist: $path")
            }

            if (-not (Is-Semver $version)) {
                [void]$errors.Add("Package '$name' has invalid version '$version'")
            }

            if ($deps -ne '') {
                foreach ($spec in ($deps -split ',')) {
                    $token = $spec.Trim()
                    if ($token -eq '') { continue }
                    $depName = $token
                    $atIndex = $token.IndexOf('@')
                    if ($atIndex -ge 0) {
                        $depName = $token.Substring(0, $atIndex).Trim()
                    }
                    if (-not $data.Packages.ContainsKey($depName)) {
                        [void]$errors.Add("Package '$name' depends on missing package '$depName'")
                    }
                }
            }
        }

        try {
            [void](Resolve-Order $data '')
        } catch {
            [void]$errors.Add("Dependency resolution failed: $($_.Exception.Message)")
        }

        $lockState = 'missing'
        if (Test-Path -LiteralPath $lockfile) {
            $lockState = 'present'
            try {
                Verify-LockfileData -data $data
                $lockState = 'verified'
            } catch {
                [void]$errors.Add("Lockfile verification failed: $($_.Exception.Message)")
            }
        }

        if ($errors.Count -gt 0) {
            foreach ($msg in $errors) {
                Write-Error $msg
            }
            exit 1
        }

        Write-Host "Doctor OK: lockfile=$lockState"
    }

    default {
        Show-Usage
        exit 1
    }
}
