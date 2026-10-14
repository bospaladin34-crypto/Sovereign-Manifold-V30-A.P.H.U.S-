Write-Host "=== Gracefully Stopping Sovereign Manifold Services ===" -ForegroundColor Yellow

# 1. Stop Mobile Edge Daemons
$p10 = "58170DLCR0004V"
$p8  = "3A121FDJH00BW5"
$devList = & adb devices

if ($devList -match $p10) {
    & adb -s $p10 shell "sh /sdcard/act_omega/p2p_shard_daemon.sh --stop"
    Write-Host "  Pixel 10 Daemon : Stopped" -ForegroundColor Green
}
if ($devList -match $p8) {
    & adb -s $p8 shell "sh /sdcard/act_omega/p2p_shard_daemon.sh --stop"
    Write-Host "  Pixel 8 Daemon  : Stopped" -ForegroundColor Green
}

# 2. Stop Host Background Processes
Get-Process -Name "p2p_swarm_node" -ErrorAction SilentlyContinue | Stop-Process -Force
Write-Host "  P2P Swarm Node  : Terminated" -ForegroundColor Green

Get-Process -Name "deno" -ErrorAction SilentlyContinue | Stop-Process -Force
Write-Host "  Deno Gateway    : Terminated" -ForegroundColor Green

Write-Host "Cluster stopped cleanly." -ForegroundColor Cyan