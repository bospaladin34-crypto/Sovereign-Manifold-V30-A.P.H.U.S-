$src = "C:\sovereign_manifold_v31\01_l0_rust\target_stage\release\v31_swarm.exe"
$dst = "C:\sovereign_manifold_v31\01_l0_rust\target\release\v31_swarm.exe"

if (-not (Test-Path $src)) {
    Write-Host "Source binary not found at $src" -ForegroundColor Red
    exit 1
}

$srcHash = (Get-FileHash $src -Algorithm SHA256).Hash
Write-Host "New binary built at $src (SHA256: $srcHash)" -ForegroundColor Cyan

Write-Host "Stopping running v31_swarm process..." -ForegroundColor Yellow
Get-Process -Name "v31_swarm" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

Write-Host "Copying binary from target_stage to target\release..." -ForegroundColor Yellow
Copy-Item -Path $src -Destination $dst -Force

$dstHash = (Get-FileHash $dst -Algorithm SHA256).Hash
Write-Host "Destination binary updated (SHA256: $dstHash)" -ForegroundColor Green

if ($srcHash -ne $dstHash) {
    Write-Host "Hash mismatch after copy!" -ForegroundColor Red
    exit 1
}

Write-Host "Starting cluster via Sovereign-Lifecycle.ps1 -Action start..." -ForegroundColor Cyan
& "C:\sovereign_manifold_v31\00_control\Sovereign-Lifecycle.ps1" -Action start

Start-Sleep -Seconds 2

# Verify server is responding
try {
    $resp = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/diagnostics/v44_self_profiler" -TimeoutSec 5
    Write-Host "Server successfully responding on http://127.0.0.1:8097" -ForegroundColor Green
    exit 0
} catch {
    Write-Host "Failed to connect to server: $_" -ForegroundColor Red
    exit 1
}
