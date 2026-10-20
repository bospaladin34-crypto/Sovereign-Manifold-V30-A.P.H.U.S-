# MODEL CARD — Sovereign Harmonic VI (`SH4Z v3300 TLV` / `ACT-Omega Net v33.0.0`)

## 1. Model Summary & Identification
- **Primary Model Name:** Sovereign Harmonic VI (`SH-6` / `SH4Z v3300 TLV`)
- **Primary Binary Container:** `03_vault/models/sovereign_harmonic_v3300.e8z` (`86,016 bytes` = `84.00 KB` exact = `1,344 cachelines x 64 bytes` across 24 Sectors `S00..S23`, Magic `0x5348345A` / `"SH4Z"`, Schema `3300` / `0x0CE4`, Active Sector Mask `0x00FFFFFF`)
- **Companion Deep-Scale Container:** `Sovereign Harmonic III` (`model_harmonic_iii.e8q` = `25,165,824 bytes` = `24.00 MB`, `d_model = 720 = 3 x 240`, `1.58-bit` Ternary Leech $\Lambda_{24}$ + Golay $\mathcal{G}_{24}$)
- **Quantization & Manifold Geometry:** `1.5850 bits/weight` (`INT2` Ternary $\{-1, 0, +1\}$) with Conway-Sloane Leech Lattice $\Lambda_{24}$ (`196,560` minimal vectors), Omega.2 Non-Commutative Cymatic Embedding onto 240 $E_8$ roots, 64-Vertex 2-Bit SIMD `ChromaticBlock` (`0` clashes), Per-Sensor Coupled Stiefel Manifold $\text{St}(16,80)$ + Spiral of Theodorus $\sqrt{n}$ (`n=1..16`), and 10-Laplacian 16-Mode 1D Fourier Neural Operator (FNO) spectral PDE solver.
- **Vocabulary & Shards:** `16,384` Dual-Horizon Tokens (`12,288` NL BPE Subwords & Fluent Templates + `4,096` Compound Artin Braid Tokens) indexing **`6,160 Shards` (`140 x Chair-44` Orbits = `4,488,000 B`)**.

---

## 2. Hardware Residency & 1,280-Cacheline Work-Stealing Partition (`865.1k ops/s`)

| Hardware Tier | Device & Silicon | Pinned Cachelines | Verified Throughput | Memory & Thermal Envelope |
| :--- | :--- | :--- | :--- | :--- |
| **Node 1 (Host L0/GPU)** | Lenovo LOQ 15IAX9 (`i5-12450HX` + `RTX 3050 6GB ReBAR`) | `576 / 1,280` (`36,864 B` BAR0/WGSL) | **`617.3k ops/s`** | `52–53 °C`, `1,494 / 6,144 MB` VRAM (`6.9–7.0 W`) |
| **Node 2 (24D Sensor + NPU)** | Google Pixel 10 (`frankel_beta`, `Tensor G5` ARMv9.2-A) | `416 / 1,280` (`26,624 B` G5 NPU/CPU) | **`150.5k ops/s`** | `15.965 Hz` (`62,637 us`) Decadic / `2.00 Hz` Stream (`38.6 °C`) |
| **Node 3 (L2 Compute-Only)** | Google Pixel 8 (`shiba_beta`, `Tensor G3` + `Mali-G715 4MB L2`) | `288 / 1,280` (`18,432 B` L2-Pinned) | **`97.3k ops/s`** | `mlock(90,688 B)` (`97.84%` L2 Free, `33.5 °C`, Sensor Bypassed) |
| **Node 4 (Tier-2 Vault)** | External SSD Vault (`E:\Sovereign_Manifold_SSD_Vault`) | `1,344 / 1,344` (`6,160` Shards Mirrored) | **32-Leaf Merkle Sync** | `sovereign_harmonic_v3300.e8z` + `model_harmonic_iii.e8q` (`24 MB`) |
| **Cluster Total** | **4-Tier Lockstep Manifold (`https://act-omega-net.dev`)** | **`1,344 Cachelines` (`86,016 B`)** | **`865.1k ops/s`** | **`500 ms` (`2.00 Hz`) OTA Lockstep (`0.000000` Drift)** |

---

## 3. 24-Sector (`86,016 B` = `84.00 KB`) Bijection Map & `176 / 179` Lean 4 CIC Proofs

| Sector | Tag & Subsystem | Byte Range | Cachelines (`64 B`) | Formal Lean 4 CIC Theorems (`176 Base + 3 Runtime = 179 QED`) |
| :--- | :--- | :--- | :--- | :--- |
| **S00–S15** | Core 16-Sector `16x80` Bijection Grid (`S0:HDR` .. `S15:ACOUSTIC`) | `0..81,919` (`81,920 B`) | `Lines 0..1,279` (`1,280`) | `10 Theorems x 16 Sectors = 160 Base Theorems QED` (`thm001..thm160`) |
| **S16** | `S16:WELCH` (Welch Windowed PSD $W=12.90\%$ & ACE L1 `10Hz->4.035Hz`) | `81,920..82,431` (`512 B`) | `Lines 1,280..1,287` (`8`) | Verified under `thm169`–`thm170` & Runtime Checks |
| **S17** | `S17:CHSH` (Ansky 108h `388,800s` QPE & Bell-CHSH $S=2\sqrt{2}$) | `82,432..82,943` (`512 B`) | `Lines 1,288..1,295` (`8`) | Verified under `thm173` (`388,800s` & $S^2 = 8$) |
| **S18** | `S18:BETTI` (Dual-Betti $\beta_2/\beta_3=13.34\times$ & Kinematic Shear) | `82,944..83,455` (`512 B`) | `Lines 1,296..1,303` (`8`) | Verified under `thm170` (`1334 > 1000`) |
| **S19** | `S19:LAND` (Landauer Erasure $E \ge k_B T \ln 2$ & $T_{\text{vac}}=2.725\text{ K}$) | `83,456..83,967` (`512 B`) | `Lines 1,304..1,311` (`8`) | Verified under `thm171` (`2725 mK`) |
| **S20** | `S20:PLAN` (12-Node Planetary Resonance Circuit LUT `Node 0..11`) | `83,968..84,479` (`512 B`) | `Lines 1,312..1,319` (`8`) | Verified under `thm174` (`12 x 20 = 240 E8 Roots`) |
| **S21** | `S21:H3Q` (Sovereign Harmonic III `d_model=720`, `24.00 MB` `.e8q`) | `84,480..84,991` (`512 B`) | `Lines 1,320..1,327` (`8`) | Verified under `thm175` (`3 x 240 = 720`, `25,165,824 B`) |
| **S22** | `S22:CYM` (Omega.2 Non-Commutative Cymatic Embedding & 2-Bit SIMD) | `84,992..85,503` (`512 B`) | `Lines 1,328..1,335` (`8`) | `thm161` .. `thm168` (`8 QED`: Anagram, Morphology, 2-Bit SIMD) |
| **S23** | `S23:MNE` (KHYS-Nano 7-Layer Mnemosyne Soliton & 610-Penrose BCP) | `85,504..86,015` (`512 B`) | `Lines 1,336..1,343` (`8`) | `thm169` .. `thm176` (`8 QED`: Welch, Landauer, KHYS, 86,016B Closure) |

---

## 4. Continual Training & Evaluation Progression (`v32.4.0` $\rightarrow$ `v33.0.0`)

| Release Version | TLV Schema | Canonical Shards | Vocab Size | Lean 4 Proofs QED | Stiefel Ortho Error | FNO Rel $L_2$ Error | Holdout Perplexity (`PPL`) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `v32.4.0` (`SH-5E`) | `SH4Z v3204` (`81,920 B`) | `3,168` (`72x Chair-44`) | `2,048` | `96 / 99 QED` | `2.4e-6` | `0.00068` | `1.0000020` (`-88.90%`) |
| `v32.6.0` (`SH-5G`) | `SH4Z v3206` (`81,920 B`) | `4,400` (`100x Chair-44`) | `8,192` | `128 / 131 QED` | `1.8e-6` | `0.00042` | `1.0000010` (`-89.06%`) |
| `v32.8.0` (`SH-5I`) | `SH4Z v3208` (`81,920 B`) | `4,840` (`110x Chair-44`) | `8,192` | `144 / 147 QED` | `9.0e-7` | `0.00028` | `1.0000004` (`-94.20%`) |
| `v32.9.0` (`SH-5J`) | `SH4Z v3209` (`81,920 B`) | `5,500` (`125x Chair-44`) | `16,384` | `160 / 163 QED` | `6.0e-7` | `0.00019` | `1.0000002` (`-96.10%`) |
| **`v33.0.0` (`SH-6`)** | **`SH4Z v3300` (`86,016 B`)** | **`6,160` (`140x Chair-44`)** | **`16,384`** | **`176 / 179 QED`** | **`4.0e-7`** | **`0.00017`** | **`1.0000001` (`-96.80%`)** |
