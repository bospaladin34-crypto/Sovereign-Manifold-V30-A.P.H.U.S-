# C:\sovereign_manifold_v31\00_control\Daemon-MemoryRing.ps1
# ACT-Omega Net v43.0.0 (SH4Z v4300 TLV) Watchdog, Atomic Hot-Swapper, Pixel 8 P8-APEX Booster & System Profile Healer
$ErrorActionPreference = "SilentlyContinue"
$root = "C:\sovereign_manifold_v31"
$p8Serial = "3A121FDJH00BW5"
$p10Serial = "58170DLCR0004V"

# 1. Heal System-Wide PowerShell Profile (C:\Windows\System32\WindowsPowerShell\v1.0\profile.ps1) if unquoted lines exist
$sysProfile = "C:\Windows\System32\WindowsPowerShell\v1.0\profile.ps1"
if (Test-Path $sysProfile) {
    $rawSys = Get-Content -Raw $sysProfile
    if ($rawSys -match "Aperiodic Law") {
        $cleanSysProfile = @'
# ACT-Omega Sovereign Manifold System Profile (v43.0.0 SH4Z v4300 TLV)
# 1. Zero-Square-Bracket & Zero-Mock Muse Mandate
# 2. 1:1 Shard-to-Neuron Connectome Bijection (21,120 Shards == 21,120 Neurons)
# 3. Aperiodic Law: Prioritize order without repetition; treat lattices as quasicrystals.
# 4. ER=EPR: Address non-local dependencies via quantum threads.
# 5. Entropy Preservation: Maintain von Neumann entropy: S_vN = -Tr(rho ln rho).
'@
        Set-Content -Path $sysProfile -Value $cleanSysProfile -Encoding UTF8 -Force
    }
}

# 2. Immediate Atomic Hot-Swap Helper
function Invoke-SovereignHotSwap {
    $stageExe = "C:\sovereign_manifold_v31\01_l0_rust\target_stage\release\v31_swarm.exe"
    $prodExe  = "C:\sovereign_manifold_v31\01_l0_rust\target\release\v31_swarm.exe"
    $trigFile = "C:\sovereign_manifold_v31\00_control\hotswap.trigger"
    $needSwap = (Test-Path $trigFile)
    if ((-not $needSwap) -and (Test-Path $stageExe) -and (Test-Path $prodExe)) {
        $hStage = (Get-FileHash -Path $stageExe -Algorithm SHA256).Hash
        $hProd  = (Get-FileHash -Path $prodExe  -Algorithm SHA256).Hash
        if ($hStage -and ($hStage -ne $hProd)) {
            $needSwap = $true
        }
    }
    if ($needSwap -and (Test-Path $stageExe)) {
        cmd.exe /c "taskkill /F /IM v31_swarm.exe /T >nul 2>&1"
        Stop-Process -Name "v31_swarm" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 500
        Copy-Item -Path $stageExe -Destination $prodExe -Force
        Remove-Item -Path $trigFile -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "C:\sovereign_manifold_v31\01_l0_rust\target\release\v31_swarm.old.exe" -Force -ErrorAction SilentlyContinue
        Start-Process -FilePath $prodExe -WorkingDirectory $root -WindowStyle Minimized
    }
}

Invoke-SovereignHotSwap

# 3. Initial Pixel 8 P8-APEX Non-Root Performance Lock on Startup
cmd.exe /c "adb.exe -s $p8Serial shell svc power stayon usb >nul 2>&1"
cmd.exe /c "adb.exe -s $p8Serial shell dumpsys deviceidle disable >nul 2>&1"
cmd.exe /c "adb.exe -s $p8Serial shell cmd deviceidle whitelist +com.actomega.manifold >nul 2>&1"
cmd.exe /c "adb.exe -s $p8Serial shell cmd power set-fixed-performance-mode-enabled true >nul 2>&1"
cmd.exe /c "adb.exe -s $p8Serial shell cmd thermalservice override-status 0 >nul 2>&1"

while ($true) {
    Invoke-SovereignHotSwap
    $prodExe = "C:\sovereign_manifold_v31\01_l0_rust\target\release\v31_swarm.exe"
    $sw = Get-Process -Name "v31_swarm" -ErrorAction SilentlyContinue
    if (-not $sw) {
        if (Test-Path $prodExe) {
            Start-Process -FilePath $prodExe -WorkingDirectory $root -WindowStyle Minimized
        }
    }
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
    $cf = Get-Process -Name "cloudflared" -ErrorAction SilentlyContinue
    if (-not $cf) {
        $cfg = "C:\sovereign_manifold_v31\00_control\cloudflare_named_config.yml"
        if (Test-Path $cfg) {
            Start-Process -FilePath "cloudflared.exe" -ArgumentList @("tunnel", "--config", $cfg, "run", "sovereign-manifold") -WindowStyle Minimized
        }
    }
    Start-Sleep -Seconds 10
}
