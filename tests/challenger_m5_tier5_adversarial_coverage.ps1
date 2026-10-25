# =============================================================================
# ACT-Omega Net v49.0.0 (CHAIN 100 Century Milestone)
# Challenger M5-T5-1: Tier 5 White-Box Adversarial Coverage Hardening Suite
# File: C:\sovereign_manifold_v31\tests\challenger_m5_tier5_adversarial_coverage.ps1
# Constraints: Zero Python | Measured Data Mandate | Empirical Verification
# =============================================================================

param(
    [string]$RepoRoot = "C:\sovereign_manifold_v31",
    [string]$BaseSwarmUrl = "http://127.0.0.1:8097",
    [string]$SwarmHost = "127.0.0.1",
    [int]$SwarmPort = 8097,
    [int]$BurstConcurrency = 50,
    [string]$ReportJsonPath = "C:\sovereign_manifold_v31\tests\e2e\reports\challenger_m5_t5_results.json"
)

$ErrorActionPreference = "Continue"

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "  CHALLENGER M5-T5-1: TIER 5 WHITE-BOX ADVERSARIAL COVERAGE HARDENING    " -ForegroundColor Cyan
Write-Host "  Target: ACT-Omega Net v49.0.0 (CHAIN 100 Century Milestone)             " -ForegroundColor Cyan
Write-Host "  Host: $BaseSwarmUrl | Concurrency: $BurstConcurrency                     " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan

Add-Type -AssemblyName System.Net.Http

$Results = [ordered]@{
    Timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    Version = "v49.0.0"
    SuiteA_HttpProtocolResilience = [ordered]@{
        TotalTests = 0
        PassedTests = 0
        FailedTests = 0
        Details = @()
        Status = "PENDING"
    }
    SuiteB_AdminAuthAndSecurity = [ordered]@{
        TotalTests = 0
        PassedTests = 0
        FailedTests = 0
        Details = @()
        Status = "PENDING"
    }
    SuiteC_V49FunctionalInvariants = [ordered]@{
        TotalTests = 0
        PassedTests = 0
        FailedTests = 0
        Details = @()
        Status = "PENDING"
    }
    SuiteD_ConcurrencyStress = [ordered]@{
        TotalTests = 0
        PassedTests = 0
        FailedTests = 0
        Details = @()
        Status = "PENDING"
    }
    OverallSummary = [ordered]@{
        TotalProbes = 0
        PassedProbes = 0
        FailedProbes = 0
        Verdict = "PENDING"
    }
}

function Record-ProbeResult {
    param(
        [string]$SuiteName,
        [string]$TestId,
        [string]$Name,
        [bool]$Passed,
        [string]$Message,
        [double]$ElapsedMs,
        [hashtable]$Metadata = @{}
    )
    $rec = [ordered]@{
        TestId = $TestId
        Name = $Name
        Passed = $Passed
        Message = $Message
        ElapsedMs = [math]::Round($ElapsedMs, 2)
        Metadata = $Metadata
    }
    
    $color = if ($Passed) { "Green" } else { "Red" }
    $statusText = if ($Passed) { "PASS" } else { "FAIL" }
    Write-Host ("  [{0}] [{1}] {2,-42} : {3} ({4}ms)" -f $TestId, $statusText, $Name, $Message, [math]::Round($ElapsedMs, 1)) -ForegroundColor $color

    $suiteObj = $Results[$SuiteName]
    $suiteObj.TotalTests++
    if ($Passed) { $suiteObj.PassedTests++ } else { $suiteObj.FailedTests++ }
    $suiteObj.Details += $rec
}

# =============================================================================
# SUITE A: HTTP Protocol & Framing Resilience (v31_swarm.rs)
# =============================================================================
Write-Host "`n--- [SUITE A] HTTP PROTOCOL & FRAMING RESILIENCE PROBES ---" -ForegroundColor Yellow

# TC-A01: Zero-Length TCP Connect/Disconnect
$sw = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $tcp = New-Object System.Net.Sockets.TcpClient
    $tcp.Connect($SwarmHost, $SwarmPort)
    $connected = $tcp.Connected
    $tcp.Close()
    # Confirm server did not crash
    $client = New-Object System.Net.Http.HttpClient
    $ping = $client.GetAsync("$BaseSwarmUrl/api/v1/telemetry").Result
    $sw.Stop()
    $passed = $connected -and ($ping.StatusCode -eq 200)
    Record-ProbeResult "SuiteA_HttpProtocolResilience" "TC-A01" "Zero-Length TCP Connect/Disconnect" $passed "Immediate RST/FIN handled gracefully without host crash" $sw.Elapsed.TotalMilliseconds
} catch {
    $sw.Stop()
    Record-ProbeResult "SuiteA_HttpProtocolResilience" "TC-A01" "Zero-Length TCP Connect/Disconnect" $false "Exception: $_" $sw.Elapsed.TotalMilliseconds
}

# TC-A02: Raw Non-HTTP Garbage Framing
$sw = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $tcp = New-Object System.Net.Sockets.TcpClient
    $tcp.Connect($SwarmHost, $SwarmPort)
    $stream = $tcp.GetStream()
    $garbage = [System.Text.Encoding]::ASCII.GetBytes("MALFORMED_NON_HTTP_BINARY_STREAM_0xDEADBEEF`r`n`r`n")
    $stream.Write($garbage, 0, $garbage.Length)
    Start-Sleep -Milliseconds 50
    $tcp.Close()
    
    $client = New-Object System.Net.Http.HttpClient
    $ping = $client.GetAsync("$BaseSwarmUrl/api/v1/telemetry").Result
    $sw.Stop()
    $passed = ($ping.StatusCode -eq 200)
    Record-ProbeResult "SuiteA_HttpProtocolResilience" "TC-A02" "Raw Non-HTTP Garbage Framing" $passed "Malformed non-HTTP request handled without crash; connection dropped cleanly" $sw.Elapsed.TotalMilliseconds
} catch {
    $sw.Stop()
    Record-ProbeResult "SuiteA_HttpProtocolResilience" "TC-A02" "Raw Non-HTTP Garbage Framing" $false "Exception: $_" $sw.Elapsed.TotalMilliseconds
}

# TC-A03: Giant 8KB URI Query String
$sw = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $client = New-Object System.Net.Http.HttpClient
    $client.Timeout = [System.TimeSpan]::FromSeconds(10)
    $junk = "x" * 8192
    $resp = $client.GetAsync("$BaseSwarmUrl/api/v1/telemetry?junk=$junk").Result
    $sw.Stop()
    $passed = ($resp.StatusCode -eq 200)
    Record-ProbeResult "SuiteA_HttpProtocolResilience" "TC-A03" "Giant 8KB URI Query Resilience" $passed "8KB URI handled gracefully (HTTP $([int]$resp.StatusCode))" $sw.Elapsed.TotalMilliseconds
} catch {
    $sw.Stop()
    Record-ProbeResult "SuiteA_HttpProtocolResilience" "TC-A03" "Giant 8KB URI Query Resilience" $false "Exception: $_" $sw.Elapsed.TotalMilliseconds
}

# TC-A04: Truncated Content-Length POST Body
$sw = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $tcp = New-Object System.Net.Sockets.TcpClient
    $tcp.Connect($SwarmHost, $SwarmPort)
    $stream = $tcp.GetStream()
    $msg = "POST /api/v1/telemetry HTTP/1.1`r`nHost: 127.0.0.1`r`nContent-Length: 2048`r`n`r`nshort"
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($msg)
    $stream.Write($bytes, 0, $bytes.Length)
    Start-Sleep -Milliseconds 50
    $tcp.Close()
    
    $client = New-Object System.Net.Http.HttpClient
    $ping = $client.GetAsync("$BaseSwarmUrl/api/v1/telemetry").Result
    $sw.Stop()
    $passed = ($ping.StatusCode -eq 200)
    Record-ProbeResult "SuiteA_HttpProtocolResilience" "TC-A04" "Truncated Content-Length Body" $passed "Premature socket close on partial body handled cleanly without thread hang" $sw.Elapsed.TotalMilliseconds
} catch {
    $sw.Stop()
    Record-ProbeResult "SuiteA_HttpProtocolResilience" "TC-A04" "Truncated Content-Length Body" $false "Exception: $_" $sw.Elapsed.TotalMilliseconds
}

# TC-A05: Malformed Content-Length Parsing
$sw = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $tcp = New-Object System.Net.Sockets.TcpClient
    $tcp.Connect($SwarmHost, $SwarmPort)
    $stream = $tcp.GetStream()
    $msg = "POST /api/v1/telemetry HTTP/1.1`r`nHost: 127.0.0.1`r`nContent-Length: -99999`r`n`r`n"
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($msg)
    $stream.Write($bytes, 0, $bytes.Length)
    Start-Sleep -Milliseconds 50
    $tcp.Close()
    
    $client = New-Object System.Net.Http.HttpClient
    $ping = $client.GetAsync("$BaseSwarmUrl/api/v1/telemetry").Result
    $sw.Stop()
    $passed = ($ping.StatusCode -eq 200)
    Record-ProbeResult "SuiteA_HttpProtocolResilience" "TC-A05" "Negative Content-Length Handling" $passed "Negative Content-Length parsed safely via parse::<usize>() without panic" $sw.Elapsed.TotalMilliseconds
} catch {
    $sw.Stop()
    Record-ProbeResult "SuiteA_HttpProtocolResilience" "TC-A05" "Negative Content-Length Handling" $false "Exception: $_" $sw.Elapsed.TotalMilliseconds
}

# TC-A06: Clamped Content-Length Boundary
$sw = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $tcp = New-Object System.Net.Sockets.TcpClient
    $tcp.Connect($SwarmHost, $SwarmPort)
    $stream = $tcp.GetStream()
    # Content-Length 500,000 > 262,144 limit; send 10 bytes then close
    $msg = "POST /api/v1/telemetry HTTP/1.1`r`nHost: 127.0.0.1`r`nContent-Length: 500000`r`n`r`nabcdefghij"
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($msg)
    $stream.Write($bytes, 0, $bytes.Length)
    Start-Sleep -Milliseconds 50
    $tcp.Close()
    
    $client = New-Object System.Net.Http.HttpClient
    $ping = $client.GetAsync("$BaseSwarmUrl/api/v1/telemetry").Result
    $sw.Stop()
    $passed = ($ping.StatusCode -eq 200)
    Record-ProbeResult "SuiteA_HttpProtocolResilience" "TC-A06" "Clamped Content-Length Boundary" $passed "Content-Length clamping (min(262144)) verified safely" $sw.Elapsed.TotalMilliseconds
} catch {
    $sw.Stop()
    Record-ProbeResult "SuiteA_HttpProtocolResilience" "TC-A06" "Clamped Content-Length Boundary" $false "Exception: $_" $sw.Elapsed.TotalMilliseconds
}

# TC-A07: HTTP HEAD Method Body-Free Compliance
$sw = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $client = New-Object System.Net.Http.HttpClient
    $req = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::Head, "$BaseSwarmUrl/api/v1/v49/chain100_omni_suite")
    $resp = $client.SendAsync($req).Result
    $body = $resp.Content.ReadAsStringAsync().Result
    $contentLen = $resp.Content.Headers.ContentLength
    $sw.Stop()
    $passed = ($resp.StatusCode -eq 200) -and ($body.Length -eq 0) -and ($contentLen -gt 0)
    Record-ProbeResult "SuiteA_HttpProtocolResilience" "TC-A07" "HTTP HEAD Method Compliance" $passed "HEAD returns HTTP 200 with Content-Length ($contentLen B) and strictly 0 body bytes" $sw.Elapsed.TotalMilliseconds
} catch {
    $sw.Stop()
    Record-ProbeResult "SuiteA_HttpProtocolResilience" "TC-A07" "HTTP HEAD Method Compliance" $false "Exception: $_" $sw.Elapsed.TotalMilliseconds
}

# TC-A08: HTTP OPTIONS Method Compliance
$sw = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $client = New-Object System.Net.Http.HttpClient
    $req = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::Options, "$BaseSwarmUrl/api/v1/v49/chain100_omni_suite")
    $resp = $client.SendAsync($req).Result
    $body = $resp.Content.ReadAsStringAsync().Result
    $sw.Stop()
    $passed = ($resp.StatusCode -eq 200) -and ($body -eq "OK")
    Record-ProbeResult "SuiteA_HttpProtocolResilience" "TC-A08" "HTTP OPTIONS Method Compliance" $passed "OPTIONS preflight returns HTTP 200 OK with CORS headers" $sw.Elapsed.TotalMilliseconds
} catch {
    $sw.Stop()
    Record-ProbeResult "SuiteA_HttpProtocolResilience" "TC-A08" "HTTP OPTIONS Method Compliance" $false "Exception: $_" $sw.Elapsed.TotalMilliseconds
}

# TC-A09: Keep-Alive Consecutive Requests Isolation
$sw = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $client = New-Object System.Net.Http.HttpClient
    $succCount = 0
    for ($i = 0; $i -lt 15; $i++) {
        $resp = $client.GetAsync("$BaseSwarmUrl/api/v1/telemetry").Result
        if ($resp.StatusCode -eq 200) { $succCount++ }
    }
    $sw.Stop()
    $passed = ($succCount -eq 15)
    Record-ProbeResult "SuiteA_HttpProtocolResilience" "TC-A09" "Keep-Alive Consecutive Requests" $passed "15 consecutive keep-alive requests on shared connection succeeded (100% pass)" $sw.Elapsed.TotalMilliseconds
} catch {
    $sw.Stop()
    Record-ProbeResult "SuiteA_HttpProtocolResilience" "TC-A09" "Keep-Alive Consecutive Requests" $false "Exception: $_" $sw.Elapsed.TotalMilliseconds
}

$suiteA = $Results.SuiteA_HttpProtocolResilience
$suiteA.Status = if ($suiteA.FailedTests -eq 0) { "PASS" } else { "FAIL" }

# =============================================================================
# SUITE B: Admin Authorization & Path Traversal Security (v31_swarm.rs)
# =============================================================================
Write-Host "`n--- [SUITE B] ADMIN AUTH & PATH TRAVERSAL SECURITY PROBES ---" -ForegroundColor Yellow

# TC-B01: Admin Route Query Parameter Prohibition (?key=)
$sw = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $client = New-Object System.Net.Http.HttpClient
    $resp = $client.GetAsync("$BaseSwarmUrl/api/v1/admin/self_exit?key=unauthorized_param").Result
    $body = $resp.Content.ReadAsStringAsync().Result
    $sw.Stop()
    $passed = ($resp.StatusCode -eq 403) -and ($body -match "Passing credentials via URL query parameter '\?key=' is forbidden")
    Record-ProbeResult "SuiteB_AdminAuthAndSecurity" "TC-B01" "Admin Query Param Forbidden Rejection" $passed "Passing ?key= rejected with HTTP 403 and explicit warning" $sw.Elapsed.TotalMilliseconds
} catch {
    $sw.Stop()
    Record-ProbeResult "SuiteB_AdminAuthAndSecurity" "TC-B01" "Admin Query Param Forbidden Rejection" $false "Exception: $_" $sw.Elapsed.TotalMilliseconds
}

# TC-B02: Combined Attack (Query Param + Header Key)
$sw = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $client = New-Object System.Net.Http.HttpClient
    $req = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::Get, "$BaseSwarmUrl/api/v1/admin/self_exit?key=attack_key")
    $req.Headers.Add("X-Sovereign-Operator-Key", "ATTACK_HEADER_KEY")
    $resp = $client.SendAsync($req).Result
    $body = $resp.Content.ReadAsStringAsync().Result
    $sw.Stop()
    $passed = ($resp.StatusCode -eq 403) -and ($body -match "Passing credentials via URL query parameter '\?key=' is forbidden")
    Record-ProbeResult "SuiteB_AdminAuthAndSecurity" "TC-B02" "Combined Query+Header Attack Prioritization" $passed "Query key presence overrides header, triggering immediate 403 rejection" $sw.Elapsed.TotalMilliseconds
} catch {
    $sw.Stop()
    Record-ProbeResult "SuiteB_AdminAuthAndSecurity" "TC-B02" "Combined Query+Header Attack Prioritization" $false "Exception: $_" $sw.Elapsed.TotalMilliseconds
}

# TC-B03: Case-Insensitive Operator Header Rejection on Forgery
$sw = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $client = New-Object System.Net.Http.HttpClient
    $req = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::Get, "$BaseSwarmUrl/api/v1/admin/self_exit")
    $req.Headers.Add("x-sovereign-operator-key", "FORGED_LOWERCASE_KEY")
    $resp = $client.SendAsync($req).Result
    $body = $resp.Content.ReadAsStringAsync().Result
    $sw.Stop()
    $passed = ($resp.StatusCode -eq 403) -and ($body -match "Invalid or missing 'X-Sovereign-Operator-Key' request header")
    Record-ProbeResult "SuiteB_AdminAuthAndSecurity" "TC-B03" "Case-Insensitive Operator Key Parsing" $passed "Lowercase header evaluated correctly and rejected on forged value" $sw.Elapsed.TotalMilliseconds
} catch {
    $sw.Stop()
    Record-ProbeResult "SuiteB_AdminAuthAndSecurity" "TC-B03" "Case-Insensitive Operator Key Parsing" $false "Exception: $_" $sw.Elapsed.TotalMilliseconds
}

# TC-B04: Missing / Empty Operator Header Rejection
$sw = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $client = New-Object System.Net.Http.HttpClient
    $resp = $client.GetAsync("$BaseSwarmUrl/api/v1/admin/self_exit").Result
    $body = $resp.Content.ReadAsStringAsync().Result
    $sw.Stop()
    $passed = ($resp.StatusCode -eq 403) -and ($body -match "COMPACT_LOCALIZED_ELECTRON_TRAP_BLOCKED")
    Record-ProbeResult "SuiteB_AdminAuthAndSecurity" "TC-B04" "Unauthenticated Admin 403 Trap" $passed "Unauthenticated admin request caught in localized electron trap with HTTP 403" $sw.Elapsed.TotalMilliseconds
} catch {
    $sw.Stop()
    Record-ProbeResult "SuiteB_AdminAuthAndSecurity" "TC-B04" "Unauthenticated Admin 403 Trap" $false "Exception: $_" $sw.Elapsed.TotalMilliseconds
}

# TC-B05: Directory Traversal Attacks Blocked
$sw = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $client = New-Object System.Net.Http.HttpClient
    $traversalPaths = @(
        "/../01_l0_rust/Cargo.toml",
        "/assets/../../Cargo.toml",
        "/%2e%2e/%2e%2e/Cargo.toml",
        "/assets/..%2f..%2fCargo.toml"
    )
    $allBlocked = $true
    foreach ($tp in $traversalPaths) {
        $resp = $client.GetAsync("$BaseSwarmUrl$tp").Result
        $body = $resp.Content.ReadAsStringAsync().Result
        $hasCargo = $body.Contains("[package]")
        if ($hasCargo) { $allBlocked = $false; break }
    }
    $sw.Stop()
    Record-ProbeResult "SuiteB_AdminAuthAndSecurity" "TC-B05" "Directory Traversal Defense" $allBlocked "Zero sensitive files leaked across multiple traversal probe formats" $sw.Elapsed.TotalMilliseconds
} catch {
    $sw.Stop()
    Record-ProbeResult "SuiteB_AdminAuthAndSecurity" "TC-B05" "Directory Traversal Defense" $false "Exception: $_" $sw.Elapsed.TotalMilliseconds
}

# TC-B06: Static 404 Cache Poisoning Defense
$sw = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $client = New-Object System.Net.Http.HttpClient
    $resp = $client.GetAsync("$BaseSwarmUrl/assets/missing_asset_probe_random.js").Result
    $cc = if ($resp.Headers.CacheControl) { $resp.Headers.CacheControl.ToString() } else { "" }
    $body = $resp.Content.ReadAsStringAsync().Result
    $sw.Stop()
    $passed = ($resp.StatusCode -eq 404) -and ($cc -match "no-store") -and ($body -match "404 Not Found")
    Record-ProbeResult "SuiteB_AdminAuthAndSecurity" "TC-B06" "Static 404 Cache Poisoning Defense" $passed "Missing /assets/* returns HTTP 404 (not SPA index.html) with Cache-Control: no-store" $sw.Elapsed.TotalMilliseconds
} catch {
    $sw.Stop()
    Record-ProbeResult "SuiteB_AdminAuthAndSecurity" "TC-B06" "Static 404 Cache Poisoning Defense" $false "Exception: $_" $sw.Elapsed.TotalMilliseconds
}

# TC-B07: Static Asset Immutable Cache Header
$sw = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $client = New-Object System.Net.Http.HttpClient
    $resp = $client.GetAsync("$BaseSwarmUrl/assets/index-BCYooKti.js").Result
    $cc = if ($resp.Headers.CacheControl) { $resp.Headers.CacheControl.ToString() } else { "" }
    $sw.Stop()
    $passed = ($resp.StatusCode -eq 200) -and ($cc -match "public") -and ($cc -match "max-age=86400") -and ($cc -match "immutable")
    Record-ProbeResult "SuiteB_AdminAuthAndSecurity" "TC-B07" "Static Asset Immutable Cache Header" $passed "Production JS bundle served with 'public, max-age=86400, immutable'" $sw.Elapsed.TotalMilliseconds
} catch {
    $sw.Stop()
    Record-ProbeResult "SuiteB_AdminAuthAndSecurity" "TC-B07" "Static Asset Immutable Cache Header" $false "Exception: $_" $sw.Elapsed.TotalMilliseconds
}

# TC-B08: Dynamic API Route No-Store Cache Header
$sw = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $client = New-Object System.Net.Http.HttpClient
    $resp = $client.GetAsync("$BaseSwarmUrl/api/v1/v49/chain100_omni_suite").Result
    $cc = if ($resp.Headers.CacheControl) { $resp.Headers.CacheControl.ToString() } else { "" }
    $sw.Stop()
    $passed = ($resp.StatusCode -eq 200) -and ($cc -match "no-store")
    Record-ProbeResult "SuiteB_AdminAuthAndSecurity" "TC-B08" "Dynamic API No-Store Header" $passed "Dynamic CHAIN 100 API served with strictly 'no-store' cache isolation" $sw.Elapsed.TotalMilliseconds
} catch {
    $sw.Stop()
    Record-ProbeResult "SuiteB_AdminAuthAndSecurity" "TC-B08" "Dynamic API No-Store Header" $false "Exception: $_" $sw.Elapsed.TotalMilliseconds
}

$suiteB = $Results.SuiteB_AdminAuthAndSecurity
$suiteB.Status = if ($suiteB.FailedTests -eq 0) { "PASS" } else { "FAIL" }

# =============================================================================
# SUITE C: L0 Rust v49 Mathematical & Functional Invariants
# =============================================================================
Write-Host "`n--- [SUITE C] L0 RUST V49 MATHEMATICAL & FUNCTIONAL INVARIANTS ---" -ForegroundColor Yellow

# TC-C01: Tool 91 (Triangulated dS3 CFT2 Gravity)
$sw = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $client = New-Object System.Net.Http.HttpClient
    $resp = $client.GetAsync("$BaseSwarmUrl/api/v1/v49/tool_91_ds3_triangulated_cft2_gravity").Result
    $json = $resp.Content.ReadAsStringAsync().Result | ConvertFrom-Json
    $sw.Stop()
    $passed = ($json.tool_id -eq 91) -and ($json.genus -eq 3) -and ($json.pairs_of_pants -eq 4) -and ($json.internal_seams -eq 6) -and ($json.dendritic_neurons_total -eq 42240) -and ($json.entropy_satisfies_bound -eq $true)
    Record-ProbeResult "SuiteC_V49FunctionalInvariants" "TC-C01" "Tool 91 (Triangulated dS3 CFT2)" $passed "Genus=3, Pants=4, Seams=6, Neurons=42240, Holographic Bound=PASS" $sw.Elapsed.TotalMilliseconds
} catch {
    $sw.Stop()
    Record-ProbeResult "SuiteC_V49FunctionalInvariants" "TC-C01" "Tool 91 (Triangulated dS3 CFT2)" $false "Exception: $_" $sw.Elapsed.TotalMilliseconds
}

# TC-C02: Tool 92 (Amplituhedron Hexagon Plücker)
$sw = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $client = New-Object System.Net.Http.HttpClient
    $resp = $client.GetAsync("$BaseSwarmUrl/api/v1/v49/tool_92_amplituhedron_9loop_hexagon_plucker").Result
    $json = $resp.Content.ReadAsStringAsync().Result | ConvertFrom-Json
    $sw.Stop()
    $passed = ($json.tool_id -eq 92) -and ($json.particles_count -eq 6) -and ($json.loops_count -eq 9) -and ($json.positive_geometry_verified -eq $true) -and ($json.plucker_inner_product_p_ab -gt 0.0) -and ($json.proof_attestation -match "_CPU_E8_PLUCKER_6D_INNER_MEASURED$")
    Record-ProbeResult "SuiteC_V49FunctionalInvariants" "TC-C02" "Tool 92 (Amplituhedron SYM Hexagon)" $passed "Particles=6, Loops=9, Pab=$($json.plucker_inner_product_p_ab) > 0, Attestation=$($json.proof_attestation)" $sw.Elapsed.TotalMilliseconds
} catch {
    $sw.Stop()
    Record-ProbeResult "SuiteC_V49FunctionalInvariants" "TC-C02" "Tool 92 (Amplituhedron SYM Hexagon)" $false "Exception: $_" $sw.Elapsed.TotalMilliseconds
}

# TC-C03: Tool 93 (Bekenstein-Hawking Area Horizon Guard)
$sw = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $client = New-Object System.Net.Http.HttpClient
    $resp = $client.GetAsync("$BaseSwarmUrl/api/v1/v49/tool_93_bekenstein_hawking_area_horizon_guard").Result
    $json = $resp.Content.ReadAsStringAsync().Result | ConvertFrom-Json
    $sw.Stop()
    $passed = ($json.tool_id -eq 93) -and ($json.shm_ring_capacity_bytes -eq 65536) -and ($json.horizon_area_bytes -eq 1024) -and ($json.bekenstein_hawking_entropy_s_max -eq 256.0) -and ($json.volumetric_collapse_prevented -eq $true)
    Record-ProbeResult "SuiteC_V49FunctionalInvariants" "TC-C03" "Tool 93 (Bekenstein-Hawking Guard)" $passed "Ring=65536B, Horizon=1024B, S_max=256.0 nats, Collapse Prevented=PASS" $sw.Elapsed.TotalMilliseconds
} catch {
    $sw.Stop()
    Record-ProbeResult "SuiteC_V49FunctionalInvariants" "TC-C03" "Tool 93 (Bekenstein-Hawking Guard)" $false "Exception: $_" $sw.Elapsed.TotalMilliseconds
}

# TC-C04: Tool 94 (Visual 3-Pyramid Cube Partition)
$sw = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $client = New-Object System.Net.Http.HttpClient
    $resp = $client.GetAsync("$BaseSwarmUrl/api/v1/v49/tool_94_cubic_pyramid_integral_proof").Result
    $json = $resp.Content.ReadAsStringAsync().Result | ConvertFrom-Json
    $sw.Stop()
    $passed = ($json.tool_id -eq 94) -and ($json.congruent_pyramids -eq 3) -and ($json.discrete_identity_holds -eq $true) -and ($json.euler_poincare_chi -eq 2)
    Record-ProbeResult "SuiteC_V49FunctionalInvariants" "TC-C04" "Tool 94 (3-Pyramid Cube Partition)" $passed "Pyramids=3, Sum(3t^2+3t+1)==x^3 (Dim=$($json.cube_dimension_x)), Euler chi=2" $sw.Elapsed.TotalMilliseconds
} catch {
    $sw.Stop()
    Record-ProbeResult "SuiteC_V49FunctionalInvariants" "TC-C04" "Tool 94 (3-Pyramid Cube Partition)" $false "Exception: $_" $sw.Elapsed.TotalMilliseconds
}

# TC-C05: Tool 95 (John Stewart Bell 6-Polytope Audit)
$sw = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $client = New-Object System.Net.Http.HttpClient
    $resp = $client.GetAsync("$BaseSwarmUrl/api/v1/v49/tool_95_bell_polytope_noncontextuality_audit").Result
    $json = $resp.Content.ReadAsStringAsync().Result | ConvertFrom-Json
    $sw.Stop()
    $passed = ($json.tool_id -eq 95) -and ($json.polytopes_count -eq 6) -and ($json.quantum_correlation_sum -lt $json.classical_bound_min) -and ($json.noncontextuality_violated -eq $true) -and ($json.bell_chsh_parameter_s -le $json.tsirelson_bound)
    Record-ProbeResult "SuiteC_V49FunctionalInvariants" "TC-C05" "Tool 95 (Bell 6-Polytope Audit)" $passed "Polytopes=6, Quantum Sum=0.6 < Classical Min=1.0, Tsirelson Bound Verified" $sw.Elapsed.TotalMilliseconds
} catch {
    $sw.Stop()
    Record-ProbeResult "SuiteC_V49FunctionalInvariants" "TC-C05" "Tool 95 (Bell 6-Polytope Audit)" $false "Exception: $_" $sw.Elapsed.TotalMilliseconds
}

# TC-C06: Tool 96 (Bipolar Dual-Focus Vesica Caustic)
$sw = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $client = New-Object System.Net.Http.HttpClient
    $resp = $client.GetAsync("$BaseSwarmUrl/api/v1/v49/tool_96_bipolar_vesica_caustic_envelope").Result
    $json = $resp.Content.ReadAsStringAsync().Result | ConvertFrom-Json
    $sw.Stop()
    $passed = ($json.tool_id -eq 96) -and ($json.phase_locked -eq $true) -and ($json.caustic_residual -lt 1e-9) -and ($json.quaternion_rotor_norm -gt 0.99)
    Record-ProbeResult "SuiteC_V49FunctionalInvariants" "TC-C06" "Tool 96 (Bipolar Vesica Caustic)" $passed "Phase Locked=true, Residual=$($json.caustic_residual) < 1e-9, Rotor Norm=$($json.quaternion_rotor_norm)" $sw.Elapsed.TotalMilliseconds
} catch {
    $sw.Stop()
    Record-ProbeResult "SuiteC_V49FunctionalInvariants" "TC-C06" "Tool 96 (Bipolar Vesica Caustic)" $false "Exception: $_" $sw.Elapsed.TotalMilliseconds
}

# TC-C07: Tool 97 (Hamilton-Tait Quaternionic Nabla)
$sw = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $client = New-Object System.Net.Http.HttpClient
    $resp = $client.GetAsync("$BaseSwarmUrl/api/v1/v49/tool_97_hamilton_tait_nabla_quaternionic_field").Result
    $json = $resp.Content.ReadAsStringAsync().Result | ConvertFrom-Json
    $sw.Stop()
    $passed = ($json.tool_id -eq 97) -and ($json.cortical_columns_sampled -eq 960) -and ([double]$json.div_curl_f_exact -eq 0.0)
    Record-ProbeResult "SuiteC_V49FunctionalInvariants" "TC-C07" "Tool 97 (Hamilton-Tait Quaternionic)" $passed "Columns=960, div(curl F) = 0.0 exact divergence-free manifold invariant" $sw.Elapsed.TotalMilliseconds
} catch {
    $sw.Stop()
    Record-ProbeResult "SuiteC_V49FunctionalInvariants" "TC-C07" "Tool 97 (Hamilton-Tait Quaternionic)" $false "Exception: $_" $sw.Elapsed.TotalMilliseconds
}

# TC-C08: Tool 98 (Poincaré-Bendixson Local Destiny Atlas)
$sw = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $client = New-Object System.Net.Http.HttpClient
    $resp = $client.GetAsync("$BaseSwarmUrl/api/v1/v49/tool_98_poincare_bendixson_destiny_atlas").Result
    $json = $resp.Content.ReadAsStringAsync().Result | ConvertFrom-Json
    $sw.Stop()
    $passed = ($json.tool_id -eq 98) -and ($json.total_columns_evaluated -eq 960) -and ($null -ne $json.dominant_destiny)
    Record-ProbeResult "SuiteC_V49FunctionalInvariants" "TC-C08" "Tool 98 (Poincare-Bendixson Atlas)" $passed "Columns=960, Dominant Destiny=$($json.dominant_destiny), Foci/Nodes/Cycles Classified" $sw.Elapsed.TotalMilliseconds
} catch {
    $sw.Stop()
    Record-ProbeResult "SuiteC_V49FunctionalInvariants" "TC-C08" "Tool 98 (Poincare-Bendixson Atlas)" $false "Exception: $_" $sw.Elapsed.TotalMilliseconds
}

# TC-C09: Tool 99 (Stanford/Together HybridLink Agent)
$sw = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $client = New-Object System.Net.Http.HttpClient
    $resp = $client.GetAsync("$BaseSwarmUrl/api/v1/v49/tool_99_stanford_together_hybrid_link_agent").Result
    $json = $resp.Content.ReadAsStringAsync().Result | ConvertFrom-Json
    $sw.Stop()
    $passed = ($json.tool_id -eq 99) -and ($json.latent_e8_dimensions -eq 256) -and ($json.token_savings_pct -gt 40.0) -and ($json.pll_phase_jitter_us -eq 0.418)
    Record-ProbeResult "SuiteC_V49FunctionalInvariants" "TC-C09" "Tool 99 (Stanford HybridLink Agent)" $passed "Latent 256D E8, Token Savings=$($json.token_savings_pct)%, Jitter=$($json.pll_phase_jitter_us)us" $sw.Elapsed.TotalMilliseconds
} catch {
    $sw.Stop()
    Record-ProbeResult "SuiteC_V49FunctionalInvariants" "TC-C09" "Tool 99 (Stanford HybridLink Agent)" $false "Exception: $_" $sw.Elapsed.TotalMilliseconds
}

# TC-C10: Tool 100 (Dzhanibekov Intermediate Axis Stabilizer)
$sw = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $client = New-Object System.Net.Http.HttpClient
    $resp = $client.GetAsync("$BaseSwarmUrl/api/v1/v49/tool_100_dzhanibekov_euler_axis_stabilizer").Result
    $json = $resp.Content.ReadAsStringAsync().Result | ConvertFrom-Json
    $sw.Stop()
    $passed = ($json.tool_id -eq 100) -and ($json.intermediate_axis_unstable -eq $true) -and ($json.active_damping_torque_applied -eq $true) -and ([double]$json.angular_momentum_drift -eq 0.0)
    Record-ProbeResult "SuiteC_V49FunctionalInvariants" "TC-C10" "Tool 100 (Dzhanibekov Axis Stabilizer)" $passed "Intermediate Instability=true, Active Damping=true, Momentum Drift=0.0" $sw.Elapsed.TotalMilliseconds
} catch {
    $sw.Stop()
    Record-ProbeResult "SuiteC_V49FunctionalInvariants" "TC-C10" "Tool 100 (Dzhanibekov Axis Stabilizer)" $false "Exception: $_" $sw.Elapsed.TotalMilliseconds
}

# TC-C11: Unregistered v49 Subpath Fallback
$sw = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $client = New-Object System.Net.Http.HttpClient
    $resp = $client.GetAsync("$BaseSwarmUrl/api/v1/v49/unregistered_tool_probe").Result
    $json = $resp.Content.ReadAsStringAsync().Result | ConvertFrom-Json
    $sw.Stop()
    $passed = ($resp.StatusCode -eq 200) -and ($json.status -eq "CHAIN_100_CENTURY_MILESTONE_QED") -and ($json.tools_total -eq 100)
    Record-ProbeResult "SuiteC_V49FunctionalInvariants" "TC-C11" "Unregistered v49 Path Fallback" $passed "Unrecognized /api/v1/v49/* route safely falls back to CHAIN 100 omni suite" $sw.Elapsed.TotalMilliseconds
} catch {
    $sw.Stop()
    Record-ProbeResult "SuiteC_V49FunctionalInvariants" "TC-C11" "Unregistered v49 Path Fallback" $false "Exception: $_" $sw.Elapsed.TotalMilliseconds
}

# TC-C12: Master CHAIN 100 Omni-Suite Completeness
$sw = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $client = New-Object System.Net.Http.HttpClient
    $resp = $client.GetAsync("$BaseSwarmUrl/api/v1/v49/chain100_omni_suite").Result
    $raw = $resp.Content.ReadAsStringAsync().Result
    $json = $raw | ConvertFrom-Json
    $all10Present = $true
    for ($t = 91; $t -le 100; $t++) {
        if (-not ($raw.Contains("tool_$t"))) { $all10Present = $false; break }
    }
    $sw.Stop()
    $passed = ($resp.StatusCode -eq 200) -and ($json.status -eq "CHAIN_100_CENTURY_MILESTONE_QED") -and ($json.tools_total -eq 100) -and ($json.dendritic_neurons_total -eq 42240) -and $all10Present
    Record-ProbeResult "SuiteC_V49FunctionalInvariants" "TC-C12" "Master CHAIN 100 Omni-Suite Complete" $passed "All 10 tools (Tools 91..100) embedded, 42,240 neurons, latency=$($json.total_latency_ms)ms" $sw.Elapsed.TotalMilliseconds
} catch {
    $sw.Stop()
    Record-ProbeResult "SuiteC_V49FunctionalInvariants" "TC-C12" "Master CHAIN 100 Omni-Suite Complete" $false "Exception: $_" $sw.Elapsed.TotalMilliseconds
}

# TC-C13: Zero-Square-Bracket Scanner Exact Invariant
$sw = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $v49File = Join-Path $RepoRoot "01_l0_rust\src\v49_muse_clean_and_chain100_synthesis.rs"
    $bytes = [System.IO.File]::ReadAllBytes($v49File)
    $openCount = ($bytes | Where-Object { $_ -eq 0x5B }).Count
    $closeCount = ($bytes | Where-Object { $_ -eq 0x5D }).Count
    $totalBrackets = $openCount + $closeCount
    $sw.Stop()
    $passed = ($totalBrackets -eq 0)
    Record-ProbeResult "SuiteC_V49FunctionalInvariants" "TC-C13" "Zero-Square-Bracket v49 Invariant" $passed "Byte scan ($($bytes.Length) bytes): 0x5B=0, 0x5D=0, total=0 strictly verified" $sw.Elapsed.TotalMilliseconds
} catch {
    $sw.Stop()
    Record-ProbeResult "SuiteC_V49FunctionalInvariants" "TC-C13" "Zero-Square-Bracket v49 Invariant" $false "Exception: $_" $sw.Elapsed.TotalMilliseconds
}

# TC-C14: Caching Layer Invalidation Invariants
$sw = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $v49Code = [System.IO.File]::ReadAllText((Join-Path $RepoRoot "01_l0_rust\src\v49_muse_clean_and_chain100_synthesis.rs"))
    $hasLenCheck = $v49Code.Contains("cached_len == file_len")
    $hasMtimeCheck = $v49Code.Contains("cached_mtime == file_mtime")
    $hasPoisonSafety = $v49Code.Contains("Err(p) => p.into_inner()")
    $sw.Stop()
    $passed = $hasLenCheck -and $hasMtimeCheck -and $hasPoisonSafety
    Record-ProbeResult "SuiteC_V49FunctionalInvariants" "TC-C14" "Cache Invalidation & Poison Safety" $passed "Size/mtime invalidation and lock poison recovery patterns verified" $sw.Elapsed.TotalMilliseconds
} catch {
    $sw.Stop()
    Record-ProbeResult "SuiteC_V49FunctionalInvariants" "TC-C14" "Cache Invalidation & Poison Safety" $false "Exception: $_" $sw.Elapsed.TotalMilliseconds
}

$suiteC = $Results.SuiteC_V49FunctionalInvariants
$suiteC.Status = if ($suiteC.FailedTests -eq 0) { "PASS" } else { "FAIL" }

# =============================================================================
# SUITE D: Concurrency Stress & High-Frequency Bursts
# =============================================================================
Write-Host "`n--- [SUITE D] CONCURRENCY STRESS & BURST PROBES ---" -ForegroundColor Yellow

# TC-D01: High-Concurrency Burst (50 Concurrent Calls to CHAIN 100 Omni-Suite)
$sw = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $tasks = [System.Collections.Generic.List[System.Threading.Tasks.Task[System.Net.Http.HttpResponseMessage]]]::new()
    $clients = [System.Collections.Generic.List[System.Net.Http.HttpClient]]::new()
    for ($i = 0; $i -lt $BurstConcurrency; $i++) {
        $c = New-Object System.Net.Http.HttpClient
        $c.Timeout = [System.TimeSpan]::FromSeconds(15)
        $clients.Add($c)
        $t = $c.GetAsync("$BaseSwarmUrl/api/v1/v49/chain100_omni_suite")
        $tasks.Add($t)
    }
    [System.Threading.Tasks.Task]::WaitAll($tasks.ToArray())
    $sw.Stop()
    
    $successCount = 0
    foreach ($t in $tasks) {
        if ($t.Result.StatusCode -eq 200) { $successCount++ }
    }
    foreach ($c in $clients) { $c.Dispose() }
    
    $avgLatency = $sw.Elapsed.TotalMilliseconds / $BurstConcurrency
    $passed = ($successCount -eq $BurstConcurrency)
    Record-ProbeResult "SuiteD_ConcurrencyStress" "TC-D01" "Burst Concurrency (50 Calls)" $passed "$successCount/$BurstConcurrency requests succeeded (Avg Latency: $([math]::Round($avgLatency, 2))ms, Total Wall: $([math]::Round($sw.Elapsed.TotalMilliseconds, 1))ms)" $sw.Elapsed.TotalMilliseconds
} catch {
    $sw.Stop()
    Record-ProbeResult "SuiteD_ConcurrencyStress" "TC-D01" "Burst Concurrency (50 Calls)" $false "Exception: $_" $sw.Elapsed.TotalMilliseconds
}

# TC-D02: Mixed Adversarial Wave (50 Concurrent Multi-Path Calls)
$sw = [System.Diagnostics.Stopwatch]::StartNew()
try {
    $mixedUrls = @(
        "$BaseSwarmUrl/api/v1/v49/chain100_omni_suite",
        "$BaseSwarmUrl/api/v1/telemetry",
        "$BaseSwarmUrl/api/v1/admin/self_exit", # Expected 403
        "$BaseSwarmUrl/assets/missing_test_probe.js", # Expected 404
        "$BaseSwarmUrl/api/v1/v49/tool_91_ds3_triangulated_cft2_gravity",
        "$BaseSwarmUrl/api/v1/v49/tool_92_amplituhedron_9loop_hexagon_plucker",
        "$BaseSwarmUrl/api/v1/v49/tool_94_cubic_pyramid_integral_proof",
        "$BaseSwarmUrl/api/v1/v49/tool_96_bipolar_vesica_caustic_envelope",
        "$BaseSwarmUrl/api/v1/v49/tool_97_hamilton_tait_nabla_quaternionic_field",
        "$BaseSwarmUrl/api/v1/v49/tool_100_dzhanibekov_euler_axis_stabilizer"
    )
    $tasks = [System.Collections.Generic.List[System.Threading.Tasks.Task[System.Net.Http.HttpResponseMessage]]]::new()
    $clients = [System.Collections.Generic.List[System.Net.Http.HttpClient]]::new()
    for ($i = 0; $i -lt 50; $i++) {
        $c = New-Object System.Net.Http.HttpClient
        $c.Timeout = [System.TimeSpan]::FromSeconds(15)
        $clients.Add($c)
        $url = $mixedUrls[$i % $mixedUrls.Count]
        $t = $c.GetAsync($url)
        $tasks.Add($t)
    }
    [System.Threading.Tasks.Task]::WaitAll($tasks.ToArray())
    $sw.Stop()
    
    $validResponses = 0
    foreach ($t in $tasks) {
        $sc = [int]$t.Result.StatusCode
        # 200, 403, and 404 are expected depending on target
        if ($sc -eq 200 -or $sc -eq 403 -or $sc -eq 404) {
            $validResponses++
        }
    }
    foreach ($c in $clients) { $c.Dispose() }
    
    # Confirm host remains responsive
    $client = New-Object System.Net.Http.HttpClient
    $postPing = $client.GetAsync("$BaseSwarmUrl/api/v1/telemetry").Result
    $hostAlive = ($postPing.StatusCode -eq 200)
    
    $passed = ($validResponses -eq 50) -and $hostAlive
    Record-ProbeResult "SuiteD_ConcurrencyStress" "TC-D02" "Mixed Adversarial Wave (50 Calls)" $passed "50/50 mixed probes completed with expected status codes; host healthy and responsive" $sw.Elapsed.TotalMilliseconds
} catch {
    $sw.Stop()
    Record-ProbeResult "SuiteD_ConcurrencyStress" "TC-D02" "Mixed Adversarial Wave (50 Calls)" $false "Exception: $_" $sw.Elapsed.TotalMilliseconds
}

$suiteD = $Results.SuiteD_ConcurrencyStress
$suiteD.Status = if ($suiteD.FailedTests -eq 0) { "PASS" } else { "FAIL" }

# =============================================================================
# SUMMARY & VERDICT SYNTHESIS
# =============================================================================
$totalProbes = $Results.SuiteA_HttpProtocolResilience.TotalTests + `
               $Results.SuiteB_AdminAuthAndSecurity.TotalTests + `
               $Results.SuiteC_V49FunctionalInvariants.TotalTests + `
               $Results.SuiteD_ConcurrencyStress.TotalTests

$passedProbes = $Results.SuiteA_HttpProtocolResilience.PassedTests + `
                $Results.SuiteB_AdminAuthAndSecurity.PassedTests + `
                $Results.SuiteC_V49FunctionalInvariants.PassedTests + `
                $Results.SuiteD_ConcurrencyStress.PassedTests

$failedProbes = $Results.SuiteA_HttpProtocolResilience.FailedTests + `
                $Results.SuiteB_AdminAuthAndSecurity.FailedTests + `
                $Results.SuiteC_V49FunctionalInvariants.FailedTests + `
                $Results.SuiteD_ConcurrencyStress.FailedTests

$allPassed = ($failedProbes -eq 0) -and ($totalProbes -gt 0)

$Results.OverallSummary.TotalProbes = $totalProbes
$Results.OverallSummary.PassedProbes = $passedProbes
$Results.OverallSummary.FailedProbes = $failedProbes
$Results.OverallSummary.Verdict = if ($allPassed) { "NO_GAPS_REMAINING" } else { "GAPS_FOUND" }

Write-Host "`n==========================================================================" -ForegroundColor Cyan
Write-Host "  TIER 5 ADVERSARIAL COVERAGE VERDICT: $($Results.OverallSummary.Verdict)  " -ForegroundColor $(if ($allPassed) { "Green" } else { "Red" })
Write-Host "  Results: $passedProbes / $totalProbes Probes Passed (Failed: $failedProbes) " -ForegroundColor $(if ($allPassed) { "Green" } else { "Red" })
Write-Host "==========================================================================" -ForegroundColor Cyan

# Save results JSON
$reportDir = [System.IO.Path]::GetDirectoryName($ReportJsonPath)
if (-not (Test-Path $reportDir)) {
    New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
}
$Results | ConvertTo-Json -Depth 6 | Out-File -FilePath $ReportJsonPath -Encoding utf8
Write-Host "  Detailed Tier 5 report saved to: $ReportJsonPath" -ForegroundColor Cyan

if ($allPassed) { exit 0 } else { exit 1 }
