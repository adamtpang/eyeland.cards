$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$harnessRoot = Join-Path (Split-Path $projectRoot -Parent) 'helium-harness'
$harnessPython = Join-Path $harnessRoot '.venv/Scripts/python.exe'
Push-Location $harnessRoot
try {
    Get-Content -LiteralPath (Join-Path $PSScriptRoot 'capture-hsreplay.py') -Raw |
        & $harnessPython -m browser_harness.run
    if ($LASTEXITCODE -ne 0) { throw 'Helium capture failed; inspect login/access before retrying.' }
} finally { Pop-Location }
Push-Location $projectRoot
try {
    node hearthstone/scripts/import-live-collection.mjs
    if ($LASTEXITCODE -ne 0) { throw 'Collection validation failed.' }
    node hearthstone/scripts/refresh-collection.mjs --refresh-cards
    if ($LASTEXITCODE -ne 0) { throw 'Card enrichment failed.' }
    node hearthstone/scripts/self-test.mjs
    if ($LASTEXITCODE -ne 0) { throw 'Self-test report failed.' }
    Write-Output 'Open hearthstone/scripts/.cache/self-test.md for the private report.'
} finally { Pop-Location }
