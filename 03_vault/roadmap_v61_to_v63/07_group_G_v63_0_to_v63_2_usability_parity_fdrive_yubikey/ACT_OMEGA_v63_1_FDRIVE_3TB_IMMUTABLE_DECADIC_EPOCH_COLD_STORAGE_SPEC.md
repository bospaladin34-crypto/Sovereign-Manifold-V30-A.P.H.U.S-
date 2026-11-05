# ACT-Omega v63.1: `F:\` Drive (`3 TB HDD`) Immutable Decadic Epoch (`v40` / `v50` / `v60` / `v70`) Cold-Storage Architecture & YubiKey Root-of-Trust Attestation

* **Target Cold-Storage Drive:** `F:\ACT_OMEGA_IMMUTABLE_EPOCH_ARCHIVES\` (`3 TB HDD` WORM Vault)
* **One-Command Epoch Archiver & Sealer:** `Invoke_v63_1_FDrive_3TB_Immutable_Decadic_Epoch_Vault_Snapshotter.ps1` (`0` backticks, `-IgnoreWarnings`)
* **Hardware Root of Trust:** Dual-YubiKey (Primary + Backup) Slot-2 HMAC-SHA256 / FIDO2 Merkle Root Attestation

---

## 1. Four-Drive Storage Hierarchy Across Your Workstation (`C:\`, `E:\`, `F:\`, + `Pixel 8`)

Adding your `3 TB HDD` (`F:\`) alongside your two YubiKeys gives ACT-Omega a true enterprise-grade **Hot / Warm / Cold-Immutable Storage Hierarchy**:

| Drive / Node | Hardware Medium | Operational Role in ACT-Omega | Mutation Policy |
| :--- | :--- | :--- | :--- |
| **`C:\` (Internal NVMe)** | High-Speed PCIe NVMe SSD | **Hot Active Workspace:** `C:\sovereign_manifold_v31`, `C:\ACT_OMEGA_7777D_ORTHOPLEX_LAB`, `C:\ACT_OMEGA_MODELS` | Read/Write during active development & live `:8097` MCP inference. |
| **`E:\` (`ORICO` External SSD)** | USB 3.2 SSD | **Warm Staging & Bridge Vault:** `E:\ACT_OMEGA_7777D_AV_ENGINE`, `E:\ACT_OMEGA_COLD_VAULT\7777d_orthoplex_receipts`, `VESPER-OS` shared partition | Append-only receipts & high-bandwidth AV / model staging. |
| **`F:\` (`3 TB HDD`)** | **3,000 GB Spinning HDD** | **Immutable Decadic Epoch Vault (`F:\ACT_OMEGA_IMMUTABLE_EPOCH_ARCHIVES\`):** Full project + model + receipt snapshots at every **10-version milestone (`v40`, `v50`, `v60`, `v70`, ...)** | **WORM (Write-Once, Read-Many):** Sealed with `+R` Read-Only attributes, `IMMUTABLE_LOCK.seal`, Merkle SHA-256 root, and YubiKey signature. |
| **`Pixel 8` (`3A121FDJH00BW5`)** | On-Device UFS 3.1 (`/data/adb/...`) | **Edge Execution Mirror:** `gemma-4-E4B-it-full.sh4z` (`1.978 GiB`) + `orthoplex_7777d\` (`154 KB`) | Verified against Host/YubiKey Merkle root on USB sync. |

---

## 2. Directory Layout on `F:\ACT_OMEGA_IMMUTABLE_EPOCH_ARCHIVES\`

Each 10-version milestone creates a self-contained, read-only locked folder on `F:\`:

```text
F:\ACT_OMEGA_IMMUTABLE_EPOCH_ARCHIVES\
├── EPOCH_V40_HISTORICAL_ARTIFACTS\          # Retroactive v40–v49 scripts, specs & rust modules
├── EPOCH_V50_HISTORICAL_ARTIFACTS\          # Retroactive v50–v59 E8Vault, Pixel 8 root & Gemma 4 specs
└── EPOCH_V60_IMMUTABLE_SNAPSHOT\            # Complete v60+ Master Snapshot (~5.1 GiB packed)
    ├── 01_sovereign_manifold_project\       # Full copy of C:\sovereign_manifold_v31
    ├── 02_orthoplex_7777d_lab\              # Full copy of C:\ACT_OMEGA_7777D_ORTHOPLEX_LAB
    ├── 03_av_generation_engine\             # Full copy of E:\ACT_OMEGA_7777D_AV_ENGINE (.wav/.png/.o7777v)
    ├── 04_cold_vault_receipts\              # Full copy of E:\ACT_OMEGA_COLD_VAULT receipts
    ├── 05_packed_gemma4_sh4z_o7777_models\  # Packed gemma-4-E4B-it & 12B-it (.sh4z + .o7777 + .bin)
    ├── EPOCH_MERKLE_MANIFEST.json           # Every file's byte count + SHA-256 + Master Merkle Root
    ├── YUBIKEY_ATTESTATION.sig              # YubiKey hardware HMAC-SHA256 signature of Merkle Root
    └── IMMUTABLE_LOCK.seal                  # WORM seal preventing overwrite of EPOCH_V60
```

- **Capacity Math on Your `3 TB` (`3,000 GB`) `F:\` Drive:**
  - A complete decadic snapshot including the source codebase, labs, AV engine, receipts, and both packed Gemma 4 models (`E4B-it` `1.978 GiB` + `12B-it` `2.959 GiB` `.sh4z` + `.o7777`) is **`~5.15 GiB`**.
  - That means your `3 TB` `F:\` drive can store **more than `550` full decadic epoch snapshots** (or `~65` snapshots even if you include the `37.17 GiB` raw `BF16` `.safetensors` via `-IncludeRawSafetensors $true`)!

---

## 3. Setting Up Your Two New YubiKeys (Primary + Backup) for `F:\` Epoch Attestation

Buying **two YubiKeys** (one stays in your `LENOVO LOQ 15` USB port as your daily Primary key; the second is programmed with the exact same shared secret and stored in a safe place as your Backup key) avoids any single point of failure:

1. **Program Both YubiKeys with an Identical Slot-2 HMAC-SHA1/SHA256 Secret (One-Time Setup via `ykman`):**
   ```powershell
   # Generate a random 20-byte (40-hex-char) secret once and program BOTH YubiKey #1 and YubiKey #2:
   ykman otp chalresp --touch 2 3132333435363738393031323334353637383930
   ```
   *(The `--touch` flag requires you to physically touch the gold contact on the YubiKey before it signs an `F:\` Epoch Merkle Root!)*
2. **Automatic Signing During `F:\` Epoch Archiving:**
   - When `Invoke_v63_1_FDrive_3TB_Immutable_Decadic_Epoch_Vault_Snapshotter.ps1` finishes computing `epoch_merkle_root_sha256` on `F:\`, it automatically calls `ykman otp calculate 2 <merkle_root_challenge>` and writes the hardware response into `F:\ACT_OMEGA_IMMUTABLE_EPOCH_ARCHIVES\EPOCH_V60_IMMUTABLE_SNAPSHOT\YUBIKEY_ATTESTATION.sig`.

---

## 4. One-Line Commands to Run for `v60` (and Future `v70`, `v80` Jumps)

```powershell
# Snapshot and seal the current v60 Epoch onto F:\ (plus populate v40 & v50 historical folders):
powershell -ExecutionPolicy Bypass -File "$HOME\Downloads\Invoke_v63_1_FDrive_3TB_Immutable_Decadic_Epoch_Vault_Snapshotter.ps1" -EpochVersion "v60"

# When you reach v70, run the exact same script with -EpochVersion "v70":
powershell -ExecutionPolicy Bypass -File "$HOME\Downloads\Invoke_v63_1_FDrive_3TB_Immutable_Decadic_Epoch_Vault_Snapshotter.ps1" -EpochVersion "v70"
```
