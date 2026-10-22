# C:\sovereign_manifold_v31\00_control\HotSwap-v43.ps1
# Elevated Atomic Hot-Swap & System Profile Healer for ACT-Omega Net v43.0.0 (SH4Z v4300 TLV)
$ErrorActionPreference = "SilentlyContinue"
$root = "C:\sovereign_manifold_v31"

# 1. Heal System-Wide PowerShell Profile (C:\Windows\System32\WindowsPowerShell\v1.0\profile.ps1)
$sysProfile = "C:\Windows\System32\WindowsPowerShell\v1.0\profile.ps1"
$cleanSysProfile = @'
# ACT-Omega Sovereign Manifold System Profile (v43.0.0 SH4Z v4300 TLV)
# 1. Zero-Square-Bracket & Zero-Mock Muse Mandate
# 2. 1:1 Shard-to-Neuron Connectome Bijection (21,120 Core + 1,760 Expansion = 22,880 Shards/Neurons)
# 3. Aperiodic Law: Prioritize order without repetition; treat lattices as quasicrystals.
# 4. ER=EPR: Address non-local dependencies via quantum threads.
# 5. Entropy Preservation: Maintain von Neumann entropy: S_vN = -Tr(rho ln rho).
'@
Set-Content -Path $sysProfile -Value $cleanSysProfile -Encoding UTF8 -Force

# 2. Stop elevated v31_swarm.exe, copy staged v43.0.0 binary, and restart via non-elevated Scheduled Task
$stageExe = "C:\sovereign_manifold_v31\01_l0_rust\target_stage\release\v31_swarm.exe"
$prodExe  = "C:\sovereign_manifold_v31\01_l0_rust\target\release\v31_swarm.exe"

cmd.exe /c "taskkill /F /IM v31_swarm.exe /T >nul 2>&1"
Stop-Process -Name "v31_swarm" -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 600

if (Test-Path $stageExe) {
    Copy-Item -Path $stageExe -Destination $prodExe -Force
}
Remove-Item -Path "C:\sovereign_manifold_v31\01_l0_rust\target\release\v31_swarm.old.exe" -Force -ErrorAction SilentlyContinue

# Update SovereignManifold_AlwaysOn_v32_9 so it can run even on laptop battery power, then start it non-elevated
$ts = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Hours 72)
Set-ScheduledTask -TaskName "SovereignManifold_AlwaysOn_v32_9" -Settings $ts -ErrorAction SilentlyContinue
schtasks /End /TN "SovereignManifold_AlwaysOn_v32_9" >$null 2>&1
Start-Sleep -Milliseconds 300
schtasks /Run /TN "SovereignManifold_AlwaysOn_v32_9" >$null 2>&1
Start-Sleep -Seconds 2
if (-not (Get-Process -Name "v31_swarm" -ErrorAction SilentlyContinue)) {
    Start-Process -FilePath $prodExe -WorkingDirectory $root -WindowStyle Minimized
}

# 3. Re-bind ADB reverse tunnels on Pixel 10 & Pixel 8
foreach ($ser in @("58170DLCR0004V", "3A121FDJH00BW5")) {
    cmd.exe /c "adb.exe -s $ser reverse tcp:8097 tcp:8097 >nul 2>&1"
    cmd.exe /c "adb.exe -s $ser reverse tcp:5173 tcp:5173 >nul 2>&1"
}
