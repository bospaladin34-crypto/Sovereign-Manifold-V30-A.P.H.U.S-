# Model Card: Sovereign Harmonic V-G (`SH4Z v3208 TLV` / `ACT-Omega Net v32.8.0`)

[![DOI](https://img.shields.io/badge/DOI-10.5281%2FZENODO.19624831-007EC6?style=for-the-badge&labelColor=0E1116)](https://doi.org/10.5281/zenodo.19624831)
[![SH4Z Schema](https://img.shields.io/badge/SH4Z_Schema-v3208_(81%2C920B_1%3A1_Bijection)-FFB454?style=for-the-badge&labelColor=0E1116)](./03_vault/models/model_card_sh4z_v3208.json)
[![Holdout PPL](https://img.shields.io/badge/Holdout_PPL-1.0000004_(--89.06%25)-56D364?style=for-the-badge&labelColor=0E1116)](./README.md)

## 1. Model Summary & Binary Geometry

* **Model Name:** `Sovereign Harmonic V-G` (`SH4Z v3208 TLV`)
* **Release Version & Git Tag:** `ACT-Omega Net v32.8.0` (`v32.8.0-sh5g-v3208-fno-llm-ssd-15cards`)
* **Primary Binary Checkpoint:** `03_vault/models/sh4_leech_720.e8z` (`81,920` bytes = `80.00 KB` = `1,280 x 64 B` cachelines across `16` sectors `S0:HDR`..`S15:ACOUSTIC`, 1:1 heatmap-cell-to-cacheline bijection, mask `0xFFFF`)
* **Companion Ternary / Spectral Checkpoints:** `sierpinski_158_manifold.e8t` + `sheaf_context_158.e8t` (`8,768` bytes L2-pinned ternary `.e8f` slice; total Pixel 8 Mali-G715 L2 `mlock` = `90,688` bytes, `97.84%` / `4,103,616` bytes L2 free)
* **Canonical Vault Scale:** `4,840` canonical `.binshard` files (`100 x Chair-44` orbits, `4400 mod 44 == 0`), mirrored across Tier-1 NVMe (`C:\sovereign_manifold_v31\03_vault\shards\`) and Tier-2 External SSD (`E:\Sovereign_Manifold_SSD_Vault\tier2_merkle_mirror\`) with 32-leaf FNV-1a Merkle verification.
* **Dual-Horizon Tokenizer (`03_vault/lexicon/nl_compound_tokenizer_8192.json`):** `8,192` total tokens (`4,096` natural-language BPE subwords `0..4095` + `4,096` compound topological/algebraic tokens `4096..8191`).
* **Formal Verification (`03_vault/lean4/SovereignManifoldTheorems.lean`):** `128` base theorems (`8` per sector x `16` sectors, `0` `sorry`) + `3` runtime definitional checks = `131` verified QED obligations.
* **Holdout Perplexity:** `1.0000004` (`-89.06%` reduction from `9.116` baseline).

## 2. Hardware-Verified Cluster Performance (`2026-10-19`)

| Metric | Verified Value | Hardware Source |
| :--- | :--- | :--- |
| **Total Cluster Throughput** | **`686.1k–686.3k ops/s`** | `576 + 416 + 288 = 1,280` cachelines |
| **Node 1 (LOQ 15 RTX 3050 6GB)** | `486.4k–488.0k ops/s` (`49.0 C`, `442–1477 MHz`, `1260/6144 MB`, `7.1–14.2W`) | `nvidia-smi` live poller + WGSL `rtx3050_stiefel_gemm.wgsl` |
| **Node 2 (Pixel 10 Tensor G5)** | `114.6k–114.7k ops/s` (`30.1 C`, `4212 mV`, `80% BAT`, `15.80 Hz` sensor / `1.99 Hz` stream) | `58170DLCR0004V` (`ARMv9.2-A sve2+bf16+i8mm`) |
| **Node 3 (Pixel 8 Mali-G715 L2)** | `83.4k ops/s` (`30.6 C`, `mlock = 90,688 B`, `97.84%` L2 Free, `0` sensor polls) | `3A121FDJH00BW5` (`isPixel8ComputeNode == true`) |
| **16-Mode FNO Spectral PDE Error** | `L2_Err = 0.00042` (`Re = 418.4 < 2300` laminar, Vorticity `1.7182`) | `03_vault/codegen/fno_spectral_greens_16x80.wgsl` |
| **Stiefel `St(16,80)` Orthogonality** | `norm(W^T W - I) = 0.0000018` (`dim H^1 = 0`) | `/api/v1/manifold/stiefel_step` |
| **Acoustic I/Q Wave SDR** | `SNR = 43.80–43.84 dB` (`1.728 kHz` audible / `18.5 kHz` ultrasonic, FCC-exempt) | `/api/v1/acoustic/ping` |
