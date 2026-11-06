# Build-VesperShimeji.ps1 - Compiles VesperArachneSwarmDroneOverlay.exe and mirrors across canonical paths
param(
    [switch]$NoRestart
)

$ErrorActionPreference = "Stop"

# Terminate running instance if present
cmd.exe /c "taskkill /F /IM VesperArachneSwarmDroneOverlay.exe /T >nul 2>&1"
Get-Process -Name "VesperArachneSwarmDroneOverlay" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Get-CimInstance Win32_Process -Filter "Name = 'VesperArachneSwarmDroneOverlay.exe'" -ErrorAction SilentlyContinue | Invoke-CimMethod -MethodName Terminate -ErrorAction SilentlyContinue | Out-Null
Start-Sleep -Milliseconds 500

$src = "C:\sovereign_manifold_v31\00_control\Win11_Native_Tray_HUD\VesperArachneSwarmDroneOverlay.cs"
$target1 = "C:\sovereign_manifold_v31\00_control\Win11_Native_Tray_HUD\VesperArachneSwarmDroneOverlay.exe"
$target2 = "C:\ACT_OMEGA_MODELS\vesper_arachne_shimeji\VesperArachneSwarmDroneOverlay.exe"
$target3 = "C:\sovereign_manifold_v31\VesperArachneSwarmDroneOverlay.exe"
$mirrorCs = "C:\ACT_OMEGA_MODELS\vesper_arachne_shimeji\VesperArachneSwarmDroneOverlay.cs"

if (-not (Test-Path "C:\ACT_OMEGA_MODELS\vesper_arachne_shimeji")) {
    New-Item -ItemType Directory -Force -Path "C:\ACT_OMEGA_MODELS\vesper_arachne_shimeji" | Out-Null
}

Write-Host "Compiling VesperArachneSwarmDroneOverlay.exe with csc.exe..." -ForegroundColor Cyan
& "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe" /nologo /target:winexe /optimize+ /platform:anycpu /r:System.dll /r:System.Drawing.dll /r:System.Windows.Forms.dll /r:System.Core.dll /out:$target1 $src
if ($LASTEXITCODE -ne 0) { throw "CSC compilation failed with code $LASTEXITCODE" }

Copy-Item -Path $target1 -Destination $target2 -Force
Copy-Item -Path $target1 -Destination $target3 -Force
Copy-Item -Path $src -Destination $mirrorCs -Force

Write-Host "[OK] VesperArachneSwarmDroneOverlay.exe compiled and mirrored successfully across all 3 targets." -ForegroundColor Green
Write-Host "Target1: $((Get-FileHash $target1).Hash)"
Write-Host "Target2: $((Get-FileHash $target2).Hash)"
Write-Host "Target3: $((Get-FileHash $target3).Hash)"
Write-Host "Source:  $((Get-FileHash $src).Hash)"
Write-Host "Mirror:  $((Get-FileHash $mirrorCs).Hash)"

if (-not $NoRestart) {
    Write-Host "Restarting VesperArachneSwarmDroneOverlay via WMI Service Host..." -ForegroundColor Yellow
    $res = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{
        CommandLine = "`"$target1`""
        CurrentDirectory = "C:\sovereign_manifold_v31"
    }
    Start-Sleep -Milliseconds 600
    Write-Host "[OK] Vesper-Arachne Desktop Companion launched (PID: $($res.ProcessId))." -ForegroundColor Green
}
