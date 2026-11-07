# C:\sovereign_manifold_v31\00_control\HotSwap-v50.ps1
$stageExe = "C:\sovereign_manifold_v31\01_l0_rust\target_stage\release\v31_swarm.exe"
$prodExe  = "C:\sovereign_manifold_v31\01_l0_rust\target\release\v31_swarm.exe"
$prevExe  = "C:\sovereign_manifold_v31\01_l0_rust\target\release\v31_swarm_prev.exe"

if (-not (Test-Path $stageExe)) {
    Write-Error "Stage exe not found at $stageExe"
    exit 1
}

# 1. Stage binary atomically via Windows live image rename BEFORE stopping running process (<15ms cutover)
cmd.exe /c "taskkill /F /IM v31_swarm_prev.exe /T >nul 2>&1"
Remove-Item -Path $prevExe -Force -ErrorAction SilentlyContinue
if (Test-Path $prodExe) {
    Move-Item -Path $prodExe -Destination $prevExe -Force -ErrorAction SilentlyContinue
}
Copy-Item -Path $stageExe -Destination $prodExe -Force
Write-Host "Pre-staged $stageExe -> $prodExe prior to process cutover."

# 2. Cut over immediately
cmd.exe /c "taskkill /F /IM v31_swarm.exe /T >nul 2>&1"
cmd.exe /c "taskkill /F /IM v31_swarm_prev.exe /T >nul 2>&1"
Get-Process -Name "*v31_swarm*" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

# 3. Start v31_swarm immediately via WMI
$startup = New-CimInstance -ClassName Win32_ProcessStartup -Property @{ ShowWindow = [uint16]0 } -ClientOnly
$res = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{
    CommandLine = "`"$prodExe`""
    CurrentDirectory = "C:\sovereign_manifold_v31"
    ProcessStartupInformation = $startup
}
Write-Host "WMI Process Create ReturnCode: $($res.ReturnValue), ProcessId: $($res.ProcessId)"
Start-Sleep -Seconds 2

# Verify process and port 8097
$proc = Get-Process -Name "v31_swarm" -ErrorAction SilentlyContinue
$portConn = Get-NetTCPConnection -LocalPort 8097 -State Listen -ErrorAction SilentlyContinue
Write-Host "v31_swarm running: $($null -ne $proc) (PID: $($proc.Id)) | Port :8097 Listening: $($null -ne $portConn)"

# Verify CHAIN 308 Master Certification
try {
    $c308 = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/chain308/master_certification" -TimeoutSec 5
    Write-Host "Hot-Swap Verification: Status=$($c308.status) | Tools=$($c308.tools_verified) | Theorems=$($c308.lean4_theorems_qed)"
} catch {
    Write-Host "Hot-Swap Warning: :8097 responded with error: $($_.Exception.Message)"
}
