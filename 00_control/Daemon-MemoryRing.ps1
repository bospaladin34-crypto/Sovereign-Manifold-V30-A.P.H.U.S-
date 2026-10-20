# C:\sovereign_manifold_v31\00_control\Daemon-MemoryRing.ps1
# ACT-Omega Net v37.0.0 (SH4Z v3700) Watchdog, Pixel 8 P8-APEX Non-Root Booster & Bi-Temporal WAL Healer
$ErrorActionPreference = "SilentlyContinue"
$root = "C:\sovereign_manifold_v31"
$p8Serial = "3A121FDJH00BW5"
$p10Serial = "58170DLCR0004V"

# Initial Pixel 8 P8-APEX Non-Root Performance Lock on Startup
cmd.exe /c "adb.exe -s $p8Serial shell svc power stayon usb >nul 2>&1"
cmd.exe /c "adb.exe -s $p8Serial shell dumpsys deviceidle disable >nul 2>&1"
cmd.exe /c "adb.exe -s $p8Serial shell cmd deviceidle whitelist +com.actomega.manifold >nul 2>&1"
cmd.exe /c "adb.exe -s $p8Serial shell cmd power set-fixed-performance-mode-enabled true >nul 2>&1"
cmd.exe /c "adb.exe -s $p8Serial shell cmd thermalservice override-status 0 >nul 2>&1"

while ($true) {
    foreach ($ser in @($p8Serial, $p10Serial)) {
        cmd.exe /c "adb.exe -s $ser reverse tcp:8097 tcp:8097 >nul 2>&1"
        cmd.exe /c "adb.exe -s $ser reverse tcp:5173 tcp:5173 >nul 2>&1"
    }
    # Pixel 8 43.0C Thermal Safety Guard: keep fixed-performance + thermal override 0 unless battery temp > 430 (43.0C)
    $batOut = cmd.exe /c "adb.exe -s $p8Serial shell dumpsys battery"
    $tempTenths = 316
    foreach ($ln in $batOut) {
        if ($ln -match "temperature:\s*(\d+)") {
            $tempTenths = [int]$Matches[1]
        }
    }
    if ($tempTenths -gt 430) {
        cmd.exe /c "adb.exe -s $p8Serial shell cmd thermalservice reset >nul 2>&1"
        cmd.exe /c "adb.exe -s $p8Serial shell cmd power set-fixed-performance-mode-enabled false >nul 2>&1"
    } else {
        cmd.exe /c "adb.exe -s $p8Serial shell cmd power set-fixed-performance-mode-enabled true >nul 2>&1"
        cmd.exe /c "adb.exe -s $p8Serial shell cmd thermalservice override-status 0 >nul 2>&1"
    }
    $sw = Get-Process -Name "v31_swarm" -ErrorAction SilentlyContinue
    if (-not $sw) {
        $exe = "C:\sovereign_manifold_v31\01_l0_rust\target\release\v31_swarm.exe"
        if (Test-Path $exe) {
            Start-Process -FilePath $exe -WorkingDirectory $root -WindowStyle Minimized
        }
    }
    $cf = Get-Process -Name "cloudflared" -ErrorAction SilentlyContinue
    if (-not $cf) {
        $cfg = "C:\sovereign_manifold_v31\00_control\cloudflare_named_config.yml"
        if (Test-Path $cfg) {
            Start-Process -FilePath "cloudflared.exe" -ArgumentList @("tunnel", "--config", $cfg, "run", "sovereign-manifold") -WindowStyle Minimized
        }
    }
    Start-Sleep -Seconds 10
}
