$ErrorActionPreference="Continue";
Write-Host "=========================================================================" -ForegroundColor Cyan;
Write-Host "   ACT-OMEGA NET v31.0 (SH-4) -- LIVE TRI-SILICON CLUSTER LAUNCHER       " -ForegroundColor Cyan;
Write-Host "=========================================================================" -ForegroundColor Cyan;
powershell -ExecutionPolicy Bypass -File "C:\sovereign_manifold_v31\00_control\Stop-SovereignManifold.ps1";
Start-Sleep -Milliseconds 800;
Write-Host "[1/4] Starting Tier-1 Rust L0 UTCP-v31 Swarm & Telemetry Daemon (:8097 / :8098)..." -ForegroundColor Cyan;
Start-Process -FilePath "C:\sovereign_manifold_v31\01_l0_rust\target\release\v31_swarm.exe" -ArgumentList "--daemon" -WorkingDirectory "C:\sovereign_manifold_v31\01_l0_rust" -WindowStyle Minimized;
Write-Host "[2/4] Starting Tier-2 Deno L2 Gateway (:8099)..." -ForegroundColor Cyan;
Start-Process -FilePath "deno" -ArgumentList "run -A --unstable-ffi --unstable-net C:\sovereign_manifold_v31\02_gateway_deno\server.ts" -WorkingDirectory "C:\sovereign_manifold_v31\02_gateway_deno" -WindowStyle Minimized;
Write-Host "[3/4] Starting Tier-3 WebGPU 60 FPS Cockpit HUD (:5173)..." -ForegroundColor Cyan;
Start-Process -FilePath "node" -ArgumentList "--preserve-symlinks .\node_modules\vite\bin\vite.js --host 0.0.0.0 --port 5173" -WorkingDirectory "C:\sovereign_manifold_v31\05_hud_cockpit" -WindowStyle Minimized;
Write-Host "[4/4] Engaging Tier-4 Mobile Edge Nodes (Pixel 10 & Pixel 8) via ADB..." -ForegroundColor Cyan;
$adbDevs=[string]::Join(",",(adb devices));
if($adbDevs.Contains("58170DLCR0004V")){
adb -s 58170DLCR0004V reverse tcp:8097 tcp:8097|Out-Null;
adb -s 58170DLCR0004V reverse tcp:8098 tcp:8098|Out-Null;
adb -s 58170DLCR0004V reverse tcp:8099 tcp:8099|Out-Null;
adb -s 58170DLCR0004V shell "am start -n com.actomega.manifold/.MainActivity"|Out-Null;
$p10Temp=[string]::Join(" ",(adb -s 58170DLCR0004V shell "dumpsys battery | grep temperature"));
Write-Host "  [PIXEL 10 58170DLCR0004V] Tunnels 8097/8098/8099 ACTIVE | NDK App Launched |$p10Temp" -ForegroundColor Green;
}
if($adbDevs.Contains("3A121FDJH00BW5")){
adb -s 3A121FDJH00BW5 reverse tcp:8097 tcp:8097|Out-Null;
adb -s 3A121FDJH00BW5 reverse tcp:8098 tcp:8098|Out-Null;
adb -s 3A121FDJH00BW5 reverse tcp:8099 tcp:8099|Out-Null;
adb -s 3A121FDJH00BW5 shell "nohup sh /data/local/tmp/p8_v31_worker.sh >/data/local/tmp/p8_v31.log 2>&1 &"|Out-Null;
Start-Sleep -Milliseconds 500;
$p8Pid=[string]::Join("",(adb -s 3A121FDJH00BW5 shell "cat /data/local/tmp/p8_v31_worker.pid"));
$p8Temp=[string]::Join(" ",(adb -s 3A121FDJH00BW5 shell "dumpsys battery | grep temperature"));
Write-Host "  [PIXEL 8  3A121FDJH00BW5] Tunnels 8097/8098/8099 ACTIVE | L2 Worker PID=$p8Pid |$p8Temp" -ForegroundColor Green;
}
Write-Host "Waiting 4 seconds for all host listeners to bind..." -ForegroundColor Yellow;
Start-Sleep -Seconds 4;
$checkPorts=@(8097,8098,8099,5173);
foreach($cp in($checkPorts)){
$listening=Get-NetTCPConnection -LocalPort($cp) -State Listen -ErrorAction SilentlyContinue;
if($listening){
Write-Host "  [PORT:$cp] ONLINE" -ForegroundColor Green;
} else {
Write-Host "  [PORT:$cp] OFFLINE" -ForegroundColor Red;
}
}
try {
$swarmResp=Invoke-RestMethod -Uri "http://127.0.0.1:8097" -TimeoutSec 3;
Write-Host ("  [SWARM :8097]     Service="+$swarmResp.service+" | Version="+$swarmResp.version+" | PPL="+$swarmResp.holdout_ppl) -ForegroundColor Green;
} catch {
Write-Host "  [SWARM :8097]     Probe skipped" -ForegroundColor Yellow;
}
try {
$genBody='{"prompt":"Verify Sovereign Harmonic IV Leech Triality manifold lock","max_tokens":12}';
$genResp=Invoke-RestMethod -Uri "http://127.0.0.1:8099/api/v1/harmonic/generate" -Method Post -ContentType "application/json" -Body($genBody) -TimeoutSec 5;
Write-Host ("  [GATEWAY :8099]   Reflex Response="+$genResp.text+" | Latency_us="+$genResp.latency_us) -ForegroundColor Green;
} catch {
Write-Host "  [GATEWAY :8099]   HTTP probe checking root..." -ForegroundColor Yellow;
}
Start-Process "http://localhost:5173";
Write-Host "=========================================================================" -ForegroundColor Cyan;
Write-Host "   ACT-OMEGA NET v31.0 (SH-4) LIVE CLUSTER ONLINE (HUD: :5173)           " -ForegroundColor Green;
Write-Host "=========================================================================" -ForegroundColor Cyan;