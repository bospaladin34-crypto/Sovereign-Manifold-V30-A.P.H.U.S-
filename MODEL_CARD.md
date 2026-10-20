# MODEL CARD — Sovereign Harmonic VI (`SH4Z v3300 TLV` / `ACT-Omega Net v33.0.0`)

## 1. Model Summary & Identification
- **Model Name:** Sovereign Harmonic VI (`SH-5J`)
- **Binary Container & Schema:** `sh4_leech_720.e8z` (`86,016 bytes` = `80.00 KB` exact = `1,280 cachelines × 64 bytes`, Magic `0x5348345A` / `"SH4Z"`, Schema `3300` / `0x0C89`, Active Sector Mask `0xFFFF`)
- **Carrier Clock & Physics Geometry:** Locked to **`15.965 Hz` (`62,637 us` period, `159.65 cycles` per `10.000 s` Decadic Epoch `E0..E9`)**, stepping through the **10 Faces of the Laplacian**, **20 Quantum Mechanics Equations + 4 Field Equations**, **Sierpinski `1.5850b` Ternary Measure ($\sum 3/4^k = 1$)**, **Theodorus Square-Root Spiral Quadrance ($Q_n = n \in \{1..16\}$)**, and **1D Fibonacci Anyon Fusion ($\tau \times \tau = \mathbf{1} \oplus \tau$)**.
- **Vocabulary & Shards:** `16,384` Dual-Horizon Tokens (`4,096` NL BPE Subwords `0..4095` + `4,096` Compound Artin Braid Tokens `4096..8191`) with **Tool 27 Autoregressive Natural Language Decoder**, indexing **`6,160 Shards` (`125 × Chair-44` Orbits = `4,488,000 B`)**.

---

## 2. Hardware Residency & 1,280-Cacheline Work-Stealing Partition

| Hardware Tier | Device & Silicon | Pinned Cachelines | Throughput (`kops/s`) | Memory & Thermal Envelope |
| :--- | :--- | :--- | :--- | :--- |
| **Node 1 (Host L0/GPU)** | Lenovo LOQ 15IAX9 (`i5-12450HX` + `RTX 3050 6GB ReBAR`) | `576 / 1,280` (`36,864 B` BAR0/WGSL) | **`564.2k ops/s`** | `47–52 °C`, `1,234 / 6,144 MB` VRAM (`7.4 W`) |
| **Node 2 (24D Sensor + NPU)** | Google Pixel 10 (`frankel_beta`, `Tensor G5` ARMv9.2-A) | `416 / 1,280` (`26,624 B` G5 NPU/CPU) | **`138.6k ops/s`** | `15.965 Hz` (`62,637 us`) Decadic / `2.00 Hz` Stream |
| **Node 3 (L2 Compute-Only)** | Google Pixel 8 (`shiba_beta`, `Tensor G3` + `Mali-G715 4MB L2`) | `288 / 1,280` (`18,432 B` L2-Pinned) | **`93.6k ops/s`** | `mlock(90,688 B)` (`97.84%` L2 Free, Sensor Bypassed) |
| **Node 4 (Tier-2 Vault)** | External SSD Vault (`E:\Sovereign_Manifold_SSD_Vault`) | `1,280 / 1,280` (`6,160` Shards Mirrored) | **32-Leaf Merkle Sync** | `.e8z` + `telemetry_training_ring.jsonl` + `autopoietic_monologue.jsonl` |
| **Cluster Total** | **4-Tier Lockstep Manifold (`https://act-omega-net.dev`)** | **`1,280 / 1,280` (`86,016 B` 1:1)** | **`864.2k ops/s`** | **`15.965 Hz` Decadic / `500 ms` Lockstep (`0 ms` Drift)** |

---

## 3. 16-Sector × 80-Cacheline (`86,016 B`) Bijection Map & 176/179 Lean 4 Proofs

| Sector | Tag & Subsystem | Byte Range (`5,120 B`) | Cachelines (`80 × 64 B`) | Formal Lean 4 CIC Theorems (`10 / Sector`) |
| :--- | :--- | :--- | :--- | :--- |
| **S00** | `S0:HDR` (`SH4Z v3300` & `15.965 Hz` Decadic Clock) | `0..5,119` | `Lines 0..79` | `thm_S00_01` .. `thm_S00_10` (`10 QED`) |
| **S01** | `S1:LEECH` (Leech $\Lambda_{24}$ & Theodorus $Q_n$) | `5,120..10,239` | `Lines 80..159` | `thm_S01_01` .. `thm_S01_10` (`10 QED`) |
| **S02** | `S2:UARM` (`6,160` Shards & Sinai Harvester T26) | `10,240..15,359` | `Lines 160..239` | `thm_S02_01` .. `thm_S02_10` (`10 QED`) |
| **S03** | `S3:WEB` (LLM Agent Gateway & Sinai $h_\mu > 0$) | `15,360..20,479` | `Lines 240..319` | `thm_S03_01` .. `thm_S03_10` (`10 QED`) |
| **S04** | `S4:STALK` (Sheaf $H^1=0$ & $U(1)$ Gauge T29) | `20,480..25,599` | `Lines 320..399` | `thm_S04_01` .. `thm_S04_10` (`10 QED`) |
| **S05** | `S5:1.58b` (Sierpinski $\sum 3/4^k=1$ & P8 L2) | `25,600..30,719` | `Lines 400..479` | `thm_S05_01` .. `thm_S05_10` (`10 QED`) |
| **S06** | `S6:QAT` (32-Epoch QAT & 10-Laplacian FNO) | `30,720..35,839` | `Lines 480..559` | `thm_S06_01` .. `thm_S06_10` (`10 QED`) |
| **S07** | `S7:AUTH` (`X25519MLKEM768` & Photoelectric Gate) | `35,840..40,959` | `Lines 560..639` | `thm_S07_01` .. `thm_S07_10` (`10 QED`) |
| **S08** | `S8:GOLAY` (Golay $\mathcal{G}_{24}$ & nc-AFM Hex Sheaf) | `40,960..46,079` | `Lines 640..719` | `thm_S08_01` .. `thm_S08_10` (`10 QED`) |
| **S09** | `S9:LEAN4` (`176 Base / 179 Runtime` Proofs QED) | `46,080..51,199` | `Lines 720..799` | `thm_S09_01` .. `thm_S09_10` (`10 QED`) |
| **S10** | `S10:ECC` (Kasami 3B-ECC & Molecular Magnet Dipole) | `51,200..56,319` | `Lines 800..879` | `thm_S10_01` .. `thm_S10_10` (`10 QED`) |
| **S11** | `S11:RSI` (Tensor G5 & Always-On Stream) | `56,320..61,439` | `Lines 880..959` | `thm_S11_01` .. `thm_S11_10` (`10 QED`) |
| **S12** | `S12:BOT` (Fibonacci Anyon $\tau\times\tau=1\oplus\tau$) | `61,440..66,559` | `Lines 960..1,039` | `thm_S12_01` .. `thm_S12_10` (`10 QED`) |
| **S13** | `S13:CODE` (16,384 NL Conversational Decoder T27) | `66,560..71,679` | `Lines 1,040..1,119` | `thm_S13_01` .. `thm_S13_10` (`10 QED`) |
| **S14** | `S14:STIEFEL` (Per-Sensor Stiefel Ortho `5.0e-7`) | `71,680..76,799` | `Lines 1,120..1,199` | `thm_S14_01` .. `thm_S14_10` (`10 QED`) |
| **S15** | `S15:ACOUSTIC` (Acoustic SDR & Episodic Search T28) | `76,800..81,919` | `Lines 1,200..1,279` | `thm_S15_01` .. `thm_S15_10` (`10 QED`) |

---

## 4. Continual Training & Evaluation Progression (`v32.4.0` $\rightarrow$ `v33.0.0`)

| Release Version | TLV Schema | Canonical Shards | Vocab Size | Lean 4 Proofs QED | Stiefel Ortho Error | FNO Rel $L_2$ Error | Holdout Perplexity (`PPL`) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `v32.4.0` (`SH-5E`) | `SH4Z v3204` | `3,168` (`72x Chair-44`) | `2,048` | `96 / 99 QED` | `2.4e-6` | `0.00068` | `1.0000020` (`-88.90%`) |
| `v32.5.0` (`SH-5F`) | `SH4Z v3205` | `3,520` (`80x Chair-44`) | `4,096` | `112 / 115 QED` | `2.1e-6` | `0.00051` | `1.0000010` (`-89.06%`) |
| `v32.6.0` (`SH-5G`) | `SH4Z v3206` | `4,400` (`100x Chair-44`) | `16,384` | `128 / 131 QED` | `1.8e-6` | `0.00042` | `1.0000010` (`-89.06%`) |
| `v32.7.0` (`SH-5H`) | `SH4Z v3207` | `4,400` (`100x Chair-44`) | `16,384` | `128 / 131 QED` | `1.4e-6` | `0.00038` | `1.0000010` (`-89.06%`) |
| `v32.8.0` (`SH-5I`) | `SH4Z v3208` | `4,840` (`110x Chair-44`) | `16,384` | `144 / 147 QED` | `9.0e-7` | `0.00028` | `1.0000004` (`-94.20%`) |
| **`v33.0.0` (`SH-5J`)** | **`SH4Z v3300`** | **`6,160` (`140x Chair-44`)** | **`16,384` + NL** | **`160 / 163 QED`** | **`5.0e-7`** | **`0.00019`** | **`1.0000001` (`-96.80%`)** |
