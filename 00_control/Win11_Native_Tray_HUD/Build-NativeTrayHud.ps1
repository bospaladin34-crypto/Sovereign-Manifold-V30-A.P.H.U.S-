# Build-NativeTrayHud.ps1 - Compiles SovereignCockpitHUD.exe and mirrors across all 3 deployment targets
$ErrorActionPreference = "Stop"

# Stop running instance if present
Get-Process -Name "SovereignCockpitHUD" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 600

$src = "C:\sovereign_manifold_v31\00_control\Win11_Native_Tray_HUD\SovereignTrayAndHud.cs"
$target1 = "C:\sovereign_manifold_v31\00_control\Win11_Native_Tray_HUD\SovereignCockpitHUD.exe"
$target2 = "C:\sovereign_manifold_v31\SovereignCockpitHUD.exe"
$target3 = "C:\sovereign_manifold_v31\docs\SovereignCockpitHUD.exe"
$mirrorCs = "C:\sovereign_manifold_v31\00_control\SovereignCockpitHUD.cs"

# Compile via Framework64 csc.exe
Write-Host "Compiling SovereignCockpitHUD.exe with csc.exe..." -ForegroundColor Cyan
& "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe" /nologo /target:winexe /optimize+ /out:$target1 $src
if ($LASTEXITCODE -ne 0) { throw "CSC compilation failed with code $LASTEXITCODE" }

# Mirror binary and source (using atomic rename on Windows if target2 is locked by a child WebView2/tray handle)
if (Test-Path $target2) {
    Move-Item -Path $target2 -Destination "$target2.old" -Force -ErrorAction SilentlyContinue
}
Copy-Item -Path $target1 -Destination $target2 -Force
Remove-Item -Path "$target2.old" -Force -ErrorAction SilentlyContinue
Copy-Item -Path $target1 -Destination $target3 -Force
Copy-Item -Path $src -Destination $mirrorCs -Force

Write-Host "[OK] SovereignCockpitHUD.exe compiled and mirrored successfully across all 3 targets." -ForegroundColor Green
Write-Host "Target1: $((Get-FileHash $target1).Hash)"
Write-Host "Target2: $((Get-FileHash $target2).Hash)"
Write-Host "Target3: $((Get-FileHash $target3).Hash)"
Write-Host "Source:  $((Get-FileHash $src).Hash)"
Write-Host "Mirror:  $((Get-FileHash $mirrorCs).Hash)"
