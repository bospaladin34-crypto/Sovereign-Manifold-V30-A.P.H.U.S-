# tests/test_t414_adversarial_stress.ps1
# Empirical and Adversarial Stress Test Harness for T4.14
param(
    [int]$Iterations = 50,
    [int]$Tier4Runs = 5
)

$ErrorActionPreference = "Stop"

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "    EMPIRICAL ADVERSARIAL STRESS TEST: T4.14 & TIER 4 SUITE      " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 1. Warm-up and load TrackBFormalGateVerifier via dot-sourcing in current session
Write-Host "[1/4] Warming up environment and loading TrackBFormalGateVerifier via dot-sourcing..." -ForegroundColor Yellow
$suiteScript = Join-Path (Split-Path $PSScriptRoot -Parent) "00_control\Invoke-TrackBE2ESuite.ps1"
. $suiteScript -DryRun -Tier 4 | Out-Null
Write-Host "Warm-up complete. Type loaded: $([TrackBFormalGateVerifier] -ne $null)" -ForegroundColor Green

# 2. Compare Single-Trial vs Best-of-3 across iterations
Write-Host "[2/4] Executing $Iterations iterations comparing Single-Trial vs Best-of-3..." -ForegroundColor Yellow

$singlePassCount = 0
$singleFailCount = 0
$singleSpeedups = New-Object System.Collections.Generic.List[double]

$bestOf3PassCount = 0
$bestOf3FailCount = 0
$trial1Count = 0
$trial2Count = 0
$trial3Count = 0
$bestOf3Speedups = New-Object System.Collections.Generic.List[double]

for ($i = 1; $i -le $Iterations; $i++) {
    # Single trial simulation (prior un-remediated behavior)
    $spSingle = 0.0; $dSingle = 0.0; $sSingle = 0.0
    $pSingle = [TrackBFormalGateVerifier]::VerifyGateG10MatVecSpeedup(10000, [ref]$spSingle, [ref]$dSingle, [ref]$sSingle)
    $singleSpeedups.Add($spSingle)
    if ($spSingle -ge 24.04) {
        $singlePassCount++
    } else {
        $singleFailCount++
    }

    # Best-of-3 trials simulation (remediated behavior)
    $spBest = 0.0; $dBest = 0.0; $sBest = 0.0
    $pBest = $false
    $trialsUsed = 0
    for ($trial = 0; $trial -lt 3; $trial++) {
        $sp = 0.0; $d = 0.0; $s = 0.0
        $p = [TrackBFormalGateVerifier]::VerifyGateG10MatVecSpeedup(10000, [ref]$sp, [ref]$d, [ref]$s)
        if ($sp -gt $spBest) {
            $spBest = $sp; $dBest = $d; $sBest = $s; $pBest = $p
        }
        if ($spBest -ge 24.04) {
            $trialsUsed = $trial + 1
            break
        }
    }
    $bestOf3Speedups.Add($spBest)
    if ($spBest -ge 24.04) {
        $bestOf3PassCount++
        if ($trialsUsed -eq 1) { $trial1Count++ }
        elseif ($trialsUsed -eq 2) { $trial2Count++ }
        elseif ($trialsUsed -eq 3) { $trial3Count++ }
    } else {
        $bestOf3FailCount++
    }
}

$singleStats = $singleSpeedups | Measure-Object -Minimum -Maximum -Average
$bestStats = $bestOf3Speedups | Measure-Object -Minimum -Maximum -Average

Write-Host "--- SINGLE TRIAL RESULTS ($Iterations runs) ---" -ForegroundColor White
Write-Host ("  Pass Count (>= 24.04x) : {0}/{1} ({2:F1}%)" -f $singlePassCount, $Iterations, (($singlePassCount / $Iterations) * 100))
Write-Host ("  Fail Count (< 24.04x)  : {0}/{1} ({2:F1}%)" -f $singleFailCount, $Iterations, (($singleFailCount / $Iterations) * 100))
Write-Host ("  Min Speedup            : {0:F2}x" -f $singleStats.Minimum)
Write-Host ("  Max Speedup            : {0:F2}x" -f $singleStats.Maximum)
Write-Host ("  Avg Speedup            : {0:F2}x" -f $singleStats.Average)

Write-Host "--- BEST-OF-3 RESULTS ($Iterations runs) ---" -ForegroundColor White
Write-Host ("  Pass Count (>= 24.04x) : {0}/{1} ({2:F1}%)" -f $bestOf3PassCount, $Iterations, (($bestOf3PassCount / $Iterations) * 100))
Write-Host ("  Fail Count (< 24.04x)  : {0}/{1} ({2:F1}%)" -f $bestOf3FailCount, $Iterations, (($bestOf3FailCount / $Iterations) * 100))
Write-Host ("  Trial 1 Passes         : {0} ({1:F1}%)" -f $trial1Count, (($trial1Count / $Iterations) * 100))
Write-Host ("  Trial 2 Passes         : {0} ({1:F1}%)" -f $trial2Count, (($trial2Count / $Iterations) * 100))
Write-Host ("  Trial 3 Passes         : {0} ({1:F1}%)" -f $trial3Count, (($trial3Count / $Iterations) * 100))
Write-Host ("  Min Speedup            : {0:F2}x" -f $bestStats.Minimum)
Write-Host ("  Max Speedup            : {0:F2}x" -f $bestStats.Maximum)
Write-Host ("  Avg Speedup            : {0:F2}x" -f $bestStats.Average)

# 3. Falsifiability Test
Write-Host "[3/4] Falsifiability Test: Testing with impossible threshold 999.0x..." -ForegroundColor Yellow
$falsifyPassCount = 0
for ($f = 0; $f -lt 10; $f++) {
    $spFalsify = 0.0; $dFalsify = 0.0; $sFalsify = 0.0
    for ($trial = 0; $trial -lt 3; $trial++) {
        $sp = 0.0; $d = 0.0; $s = 0.0
        $p = [TrackBFormalGateVerifier]::VerifyGateG10MatVecSpeedup(10000, [ref]$sp, [ref]$d, [ref]$s)
        if ($sp -gt $spFalsify) {
            $spFalsify = $sp; $dFalsify = $d; $sFalsify = $s
        }
        if ($spFalsify -ge 999.0) { break }
    }
    $falsifyPassed = ($spFalsify -ge 999.0)
    if ($falsifyPassed) { $falsifyPassCount++ }
}
if ($falsifyPassCount -eq 0) {
    Write-Host "  Falsifiability PASSED: 10/10 runs rejected impossible 999.0x threshold." -ForegroundColor Green
} else {
    Write-Host ("  Falsifiability FAILED: {0}/10 runs passed impossible threshold!" -f $falsifyPassCount) -ForegroundColor Red
}

# 4. Consecutive Live Tier 4 Suite Executions
Write-Host "[4/4] Executing $Tier4Runs consecutive live Tier 4 suite runs..." -ForegroundColor Yellow
$consecutiveTier4Pass = 0
for ($r = 1; $r -le $Tier4Runs; $r++) {
    Write-Host ("  Tier 4 Run #{0}/{1} starting..." -f $r, $Tier4Runs)
    $swRun = [System.Diagnostics.Stopwatch]::StartNew()
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = "powershell"
    $pinfo.Arguments = "-NoProfile -ExecutionPolicy Bypass -File 00_control\Invoke-TrackBE2ESuite.ps1 -Tier 4"
    $pinfo.RedirectStandardOutput = $true
    $pinfo.RedirectStandardError = $true
    $pinfo.UseShellExecute = $false
    $pinfo.CreateNoWindow = $true
    $proc = [System.Diagnostics.Process]::Start($pinfo)
    $stdout = $proc.StandardOutput.ReadToEnd()
    $proc.WaitForExit()
    $swRun.Stop()

    $tier4Passed15 = ($proc.ExitCode -eq 0 -and $stdout -match "Tier 4 Pass Rate: 15/15 \(100%\)")
    if ($tier4Passed15) {
        $consecutiveTier4Pass++
        Write-Host ("  Tier 4 Run #{0}/{1}: 15/15 PASSED ({2:F1}s, Exit: 0)" -f $r, $Tier4Runs, $swRun.Elapsed.TotalSeconds) -ForegroundColor Green
    } else {
        Write-Host ("  Tier 4 Run #{0}/{1}: FAILED (Exit: {2})" -f $r, $Tier4Runs, $proc.ExitCode) -ForegroundColor Red
    }
}

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host ("  STRESS SUMMARY: Tier 4 Consecutive Passes: {0}/{1}" -f $consecutiveTier4Pass, $Tier4Runs) -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
