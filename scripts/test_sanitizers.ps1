$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$isWin = $false
if ($null -ne (Get-Variable -Name IsWindows -ErrorAction SilentlyContinue)) {
    $isWin = [bool]$IsWindows
} elseif ($env:OS -eq 'Windows_NT') {
    $isWin = $true
}

if ($isWin) {
    Write-Host '[san-win] skip: sanitizer gate runs on Linux/macOS only'
    exit 0
}

function Resolve-CCompiler {
    $clangCmd = Get-Command clang -ErrorAction SilentlyContinue
    if ($clangCmd) { return $clangCmd.Source }

    $gccCmd = Get-Command gcc -ErrorAction SilentlyContinue
    if ($gccCmd) { return $gccCmd.Source }

    throw 'No clang/gcc compiler found'
}

$cc = Resolve-CCompiler
Write-Host ("[san-win] compiler: {0}" -f $cc)

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("cy_san_" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp | Out-Null

try {
    $probe = Join-Path $tmp 'probe.c'
    'int main(void) { return 0; }' | Set-Content -NoNewline -LiteralPath $probe

    $flags = @('-O1', '-g', '-std=c99', '-Wall', '-Wextra', '-Werror', '-fno-omit-frame-pointer', '-fsanitize=address,undefined')
    $probeOut = Join-Path $tmp 'probe'
    & $cc @flags '-o' $probeOut $probe *> (Join-Path $tmp 'probe.log')
    if ($LASTEXITCODE -ne 0) {
        Write-Host '[san-win] skip: compiler does not support address+undefined sanitizers'
        exit 0
    }

    $runtime = Join-Path $tmp 'cy_san'
    Write-Host '[san-win] building sanitized runtime...'
    & $cc @flags '-o' $runtime 'native/nyx.c'
    if ($LASTEXITCODE -ne 0) {
        throw 'Failed to build sanitized runtime'
    }

    $smoke = Join-Path $tmp 'smoke.ny'
@"
fn add(a, b) {
    return a + b;
}

module M {
    fn id(x) {
        return x;
    }
}

class Box {
    fn init(self, v) {
        object_set(self, "v", v);
    }
    fn get(self) {
        return object_get(self, "v");
    }
}

let b = new(Box, 40);
let xs = [n + 1 for n in [1, 2, 3, 4] if n > 1];
print(add(M.id(b.get()), xs[0]));
"@ | Set-Content -NoNewline -LiteralPath $smoke

    $limits = Join-Path $tmp 'limits.ny'
@"
let i = 0;
while (true) {
    i = i + 1;
}
"@ | Set-Content -NoNewline -LiteralPath $limits

    $env:ASAN_OPTIONS = if ($env:ASAN_OPTIONS) { $env:ASAN_OPTIONS } else { 'detect_leaks=1:abort_on_error=1' }
    $env:UBSAN_OPTIONS = if ($env:UBSAN_OPTIONS) { $env:UBSAN_OPTIONS } else { 'print_stacktrace=1:halt_on_error=1' }

    $outAstRaw = (& $runtime $smoke 2>&1 | Out-String)
    $outAst = ($outAstRaw -replace "`r`n", "`n" -replace "`r", "`n").TrimEnd("`n")
    if ($LASTEXITCODE -ne 0) {
        throw "Sanitized AST run failed: $outAst"
    }

    $outVmRaw = (& $runtime '--vm-strict' $smoke 2>&1 | Out-String)
    $outVm = ($outVmRaw -replace "`r`n", "`n" -replace "`r", "`n").TrimEnd("`n")
    if ($LASTEXITCODE -ne 0) {
        throw "Sanitized VM run failed: $outVm"
    }

    if ($outAst -ne $outVm) {
        throw "Sanitized AST/VM mismatch: AST='$outAst' VM='$outVm'"
    }

    & $runtime '--max-steps' '120' $limits *> (Join-Path $tmp 'limit.err')
    if ($LASTEXITCODE -eq 0) {
        throw 'Sanitized max-steps limit expected failure'
    }
    $err = Get-Content -Raw -LiteralPath (Join-Path $tmp 'limit.err')
    if ($err -notmatch 'max step count exceeded') {
        throw 'Sanitized limit error message missing'
    }

    Write-Host '[san-win] PASS'
}
finally {
    Remove-Item -Recurse -Force $tmp
}
