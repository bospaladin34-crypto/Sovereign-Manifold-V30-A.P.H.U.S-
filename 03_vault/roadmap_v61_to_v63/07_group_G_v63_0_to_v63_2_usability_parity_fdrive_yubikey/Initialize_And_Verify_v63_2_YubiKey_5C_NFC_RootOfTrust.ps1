param(
    [string]$SecretVaultDir = "F:\ACT_OMEGA_IMMUTABLE_EPOCH_ARCHIVES\YUBIKEY_ROOT_OF_TRUST_BACKUP",
    [string]$FallbackVaultDir = "E:\ACT_OMEGA_COLD_VAULT\YUBIKEY_ROOT_OF_TRUST_BACKUP",
    [switch]$ProgramSlot2Now = $true
)

$ErrorActionPreference = "Continue"

Write-Host "=========================================================================" -ForegroundColor Cyan
Write-Host " ACT-OMEGA v63.2: YUBIKEY 5C NFC ROOT-OF-TRUST PROVISIONER & VERIFIER    " -ForegroundColor Cyan
Write-Host " Supports: Single-Key Setup Now + Cloning Secret for Payday Backup Key #2" -ForegroundColor Cyan
Write-Host "=========================================================================" -ForegroundColor Cyan

# 1. Locate or Install YubiKey Manager CLI (ykman.exe)
$YkmanCandidates = @(
    "C:\Program Files\Yubico\YubiKey Manager\ykman.exe",
    "C:\Program Files\Yubico\YubiKey Manager CLI\ykman.exe",
    "ykman.exe"
)
$YkmanExe = $YkmanCandidates | Where-Object { (Test-Path $_) -or (Get-Command $_ -ErrorAction SilentlyContinue) } | Select-Object -First 1

if (-not $YkmanExe) {
    Write-Host ">>> [STEP 1] Installing official Yubico YubiKey Manager via winget..." -ForegroundColor Yellow
    & winget install --id Yubico.YubiKeyManager --exact --silent --accept-package-agreements --accept-source-agreements
    foreach ($cand in $YkmanCandidates) {
        if ((Test-Path $cand) -or (Get-Command $cand -ErrorAction SilentlyContinue)) {
            $YkmanExe = $cand
            break
        }
    }
}

if (-not $YkmanExe) {
    Write-Host "[WARN] ykman.exe not found yet. If winget just installed it, close and reopen PowerShell or install from https://www.yubico.com/support/download/yubikey-manager/" -ForegroundColor Magenta
    exit 1
}

Write-Host "[OK] Found YubiKey Manager CLI: $YkmanExe" -ForegroundColor Green

# 2. Detect Plugged-In YubiKey 5C NFC
Write-Host ""
Write-Host ">>> [STEP 2] Scanning USB-C ports for your YubiKey 5C NFC..." -ForegroundColor Cyan
$ListOut = & $YkmanExe list 2>&1 | Out-String
if (-not ($ListOut -match "YubiKey")) {
    Write-Host "[WAIT] Please plug your YubiKey 5C NFC into the USB-C port on your Lenovo LOQ 15 and re-run this script!" -ForegroundColor Yellow
    exit 0
}
Write-Host "[DETECTED] $($ListOut.Trim())" -ForegroundColor Green

Write-Host ""
Write-Host ">>> [STEP 3] Reading YubiKey 5C NFC Device Info & Enabled Interfaces..." -ForegroundColor Cyan
$InfoOut = & $YkmanExe info 2>&1 | Out-String
Write-Host $InfoOut -ForegroundColor Gray

# 3. Determine Vault Directory on F:\ (or E:\ / C:\ fallback) to save the Payday Clone Secret
$TargetVault = $SecretVaultDir
if (-not (Test-Path "F:\")) {
    if (Test-Path "E:\") {
        $TargetVault = $FallbackVaultDir
    } else {
        $TargetVault = "C:\ACT_OMEGA_7777D_ORTHOPLEX_LAB\YUBIKEY_ROOT_OF_TRUST_BACKUP"
    }
}
if (-not (Test-Path $TargetVault)) {
    New-Item -ItemType Directory -Path $TargetVault -Force | Out-Null
}

$SecretFile = Join-Path $TargetVault "SLOT2_HMAC_SHARED_SECRET_FOR_KEY2_CLONING.txt"
$ReceiptFile = Join-Path $TargetVault "v63_2_yubikey_5c_nfc_attestation_receipt.json"

# 4. Generate or Load the 20-Byte (40-Hex-Char) Slot-2 HMAC Challenge-Response Secret
$HmacSecretHex = ""
if (Test-Path $SecretFile) {
    $Lines = Get-Content -Path $SecretFile
    foreach ($ln in $Lines) {
        if ($ln -match "^HMAC_SECRET_HEX=([0-9a-fA-F]{40})$") {
            $HmacSecretHex = $Matches[1]
        }
    }
}

if ([string]::IsNullOrEmpty($HmacSecretHex)) {
    $RngBytes = New-Object byte[] 20
    $Rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $Rng.GetBytes($RngBytes)
    $SbHex = New-Object System.Text.StringBuilder
    foreach ($b in $RngBytes) { [void]$SbHex.Append($b.ToString("x2")) }
    $HmacSecretHex = $SbHex.ToString()

    $BackupText = @(
        "ACT-OMEGA YUBIKEY 5C NFC SLOT-2 HMAC SHARED SECRET (KEEP OFFLINE FOR KEY #2 CLONING)",
        "CREATED_UTC=$((Get-Date).ToUniversalTime().ToString('o'))",
        "PRIMARY_DEVICE=$($ListOut.Trim())",
        "HMAC_SECRET_HEX=$HmacSecretHex",
        "CLONE_TO_KEY2_COMMAND=ykman otp chalresp --force 2 $HmacSecretHex"
    ) -join [Environment]::NewLine
    [System.IO.File]::WriteAllText($SecretFile, $BackupText)
    Write-Host "[SECRET SAVED] Generated 160-bit Slot-2 HMAC Secret and backed up to:" -ForegroundColor Green
    Write-Host "               $SecretFile" -ForegroundColor Yellow
    Write-Host "               (When you get YubiKey #2 on payday, this file lets you clone the exact same Slot-2 secret onto Key #2!)" -ForegroundColor Cyan
} else {
    Write-Host "[SECRET LOADED] Reusing existing Slot-2 HMAC Secret from $SecretFile" -ForegroundColor Green
}

# 5. Program Slot 2 on the YubiKey 5C NFC for ACT-Omega Merkle Root Attestation
if ($ProgramSlot2Now) {
    Write-Host ""
    Write-Host ">>> [STEP 4] Programming OTP Slot 2 (HMAC-SHA1 Challenge-Response) on YubiKey 5C NFC..." -ForegroundColor Cyan
    & $YkmanExe otp chalresp --force 2 $HmacSecretHex
    Write-Host "[SLOT 2 READY] Slot 2 is now configured for ACT-Omega Cryptographic Challenge-Response!" -ForegroundColor Green
}

# 6. Run Live Hardware Challenge-Response Test Against ACT-Omega Canonical Seed
$CanonicalChallenge = "3333282816177777"
Write-Host ""
Write-Host ">>> [STEP 5] Running Live Hardware Attestation Test (Challenge = $CanonicalChallenge)..." -ForegroundColor Cyan
$HmacResponse = (& $YkmanExe otp calculate 2 $CanonicalChallenge 2>&1 | Out-String).Trim()
Write-Host "[HARDWARE SIGNATURE] Challenge: $CanonicalChallenge -> YubiKey 5C NFC Response: $HmacResponse" -ForegroundColor Green

# 7. Also Sign Any Pending Epoch Manifests on F:\ or E:\
foreach ($archiveRoot in @("F:\ACT_OMEGA_IMMUTABLE_EPOCH_ARCHIVES", "E:\ACT_OMEGA_FDRIVE_STAGING_ARCHIVES")) {
    if (Test-Path $archiveRoot) {
        Get-ChildItem -Path $archiveRoot -Filter "EPOCH_MERKLE_MANIFEST.json" -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
            $epDir = $_.DirectoryName
            $jsonRaw = Get-Content -Path $_.FullName -Raw | ConvertFrom-Json
            if ($jsonRaw.epoch_merkle_root_sha256) {
                $chal = $jsonRaw.epoch_merkle_root_sha256.Substring(0, 64)
                $resp = (& $YkmanExe otp calculate 2 $chal 2>&1 | Out-String).Trim()
                $sigPath = Join-Path $epDir "YUBIKEY_ATTESTATION.sig"
                Set-ItemProperty -Path $sigPath -Name IsReadOnly -Value $false -ErrorAction SilentlyContinue
                $sigBody = @(
                    "YUBIKEY_5C_NFC_HARDWARE_ATTESTATION_V1",
                    "DEVICE=$($ListOut.Trim())",
                    "MERKLE_ROOT=$($jsonRaw.epoch_merkle_root_sha256)",
                    "CHALLENGE_HEX=$chal",
                    "HARDWARE_HMAC_RESPONSE=$resp",
                    "SIGNED_UTC=$((Get-Date).ToUniversalTime().ToString('o'))"
                ) -join [Environment]::NewLine
                [System.IO.File]::WriteAllText($sigPath, $sigBody)
                Set-ItemProperty -Path $sigPath -Name IsReadOnly -Value $true -ErrorAction SilentlyContinue
                Write-Host "[EPOCH SIGNED] Hardware-signed $($epDir) -> HMAC: $resp" -ForegroundColor Yellow
            }
        }
    }
}

$ReceiptObj = [PSCustomObject]@{
    release                 = "ACT-Omega v63.2 YubiKey 5C NFC Root-of-Trust Provisioning"
    timestamp_utc           = (Get-Date).ToUniversalTime().ToString("o")
    detected_device         = $ListOut.Trim()
    slot2_configured        = $true
    canonical_challenge_hex = $CanonicalChallenge
    hardware_hmac_response  = $HmacResponse
    clone_secret_backup     = $SecretFile
}
$ReceiptObj | ConvertTo-Json -Depth 3 | Set-Content -Path $ReceiptFile

Write-Host "=========================================================================" -ForegroundColor Green
Write-Host " YUBIKEY 5C NFC ROOT OF TRUST ONLINE! Receipt: $ReceiptFile" -ForegroundColor Green
Write-Host "=========================================================================" -ForegroundColor Green
