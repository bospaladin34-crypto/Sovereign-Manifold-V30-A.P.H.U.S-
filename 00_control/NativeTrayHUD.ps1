# NativeTrayHUD.ps1 - Launcher and status checker for Windows 11 Native Tray HUD
param(
    [switch]$Build,
    [switch]$Restart,
    [switch]$Status
)

$ErrorActionPreference = "Stop"
$root = "C:\sovereign_manifold_v31"
$hudExe = "$root\SovereignCockpitHUD.exe"
$buildScript = "$root\00_control\Win11_Native_Tray_HUD\Build-NativeTrayHud.ps1"

if ($Build) {
    Write-Host "Compiling and mirroring SovereignCockpitHUD.exe via Build-NativeTrayHud.ps1..." -ForegroundColor Cyan
    & powershell -File $buildScript
    if ($LASTEXITCODE -ne 0) { throw "Build failed with exit code $LASTEXITCODE" }
}

if ($Restart) {
    Write-Host "Restarting SovereignCockpitHUD.exe..." -ForegroundColor Cyan
    Get-Process -Name "SovereignCockpitHUD" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 600
    if (Test-Path $hudExe) {
        Start-Process -FilePath $hudExe
        Write-Host "[OK] SovereignCockpitHUD.exe launched." -ForegroundColor Green
    }
}

$proc = Get-Process -Name "SovereignCockpitHUD" -ErrorAction SilentlyContinue
if ($proc) {
    Write-Host "SovereignCockpitHUD is RUNNING (PID: $($proc.Id)) - v60.0.0 (CHAIN 270 | 690 QED | 3.04M Synapses)" -ForegroundColor Green
} else {
    Write-Host "SovereignCockpitHUD is STOPPED" -ForegroundColor Yellow
}
