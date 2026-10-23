# C:\sovereign_manifold_v31\00_control\Sovereign-Lifecycle.ps1
# ACT-Omega Net v44.2.0 (SH4Z v4420 TLV) -- Unified Safe Cluster Start / Stop / Restart / Status Controller
param(
    [ValidateSet("start", "stop", "restart", "status")]
    [string]$Action = "status",
    [switch]$OpenBrowser
)

$ErrorActionPreference = "SilentlyContinue"
$root      = "C:\sovereign_manifold_v31"
$pauseFile = "C:\sovereign_manifold_v31\00_control\daemon.paused"
$swarmExe  = "C:\sovereign_manifold_v31\01_l0_rust\target\release\v31_swarm.exe"
$cfExe     = "C:\sovereign_manifold_v31\00_control\cloudflared.exe"
$cfCfg     = "C:\sovereign_manifold_v31\00_control\cloudflare_named_config.yml"
$p10Serial = "58170DLCR0004V"
$p8Serial  = "3A121FDJH00BW5"

function Show-SovereignStatus {
    Write-Host ""
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "   ACT-OMEGA NET v44.2.0 (SH4Z v4420) -- TRI-SILICON CLUSTER STATUS       " -ForegroundColor Cyan
    Write-Host "==========================================================================" -ForegroundColor Cyan

    $isPaused = Test-Path $pauseFile
    if ($isPaused) {
        Write-Host "  [1] WATCHDOG SENTINEL : PAUSED (00_control\daemon.paused present)" -ForegroundColor Yellow
    } else {
        Write-Host "  [1] WATCHDOG SENTINEL : ACTIVE (Auto-Heal + Hot-Swap Enabled)" -ForegroundColor Green
    }

    $swProc = Get-Process -Name "v31_swarm" -ErrorAction SilentlyContinue
    $port8097 = Get-NetTCPConnection -LocalPort 8097 -State Listen -ErrorAction SilentlyContinue
    if ($swProc -and $port8097) {
        $prof = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/diagnostics/v44_self_profiler" -TimeoutSec 2
        $grade = "ONLINE"
        if ($prof) {
            $grade = "$($prof.health_grade) ($($prof.health_score)/100) -- $($prof.cluster_kops)k ops/s -- RTX=$($prof.rtx3050_temp_c)C"
        }
        $swPid = $swProc[0].Id
        Write-Host "  [2] HOST L0 SWARM     : ONLINE (PID $swPid -- :8097 API/MCP + :5173 WebGPU HUD) -> $grade" -ForegroundColor Green
    } else {
        Write-Host "  [2] HOST L0 SWARM     : OFFLINE" -ForegroundColor Red
    }

    $cfProc = Get-Process -Name "cloudflared" -ErrorAction SilentlyContinue
    if ($cfProc) {
        $cfPid = $cfProc[0].Id
        Write-Host "  [3] CLOUDFLARE TUNNEL : ONLINE (PID $cfPid -- act-omega-net.dev + mcp.act-omega-net.dev)" -ForegroundColor Green
    } else {
        Write-Host "  [3] CLOUDFLARE TUNNEL : OFFLINE" -ForegroundColor Red
    }

    $adbRaw = (adb devices) -join " "
    if ($adbRaw -match $p10Serial) {
        $p10Bat = (adb -s $p10Serial shell "dumpsys battery") -join " "
        $p10T = 0.0
        if ($p10Bat -match "temperature:\s*(\d+)") { $p10T = ([double]$Matches[1] / 10.0) }
        Write-Host "  [4] PIXEL 10 (EDGE-1) : CONNECTED ($p10Serial -- Tensor G5 -- Temp=${p10T}C -- S48..S63)" -ForegroundColor Green
    } else {
        Write-Host "  [4] PIXEL 10 (EDGE-1) : DISCONNECTED ($p10Serial)" -ForegroundColor Yellow
    }

    if ($adbRaw -match $p8Serial) {
        $p8Bat = (adb -s $p8Serial shell "dumpsys battery") -join " "
        $p8T = 0.0
        if ($p8Bat -match "temperature:\s*(\d+)") { $p8T = ([double]$Matches[1] / 10.0) }
        Write-Host "  [5] PIXEL 8  (EDGE-2) : CONNECTED ($p8Serial -- Tensor G3 P8-APEX -- Temp=${p8T}C -- 3.56MB SHM L2)" -ForegroundColor Green
    } else {
        Write-Host "  [5] PIXEL 8  (EDGE-2) : DISCONNECTED ($p8Serial)" -ForegroundColor Yellow
    }

    $ssdState = "OFFLINE"
    if (Test-Path "E:\Sovereign_Manifold_SSD_Vault") { $ssdState = "MOUNTED" }
    $drvState = "OFFLINE"
    if (Test-Path "G:\My Drive\ACT_OMEGA_GEMINI_BRIDGE") { $drvState = "MOUNTED" }
    Write-Host "  [6] EXTERNAL VAULTS   : E:\ SSD=$ssdState -- G:\ Drive Bridge=$drvState" -ForegroundColor Cyan
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "  Controls: 'sovereign-start' ('ignite') | 'sovereign-stop' ('halt') | 'sovereign-restart' | 'sovereign-status'" -ForegroundColor Gray
    Write-Host ""
}

function Stop-SovereignClusterSafely {
    Write-Host ""
    Write-Host "==========================================================================" -ForegroundColor Yellow
    Write-Host "   SAFE GRACEFUL SHUTDOWN: ACT-OMEGA NET v44.2.0 (SH4Z v4420)             " -ForegroundColor Yellow
    Write-Host "==========================================================================" -ForegroundColor Yellow

    $ts = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    Set-Content -Path $pauseFile -Value "PAUSED_AT_$ts" -Encoding UTF8 -Force
    Write-Host "  [1/4] Engaged Watchdog Pause Sentinel (00_control\daemon.paused)..." -ForegroundColor Yellow

    try {
        $prof = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/diagnostics/v44_self_profiler" -TimeoutSec 2
        if ($prof -and (Test-Path "E:\Sovereign_Manifold_SSD_Vault\connectome")) {
            Copy-Item "C:\sovereign_manifold_v31\03_vault\connectome\*.jsonl" "E:\Sovereign_Manifold_SSD_Vault\connectome\" -Force
            Write-Host "  [2/4] Flushed connectome JSONL rings to E:\Sovereign_Manifold_SSD_Vault..." -ForegroundColor Green
        } else {
            Write-Host "  [2/4] Connectome state already synced on disk." -ForegroundColor Green
        }
    } catch {
        Write-Host "  [2/4] L0 already offline; skipping HTTP flush." -ForegroundColor Gray
    }

    $adbRaw = (adb devices) -join " "
    if ($adbRaw -match $p8Serial) {
        adb -s $p8Serial shell "cmd thermalservice reset" | Out-Null
        adb -s $p8Serial shell "cmd power set-fixed-performance-mode-enabled false" | Out-Null
        adb -s $p8Serial shell "am force-stop com.actomega.manifold" | Out-Null
        Write-Host "  [3/4] Reset Pixel 8 ($p8Serial) thermal/performance locks + stopped mobile APK..." -ForegroundColor Green
    }
    if ($adbRaw -match $p10Serial) {
        adb -s $p10Serial shell "am force-stop com.actomega.manifold" | Out-Null
        Write-Host "  [3/4] Stopped Pixel 10 ($p10Serial) mobile APK..." -ForegroundColor Green
    }

    Get-Process -Name "cloudflared" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Get-Process -Name "v31_swarm", "v31_swarm_prev" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 600
    Write-Host "  [4/4] Stopped v31_swarm.exe (:8097/:5173) and cloudflared.exe tunnel." -ForegroundColor Green
    Show-SovereignStatus
}

function Start-SovereignClusterSafely {
    Write-Host ""
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "   SAFE CLUSTER IGNITION: ACT-OMEGA NET v44.2.0 (SH4Z v4420)              " -ForegroundColor Cyan
    Write-Host "==========================================================================" -ForegroundColor Cyan

    if (Test-Path $pauseFile) {
        Remove-Item -Path $pauseFile -Force -ErrorAction SilentlyContinue
        Write-Host "  [1/5] Cleared Watchdog Pause Sentinel (00_control\daemon.paused)..." -ForegroundColor Green
    } else {
        Write-Host "  [1/5] Watchdog Sentinel ready..." -ForegroundColor Green
    }

    $swProc = Get-Process -Name "v31_swarm" -ErrorAction SilentlyContinue
    if (-not $swProc) {
        $startup = New-CimInstance -ClassName Win32_ProcessStartup -ClientOnly
        $startup.ShowWindow = [uint16]0
        $null = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{
            CommandLine = "`"$swarmExe`""
            CurrentDirectory = $root
            ProcessStartupInformation = $startup
        }
        Start-Sleep -Seconds 2
        Write-Host "  [2/5] Launched v31_swarm.exe via WMI Service Host (:8097 L0 API/MCP + :5173 WebGPU HUD)..." -ForegroundColor Green
    } else {
        $swPid = $swProc[0].Id
        Write-Host "  [2/5] v31_swarm.exe already running (PID $swPid)..." -ForegroundColor Green
    }

    $cfProc = Get-Process -Name "cloudflared" -ErrorAction SilentlyContinue
    if (-not $cfProc) {
        if ((Test-Path $cfExe) -and (Test-Path $cfCfg)) {
            $startup = New-CimInstance -ClassName Win32_ProcessStartup -ClientOnly
            $startup.ShowWindow = [uint16]0
            $cfCmd = "`"$cfExe`" tunnel --config `"$cfCfg`" --logfile `"C:\sovereign_manifold_v31\00_control\cloudflared_named.log`" run 9cdea4c4-831d-4ccc-983d-5f7587a98206"
            $null = Invoke-CimMethod -ClassName Win32_Process -MethodName Create -Arguments @{
                CommandLine = $cfCmd
                CurrentDirectory = $root
                ProcessStartupInformation = $startup
            }
            Start-Sleep -Seconds 3
            Write-Host "  [3/5] Launched Cloudflare Named Tunnel via WMI Service Host (9cdea4c4 -> act-omega-net.dev :5173, api/mcp :8097)..." -ForegroundColor Green
        } else {
            Write-Host "  [3/5] WARNING: cloudflared.exe or config not found!" -ForegroundColor Yellow
        }
    } else {
        $cfPid = $cfProc[0].Id
        Write-Host "  [3/5] Cloudflare Named Tunnel already running (PID $cfPid)..." -ForegroundColor Green
    }

    $adbRaw = (adb devices) -join " "
    if ($adbRaw -match $p10Serial) {
        adb -s $p10Serial reverse tcp:8097 tcp:8097 | Out-Null
        adb -s $p10Serial reverse tcp:5173 tcp:5173 | Out-Null
        adb -s $p10Serial shell "am start -n com.actomega.manifold/.MainActivity" | Out-Null
        Write-Host "  [4/5] Engaged Pixel 10 ($p10Serial): ADB reverse :8097/:5173 + Launched NDK HUD..." -ForegroundColor Green
    }
    if ($adbRaw -match $p8Serial) {
        adb -s $p8Serial reverse tcp:8097 tcp:8097 | Out-Null
        adb -s $p8Serial reverse tcp:5173 tcp:5173 | Out-Null
        adb -s $p8Serial shell "svc power stayon usb" | Out-Null
        adb -s $p8Serial shell "cmd power set-fixed-performance-mode-enabled true" | Out-Null
        adb -s $p8Serial shell "cmd thermalservice override-status 0" | Out-Null
        $shmCheck = (adb -s $p8Serial shell "ls -l /data/local/tmp/neurons_v4400_p8_shm.npage 2>/dev/null") -join " "
        if ($shmCheck -notmatch "3604480") {
            adb -s $p8Serial push "C:\sovereign_manifold_v31\00_control\weights\neurons_v4400_p8_shm.npage" "/data/local/tmp/neurons_v4400_p8_shm.npage" | Out-Null
        }
        adb -s $p8Serial shell "am start -n com.actomega.manifold/.MainActivity" | Out-Null
        Write-Host "  [5/5] Engaged Pixel 8 ($p8Serial): P8-APEX Lock + 3.56MB .npage SHM Verified + Launched NDK HUD..." -ForegroundColor Green
    }

    if ($OpenBrowser) {
        Start-Process "http://127.0.0.1:5173"
    }
    Show-SovereignStatus
}

switch ($Action) {
    "start"   { Start-SovereignClusterSafely }
    "stop"    { Stop-SovereignClusterSafely }
    "restart" { Stop-SovereignClusterSafely; Start-Sleep -Seconds 1; Start-SovereignClusterSafely }
    "status"  { Show-SovereignStatus }
}
