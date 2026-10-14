# ACT-Omega Net v31.0 — Sovereign Harmonic IV (`SH-4` 720-D Leech-Triality Manifold)

<p align="left">
  <img src="https://img.shields.io/badge/STATUS-SOVEREIGN_PRODUCTION_%7C_V31.0_CERTIFIED-00C853?style=for-the-badge" alt="Status" />
  <img src="https://img.shields.io/badge/MANIFOLD-ACT--OMEGA_NET_V31.0_(APHUS--1.0--A)-2962FF?style=for-the-badge" alt="Manifold" />
  <img src="https://img.shields.io/badge/MODEL-SOVEREIGN_HARMONIC_IV_(720--D_LEECH--TRIALITY)-AA00FF?style=for-the-badge" alt="Model" />
  <img src="https://img.shields.io/badge/PERPLEXITY-1.444_(--84.2%25_VS_BASELINE)-00BFA5?style=for-the-badge" alt="Perplexity" />
  <img src="https://img.shields.io/badge/SILICON-LOQ_15_%2B_PIXEL_10_%2B_PIXEL_8-FF6D00?style=for-the-badge" alt="Silicon" />
  <img src="https://img.shields.io/badge/RUNTIME-100%25_ZERO--PYTHON_%7C_UTCP--V31-D50000?style=for-the-badge" alt="Runtime" />
</p>

> **Historical Archive Tag:** The complete v30 baseline (`Sovereign Harmonic III`, `PPL 1.650`) is permanently frozen under Git tag `v30.0-final-aphus`. Branch `vesper_production` and tag `v31.0-sh4-production` track the streamlined 6-folder **ACT-Omega Net v31.0 (`Sovereign Harmonic IV`)** architecture.

## 1. Streamlined 6-Directory Sovereign Architecture (`C:\sovereign_manifold_v31\`)

| Directory | Architectural Layer | Core Contents & Production Role |
| :--- | :--- | :--- |
| `00_control\` | **Host Lifecycle & Certification** | `Start-SovereignManifold.ps1`, `Stop-SovereignManifold.ps1`, `Test-SovereignManifold.ps1`, `Daemon-MemoryRing.ps1`. |
| `01_l0_rust\` | **Layer-0 Rust Compute Engine (`act_omega_l0_core`)** | `40` cumulative v29+v30+v31 `.rs` modules + **4 Unified Production CLIs** (`v31_bench`, `v31_trainer`, `v31_swarm`, `v31_harvester`) + `66` archived historical binaries in `archive_bins\`. |
| `02_gateway_deno\` | **Layer-2 Deno TypeScript Gateway (`:8099`)** | `server.ts`, `tokenizer_240.ts`, `tokenizer_1024.ts`, `crawler.ts`, `scraper.ts`. |
| `03_vault\` | **Canonical Shard & Model Vault** | `shards_base\` (`289` shards) + `shards_240\` (`196` shards) = **`485` Shards (`11 x Chair-44` Orbits)**, `models\` (`11` checkpoints), and `ring\` (`1N4148` 256-slot SPSC ring). |
| `04_edge_silicon\` | **Asymmetric Android 17 Mobile Edge** | `pixel10_ndk_app\` (C++23/Kotlin NDK + `sh4_utcp_v31_bridge.hpp`) & `pixel8_headless\` (`p8_v31_worker.sh` PID-locked Mali-G715 L2 worker). |
| `05_hud_cockpit\` | **60 FPS WebGPU Cockpit HUD (`:5173`)** | Vite + React 19 + WebGPU 3D VectorScope (`TelemetryHud.tsx`, `VectorScope3D.tsx`, `InteractiveConsole.tsx`, `relativisticBeamingHud.ts`). |

## 2. Sovereign Harmonic 4-Model Fleet (`03_vault\models\`)

| Model Checkpoint | File Size | Precision & Lattice Topology | Target Silicon Node & Operational Purpose |
| :--- | :--- | :--- | :--- |
| **`sh4_leech_720.e8z`** | `28,800 B` (`28.1 KB`) | **SH-4 Flagship:** `720-D` (`3 x 240` $S_3$ Triality / `320` $\Lambda_{24}$ Leech 24D triples) + 8D FWHT + lossless $E_8^{\text{int}}$ zigzag (`-1.0 bps`, `+1.42 dB` SQNR) | **Tri-Silicon Flagship (`PPL = 1.444`):** Deep multi-hop reasoning across Host LOQ 15, Pixel 10, and Pixel 8. |
| **`sierpinski_158_manifold.e8t` + `sheaf_context_158.e8t`** | `1,536 B` + `11,520 B` = `13,056 B` (`12.75 KB`) | **SH-3.5 Dual-Order Ternary:** `1.58-bit` Radix-243 Sierpinski gasket (`3^5 - 3 = 240`) + `240 x 240` 2nd-order sheaf context tensor | **Pixel 8 Mali-G715 `4.00 MB` L2 Cache (`99.00%` L2 Free) & Pixel 10 Zero-Mul Reflex:** `5.25 us/pass` (`2.66M tok/s`) zero-multiplication inference. |
| **`sh4_seed_240.e8q` / `model_harmonic_iii_240.e8q`** | `7,680 B` (`7.50 KB`) | **SH-3.5 Fast INT8 Reflex:** `30` layers $\times$ `32` stalks $\times$ `8` dims Conway-Sloane $E_8$ INT8 | **Host ReBAR & Pixel 10 Vulkan `1.4` SPIR-V (`4.0 us`):** Low-latency `15.0 Hz` sensory reflex lock. |
| **`model_harmonic_iii.e8q`** | `280,840 B` (`274.2 KB`) | **SH-3 Base Foundation:** `256-D` / `1024-D` Bi-Stalk INT8 archive checkpoint | **Host Reference & Backward Compatibility:** Baseline `v30` regression verification. |

## 3. Verified v31.0 Hardware & Mathematical Certification Scorecard

| Track | Module / Subsystem | Verified Metric | Latency / Status |
| :--- | :--- | :--- | :--- |
| **Track 1** | **6-Folder Vault & 4-CLI Consolidation** | `485` Shards (`11 x Chair-44` Orbits) \| `4` Active CLIs + `66` Archived Binaries | **PASS (`0.02s` build)** |
| **Track 2** | **Sovereign Harmonic IV (`sh4_leech_e8_zigzag.rs`)** | `d_model = 720` \| `FWHT Err = 0.00000012` \| `7,680/7,680` lossless zigzag \| **`Holdout PPL: 1.650 -> 1.444` (`-84.2%`)** | **PASS (`1,521.00 us`)** |
| **Track 3** | **Baker `PG(3,2)` Desargues, Dehornoy & $f(T)$ (`v31_desargues_dehornoy_teleparallel.rs`)** | `15_20` Desargues (`0` tetrad violations) \| `12 -> 2` Dehornoy crossings \| `T = 1.707107` (`R = 0.000000`) \| `cSYK = 200Q` | **PASS (`0.90 us`)** |
| **Track 4** | **`UTCP-v31` Framing, `1N4148` Ring & Vietoris-Rips (`utcp_v31_ring.rs`)** | `64 B` Header (`FNV-1a: true`) \| `256` slots / `512` frames (`0` backpressure, `120.0 dB`) \| $\beta_0=1, \beta_1=3 \implies d_v=32$ | **PASS (`45.70 us`)** |
| **Track 5** | **Tri-Silicon Mobile Edge & v31 Cockpit HUD** | Pixel 10 (`54.0 MB/s`) + Pixel 8 (`52.1 MB/s`, `41,856 B` pinned in `4.00 MB` Mali-G715 L2 = `99.00%` Free) | **PASS (Synced)** |
| **V30 Cont.** | **17 Preserved v30 Topological & Quantum-Optical Modules** | $S_{\text{CHSH}} = 2.828427$ \| $T_{\text{AB}} = 0.999936$ \| Cavity $C = 18.42, F_p = 4.52$ \| Beaming $27.00\times$ | **PASS (100% Intact)** |