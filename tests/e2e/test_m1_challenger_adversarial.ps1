# ==============================================================================
# ACT-OMEGA NET v49.0.0 — MILESTONE 1 ADVERSARIAL CHALLENGER SUITE
# Challenger M1-2: Caching Invariants, Edge Cases & Keep-Alive Stream Probing
# ==============================================================================

$ErrorActionPreference = "Stop"
$HostAddr = "127.0.0.1"
$Port = 8097
$PassCount = 0
$FailCount = 0
$Findings = @()

function Report-Pass($desc) {
    Write-Host "  [PASS] $desc" -ForegroundColor Green
    $global:PassCount++
}

function Report-Fail($desc, $details) {
    Write-Host "  [FAIL] $desc" -ForegroundColor Red
    Write-Host "         Details: $details" -ForegroundColor DarkYellow
    $global:FailCount++
    $global:Findings += [PSCustomObject]@{
        Test = $desc
        Details = $details
    }
}

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "   MILESTONE 1: CHALLENGER M1-2 ADVERSARIAL CACHING & SOCKET PROBE        " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan

# ------------------------------------------------------------------------------
# Helper: Raw HTTP request over TCP socket
# ------------------------------------------------------------------------------
function Send-RawHttp($stream, $reader, $reqStr, $isHead = $false) {
    $bytes = [System.Text.Encoding]::ASCII.GetBytes($reqStr)
    $stream.Write($bytes, 0, $bytes.Length)
    $stream.Flush()

    # Read status line
    $statusLine = $reader.ReadLine()
    if ($null -eq $statusLine) {
        return $null
    }

    # Read headers
    $headers = @{}
    $contentLength = 0
    while ($true) {
        $line = $reader.ReadLine()
        if ($null -eq $line -or $line -eq "") { break }
        $colonIdx = $line.IndexOf(":")
        if ($colonIdx -gt 0) {
            $hName = $line.Substring(0, $colonIdx).Trim().ToLower()
            $hVal = $line.Substring($colonIdx + 1).Trim()
            $headers[$hName] = $hVal
            if ($hName -eq "content-length") {
                [int]::TryParse($hVal, [ref]$contentLength) | Out-Null
            }
        }
    }

    # Read body if any (HEAD responses NEVER have a message body per RFC 7230)
    $body = ""
    if (-not $isHead -and $contentLength -gt 0) {
        $buf = New-Object char[] $contentLength
        $totalRead = 0
        while ($totalRead -lt $contentLength) {
            $read = $reader.Read($buf, $totalRead, $contentLength - $totalRead)
            if ($read -le 0) { break }
            $totalRead += $read
        }
        $body = New-Object string ($buf, 0, $totalRead)
    }

    return [PSCustomObject]@{
        StatusLine = $statusLine
        Headers = $headers
        Body = $body
    }
}

# ------------------------------------------------------------------------------
# PHASE 1: Path & Extension Adversarial Probing (Independent HTTP Requests)
# ------------------------------------------------------------------------------
Write-Host "`n--- Phase 1: Cache-Control Header Probing Across Path Variants ---" -ForegroundColor Yellow

$TestMatrix = @(
    # [Target, ExpectedCacheControl, Description]
    @("/assets/index-CaWs2mFf.js", "public, max-age=86400, immutable", "Static JS bundle in /assets/"),
    @("/favicon.ico", "public, max-age=86400, immutable", "Static root favicon.ico"),
    @("/favicon.png", "public, max-age=86400, immutable", "Static root favicon.png"),
    @("/logo.svg", "public, max-age=86400, immutable", "Static root logo.svg"),
    @("/act_omega_logo.jpg", "public, max-age=86400, immutable", "Static root logo.jpg"),
    @("/icon-192.png", "public, max-age=86400, immutable", "Static root icon-192.png"),
    @("/icon-512.png", "public, max-age=86400, immutable", "Static root icon-512.png"),
    @("/api/v1/telemetry", "no-store", "Dynamic live telemetry route"),
    @("/api/v1/health", "no-store", "Dynamic health check route"),
    @("/api/v1/StateGraph", "no-store", "Dynamic StateGraph route"),
    @("/shadow/status", "no-store", "Shadow state endpoint"),
    @("/sw.js", "no-store", "PWA Service Worker root"),
    @("/manifest.webmanifest", "no-store", "PWA Web App Manifest"),
    @("/index.html", "no-store", "Root SPA HTML entrypoint"),
    @("/", "no-store", "Root slash entrypoint"),
    @("/wiki", "no-store", "Wiki SPA entrypoint"),
    @("/wiki.html", "no-store", "Wiki HTML entrypoint"),
    @("/github_pages", "no-store", "GitHub Pages entrypoint"),
    @("/sovereign_harmonic_iv_v4000.e8z", "no-store", "Binary weight buffer .e8z"),
    @("/llms.txt", "no-store", "LLMs context manifest"),
    # Adversarial edge cases:
    @("/api/test.js", "no-store", "Adversarial: /api/ prefix with .js extension"),
    @("/api/v1/icon.png", "no-store", "Adversarial: /api/ prefix with .png extension"),
    @("/shadow/style.css", "no-store", "Adversarial: /shadow/ prefix with .css extension"),
    @("/sw.js?v=49", "no-store", "Adversarial: /sw.js with query parameter"),
    @("/manifest.webmanifest?hash=abc", "no-store", "Adversarial: manifest with query parameter"),
    @("/index.html?v=49", "no-store", "Adversarial: index.html with query parameter"),
    @("/api/v1/admin/self_exit", "no-store", "Adversarial 403 Forbidden endpoint: /api/v1/admin/self_exit")
)

foreach ($item in $TestMatrix) {
    $target = $item[0]
    $expected = $item[1]
    $desc = $item[2]

    $client = New-Object System.Net.Sockets.TcpClient($HostAddr, $Port)
    $stream = $client.GetStream()
    $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::ASCII)

    $req = "GET $target HTTP/1.1`r`nHost: $HostAddr`r`nConnection: close`r`n`r`n"
    $res = Send-RawHttp $stream $reader $req

    $client.Close()

    if ($null -eq $res) {
        Report-Fail "$desc ($target)" "Server returned null response (socket closed prematurely)"
        continue
    }

    $actualCache = $res.Headers["cache-control"]
    if ($actualCache -eq $expected) {
        Report-Pass "$($desc) -> Cache-Control = '$actualCache'"
    } else {
        Report-Fail "$desc ($target)" "Expected '$expected' but got '$actualCache' (Status: $($res.StatusLine))"
    }
}

# ------------------------------------------------------------------------------
# PHASE 2: Keep-Alive State Contamination / Cross-Request Leaks
# ------------------------------------------------------------------------------
Write-Host "`n--- Phase 2: Single-Socket Keep-Alive Header Isolation Test ---" -ForegroundColor Yellow

$kaClient = New-Object System.Net.Sockets.TcpClient($HostAddr, $Port)
$kaStream = $kaClient.GetStream()
$kaReader = New-Object System.IO.StreamReader($kaStream, [System.Text.Encoding]::ASCII)

$KaSequence = @(
    # Request alternating static (immutable) and sensitive (no-store) assets
    @("GET", "/assets/index-CaWs2mFf.js", "public, max-age=86400, immutable", "Seq 1: Static JS bundle"),
    @("GET", "/api/v1/health", "no-store", "Seq 2: API Health immediately after static JS"),
    @("GET", "/favicon.ico", "public, max-age=86400, immutable", "Seq 3: Static Favicon"),
    @("GET", "/sw.js", "no-store", "Seq 4: Service Worker immediately after static Favicon"),
    @("GET", "/logo.svg", "public, max-age=86400, immutable", "Seq 5: Static SVG logo"),
    @("GET", "/manifest.webmanifest", "no-store", "Seq 6: Manifest immediately after static SVG"),
    @("GET", "/icon-192.png", "public, max-age=86400, immutable", "Seq 7: Static PNG icon"),
    @("GET", "/index.html", "no-store", "Seq 8: index.html immediately after static PNG"),
    @("GET", "/assets/index-CaWs2mFf.js", "public, max-age=86400, immutable", "Seq 9: Static JS bundle"),
    @("OPTIONS", "/api/v1/telemetry", "no-store", "Seq 10: OPTIONS request immediately after static JS"),
    @("GET", "/assets/index-CaWs2mFf.js", "public, max-age=86400, immutable", "Seq 11: Static JS bundle"),
    @("HEAD", "/api/v1/health", "no-store", "Seq 12: HEAD /api/v1/health immediately after static JS"),
    @("GET", "/assets/index-CaWs2mFf.js", "public, max-age=86400, immutable", "Seq 13: Static JS bundle"),
    @("GET", "/api/v1/admin/self_exit", "no-store", "Seq 14: 403 Forbidden immediately after static JS")
)

$seqIdx = 0
foreach ($step in $KaSequence) {
    $seqIdx++
    $m = $step[0]
    $u = $step[1]
    $expHdr = $step[2]
    $label = $step[3]

    $reqStr = "$m $u HTTP/1.1`r`nHost: $HostAddr`r`nConnection: keep-alive`r`n`r`n"
    $res = Send-RawHttp $kaStream $kaReader $reqStr ($m -eq "HEAD")

    if ($null -eq $res) {
        Report-Fail "$label" "Socket unexpectedly terminated at step $seqIdx"
        break
    }

    $actual = $res.Headers["cache-control"]
    if ($actual -eq $expHdr) {
        Report-Pass "$($label) -> Cache-Control = '$actual'"
    } else {
        Report-Fail "$label" "LEAK DETECTED! Expected '$expHdr' but got '$actual' (Status: $($res.StatusLine))"
    }
}

$kaClient.Close()

# ------------------------------------------------------------------------------
# PHASE 3: 100 Consecutive Keep-Alive Requests on Single TCP Connection
# ------------------------------------------------------------------------------
Write-Host "`n--- Phase 3: High-Volume 100-Request Keep-Alive Stream ---" -ForegroundColor Yellow

$stressClient = New-Object System.Net.Sockets.TcpClient($HostAddr, $Port)
$stressStream = $stressClient.GetStream()
$stressReader = New-Object System.IO.StreamReader($stressStream, [System.Text.Encoding]::ASCII)

$completedRequests = 0
$stressErrors = 0
$lastConnectionHdr = ""

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

for ($i = 1; $i -le 100; $i++) {
    # Alternate between /api/v1/health and /favicon.ico
    $targetPath = if ($i % 2 -eq 0) { "/api/v1/health" } else { "/favicon.ico" }
    $reqStr = "GET $targetPath HTTP/1.1`r`nHost: $HostAddr`r`nConnection: keep-alive`r`n`r`n"

    try {
        $res = Send-RawHttp $stressStream $stressReader $reqStr
        if ($null -eq $res) {
            Report-Fail "Stress Request #$i" "Socket closed or null response received from server"
            $stressErrors++
            break
        }
        $completedRequests++
        if ($res.Headers.ContainsKey("connection")) {
            $lastConnectionHdr = $res.Headers["connection"]
        }
    } catch {
        Report-Fail "Stress Request #$i" "Exception during send/recv: $($_.Exception.Message)"
        $stressErrors++
        break
    }
}

$stopwatch.Stop()

if ($completedRequests -eq 100 -and $stressErrors -eq 0) {
    Report-Pass "100/100 consecutive keep-alive requests completed successfully in $($stopwatch.ElapsedMilliseconds) ms (avg $([math]::Round($stopwatch.ElapsedMilliseconds / 100.0, 2)) ms/req)"
} else {
    Report-Fail "100 Consecutive Keep-Alive Requests" "Completed $completedRequests/100 requests. Errors: $stressErrors"
}

# Verify request 100 signaled connection close as server max=100
if ($lastConnectionHdr -eq "close") {
    Report-Pass "Request #100 received 'Connection: close' honoring max=100 boundary"
} else {
    Write-Host "  [*] Request #100 Connection header: '$lastConnectionHdr'" -ForegroundColor DarkGray
}

$stressClient.Close()

# ------------------------------------------------------------------------------
# PHASE 4: Path Traversal & Exotic Edge Cases
# ------------------------------------------------------------------------------
Write-Host "`n--- Phase 4: Path Normalization & Exotic Edge Cases ---" -ForegroundColor Yellow

$ExoticCases = @(
    @("//sw.js", "no-store", "Double leading slash on service worker (//sw.js)"),
    @("/./sw.js", "no-store", "Dot-slash on service worker (/./sw.js)"),
    @("/assets/../sw.js", "no-store", "Traversal attempt out of /assets/ (/assets/../sw.js)"),
    @("/nonexistent.wasm", "public, max-age=86400, immutable", "Non-existent WASM file (/nonexistent.wasm)"),
    @("/nonexistent.xyz", "no-store", "Non-existent unknown extension (/nonexistent.xyz)")
)

foreach ($tc in $ExoticCases) {
    $u = $tc[0]
    $exp = $tc[1]
    $desc = $tc[2]

    $c = New-Object System.Net.Sockets.TcpClient($HostAddr, $Port)
    $s = $c.GetStream()
    $r = New-Object System.IO.StreamReader($s, [System.Text.Encoding]::ASCII)

    $reqStr = "GET $u HTTP/1.1`r`nHost: $HostAddr`r`nConnection: close`r`n`r`n"
    $res = Send-RawHttp $s $r $reqStr
    $c.Close()

    if ($null -eq $res) {
        Report-Fail "$desc" "Server closed socket"
        continue
    }

    $actual = $res.Headers["cache-control"]
    if ($actual -eq $exp) {
        Report-Pass "$($desc) -> Cache-Control = '$actual' (Status: $($res.StatusLine))"
    } else {
        Report-Fail "$desc" "Expected Cache-Control: '$exp' but got '$actual' (Status: $($res.StatusLine))"
    }
}

# ------------------------------------------------------------------------------
# SUMMARY & VERDICT
# ------------------------------------------------------------------------------
Write-Host "`n==========================================================================" -ForegroundColor Cyan
Write-Host "   AUDIT SUMMARY: $PassCount PASSED, $FailCount FAILED" -ForegroundColor $(if ($FailCount -eq 0) { "Green" } else { "Red" })
Write-Host "==========================================================================" -ForegroundColor Cyan

if ($FailCount -gt 0) {
    Write-Host "`nFindings Summary:" -ForegroundColor Red
    foreach ($f in $Findings) {
        Write-Host " - $($f.Test): $($f.Details)" -ForegroundColor DarkYellow
    }
}
