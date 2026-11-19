# C:\sovereign_manifold_v31\00_control\Daemon-MemoryRing.ps1
# ACT-Omega Net v33.0.0 (SH4Z v3300) Always-On Cluster Watchdog, 15.965 Hz Decadic Sync & ADB Healer
$ErrorActionPreference = "SilentlyContinue"
$root = "C:\sovereign_manifold_v31"
while ($true) {
    $adbTargets = @()
    $adbLines = adb.exe devices -l 2>$null
    foreach ($l in $adbLines) {
        if ($l -match "^(\S+)\s+device\b" -and ($l -match "model:Pixel_8|product:shiba|model:Pixel_10|product:frankel|192\.168\.137\.")) {
            $adbTargets += $Matches[1]
        }
    }
    $cfgFile = "C:\Users\Nbell\.act_omega_adb_devices.json"
    if ($adbTargets.Count -eq 0 -and (Test-Path $cfgFile)) {
        try {
            $cfg = Get-Content -Raw $cfgFile | ConvertFrom-Json
            if ($cfg.pixel8.serial) { $adbTargets += [string]$cfg.pixel8.serial }
            if ($cfg.pixel10.serial) { $adbTargets += [string]$cfg.pixel10.serial }
        } catch {}
    }
    foreach ($ser in $adbTargets) {
        cmd.exe /c "adb.exe -s $ser reverse tcp:8097 tcp:8097 >nul 2>&1"
        cmd.exe /c "adb.exe -s $ser reverse tcp:5173 tcp:5173 >nul 2>&1"
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
