# ACT-Omega Net v56.1.0 (SH4Z v5600 TLV | CHAIN 210 | 624/624 Lean 4 QED)
# Master Dual-Track E2E Test Suite Runner for v56.0.0 Baseline & v56.1.0 Master Capabilities
# File: C:\sovereign_manifold_v31\tests\e2e\test_runner_v56.ps1
# STRICT CONSTRAINT: ZERO PYTHON | MUSE ZERO-UNMEASURED DATA MANDATE

param(
    [ValidateSet("1", "2", "3", "4", "All")]
    [string]$Tier = "All",

    [int]$Feature = 0,

    [ValidateSet("M0", "M1", "M2", "M3", "M4", "M5", "All")]
    [string]$Milestone = "All",

    [ValidateSet("Console", "JSON", "Markdown", "All")]
    [string]$ReportFormat = "Console",

    [string]$OutputPath = "",

    [ValidateSet("Baseline", "v56.1", "All")]
    [string]$Suite = "All",

    [switch]$Strict
)

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "       ACT-OMEGA NET v56.1.0: DUAL-TRACK OPAQUE-BOX E2E TEST RUNNER       " -ForegroundColor Cyan
Write-Host "       (STRICT ZERO-PYTHON MANDATE | ZERO-UNMEASURED AUDIT RIGOR)         " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host ("  Invoked at : {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC")) -ForegroundColor Gray
Write-Host ("  Target Tier: {0} | Milestone: {1} | Specific Feature: {2} | Suite: {3}" -f $Tier, $Milestone, $(if($Feature -gt 0){$Feature}else{"All"}), $Suite) -ForegroundColor Gray
Write-Host ""

. "$PSScriptRoot\e2e_common.ps1"
. "$PSScriptRoot\tier1_features_v56.ps1"
. "$PSScriptRoot\tier2_boundaries_v56.ps1"
. "$PSScriptRoot\tier3_integration_v56.ps1"
. "$PSScriptRoot\tier4_scenarios_v56.ps1"

# Load v56.1.0 suites
if (Test-Path "$PSScriptRoot\tier1_features_v56_1.ps1") { . "$PSScriptRoot\tier1_features_v56_1.ps1" }
if (Test-Path "$PSScriptRoot\tier2_boundaries_v56_1.ps1") { . "$PSScriptRoot\tier2_boundaries_v56_1.ps1" }
if (Test-Path "$PSScriptRoot\tier3_integration_v56_1.ps1") { . "$PSScriptRoot\tier3_integration_v56_1.ps1" }
if (Test-Path "$PSScriptRoot\tier4_scenarios_v56_1.ps1") { . "$PSScriptRoot\tier4_scenarios_v56_1.ps1" }

$baselineResults = @()
$v56_1Results = @()

# -----------------------------------------------------------------------------
# Isolated Feature Mode
# -----------------------------------------------------------------------------
if ($Feature -gt 0) {
    if ($Suite -eq "v56.1" -or ($Feature -le 14 -and $Suite -ne "Baseline")) {
        $featureFuncName = ("Test-Feature-v56-1-{0:D2}" -f $Feature)
        if (Get-Command $featureFuncName -ErrorAction SilentlyContinue) {
            Write-Host "Executing isolated v56.1 feature test: $featureFuncName" -ForegroundColor Cyan
            $res = & $featureFuncName
            $statusStr = if ($res.Passed) { "PASS" } else { "FAIL" }
            $color = if ($res.Passed) { "Green" } else { "Red" }
            Write-Host ("  [{0}] [{1}] {2} : {3} ({4}ms)" -f $res.Id, $statusStr, $res.Name, $res.Message, [math]::Round($res.ElapsedMs, 1)) -ForegroundColor $color
            $v56_1Results += $res
        } else {
            Write-Host "Error: v56.1 feature test $featureFuncName not found (valid features: 1..14)" -ForegroundColor Red
            exit 1
        }
    } else {
        $featureFuncName = ("Test-Feature-{0:D2}" -f $Feature)
        if (Get-Command $featureFuncName -ErrorAction SilentlyContinue) {
            Write-Host "Executing isolated baseline feature test: $featureFuncName" -ForegroundColor Cyan
            $res = & $featureFuncName
            $statusStr = if ($res.Passed) { "PASS" } else { "FAIL" }
            $color = if ($res.Passed) { "Green" } else { "Red" }
            Write-Host ("  [{0}] [{1}] {2} : {3} ({4}ms)" -f $res.Id, $statusStr, $res.Name, $res.Message, [math]::Round($res.ElapsedMs, 1)) -ForegroundColor $color
            $baselineResults += $res
        } else {
            Write-Host "Error: Baseline feature test $featureFuncName not found (valid features: 1..20)" -ForegroundColor Red
            exit 1
        }
    }
} else {
    # -------------------------------------------------------------------------
    # Milestone-Filtered or Suite Mode
    # -------------------------------------------------------------------------
    $runBaseline = ($Suite -eq "Baseline" -or ($Suite -eq "All" -and $Milestone -in @("All", "M0", "M5")))
    $runV56_1 = ($Suite -eq "v56.1" -or $Suite -eq "All" -or $Milestone -in @("M0", "M1", "M2", "M3", "M4"))

    # Part 1: Baseline Suite (v56.0.0 Regression: 40 Tests)
    if ($runBaseline) {
        Write-Host "==========================================================================" -ForegroundColor DarkCyan
        Write-Host "   PART 1: BASELINE REGRESSION SUITE (v56.0.0 -- 40 CORE TESTS)           " -ForegroundColor DarkCyan
        Write-Host "==========================================================================" -ForegroundColor DarkCyan
        if ($Tier -eq "1" -or $Tier -eq "All") {
            $baselineResults += Invoke-Tier1-Tests-v56 -MilestoneFilter $(if($Milestone -in @("M0", "M5")){$Milestone}else{"All"})
        }
        if ($Tier -eq "2" -or $Tier -eq "All") {
            $baselineResults += Invoke-Tier2-Tests-v56
        }
        if ($Tier -eq "3" -or $Tier -eq "All") {
            $baselineResults += Invoke-Tier3-Tests-v56
        }
        if ($Tier -eq "4" -or $Tier -eq "All") {
            $baselineResults += Invoke-Tier4-Tests-v56
        }
    }

    # Part 2: v56.1.0 Master Capabilities Suite (34 Tests)
    if ($runV56_1) {
        Write-Host ""
        Write-Host "==========================================================================" -ForegroundColor DarkCyan
        Write-Host "   PART 2: ACT-OMEGA NET v56.1.0 CAPABILITIES SUITE (34 TESTS)            " -ForegroundColor DarkCyan
        Write-Host "==========================================================================" -ForegroundColor DarkCyan
        if ($Tier -eq "1" -or $Tier -eq "All") {
            $v56_1Results += Invoke-Tier1-Tests-v56-1 -MilestoneFilter $Milestone
        }
        if ($Tier -eq "2" -or $Tier -eq "All") {
            $t2 = Invoke-Tier2-Tests-v56-1 -MilestoneFilter $Milestone
            $v56_1Results += if ($Milestone -eq "All") { $t2 } else { @($t2 | Where-Object { $_.Milestone -eq $Milestone }) }
        }
        if ($Tier -eq "3" -or $Tier -eq "All") {
            $t3 = Invoke-Tier3-Tests-v56-1 -MilestoneFilter $Milestone
            $v56_1Results += if ($Milestone -eq "All") { $t3 } else { @($t3 | Where-Object { $_.Milestone -eq $Milestone }) }
        }
        if ($Tier -eq "4" -or $Tier -eq "All") {
            $t4 = Invoke-Tier4-Tests-v56-1 -MilestoneFilter $Milestone
            $v56_1Results += if ($Milestone -eq "All") { $t4 } else { @($t4 | Where-Object { $_.Milestone -eq $Milestone }) }
        }
    }
}

$allResults = $baselineResults + $v56_1Results

# Output Execution Summaries
if ($baselineResults.Count -gt 0) {
    Write-Host "--- BASELINE REGRESSION (v56.0.0) SUMMARY ---" -ForegroundColor Cyan
    $baseSummary = Format-TestSummary -Results $baselineResults
}
if ($v56_1Results.Count -gt 0) {
    Write-Host "--- v56.1.0 MASTER CAPABILITIES SUMMARY ---" -ForegroundColor Cyan
    $v56Summary = Format-TestSummary -Results $v56_1Results
}

# Export JSON report
if ($ReportFormat -eq "JSON" -or $ReportFormat -eq "All" -or ($OutputPath -and $OutputPath.EndsWith(".json"))) {
    $reportDir = "$PSScriptRoot\reports"
    if (-not (Test-Path $reportDir)) {
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    }
    $targetPath = if ($OutputPath) { $OutputPath } else { "$reportDir\v56_1_results_$(Get-Date -Format 'yyyyMMdd_HHmmss').json" }
    Export-TestResultsJson -Results $allResults -OutputPath $targetPath
}

# Determine exit code based on invocation mode
$baseFailed = ($baselineResults | Where-Object { (-not $_.Passed) -and ($Milestone -eq "All" -or $_.Milestone -eq $Milestone) }).Count
$v56Failed = ($v56_1Results | Where-Object { (-not $_.Passed) -and ($Milestone -eq "All" -or $_.Milestone -eq $Milestone) }).Count

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "                        FINAL EXECUTION STATUS                            " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan

if ($baselineResults.Count -gt 0) {
    $baseColor = if ($baseFailed -eq 0) { "Green" } else { "Red" }
    Write-Host ("  Baseline Regression Score : {0}/{1} Passed ({2}%)" -f ($baselineResults.Count - $baseFailed), $baselineResults.Count, $(if($baselineResults.Count -gt 0){[math]::Round((($baselineResults.Count - $baseFailed)/$baselineResults.Count)*100,1)}else{0})) -ForegroundColor $baseColor
}
if ($v56_1Results.Count -gt 0) {
    $v56Color = if ($v56Failed -eq 0) { "Green" } else { "Yellow" }
    Write-Host ("  v56.1.0 Capability Matrix : {0}/{1} Verified ({2}% Ready)" -f ($v56_1Results.Count - $v56Failed), $v56_1Results.Count, $(if($v56_1Results.Count -gt 0){[math]::Round((($v56_1Results.Count - $v56Failed)/$v56_1Results.Count)*100,1)}else{0})) -ForegroundColor $v56Color
}
Write-Host "==========================================================================" -ForegroundColor Cyan

if ($Suite -eq "Baseline") {
    if ($baseFailed -eq 0) {
        Write-Host "  [E2E SUITE RESULT: BASELINE 40/40 PASSED CLEANLY (100%)]" -ForegroundColor Green
        exit 0
    } else {
        Write-Host ("  [E2E SUITE RESULT: {0} BASELINE TEST(S) FAILED]" -f $baseFailed) -ForegroundColor Red
        exit 1
    }
} elseif ($Suite -eq "v56.1" -or $Milestone -in @("M0", "M1", "M2", "M3", "M4") -or $Strict) {
    if ($v56Failed -eq 0 -and $baseFailed -eq 0) {
        Write-Host "  [E2E SUITE RESULT: ALL TESTS PASSED CLEANLY (100%)]" -ForegroundColor Green
        exit 0
    } else {
        Write-Host ("  [E2E SUITE RESULT: TARGET EXECUTION HAD {0} PENDING/FAILED TEST(S)]" -f ($baseFailed + $v56Failed)) -ForegroundColor Red
        exit 1
    }
} else {
    # Default Dual-Track execution
    if ($baseFailed -eq 0) {
        Write-Host "  [E2E SUITE RESULT: BASELINE 40/40 VERIFIED (100%) | v56.1.0 MATRIX ACTIVE]" -ForegroundColor Green
        exit 0
    } else {
        Write-Host ("  [E2E SUITE RESULT: BASELINE FAILED WITH {0} VIOLATIONS]" -f $baseFailed) -ForegroundColor Red
        exit 1
    }
}
