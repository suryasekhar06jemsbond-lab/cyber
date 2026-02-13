param(
    [int]$Seed = 4242,
    [int]$Cases = 800
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host ("[fuzz-vm-win] seed={0} cases={1}" -f $Seed, $Cases)
$scriptPath = Join-Path $PSScriptRoot 'test_vm_consistency.ps1'
& $scriptPath -Seed $Seed -Cases $Cases
if ($LASTEXITCODE -ne 0) {
    throw "VM fuzz consistency failed"
}
$progCases = [Math]::Max(30, [int]($Cases / 4))
$programScript = Join-Path $PSScriptRoot 'test_vm_program_consistency.ps1'
& $programScript -Seed $Seed -Cases $progCases
if ($LASTEXITCODE -ne 0) {
    throw "VM program consistency failed"
}
Write-Host '[fuzz-vm-win] PASS'
