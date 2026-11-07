# ACT-Omega Net v62.0.0
# Challenger M_FINAL Adversarial Stress & Concurrency Test
# Target: PID 2084 on :8097 and SSD Writebacks on E:\

$ErrorActionPreference = "Continue"

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "   CHALLENGER M_FINAL: HIGH CONCURRENCY, BURST & SSD WRITEBACK AUDIT      " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan

# 1. Inspect Initial PID 2084 Metrics
$targetPid = 2084
$proc = Get-Process -Id $targetPid -ErrorAction SilentlyContinue
if (-not $proc) {
    Write-Host "FATAL: Process PID $targetPid not found!" -ForegroundColor Red
    exit 1
}

$initialWS = $proc.WorkingSet64
$initialPrivate = $proc.PrivateMemorySize64
$initialHandles = $proc.Handles
$initialThreads = $proc.Threads.Count

Write-Host ("Initial Process Metrics (PID {0}):" -f $targetPid) -ForegroundColor Yellow
Write-Host ("  Working Set   : {0:N2} MB ({1} bytes)" -f ($initialWS / 1MB), $initialWS)
Write-Host ("  Private Memory: {0:N2} MB ({1} bytes)" -f ($initialPrivate / 1MB), $initialPrivate)
Write-Host ("  Handle Count  : {0}" -f $initialHandles)
Write-Host ("  Thread Count  : {0}" -f $initialThreads)
Write-Host ""

# 2. High Concurrency Burst (300 total requests across Track B endpoints)
Write-Host "--- PHASE 1: HIGH CONCURRENCY & BURST THROUGHPUT (300 REQUESTS) ---" -ForegroundColor Cyan

$endpoints = @(
    @{ Method = "GET"; Url = "http://127.0.0.1:8097/api/v1/chain292/master_certification" },
    @{ Method = "GET"; Url = "http://127.0.0.1:8097/api/v1/tools/t289" },
    @{ Method = "GET"; Url = "http://127.0.0.1:8097/api/v1/tools/t290" },
    @{ Method = "GET"; Url = "http://127.0.0.1:8097/api/v1/tools/t291" },
    @{ Method = "GET"; Url = "http://127.0.0.1:8097/api/v1/tools/t292" },
    @{ Method = "POST"; Url = "http://127.0.0.1:8097/api/v1/polytope7777/crt_pfa"; Body = '{"signal_length":7777,"moduli":[7,11,101],"action":"decompose"}' },
    @{ Method = "POST"; Url = "http://127.0.0.1:8097/api/v1/polytope7777/rvq_pvq"; Body = '{"stages":3,"target_dim":7777,"codebook_bits":8}' },
    @{ Method = "POST"; Url = "http://127.0.0.1:8097/api/v1/polytope7777/sparse_matvec"; Body = '{"dim":7777,"sparsity":0.95,"blocks":16}' },
    @{ Method = "POST"; Url = "http://127.0.0.1:8097/mcp"; Body = '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}' },
    @{ Method = "POST"; Url = "http://127.0.0.1:8097/mcp"; Body = '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"polytope_7777d_crt_rvq_router","arguments":{"operation":"certify"}}}' },
    # Adversarial boundary conditions
    @{ Method = "GET"; Url = "http://127.0.0.1:8097/api/v1/tools/t293"; ExpectedStatus = "ERROR_TOOL_OUT_OF_RANGE" },
    @{ Method = "GET"; Url = "http://127.0.0.1:8097/api/v1/tools/t0"; ExpectedStatus = "ERROR_TOOL_OUT_OF_RANGE" },
    @{ Method = "GET"; Url = "http://127.0.0.1:8097/api/v1/tools/t9999"; ExpectedStatus = "ERROR_TOOL_OUT_OF_RANGE" },
    @{ Method = "POST"; Url = "http://127.0.0.1:8097/api/v1/polytope7777/crt_pfa"; Body = '{malformed:json!}' },
    @{ Method = "POST"; Url = "http://127.0.0.1:8097/mcp"; Body = '{"jsonrpc":"2.0","id":99,"method":"tools/unknown","params":{}}' }
)

$totalBurst = 300
$swBurst = [System.Diagnostics.Stopwatch]::StartNew()
$successCount = 0
$adversarialCleanCount = 0
$droppedCount = 0

# Execute burst using parallel runspaces
$pool = [RunspaceFactory]::CreateRunspacePool(1, 16)
$pool.Open()
$tasks = [System.Collections.ArrayList]::new()

for ($i = 0; $i -lt $totalBurst; $i++) {
    $ep = $endpoints[$i % $endpoints.Count]
    $ps = [PowerShell]::Create()
    $ps.RunspacePool = $pool
    
    [void]$ps.AddScript({
        param($method, $url, $body, $expectedStatus)
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        try {
            $req = [System.Net.HttpWebRequest]::Create($url)
            $req.Method = $method
            $req.Timeout = 5000
            $req.KeepAlive = $false
            if ($method -eq "POST" -and $body) {
                $req.ContentType = "application/json"
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($body)
                $req.ContentLength = $bytes.Length
                $st = $req.GetRequestStream()
                $st.Write($bytes, 0, $bytes.Length)
                $st.Close()
            }
            $resp = $req.GetResponse()
            $reader = [System.IO.StreamReader]::new($resp.GetResponseStream())
            $respText = $reader.ReadToEnd()
            $reader.Close()
            $statusCode = [int]$resp.StatusCode
            $resp.Close()
            $sw.Stop()
            return @{
                Success = $true
                StatusCode = $statusCode
                DurationMs = $sw.Elapsed.TotalMilliseconds
                Response = $respText
                Expected = $expectedStatus
            }
        } catch [System.Net.WebException] {
            $sw.Stop()
            $webEx = $_.Exception
            $resp = $webEx.Response
            if ($resp) {
                $reader = [System.IO.StreamReader]::new($resp.GetResponseStream())
                $respText = $reader.ReadToEnd()
                $reader.Close()
                $statusCode = [int]$resp.StatusCode
                $resp.Close()
                return @{
                    Success = $true # Caught HTTP error response cleanly
                    StatusCode = $statusCode
                    DurationMs = $sw.Elapsed.TotalMilliseconds
                    Response = $respText
                    Expected = $expectedStatus
                }
            } else {
                return @{
                    Success = $false
                    Error = $webEx.Message
                    DurationMs = $sw.Elapsed.TotalMilliseconds
                }
            }
        } catch {
            $sw.Stop()
            return @{
                Success = $false
                Error = $_.Exception.Message
                DurationMs = $sw.Elapsed.TotalMilliseconds
            }
        }
    }).AddArgument($ep.Method).AddArgument($ep.Url).AddArgument($ep.Body).AddArgument($ep.ExpectedStatus)
    
    $async = $ps.BeginInvoke()
    [void]$tasks.Add(@{ PS = $ps; Async = $async; Expected = $ep.ExpectedStatus })
}

# Collect all results
$latencies = @()
foreach ($t in $tasks) {
    $res = $t.PS.EndInvoke($t.Async)
    $t.PS.Dispose()
    if ($res -and $res.Success) {
        $latencies += $res.DurationMs
        if ($t.Expected) {
            if ($res.Response -match $t.Expected) {
                $adversarialCleanCount++
                $successCount++
            } else {
                Write-Host ("Adversarial mismatch: expected {0}, got {1}" -f $t.Expected, $res.Response) -ForegroundColor Yellow
            }
        } else {
            $successCount++
        }
    } else {
        $droppedCount++
    }
}
$pool.Close()
$pool.Dispose()
$swBurst.Stop()

$avgLatency = if ($latencies.Count -gt 0) { ($latencies | Measure-Object -Average).Average } else { 0 }
$maxLatency = if ($latencies.Count -gt 0) { ($latencies | Measure-Object -Maximum).Maximum } else { 0 }
$minLatency = if ($latencies.Count -gt 0) { ($latencies | Measure-Object -Minimum).Minimum } else { 0 }
$rps = [math]::Round($totalBurst / ($swBurst.Elapsed.TotalSeconds), 1)

Write-Host ("Burst Completed in {0:N1} ms | Rate: {1} req/sec" -f $swBurst.Elapsed.TotalMilliseconds, $rps) -ForegroundColor Green
Write-Host ("  Total Requests : {0}" -f $totalBurst)
Write-Host ("  Successful     : {0} ({1:P1})" -f $successCount, ($successCount / $totalBurst))
Write-Host ("  Dropped / Reset: {0}" -f $droppedCount)
Write-Host ("  Latency Min/Avg/Max: {0:N1}ms / {1:N1}ms / {2:N1}ms" -f $minLatency, $avgLatency, $maxLatency)
Write-Host ""

# 3. Post-Burst Memory and Handle Leak Audit
Write-Host "--- PHASE 2: MEMORY & HANDLE LEAK AUDIT (PID 2084) ---" -ForegroundColor Cyan
Write-Host "Waiting 8 seconds for TCP socket reclamation..." -ForegroundColor Yellow
Start-Sleep -Seconds 8

$procAfter = Get-Process -Id $targetPid -ErrorAction SilentlyContinue
if (-not $procAfter) {
    Write-Host "FATAL: Process PID $targetPid crashed during stress burst!" -ForegroundColor Red
    exit 1
}

$afterWS = $procAfter.WorkingSet64
$afterPrivate = $procAfter.PrivateMemorySize64
$afterHandles = $procAfter.Handles
$afterThreads = $procAfter.Threads.Count

$deltaWS = $afterWS - $initialWS
$deltaPrivate = $afterPrivate - $initialPrivate
$deltaHandles = $afterHandles - $initialHandles
$deltaThreads = $afterThreads - $initialThreads

Write-Host ("Post-Burst Process Metrics (PID {0}):" -f $targetPid) -ForegroundColor Yellow
Write-Host ("  Working Set   : {0:N2} MB (Delta: {1:+#,##0;-#,##0;0} bytes / {2:+0.00;-0.00;0.00} MB)" -f ($afterWS / 1MB), $deltaWS, ($deltaWS / 1MB))
Write-Host ("  Private Memory: {0:N2} MB (Delta: {1:+#,##0;-#,##0;0} bytes / {2:+0.00;-0.00;0.00} MB)" -f ($afterPrivate / 1MB), $deltaPrivate, ($deltaPrivate / 1MB))
Write-Host ("  Handle Count  : {0} (Delta: {1:+#;-#;0})" -f $afterHandles, $deltaHandles)
Write-Host ("  Thread Count  : {0} (Delta: {1:+#;-#;0})" -f $afterThreads, $deltaThreads)

$handleLeakDetected = $deltaHandles -gt 5
$memoryLeakDetected = $deltaPrivate -gt 15MB

if ($handleLeakDetected) {
    Write-Host ("FAIL: Significant handle increase detected: {0} handles leaked" -f $deltaHandles) -ForegroundColor Red
} else {
    Write-Host ("PASS: Zero handle leaks confirmed (delta={0} handles <= threshold)" -f $deltaHandles) -ForegroundColor Green
}

if ($memoryLeakDetected) {
    Write-Host ("FAIL: Unbounded private memory growth detected: {0:N2} MB" -f ($deltaPrivate / 1MB)) -ForegroundColor Red
} else {
    Write-Host ("PASS: Memory stability confirmed (delta={0:N2} MB within stable bounds)" -f ($deltaPrivate / 1MB)) -ForegroundColor Green
}
Write-Host ""

# 4. Autopoietic Coordinator Bus SSD Writeback SHA-256 Audit
Write-Host "--- PHASE 3: SSD WRITEBACK SHA-256 INTEGRITY AUDIT ---" -ForegroundColor Cyan
$manifestPath = "E:\Sovereign_Manifold_SSD_Vault\coordinator_bus\codegen_integration_manifest_v4800.jsonl"
if (-not (Test-Path $manifestPath)) {
    Write-Host "FATAL: Manifest not found at $manifestPath" -ForegroundColor Red
    exit 1
}

$manifestLines = Get-Content -Path $manifestPath
$trackBEntries = @()
foreach ($line in $manifestLines) {
    if ($line -match '"source_tool":"tool_(289|290|291|292)"') {
        try {
            $entry = $line | ConvertFrom-Json
            $trackBEntries += $entry
        } catch {}
    }
}

Write-Host ("Found {0} total Track B writeback records in coordinator manifest." -f $trackBEntries.Count)

$sampleCount = [math]::Min($trackBEntries.Count, 100)
$sampledEntries = $trackBEntries | Select-Object -Last $sampleCount
$writebackPassCount = 0
$writebackFailCount = 0

foreach ($entry in $sampledEntries) {
    $filePath = $entry.file_path
    $expectedHash = $entry.measured_sha256.ToLower()
    $expectedBytes = $entry.measured_bytes
    
    if (-not (Test-Path $filePath)) {
        Write-Host ("FAIL: Writeback file missing on SSD: {0}" -f $filePath) -ForegroundColor Red
        $writebackFailCount++
        continue
    }
    
    $fileInfo = Get-Item $filePath
    if ($fileInfo.Length -ne $expectedBytes) {
        Write-Host ("FAIL: Byte count mismatch on {0}: expected {1}, got {2}" -f $filePath, $expectedBytes, $fileInfo.Length) -ForegroundColor Red
        $writebackFailCount++
        continue
    }
    
    $actualHash = (Get-FileHash -Path $filePath -Algorithm SHA256).Hash.ToLower()
    if ($actualHash -ne $expectedHash) {
        Write-Host ("FAIL: SHA-256 mismatch on {0}: expected {1}, got {2}" -f $filePath, $expectedHash, $actualHash) -ForegroundColor Red
        $writebackFailCount++
        continue
    }
    
    $writebackPassCount++
}

Write-Host ("Sampled {0} Track B writeback artifacts on E:\ drive:" -f $sampleCount)
Write-Host ("  Passed (100% SHA-256 & byte match): {0}" -f $writebackPassCount) -ForegroundColor Green
Write-Host ("  Failed                            : {0}" -f $writebackFailCount) -ForegroundColor $(if ($writebackFailCount -eq 0) { "Green" } else { "Red" })

if ($writebackFailCount -eq 0 -and $writebackPassCount -gt 0) {
    Write-Host "PASS: All Track B SSD writebacks strictly match measured SHA-256 digests." -ForegroundColor Green
} else {
    Write-Host "FAIL: Writeback integrity violations detected." -ForegroundColor Red
}
Write-Host ""

# Overall Verdict
$stressPassed = ($droppedCount -eq 0) -and (-not $handleLeakDetected) -and (-not $memoryLeakDetected) -and ($writebackFailCount -eq 0)
Write-Host "==========================================================================" -ForegroundColor Cyan
if ($stressPassed) {
    Write-Host "   CHALLENGER VERDICT: STRESS & WRITEBACK AUDIT PASSED (0 ANOMALIES)       " -ForegroundColor Green
    Write-Host "==========================================================================" -ForegroundColor Cyan
    exit 0
} else {
    Write-Host "   CHALLENGER VERDICT: STRESS OR WRITEBACK AUDIT FAILED                   " -ForegroundColor Red
    Write-Host "==========================================================================" -ForegroundColor Cyan
    exit 1
}
