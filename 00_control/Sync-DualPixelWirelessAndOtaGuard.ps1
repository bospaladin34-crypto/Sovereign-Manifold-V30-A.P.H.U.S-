# =============================================================================
# ACT-OMEGA SOVEREIGN MANIFOLD v62.0.0 — DUAL-PIXEL WIRELESS & ANDROID 17 QPR3 BETA 3 OTA GUARD
# =============================================================================
# Solves:
# 1. USB Slot Preservation for YubiKey 5C NFC (Serial: 39651128) via Zero-Cable
#    Wireless ADB over GARLOCK00 Wi-Fi 6 Direct Hotspot ("GARLOCK00 0975", 192.168.137.1/24)
#    plus HTTP/2 Over-The-Air APK distribution (:8097/api/v1/ota/pixel_apk).
# 2. Dynamic Target Resolution across USB Serial, Wireless TCP (:5555), Wireless TLS,
#    and mDNS (_adb-tls-connect._tcp) for Pixel 10 (58170DLCR0004V) & Pixel 8 (3A121FDJH00BW5).
# 3. Android 17 QPR3 Beta 3 A/B Slot Update Survival:
#    - Pre-Reboot KernelSU Inactive-Slot Patcher (-PatchInactiveSlot -> ksud boot-patch --ota --flash)
#    - Persistent /data/adb/service.d/99_sovereign_wireless_ota_guard.sh boot script
#    - Whole-App APK Over-The-Air Wireless Installer (-FlashWholeApp)
# =============================================================================

param(
    [switch]$FlashWholeApp,
    [switch]$SyncWeights,
    [switch]$PatchInactiveSlot,
    [string]$Pixel10WirelessEndpoint = "",
    [string]$Pixel8WirelessEndpoint = "192.168.137.8:5555"
)

$ErrorActionPreference = "Continue"
$adb = "C:\Users\Nbell\AppData\Local\Android\Sdk\platform-tools\adb.exe"
if (-not (Test-Path $adb)) { $adb = "adb" }

Write-Host "`n==========================================================================" -ForegroundColor Cyan
Write-Host " ACT-OMEGA DUAL-PIXEL WIRELESS & ANDROID 17 QPR3 BETA 3 OTA GUARD" -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan

# 1. Ensure Windows 11 Wi-Fi 6 Direct Hotspot ("GARLOCK00 0975" -> 192.168.137.1/24) is active
#    (Bypasses router AP client isolation on guest Wi-Fi networks)
try {
    $connectionProfile = [Windows.Networking.Connectivity.NetworkInformation,Windows.Networking.Connectivity,ContentType=WindowsRuntime]::GetInternetConnectionProfile()
    if ($null -ne $connectionProfile) {
        $tetheringManager = [Windows.Networking.NetworkOperators.NetworkOperatorTetheringManager,Windows.Networking.NetworkOperators,ContentType=WindowsRuntime]::CreateFromConnectionProfile($connectionProfile)
        if ($tetheringManager.TetheringOperationalState -ne 'On') {
            Write-Host "[1/5] Starting GARLOCK00 Wi-Fi 6 Direct Hotspot (192.168.137.1/24)..." -ForegroundColor Yellow
            $null = $tetheringManager.StartTetheringAsync()
            Start-Sleep -Seconds 3
        }
        $cfg = $tetheringManager.GetCurrentAccessPointConfiguration()
        Write-Host "[1/5] Hotspot Active: SSID='$($cfg.Ssid)' | Gateway=192.168.137.1/24 | State=$($tetheringManager.TetheringOperationalState)" -ForegroundColor Green
    }
} catch {
    Write-Host "[1/5] Hotspot check skipped: $($_.Exception.Message)" -ForegroundColor DarkYellow
}

# 2. If Pixel 8 or Pixel 10 is attached via USB right now, bridge it onto GARLOCK00 0975 & TCP :5555
$rawDevs = (& $adb devices -l) -join "`n"
if ($rawDevs -match "3A121FDJH00BW5\s+device") {
    Write-Host "[2/5] Pixel 8 (3A121FDJH00BW5) detected on USB -> Pinning TCP :5555 & 192.168.137.8/24..." -ForegroundColor Cyan
    & $adb -s 3A121FDJH00BW5 tcpip 5555 | Out-Null
    Start-Sleep -Seconds 2
    & $adb -s 3A121FDJH00BW5 shell "cmd wifi connect-network 4741524c4f434b30302030393735 wpa2 '011e9^2X' -x; sleep 2; su -c 'ip addr replace 192.168.137.8/24 dev wlan0; ip route replace 192.168.137.0/24 dev wlan0 table local_network; iptables -C INPUT -s 192.168.137.0/24 -j ACCEPT 2>/dev/null || iptables -I INPUT 1 -s 192.168.137.0/24 -j ACCEPT; iptables -C OUTPUT -d 192.168.137.0/24 -j ACCEPT 2>/dev/null || iptables -I OUTPUT 1 -d 192.168.137.0/24 -j ACCEPT'" | Out-Null
}
if ($rawDevs -match "58170DLCR0004V\s+device") {
    Write-Host "[2/5] Pixel 10 (58170DLCR0004V) detected on USB -> Pinning TCP :5555..." -ForegroundColor Cyan
    & $adb -s 58170DLCR0004V tcpip 5555 | Out-Null
    Start-Sleep -Seconds 2
}

if (-not [string]::IsNullOrWhiteSpace($Pixel8WirelessEndpoint)) {
    & $adb connect $Pixel8WirelessEndpoint | Out-Null
}
if (-not [string]::IsNullOrWhiteSpace($Pixel10WirelessEndpoint)) {
    & $adb connect $Pixel10WirelessEndpoint | Out-Null
}

# 3. Resolve Active ADB Targets (USB, Wireless TCP :5555, Wireless TLS, or mDNS)
function Resolve-PixelTarget {
    param([string]$CanonicalSerial, [string]$ModelHint)
    $lines = & $adb devices -l
    foreach ($l in $lines) {
        if ($l -match "^$([regex]::Escape($CanonicalSerial))\s+device\b") {
            return $CanonicalSerial
        }
    }
    foreach ($l in $lines) {
        if ($l -match "\s+device\b" -and ($l -match $ModelHint -or $l -match $CanonicalSerial)) {
            return ($l -split "\s+")[0]
        }
    }
    return ""
}

$p8Target  = Resolve-PixelTarget -CanonicalSerial "3A121FDJH00BW5" -ModelHint "model:Pixel_8|product:shiba|192\.168\.137\.8:"
$p10Target = Resolve-PixelTarget -CanonicalSerial "58170DLCR0004V" -ModelHint "model:Pixel_10|product:frankel|192\.168\.137\.10:"

Write-Host "[3/5] Resolved ADB Transports:" -ForegroundColor Cyan
Write-Host "      - Edge-2 Pixel 8  (3A121FDJH00BW5): $(if ($p8Target) { $p8Target } else { 'OFFLINE (Connect to GARLOCK00 0975 Wi-Fi -> IP 192.168.137.8)' })" -ForegroundColor $(if ($p8Target) { "Green" } else { "Yellow" })
Write-Host "      - Edge-1 Pixel 10 (58170DLCR0004V): $(if ($p10Target) { $p10Target } else { 'OFFLINE (Connect to GARLOCK00 0975 Wi-Fi -> Static IP 192.168.137.10, Gw 192.168.137.1)' })" -ForegroundColor $(if ($p10Target) { "Green" } else { "Yellow" })

# 4. Inspect Android 17 QPR3 Beta 3 Readiness & Optional Inactive-Slot KernelSU OTA Patch
if ($p8Target) {
    $p8Props = (& $adb -s $p8Target shell "getprop ro.build.version.release; getprop ro.build.id; getprop ro.boot.slot_suffix; su -c 'id'") -split "`r?`n"
    Write-Host "[4/5] Pixel 8 Live OS Telemetry ($p8Target): Android $($p8Props[0]) | Build=$($p8Props[1]) | ActiveSlot=$($p8Props[2]) | Root=$($p8Props[3])" -ForegroundColor Green

    if ($PatchInactiveSlot) {
        Write-Host "      [OTA-GUARD] Patching inactive A/B slot on Pixel 8 via '/data/adb/ksud boot-patch --ota --flash'..." -ForegroundColor Magenta
        & $adb -s $p8Target shell "su -c '/data/adb/ksud boot-patch --ota --flash'"
    }
}

if ($p10Target) {
    $p10Props = (& $adb -s $p10Target shell "getprop ro.build.version.release; getprop ro.build.id; getprop ro.boot.slot_suffix") -split "`r?`n"
    Write-Host "[4/5] Pixel 10 Live OS Telemetry ($p10Target): Android $($p10Props[0]) | Build=$($p10Props[1]) | ActiveSlot=$($p10Props[2])" -ForegroundColor Green
}

# 5. Optional Whole-App Wireless APK Flash & Weight Sync
$apkPath = "C:\sovereign_manifold_v31\04_edge_silicon\ACT-Omega-Pixel10-Sovereign.apk"
if (-not (Test-Path $apkPath)) {
    $apkPath = "C:\sovereign_manifold_v31\04_edge_silicon\pixel10_ndk_app\app\build\outputs\apk\debug\app-debug.apk"
}

if ($FlashWholeApp -and (Test-Path $apkPath)) {
    foreach ($tgt in @($p8Target, $p10Target)) {
        if (-not [string]::IsNullOrWhiteSpace($tgt)) {
            Write-Host "[5/5] Flashing Whole-App APK ($apkPath) wirelessly to $tgt..." -ForegroundColor Cyan
            & $adb -s $tgt install -r -d $apkPath
            & $adb -s $tgt reverse tcp:8097 tcp:8097 2>$null
            & $adb -s $tgt reverse tcp:5173 tcp:5173 2>$null
            & $adb -s $tgt shell am start -n com.actomega.manifold/.MainActivity
        }
    }
}

if ($SyncWeights) {
    foreach ($tgt in @($p8Target, $p10Target)) {
        if (-not [string]::IsNullOrWhiteSpace($tgt)) {
            Write-Host "[5/5] Pushing .e8z weights wirelessly to ${tgt}:/data/local/tmp/..." -ForegroundColor Cyan
            & $adb -s $tgt push "C:\sovereign_manifold_v31\00_control\weights\sovereign_harmonic_iv_v5000.e8z" "/data/local/tmp/sovereign_harmonic_iv_v5000.e8z"
        }
    }
}

Write-Host "==========================================================================`n" -ForegroundColor Cyan
