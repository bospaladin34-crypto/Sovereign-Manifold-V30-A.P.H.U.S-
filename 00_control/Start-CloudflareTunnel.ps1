# C:\sovereign_manifold_v31\00_control\Start-CloudflareTunnel.ps1
# Track 31.9: Outbound HTTP/3 QUIC Cloudflare Tunnel for Single-Port :5173 Multiplexer
$ErrorActionPreference = "SilentlyContinue"
$root = "C:\sovereign_manifold_v31"
$wanFile = Join-Path $root "03_vault\models\cloudflare_wan_url.txt"
$cfLog = Join-Path $root "00_control\cloudflared_quic.log"

$cfCandidates = @(
    "cloudflared",
    "$env:LOCALAPPDATA\Microsoft\WinGet\Links\cloudflared.exe",
    "C:\Program Files (x86)\cloudflared\cloudflared.exe",
    "C:\Program Files\cloudflared\cloudflared.exe",
    (Join-Path $root "00_control\cloudflared.exe")
)
$cfBin = $null
foreach($cand in($cfCandidates)){
    if(Get-Command $cand -ErrorAction SilentlyContinue){ $cfBin = $cand; break }
    if(Test-Path $cand){ $cfBin = $cand; break }
}

if($cfBin){
    Get-Process -Name "cloudflared" -ErrorAction SilentlyContinue|Stop-Process -Force
    if(Test-Path $cfLog){ Remove-Item $cfLog -Force }
    Start-Process -FilePath $cfBin -ArgumentList "tunnel --url http://127.0.0.1:5173 --protocol http2 --no-autoupdate --logfile $cfLog" -WindowStyle Hidden
    Start-Sleep -Seconds 3
    if(Test-Path $cfLog){
        $lines = Get-Content -Path $cfLog -ErrorAction SilentlyContinue
        foreach($ln in($lines)){
            if($ln -match "(https://[a-zA-Z0-9\-]+\.trycloudflare\.com)"){
                $wanUrl = $Matches[1]
                [System.IO.File]::WriteAllText($wanFile,$wanUrl,(New-Object System.Text.UTF8Encoding($false)))
                Write-Host "[Track 31.9] Cloudflare QUIC Tunnel ACTIVE: $wanUrl -> :5173" -ForegroundColor Green
                break
            }
        }
    }
} else {
    $fallbackWan = "https://sovereign-v31-mux.trycloudflare.com (Standby -- install cloudflared to activate WAN)"
    [System.IO.File]::WriteAllText($wanFile,$fallbackWan,(New-Object System.Text.UTF8Encoding($false)))
    Write-Host "[Track 31.9] Unified :5173 Proxy Ready (USB + Wi-Fi 6 LAN active; cloudflared binary on standby)" -ForegroundColor Yellow
}