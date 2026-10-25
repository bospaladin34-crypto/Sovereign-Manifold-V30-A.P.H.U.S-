# C:\sovereign_manifold_v31\tests\e2e\test_m1_swarm_socket_headers.ps1
# Automated Verification for Feature 4 (Keep-Alive Timeout) and Feature 5 (Static Asset Caching)
$ErrorActionPreference = "Stop"

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "   MILESTONE 1: SWARM SOCKET TIMEOUT & STATIC CACHE HEADER VERIFICATION   " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan

$baseUrl = "http://127.0.0.1:8097"
$allPass = $true

# -------------------------------------------------------------
# Part 1: Static Asset vs Dynamic Route Cache-Control Headers
# -------------------------------------------------------------
$testCases = @(
    @{ Path = "/assets/index-CaWs2mFf.js"; Expected = "public, max-age=86400, immutable"; Label = "Vite Bundled JS" },
    @{ Path = "/favicon.ico";             Expected = "public, max-age=86400, immutable"; Label = "Favicon Icon" },
    @{ Path = "/api/v1/telemetry";         Expected = "no-store";                         Label = "Live Telemetry API" },
    @{ Path = "/api/v1/health";            Expected = "no-store";                         Label = "Health Endpoint" },
    @{ Path = "/sw.js";                    Expected = "no-store";                         Label = "Service Worker (Must Not Cache)" },
    @{ Path = "/manifest.webmanifest";     Expected = "no-store";                         Label = "PWA Manifest" },
    @{ Path = "/llms.txt";                 Expected = "no-store";                         Label = "LLMs Text Route" }
)

foreach ($tc in $testCases) {
    try {
        $res = Invoke-WebRequest -Uri "$baseUrl$($tc.Path)" -UseBasicParsing -TimeoutSec 5
        $actualCc = $res.Headers["Cache-Control"]
        if ($actualCc -is [array]) {
            $actualCc = $actualCc -join ", "
        }
        if ($actualCc -eq $tc.Expected) {
            Write-Host "  [PASS] [$($tc.Label)] $($tc.Path) -> Cache-Control: $actualCc" -ForegroundColor Green
        } else {
            Write-Host "  [FAIL] [$($tc.Label)] $($tc.Path) -> Expected '$($tc.Expected)', got '$actualCc'" -ForegroundColor Red
            $allPass = $false
        }
    } catch {
        Write-Host "  [FAIL] [$($tc.Label)] $($tc.Path) request failed: $_" -ForegroundColor Red
        $allPass = $false
    }
}

# -------------------------------------------------------------
# Part 2: Keep-Alive Header Verification
# -------------------------------------------------------------
try {
    $res = Invoke-WebRequest -Uri "$baseUrl/api/v1/health" -UseBasicParsing -TimeoutSec 5
    $keepAliveHdr = $res.Headers["Keep-Alive"]
    if ($keepAliveHdr -is [array]) {
        $keepAliveHdr = $keepAliveHdr -join ", "
    }
    if ($keepAliveHdr -match "timeout=25" -and $keepAliveHdr -match "max=100") {
        Write-Host "  [PASS] Keep-Alive header reports timeout=25, max=100 ($keepAliveHdr)" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] Keep-Alive header missing expected values: '$keepAliveHdr'" -ForegroundColor Red
        $allPass = $false
    }
} catch {
    Write-Host "  [FAIL] Health check failed: $_" -ForegroundColor Red
    $allPass = $false
}

# -------------------------------------------------------------
# Part 3: Active 12-Second TCP Socket Idle Survival Test
# -------------------------------------------------------------
Write-Host "  [*] Testing TCP Keep-Alive Socket Survival across 12s idle interval..." -ForegroundColor Yellow
try {
    $tcp = New-Object System.Net.Sockets.TcpClient("127.0.0.1", 8097)
    $tcp.ReceiveTimeout = 30000
    $tcp.SendTimeout = 30000
    $stream = $tcp.GetStream()
    $writer = New-Object System.IO.StreamWriter($stream, [System.Text.Encoding]::ASCII)
    $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::ASCII)

    # Send Request 1
    $writer.Write("GET /api/v1/health HTTP/1.1`r`nHost: 127.0.0.1:8097`r`n`r`n")
    $writer.Flush()
    $statusLine1 = $reader.ReadLine()
    while (($line = $reader.ReadLine()) -ne "") {
        if ($null -eq $line) { break }
    }

    if ($statusLine1 -notmatch "200 OK") {
        throw "First request failed on socket: $statusLine1"
    }

    # Idle wait for 12 seconds (> 4.5s old timeout, > 10.0s cloudflared timeout, < 25.0s new timeout)
    Start-Sleep -Seconds 12

    # Send Request 2 on the SAME open socket
    $writer.Write("GET /api/v1/health HTTP/1.1`r`nHost: 127.0.0.1:8097`r`nConnection: close`r`n`r`n")
    $writer.Flush()
    $statusLine2 = $reader.ReadLine()
    $tcp.Close()

    if ($statusLine2 -match "200 OK") {
        Write-Host "  [PASS] TCP Socket survived 12.0s idle window without disconnection! (Status: $statusLine2)" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] Second request on socket failed after 12s idle: '$statusLine2'" -ForegroundColor Red
        $allPass = $false
    }
} catch {
    Write-Host "  [FAIL] TCP Socket Idle test threw exception: $_" -ForegroundColor Red
    $allPass = $false
}

Write-Host "==========================================================================" -ForegroundColor Cyan
if (-not $allPass) {
    throw "Swarm Socket and Header Verification failed."
}
Write-Host "  SWARM VERIFICATION PASSED: ALL TESTS MET EXPECTATIONS" -ForegroundColor Green
Write-Host ""
