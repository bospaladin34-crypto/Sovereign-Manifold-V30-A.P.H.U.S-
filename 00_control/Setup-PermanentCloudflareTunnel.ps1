param(
    [string]$CloudflareToken = ""
)
$ErrorActionPreference = "SilentlyContinue"
$utf8NoBom =
    New-Object System.Text.UTF8Encoding(0)
Set-Location -Path "C:\sovereign_manifold_v31"

if($CloudflareToken -ne ""){
    Stop-Process -Name "cloudflared" -Force -ErrorAction SilentlyContinue
    $cfArgs =
        "tunnel --no-autoupdate run --token " +
        $CloudflareToken
    Start-Process -FilePath "C:\sovereign_manifold_v31\00_control\cloudflared.exe" -ArgumentList($cfArgs) -WindowStyle Hidden
    Write-Host "[Cloudflare Named Tunnel] Started persistent Zero-Trust Named Tunnel." -ForegroundColor Green
} else {
    $wanFile = "C:\sovereign_manifold_v31\03_vault\models\cloudflare_wan_url.txt"
    $wanUrl =
        ([System.IO.File]::ReadAllText($wanFile)).Trim()
    Write-Host ("[Permanent Beacon Active] Current Tunnel: " + $wanUrl) -ForegroundColor Cyan
    Write-Host "Pixel 10 Permanent Discovery URL: https://raw.githubusercontent.com/bospaladin34-crypto/Sovereign-Manifold-V30-A.P.H.U.S-/vesper_production/03_vault/models/cloudflare_wan_url.txt" -ForegroundColor Green
}