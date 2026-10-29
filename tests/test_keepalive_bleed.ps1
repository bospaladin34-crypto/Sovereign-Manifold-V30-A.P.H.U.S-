# Single socket keepalive pipeline test
$ErrorActionPreference = "Stop"

$tcp = New-Object System.Net.Sockets.TcpClient("127.0.0.1", 8097)
$stream = $tcp.GetStream()
$writer = New-Object System.IO.StreamWriter($stream, [System.Text.Encoding]::ASCII)
$reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::ASCII)

function Read-ResponseHeaders($r) {
    $hdrs = @{}
    $statusLine = $r.ReadLine()
    $hdrs["STATUS"] = $statusLine
    while ($true) {
        $line = $r.ReadLine()
        if ([string]::IsNullOrEmpty($line)) { break }
        $parts = $line -split ':\s*', 2
        if ($parts.Count -eq 2) {
            $hdrs[$parts[0].Trim()] = $parts[1].Trim()
        }
    }
    if ($hdrs.ContainsKey("Content-Length")) {
        $cl = [int]$hdrs["Content-Length"]
        $buf = New-Object char[] $cl
        $totalRead = 0
        while ($totalRead -lt $cl) {
            $readCount = $r.Read($buf, $totalRead, $cl - $totalRead)
            if ($readCount -le 0) { break }
            $totalRead += $readCount
        }
    }
    return $hdrs
}

# 1. HTML request
$writer.Write("GET / HTTP/1.1`r`nHost: 127.0.0.1:8097`r`nConnection: keep-alive`r`n`r`n")
$writer.Flush()
$h1 = Read-ResponseHeaders $reader
Write-Host "Req 1 (/): Status=$($h1['STATUS']), Cache-Control=$($h1['Cache-Control']), Robots=$($h1['X-Robots-Tag'])"

# 2. API request over same connection
$writer.Write("GET /api/v1/health HTTP/1.1`r`nHost: 127.0.0.1:8097`r`nConnection: keep-alive`r`n`r`n")
$writer.Flush()
$h2 = Read-ResponseHeaders $reader
Write-Host "Req 2 (/api/v1/health): Status=$($h2['STATUS']), Cache-Control=$($h2['Cache-Control']), Robots=$($h2['X-Robots-Tag'])"

# 3. HTML request over same connection
$writer.Write("GET /index.html HTTP/1.1`r`nHost: 127.0.0.1:8097`r`nConnection: keep-alive`r`n`r`n")
$writer.Flush()
$h3 = Read-ResponseHeaders $reader
Write-Host "Req 3 (/index.html): Status=$($h3['STATUS']), Cache-Control=$($h3['Cache-Control']), Robots=$($h3['X-Robots-Tag'])"

# 4. Manifest request over same connection
$writer.Write("GET /manifest.webmanifest HTTP/1.1`r`nHost: 127.0.0.1:8097`r`nConnection: close`r`n`r`n")
$writer.Flush()
$h4 = Read-ResponseHeaders $reader
Write-Host "Req 4 (/manifest.webmanifest): Status=$($h4['STATUS']), Cache-Control=$($h4['Cache-Control']), Robots=$($h4['X-Robots-Tag'])"

$tcp.Close()

$pass1 = ($h1['Cache-Control'] -match "public, max-age=0, must-revalidate" -and $h1['X-Robots-Tag'] -match "index, follow")
$pass2 = ($h2['Cache-Control'] -eq "no-store" -and [string]::IsNullOrEmpty($h2['X-Robots-Tag']))
$pass3 = ($h3['Cache-Control'] -match "public, max-age=0, must-revalidate" -and $h3['X-Robots-Tag'] -match "index, follow")
$pass4 = ($h4['Cache-Control'] -eq "no-store" -and [string]::IsNullOrEmpty($h4['X-Robots-Tag']))

$allPass = ($pass1 -and $pass2 -and $pass3 -and $pass4)
Write-Host "KEEP-ALIVE ZERO-BLEED VERIFICATION: $allPass"
if ($allPass) { exit 0 } else { exit 1 }
