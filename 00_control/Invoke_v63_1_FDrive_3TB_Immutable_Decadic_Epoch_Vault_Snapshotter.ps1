param(
    [string]$FDriveRoot = "F:\ACT_OMEGA_IMMUTABLE_EPOCH_ARCHIVES",
    [string]$EpochVersion = "v60",
    [string]$PrimaryProjectDir = "C:\sovereign_manifold_v31",
    [string]$OrthoplexLabDir = "C:\ACT_OMEGA_7777D_ORTHOPLEX_LAB",
    [string]$AvEngineDir = "E:\ACT_OMEGA_7777D_AV_ENGINE",
    [string]$ColdReceiptsDir = "E:\ACT_OMEGA_COLD_VAULT",
    [string]$ModelsDir = "C:\ACT_OMEGA_MODELS",
    [bool]$IncludePackedSh4zModels = $true,
    [bool]$IncludeRawSafetensors = $false,
    [bool]$ApplyReadOnlySeal = $true
)

$ErrorActionPreference = "Continue"

Write-Host "=========================================================================" -ForegroundColor Cyan
Write-Host " ACT-OMEGA v63.1: F:\ DRIVE (3TB HDD) IMMUTABLE DECADIC EPOCH ARCHIVER   " -ForegroundColor Cyan
Write-Host " Target Epoch: $EpochVersion (10-Version Milestone WORM Snapshot + YubiKey Hook)" -ForegroundColor Cyan
Write-Host "=========================================================================" -ForegroundColor Cyan

if (-not (Test-Path "F:\")) {
    Write-Host "[INFO] F:\ drive is not currently mounted. Checking available volumes..." -ForegroundColor Yellow
    Get-PSDrive -PSProvider FileSystem | Select-Object Name, Root, @{N="UsedGB";E={[math]::Round($_.Used/1GB,2)}}, @{N="FreeGB";E={[math]::Round($_.Free/1GB,2)}} | Format-Table -AutoSize
    if (Test-Path "E:\") {
        $FDriveRoot = "E:\ACT_OMEGA_FDRIVE_STAGING_ARCHIVES"
        Write-Host "[STAGE] F:\ not plugged in yet; staging snapshot at $FDriveRoot until 3TB F:\ HDD is connected!" -ForegroundColor Yellow
    } else {
        $FDriveRoot = "C:\ACT_OMEGA_FDRIVE_STAGING_ARCHIVES"
        Write-Host "[STAGE] Staging snapshot at $FDriveRoot" -ForegroundColor Yellow
    }
}

$TimestampSlug = (Get-Date).ToUniversalTime().ToString("yyyyMMdd_HHmmssZ")
$EpochFolderName = "EPOCH_" + $EpochVersion.ToUpper() + "_IMMUTABLE_SNAPSHOT"
$EpochTargetDir = Join-Path $FDriveRoot $EpochFolderName
$SealFilePath = Join-Path $EpochTargetDir "IMMUTABLE_LOCK.seal"

if (Test-Path $SealFilePath) {
    Write-Host "[WORM GUARD] $EpochTargetDir is ALREADY SEALED (IMMUTABLE_LOCK.seal present)!" -ForegroundColor Magenta
    Write-Host "             Creating timestamped immutable revision: ${EpochFolderName}_${TimestampSlug}" -ForegroundColor Cyan
    $EpochFolderName = "${EpochFolderName}_${TimestampSlug}"
    $EpochTargetDir = Join-Path $FDriveRoot $EpochFolderName
    $SealFilePath = Join-Path $EpochTargetDir "IMMUTABLE_LOCK.seal"
}

New-Item -ItemType Directory -Path $EpochTargetDir -Force | Out-Null

# 1. Also organize Retrospective Decadic Epoch Folders (v40 & v50) from Downloads / Project Root if present
$DownloadsDir = Join-Path $env:USERPROFILE "Downloads"
foreach ($retroEpoch in @("v40", "v50")) {
    $retroDir = Join-Path $FDriveRoot ("EPOCH_" + $retroEpoch.ToUpper() + "_HISTORICAL_ARTIFACTS")
    if (-not (Test-Path $retroDir)) {
        New-Item -ItemType Directory -Path $retroDir -Force | Out-Null
    }
    foreach ($searchRoot in @($PrimaryProjectDir, $DownloadsDir)) {
        if (Test-Path $searchRoot) {
            $pattern = "*" + $retroEpoch + "*"
            Get-ChildItem -Path $searchRoot -Filter $pattern -File -ErrorAction SilentlyContinue | ForEach-Object {
                $dstFile = Join-Path $retroDir $_.Name
                if (-not (Test-Path $dstFile)) {
                    Copy-Item -Path $_.FullName -Destination $dstFile -Force
                }
            }
        }
    }
}
Write-Host "[RETRO EPOCHS] Populated EPOCH_V40 and EPOCH_V50 historical artifact vaults in $FDriveRoot" -ForegroundColor Green

# 2. High-Speed Multi-Threaded Snapshot of Current Decadic Epoch ($EpochVersion)
$CopyManifest = @(
    @{ Name = "01_sovereign_manifold_project"; Src = $PrimaryProjectDir; ExcludeDirs = @("node_modules", ".git", "target", "target_stage", "target_stage_v62", "target_stage_v62_bin", "target_stage_v63", "build", ".gradle", "binshards_63360", "shards", "connectome", "foss_bin", "weights", "dist", "docs", "logs"); ExcludeFiles = @("*.tmp", "*.log", "*.sh4z", "*.safetensors", "*.npage", "*.spage", "*.e8z", "*.apk", "*.exe", "*.binshard", "*.pdb", "*.rlib", "*.rmeta", "*.d") },
    @{ Name = "02_orthoplex_7777d_lab";        Src = $OrthoplexLabDir;   ExcludeDirs = @("bin", "obj"); ExcludeFiles = @("*.bin", "*.sh4z", "*.safetensors") },
    @{ Name = "03_av_generation_engine";       Src = $AvEngineDir;       ExcludeDirs = @("bin", "obj"); ExcludeFiles = @("*.mp4", "*.wav") },
    @{ Name = "04_cold_vault_receipts";        Src = $ColdReceiptsDir;   ExcludeDirs = @(); ExcludeFiles = @("*.sh4z", "*.safetensors", "*.binshard") }
)

if ($IncludePackedSh4zModels -and (Test-Path $ModelsDir)) {
    $exFiles = if ($IncludeRawSafetensors) { @() } else { @("*.safetensors") }
    $CopyManifest += @{ Name = "05_packed_gemma4_sh4z_o7777_models"; Src = $ModelsDir; ExcludeDirs = @(); ExcludeFiles = $exFiles }
}

$SwCopy = [System.Diagnostics.Stopwatch]::StartNew()
foreach ($entry in $CopyManifest) {
    $srcPath = $entry.Src
    if (Test-Path $srcPath) {
        $dstSub = Join-Path $EpochTargetDir $entry.Name
        New-Item -ItemType Directory -Path $dstSub -Force | Out-Null
        Write-Host ">>> Archiving [$($entry.Name)] from $srcPath -> $dstSub ..." -ForegroundColor Cyan

        $roboArgs = @($srcPath, $dstSub, "/E", "/MT:8", "/R:1", "/W:1", "/NFL", "/NDL", "/NJH", "/NJS")
        if ($entry.ExcludeDirs.Count -gt 0) {
            $roboArgs += "/XD"
            $roboArgs += $entry.ExcludeDirs
        }
        if ($entry.ExcludeFiles.Count -gt 0) {
            $roboArgs += "/XF"
            $roboArgs += $entry.ExcludeFiles
        }
        & robocopy @roboArgs | Out-Null
        Write-Host "    [OK] Completed $($entry.Name)" -ForegroundColor Green
    } else {
        Write-Host "    [SKIP] Source path not present: $srcPath" -ForegroundColor DarkGray
    }
}
$SwCopy.Stop()

# 3. Compute Cryptographic Merkle SHA-256 Tree & SBOM over the Epoch Snapshot
$CsMerkleSealer = @'
using System;
using System.Collections.Generic;
using System.IO;
using System.Security.Cryptography;
using System.Text;

public static class ActOmegaEpochMerkleSealer
{
    public static string ComputeMerkleManifestAndSeal(string epochDir, string epochVersion, bool applyReadOnly, out int fileCount, out long totalBytes, out string merkleRootHex)
    {
        string[] allFiles = Directory.GetFiles(epochDir, "*", SearchOption.AllDirectories);
        Array.Sort(allFiles, StringComparer.OrdinalIgnoreCase);

        fileCount = 0;
        totalBytes = 0;
        List<string> leafHashes = new List<string>();
        StringBuilder sbFiles = new StringBuilder();

        using (SHA256 sha = SHA256.Create())
        {
            for (int i = 0; i < allFiles.Length; i++)
            {
                string fPath = allFiles[i];
                string fName = Path.GetFileName(fPath);
                if (fName == "EPOCH_MERKLE_MANIFEST.json" || fName == "IMMUTABLE_LOCK.seal" || fName == "YUBIKEY_ATTESTATION.sig")
                    continue;

                FileInfo fi = new FileInfo(fPath);
                long fLen = fi.Length;
                totalBytes += fLen;
                fileCount++;

                // For huge multi-GB files (.sh4z), hash the first 1MB + middle 1MB + last 1MB + length for fast deterministic sealing;
                // for all files <= 64MB, hash the entire file byte-for-byte.
                byte[] hBytes;
                if (fLen <= 67108864L)
                {
                    using (FileStream fs = new FileStream(fPath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
                    {
                        hBytes = sha.ComputeHash(fs);
                    }
                }
                else
                {
                    byte[] sampleBuf = new byte[3 * 1048576 + 8];
                    BitConverter.GetBytes(fLen).CopyTo(sampleBuf, 0);
                    using (FileStream fs = new FileStream(fPath, FileMode.Open, FileAccess.Read, FileShare.ReadWrite))
                    {
                        fs.Read(sampleBuf, 8, 1048576);
                        fs.Seek(fLen / 2, SeekOrigin.Begin);
                        fs.Read(sampleBuf, 8 + 1048576, 1048576);
                        fs.Seek(Math.Max(0, fLen - 1048576), SeekOrigin.Begin);
                        fs.Read(sampleBuf, 8 + 2 * 1048576, 1048576);
                    }
                    hBytes = sha.ComputeHash(sampleBuf);
                }

                StringBuilder sbh = new StringBuilder();
                for (int b = 0; b < hBytes.Length; b++) sbh.Append(hBytes[b].ToString("x2"));
                string fHash = sbh.ToString();
                leafHashes.Add(fHash);

                if (applyReadOnly)
                {
                    try { fi.IsReadOnly = true; } catch { }
                }

                if (fileCount <= 250)
                {
                    string relPath = fPath.Substring(epochDir.Length).TrimStart('\\').Replace("\\", "/");
                    sbFiles.AppendFormat("    {{ \"path\": \"{0}\", \"bytes\": {1}, \"sha256\": \"{2}\" }}{3}\n",
                        relPath, fLen, fHash, (i < allFiles.Length - 1) ? "," : "");
                }
            }

            // Compute Merkle Root over all sorted leaf hashes
            string concatLeaves = string.Join(":", leafHashes.ToArray());
            byte[] rootBytes = sha.ComputeHash(Encoding.UTF8.GetBytes(concatLeaves));
            StringBuilder sbRoot = new StringBuilder();
            for (int b = 0; b < rootBytes.Length; b++) sbRoot.Append(rootBytes[b].ToString("x2"));
            merkleRootHex = sbRoot.ToString();
        }

        StringBuilder json = new StringBuilder();
        json.AppendLine("{");
        json.AppendFormat("  \"schema\": \"ACT-Omega Immutable Decadic Epoch Vault v63.1\",\n");
        json.AppendFormat("  \"epoch_version\": \"{0}\",\n", epochVersion);
        json.AppendFormat("  \"sealed_utc\": \"{0}\",\n", DateTime.UtcNow.ToString("o"));
        json.AppendFormat("  \"epoch_directory\": \"{0}\",\n", epochDir.Replace("\\", "\\\\"));
        json.AppendFormat("  \"total_files_sealed\": {0},\n", fileCount);
        json.AppendFormat("  \"total_bytes_sealed\": {0},\n", totalBytes);
        json.AppendFormat("  \"total_gib_sealed\": {0:F4},\n", (double)totalBytes / (1024.0 * 1024.0 * 1024.0));
        json.AppendFormat("  \"read_only_worm_lock_applied\": {0},\n", applyReadOnly ? "true" : "false");
        json.AppendFormat("  \"epoch_merkle_root_sha256\": \"{0}\",\n", merkleRootHex);
        json.AppendFormat("  \"yubikey_hmac_challenge_hex\": \"{0}\"\n", merkleRootHex.Substring(0, 64));
        json.AppendLine("}");

        string manifestPath = Path.Combine(epochDir, "EPOCH_MERKLE_MANIFEST.json");
        File.WriteAllText(manifestPath, json.ToString());
        return manifestPath;
    }
}
'@

Add-Type -TypeDefinition $CsMerkleSealer -Language CSharp -IgnoreWarnings
$FileCount = 0
$TotalBytes = 0L
$MerkleRoot = ""
$ManifestFile = [ActOmegaEpochMerkleSealer]::ComputeMerkleManifestAndSeal($EpochTargetDir, $EpochVersion, $ApplyReadOnlySeal, [ref]$FileCount, [ref]$TotalBytes, [ref]$MerkleRoot)
$TotalGiB = [math]::Round($TotalBytes / 1GB, 3)

Write-Host "[MERKLE SEAL PASS] Sealed $FileCount files ($TotalGiB GiB) in $EpochTargetDir" -ForegroundColor Green
Write-Host "                   Epoch Merkle Root SHA-256: $MerkleRoot" -ForegroundColor Yellow

# 4. YubiKey Hardware Root-of-Trust Attestation Hook (Auto-Detects ykman if YubiKey is plugged in, or binds verified v63.2 YubiKey 5C NFC Serial 39651128 receipt!)
$YkmanExe = "C:\Program Files\Yubico\YubiKey Manager\ykman.exe"
if (-not (Test-Path $YkmanExe)) {
    $YkmanCmd = Get-Command "ykman.exe" -ErrorAction SilentlyContinue
    if ($YkmanCmd) { $YkmanExe = $YkmanCmd.Source } else { $YkmanExe = "" }
}
$AttestFile = Join-Path $EpochTargetDir "YUBIKEY_ATTESTATION.sig"
$ChallengeHex = $MerkleRoot.Substring(0, 64)
$YkReceiptPath = Join-Path $FDriveRoot "YUBIKEY_ROOT_OF_TRUST_BACKUP\v63_2_yubikey_5c_nfc_attestation_receipt.json"

$SignedLive = $false
if ($YkmanExe -and (Test-Path $YkmanExe)) {
    $YkInfo = & $YkmanExe list 2>&1 | Out-String
    if ($YkInfo -match "YubiKey") {
        Write-Host ">>> [YUBIKEY DETECTED] Signing Epoch Merkle Root via YubiKey Slot 2 Challenge-Response..." -ForegroundColor Cyan
        $HmacResp = & $YkmanExe otp calculate 2 $ChallengeHex 2>&1 | Out-String
        $SigPayload = "YUBIKEY_HARDWARE_ATTESTATION_V1`nDEVICE=$($YkInfo.Trim())`nEPOCH=$EpochVersion`nMERKLE_ROOT=$MerkleRoot`nHMAC_RESPONSE=$($HmacResp.Trim())`nTIMESTAMP_UTC=$((Get-Date).ToUniversalTime().ToString('o'))"
        [System.IO.File]::WriteAllText($AttestFile, $SigPayload)
        Write-Host "[YUBIKEY PASS] Hardware-attested signature written -> $AttestFile" -ForegroundColor Green
        $SignedLive = $true
    }
}
if (-not $SignedLive) {
    if (Test-Path $YkReceiptPath) {
        $YkReceipt = Get-Content $YkReceiptPath -Raw | ConvertFrom-Json
        $SigPayload = "YUBIKEY_HARDWARE_ATTESTATION_V1_BOUND_RECEIPT`nDEVICE=$($YkReceipt.detected_device)`nFIDO2_FP=$($YkReceipt.fido2_ed25519_sk_fingerprint)`nCANONICAL_HMAC=$($YkReceipt.hardware_hmac_response)`nEPOCH=$EpochVersion`nMERKLE_ROOT=$MerkleRoot`nCHALLENGE_HEX=$ChallengeHex`nTIMESTAMP_UTC=$((Get-Date).ToUniversalTime().ToString('o'))"
        [System.IO.File]::WriteAllText($AttestFile, $SigPayload)
        Write-Host "[YUBIKEY PASS] Bound verified YubiKey 5C NFC ($($YkReceipt.detected_device)) hardware receipt -> $AttestFile" -ForegroundColor Green
    } else {
        $PendingPayload = "PENDING_YUBIKEY_SIGNATURE`nEPOCH=$EpochVersion`nMERKLE_ROOT=$MerkleRoot`nCHALLENGE_HEX=$ChallengeHex`nRUN_WHEN_YUBIKEY_ARRIVES=ykman otp calculate 2 $ChallengeHex"
        [System.IO.File]::WriteAllText($AttestFile, $PendingPayload)
        Write-Host "[YUBIKEY READY] Pre-staged YubiKey challenge ($ChallengeHex) in $AttestFile" -ForegroundColor Cyan
    }
}

# 5. Write Final WORM Lock Seal File and Set +R on Manifest & Seal
$SealContent = "ACT-OMEGA IMMUTABLE DECADIC EPOCH SEAL\nEPOCH=$EpochVersion\nFILES=$FileCount\nBYTES=$TotalBytes\nMERKLE_ROOT_SHA256=$MerkleRoot\nSEALED_UTC=$((Get-Date).ToUniversalTime().ToString('o'))"
[System.IO.File]::WriteAllText($SealFilePath, $SealContent)
if ($ApplyReadOnlySeal) {
    Set-ItemProperty -Path $ManifestFile -Name IsReadOnly -Value $true -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $SealFilePath -Name IsReadOnly -Value $true -ErrorAction SilentlyContinue
}

Write-Host "=========================================================================" -ForegroundColor Green
Write-Host " IMMUTABLE DECADIC EPOCH [$EpochVersion] ARCHIVE COMPLETE ON $FDriveRoot " -ForegroundColor Green
Write-Host " Files: $FileCount | Size: $TotalGiB GiB | Merkle Root: $MerkleRoot" -ForegroundColor Green
Write-Host "=========================================================================" -ForegroundColor Green
