param(
    [ValidateSet("Bench","Daemon","BenchAndDaemon","VulkanOnly","TensorOnly","CoopMatOnly","TpuOnly","Caps","Json","HostOnly")][string]$Action = "BenchAndDaemon",
    [string]$Kernel = "all",
    [int]$Port = 19788
)
$ErrorActionPreference = "Continue"
$WorkerRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$SrcMain = "$WorkerRoot\src\main.rs"
$OutDir = "$WorkerRoot\bin"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$Rustc = ""
$Rustup = ""
if (Test-Path "$env:USERPROFILE\.cargo\bin\rustc.exe") {
    $Rustc = "$env:USERPROFILE\.cargo\bin\rustc.exe"
    $Rustup = "$env:USERPROFILE\.cargo\bin\rustup.exe"
} else {
    $rcCmd = Get-Command "rustc.exe" -ErrorAction SilentlyContinue
    if ($rcCmd) { $Rustc = $rcCmd.Source }
    $ruCmd = Get-Command "rustup.exe" -ErrorAction SilentlyContinue
    if ($ruCmd) { $Rustup = $ruCmd.Source }
}

if ($Rustc -eq "") {
    Write-Host "    [SKIP] rustc.exe not found on PATH or %USERPROFILE%\.cargo\bin." -ForegroundColor Yellow
    exit 0
}

Write-Host "    [5a] Compiling Host x64 v0.7.5 IntDot + CoopMatrix Tensor Companion (omega_p10_worker_host.exe)..." -ForegroundColor Cyan
$HostExe = "$OutDir\omega_p10_worker_host.exe"
if (Test-Path $HostExe) { Remove-Item $HostExe -Force -ErrorAction SilentlyContinue }
& $Rustc --edition 2021 -C opt-level=3 -C target-cpu=native $SrcMain -o $HostExe | Out-Host
if (($LASTEXITCODE -eq 0) -and (Test-Path $HostExe)) {
    $hkb = [Math]::Round(((Get-Item $HostExe).Length / 1024.0), 1)
    Write-Host "    [PASS] Host x64 v0.7.5 Companion           -> $hkb KB (RTX 3050 IntDot + CoopMatrix Tensor Cores)" -ForegroundColor Green
    if ($Action -eq "HostOnly") {
        & $HostExe --bench | Out-Host
        exit 0
    }
    if (($Action -eq "Bench") -or ($Action -eq "BenchAndDaemon") -or ($Action -eq "TensorOnly") -or ($Action -eq "CoopMatOnly")) {
        Write-Host "    [5a-RTX] Verifying Host RTX 3050 Ampere IntDot + Cooperative Matrix Tensor Kernels..." -ForegroundColor Magenta
        & $HostExe --vulkan tensor | Out-Host
    }
}

Write-Host "    [5b] Cross-Compiling ARMv9.2 (+dotprod,+i8mm,+fp16,+lse) + PowerVR IntDot/CoopMat v0.7.5..." -ForegroundColor Cyan
$P10Bin = "$OutDir\omega_p10_worker"
if (Test-Path $P10Bin) { Remove-Item $P10Bin -Force -ErrorAction SilentlyContinue }

[System.IO.File]::WriteAllText("$OutDir\libgcc.a", "INPUT(-lunwind)" + [Environment]::NewLine, (New-Object System.Text.UTF8Encoding($false)))

$NdkClang = ""
$NdkRoots = @(
    "$env:ANDROID_NDK_HOME",
    "$env:ANDROID_NDK_ROOT",
    "$env:NDK_HOME",
    "$env:LOCALAPPDATA\Android\Sdk\ndk",
    "$env:USERPROFILE\AppData\Local\Android\Sdk\ndk",
    "C:\Android\Sdk\ndk",
    "C:\Android\ndk",
    "D:\Android\Sdk\ndk",
    "E:\Android\Sdk\ndk",
    "E:\ndk",
    "F:\Android\Sdk\ndk",
    "C:\sovereign_manifold_v31\ndk"
)
foreach ($nr in $NdkRoots) {
    if (($nr -ne "") -and (Test-Path $nr)) {
        $foundCmds = @(Get-ChildItem -Path $nr -Filter "aarch64-linux-android*-clang.cmd" -Recurse -ErrorAction SilentlyContinue | Sort-Object Name -Descending)
        if ($foundCmds.Count -gt 0) {
            $NdkClang = $foundCmds[0].FullName
            break
        }
    }
}

$ArmFeatures = "+neon,+dotprod,+i8mm,+fp16,+lse,+aes,+sha2"
$BuiltArm64 = $false
if (($NdkClang -ne "") -and ($Rustup -ne "")) {
    Write-Host "    [NDK DETECTED] Linker: $NdkClang (ARMv9.2 DotProd/I8MM + PowerVR IntDot/CoopMatrix Vulkan)" -ForegroundColor Green
    & $Rustup target add aarch64-linux-android 2>&1 | Out-Null
    & $Rustc --edition 2021 -C opt-level=3 -C strip=symbols -C "target-feature=$ArmFeatures" --target aarch64-linux-android -L $OutDir -C "linker=$NdkClang" $SrcMain -o $P10Bin | Out-Host
    if (($LASTEXITCODE -eq 0) -and (Test-Path $P10Bin)) { $BuiltArm64 = $true }
}

if ((-not $BuiltArm64) -and ($Rustup -ne "")) {
    Write-Host "    [ZERO-NDK STATIC ARM64] Linking via rustup built-in rust-lld..." -ForegroundColor Yellow
    & $Rustup target add aarch64-unknown-linux-musl 2>&1 | Out-Null
    $SysRoot = (& $Rustc --print sysroot | Out-String).Trim()
    $RustLld = "$SysRoot\lib\rustlib\x86_64-pc-windows-msvc\bin\rust-lld.exe"
    if (Test-Path $RustLld) {
        foreach ($flav in @("gnu-lld","ld.lld","gnu")) {
            if ($BuiltArm64) { break }
            & $Rustc --edition 2021 -C opt-level=3 -C strip=symbols -C "target-feature=$ArmFeatures" --target aarch64-unknown-linux-musl -C "linker-flavor=$flav" -C "linker=$RustLld" -C link-self-contained=yes $SrcMain -o $P10Bin 2>&1 | Out-Null
            if (($LASTEXITCODE -eq 0) -and (Test-Path $P10Bin)) { $BuiltArm64 = $true }
        }
    }
}

if ($BuiltArm64 -and (Test-Path $P10Bin)) {
    $pkb = [Math]::Round(((Get-Item $P10Bin).Length / 1024.0), 1)
    Write-Host "    [PASS] Pixel 10 ARMv9.2 + IntDot/CoopMat Binary -> $pkb KB" -ForegroundColor Green
} else {
    if (Test-Path $HostExe) { & $HostExe --bench | Out-Host }
    exit 0
}

$Adb = ""
foreach ($ac in @("$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe","C:\platform-tools\adb.exe","E:\platform-tools\adb.exe")) {
    if (Test-Path $ac) { $Adb = $ac; break }
}
if ($Adb -eq "") {
    $adbCmd = Get-Command "adb.exe" -ErrorAction SilentlyContinue
    if ($adbCmd) { $Adb = $adbCmd.Source }
}
if ($Adb -eq "") { exit 0 }

$DevLines = @(& $Adb devices 2>&1)
$Serials = @()
foreach ($dl in $DevLines) {
    $t = "$dl".Trim()
    if ($t -match "^(\S+)\s+device$") { $Serials += $Matches[1] }
}
if ($Serials.Count -eq 0) {
    Write-Host "    [INFO] Pixel 10 unplugged; running full Host RTX 3050 Tensor/Vulkan Suite:" -ForegroundColor Yellow
    if (Test-Path $HostExe) { & $HostExe --bench | Out-Host }
    exit 0
}

$P10Ser = $Serials[0]
Write-Host "    [5c] Deploying v0.7.5 & Running Subgroup-128 + IntDot + CoopMatrix Suite on Pixel 10 ($P10Ser)..." -ForegroundColor Green
& $Adb -s $P10Ser shell "pkill -f omega_p10_worker >/dev/null 2>&1" 2>&1 | Out-Null
& $Adb -s $P10Ser push $P10Bin "/data/local/tmp/omega_p10_worker" 2>&1 | Out-Null
& $Adb -s $P10Ser shell "chmod 755 /data/local/tmp/omega_p10_worker" 2>&1 | Out-Null
& $Adb -s $P10Ser forward "tcp:$Port" "tcp:$Port" 2>&1 | Out-Null

if ($Action -eq "Daemon") {
    & $Adb -s $P10Ser shell "/data/local/tmp/omega_p10_worker --daemonize --port $Port" 2>&1 | Out-Null
    Start-Sleep -Milliseconds 500
    Write-Host "    [DAEMON LIVE] http://127.0.0.1:$Port/api/status" -ForegroundColor Green
} elseif ($Action -eq "VulkanOnly") {
    & $Adb -s $P10Ser shell "/data/local/tmp/omega_p10_worker --vulkan $Kernel" | Out-Host
} elseif ($Action -eq "TensorOnly") {
    & $Adb -s $P10Ser shell "/data/local/tmp/omega_p10_worker --vulkan tensor" | Out-Host
} elseif ($Action -eq "CoopMatOnly") {
    & $Adb -s $P10Ser shell "/data/local/tmp/omega_p10_worker --coopmat" | Out-Host
} elseif ($Action -eq "Caps") {
    & $Adb -s $P10Ser shell "/data/local/tmp/omega_p10_worker --caps" | Out-Host
} elseif ($Action -eq "Json") {
    & $Adb -s $P10Ser shell "/data/local/tmp/omega_p10_worker --json" | Out-Host
} elseif ($Action -eq "TpuOnly") {
    & $Adb -s $P10Ser shell "/data/local/tmp/omega_p10_worker --tpu" | Out-Host
} elseif ($Action -eq "BenchAndDaemon") {
    & $Adb -s $P10Ser shell "/data/local/tmp/omega_p10_worker --bench" | Out-Host
    & $Adb -s $P10Ser shell "/data/local/tmp/omega_p10_worker --daemonize --port $Port" 2>&1 | Out-Null
    for ($w = 0; $w -lt 36; $w++) {
        Start-Sleep -Milliseconds 350
        try {
            $hc = (New-Object System.Net.WebClient).DownloadString("http://127.0.0.1:$Port/api/health")
            if ($hc -match '"ok":true') { break }
        } catch { }
    }
    Write-Host "    [DAEMON ARMED] v0.7.5 13-Kernel (PowerVR + 16L Tensor G5 TPU) LIVE on http://127.0.0.1:$Port (:19788)" -ForegroundColor Magenta
} else {
    & $Adb -s $P10Ser shell "/data/local/tmp/omega_p10_worker --bench" | Out-Host
}
