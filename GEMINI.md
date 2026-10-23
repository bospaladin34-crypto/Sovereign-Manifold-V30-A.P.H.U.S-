# ACT-Omega Net v46.0.0 (SH4Z v4600 TLV) — Google Antigravity (Gemini 4 Argon) Master Context (`GEMINI.md`)

You are operating inside **Google Antigravity** powered by **Gemini 4 Argon** on the **ACT-Omega Sovereign Manifold (`C:\sovereign_manifold_v31`)** Tri-Silicon Cluster:
- **Anchor-1 (Host)**: Lenovo LOQ 15 (`Intel i5-12450HX` 12 Threads + `NVIDIA RTX 3050 6GB`, Sectors `S00..S47`, Ports `:8097` & `:5173`).
- **Edge-1 (Sensor & NPU Node)**: Google Pixel 10 (`Tensor G5`, ADB Serial `58170DLCR0004V`, Sectors `S48..S63`, 1Hz 24D Magnetometer/Barometer/IMU stream).
- **Edge-2 (Speculative Verifier)**: Google Pixel 8 (`Tensor G3 P8-APEX`, ADB Serial `3A121FDJH00BW5`, Sectors `S64..S79`, `4.00 MB` Mali-G715 L2 Cache Pinning).
- **Edge Cloud & Vault**: Cloudflare Named Tunnel (`act-omega-net.dev` -> `:5173`, `api.act-omega-net.dev` / `mcp.act-omega-net.dev` -> `:8097`) + Remote 5 GB Cloudflare D1 SQLite (`act_omega_d1_vault`, UUID `9f46d56a-ef3e-4232-a9ac-c4bd12e20a87`, 10 Tables) + External SSD Tier-2 Vault (`E:\Sovereign_Manifold_SSD_Vault`) + Google Drive Bridge (`G:\My Drive\ACT_OMEGA_GEMINI_BRIDGE`).

## Hard Architectural Invariants (Always Enforced)
1. **MANDATORY MUSE STANDING RULE — ZERO UNMEASURED DATA**:
   - **"If it is not measured, calculated or computed, it DOES NOT ship, full stop."**
   - This applies to the Parent Agent and ALL Subagents without exception. Never emit hardcoded telemetry constants, fabricated QAT perplexity/loss values, clamped `.max()`/`.min()` floors that disguise runtime metrics, hardcoded SHA-256 digests, synthetic `sin`/`cos` UI heatmaps, unauthenticated admin endpoints, or unconditional "all-green" audits without real failure thresholds.
2. **1:1 Shard-to-Neuron Connectome Bijection**:
   - `21,120` Core Binary Shards (`03_vault\shards\shard_00001..21120.binshard`) == `21,120` Core 3-Compartment Dendritic Pyramidal Neurons (`00_control\weights\neurons_v4000.npage`, `2,703,360 B = 21,120 x 128 B`, `480 x Chair-44` columns, `168,960` BDH/KAN synapses, SHA-256 `aee7711086a07bb6ddebc9e347ed4d68d3a38b57d57b08f9089d22345fa07d6d`).
   - `21,120` Expansion Binary Shards (`03_vault\shards_expansion\shard_21121..42240.binshard`) + Core == `42,240` Total Combined Dendritic Neurons (`00_control\weights\neurons_v4600_42240.npage`, `5,406,720 B = 42,240 x 128 B`, `960 x Chair-44` columns, `337,920` synapses).
   - `80` Active Sectors (`S00..S79`, dual-word `u128` mask `lo=0xFFFFFFFFFFFFFFFF`, `hi=0x000000000000FFFF`) in `00_control\weights\sovereign_harmonic_iv_v4000.e8z` (`133,120 B = 2,080 x 64 B` cachelines, SHA-256 `c383b1b7d00e6ce8cef22593536aea2d66523d53360c3552a64970a61e394b23`).
3. **Deep 5W1H Metabolic Harness + Neuron Connectome Coupling (`Tools 37, 42, 45, 65 & 70`)**:
   - Every routing and scheduling decision in `01_l0_rust\src\v37_metabolic_harness_5w1h.rs` and `v42_distributed_5w1h_router_ide_vault.rs` evaluates `WHO`, `WHAT`, `WHEN` (`15.965 Hz` Decadic clock + `159.65 Hz` SWR replay), `WHERE` (`LOQ 15` / `Pixel 10` / `Pixel 8` / `E:\ SSD` / `Cloudflare D1`), `WHY` (`M_ATP` across 4 Metabolic Bands), and `HOW`, directly bound to `.npage` neurons and logged to Cloudflare D1 (`harness_5w1h_audit_log`, `npage_tier_snapshots`, `v42_5w1h_distributed_routes`).
4. **100% HUD & Mobile Preservation Rule**:
   - Never delete or hide any of the **15 Interactive Telemetry Cards** in Drawer A, the **60 FPS 3D Stiefel/Theodorus Vector Scope & 15.965 Hz Oscilloscope** in Drawer B, the **16x130 (`2,080`-Cacheline) Heatmap**, or Drawers 1–4 in `05_hud_cockpit\src\App.tsx` or `04_edge_silicon\pixel10_ndk_app\app\src\main\java\com\actomega\manifold\MainActivity.kt`.
5. **Zero-Square-Bracket L0 Rust & Zero-Mock Muse Mandate**:
   - Included L0 Rust modules (`v33..v46`) enforce zero square brackets where required by the compiler verifier, and all telemetry metrics must derive from real hardware/filesystem measurements (`Instant::now()`, `fs::metadata`, real SHA-256 digests).
6. **First-Pass Periphery, Widget, Mini-HUD & Edge Synchronization (`periphery-widgets-mini-hud-sync`)**:
   - On every version bump, UI update, or telemetry schema change, invoke `periphery-widgets-mini-hud-sync` on the first pass to synchronize the Windows 11 Native Tray & Mini-HUD (`00_control\Win11_Native_Tray_HUD\SovereignTrayAndHud.cs` -> `SovereignCockpitHUD.exe`), Android Homescreen Widget & Live Wallpaper (`sovereign_heatmap_widget.xml`, `strings.xml`, `AndroidManifest.xml`, `ACTION_REFRESH_HEATMAP`), PWA Service Worker cache key (`05_hud_cockpit\public\sw.js`, `manifest.webmanifest`, `docs\` mirror), Cloudflare Edge Worker (`worker_continuum_do.js`, `cloudflare_named_config.yml`, D1 SQL scripts), and PowerShell/Markdown docs.
