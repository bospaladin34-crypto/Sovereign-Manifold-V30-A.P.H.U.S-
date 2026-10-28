# ==============================================================================
# ACT-OMEGA NET v50.0.0 -- MILESTONE 1 CHALLENGER 2 ADVERSARIAL STRESS SUITE
# Boundary Conditions: Client Drop (RST), Rapid Connect/Disconnect, HTTP Pipelining
# Target: v31_swarm HTTP Server on 127.0.0.1:8097
# ==============================================================================

$ErrorActionPreference = "Stop"
$Server = "127.0.0.1"
$Port = 8097
$TotalTests = 0
$PassTests = 0
$FailTests = 0
$Findings = @()

function Report-Pass {
    param([string]$Name, [string]$Details)
    $script:TotalTests++
    $script:PassTests++
    Write-Host "  [PASS] $Name : $Details" -ForegroundColor Green
}

function Report-Fail {
    param([string]$Name, [string]$Details)
    $script:TotalTests++
    $script:FailTests++
    Write-Host "  [FAIL] $Name : $Details" -ForegroundColor Red
    $script:Findings += [PSCustomObject]@{
        Name = $Name
        Details = $Details
    }
}

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "   ACT-OMEGA NET v50.0.0 -- M1 CHALLENGER 2 BOUNDARY AND STRESS SUITE     " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan

# Pre-test Health & Process Baseline
$procBefore = Get-Process -Name v31_swarm -ErrorAction SilentlyContinue
if ($null -eq $procBefore) {
    Write-Host "[FATAL] v31_swarm process is not running!" -ForegroundColor Red
    exit 1
}
$wsBefore = [math]::Round($procBefore.WorkingSet64 / 1MB, 2)
$handlesBefore = $procBefore.HandleCount
Write-Host "Baseline Process: PID $($procBefore.Id), WS: $wsBefore MB, Handles: $handlesBefore" -ForegroundColor Gray

# ------------------------------------------------------------------------------
# TEST 1: HTTP Pipelining (5 Pipelined Requests in Single Socket Write)
# ------------------------------------------------------------------------------
Write-Host "`n--- Test 1: Pipelining 5 Requests in a Single TCP Write ---" -ForegroundColor Yellow
try {
    $tcp = New-Object System.Net.Sockets.TcpClient($Server, $Port)
    $tcp.ReceiveTimeout = 5000
    $tcp.SendTimeout = 5000
    $stream = $tcp.GetStream()

    $pipelinedPayload = ""
    for ($i = 1; $i -le 5; $i++) {
        $pipelinedPayload += "GET /api/v1/telemetry HTTP/1.1`r`nHost: $Server`:$Port`r`nX-Pipeline-Id: $i`r`n`r`n"
    }

    $bytes = [System.Text.Encoding]::ASCII.GetBytes($pipelinedPayload)
    $stream.Write($bytes, 0, $bytes.Length)
    $stream.Flush()

    $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::ASCII)
    $responses = 0

    for ($i = 1; $i -le 5; $i++) {
        $statusLine = $reader.ReadLine()
        if ($null -eq $statusLine) { break }
        if ($statusLine -match "200 OK") {
            $responses++
        }
        $contentLength = 0
        while ($true) {
            $hdr = $reader.ReadLine()
            if ($null -eq $hdr -or $hdr -eq "") { break }
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

    if ($responses -eq 5) {
        Report-Pass -Name "Test 1 (5 Pipelined GETs)" -Details "All 5 responses received sequentially with 200 OK"
    } else {
        Report-Fail -Name "Test 1 (5 Pipelined GETs)" -Details "Expected 5 responses, got $responses"
    }
} catch {
    Report-Fail -Name "Test 1 (5 Pipelined GETs)" -Details "Exception: $_"
}

# ------------------------------------------------------------------------------
# TEST 2: Deep Pipelining (20 Pipelined Requests in Single Socket Write)
# ------------------------------------------------------------------------------
Write-Host "`n--- Test 2: Deep Pipelining 20 Requests in a Single TCP Write ---" -ForegroundColor Yellow
try {
    $tcp = New-Object System.Net.Sockets.TcpClient($Server, $Port)
    $tcp.ReceiveTimeout = 10000
    $tcp.SendTimeout = 10000
    $stream = $tcp.GetStream()

    $deepPayload = ""
    for ($i = 1; $i -le 20; $i++) {
        $deepPayload += "GET /api/v1/health HTTP/1.1`r`nHost: $Server`:$Port`r`n`r`n"
    }
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($deepPayload)
    $stream.Write($bytes, 0, $bytes.Length)
    $stream.Flush()

    $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::ASCII)
    $responses20 = 0

    for ($i = 1; $i -le 20; $i++) {
        $statusLine = $reader.ReadLine()
        if ($null -eq $statusLine) { break }
        if ($statusLine -match "200 OK") {
            $responses20++
        }
        $contentLength = 0
        while ($true) {
            $hdr = $reader.ReadLine()
            if ($null -eq $hdr -or $hdr -eq "") { break }
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

    if ($responses20 -eq 20) {
        Report-Pass -Name "Test 2 (20 Deep Pipelined GETs)" -Details "All 20 responses received with 200 OK"
    } else {
        Report-Fail -Name "Test 2 (20 Deep Pipelined GETs)" -Details "Expected 20 responses, got $responses20"
    }
} catch {
    Report-Fail -Name "Test 2 (20 Deep Pipelined GETs)" -Details "Exception: $_"
}

# ------------------------------------------------------------------------------
# TEST 3: Pipelining with Early 'Connection: close' Mid-Stream
# ------------------------------------------------------------------------------
Write-Host "`n--- Test 3: Pipelining with Connection: close on Request 2 of 4 ---" -ForegroundColor Yellow
try {
    $tcp = New-Object System.Net.Sockets.TcpClient($Server, $Port)
    $tcp.ReceiveTimeout = 5000
    $tcp.SendTimeout = 5000
    $stream = $tcp.GetStream()

    $midClosePayload = "GET /api/v1/health HTTP/1.1`r`nHost: $Server`:$Port`r`n`r`n" +
                       "GET /api/v1/telemetry HTTP/1.1`r`nHost: $Server`:$Port`r`nConnection: close`r`n`r`n" +
                       "GET /api/v1/health HTTP/1.1`r`nHost: $Server`:$Port`r`n`r`n" +
                       "GET /api/v1/health HTTP/1.1`r`nHost: $Server`:$Port`r`n`r`n"

    $bytes = [System.Text.Encoding]::ASCII.GetBytes($midClosePayload)
    $stream.Write($bytes, 0, $bytes.Length)
    $stream.Flush()

    $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::ASCII)
    $receivedCount = 0
    $sawConnectionClose = $false

    for ($i = 1; $i -le 4; $i++) {
        $statusLine = $reader.ReadLine()
        if ($null -eq $statusLine) { break }
        $receivedCount++
        $contentLength = 0
        while ($true) {
            $hdr = $reader.ReadLine()
            if ($null -eq $hdr -or $hdr -eq "") { break }
            if ($hdr -match "^Connection:\s*close") {
                $sawConnectionClose = $true
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

    if ($receivedCount -eq 2 -and $sawConnectionClose) {
        Report-Pass -Name "Test 3 (Early Connection: close)" -Details "Server cleanly terminated pipeline after request 2 ($receivedCount responses), respecting Connection: close"
    } else {
        Report-Fail -Name "Test 3 (Early Connection: close)" -Details "Received $receivedCount responses (expected 2), sawClose=$sawConnectionClose"
    }
} catch {
    Report-Fail -Name "Test 3 (Early Connection: close)" -Details "Exception: $_"
}

# ------------------------------------------------------------------------------
# TEST 4: Abrupt Client Disconnect via Hard TCP RST (Linger Option 0)
# ------------------------------------------------------------------------------
Write-Host "`n--- Test 4: Abrupt Client Drops with Hard TCP RST (50 Iterations) ---" -ForegroundColor Yellow
$rstSuccessCount = 0
try {
    for ($i = 1; $i -le 50; $i++) {
        $sock = New-Object System.Net.Sockets.Socket(
            [System.Net.Sockets.AddressFamily]::InterNetwork,
            [System.Net.Sockets.SocketType]::Stream,
            [System.Net.Sockets.ProtocolType]::Tcp
        )
        $sock.Connect($Server, $Port)
        
        # Mode A (1-15): Write partial request and immediately abort with RST
        if ($i -le 15) {
            $partial = [System.Text.Encoding]::ASCII.GetBytes("GET /api/v1/telemetry HTTP/1.1`r`nHost: $Server`:$Port`r`n")
            [void]$sock.Send($partial)
        }
        # Mode B (16-30): Write complete request, don't read response, immediately abort with RST
        elseif ($i -le 30) {
            $full = [System.Text.Encoding]::ASCII.GetBytes("GET /api/v1/telemetry HTTP/1.1`r`nHost: $Server`:$Port`r`n`r`n")
            [void]$sock.Send($full)
        }
        # Mode C (31-40): Connect and immediately RST without sending any data
        elseif ($i -le 40) {
            # no data sent
        }
        # Mode D (41-50): Send malformed non-HTTP garbage then RST
        else {
            $garbage = [byte[]](0xDE, 0xAD, 0xBE, 0xEF, 0x00, 0x11, 0x22, 0x33)
            [void]$sock.Send($garbage)
        }

        # Force Winsock to send TCP RST (l_onoff=1, l_linger=0)
        $sock.LingerState = New-Object System.Net.Sockets.LingerOption($true, 0)
        $sock.Close()
        $rstSuccessCount++
    }
    Report-Pass -Name "Test 4 (Abrupt TCP RST Drops)" -Details "Executed 50 hard RST drops across 4 modes without client-side error"
} catch {
    Report-Fail -Name "Test 4 (Abrupt TCP RST Drops)" -Details "Exception at iter $i`: $_"
}

# ------------------------------------------------------------------------------
# TEST 5: Rapid Connect / Disconnect Storm (100 Rapid Connections)
# ------------------------------------------------------------------------------
Write-Host "`n--- Test 5: Rapid Connect / Disconnect Storm (100 Connections) ---" -ForegroundColor Yellow
$stormSuccess = 0
try {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    for ($i = 1; $i -le 100; $i++) {
        $client = New-Object System.Net.Sockets.TcpClient
        $client.Connect($Server, $Port)
        $client.Close()
        $stormSuccess++
    }
    $sw.Stop()
    $rate = [math]::Round($stormSuccess / ($sw.Elapsed.TotalSeconds + 0.001), 1)
    Report-Pass -Name "Test 5 (Connect/Disconnect Storm)" -Details "100 rapid connections established and closed in $($sw.ElapsedMilliseconds)ms ($rate conns/sec)"
} catch {
    Report-Fail -Name "Test 5 (Connect/Disconnect Storm)" -Details "Exception at iter $i`: $_"
}

# ------------------------------------------------------------------------------
# TEST 6: Trailing Residual Bytes Drain Verification
# ------------------------------------------------------------------------------
Write-Host "`n--- Test 6: Trailing Residual Bytes Drain Verification ---" -ForegroundColor Yellow
try {
    $tcp = New-Object System.Net.Sockets.TcpClient($Server, $Port)
    $tcp.ReceiveTimeout = 5000
    $tcp.SendTimeout = 5000
    $stream = $tcp.GetStream()

    # Send request with Connection: close AND 256 bytes of residual garbage appended
    $garbageTail = "X" * 256
    $reqWithTail = "GET /api/v1/health HTTP/1.1`r`nHost: $Server`:$Port`r`nConnection: close`r`n`r`n" + $garbageTail
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($reqWithTail)
    $stream.Write($bytes, 0, $bytes.Length)
    $stream.Flush()

    $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::ASCII)
    $statusLine = $reader.ReadLine()
    $contentLength = 0
    while ($true) {
        $hdr = $reader.ReadLine()
        if ($null -eq $hdr -or $hdr -eq "") { break }
        if ($hdr -match "^Content-Length:\s*(\d+)") {
            $contentLength = [int]$matches[1]
        }
    }
    if ($contentLength -gt 0) {
        $buf = New-Object char[] $contentLength
        [void]$reader.ReadBlock($buf, 0, $contentLength)
    }

    # Verify server closes cleanly with EOF (FIN) without throwing ConnectionReset
    $finalRead = $stream.Read((New-Object byte[] 16), 0, 16)
    $tcp.Close()

    if ($statusLine -match "200 OK" -and $finalRead -eq 0) {
        Report-Pass -Name "Test 6 (Residual Bytes Drain)" -Details "Server absorbed residual trailing bytes, returned 200 OK, and closed with clean FIN (EOF)"
    } else {
        Report-Fail -Name "Test 6 (Residual Bytes Drain)" -Details "Status: $statusLine, finalRead: $finalRead"
    }
} catch {
    Report-Fail -Name "Test 6 (Residual Bytes Drain)" -Details "Exception during residual bytes test: $_"
}

# ------------------------------------------------------------------------------
# TEST 7: Server Liveness & Memory Leak Verification Post-Stress
# ------------------------------------------------------------------------------
Write-Host "`n--- Test 7: Post-Stress Liveness & Memory Leak Check ---" -ForegroundColor Yellow
try {
    Start-Sleep -Milliseconds 500
    $resp = Invoke-WebRequest -Uri "http://$Server`:$Port/api/v1/telemetry" -UseBasicParsing -TimeoutSec 5
    $procAfter = Get-Process -Name v31_swarm -ErrorAction SilentlyContinue
    $wsAfter = [math]::Round($procAfter.WorkingSet64 / 1MB, 2)
    $handlesAfter = $procAfter.HandleCount
    $wsDelta = [math]::Round($wsAfter - $wsBefore, 2)
    $handlesDelta = $handlesAfter - $handlesBefore

    Write-Host "Post-Stress Process: PID $($procAfter.Id), WS: $wsAfter MB (Delta: $wsDelta MB), Handles: $handlesAfter (Delta: $handlesDelta)" -ForegroundColor Gray

    $isLive = ($resp.StatusCode -eq 200 -and $null -ne $procAfter -and $procAfter.Id -eq $procBefore.Id)
    $memStable = ($wsDelta -lt 30.0 -and $handlesDelta -lt 100)

    if ($isLive -and $memStable) {
        Report-Pass -Name "Test 7 (Post-Stress Liveness & Memory)" -Details "Server fully operational (HTTP 200), PID unchanged ($($procAfter.Id)), memory stable (delta: $wsDelta MB, handle delta: $handlesDelta)"
    } else {
        Report-Fail -Name "Test 7 (Post-Stress Liveness & Memory)" -Details "isLive=$isLive, wsDelta=$wsDelta MB, handlesDelta=$handlesDelta"
    }
} catch {
    Report-Fail -Name "Test 7 (Post-Stress Liveness & Memory)" -Details "Exception verifying post-stress health: $_"
}

# ------------------------------------------------------------------------------
# SUMMARY
# ------------------------------------------------------------------------------
Write-Host "`n==========================================================================" -ForegroundColor Cyan
Write-Host "   M1 CHALLENGER 2 STRESS SUITE RESULTS: $PassTests / $TotalTests PASSED  " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan

if ($FailTests -gt 0) {
    Write-Host "FAILURES DETECTED:" -ForegroundColor Red
    foreach ($f in $Findings) {
        Write-Host "  - $($f.Name): $($f.Details)" -ForegroundColor Red
    }
    exit 1
} else {
    Write-Host "ALL TESTS PASSED WITH ZERO CRASHES, ZERO HANGS, AND ZERO LEAKS." -ForegroundColor Green
    exit 0
}
