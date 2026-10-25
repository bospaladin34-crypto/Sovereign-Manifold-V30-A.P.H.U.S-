# ACT-Omega Net v49.0.0
# Challenger M5-1: High-Concurrency Burst & Adversarial API Stress Test Suite
# File: C:\sovereign_manifold_v31\tests\challenger_m5_concurrency_stress.ps1
# Constraints: Zero Python | Zero-Unmeasured Data Mandate | Opaque-Box

param(
    [string]$BaseUrl = "http://127.0.0.1:8097",
    [int]$BurstConcurrency = 50,
    [int]$RoundsPerEndpoint = 3,
    [string]$OutputPath = "C:\sovereign_manifold_v31\tests\e2e\reports\challenger_m5_stress_results.json"
)

$ErrorActionPreference = "Continue"

Add-Type -AssemblyName System.Net.Http
[System.Net.ServicePointManager]::DefaultConnectionLimit = 500

if (-not ([System.Management.Automation.PSTypeName]'M5BurstRunner').Type) {
    Add-Type -ReferencedAssemblies 'System.Net.Http' -TypeDefinition @'
using System;
using System.Net.Http;
using System.Diagnostics;
using System.Threading.Tasks;
using System.Collections.Generic;

public class M5ProbeResult {
    public int StatusCode;
    public double LatencyMs;
    public string Content;
    public string Error;
}

public class M5BurstRunner {
    public static async Task<M5ProbeResult> RunOne(HttpClient client, string url, string headerKey = null, string headerVal = null) {
        var r = new M5ProbeResult();
        var sw = Stopwatch.StartNew();
        try {
            using (var req = new HttpRequestMessage(HttpMethod.Get, url)) {
                if (!string.IsNullOrEmpty(headerKey) && !string.IsNullOrEmpty(headerVal)) {
                    req.Headers.Add(headerKey, headerVal);
                }
                using (var resp = await client.SendAsync(req).ConfigureAwait(false)) {
                    sw.Stop();
                    r.StatusCode = (int)resp.StatusCode;
                    r.LatencyMs = sw.Elapsed.TotalMilliseconds;
                    r.Content = await resp.Content.ReadAsStringAsync().ConfigureAwait(false);
                }
            }
        } catch (Exception ex) {
            sw.Stop();
            r.StatusCode = 0;
            r.LatencyMs = sw.Elapsed.TotalMilliseconds;
            r.Error = ex.Message;
            if (ex.InnerException != null) {
                r.Error += " -> " + ex.InnerException.Message;
            }
        }
        return r;
    }
}
'@
}

Write-Host ""
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "   CHALLENGER M5-1: ADVERSARIAL API CONCURRENCY BURST HARNESS              " -ForegroundColor Cyan
Write-Host "   Target URL: $BaseUrl | Concurrency: $BurstConcurrency | Rounds: $RoundsPerEndpoint" -ForegroundColor Cyan
Write-Host "   Requirements: 0 Socket Hangs | Latency < 100ms | 0 Process Crashes    " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan

$suiteWatch = [System.Diagnostics.Stopwatch]::StartNew()
$AllResults = [System.Collections.Generic.List[PSObject]]::new()
$globalFailCount = 0

function Execute-Burst-Test {
    param(
        [string]$TestId,
        [string]$TestName,
        [string]$Url,
        [string]$HeaderKey = $null,
        [string]$HeaderVal = $null,
        [int]$ExpectedStatusCode = 200,
        [scriptblock]$Validator = $null,
        [double]$MaxAllowedAvgLatencyMs = 100.0,
        [int]$Rounds = 3
    )

    Write-Host "`n>>> [RUNNING] $TestId : $TestName" -ForegroundColor Yellow
    Write-Host "    Target: $Url (Expect HTTP $ExpectedStatusCode, Concurrency $BurstConcurrency x $Rounds rounds)" -ForegroundColor Gray

    $roundSummaries = @()

    for ($r = 1; $r -le $Rounds; $r++) {
        $client = New-Object System.Net.Http.HttpClient
        $client.Timeout = [System.TimeSpan]::FromSeconds(15)

        $wallSw = [System.Diagnostics.Stopwatch]::StartNew()
        $tasks = [System.Collections.Generic.List[System.Threading.Tasks.Task[M5ProbeResult]]]::new()

        for ($i = 0; $i -lt $BurstConcurrency; $i++) {
            $tasks.Add([M5BurstRunner]::RunOne($client, $Url, $HeaderKey, $HeaderVal))
        }

        [System.Threading.Tasks.Task]::WaitAll($tasks.ToArray())
        $wallSw.Stop()
        $client.Dispose()

        $results = @($tasks | ForEach-Object { $_.Result })
        $latencies = @($results | ForEach-Object { $_.LatencyMs })
        [Array]::Sort($latencies)

        $count = $latencies.Length
        $sum = 0
        foreach ($lat in $latencies) { $sum += $lat }
        $avg = if ($count -gt 0) { $sum / $count } else { 0 }
        $min = if ($count -gt 0) { $latencies[0] } else { 0 }
        $max = if ($count -gt 0) { $latencies[$count - 1] } else { 0 }
        $median = if ($count -gt 0) { $latencies[[math]::Floor($count / 2)] } else { 0 }
        $p95 = if ($count -gt 0) { $latencies[[math]::Floor($count * 0.95)] } else { 0 }

        $statusCodes = @($results | ForEach-Object { $_.StatusCode })
        $matchedStatusCount = ($statusCodes | Where-Object { $_ -eq $ExpectedStatusCode }).Length
        $hangsCount = ($results | Where-Object { $_.StatusCode -eq 0 -or -not [string]::IsNullOrEmpty($_.Error) }).Length

        $payloadValidCount = 0
        $firstError = ""
        foreach ($res in $results) {
            if (-not [string]::IsNullOrEmpty($res.Error)) {
                if ([string]::IsNullOrEmpty($firstError)) { $firstError = $res.Error }
            }
            if ($res.StatusCode -eq $ExpectedStatusCode) {
                if ($null -ne $Validator) {
                    $isValid = & $Validator $res.Content
                    if ($isValid) { $payloadValidCount++ }
                } else {
                    $payloadValidCount++
                }
            }
        }

        $roundPassed = ($matchedStatusCount -eq $BurstConcurrency) -and 
                       ($hangsCount -eq 0) -and 
                       ($payloadValidCount -eq $BurstConcurrency) -and 
                       ($avg -lt $MaxAllowedAvgLatencyMs)

        $roundObj = [PSCustomObject]@{
            Round = $r
            Passed = $roundPassed
            TotalRequests = $BurstConcurrency
            MatchedStatus = $matchedStatusCount
            SocketHangs = $hangsCount
            PayloadValid = $payloadValidCount
            AvgLatencyMs = [math]::Round($avg, 2)
            MinLatencyMs = [math]::Round($min, 2)
            MaxLatencyMs = [math]::Round($max, 2)
            MedianLatencyMs = [math]::Round($median, 2)
            P95LatencyMs = [math]::Round($p95, 2)
            WallClockMs = [math]::Round($wallSw.Elapsed.TotalMilliseconds, 2)
            FirstError = $firstError
        }
        $roundSummaries += $roundObj

        $rColor = if ($roundPassed) { "Green" } else { "Red" }
        Write-Host ("      Round {0}: HTTP={1}/{2} | Hangs={3} | AvgLat={4:0.0}ms | P95={5:0.0}ms | Wall={6:0.0}ms" -f 
            $r, $matchedStatusCount, $BurstConcurrency, $hangsCount, $avg, $p95, $wallSw.Elapsed.TotalMilliseconds) -ForegroundColor $rColor
        if (-not [string]::IsNullOrEmpty($firstError)) {
            Write-Host ("        Error observed: {0}" -f $firstError) -ForegroundColor Red
        }
    }

    $failedRounds = ($roundSummaries | Where-Object { -not $_.Passed }).Length
    $overallPassed = ($failedRounds -eq 0)
    if (-not $overallPassed) { $script:globalFailCount++ }

    $allAvgs = @($roundSummaries | ForEach-Object { $_.AvgLatencyMs })
    $grandAvg = [math]::Round((($allAvgs | Measure-Object -Average).Average), 2)
    $maxP95 = [math]::Round((($roundSummaries | Measure-Object -Property P95LatencyMs -Maximum).Maximum), 2)
    $totalHangs = ($roundSummaries | Measure-Object -Property SocketHangs -Sum).Sum

    $testRecord = [PSCustomObject]@{
        TestId = $TestId
        TestName = $TestName
        Passed = $overallPassed
        Endpoint = $Url
        ExpectedStatus = $ExpectedStatusCode
        TotalRounds = $Rounds
        RequestsPerRound = $BurstConcurrency
        TotalRequests = ($Rounds * $BurstConcurrency)
        TotalHangs = $totalHangs
        GrandAvgLatencyMs = $grandAvg
        MaxP95LatencyMs = $maxP95
        RoundDetails = $roundSummaries
    }
    $script:AllResults.Add($testRecord)

    $summaryColor = if ($overallPassed) { "Green" } else { "Red" }
    $tag = if ($overallPassed) { "[PASS]" } else { "[FAIL]" }
    Write-Host ("    {0} {1} : GrandAvg={2:0.0}ms | MaxP95={3:0.0}ms | Hangs={4}" -f 
        $tag, $TestName, $grandAvg, $maxP95, $totalHangs) -ForegroundColor $summaryColor
}

# -----------------------------------------------------------------------------
# ADVERSARIAL TEST 1: /api/v1/v49/chain100_omni_suite Concurrent Bursts (Heavy Workload)
# -----------------------------------------------------------------------------
Execute-Burst-Test `
    -TestId "ADV-01" `
    -TestName "CHAIN 100 Omni-Suite Concurrent Burst" `
    -Url "$BaseUrl/api/v1/v49/chain100_omni_suite" `
    -ExpectedStatusCode 200 `
    -MaxAllowedAvgLatencyMs 100.0 `
    -Rounds $RoundsPerEndpoint `
    -Validator {
        param($content)
        try {
            $json = $content | ConvertFrom-Json
            return ($null -ne $json -and $json.chain100_complete -eq $true -and $json.tools_total -eq 100 -and $null -ne $json.tool_91 -and $null -ne $json.tool_100)
        } catch {
            return $false
        }
    }

# -----------------------------------------------------------------------------
# ADVERSARIAL TEST 2: /api/v1/admin/self_exit Unauthenticated Security Burst
# -----------------------------------------------------------------------------
Execute-Burst-Test `
    -TestId "ADV-02" `
    -TestName "Admin Self-Exit Unauthenticated Rejection Burst (HTTP 403)" `
    -Url "$BaseUrl/api/v1/admin/self_exit" `
    -ExpectedStatusCode 403 `
    -MaxAllowedAvgLatencyMs 100.0 `
    -Rounds $RoundsPerEndpoint `
    -Validator {
        param($content)
        return ($content -like "*FORBIDDEN*" -or $content -like "*DENIED*" -or $content.Length -gt 0)
    }

# -----------------------------------------------------------------------------
# ADVERSARIAL TEST 3: /api/v1/admin/self_exit Forged Header Burst
# -----------------------------------------------------------------------------
Execute-Burst-Test `
    -TestId "ADV-03" `
    -TestName "Admin Self-Exit Forged Header Rejection Burst (HTTP 403)" `
    -Url "$BaseUrl/api/v1/admin/self_exit" `
    -HeaderKey "X-Sovereign-Operator-Key" `
    -HeaderVal "FORGED-ATTACKER-TOKEN-0xDEADBEEF" `
    -ExpectedStatusCode 403 `
    -MaxAllowedAvgLatencyMs 100.0 `
    -Rounds $RoundsPerEndpoint `
    -Validator {
        param($content)
        return ($content -like "*FORBIDDEN*" -or $content -like "*DENIED*" -or $content.Length -gt 0)
    }

# -----------------------------------------------------------------------------
# ADVERSARIAL TEST 4: Tool 91 (Triangulated dS3 Gravity) Concurrent Burst
# -----------------------------------------------------------------------------
Execute-Burst-Test `
    -TestId "ADV-04" `
    -TestName "Tool 91 Triangulated dS3 Gravity Burst" `
    -Url "$BaseUrl/api/v1/v49/tool_91_ds3_triangulated_cft2_gravity" `
    -ExpectedStatusCode 200 `
    -MaxAllowedAvgLatencyMs 100.0 `
    -Rounds $RoundsPerEndpoint `
    -Validator {
        param($content)
        try {
            $json = $content | ConvertFrom-Json
            return ($null -ne $json -and $json.tool_id -eq 91 -and $json.genus -eq 3 -and $json.pairs_of_pants -eq 4)
        } catch { return $false }
    }

# -----------------------------------------------------------------------------
# ADVERSARIAL TEST 5: Tool 92 (Amplituhedron SYM Hexagon Plucker) Concurrent Burst
# -----------------------------------------------------------------------------
Execute-Burst-Test `
    -TestId "ADV-05" `
    -TestName "Tool 92 Amplituhedron SYM Hexagon Burst" `
    -Url "$BaseUrl/api/v1/v49/tool_92_amplituhedron_9loop_hexagon_plucker" `
    -ExpectedStatusCode 200 `
    -MaxAllowedAvgLatencyMs 100.0 `
    -Rounds $RoundsPerEndpoint `
    -Validator {
        param($content)
        try {
            $json = $content | ConvertFrom-Json
            return ($null -ne $json -and $json.tool_id -eq 92 -and $json.loops_count -eq 9 -and $json.particles_count -eq 6)
        } catch { return $false }
    }

# -----------------------------------------------------------------------------
# ADVERSARIAL TEST 6: Tool 97 (Quaternionic Nabla Operator) Concurrent Burst
# -----------------------------------------------------------------------------
Execute-Burst-Test `
    -TestId "ADV-06" `
    -TestName "Tool 97 Quaternionic Nabla Operator Burst" `
    -Url "$BaseUrl/api/v1/v49/tool_97_hamilton_tait_nabla_quaternionic_field" `
    -ExpectedStatusCode 200 `
    -MaxAllowedAvgLatencyMs 100.0 `
    -Rounds $RoundsPerEndpoint `
    -Validator {
        param($content)
        try {
            $json = $content | ConvertFrom-Json
            return ($null -ne $json -and $json.tool_id -eq 97 -and [double]$json.div_curl_f_exact -eq 0.0)
        } catch { return $false }
    }

# -----------------------------------------------------------------------------
# ADVERSARIAL TEST 7: Tool 100 (Dzhanibekov Intermediate Axis) Concurrent Burst
# -----------------------------------------------------------------------------
Execute-Burst-Test `
    -TestId "ADV-07" `
    -TestName "Tool 100 Dzhanibekov Intermediate Axis Burst" `
    -Url "$BaseUrl/api/v1/v49/tool_100_dzhanibekov_euler_axis_stabilizer" `
    -ExpectedStatusCode 200 `
    -MaxAllowedAvgLatencyMs 100.0 `
    -Rounds $RoundsPerEndpoint `
    -Validator {
        param($content)
        try {
            $json = $content | ConvertFrom-Json
            return ($null -ne $json -and $json.tool_id -eq 100 -and $json.chain100_capstone_status -like "*CHAIN_100_CENTURY_MILESTONE_COMPLETE*")
        } catch { return $false }
    }

# -----------------------------------------------------------------------------
# ADVERSARIAL TEST 8: Mixed Rapid Interleaved Burst (All Endpoints Concurrently)
# -----------------------------------------------------------------------------
Write-Host "`n>>> [RUNNING] ADV-08 : Mixed Rapid Interleaved Concurrency Burst" -ForegroundColor Yellow
$mixedEndpoints = @(
    "$BaseUrl/health",
    "$BaseUrl/api/v1/v49/chain100_omni_suite",
    "$BaseUrl/api/v1/v49/tool_94_cubic_pyramid_integral_proof",
    "$BaseUrl/api/v1/v49/tool_98_poincare_bendixson_destiny_atlas",
    "$BaseUrl/api/v1/admin/self_exit"
)

$client = New-Object System.Net.Http.HttpClient
$client.Timeout = [System.TimeSpan]::FromSeconds(15)
$wallSw = [System.Diagnostics.Stopwatch]::StartNew()
$tasks = [System.Collections.Generic.List[System.Threading.Tasks.Task[M5ProbeResult]]]::new()

for ($i = 0; $i -lt 50; $i++) {
    $targetUrl = $mixedEndpoints[$i % $mixedEndpoints.Length]
    $tasks.Add([M5BurstRunner]::RunOne($client, $targetUrl))
}

[System.Threading.Tasks.Task]::WaitAll($tasks.ToArray())
$wallSw.Stop()
$client.Dispose()

$mixedResults = @($tasks | ForEach-Object { $_.Result })
$mixedHangs = ($mixedResults | Where-Object { $_.StatusCode -eq 0 -or -not [string]::IsNullOrEmpty($_.Error) }).Length
$mixedLat = @($mixedResults | ForEach-Object { $_.LatencyMs })
[Array]::Sort($mixedLat)
$mixedSum = 0; foreach ($l in $mixedLat) { $mixedSum += $l }
$mixedAvg = if ($mixedLat.Length -gt 0) { $mixedSum / $mixedLat.Length } else { 0 }
$mixedP95 = if ($mixedLat.Length -gt 0) { $mixedLat[[math]::Floor($mixedLat.Length * 0.95)] } else { 0 }
$mixedPassed = ($mixedHangs -eq 0) -and ($mixedAvg -lt 100.0)
if (-not $mixedPassed) { $globalFailCount++ }

$mixedRecord = [PSCustomObject]@{
    TestId = "ADV-08"
    TestName = "Mixed Rapid Interleaved Concurrency Burst"
    Passed = $mixedPassed
    Endpoint = "MIXED (5 endpoints)"
    ExpectedStatus = 0
    TotalRounds = 1
    RequestsPerRound = 50
    TotalRequests = 50
    TotalHangs = $mixedHangs
    GrandAvgLatencyMs = [math]::Round($mixedAvg, 2)
    MaxP95LatencyMs = [math]::Round($mixedP95, 2)
    RoundDetails = @()
}
$AllResults.Add($mixedRecord)

$mColor = if ($mixedPassed) { "Green" } else { "Red" }
$mTag = if ($mixedPassed) { "[PASS]" } else { "[FAIL]" }
Write-Host ("    {0} Mixed Interleaved Burst: Hangs={1} | AvgLat={2:0.0}ms | P95={3:0.0}ms | Wall={4:0.0}ms" -f 
    $mTag, $mixedHangs, $mixedAvg, $mixedP95, $wallSw.Elapsed.TotalMilliseconds) -ForegroundColor $mColor

# -----------------------------------------------------------------------------
# ADVERSARIAL TEST 9: Host Post-Stress Survival Verification
# -----------------------------------------------------------------------------
Write-Host "`n>>> [RUNNING] ADV-09 : Host Daemon Survival Post-Stress Verification" -ForegroundColor Yellow
$proc = Get-Process -Name "v31_swarm" -ErrorAction SilentlyContinue
$healthSw = [System.Diagnostics.Stopwatch]::StartNew()
$healthResp = $null
try {
    $healthResp = Invoke-WebRequest -Uri "$BaseUrl/health" -UseBasicParsing -TimeoutSec 5
} catch {}
$healthSw.Stop()

$hostAlive = ($null -ne $proc -and -not $proc.HasExited)
$healthOk = ($null -ne $healthResp -and $healthResp.StatusCode -eq 200)
$adv09Passed = $hostAlive -and $healthOk
if (-not $adv09Passed) { $globalFailCount++ }

$hostRecord = [PSCustomObject]@{
    TestId = "ADV-09"
    TestName = "Host Daemon Survival Post-Stress Verification"
    Passed = $adv09Passed
    Endpoint = "$BaseUrl/health"
    ExpectedStatus = 200
    TotalRounds = 1
    RequestsPerRound = 1
    TotalRequests = 1
    TotalHangs = $(if ($adv09Passed) { 0 } else { 1 })
    GrandAvgLatencyMs = [math]::Round($healthSw.Elapsed.TotalMilliseconds, 2)
    MaxP95LatencyMs = [math]::Round($healthSw.Elapsed.TotalMilliseconds, 2)
    RoundDetails = @()
}
$AllResults.Add($hostRecord)

$hColor = if ($adv09Passed) { "Green" } else { "Red" }
$hTag = if ($adv09Passed) { "[PASS]" } else { "[FAIL]" }
Write-Host ("    {0} Host Survival: ProcessRunning={1} (PID {2}) | /health HTTP={3} in {4:0.0}ms" -f 
    $hTag, $hostAlive, $proc.Id, $healthResp.StatusCode, $healthSw.Elapsed.TotalMilliseconds) -ForegroundColor $hColor

$suiteWatch.Stop()

# -----------------------------------------------------------------------------
# SUMMARY & JSON EXPORT
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "              CHALLENGER M5-1 ADVERSARIAL STRESS SUMMARY                   " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
$totalTests = $AllResults.Count
$passedTests = ($AllResults | Where-Object { $_.Passed }).Length
$failedTests = ($AllResults | Where-Object { -not $_.Passed }).Length
$totalRequestsFired = ($AllResults | Measure-Object -Property TotalRequests -Sum).Sum
$totalHangsRecorded = ($AllResults | Measure-Object -Property TotalHangs -Sum).Sum

Write-Host ("  Total Adversarial Tests : {0}" -f $totalTests) -ForegroundColor Gray
Write-Host ("  Passed                  : {0} ({1:0.0}%)" -f $passedTests, (($passedTests / $totalTests) * 100)) -ForegroundColor $(if ($failedTests -eq 0) { "Green" } else { "Red" })
Write-Host ("  Failed                  : {0}" -f $failedTests) -ForegroundColor $(if ($failedTests -eq 0) { "Green" } else { "Red" })
Write-Host ("  Total HTTP Requests     : {0}" -f $totalRequestsFired) -ForegroundColor Gray
Write-Host ("  Total Socket Hangs      : {0}" -f $totalHangsRecorded) -ForegroundColor $(if ($totalHangsRecorded -eq 0) { "Green" } else { "Red" })
Write-Host ("  Total Suite Duration    : {0:0.0}s" -f ($suiteWatch.Elapsed.TotalSeconds)) -ForegroundColor Gray
Write-Host "==========================================================================" -ForegroundColor Cyan

# Export JSON report
$reportDir = [System.IO.Path]::GetDirectoryName($OutputPath)
if (-not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
}

$exportPayload = [PSCustomObject]@{
    Suite = "Challenger M5-1 Adversarial Concurrency Stress"
    TimestampUtc = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    BaseUrl = $BaseUrl
    BurstConcurrency = $BurstConcurrency
    TotalTests = $totalTests
    PassedTests = $passedTests
    FailedTests = $failedTests
    TotalRequests = $totalRequestsFired
    TotalSocketHangs = $totalHangsRecorded
    DurationSeconds = [math]::Round($suiteWatch.Elapsed.TotalSeconds, 2)
    Results = $AllResults
}

$exportPayload | ConvertTo-Json -Depth 5 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host "Exported stress results to $OutputPath" -ForegroundColor Green

if ($failedTests -eq 0) {
    Write-Host "`n>>> [VERDICT: ALL ADVERSARIAL STRESS TESTS PASSED (0 HANGS, LATENCY < 100MS)] <<<" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n>>> [VERDICT: ADVERSARIAL STRESS FAILURES DETECTED] <<<" -ForegroundColor Red
    exit 1
}
