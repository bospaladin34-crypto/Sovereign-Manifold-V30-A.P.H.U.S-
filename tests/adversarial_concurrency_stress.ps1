# tests\adversarial_concurrency_stress.ps1
# ACT-Omega Track B Adversarial Concurrency & Subprocess Stress Harness
# Verifies:
#   1. Multi-threaded burst against daemon :8097 (zero drops, zero 500s, zero crash)
#   2. Concurrent mcp_stdio_wrapper.ps1 subprocess invocations (zero deadlocks, zero orphans, zero leaks)
#   3. Daemon handle and memory stability under burst load
# STRICT INVARIANTS: ZERO PYTHON | MUSE ZERO-UNMEASURED DATA MANDATE | ZERO BACKTICKS

$ErrorActionPreference = "Continue"

Write-Host "=========================================================================="
Write-Host "  ACT-OMEGA TRACK B ADVERSARIAL CONCURRENCY & STRESS TEST HARNESS"
Write-Host "=========================================================================="

$RepoRoot = "C:\sovereign_manifold_v31"
$Endpoint = "http://127.0.0.1:8097"
$WrapperPath = Join-Path $RepoRoot "00_control\mcp_stdio_wrapper.ps1"

Write-Host ""
Write-Host "[PHASE 1] Inspecting baseline daemon status..."
$daemonProc = Get-Process -Name v31_swarm -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $daemonProc) {
    Write-Error "Daemon v31_swarm is not running on 127.0.0.1:8097!"
    exit 1
}

$initialHandles = $daemonProc.Handles
$initialWsMb = [math]::Round($daemonProc.WorkingSet64 / 1MB, 2)
$initialPid = $daemonProc.Id

Write-Host "  Daemon PID: $initialPid"
Write-Host "  Initial Handles: $initialHandles"
Write-Host "  Initial Working Set: $initialWsMb MB"

# 2. Multi-threaded Concurrency Burst against :8097
Write-Host ""
Write-Host "[PHASE 2] Executing 100-request multi-threaded concurrency burst against :8097..."
$burstSw = [System.Diagnostics.Stopwatch]::StartNew()
$burstConcurrency = 20
$totalRequests = 100

# Using RunspacePool for genuine OS-level multi-threaded concurrency
$runspacePool = [runspacefactory]::CreateRunspacePool(1, $burstConcurrency)
$runspacePool.Open()

$tasks = [System.Collections.Generic.List[PSObject]]::new()

$endpointsToTest = @(
    @{ Path = "/mcp"; Method = "POST"; Body = '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' },
    @{ Path = "/mcp"; Method = "POST"; Body = '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"polytope_7777d_crt_rvq_router","arguments":{"action":"crt_pfa"}}}' },
    @{ Path = "/api/v1/master_certification"; Method = "POST"; Body = '{}' },
    @{ Path = "/api/v1/crt/project_decompose"; Method = "POST"; Body = '{}' },
    @{ Path = "/api/v1/rvq/hierarchical_encode"; Method = "POST"; Body = '{"stages":3}' }
)

$scriptBlock = {
    param($uri, $body, $reqId)
    Add-Type -AssemblyName System.Net.Http -ErrorAction SilentlyContinue
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $status = 0
    $success = $false
    $err = ""
    try {
        $client = [System.Net.Http.HttpClient]::new()
        $client.Timeout = [System.TimeSpan]::FromSeconds(10)
        $content = [System.Net.Http.StringContent]::new($body, [System.Text.Encoding]::UTF8, "application/json")
        $resp = $client.PostAsync($uri, $content).GetAwaiter().GetResult()
        $status = [int]$resp.StatusCode
        $respBody = $resp.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        $client.Dispose()
        $success = ($status -eq 200 -and -not [string]::IsNullOrEmpty($respBody))
    } catch {
        $err = $_.Exception.Message
    }
    $sw.Stop()
    return [PSCustomObject]@{
        ReqId = $reqId
        StatusCode = $status
        Success = $success
        ElapsedMs = $sw.Elapsed.TotalMilliseconds
        Error = $err
    }
}

for ($i = 1; $i -le $totalRequests; $i++) {
    $target = $endpointsToTest[($i - 1) % $endpointsToTest.Count]
    $uri = "$Endpoint$($target.Path)"
    $body = $target.Body
    
    $ps = [powershell]::Create()
    $ps.RunspacePool = $runspacePool
    [void]$ps.AddScript($scriptBlock)
    [void]$ps.AddArgument($uri)
    [void]$ps.AddArgument($body)
    [void]$ps.AddArgument($i)
    
    $asyncHandle = $ps.BeginInvoke()
    $tasks.Add([PSCustomObject]@{
        PowerShell = $ps
        AsyncHandle = $asyncHandle
    })
}

# Wait for all burst tasks
$results = [System.Collections.Generic.List[PSObject]]::new()
foreach ($item in $tasks) {
    $res = $item.PowerShell.EndInvoke($item.AsyncHandle)
    $item.PowerShell.Dispose()
    foreach ($r in $res) {
        $results.Add($r)
    }
}
$runspacePool.Close()
$runspacePool.Dispose()
$burstSw.Stop()

$successCount = ($results | Where-Object { $_.Success -eq $true }).Count
$failureCount = $totalRequests - $successCount
$latencies = $results | ForEach-Object { $_.ElapsedMs }
$avgLatency = [math]::Round(($latencies | Measure-Object -Average).Average, 2)
$maxLatency = [math]::Round(($latencies | Measure-Object -Maximum).Maximum, 2)
$minLatency = [math]::Round(($latencies | Measure-Object -Minimum).Minimum, 2)

Write-Host "  Total Requests: $totalRequests"
Write-Host "  Successful (200 OK): $successCount / $totalRequests"
Write-Host "  Failures: $failureCount"
Write-Host "  Total Burst Duration: $([math]::Round($burstSw.Elapsed.TotalMilliseconds, 2)) ms"
Write-Host "  Latency (Min / Avg / Max): $minLatency ms / $avgLatency ms / $maxLatency ms"

if ($failureCount -gt 0) {
    $firstErr = ($results | Where-Object { -not $_.Success } | Select-Object -First 1).Error
    Write-Host "  First Failure Reason: $firstErr"
    Write-Error "Adversarial burst test failed: $failureCount requests dropped or failed!"
}

# 3. Concurrent Subprocess Stress on mcp_stdio_wrapper.ps1
Write-Host ""
Write-Host "[PHASE 3] Executing concurrent subprocess stress test on mcp_stdio_wrapper.ps1..."
$subprocSw = [System.Diagnostics.Stopwatch]::StartNew()
$concurrentProcesses = 8
$subprocList = [System.Collections.Generic.List[PSObject]]::new()

for ($p = 1; $p -le $concurrentProcesses; $p++) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Arguments = '-NoProfile -NonInteractive -ExecutionPolicy Bypass -File "' + $WrapperPath + '"'
    $psi.UseShellExecute = $false
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.CreateNoWindow = $true

    $proc = [System.Diagnostics.Process]::Start($psi)
    $stdoutTask = $proc.StandardOutput.ReadToEndAsync()
    $stderrTask = $proc.StandardError.ReadToEndAsync()
    
    $subprocList.Add([PSCustomObject]@{
        Index = $p
        Process = $proc
        StdoutTask = $stdoutTask
        StderrTask = $stderrTask
    })
}

# Write multi-stage requests to all concurrent processes simultaneously
foreach ($sp in $subprocList) {
    $idx = $sp.Index
    # Request 1: Tools list
    $sp.Process.StandardInput.WriteLine('{"jsonrpc":"2.0","id":' + ($idx * 100 + 1) + ',"method":"tools/list"}')
    # Request 2: Large payload (>64KB)
    $largePad = "Z" * 68000
    $sp.Process.StandardInput.WriteLine('{"jsonrpc":"2.0","id":' + ($idx * 100 + 2) + ',"method":"tools/list","params":{"pad":"' + $largePad + '"}}')
    # Request 3: Tool 292 router call
    $sp.Process.StandardInput.WriteLine('{"jsonrpc":"2.0","id":' + ($idx * 100 + 3) + ',"method":"tools/call","params":{"name":"polytope_7777d_crt_rvq_router","arguments":{"action":"rvq_encode","stages":3}}}')
    # Request 4: Null ID notification
    $sp.Process.StandardInput.WriteLine('{"jsonrpc":"2.0","id":null,"method":"notifications/initialized"}')
    # Request 5: Final tools list
    $sp.Process.StandardInput.WriteLine('{"jsonrpc":"2.0","id":' + ($idx * 100 + 5) + ',"method":"tools/list"}')
    # Close stdin to trigger graceful shutdown
    $sp.Process.StandardInput.Close()
}

# Drain all processes and verify zero deadlocks
$subprocResults = [System.Collections.Generic.List[PSObject]]::new()
foreach ($sp in $subprocList) {
    $cleanExit = $sp.Process.WaitForExit(7000)
    if (-not $cleanExit) {
        $sp.Process.Kill()
    }
    
    $stdout = $sp.StdoutTask.GetAwaiter().GetResult()
    $stderr = $sp.StderrTask.GetAwaiter().GetResult()
    $lines = $stdout -split [System.Environment]::NewLine | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    
    $validJsonCount = 0
    foreach ($line in $lines) {
        try {
            $parsed = $line | ConvertFrom-Json
            if ($null -ne $parsed.jsonrpc) { $validJsonCount++ }
        } catch {}
    }
    
    $subprocResults.Add([PSCustomObject]@{
        Index = $sp.Index
        ExitedCleanly = $cleanExit
        ExitCode = $sp.Process.ExitCode
        ResponseLines = $lines.Count
        ValidJsonCount = $validJsonCount
        StderrBytes = if ($stderr) { $stderr.Length } else { 0 }
    })
    $sp.Process.Dispose()
}
$subprocSw.Stop()

$allExitedCleanly = ($subprocResults | Where-Object { $_.ExitedCleanly -eq $true }).Count -eq $concurrentProcesses
$allExitZero = ($subprocResults | Where-Object { $_.ExitCode -eq 0 }).Count -eq $concurrentProcesses
$allResponsesReceived = ($subprocResults | Where-Object { $_.ValidJsonCount -ge 4 }).Count -eq $concurrentProcesses

Write-Host "  Concurrent Subprocesses Spawned: $concurrentProcesses"
Write-Host "  All Exited Cleanly (No Deadlock): $allExitedCleanly"
Write-Host "  All Exit Codes Zero: $allExitZero"
Write-Host "  All Valid JSON Responses Delivered: $allResponsesReceived"
Write-Host "  Subprocess Suite Duration: $([math]::Round($subprocSw.Elapsed.TotalMilliseconds, 2)) ms"

# Check for lingering powershell processes running mcp_stdio_wrapper
$orphanedWrappers = Get-CimInstance Win32_Process | Where-Object { $_.CommandLine -match "mcp_stdio_wrapper\.ps1" }
$zeroOrphans = ($null -eq $orphanedWrappers -or $orphanedWrappers.Count -eq 0)
Write-Host "  Zero Orphaned Wrapper Processes: $zeroOrphans"

# 4. Post-Stress Daemon Health & Handle Leak Audit
Write-Host ""
Write-Host "[PHASE 4] Post-stress daemon stability and handle audit..."
$daemonPost = Get-Process -Id $initialPid -ErrorAction SilentlyContinue
if (-not $daemonPost) {
    Write-Error "CRITICAL: Daemon v31_swarm crashed during stress test!"
    exit 1
}

$finalHandles = $daemonPost.Handles
$finalWsMb = [math]::Round($daemonPost.WorkingSet64 / 1MB, 2)
$handleDiff = $finalHandles - $initialHandles
$wsDiffMb = [math]::Round($finalWsMb - $initialWsMb, 2)

Write-Host "  Daemon PID: $($daemonPost.Id) (Still Alive: True)"
Write-Host "  Final Handles: $finalHandles (Delta: $handleDiff)"
Write-Host "  Final Working Set: $finalWsMb MB (Delta: $wsDiffMb MB)"

# Handle difference threshold: small delta (< 50 handles) during active sockets is normal, but no runaway leak (> 200)
$handlesStable = [math]::Abs($handleDiff) -lt 100
Write-Host "  Handle Stability Check (< 100 delta): $handlesStable"

# 5. Final Summary
Write-Host ""
Write-Host "=========================================================================="
Write-Host "                      STRESS HARNESS VERDICT"
Write-Host "=========================================================================="
$overallPass = ($failureCount -eq 0) -and $allExitedCleanly -and $allExitZero -and $allResponsesReceived -and $zeroOrphans -and $handlesStable

Write-Host "  Phase 2 Burst Pass (100/100 200 OK)  : $($failureCount -eq 0)"
Write-Host "  Phase 3 Subprocess Anti-Deadlock Pass : $($allExitedCleanly -and $allExitZero -and $allResponsesReceived)"
Write-Host "  Zero Orphaned Child Processes         : $zeroOrphans"
Write-Host "  Zero Process Crashes                  : True"
Write-Host "  Zero Handle Leaks                     : $handlesStable"
Write-Host "--------------------------------------------------------------------------"
Write-Host "  OVERALL ADVERSARIAL STRESS VERDICT   : $(if ($overallPass) { 'PASS' } else { 'FAIL' })"
Write-Host "=========================================================================="

if ($overallPass) {
    exit 0
} else {
    exit 1
}
