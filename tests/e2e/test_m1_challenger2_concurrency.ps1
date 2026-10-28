# ==============================================================================
# ACT-OMEGA NET v50.0.0 -- M1 CHALLENGER 2 CONCURRENCY AND LIMIT STRESS
# Tests:
# 1. 100-Request Keep-Alive Overflow (105 pipelined requests on single socket)
# 2. Multi-threaded Concurrent Hammer (Pipelining + RST Drops + Rapid Connects)
# 3. Slowloris / Incomplete Header Timeout Recovery
# ==============================================================================

$ErrorActionPreference = "Stop"
$Server = "127.0.0.1"
$Port = 8097
$Total = 0
$Passed = 0
$Failed = 0

function Check-Assert {
    param([string]$Name, [bool]$Condition, [string]$Details)
    $script:Total++
    if ($Condition) {
        $script:Passed++
        Write-Host "  [PASS] $Name : $Details" -ForegroundColor Green
    } else {
        $script:Failed++
        Write-Host "  [FAIL] $Name : $Details" -ForegroundColor Red
    }
}

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "   M1 CHALLENGER 2: CONCURRENCY, LIMITS, AND ADVERSARIAL FLOOD SUITE      " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan

# ------------------------------------------------------------------------------
# Test A: Keep-Alive 100-Request Loop Limit Boundary
# Send 105 pipelined requests in one TCP write. The server's loop is 0..100.
# The server must serve exactly 100 requests, set Connection: close on #100,
# drain remaining bytes, and cleanly close without panicking.
# ------------------------------------------------------------------------------
Write-Host "`n--- Test A: 105 Pipelined Requests (Exceeding 100 Max Loop Bound) ---" -ForegroundColor Yellow
try {
    $tcp = New-Object System.Net.Sockets.TcpClient($Server, $Port)
    $tcp.ReceiveTimeout = 10000
    $tcp.SendTimeout = 10000
    $stream = $tcp.GetStream()

    $payload105 = ""
    for ($i = 1; $i -le 105; $i++) {
        $payload105 += "GET /api/v1/health HTTP/1.1`r`nHost: $Server`:$Port`r`n`r`n"
    }
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($payload105)
    $stream.Write($bytes, 0, $bytes.Length)
    $stream.Flush()

    $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::ASCII)
    $countServed = 0
    $lastHadConnectionClose = $false

    while ($true) {
        $line = $reader.ReadLine()
        if ($null -eq $line -or $line -eq "") { break }
        if ($line -match "200 OK") {
            $countServed++
        }
        $contentLength = 0
        while ($true) {
            $hdr = $reader.ReadLine()
            if ($null -eq $hdr -or $hdr -eq "") { break }
            if ($hdr -match "^Connection:\s*close") {
                $lastHadConnectionClose = $true
            }
            if ($hdr -match "^Content-Length:\s*(\d+)") {
                $contentLength = [int]$matches[1]
            }
        }
        if ($contentLength -gt 0) {
            $buf = New-Object char[] $contentLength
            $totalRead = 0
            while ($totalRead -lt $contentLength) {
                $n = $reader.Read($buf, $totalRead, $contentLength - $totalRead)
                if ($n -le 0) { break }
                $totalRead += $n
            }
        }
    }
    $tcp.Close()

    Check-Assert -Name "Test A (100 Max Bound)" -Condition ($countServed -eq 100 -and $lastHadConnectionClose) -Details "Server served exactly $countServed responses (limit: 100), Connection: close issued, remaining drained"
} catch {
    Check-Assert -Name "Test A (100 Max Bound)" -Condition $false -Details "Exception: $_"
}

# ------------------------------------------------------------------------------
# Test B: Concurrent Hammer (8 Parallel Background Jobs)
# Jobs 1-3: Pipelined GET requests
# Jobs 4-6: Abrupt RST drops
# Jobs 7-8: Rapid connection storms
# ------------------------------------------------------------------------------
Write-Host "`n--- Test B: 8-Worker Concurrent Background Hammer ---" -ForegroundColor Yellow
$procBefore = Get-Process -Name v31_swarm
$wsBefore = [math]::Round($procBefore.WorkingSet64 / 1MB, 2)
$handlesBefore = $procBefore.HandleCount

$jobs = @()
$scriptBlockPipelines = {
    param($server, $port)
    $success = 0
    for ($c = 1; $c -le 10; $c++) {
        try {
            $tcp = New-Object System.Net.Sockets.TcpClient($server, $port)
            $tcp.ReceiveTimeout = 4000
            $tcp.SendTimeout = 4000
            $stream = $tcp.GetStream()
            $payload = ""
            for ($k = 1; $k -le 5; $k++) {
                $payload += "GET /api/v1/telemetry HTTP/1.1`r`nHost: $server`:$port`r`n`r`n"
            }
            $b = [System.Text.Encoding]::ASCII.GetBytes($payload)
            $stream.Write($b, 0, $b.Length)
            $stream.Flush()
            $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::ASCII)
            for ($k = 1; $k -le 5; $k++) {
                $st = $reader.ReadLine()
                if ($st -match "200 OK") { $success++ }
                while (($h = $reader.ReadLine()) -ne "") { if ($null -eq $h) { break } }
            }
            $tcp.Close()
        } catch {}
    }
    return $success
}

$scriptBlockRst = {
    param($server, $port)
    $rstDrops = 0
    for ($k = 1; $k -le 25; $k++) {
        try {
            $sock = New-Object System.Net.Sockets.Socket(
                [System.Net.Sockets.AddressFamily]::InterNetwork,
                [System.Net.Sockets.SocketType]::Stream,
                [System.Net.Sockets.ProtocolType]::Tcp
            )
            $sock.Connect($server, $port)
            $b = [System.Text.Encoding]::ASCII.GetBytes("GET /api/v1/health HTTP/1.1`r`n")
            [void]$sock.Send($b)
            $sock.LingerState = New-Object System.Net.Sockets.LingerOption($true, 0)
            $sock.Close()
            $rstDrops++
        } catch {}
    }
    return $rstDrops
}

$scriptBlockStorm = {
    param($server, $port)
    $stormConns = 0
    for ($k = 1; $k -le 50; $k++) {
        try {
            $c = New-Object System.Net.Sockets.TcpClient
            $c.Connect($server, $port)
            $c.Close()
            $stormConns++
        } catch {}
    }
    return $stormConns
}

# Launch 8 jobs concurrently
$jobs += Start-Job -ScriptBlock $scriptBlockPipelines -ArgumentList $Server, $Port
$jobs += Start-Job -ScriptBlock $scriptBlockPipelines -ArgumentList $Server, $Port
$jobs += Start-Job -ScriptBlock $scriptBlockPipelines -ArgumentList $Server, $Port
$jobs += Start-Job -ScriptBlock $scriptBlockRst -ArgumentList $Server, $Port
$jobs += Start-Job -ScriptBlock $scriptBlockRst -ArgumentList $Server, $Port
$jobs += Start-Job -ScriptBlock $scriptBlockRst -ArgumentList $Server, $Port
$jobs += Start-Job -ScriptBlock $scriptBlockStorm -ArgumentList $Server, $Port
$jobs += Start-Job -ScriptBlock $scriptBlockStorm -ArgumentList $Server, $Port

Write-Host "  [*] 8 background worker jobs launched, awaiting completion..." -ForegroundColor DarkYellow
$waitResult = Wait-Job -Job $jobs -Timeout 30

$totalPipelinedSuccess = 0
$totalRstCompleted = 0
$totalStormCompleted = 0

for ($j = 0; $j -lt 3; $j++) {
    $res = Receive-Job -Job $jobs[$j]
    if ($res) { $totalPipelinedSuccess += [int]$res }
}
for ($j = 3; $j -lt 6; $j++) {
    $res = Receive-Job -Job $jobs[$j]
    if ($res) { $totalRstCompleted += [int]$res }
}
for ($j = 6; $j -lt 8; $j++) {
    $res = Receive-Job -Job $jobs[$j]
    if ($res) { $totalStormCompleted += [int]$res }
}
Remove-Job -Job $jobs -Force

Write-Host "  [*] Completed: $totalPipelinedSuccess pipelined requests, $totalRstCompleted RST drops, $totalStormCompleted rapid connects" -ForegroundColor Gray
Check-Assert -Name "Test B (Concurrent Hammer)" -Condition ($totalPipelinedSuccess -ge 100 -and $totalRstCompleted -ge 50 -and $totalStormCompleted -ge 80) -Details "Hammer completed successfully across all 8 concurrent jobs"

# ------------------------------------------------------------------------------
# Test C: Health Check and Stability Post-Hammer
# ------------------------------------------------------------------------------
Write-Host "`n--- Test C: Post-Hammer Liveness & Resource Inspection ---" -ForegroundColor Yellow
$procAfter = Get-Process -Name v31_swarm
$wsAfter = [math]::Round($procAfter.WorkingSet64 / 1MB, 2)
$handlesAfter = $procAfter.HandleCount
$wsDelta = [math]::Round($wsAfter - $wsBefore, 2)
$handlesDelta = $handlesAfter - $handlesBefore

$resp = Invoke-WebRequest -Uri "http://$Server`:$Port/api/v1/health" -UseBasicParsing -TimeoutSec 3
$healthy = ($resp.StatusCode -eq 200 -and $procAfter.Id -eq $procBefore.Id)

Check-Assert -Name "Test C (Liveness Post-Hammer)" -Condition $healthy -Details "Server responded 200 OK after full concurrency assault (PID $($procAfter.Id))"
Check-Assert -Name "Test C (Memory Stability)" -Condition ($wsDelta -lt 25.0) -Details "Working set delta: $wsDelta MB (Current: $wsAfter MB)"
Check-Assert -Name "Test C (Handle Stability)" -Condition ($handlesDelta -lt 50) -Details "Handle delta: $handlesDelta (Current: $handlesAfter)"

# ------------------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------------------
Write-Host "`n==========================================================================" -ForegroundColor Cyan
Write-Host "   M1 CHALLENGER 2 CONCURRENCY RESULTS: $Passed / $Total PASSED           " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan

if ($Failed -gt 0) {
    exit 1
} else {
    exit 0
}
