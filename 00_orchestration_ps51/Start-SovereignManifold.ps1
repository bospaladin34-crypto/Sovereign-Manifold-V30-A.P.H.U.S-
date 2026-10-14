Write-Host "====================================================" -ForegroundColor Cyan;
Write-Host "ACT-Omega v30.0: Starting Sovereign Manifold Cluster" -ForegroundColor Cyan;
Write-Host "Geodesic Anchor: Missoula, MT (15.0 Hz Carrier Clock)" -ForegroundColor Cyan;
Write-Host "====================================================" -ForegroundColor Cyan;

$root = "C:\sovereign_manifold_v30";

# 1. Arm ADB Reverse Tunnels (Literal Serials)
Write-Host "`n[1. Configuring Mobile Edge Tunnels]" -ForegroundColor Yellow;
$devList = (& adb devices);

if ($devList -match "58170DLCR0004V") {
    & adb -s 58170DLCR0004V reverse tcp:8097 tcp:8097;
    & adb -s 58170DLCR0004V reverse tcp:8098 tcp:8098;
    & adb -s 58170DLCR0004V reverse tcp:8099 tcp:8099;
    Write-Host "  Pixel 10 (Tensor G5) : Tunnels Armed (8097, 8098, 8099)" -ForegroundColor Green;
    & adb -s 58170DLCR0004V shell "nohup sh /sdcard/act_omega/p2p_shard_daemon.sh > /sdcard/act_omega/daemon.log 2>&1 &";
} else {
    Write-Host "  Pixel 10 (Tensor G5) : Skipped (Not Attached)" -ForegroundColor DarkGray;
};

if ($devList -match "3A121FDJH00BW5") {
    & adb -s 3A121FDJH00BW5 reverse tcp:8097 tcp:8097;
    Write-Host "  Pixel 8 (Tensor G3)  : Tunnel Armed (8097)" -ForegroundColor Green;
    & adb -s 3A121FDJH00BW5 shell "nohup sh /sdcard/act_omega/p2p_shard_daemon.sh > /sdcard/act_omega/daemon.log 2>&1 &";
} else {
    Write-Host "  Pixel 8 (Tensor G3)  : Skipped (Not Attached)" -ForegroundColor DarkGray;
};

# 2. Host Port Check & Launch
Write-Host "`n[2. Verifying Host Services]" -ForegroundColor Yellow;

$p8097 = (Test-NetConnection -ComputerName "127.0.0.1" -Port 8097 -WarningAction SilentlyContinue).TcpTestSucceeded;
if (-not $p8097) {
    Write-Host "  Launching P2P Swarm Node (Port 8097)..." -ForegroundColor Yellow;
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoExit", "-Command", "Set-Location '$root\01_l0_core'; .\target\release\p2p_swarm_node.exe";
    Start-Sleep -Seconds 2;
} else {
    Write-Host "  P2P Swarm Node (Port 8097) : Already Running" -ForegroundColor Green;
};

$p8099 = (Test-NetConnection -ComputerName "127.0.0.1" -Port 8099 -WarningAction SilentlyContinue).TcpTestSucceeded;
if (-not $p8099) {
    Write-Host "  Launching Deno L2 Gateway (Ports 8098/8099)..." -ForegroundColor Yellow;
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoExit", "-Command", "Set-Location '$root\02_gateway_l2'; deno run -A --unstable-net server.ts";
    Start-Sleep -Seconds 2;
} else {
    Write-Host "  Deno L2 Gateway (Port 8099) : Already Running" -ForegroundColor Green;
};

$p5173 = (Test-NetConnection -ComputerName "127.0.0.1" -Port 5173 -WarningAction SilentlyContinue).TcpTestSucceeded;
if (-not $p5173) {
    Write-Host "  Launching WebGPU Cockpit HUD (Port 5173)..." -ForegroundColor Yellow;
    Start-Process -FilePath "powershell.exe" -ArgumentList "-NoExit", "-Command", "Set-Location '$root\05_hud_webgpu'; npm run dev";
    Start-Sleep -Seconds 2;
} else {
    Write-Host "  WebGPU Cockpit HUD (Port 5173) : Already Running" -ForegroundColor Green;
};

Start-Sleep -Seconds 1;
& "$root\00_orchestration_ps51\Test-SovereignManifold.ps1";