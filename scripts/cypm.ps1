param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$CliArgs
)

$ErrorActionPreference = 'Stop'

if ($null -eq $CliArgs) { $CliArgs = @() }

$manifest = 'cy.pkg'
$lockfile = 'cy.lock'

function Show-Usage {
@"
Usage: cypm <command> [args]
Commands:
  init [project]
  add <name> <path> [version] [deps_csv]
  dep <name> <deps_csv>
  version <name> <version>
  remove <name>
  list
  path <name>
  resolve [roots_csv]
  lock [roots_csv]
  verify-lock

Version examples:
  1.2.3
Dependency examples:
  core@^1.0.0,util@>=2.1.0,fmt@1.4.2
"@
}

function Ensure-Manifest {
    if (-not (Test-Path $manifest)) {
        throw "Manifest '$manifest' not found. Run: cypm init"
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

function Read-Manifest {
    Ensure-Manifest

    $data = @{
        Project = 'cy-project'
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
    $lines += '# cy package manifest'
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

$cmd = if ($CliArgs.Count -gt 0) { $CliArgs[0] } else { '' }

switch ($cmd) {
    'init' {
        $project = if ($CliArgs.Count -gt 1) { $CliArgs[1] } else { 'cy-project' }
        if (Test-Path $manifest) {
            Write-Host "$manifest already exists"
            exit 0
        }

        @(
            '# cy package manifest'
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
        $lines += '# cy lockfile v1'
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
        if (-not (Test-Path -LiteralPath $lockfile)) {
            throw "Lockfile '$lockfile' not found. Run: cypm lock"
        }

        $data = Read-Manifest
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

        Write-Host 'Lockfile verified'
    }

    default {
        Show-Usage
        exit 1
    }
}
