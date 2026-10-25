# C:\sovereign_manifold_v31\tests\e2e\test_m1_challenger_concurrent_sockets.ps1
# Adversarial Concurrent Socket Idle Hold Stress Test
# Tests 8 concurrent raw TCP sockets holding idle for 16.0s simultaneously
$ErrorActionPreference = "Stop"

$server = "127.0.0.1"
$port = 8097
$numSockets = 8
$conns = @()

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "   CHALLENGER M1-2: CONCURRENT RAW TCP SOCKET IDLE HOLD STRESS (8x 16s)   " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan

try {
    Write-Host "[*] Establishing $numSockets concurrent TCP connections..." -ForegroundColor Yellow
    for ($i = 0; $i -lt $numSockets; $i++) {
        $tcp = New-Object System.Net.Sockets.TcpClient($server, $port)
        $tcp.ReceiveTimeout = 30000
        $tcp.SendTimeout = 30000
        $stream = $tcp.GetStream()
        $writer = New-Object System.IO.StreamWriter($stream, [System.Text.Encoding]::ASCII)
        $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::ASCII)

        # Initial request
        $writer.Write("GET /api/v1/health HTTP/1.1`r`nHost: $server`:$port`r`n`r`n")
        $writer.Flush()
        $statusLine = $reader.ReadLine()
        if ($statusLine -notmatch "200 OK") {
            throw "Socket $i initial health check failed: $statusLine"
        }
        # Drain headers
        while (($line = $reader.ReadLine()) -ne "") {
            if ($null -eq $line) { break }
        }
        $conns += [PSCustomObject]@{
            Id = $i
            Tcp = $tcp
            Stream = $stream
            Writer = $writer
            Reader = $reader
        }
        Write-Host "  [+] Socket $i connected and initialized with 200 OK" -ForegroundColor Gray
    }

    Write-Host "`n[*] All $numSockets sockets established. Idling simultaneously for 16.0 seconds..." -ForegroundColor DarkYellow
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    Start-Sleep -Milliseconds 16000
    $sw.Stop()
    $elapsedSec = [math]::Round($sw.Elapsed.TotalSeconds, 2)
    Write-Host "[*] Sleep completed after $elapsedSec seconds. Verifying all $numSockets sockets are alive..." -ForegroundColor Yellow

    $allPassed = $true
    for ($i = 0; $i -lt $numSockets; $i++) {
        $c = $conns[$i]
        $c.Writer.Write("GET /assets/index-CaWs2mFf.js HTTP/1.1`r`nHost: $server`:$port`r`nConnection: close`r`n`r`n")
        $c.Writer.Flush()

        $status = $c.Reader.ReadLine()
        $cacheControl = ""
        while (($line = $c.Reader.ReadLine()) -ne "") {
            if ($null -eq $line) { break }
            if ($line -match "^Cache-Control:\s*(.+)") {
                $cacheControl = $matches[1].Trim()
            }
        }

        $ok = ($status -match "200 OK" -and $cacheControl -eq "public, max-age=86400, immutable")
        if ($ok) {
            Write-Host "  [PASS] Socket $($c.Id) survived $elapsedSec s idle -> Status: $status, Cache-Control: $cacheControl" -ForegroundColor Green
        } else {
            $allPassed = $false
            Write-Host "  [FAIL] Socket $($c.Id) failed after $elapsedSec s idle -> Status: $status, Cache-Control: $cacheControl" -ForegroundColor Red
        }
        $c.Tcp.Close()
    }

    Write-Host "==========================================================================" -ForegroundColor Cyan
    if ($allPassed) {
        Write-Host "CONCURRENT STRESS AUDIT: ALL $numSockets CONCURRENT SOCKETS PASSED (100%)" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "CONCURRENT STRESS AUDIT: FAILURE DETECTED" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "[ERROR] Exception during concurrent stress test: $_" -ForegroundColor Red
    foreach ($c in $conns) {
        try { $c.Tcp.Close() } catch {}
    }
    exit 1
}
