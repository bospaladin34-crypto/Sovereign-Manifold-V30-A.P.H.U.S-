# ACT-Omega Net v49.0.0
# Challenger M4-2: 10-Iteration Burst Stability Test
# File: C:\sovereign_manifold_v31\tests\e2e\test_m4_burst.ps1

$testScript = "C:\sovereign_manifold_v31\tests\e2e\Run-All-E2E-Tests.ps1"
$results = @()
$failedCount = 0

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "   CHALLENGER M4-2: 10-ITERATION BURST TEST (Run-All-E2E-Tests.ps1 M4)    " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan

for ($i = 1; $i -le 10; $i++) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $proc = Start-Process powershell -ArgumentList "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $testScript, "-Tier", "1", "-Milestone", "M4" -NoNewWindow -PassThru -Wait
    $sw.Stop()
    
    $exitCode = $proc.ExitCode
    $durationMs = [math]::Round($sw.Elapsed.TotalMilliseconds, 1)
    
    $status = if ($exitCode -eq 0) { "PASS" } else { "FAIL"; $failedCount++ }
    $color = if ($exitCode -eq 0) { "Green" } else { "Red" }
    
    $resObj = [PSCustomObject]@{
        Iteration = $i
        Status = $status
        ExitCode = $exitCode
        DurationMs = $durationMs
    }
    $results += $resObj
    Write-Host ("Iteration #{0,2}: [{1}] | ExitCode={2} | Duration={3}ms" -f $i, $status, $exitCode, $durationMs) -ForegroundColor $color
}

Write-Host "--------------------------------------------------------------------------" -ForegroundColor Cyan
$passedIterations = ($results | Where-Object { $_.ExitCode -eq 0 }).Count
$flakyRate = ($failedCount / 10.0) * 100.0

Write-Host ("Total Iterations: 10 | Passed: {0} | Failed: {1} | Flakiness: {2:0.0}%" -f $passedIterations, $failedCount, $flakyRate) -ForegroundColor $(if ($failedCount -eq 0) { "Green" } else { "Red" })
Write-Host "==========================================================================" -ForegroundColor Cyan

if ($failedCount -eq 0) {
    Write-Host "BURST TEST VERDICT: 100% STABLE, 0% FLAKINESS" -ForegroundColor Green
    exit 0
} else {
    Write-Host "BURST TEST VERDICT: FLAKINESS DETECTED" -ForegroundColor Red
    exit 1
}
