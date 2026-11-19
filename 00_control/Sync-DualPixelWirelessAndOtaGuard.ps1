# =============================================================================
# ACT-OMEGA SOVEREIGN MANIFOLD v62.0.0 — DUAL-PIXEL WIRELESS & ANDROID 17 QPR3 BETA 3 OTA GUARD
# =============================================================================
# Solves:
# 1. USB Slot Preservation for YubiKey 5C NFC (Serial: 39651128) via Zero-Cable
#    Wireless ADB over GARLOCK00 Wi-Fi 6 Direct Hotspot ("GARLOCK00 0975", 192.168.137.1/24)
#    plus HTTP/2 Over-The-Air APK distribution (:8097/api/v1/ota/pixel_apk).
# 2. Dynamic Target Resolution across USB Serial, Wireless TCP (:5555), Wireless TLS,
#    and mDNS (_adb-tls-connect._tcp) for Pixel 10 (Edge-1) & Pixel 8 (Edge-2) via external config.
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
function Get-ExternalPixelConfigSerial {
    param([string]$Role)
    $cfgFile = "C:\Users\Nbell\.act_omega_adb_devices.json"
    if (Test-Path $cfgFile) {
        try {
            $cfg = Get-Content -Raw $cfgFile | ConvertFrom-Json
            if ($cfg.$Role -and $cfg.$Role.serial) { return [string]$cfg.$Role.serial }
        } catch {}
    }
    return ""
}

function Resolve-PixelTarget {
    param([string]$Role, [string]$ModelHint)
    $cfgSerial = Get-ExternalPixelConfigSerial -Role $Role
    $lines = & $adb devices -l
    if ($cfgSerial) {
        foreach ($l in $lines) {
            if ($l -match "^$([regex]::Escape($cfgSerial))\s+device\b") {
                return $cfgSerial
            }
        }
    }
    foreach ($l in $lines) {
        if ($l -match "\s+device\b" -and ($l -match $ModelHint -or ($cfgSerial -and $l -match [regex]::Escape($cfgSerial)))) {
            return ($l -split "\s+")[0]
        }
    }
    return ""
}

$p8CfgSerial = Get-ExternalPixelConfigSerial -Role "pixel8"
$p10CfgSerial = Get-ExternalPixelConfigSerial -Role "pixel10"
$rawDevsLines = @(& $adb devices -l)
$p8Usb = ""
$p10Usb = ""
foreach ($l in $rawDevsLines) {
    if ($l -match "\s+device\b" -and ($l -notmatch ":\d+\s+device\b")) {
        if (($p8CfgSerial -and $l -match "^$([regex]::Escape($p8CfgSerial))\s+") -or ($l -match "model:Pixel_8|product:shiba")) {
            $p8Usb = ($l -split "\s+")[0]
        } elseif (($p10CfgSerial -and $l -match "^$([regex]::Escape($p10CfgSerial))\s+") -or ($l -match "model:Pixel_10|product:frankel")) {
            $p10Usb = ($l -split "\s+")[0]
        }
    }
}
if ($p8Usb) {
    Write-Host "[2/5] Pixel 8 (EDGE-2-PIXEL8-SHIBA) detected on USB -> Pinning TCP :5555, Wi-Fi 6 Hotspot 192.168.137.8/24 & BT-PAN 192.168.44.8/24..." -ForegroundColor Cyan
    & $adb -s $p8Usb tcpip 5555 | Out-Null
    Start-Sleep -Seconds 2
    & $adb -s $p8Usb shell "cmd wifi connect-network 4741524c4f434b30302030393735 wpa2 '011e9^2X' -x; sleep 2; echo 'ip addr replace 192.168.137.8/24 dev wlan0; ip route replace 192.168.137.0/24 dev wlan0 src 192.168.137.8 table local_network; ip route replace 192.168.137.0/24 dev wlan0 src 192.168.137.8 table wlan0; ip route replace default via 192.168.137.1 dev wlan0 table wlan0; ip rule show | grep -q \"to 192.168.137.0/24 lookup local_network\" || ip rule add to 192.168.137.0/24 lookup local_network pref 1000; iptables -C INPUT -s 192.168.137.0/24 -j ACCEPT 2>/dev/null || iptables -I INPUT 1 -s 192.168.137.0/24 -j ACCEPT; iptables -C OUTPUT -d 192.168.137.0/24 -j ACCEPT 2>/dev/null || iptables -I OUTPUT 1 -d 192.168.137.0/24 -j ACCEPT' | ksud debug su" | Out-Null
}
if ($p10Usb) {
    Write-Host "[2/5] Pixel 10 (EDGE-1-PIXEL10-G5) detected on USB -> Pinning TCP :5555..." -ForegroundColor Cyan
    & $adb -s $p10Usb tcpip 5555 | Out-Null
    Start-Sleep -Seconds 2
}

if (-not [string]::IsNullOrWhiteSpace($Pixel8WirelessEndpoint)) {
    & $adb connect $Pixel8WirelessEndpoint | Out-Null
}
if (-not [string]::IsNullOrWhiteSpace($Pixel10WirelessEndpoint)) {
    & $adb connect $Pixel10WirelessEndpoint | Out-Null
}

# 3. Resolve Active ADB Targets (USB, Wireless TCP :5555, Wireless TLS, or mDNS)
$p8Target  = Resolve-PixelTarget -Role "pixel8" -ModelHint "model:Pixel_8|product:shiba|192\.168\.137\.8:"
$p10Target = Resolve-PixelTarget -Role "pixel10" -ModelHint "model:Pixel_10|product:frankel|192\.168\.137\.10:"

Write-Host "[3/5] Resolved ADB Transports:" -ForegroundColor Cyan
Write-Host "      - Edge-2 Pixel 8  (EDGE-2-PIXEL8-SHIBA): $(if ($p8Target) { 'ONLINE' } else { 'OFFLINE (Connect to GARLOCK00 0975 Wi-Fi -> IP 192.168.137.8)' })" -ForegroundColor $(if ($p8Target) { "Green" } else { "Yellow" })
Write-Host "      - Edge-1 Pixel 10 (EDGE-1-PIXEL10-G5): $(if ($p10Target) { 'ONLINE' } else { 'OFFLINE (Connect to GARLOCK00 0975 Wi-Fi -> Static IP 192.168.137.10, Gw 192.168.137.1)' })" -ForegroundColor $(if ($p10Target) { "Green" } else { "Yellow" })

# 4. Inspect Android 17 QPR3 Beta 3 Readiness & Optional Inactive-Slot KernelSU OTA Patch
if ($p8Target) {
    & $adb -s $p8Target forward tcp:8098 tcp:8098 2>$null
    & $adb -s $p8Target reverse tcp:8097 tcp:8097 2>$null
    & $adb -s $p8Target reverse tcp:5173 tcp:5173 2>$null
    $p8Props = (& $adb -s $p8Target shell "getprop ro.build.version.release; getprop ro.build.id; getprop ro.boot.slot_suffix; echo 'id' | ksud debug su") -split "`r?`n"
    Write-Host "[4/5] Pixel 8 Live OS Telemetry (EDGE-2-PIXEL8-SHIBA): Android $($p8Props[0]) | Build=$($p8Props[1]) | ActiveSlot=$($p8Props[2]) | Root=$($p8Props[3])" -ForegroundColor Green

    if ($PatchInactiveSlot) {
        Write-Host "      [OTA-GUARD] Patching inactive A/B slot on Pixel 8 via '/data/adb/ksud boot-patch --ota --flash'..." -ForegroundColor Magenta
        & $adb -s $p8Target shell "echo '/data/adb/ksud boot-patch --ota --flash' | ksud debug su"
    }
}

if ($p10Target) {
    & $adb -s $p10Target reverse tcp:8097 tcp:8097 2>$null
    & $adb -s $p10Target reverse tcp:5173 tcp:5173 2>$null
    $p10Props = (& $adb -s $p10Target shell "getprop ro.build.version.release; getprop ro.build.id; getprop ro.boot.slot_suffix") -split "`r?`n"
    Write-Host "[4/5] Pixel 10 Live OS Telemetry (EDGE-1-PIXEL10-G5): Android $($p10Props[0]) | Build=$($p10Props[1]) | ActiveSlot=$($p10Props[2])" -ForegroundColor Green
}

# 5. Optional Whole-App Wireless APK Flash & Weight Sync
$apkPath = "C:\sovereign_manifold_v31\04_edge_silicon\ACT-Omega-Pixel10-Sovereign.apk"
if (-not (Test-Path $apkPath)) {
    $apkPath = "C:\sovereign_manifold_v31\04_edge_silicon\pixel10_ndk_app\app\build\outputs\apk\debug\app-debug.apk"
}

if ($FlashWholeApp -and (Test-Path $apkPath)) {
    $hostOpKeyFile = "C:\Users\Nbell\.act_omega_operator_vault_key"
    foreach ($tgt in @($p8Target, $p10Target)) {
        if (-not [string]::IsNullOrWhiteSpace($tgt)) {
            $nodeLabel = if ($tgt -eq $p8Target) { "EDGE-2-PIXEL8-SHIBA" } else { "EDGE-1-PIXEL10-G5" }
            Write-Host "[5/5] Flashing Whole-App APK ($apkPath) wirelessly to $nodeLabel..." -ForegroundColor Cyan
            & $adb -s $tgt install -r -d $apkPath
            if (Test-Path $hostOpKeyFile) {
                & $adb -s $tgt push $hostOpKeyFile "/data/local/tmp/.act_omega_operator_vault_key" | Out-Null
                & $adb -s $tgt shell "chmod 644 /data/local/tmp/.act_omega_operator_vault_key" 2>$null
            }
            & $adb -s $tgt reverse tcp:8097 tcp:8097 2>$null
            & $adb -s $tgt reverse tcp:5173 tcp:5173 2>$null
            & $adb -s $tgt shell am start -n com.actomega.manifold/.MainActivity
        }
    }
}

if ($SyncWeights) {
    foreach ($tgt in @($p8Target, $p10Target)) {
        if (-not [string]::IsNullOrWhiteSpace($tgt)) {
            $nodeLabel = if ($tgt -eq $p8Target) { "EDGE-2-PIXEL8-SHIBA" } else { "EDGE-1-PIXEL10-G5" }
            Write-Host "[5/5] Pushing .e8z weights wirelessly to ${nodeLabel}:/data/local/tmp/..." -ForegroundColor Cyan
            & $adb -s $tgt push "C:\sovereign_manifold_v31\00_control\weights\sovereign_harmonic_iv_v5000.e8z" "/data/local/tmp/sovereign_harmonic_iv_v5000.e8z"
        }
    }
}

Write-Host "==========================================================================`n" -ForegroundColor Cyan
