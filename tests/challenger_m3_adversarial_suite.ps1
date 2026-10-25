# Challenger M3-1: Adversarial Stress & Concurrency Test Suite
# Target: Milestone 3 (Tools 91–100 & Zero-Bracket L0 Rust CHAIN 100)
# File: C:\sovereign_manifold_v31\tests\challenger_m3_adversarial_suite.ps1
# Constraints: Zero Python | Measured Data Mandate

param(
    [string]$BaseUrl = "http://127.0.0.1:8097",
    [int]$BurstConcurrency = 50,
    [int]$BurstRounds = 3
)

$ErrorActionPreference = "Continue"

# Ensure .NET Http and Sockets assemblies are available and set connection limit
Add-Type -AssemblyName System.Net.Http
[System.Net.ServicePointManager]::DefaultConnectionLimit = 200

if (-not ([System.Management.Automation.PSTypeName]'M3BurstRunner').Type) {
    Add-Type -ReferencedAssemblies 'System.Net.Http' -TypeDefinition @'
using System;
using System.Net.Http;
using System.Diagnostics;
using System.Threading.Tasks;

public class M3ProbeResult {
    public int StatusCode;
    public double LatencyMs;
    public string Content;
    public string Error;
}

public class M3BurstRunner {
    public static async Task<M3ProbeResult> RunOne(HttpClient client, string url) {
        var r = new M3ProbeResult();
        var sw = Stopwatch.StartNew();
        try {
            var resp = await client.GetAsync(url).ConfigureAwait(false);
            sw.Stop();
            r.StatusCode = (int)resp.StatusCode;
            r.LatencyMs = sw.Elapsed.TotalMilliseconds;
            r.Content = await resp.Content.ReadAsStringAsync().ConfigureAwait(false);
        } catch (Exception ex) {
            sw.Stop();
            r.StatusCode = 0;
            r.LatencyMs = sw.Elapsed.TotalMilliseconds;
            r.Error = ex.Message;
        }
        return r;
    }
}
'@
}

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "  CHALLENGER M3-1: ADVERSARIAL STRESS & CONCURRENCY TEST SUITE             " -ForegroundColor Cyan
Write-Host "  Target URL: $BaseUrl | Concurrency: $BurstConcurrency | Rounds: $BurstRounds" -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan

$AllTestRecords = [System.Collections.Generic.List[PSObject]]::new()

function Record-Test {
    param(
        [string]$TestId,
        [string]$Name,
        [bool]$Passed,
        [string]$Details,
        [double]$DurationMs,
        [hashtable]$Metadata = @{}
    )
    $obj = [PSCustomObject]@{
        TestId = $TestId
        Name = $Name
        Passed = $Passed
        Details = $Details
        DurationMs = [math]::Round($DurationMs, 2)
        Metadata = $Metadata
    }
    $AllTestRecords.Add($obj)
    $color = if ($Passed) { "Green" } else { "Red" }
    $tag = if ($Passed) { "[PASS]" } else { "[FAIL]" }
    Write-Host "$tag $TestId - $Name : $Details ($($obj.DurationMs) ms)" -ForegroundColor $color
}

# -----------------------------------------------------------------------------
# TEST GROUP 1: Individual Tool Subroutes Under /api/v1/v49/*
# -----------------------------------------------------------------------------
Write-Host "`n>>> [SECTION 1] PROBING INDIVIDUAL V49 TOOL SUBROUTES <<<" -ForegroundColor Yellow

$toolRoutes = @(
    @{ Id = "T91"; Route = "/api/v1/v49/tool_91_ds3_triangulated_cft2_gravity"; ExpectedToolId = 91; KeyField = "genus" },
    @{ Id = "T92"; Route = "/api/v1/v49/tool_92_amplituhedron_9loop_hexagon_plucker"; ExpectedToolId = 92; KeyField = "particles_count" },
    @{ Id = "T93"; Route = "/api/v1/v49/tool_93_bekenstein_hawking_area_horizon_guard"; ExpectedToolId = 93; KeyField = "shm_ring_capacity_bytes" },
    @{ Id = "T94"; Route = "/api/v1/v49/tool_94_cubic_pyramid_integral_proof"; ExpectedToolId = 94; KeyField = "congruent_pyramids" },
    @{ Id = "T95"; Route = "/api/v1/v49/tool_95_bell_polytope_noncontextuality_audit"; ExpectedToolId = 95; KeyField = "polytopes_count" },
    @{ Id = "T96"; Route = "/api/v1/v49/tool_96_bipolar_vesica_caustic_envelope"; ExpectedToolId = 96; KeyField = "caustic_residual" },
    @{ Id = "T97"; Route = "/api/v1/v49/tool_97_hamilton_tait_nabla_quaternionic_field"; ExpectedToolId = 97; KeyField = "div_curl_f_exact" },
    @{ Id = "T98"; Route = "/api/v1/v49/tool_98_poincare_bendixson_destiny_atlas"; ExpectedToolId = 98; KeyField = "total_columns_evaluated" },
    @{ Id = "T99"; Route = "/api/v1/v49/tool_99_stanford_together_hybrid_link_agent"; ExpectedToolId = 99; KeyField = "latent_e8_dimensions" },
    @{ Id = "T100"; Route = "/api/v1/v49/tool_100_dzhanibekov_euler_axis_stabilizer"; ExpectedToolId = 100; KeyField = "angular_momentum_l2_norm" }
)

foreach ($tr in $toolRoutes) {
    $uri = "$BaseUrl$($tr.Route)"
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $statusCode = 0
    $body = ""
    $jsonValid = $false
    $parsedObj = $null
    try {
        $req = [System.Net.HttpWebRequest]::Create($uri)
        $req.Timeout = 10000
        $req.Method = "GET"
        $req.KeepAlive = $false
        $resp = $req.GetResponse()
        $statusCode = [int]$resp.StatusCode
        $reader = New-Object System.IO.StreamReader($resp.GetResponseStream())
        $body = $reader.ReadToEnd()
        $resp.Close()
        $sw.Stop()
        
        $parsedObj = $body | ConvertFrom-Json
        $jsonValid = ($null -ne $parsedObj)
    } catch {
        $sw.Stop()
        if ($_.Exception -is [System.Net.WebException] -and $_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
        }
    }

    $toolIdMatch = ($jsonValid -and ($parsedObj.tool_id -eq $tr.ExpectedToolId))
    $keyFieldPresent = ($jsonValid -and ($null -ne $parsedObj.$($tr.KeyField)))
    $passed = ($statusCode -eq 200) -and $jsonValid -and $toolIdMatch -and $keyFieldPresent

    Record-Test -TestId "SUB-$($tr.Id)" `
        -Name "Subroute $($tr.Route)" `
        -Passed $passed `
        -Details "HTTP $statusCode | JSON=$jsonValid | tool_id=$($parsedObj.tool_id) | $($tr.KeyField)=$($parsedObj.$($tr.KeyField))" `
        -DurationMs $sw.Elapsed.TotalMilliseconds `
        -Metadata @{ StatusCode = $statusCode; LatencyMs = $sw.Elapsed.TotalMilliseconds }
}

# -----------------------------------------------------------------------------
# TEST GROUP 2: Adversarial Route Probing (Alternative / Malformed Names)
# -----------------------------------------------------------------------------
Write-Host "`n>>> [SECTION 2] PROBING ADVERSARIAL & DISPATCH VARIANT ROUTES <<<" -ForegroundColor Yellow

$altRoutes = @(
    "/api/v1/v49/tool91_holographic_bound",
    "/api/v1/v49/tool92_grassmannian_amplituhedron",
    "/api/v1/v49/chain100_omni_suite?burst=adversarial&threads=50",
    "/api/v1/v49/unknown_tool_probe_fallback"
)

foreach ($ar in $altRoutes) {
    $uri = "$BaseUrl$ar"
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $statusCode = 0
    $body = ""
    $jsonValid = $false
    try {
        $req = [System.Net.HttpWebRequest]::Create($uri)
        $req.Timeout = 5000
        $req.Method = "GET"
        $resp = $req.GetResponse()
        $statusCode = [int]$resp.StatusCode
        $reader = New-Object System.IO.StreamReader($resp.GetResponseStream())
        $body = $reader.ReadToEnd()
        $resp.Close()
        $sw.Stop()
        $parsed = $body | ConvertFrom-Json
        $jsonValid = ($null -ne $parsed)
    } catch {
        $sw.Stop()
        if ($_.Exception -is [System.Net.WebException] -and $_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
        }
    }
    # For /api/v1/v49/*, any unmatched route falls through to run_chain100_omni_suite_measured (HTTP 200)
    $passed = ($statusCode -eq 200 -and $jsonValid)
    Record-Test -TestId "ALT-ROUTE" `
        -Name "Probe $ar" `
        -Passed $passed `
        -Details "HTTP $statusCode | Valid JSON=$jsonValid (Clean Fallback)" `
        -DurationMs $sw.Elapsed.TotalMilliseconds
}

# -----------------------------------------------------------------------------
# TEST GROUP 3: 50-Request Concurrent Bursts against chain100_omni_suite
# -----------------------------------------------------------------------------
Write-Host "`n>>> [SECTION 3] ADVERSARIAL CONCURRENT BURST STRESS HARNESS <<<" -ForegroundColor Yellow

$targetEndpoint = "$BaseUrl/api/v1/v49/chain100_omni_suite"

for ($round = 1; $round -le $BurstRounds; $round++) {
    Write-Host "`n--- Round ${round}: Launching $BurstConcurrency parallel requests against $targetEndpoint ---" -ForegroundColor Magenta
    
    $client = New-Object System.Net.Http.HttpClient
    $client.Timeout = [System.TimeSpan]::FromSeconds(30)
    $wallWatch = [System.Diagnostics.Stopwatch]::StartNew()

    $tasks = [System.Collections.Generic.List[System.Threading.Tasks.Task[M3ProbeResult]]]::new()
    for ($i = 0; $i -lt $BurstConcurrency; $i++) {
        $tasks.Add([M3BurstRunner]::RunOne($client, $targetEndpoint))
    }

    [System.Threading.Tasks.Task]::WaitAll($tasks.ToArray())
    $wallWatch.Stop()
    $client.Dispose()

    $results = @($tasks | ForEach-Object { $_.Result })
    $latArray = @($results | ForEach-Object { $_.LatencyMs })
    [Array]::Sort($latArray)
    $count = $latArray.Length
    $sum = 0
    foreach ($l in $latArray) { $sum += $l }
    $avgLatency = if ($count -gt 0) { $sum / $count } else { 0 }
    $minLatency = if ($count -gt 0) { $latArray[0] } else { 0 }
    $maxLatency = if ($count -gt 0) { $latArray[$count - 1] } else { 0 }
    $medianLatency = if ($count -gt 0) { $latArray[[math]::Floor($count / 2)] } else { 0 }
    $p95Index = [math]::Floor($count * 0.95)
    $p95Latency = if ($count -gt 0) { $latArray[$p95Index] } else { 0 }

    $statusCodes = @($results | ForEach-Object { $_.StatusCode })
    $non200Count = ($statusCodes | Where-Object { $_ -ne 200 }).Length
    $all200 = ($non200Count -eq 0)

    $jsonErrors = [System.Collections.Generic.List[string]]::new()
    $validJsonCount = 0
    foreach ($res in $results) {
        if (![string]::IsNullOrEmpty($res.Error)) {
            $jsonErrors.Add($res.Error)
        }
        if ($res.StatusCode -eq 200) {
            try {
                $obj = $res.Content | ConvertFrom-Json
                if ($obj -and $obj.chain100_complete -and ($obj.tools_total -eq 100)) {
                    $validJsonCount++
                } else {
                    $jsonErrors.Add("Invalid payload structure in 200 response")
                }
            } catch {
                $jsonErrors.Add("JSON parse error: $_")
            }
        }
    }

    $zeroErrors = ($jsonErrors.Count -eq 0)
    $allJsonValid = ($validJsonCount -eq $BurstConcurrency)
    $sub100msAvg = ($avgLatency -lt 100.0)

    Write-Host "  Round ${round} Results:" -ForegroundColor Gray
    Write-Host "    Completed Requests : $count / $BurstConcurrency"
    Write-Host "    Wall Clock Time    : $([math]::Round($wallWatch.Elapsed.TotalMilliseconds, 2)) ms"
    Write-Host "    Average Latency    : $([math]::Round($avgLatency, 2)) ms (Target: < 100.0 ms)"
    Write-Host "    Median Latency     : $([math]::Round($medianLatency, 2)) ms"
    Write-Host "    Min Latency        : $([math]::Round($minLatency, 2)) ms"
    Write-Host "    Max Latency        : $([math]::Round($maxLatency, 2)) ms"
    Write-Host "    p95 Latency        : $([math]::Round($p95Latency, 2)) ms"
    Write-Host "    All HTTP 200 OK    : $all200 (Non-200s: $non200Count)"
    Write-Host "    Valid JSON Parsed  : $validJsonCount / $BurstConcurrency"
    Write-Host "    Errors/Panics Count: $($jsonErrors.Count)"

    $roundPassed = $all200 -and $zeroErrors -and $allJsonValid -and $sub100msAvg

    Record-Test -TestId "BURST-R$round" `
        -Name "50-Parallel-Burst Round $round" `
        -Passed $roundPassed `
        -Details "AvgLat=$([math]::Round($avgLatency, 2))ms (<100ms: $sub100msAvg) | Med=$([math]::Round($medianLatency, 2))ms | Max=$([math]::Round($maxLatency, 2))ms | Wall=$([math]::Round($wallWatch.Elapsed.TotalMilliseconds, 2))ms | 200s=$($BurstConcurrency - $non200Count) | ValidJson=$validJsonCount/$BurstConcurrency | Errors=$($jsonErrors.Count)" `
        -DurationMs $wallWatch.Elapsed.TotalMilliseconds `
        -Metadata @{
            AvgLatencyMs = $avgLatency
            MedianLatencyMs = $medianLatency
            MaxLatencyMs = $maxLatency
            p95LatencyMs = $p95Latency
            All200 = $all200
            ValidJson = $allJsonValid
            ZeroErrors = $zeroErrors
            Sub100msAvg = $sub100msAvg
        }
}

# -----------------------------------------------------------------------------
# TEST GROUP 4: Zero-Square-Bracket Byte Level Verification
# -----------------------------------------------------------------------------
Write-Host "`n>>> [SECTION 4] STRICT ZERO-SQUARE-BRACKET BYTE AUDIT <<<" -ForegroundColor Yellow

$v49File = "C:\sovereign_manifold_v31\01_l0_rust\src\v49_muse_clean_and_chain100_synthesis.rs"
$bracketPassed = $false
$bracketCount = -1
$byteLen = 0

if (Test-Path $v49File) {
    $bytes = [System.IO.File]::ReadAllBytes($v49File)
    $byteLen = $bytes.Length
    $openBrackets = ($bytes | Where-Object { $_ -eq 91 }).Length
    $closeBrackets = ($bytes | Where-Object { $_ -eq 93 }).Length
    $bracketCount = $openBrackets + $closeBrackets
    $bracketPassed = ($bracketCount -eq 0)
}

Record-Test -TestId "ZERO-BRACKET" `
    -Name "Zero-Square-Bracket Audit (0x5B / 0x5D)" `
    -Passed $bracketPassed `
    -Details "Total Brackets=$bracketCount (0x5B=$openBrackets, 0x5D=$closeBrackets) across $byteLen bytes" `
    -DurationMs 1.0 `
    -Metadata @{ BracketCount = $bracketCount; ByteLength = $byteLen }

# -----------------------------------------------------------------------------
# TEST GROUP 5: Muse Zero-Unmeasured-Data Rigorous Code Audit
# -----------------------------------------------------------------------------
Write-Host "`n>>> [SECTION 5] MUSE ZERO-UNMEASURED-DATA MANDATE AUDIT <<<" -ForegroundColor Yellow

$code = [System.IO.File]::ReadAllText($v49File)

# Check for banned fake clamps or artificial floor patterns
$hasClampedFloors = ($code -match "\.max\(0\.001\)\.min\(1\.0\)" -or $code -match "\.max\(1\.0001\)")
$hasInstantNow = ($code -match "Instant::now\(\)")
$hasFsMetadata = ($code -match "fs::metadata")
$hasSha256 = ($code -match "v49_sha256_hex")

$musePassed = (-not $hasClampedFloors) -and $hasInstantNow -and $hasFsMetadata -and $hasSha256

Record-Test -TestId "MUSE-AUDIT" `
    -Name "Muse Zero-Unmeasured-Data Invariants" `
    -Passed $musePassed `
    -Details "Instant::now=$hasInstantNow | fs::metadata=$hasFsMetadata | SHA-256=$hasSha256 | BannedClamps=$hasClampedFloors" `
    -DurationMs 1.0 `
    -Metadata @{ HasInstantNow = $hasInstantNow; HasFsMetadata = $hasFsMetadata; HasSha256 = $hasSha256 }

# -----------------------------------------------------------------------------
# SUMMARY & VERDICT
# -----------------------------------------------------------------------------
Write-Host "`n==========================================================================" -ForegroundColor Cyan
Write-Host "                      TEST SUMMARY & VERDICT                             " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan

$totalTests = $AllTestRecords.Count
$passedTests = ($AllTestRecords | Where-Object { $_.Passed }).Count
$failedTests = $totalTests - $passedTests
$passRate = [math]::Round(($passedTests / $totalTests) * 100, 1)

Write-Host "Total Tests Run : $totalTests"
Write-Host "Passed Tests    : $passedTests"
Write-Host "Failed Tests    : $failedTests"
Write-Host "Pass Rate       : $passRate %"

$verdict = if ($failedTests -eq 0) { "APPROVE" } else { "REQUEST_CHANGES" }
$verdictColor = if ($verdict -eq "APPROVE") { "Green" } else { "Red" }
Write-Host "`nFINAL VERDICT: $verdict" -ForegroundColor $verdictColor
Write-Host "==========================================================================" -ForegroundColor Cyan

# Return structured JSON for orchestrator / handoff embedding
$AllTestRecords | ConvertTo-Json -Depth 4 | Out-File -Encoding utf8 "C:\sovereign_manifold_v31\tests\challenger_m3_results.json"
exit $failedTests
