$scripts = @(
    @{ Name = 'Crypto Utilities'; Path = 'usage.js' },
    @{ Name = 'Standard Library (Math, String, FS, JSON, Date, Color)'; Path = 'test-all.js' },
    @{ Name = 'Network Package'; Path = 'test-net.js' },
    @{ Name = 'Server Package'; Path = 'test-server.js' },
    @{ Name = 'Package Manager (NYPM)'; Path = 'test-nypm.js' }
)

Write-Host '========================================'
Write-Host '   RUNNING FULL NYX LANGUAGE TEST SUITE   '
Write-Host '========================================'
Write-Host ''

$failures = 0

foreach ($script in $scripts) {
    Write-Host ("[TEST] Running {0}..." -f $script.Name)
    $scriptPath = Join-Path $PSScriptRoot $script.Path
    
    if (-not (Test-Path -LiteralPath $scriptPath)) {
        Write-Error ("File not found: {0}" -f $scriptPath)
        $failures++
        continue
    }

    try {
        & node $scriptPath
        if ($LASTEXITCODE -ne 0) {
            Write-Host ("[FAIL] {0}`n" -f $script.Name) -ForegroundColor Red
            $failures++
        } else {
            Write-Host ("[PASS] {0}`n" -f $script.Name)
        }
    } catch {
        Write-Host ("[FAIL] {0}`n" -f $script.Name) -ForegroundColor Red
        $failures++
    }
}

if ($failures -eq 0) {
    Write-Host '========================================'
    Write-Host '   ALL TESTS PASSED SUCCESSFULLY   '
    Write-Host '========================================'
    exit 0
} else {
    Write-Host '========================================' -ForegroundColor Red
    Write-Host ("   {0} TEST(S) FAILED   " -f $failures) -ForegroundColor Red
    Write-Host '========================================' -ForegroundColor Red
    exit 1
}