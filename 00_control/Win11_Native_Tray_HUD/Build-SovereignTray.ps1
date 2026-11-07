# Build-SovereignTray.ps1 - Compiles SovereignTrayAndHud.exe & SovereignCockpitHUD.exe (v70.0.0 / Ω70)
$ErrorActionPreference = "Stop"
$csc = "C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe"
$src = "C:\sovereign_manifold_v31\00_control\Win11_Native_Tray_HUD\SovereignTrayAndHud.cs"
$out1 = "C:\sovereign_manifold_v31\00_control\Win11_Native_Tray_HUD\SovereignTrayAndHud.exe"
$out2 = "C:\sovereign_manifold_v31\00_control\Win11_Native_Tray_HUD\SovereignCockpitHUD.exe"
$outRoot = "C:\sovereign_manifold_v31\SovereignCockpitHUD.exe"
$outDocs = "C:\sovereign_manifold_v31\docs\SovereignCockpitHUD.exe"
$mirrorCs = "C:\sovereign_manifold_v31\00_control\SovereignCockpitHUD.cs"

cmd.exe /c "taskkill /F /IM SovereignCockpitHUD.exe /T >nul 2>&1"
cmd.exe /c "taskkill /F /IM SovereignTrayAndHud.exe /T >nul 2>&1"
Start-Sleep -Milliseconds 400

Write-Host "Compiling SovereignTrayAndHud.exe (v70.0.0 / Ω70)..." -ForegroundColor Cyan
& $csc /nologo /target:winexe /optimize+ /out:$out1 $src
if ($LASTEXITCODE -ne 0) { throw "CSC compilation failed with code $LASTEXITCODE" }

Copy-Item $out1 $out2 -Force
Copy-Item $out1 $outRoot -Force
Copy-Item $out1 $outDocs -Force
Copy-Item $src $mirrorCs -Force
Write-Host "[OK] SovereignTrayAndHud.exe compiled with 0 errors and mirrored across all targets." -ForegroundColor Green
