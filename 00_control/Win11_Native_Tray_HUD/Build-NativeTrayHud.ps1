# Build-NativeTrayHud.ps1 - Compiles SovereignCockpitHUD.exe & VesperArachneSwarmDroneOverlay.exe across all canonical targets
param(
    [switch]$NoRestart
)

$ErrorActionPreference = "Stop"

# 1. Stop running instances of both HUD and Shimeji Companion to prevent file locking
Write-Host "Terminating active HUD and Shimeji processes..." -ForegroundColor Cyan
cmd.exe /c "taskkill /F /IM SovereignCockpitHUD.exe /T >nul 2>&1"
cmd.exe /c "taskkill /F /IM SovereignTrayAndHud.exe /T >nul 2>&1"
cmd.exe /c "taskkill /F /IM VesperArachneSwarmDroneOverlay.exe /T >nul 2>&1"
Get-Process -Name "SovereignCockpitHUD", "SovereignTrayAndHud", "VesperArachneSwarmDroneOverlay" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Get-CimInstance Win32_Process -Filter "Name = 'SovereignCockpitHUD.exe' or Name = 'SovereignTrayAndHud.exe' or Name = 'VesperArachneSwarmDroneOverlay.exe'" -ErrorAction SilentlyContinue | Invoke-CimMethod -MethodName Terminate -ErrorAction SilentlyContinue | Out-Null
Start-Sleep -Milliseconds 600

$srcHud = "C:\sovereign_manifold_v31\00_control\Win11_Native_Tray_HUD\SovereignTrayAndHud.cs"
$targetHud1 = "C:\sovereign_manifold_v31\00_control\Win11_Native_Tray_HUD\SovereignCockpitHUD.exe"
$targetHudTray = "C:\sovereign_manifold_v31\00_control\Win11_Native_Tray_HUD\SovereignTrayAndHud.exe"
$targetHud2 = "C:\sovereign_manifold_v31\SovereignCockpitHUD.exe"
$targetHud3 = "C:\sovereign_manifold_v31\docs\SovereignCockpitHUD.exe"
$mirrorHudCs = "C:\sovereign_manifold_v31\00_control\SovereignCockpitHUD.cs"

$srcDrone = "C:\sovereign_manifold_v31\00_control\Win11_Native_Tray_HUD\VesperArachneSwarmDroneOverlay.cs"
$droneDir2 = "C:\ACT_OMEGA_MODELS\vesper_arachne_shimeji"
$targetDrone1 = "C:\sovereign_manifold_v31\00_control\Win11_Native_Tray_HUD\VesperArachneSwarmDroneOverlay.exe"
$targetDrone2 = "C:\sovereign_manifold_v31\VesperArachneSwarmDroneOverlay.exe"
$targetDrone3 = Join-Path $droneDir2 "VesperArachneSwarmDroneOverlay.exe"
$mirrorDroneCs = Join-Path $droneDir2 "VesperArachneSwarmDroneOverlay.cs"

if (-not (Test-Path $droneDir2)) {
    New-Item -ItemType Directory -Force -Path $droneDir2 | Out-Null
}

$csc = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"

# 2. Compile SovereignCockpitHUD.exe (v72.2.0 / Ω72)
Write-Host "Compiling SovereignCockpitHUD.exe (v72.2.0 / Ω72) with csc.exe..." -ForegroundColor Cyan
& $csc /nologo /target:winexe /optimize+ /out:$targetHud1 $srcHud
if ($LASTEXITCODE -ne 0) { throw "CSC compilation of SovereignCockpitHUD.exe failed with code $LASTEXITCODE" }

# Mirror SovereignCockpitHUD across targets with atomic rename
Copy-Item -Path $targetHud1 -Destination $targetHudTray -Force
if (Test-Path $targetHud2) {
    Move-Item -Path $targetHud2 -Destination "$targetHud2.old" -Force -ErrorAction SilentlyContinue
}
Copy-Item -Path $targetHud1 -Destination $targetHud2 -Force
Remove-Item -Path "$targetHud2.old" -Force -ErrorAction SilentlyContinue
Copy-Item -Path $targetHud1 -Destination $targetHud3 -Force
Copy-Item -Path $srcHud -Destination $mirrorHudCs -Force

Write-Host "[OK] SovereignCockpitHUD.exe compiled and mirrored successfully across all 3 targets." -ForegroundColor Green
Write-Host "HUD Target1: $((Get-FileHash $targetHud1).Hash)"
Write-Host "HUD Target2: $((Get-FileHash $targetHud2).Hash)"
Write-Host "HUD Target3: $((Get-FileHash $targetHud3).Hash)"
Write-Host "HUD Source:  $((Get-FileHash $srcHud).Hash)"
Write-Host "HUD Mirror:  $((Get-FileHash $mirrorHudCs).Hash)"

# 3. Compile VesperArachneSwarmDroneOverlay.exe
Write-Host "Compiling VesperArachneSwarmDroneOverlay.exe with csc.exe..." -ForegroundColor Cyan
& $csc /nologo /target:winexe /optimize+ /platform:anycpu /r:System.dll /r:System.Drawing.dll /r:System.Windows.Forms.dll /r:System.Core.dll /out:$targetDrone1 $srcDrone
if ($LASTEXITCODE -ne 0) { throw "CSC compilation of VesperArachneSwarmDroneOverlay.exe failed with code $LASTEXITCODE" }

if (Test-Path $targetDrone2) {
    Move-Item -Path $targetDrone2 -Destination "$targetDrone2.old" -Force -ErrorAction SilentlyContinue
}
Copy-Item -Path $targetDrone1 -Destination $targetDrone2 -Force
Remove-Item -Path "$targetDrone2.old" -Force -ErrorAction SilentlyContinue
Copy-Item -Path $targetDrone1 -Destination $targetDrone3 -Force
Copy-Item -Path $srcDrone -Destination $mirrorDroneCs -Force

Write-Host "[OK] VesperArachneSwarmDroneOverlay.exe compiled and mirrored successfully across all 3 targets." -ForegroundColor Green
Write-Host "Drone Target1: $((Get-FileHash $targetDrone1).Hash)"
Write-Host "Drone Target2: $((Get-FileHash $targetDrone2).Hash)"
Write-Host "Drone Target3: $((Get-FileHash $targetDrone3).Hash)"
Write-Host "Drone Source:  $((Get-FileHash $srcDrone).Hash)"
Write-Host "Drone Mirror:  $((Get-FileHash $mirrorDroneCs).Hash)"

# 4. Restart live desktop processes
if (-not $NoRestart) {
    Write-Host "Restarting live desktop processes..." -ForegroundColor Yellow
    $resHud = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = $targetHud1 }
    $resDrone = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{ CommandLine = $targetDrone1 }
    Write-Host "[OK] Live desktop processes launched (HUD PID: $($resHud.ProcessId), Drone PID: $($resDrone.ProcessId))." -ForegroundColor Green
}
