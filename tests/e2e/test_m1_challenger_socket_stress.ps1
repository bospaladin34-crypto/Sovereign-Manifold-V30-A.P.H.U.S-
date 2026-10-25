# C:\sovereign_manifold_v31\tests\e2e\test_m1_challenger_socket_stress.ps1
# Adversarial Socket Timeout & Keep-Alive Stress Test for v31_swarm
# Challenger M1-1 (Milestone 1 Stress Test)
$ErrorActionPreference = "Stop"

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "   CHALLENGER M1-1: ADVERSARIAL RAW TCP SOCKET & TIMEOUT STRESS HARNESS   " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan

$server = "127.0.0.1"
$port = 8097
$allPass = $true
$testCount = 0
$passCount = 0

function Report-Assert($name, $condition, $msg) {
    $script:testCount++
    if ($condition) {
        $script:passCount++
        Write-Host "  [PASS] $name`: $msg" -ForegroundColor Green
    } else {
        $script:allPass = $false
        Write-Host "  [FAIL] $name`: $msg" -ForegroundColor Red
    }
}

# -------------------------------------------------------------------------
# STRESS 1: Raw TCP Connection Holding Idle for > 15 Seconds (16.5s Measured Idle)
# -------------------------------------------------------------------------
Write-Host "`n[*] STRESS 1: Raw TCP connection holding idle for > 15 seconds (target: 16.5s)..." -ForegroundColor Yellow
try {
    $tcp = New-Object System.Net.Sockets.TcpClient($server, $port)
    $tcp.ReceiveTimeout = 35000
    $tcp.SendTimeout = 35000
    $stream = $tcp.GetStream()
    $writer = New-Object System.IO.StreamWriter($stream, [System.Text.Encoding]::ASCII)
    $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::ASCII)

    # Request 1: Health check
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $writer.Write("GET /api/v1/health HTTP/1.1`r`nHost: $server`:$port`r`n`r`n")
    $writer.Flush()

    $statusLine1 = $reader.ReadLine()
    $contentLength1 = 0
    while (($line = $reader.ReadLine()) -ne "") {
        if ($null -eq $line) { break }
        if ($line -match "^Content-Length:\s*(\d+)") {
            $contentLength1 = [int]$matches[1]
        }
    }
    # Drain body
    if ($contentLength1 -gt 0) {
        $bodyBuf = New-Object char[] $contentLength1
        $readBytes = $reader.ReadBlock($bodyBuf, 0, $contentLength1)
    }

    $req1Ok = ($statusLine1 -match "200 OK")
    Report-Assert "Stress 1.1 (Request 1 on Socket)" $req1Ok "Status line: $statusLine1"

    # Idle pause for 16.5 seconds (> 15.0s prompt requirement, > 10.0s cloudflared timeout, < 25.0s swarm timeout)
    Write-Host "  [*] Idling on open TCP socket for 16.5 seconds..." -ForegroundColor DarkYellow
    $idleTimer = [System.Diagnostics.Stopwatch]::StartNew()
    Start-Sleep -Milliseconds 16500
    $idleTimer.Stop()
    $measuredIdleSec = [math]::Round($idleTimer.Elapsed.TotalSeconds, 2)

    # Request 2: Send second request on the EXACT SAME socket
    $writer.Write("GET /api/v1/health HTTP/1.1`r`nHost: $server`:$port`r`n`r`n")
    $writer.Flush()

    $statusLine2 = $reader.ReadLine()
    $contentLength2 = 0
    while (($line = $reader.ReadLine()) -ne "") {
        if ($null -eq $line) { break }
        if ($line -match "^Content-Length:\s*(\d+)") {
            $contentLength2 = [int]$matches[1]
        }
    }
    if ($contentLength2 -gt 0) {
        $bodyBuf = New-Object char[] $contentLength2
        $readBytes = $reader.ReadBlock($bodyBuf, 0, $contentLength2)
    }

    $req2Ok = ($statusLine2 -match "200 OK")
    Report-Assert "Stress 1.2 (Socket Survival after >15s Idle)" $req2Ok "Socket survived $measuredIdleSec seconds of idle and returned: $statusLine2"

    # Request 3: Send third request after another 3s idle with Connection: close
    Start-Sleep -Seconds 3
    $writer.Write("GET /assets/index-CaWs2mFf.js HTTP/1.1`r`nHost: $server`:$port`r`nConnection: close`r`n`r`n")
    $writer.Flush()

    $statusLine3 = $reader.ReadLine()
    $cacheControlHdr = ""
    while (($line = $reader.ReadLine()) -ne "") {
        if ($null -eq $line) { break }
        if ($line -match "^Cache-Control:\s*(.+)") {
            $cacheControlHdr = $matches[1].Trim()
        }
    }

    $req3Ok = ($statusLine3 -match "200 OK" -and $cacheControlHdr -eq "public, max-age=86400, immutable")
    Report-Assert "Stress 1.3 (Multi-Turn Request on Single Socket)" $req3Ok "3rd request on socket after cumulative 19.5s idle returned 200 OK with Cache-Control: $cacheControlHdr"

    $tcp.Close()
} catch {
    Report-Assert "Stress 1 (Idle Socket)" $false "Exception caught: $_"
}

# -------------------------------------------------------------------------
# STRESS 2: Pipelined Sequential Request Storm over Single TCP Socket (25 Transactions)
# -------------------------------------------------------------------------
Write-Host "`n[*] STRESS 2: High-throughput transaction loop (25 requests over single socket)..." -ForegroundColor Yellow
try {
    $tcp = New-Object System.Net.Sockets.TcpClient($server, $port)
    $tcp.ReceiveTimeout = 15000
    $tcp.SendTimeout = 15000
    $stream = $tcp.GetStream()
    $writer = New-Object System.IO.StreamWriter($stream, [System.Text.Encoding]::ASCII)
    $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::ASCII)

    $stormSuccess = $true
    $stormCount = 25
    $swStorm = [System.Diagnostics.Stopwatch]::StartNew()

    for ($i = 1; $i -le $stormCount; $i++) {
        $writer.Write("GET /api/v1/health HTTP/1.1`r`nHost: $server`:$port`r`n`r`n")
        $writer.Flush()

        $statusLine = $reader.ReadLine()
        if ($statusLine -notmatch "200 OK") {
            $stormSuccess = $false
            Write-Host "    Failed on request $i`: $statusLine" -ForegroundColor Red
            break
        }
        $cL = 0
        while (($line = $reader.ReadLine()) -ne "") {
            if ($null -eq $line) { break }
            if ($line -match "^Content-Length:\s*(\d+)") { $cL = [int]$matches[1] }
        }
        if ($cL -gt 0) {
            $buf = New-Object char[] $cL
            $null = $reader.ReadBlock($buf, 0, $cL)
        }
    }
    $swStorm.Stop()
    $tcp.Close()

    Report-Assert "Stress 2.1 (25 Sequential Requests Single Socket)" $stormSuccess "Completed $stormCount transactions in $($swStorm.ElapsedMilliseconds)ms ($([math]::Round($stormCount / $swStorm.Elapsed.TotalSeconds, 1)) req/sec)"
} catch {
    Report-Assert "Stress 2 (Transaction Loop)" $false "Exception caught: $_"
}

# -------------------------------------------------------------------------
# STRESS 3: Upper-Bound Socket Read Timeout (> 25.0s Idle Drops Cleanly)
# -------------------------------------------------------------------------
Write-Host "`n[*] STRESS 3: Verifying socket timeout upper bound (holding idle 26.5s to confirm timeout occurs)..." -ForegroundColor Yellow
try {
    $tcp = New-Object System.Net.Sockets.TcpClient($server, $port)
    $tcp.ReceiveTimeout = 35000
    $tcp.SendTimeout = 35000
    $stream = $tcp.GetStream()
    $writer = New-Object System.IO.StreamWriter($stream, [System.Text.Encoding]::ASCII)
    $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::ASCII)

    # Initial request
    $writer.Write("GET /api/v1/health HTTP/1.1`r`nHost: $server`:$port`r`n`r`n")
    $writer.Flush()
    $statusLine1 = $reader.ReadLine()
    while (($line = $reader.ReadLine()) -ne "") { if ($null -eq $line) { break } }

    # Idle wait for 26.5s (> 25.0s server timeout)
    Write-Host "  [*] Idling on open TCP socket for 26.5 seconds to trigger timeout..." -ForegroundColor DarkYellow
    Start-Sleep -Milliseconds 26500

    # Next read or write attempt should observe disconnected / EOF socket
    $timedOut = $false
    try {
        $writer.Write("GET /api/v1/health HTTP/1.1`r`nHost: $server`:$port`r`n`r`n")
        $writer.Flush()
        $lineAfterTimeout = $reader.ReadLine()
        if ($null -eq $lineAfterTimeout -or $lineAfterTimeout -eq "") {
            $timedOut = $true
        }
    } catch {
        $timedOut = $true
    }
    $tcp.Close()

    Report-Assert "Stress 3.1 (Timeout Boundary Enforcement)" $timedOut "Server cleanly terminated socket after 26.5s (> 25.0s timeout), avoiding dangling leaks"
} catch {
    Report-Assert "Stress 3 (Timeout Boundary)" $false "Exception: $_"
}

# -------------------------------------------------------------------------
# STRESS 4: Static Cache Matrix & Dynamic Isolation
# -------------------------------------------------------------------------
Write-Host "`n[*] STRESS 4: Testing static asset cache matrix against dynamic endpoints..." -ForegroundColor Yellow
$matrixTests = @(
    @{ Url = "http://$server`:$port/assets/index-CaWs2mFf.js"; Expected = "public, max-age=86400, immutable"; Label = "Vite Bundle" },
    @{ Url = "http://$server`:$port/assets/index-CaWs2mFf.js?query=bypass"; Expected = "public, max-age=86400, immutable"; Label = "Vite Bundle with Query" },
    @{ Url = "http://$server`:$port/favicon.ico"; Expected = "public, max-age=86400, immutable"; Label = "Favicon" },
    @{ Url = "http://$server`:$port/api/v1/telemetry"; Expected = "no-store"; Label = "Dynamic Telemetry" },
    @{ Url = "http://$server`:$port/api/v1/health"; Expected = "no-store"; Label = "Dynamic Health" },
    @{ Url = "http://$server`:$port/sw.js"; Expected = "no-store"; Label = "Service Worker" },
    @{ Url = "http://$server`:$port/manifest.webmanifest"; Expected = "no-store"; Label = "PWA Manifest" },
    @{ Url = "http://$server`:$port/index.html"; Expected = "no-store"; Label = "Root HTML" },
    @{ Url = "http://$server`:$port/llms.txt"; Expected = "no-store"; Label = "LLMs Text" }
)

foreach ($item in $matrixTests) {
    try {
        $res = Invoke-WebRequest -Uri $item.Url -UseBasicParsing -TimeoutSec 5
        $cc = $res.Headers["Cache-Control"]
        if ($cc -is [array]) { $cc = $cc -join ", " }
        $match = ($cc -eq $item.Expected)
        Report-Assert "Stress 4 ($($item.Label))" $match "Url: $($item.Url) -> Cache-Control: $cc"
    } catch {
        Report-Assert "Stress 4 ($($item.Label))" $false "Request failed: $_"
    }
}

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "STRESS AUDIT COMPLETE: $passCount PASSED, $($testCount - $passCount) FAILED" -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan

if (-not $allPass) {
    exit 1
} else {
    exit 0
}
