$ErrorActionPreference = 'Stop'

Write-Host "Running full Nyx test suite..."

# Run the comprehensive language test
.\nyx.exe examples\comprehensive.ny
if ($LASTEXITCODE -ne 0) { throw "Comprehensive test failed" }

# Run standard test scripts if they exist
if (Test-Path ".\scripts\test_v3.ps1") { .\scripts\test_v3.ps1 }
if (Test-Path ".\scripts\test_production.ps1") { .\scripts\test_production.ps1 -VmCases 300 }

Write-Host "Full test suite completed successfully."