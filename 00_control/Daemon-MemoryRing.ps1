# ==============================================================================
# C:\sovereign_manifold_v31\00_control\Daemon-MemoryRing.ps1
# ACT-Omega Net v32.6.2 Zero-ADB-Contention Auto-Heal Cluster & Tunnel Watchdog
#   - Monitors v31_swarm.exe (:8097 & :5173) and cloudflared.exe every 15s
#   - Automatically restarts either daemon if it ever exits or drops
#   - Uses named config 00_control\cloudflare_named_config.yml when present,
#     or falls back to HTTP/2 Post-Quantum tunnel on http://127.0.0.1:5173
#   - Strictly 0 ADB calls so USB connections to Pixel 10 & Pixel 8 are untouched
# ==============================================================================
$ErrorActionPreference = "SilentlyContinue";
$root = "C:\sovereign_manifold_v31";
$swarmExe = "C:\sovereign_manifold_v31\01_l0_rust\target\release\v31_swarm.exe";
$cfExe = "C:\sovereign_manifold_v31\00_control\cloudflared.exe";
$namedCfg = "C:\sovereign_manifold_v31\00_control\cloudflare_named_config.yml";
$cfLog = "C:\sovereign_manifold_v31\00_control\cloudflared_watchdog.log";

while ($true) {
  $swProc = Get-Process -Name "v31_swarm" -ErrorAction SilentlyContinue;
  if ($null -eq $swProc -and (Test-Path $swarmExe)) {
    Start-Process -FilePath $swarmExe -WorkingDirectory $root -WindowStyle Hidden;
  }

  $cfProc = Get-Process -Name "cloudflared" -ErrorAction SilentlyContinue;
  if ($null -eq $cfProc -and (Test-Path $cfExe)) {
    if (Test-Path $namedCfg) {
      $argNamed = "tunnel --config `"$namedCfg`" --protocol http2 --post-quantum run sovereign-manifold";
      Start-Process -FilePath $cfExe -ArgumentList $argNamed -WorkingDirectory $root -WindowStyle Hidden;
    } else {
      $argQuick = "tunnel --url http://127.0.0.1:5173 --protocol http2 --post-quantum --logfile `"$cfLog`"";
      Start-Process -FilePath $cfExe -ArgumentList $argQuick -WorkingDirectory $root -WindowStyle Hidden;
    }
  }

  Start-Sleep -Seconds 15;
}
