# C:\sovereign_manifold_v31\00_control\Start-CloudflareTunnel.ps1
# Preserves running cloudflared tunnel if healthy; otherwise starts fresh tunnel
$ErrorActionPreference = "SilentlyContinue"
$root = "C:\sovereign_manifold_v31"
$wanFile = Join-Path $root "03_vault\models\cloudflare_wan_url.txt"
$cfLog = Join-Path $root "00_control\cloudflared_quic.log"
$cfBin = Join-Path $root "00_control\cloudflared.exe"
if(-not (Test-Path $cfBin)){ $cfBin = "cloudflared" }

$runningCf = Get-Process -Name "cloudflared" -ErrorAction SilentlyContinue
$liveUrl = ""
if($runningCf -and (Test-Path $cfLog)){
    $lines = Get-Content -Path $cfLog -ErrorAction SilentlyContinue
    foreach($ln in($lines)){
        if($ln -match "(https://[a-zA-Z0-9\-]+\.trycloudflare\.com)"){
            $liveUrl = $Matches[1]
        }
    }
}

if($liveUrl -eq ""){
    Get-Process -Name "cloudflared" -ErrorAction SilentlyContinue|Stop-Process -Force
    Start-Sleep -Milliseconds 700
    if(Test-Path $cfLog){ Remove-Item $cfLog -Force }
    Start-Process -FilePath $cfBin -ArgumentList "tunnel --url http://127.0.0.1:5173 --no-autoupdate --logfile $cfLog" -WindowStyle Hidden
    for($w = 0; $w -lt 16; $w++){
        Start-Sleep -Milliseconds 750
        if(Test-Path $cfLog){
            $lines = Get-Content -Path $cfLog -ErrorAction SilentlyContinue
            foreach($ln in($lines)){
                if($ln -match "(https://[a-zA-Z0-9\-]+\.trycloudflare\.com)"){
                    $liveUrl = $Matches[1]
                }
            }
        }
        if($liveUrl -ne ""){ break }
    }
}

if($liveUrl -ne ""){
    [System.IO.File]::WriteAllText($wanFile,$liveUrl,(New-Object System.Text.UTF8Encoding($false)))
    Write-Host "[Cloudflare QUIC] LIVE ACTIVE TUNNEL URL: $liveUrl -> http://127.0.0.1:5173" -ForegroundColor Green
}