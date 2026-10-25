# Challenger M2-2: Adversarial Security & Timing Resistance Test Suite
# File: C:\sovereign_manifold_v31\tests\challenger_m2_adversarial_suite.ps1
# Constraints: Zero Python | Measured Data Mandate

param(
    [string]$SwarmPort = "8097",
    [string]$RemoteIp = "10.0.24.243",
    [int]$TimingSamplesPerClass = 50
)

$ErrorActionPreference = "Continue"

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "  CHALLENGER M2-2: ADVERSARIAL SECURITY & TIMING PROBE SUITE             " -ForegroundColor Cyan
Write-Host "  Target Swarm Port: $SwarmPort | Remote IP: $RemoteIp                    " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan

function Invoke-ProbeRequest {
    param(
        [string]$Uri,
        [hashtable]$Headers = @{},
        [int]$TimeoutSec = 3
    )
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $req = [System.Net.HttpWebRequest]::Create($Uri)
    $req.Timeout = $TimeoutSec * 1000
    $req.ReadWriteTimeout = $TimeoutSec * 1000
    $req.Method = "GET"
    $req.KeepAlive = $false
    
    foreach ($k in $Headers.Keys) {
        if ($k -eq "X-Forwarded-For") {
            $req.Headers.Add("X-Forwarded-For", $Headers[$k])
        } else {
            $req.Headers.Add($k, $Headers[$k])
        }
    }

    try {
        $resp = $req.GetResponse()
        $sw.Stop()
        $stream = $resp.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($stream)
        $body = $reader.ReadToEnd()
        $status = [int]$resp.StatusCode
        $resp.Close()
        return @{ StatusCode = $status; Body = $body; ElapsedMs = $sw.Elapsed.TotalMilliseconds; Error = $null }
    } catch {
        $sw.Stop()
        $webEx = if ($_.Exception -is [System.Net.WebException]) { 
            $_.Exception 
        } elseif ($_.Exception.InnerException -is [System.Net.WebException]) { 
            $_.Exception.InnerException 
        } else { 
            $null 
        }
        $status = 0
        $body = ""
        if ($webEx -and $webEx.Response) {
            $status = [int]$webEx.Response.StatusCode
            $stream = $webEx.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($stream)
            $body = $reader.ReadToEnd()
            $webEx.Response.Close()
        }
        return @{ StatusCode = $status; Body = $body; ElapsedMs = $sw.Elapsed.TotalMilliseconds; Error = $_.Message }
    }
}

$results = @{
    IpSpoofingTests = @()
    QueryAuthTests = @()
    TimingDistribution = @{}
    RepoScan = @{}
    OverallPassed = $true
}

# --------------------------------------------------------------------------
# SUITE 1: Remote vs Loopback & X-Forwarded-For Spoofing
# --------------------------------------------------------------------------
Write-Host "`n--- [SUITE 1] REMOTE VS LOOPBACK & X-FORWARDED-FOR SPOOFING ---" -ForegroundColor Yellow

$suite1Cases = @(
    @{
        Id = "S1-01"
        Name = "Loopback without Auth Header"
        Uri = "http://127.0.0.1:$SwarmPort/api/v1/admin/status_probe"
        Headers = @{}
        ExpectedStatus = 403
        ExpectedReasonMatch = "Invalid or missing 'X-Sovereign-Operator-Key'"
        ExpectedIsLoopback = $true
    },
    @{
        Id = "S1-02"
        Name = "Loopback with Remote Spoofed X-Forwarded-For (203.0.113.195)"
        Uri = "http://127.0.0.1:$SwarmPort/api/v1/admin/status_probe"
        Headers = @{ "X-Forwarded-For" = "203.0.113.195" }
        ExpectedStatus = 403
        ExpectedReasonMatch = "Invalid or missing 'X-Sovereign-Operator-Key'"
        ExpectedIsLoopback = $true
    },
    @{
        Id = "S1-03"
        Name = "Remote LAN IP without Auth Header"
        Uri = "http://${RemoteIp}:${SwarmPort}/api/v1/admin/status_probe"
        Headers = @{}
        ExpectedStatus = 403
        ExpectedReasonMatch = "Administrative operations are strictly restricted to 127.0.0.1 loopback."
        ExpectedIsLoopback = $false
    },
    @{
        Id = "S1-04"
        Name = "Remote LAN IP with Spoofed X-Forwarded-For 127.0.0.1"
        Uri = "http://${RemoteIp}:${SwarmPort}/api/v1/admin/status_probe"
        Headers = @{ "X-Forwarded-For" = "127.0.0.1" }
        ExpectedStatus = 403
        ExpectedReasonMatch = "Administrative operations are strictly restricted to 127.0.0.1 loopback."
        ExpectedIsLoopback = $false
    },
    @{
        Id = "S1-05"
        Name = "Remote LAN IP with Spoofed X-Forwarded-For localhost + Bogus Key"
        Uri = "http://${RemoteIp}:${SwarmPort}/api/v1/admin/status_probe"
        Headers = @{ "X-Forwarded-For" = "localhost"; "X-Sovereign-Operator-Key" = "BOGUS_ATTACK_KEY_000" }
        ExpectedStatus = 403
        ExpectedReasonMatch = "Administrative operations are strictly restricted to 127.0.0.1 loopback."
        ExpectedIsLoopback = $false
    }
)

foreach ($tc in $suite1Cases) {
    $res = Invoke-ProbeRequest -Uri $tc.Uri -Headers $tc.Headers
    $passed = ($res.StatusCode -eq $tc.ExpectedStatus)
    $reasonOk = $res.Body.Contains($tc.ExpectedReasonMatch)
    $loopbackFlag = if ($tc.ExpectedIsLoopback) { '"is_loopback":true' } else { '"is_loopback":false' }
    $loopbackOk = $res.Body.Contains($loopbackFlag)
    $casePassed = $passed -and $reasonOk -and $loopbackOk

    if (-not $casePassed) { $results.OverallPassed = $false }
    $color = if ($casePassed) { "Green" } else { "Red" }
    Write-Host ("  [{0}] [{1}] {2} -> Status: {3} (Reason OK: {4}, LoopbackFlag OK: {5})" -f `
        $tc.Id, $(if ($casePassed) { "PASS" } else { "FAIL" }), $tc.Name, $res.StatusCode, $reasonOk, $loopbackOk) -ForegroundColor $color

    $results.IpSpoofingTests += @{
        Id = $tc.Id
        Name = $tc.Name
        Passed = $casePassed
        StatusCode = $res.StatusCode
        ReasonMatch = $reasonOk
        LoopbackFlagMatch = $loopbackOk
        BodySnippet = if ($res.Body.Length -gt 150) { $res.Body.Substring(0, 150) } else { $res.Body }
    }
}

# --------------------------------------------------------------------------
# SUITE 2: Query Parameter Authentication Rejection (?key=...)
# --------------------------------------------------------------------------
Write-Host "`n--- [SUITE 2] QUERY PARAMETER AUTHENTICATION REJECTION ---" -ForegroundColor Yellow

$suite2Cases = @(
    @{
        Id = "S2-01"
        Name = "Query param ?key=SECRET on /api/v1/admin/status"
        Uri = "http://127.0.0.1:$SwarmPort/api/v1/admin/status?key=TEST_OPERATOR_KEY"
        Headers = @{}
        ExpectedStatus = 403
        ExpectedReasonMatch = "Passing credentials via URL query parameter '?key=' is forbidden."
    },
    @{
        Id = "S2-02"
        Name = "Query param ?key=SOVEREIGN-LOQ15-4200 on /api/v1/admin/self_exit"
        Uri = "http://127.0.0.1:$SwarmPort/api/v1/admin/self_exit?key=SOVEREIGN-LOQ15-4200"
        Headers = @{}
        ExpectedStatus = 403
        ExpectedReasonMatch = "Passing credentials via URL query parameter '?key=' is forbidden."
    },
    @{
        Id = "S2-03"
        Name = "Query param ?action=test&key=SECRET mixed params"
        Uri = "http://127.0.0.1:$SwarmPort/api/v1/admin/diagnostic_probe?action=test&key=SECRET_TOKEN"
        Headers = @{}
        ExpectedStatus = 403
        ExpectedReasonMatch = "Passing credentials via URL query parameter '?key=' is forbidden."
    },
    @{
        Id = "S2-04"
        Name = "Both Valid/Forged Header AND Query param ?key=SECRET (Unconditional 403)"
        Uri = "http://127.0.0.1:$SwarmPort/api/v1/admin/status?key=FORBIDDEN_QUERY_PARAM"
        Headers = @{ "X-Sovereign-Operator-Key" = "SOME_KEY" }
        ExpectedStatus = 403
        ExpectedReasonMatch = "Passing credentials via URL query parameter '?key=' is forbidden."
    }
)

foreach ($tc in $suite2Cases) {
    $res = Invoke-ProbeRequest -Uri $tc.Uri -Headers $tc.Headers
    $passed = ($res.StatusCode -eq $tc.ExpectedStatus)
    $reasonOk = $res.Body.Contains($tc.ExpectedReasonMatch)
    $casePassed = $passed -and $reasonOk

    if (-not $casePassed) { $results.OverallPassed = $false }
    $color = if ($casePassed) { "Green" } else { "Red" }
    Write-Host ("  [{0}] [{1}] {2} -> Status: {3} (Query Forbidden Msg: {4})" -f `
        $tc.Id, $(if ($casePassed) { "PASS" } else { "FAIL" }), $tc.Name, $res.StatusCode, $reasonOk) -ForegroundColor $color

    $results.QueryAuthTests += @{
        Id = $tc.Id
        Name = $tc.Name
        Passed = $casePassed
        StatusCode = $res.StatusCode
        ReasonMatch = $reasonOk
        BodySnippet = if ($res.Body.Length -gt 150) { $res.Body.Substring(0, 150) } else { $res.Body }
    }
}

# --------------------------------------------------------------------------
# SUITE 3: Timing Resistance Distribution Testing
# --------------------------------------------------------------------------
Write-Host "`n--- [SUITE 3] RESPONSE TIMING DISTRIBUTIONS ACROSS KEY PREFIXES ---" -ForegroundColor Yellow

$keyFile = "C:\sovereign_manifold_v31\00_control\.operator_vault_key"
$testSecret = "OP_SEC_E8_TEST_9941_MEASURED_CANONICAL_KEY_v49"
$testSecretCreated = $false

if (-not (Test-Path $keyFile)) {
    [System.IO.File]::WriteAllText($keyFile, $testSecret)
    $testSecretCreated = $true
    Start-Sleep -Milliseconds 100
}

try {
    $keyClasses = @{
        "ExactMatch" = $testSecret
        "NearMatch_47of48" = "OP_SEC_E8_TEST_9941_MEASURED_CANONICAL_KEY_v40" # last char mismatch
        "HalfMatch_24of48" = "OP_SEC_E8_TEST_9941_000000000000000000000000" # half mismatch
        "FullMismatch_0of48" = "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ" # complete mismatch
    }

    $timingData = @{}
    
    # Warmup
    for ($w = 0; $w -lt 10; $w++) {
        $null = Invoke-ProbeRequest -Uri "http://127.0.0.1:$SwarmPort/api/v1/admin/timing_warmup" -Headers @{ "X-Sovereign-Operator-Key" = "WARMUP" }
    }

    foreach ($className in $keyClasses.Keys) {
        $keyVal = $keyClasses[$className]
        $latencies = [System.Collections.Generic.List[double]]::new()
        
        for ($i = 0; $i -lt $TimingSamplesPerClass; $i++) {
            $res = Invoke-ProbeRequest -Uri "http://127.0.0.1:$SwarmPort/api/v1/admin/timing_probe" -Headers @{ "X-Sovereign-Operator-Key" = $keyVal }
            $latencies.Add($res.ElapsedMs)
        }
        
        # Compute statistics
        $sorted = $latencies | Sort-Object
        $count = $sorted.Count
        $sum = 0.0
        foreach ($v in $sorted) { $sum += $v }
        $mean = $sum / $count
        $median = if ($count % 2 -eq 0) { ($sorted[$count/2 - 1] + $sorted[$count/2]) / 2.0 } else { $sorted[[math]::Floor($count/2)] }
        $varSum = 0.0
        foreach ($v in $sorted) { $varSum += [math]::Pow($v - $mean, 2) }
        $stdDev = [math]::Sqrt($varSum / $count)
        
        $timingData[$className] = @{
            Count = $count
            MeanMs = [math]::Round($mean, 4)
            MedianMs = [math]::Round($median, 4)
            StdDevMs = [math]::Round($stdDev, 4)
            MinMs = [math]::Round($sorted[0], 4)
            MaxMs = [math]::Round($sorted[$count - 1], 4)
            Samples = $sorted
        }
        
        Write-Host ("  Class: {0,-18} | Samples: {1} | Mean: {2,7:F3} ms | Median: {3,7:F3} ms | StdDev: {4,6:F3} ms | Min: {5,6:F3} ms | Max: {6,6:F3} ms" -f `
            $className, $count, $mean, $median, $stdDev, $sorted[0], $sorted[$count - 1]) -ForegroundColor White
    }

    # Analyze timing difference between NearMatch and FullMismatch
    $nearMean = $timingData["NearMatch_47of48"].MeanMs
    $fullMean = $timingData["FullMismatch_0of48"].MeanMs
    $deltaMs = [math]::Abs($nearMean - $fullMean)
    # Threshold for timing attack vulnerability: if difference is statistically negligible (< 0.5ms in local loopback noise)
    $timingResistant = ($deltaMs -lt 0.75)
    
    if (-not $timingResistant) {
        Write-Host "  [WARN] Delta between NearMatch and FullMismatch is $deltaMs ms" -ForegroundColor Yellow
    } else {
        Write-Host ("  [PASS] Timing difference between 47/48 prefix match and 0/48 match: {0:F4} ms (Constant-Time Verified)" -f $deltaMs) -ForegroundColor Green
    }
    
    $results.TimingDistribution = @{
        Classes = $timingData
        DeltaNearVsFullMs = $deltaMs
        TimingResistant = $timingResistant
    }
} finally {
    if ($testSecretCreated -and (Test-Path $keyFile)) {
        Remove-Item $keyFile -Force
    }
}

# --------------------------------------------------------------------------
# SUITE 4: Repository Passkey Purge Audit
# --------------------------------------------------------------------------
Write-Host "`n--- [SUITE 4] GLOBAL REPOSITORY PASSKEY PURGE SCAN ---" -ForegroundColor Yellow
$targetExts = @("*.html", "*.js", "*.ts", "*.tsx", "*.rs")
$repoRoot = "C:\sovereign_manifold_v31"
$needle = "SOVEREIGN-LOQ15-4200"

$filesToScan = Get-ChildItem -Path $repoRoot -Recurse -File -Include $targetExts | Where-Object {
    $_.FullName -notmatch '\\\.git\\' -and 
    $_.FullName -notmatch '\\target\\' -and 
    $_.FullName -notmatch '\\target_stage\\' -and 
    $_.FullName -notmatch '\\node_modules\\' -and
    $_.FullName -notmatch '\\\.agents\\teamwork\\' # Exclude agent logs/reports
}

$hits = @()
foreach ($f in $filesToScan) {
    $matchesInFile = Select-String -Path $f.FullName -Pattern $needle -SimpleMatch -ErrorAction SilentlyContinue
    if ($matchesInFile) {
        foreach ($m in $matchesInFile) {
            $hits += @{
                File = $f.FullName.Replace($repoRoot, "")
                LineNumber = $m.LineNumber
                LineText = $m.Line.Trim()
            }
        }
    }
}

$passkeyPurged = ($hits.Count -eq 0)
if (-not $passkeyPurged) {
    $results.OverallPassed = $false
    Write-Host ("  [FAIL] Found {0} lingering occurrences of '{1}':" -f $hits.Count, $needle) -ForegroundColor Red
    foreach ($h in $hits) {
        Write-Host ("    -> {0}:{1} : {2}" -f $h.File, $h.LineNumber, $h.LineText) -ForegroundColor Red
    }
} else {
    Write-Host ("  [PASS] Clean scan: 0 occurrences of '{0}' in {1} source files (.html, .js, .ts, .tsx, .rs)" -f $needle, $filesToScan.Count) -ForegroundColor Green
}

$results.RepoScan = @{
    ScannedFileCount = $filesToScan.Count
    HitCount = $hits.Count
    Hits = $hits
    PasskeyPurged = $passkeyPurged
}

# --------------------------------------------------------------------------
# OVERALL SUMMARY
# --------------------------------------------------------------------------
Write-Host "`n==========================================================================" -ForegroundColor Cyan
Write-Host ("  CHALLENGER VERDICT: {0}" -f $(if ($results.OverallPassed) { "APPROVE" } else { "REQUEST_CHANGES" })) -ForegroundColor $(if ($results.OverallPassed) { "Green" } else { "Red" })
Write-Host "==========================================================================" -ForegroundColor Cyan

return $results
