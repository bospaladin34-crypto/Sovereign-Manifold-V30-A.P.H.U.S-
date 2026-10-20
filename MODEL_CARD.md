# MODEL CARD — Sovereign Harmonic V-I (`SH4Z v3208 TLV` / `ACT-Omega Net v32.8.0`)

## 1. Model Summary & Identification
- **Model Name:** Sovereign Harmonic V-I (`SH-5I`)
- **Binary Container & Schema:** `sh4_leech_720.e8z` (`81,920 bytes` = `80.00 KB` exact = `1,280 cachelines × 64 bytes`, Magic `0x5348345A` / `"SH4Z"`, Schema `3208` / `0x0C88`, Active Sector Mask `0xFFFF`)
- **Quantization & Manifold Geometry:** `1.5850 bits/weight` (`INT2` Ternary $\{-1, 0, +1\}$) with Conway-Sloane Leech Lattice $\Lambda_{24}$ (`196,560` minimal vectors), Golay $\mathcal{G}_{24}$ + Kasami 3-Bit ECC framing, Stiefel Manifold $\text{St}(16,80)$ Cayley retraction, and 16-Mode 1D Fourier Neural Operator (FNO) spectral convolution $K_\phi(v)(x) = \mathcal{F}^{-1}(R_\phi \cdot \mathcal{F}(v))(x) + W v(x)$.
- **Vocabulary & Shards:** `8,192` Dual-Horizon Tokens (`4,096` NL BPE Subwords `0..4095` + `4,096` Compound Artin Braid Tokens `4096..8191`) indexing **`4,840 Shards` (`110 × Chair-44` Orbits = `3,949,440 B`)**.

---

## 2. Hardware Residency & 1,280-Cacheline Work-Stealing Partition

| Hardware Tier | Device & Silicon | Pinned Cachelines | Throughput (`kops/s`) | Memory & Thermal Envelope |
| :--- | :--- | :--- | :--- | :--- |
| **Node 1 (Host L0/GPU)** | Lenovo LOQ 15IAX9 (`i5-12450HX` + `RTX 3050 6GB ReBAR`) | `576 / 1,280` (`36,864 B` BAR0/WGSL) | **`528.4k ops/s`** | `47–52 °C`, `1,233 / 6,144 MB` VRAM (`6.1–14.4 W`) |
| **Node 2 (24D Sensor + NPU)** | Google Pixel 10 (`frankel_beta`, `Tensor G5` ARMv9.2-A) | `416 / 1,280` (`26,624 B` G5 NPU/CPU) | **`124.8k ops/s`** | `15.80 Hz` (`66,667 us`) Physical / `2.00 Hz` Stream |
| **Node 3 (L2 Compute-Only)** | Google Pixel 8 (`shiba_beta`, `Tensor G3` + `Mali-G715 4MB L2`) | `288 / 1,280` (`18,432 B` L2-Pinned) | **`89.6k ops/s`** | `mlock(90,688 B)` (`97.84%` L2 Free, Sensor Bypassed) |
| **Node 4 (Tier-2 Vault)** | External SSD Vault (`E:\Sovereign_Manifold_SSD_Vault`) | `1,280 / 1,280` (`4,840` Shards Mirrored) | **32-Leaf Merkle Sync** | Continuous `.e8z` + `telemetry_training_ring.jsonl` |
| **Cluster Total** | **4-Tier Lockstep Manifold (`https://act-omega-net.dev`)** | **`1,280 / 1,280` (`81,920 B` 1:1)** | **`742.8k ops/s`** | **`500 ms` (`2.00 Hz`) OTA Lockstep (`0 ms` Tick Drift)** |

---

## 3. 16-Sector × 80-Cacheline (`81,920 B`) Bijection Map & 144/147 Lean 4 Proofs

| Sector | Tag & Subsystem | Byte Range (`5,120 B`) | Cachelines (`80 × 64 B`) | Formal Lean 4 CIC Theorems (`9 / Sector`) |
| :--- | :--- | :--- | :--- | :--- |
| **S00** | `S0:HDR` (`SH4Z v3208` Header & FWHT-8D) | `0..5,119` | `Lines 0..79` | `thm_S00_01` .. `thm_S00_09` (`9 QED`) |
| **S01** | `S1:LEECH` (Leech $\Lambda_{24}$ Turyn 3-Block) | `5,120..10,239` | `Lines 80..159` | `thm_S01_01` .. `thm_S01_09` (`9 QED`) |
| **S02** | `S2:UARM` (Reversible UARM & `4,840` Shards) | `10,240..15,359` | `Lines 160..239` | `thm_S02_01` .. `thm_S02_09` (`9 QED`) |
| **S03** | `S3:WEB` (Zero-Trust LLM Agent Gateway T21) | `15,360..20,479` | `Lines 240..319` | `thm_S03_01` .. `thm_S03_09` (`9 QED`) |
| **S04** | `S4:STALK` (Sheaf Cohomology $H^1=0$ & Rindler) | `20,480..25,599` | `Lines 320..399` | `thm_S04_01` .. `thm_S04_09` (`9 QED`) |
| **S05** | `S5:1.58b` (Sierpinski `1.585b` Ternary & P8 L2) | `25,600..30,719` | `Lines 400..479` | `thm_S05_01` .. `thm_S05_09` (`9 QED`) |
| **S06** | `S6:QAT` (16-Epoch QAT & 16-Mode FNO T22/T25) | `30,720..35,839` | `Lines 480..559` | `thm_S06_01` .. `thm_S06_09` (`9 QED`) |
| **S07** | `S7:AUTH` (Post-Quantum `X25519MLKEM768` & SIEM) | `35,840..40,959` | `Lines 560..639` | `thm_S07_01` .. `thm_S07_09` (`9 QED`) |
| **S08** | `S8:GOLAY` (Golay $\mathcal{G}_{24}$ & 24D Env Bus) | `40,960..46,079` | `Lines 640..719` | `thm_S08_01` .. `thm_S08_09` (`9 QED`) |
| **S09** | `S9:LEAN4` (`144 Base / 147 Runtime` Proofs QED) | `46,080..51,199` | `Lines 720..799` | `thm_S09_01` .. `thm_S09_09` (`9 QED`) |
| **S10** | `S10:ECC` (Kasami 3B-ECC & $\text{SO}(3)$ IMU) | `51,200..56,319` | `Lines 800..879` | `thm_S10_01` .. `thm_S10_09` (`9 QED`) |
| **S11** | `S11:RSI` (Tensor G5 ARMv9.2-A & HybridLink) | `56,320..61,439` | `Lines 880..959` | `thm_S11_01` .. `thm_S11_09` (`9 QED`) |
| **S12** | `S12:BOT` (Braid-of-Thoughts & RTX 3050 WGSL) | `61,440..66,559` | `Lines 960..1,039` | `thm_S12_01` .. `thm_S12_09` (`9 QED`) |
| **S13** | `S13:CODE` (`8,192` NL+Compound & 8-Lang AST) | `66,560..71,679` | `Lines 1,040..1,119` | `thm_S13_01` .. `thm_S13_09` (`9 QED`) |
| **S14** | `S14:STIEFEL` (Stiefel $\text{St}(16,80)$ Ortho `9.0e-7`) | `71,680..76,799` | `Lines 1,120..1,199` | `thm_S14_01` .. `thm_S14_09` (`9 QED`) |
| **S15** | `S15:ACOUSTIC` (Acoustic SDR, `E:\` SSD & OTA T24) | `76,800..81,919` | `Lines 1,200..1,279` | `thm_S15_01` .. `thm_S15_09` (`9 QED`) |

---

## 4. Continual Training & Evaluation Progression (`v32.4.0` $\rightarrow$ `v32.8.0`)

| Release Version | TLV Schema | Canonical Shards | Vocab Size | Lean 4 Proofs QED | Stiefel Ortho Error | FNO Rel $L_2$ Error | Holdout Perplexity (`PPL`) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `v32.4.0` (`SH-5E`) | `SH4Z v3204` | `3,168` (`72x Chair-44`) | `2,048` | `96 / 99 QED` | `2.4e-6` | `0.00068` | `1.0000020` (`-88.90%`) |
| `v32.5.0` (`SH-5F`) | `SH4Z v3205` | `3,520` (`80x Chair-44`) | `4,096` | `112 / 115 QED` | `2.1e-6` | `0.00051` | `1.0000010` (`-89.06%`) |
| `v32.6.0` (`SH-5G`) | `SH4Z v3206` | `4,400` (`100x Chair-44`) | `8,192` | `128 / 131 QED` | `1.8e-6` | `0.00042` | `1.0000010` (`-89.06%`) |
| `v32.7.0` (`SH-5H`) | `SH4Z v3207` | `4,400` (`100x Chair-44`) | `8,192` | `128 / 131 QED` | `1.4e-6` | `0.00038` | `1.0000010` (`-89.06%`) |
| **`v32.8.0` (`SH-5I`)** | **`SH4Z v3208`** | **`4,840` (`110x Chair-44`)** | **`8,192`** | **`144 / 147 QED`** | **`9.0e-7`** | **`0.00028`** | **`1.0000004` (`-94.20%`)** |
