# ACT-Omega Net v49.0.0 (CHAIN 100 Century Milestone)
# Master E2E Test Suite Runner
# File: C:\sovereign_manifold_v31\tests\e2e\Run-All-E2E-Tests.ps1
# STRICT CONSTRAINT: ZERO PYTHON | MUSE ZERO-UNMEASURED DATA MANDATE

param(
    [ValidateSet("1", "2", "3", "4", "All")]
    [string]$Tier = "All",

    [int]$Feature = 0,

    [ValidateSet("M1", "M2", "M3", "M4", "M5", "All")]
    [string]$Milestone = "All",

    [ValidateSet("Console", "JSON", "Markdown", "All")]
    [string]$ReportFormat = "Console",

    [string]$OutputPath = ""
)

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "       ACT-OMEGA NET v49.0.0: OPAQUE-BOX E2E TEST RUNNER                  " -ForegroundColor Cyan
Write-Host "       (STRICT ZERO-PYTHON MANDATE | ZERO-UNMEASURED AUDIT RIGOR)         " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host ("  Invoked at : {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC")) -ForegroundColor Gray
Write-Host ("  Target Tier: {0} | Milestone: {1} | Specific Feature: {2}" -f $Tier, $Milestone, $(if($Feature -gt 0){$Feature}else{"All"})) -ForegroundColor Gray
Write-Host ""

. "$PSScriptRoot\e2e_common.ps1"
. "$PSScriptRoot\tier1_features.ps1"
. "$PSScriptRoot\tier2_boundaries.ps1"
. "$PSScriptRoot\tier3_integration.ps1"
. "$PSScriptRoot\tier4_scenarios.ps1"

$allResults = @()

if ($Feature -gt 0) {
    # Run specific feature test
    $featureFuncName = ("Test-Feature-{0:D2}" -f $Feature)
    if (Get-Command $featureFuncName -ErrorAction SilentlyContinue) {
        Write-Host "Executing isolated feature test: $featureFuncName" -ForegroundColor Cyan
        $res = & $featureFuncName
        $statusStr = if ($res.Passed) { "PASS" } else { "FAIL" }
        $color = if ($res.Passed) { "Green" } else { "Red" }
        Write-Host ("  [{0}] [{1}] {2} : {3} ({4}ms)" -f $res.Id, $statusStr, $res.Name, $res.Message, [math]::Round($res.ElapsedMs, 1)) -ForegroundColor $color
        $allResults += $res
    } else {
        Write-Host "Error: Feature test $featureFuncName not found (valid features: 1..34)" -ForegroundColor Red
        exit 1
    }
} else {
    # Run requested tiers
    if ($Tier -eq "1" -or $Tier -eq "All") {
        $allResults += Invoke-Tier1-Tests -MilestoneFilter $Milestone
    }
    if ($Tier -eq "2" -or $Tier -eq "All") {
        $allResults += Invoke-Tier2-Tests
    }
    if ($Tier -eq "3" -or $Tier -eq "All") {
        $allResults += Invoke-Tier3-Tests
    }
    if ($Tier -eq "4" -or $Tier -eq "All") {
        $allResults += Invoke-Tier4-Tests
    }
}

$summary = Format-TestSummary -Results $allResults

# Output reports
if ($ReportFormat -eq "JSON" -or $ReportFormat -eq "All" -or ($OutputPath -and $OutputPath.EndsWith(".json"))) {
    $reportDir = "$PSScriptRoot\reports"
    if (-not (Test-Path $reportDir)) {
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    }
    $targetPath = if ($OutputPath) { $OutputPath } else { "$reportDir\e2e_results_$(Get-Date -Format 'yyyyMMdd_HHmmss').json" }
    Export-TestResultsJson -Results $allResults -OutputPath $targetPath
}

if ($summary.Failed -gt 0) {
    Write-Host ("  [E2E SUITE RESULT: {0} TEST(S) FAILED]" -f $summary.Failed) -ForegroundColor Red
    exit 1
} else {
    Write-Host "  [E2E SUITE RESULT: ALL TESTS PASSED CLEANLY (100%)]" -ForegroundColor Green
    exit 0
}
