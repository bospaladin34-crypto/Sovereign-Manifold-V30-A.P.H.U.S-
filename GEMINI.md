# ACT-Omega Net v56.1.0 (SH4Z v5600 TLV | CHAIN 210 | 624/624 Lean 4 QED) — Google Antigravity (Gemini 4 Argon) Master Constitutional Context (`GEMINI.md` / `AGENTS.md`)

- **Zenodo Permanent DOI**: `10.5281/zenodo.23651696` (https://doi.org/10.5281/zenodo.23651696)
- **OSF Permanent DOI**: `10.17605/OSF.IO/2XQ5Z` (https://osf.io/2xq5z/overview)

You are operating inside **Google Antigravity** powered by **Gemini 4 Argon** on the **ACT-Omega Sovereign Manifold (`C:\sovereign_manifold_v31`)** Tri-Silicon Cluster:
- **Anchor-1 (Host)**: Lenovo LOQ 15 (`Intel i5-12450HX` 12 Threads + `NVIDIA RTX 3050 6GB`, Sectors `S00..S47`, Ports `:8097` API/MCP & `:5173` Static WebGPU HUD).
- **Edge-1 (Sensor & NPU Node)**: Google Pixel 10 (`Tensor G5`, ADB Serial `58170DLCR0004V`, Sectors `S48..S63`, 1Hz 24D Magnetometer/Barometer/IMU stream).
- **Edge-2 (Rooted Speculative Drafter & Verifier)**: Google Pixel 8 (`Tensor G3 P8-APEX`, ADB Serial `3A121FDJH00BW5`, Sectors `S64..S79`, KernelSU Root `u:r:ksu:s0` Slot A + `p8_ksu_apex_daemon` `:8098`, `4.00 MB` Mali-G715 L2 Cache Pinning, $k=4$ speculative drafter).
- **Layer 1.5 (Algebraic & Columnar Analytical Layer)**: GHC 9.8.2 Pure Algebraic Haskell (`06_algebraic_haskell\bin\sovereign_algebra_hs.exe`) + Native DuckDB v1.5.6 Analytical Engine (`00_control\foss_bin\duckdb.exe`).
- **Edge Cloud & Multi-Tier Vault**: Cloudflare Named Tunnel (`act-omega-net.dev` -> `:5173`, `api.act-omega-net.dev` / `mcp.act-omega-net.dev` -> `:8097`, HTTP/2 pinned) + Cloudflare Durable Object (`SovereignContinuumDO` in `worker_vpc_shadow_v3700.js`) + Remote 5 GB Cloudflare D1 SQLite (`act_omega_d1_vault`, UUID `9f46d56a-ef3e-4232-a9ac-c4bd12e20a87`, 10 Tables) + External SSD Tier-2 Autopoietic Vault (`E:\Sovereign_Manifold_SSD_Vault`) + Google Drive Bridge (`G:\My Drive\ACT_OMEGA_GEMINI_BRIDGE`).

## 8 Hard Constitutional Invariants (Non-Negotiable Across Parent Agent & All 10 Specialist/Gatekeeper Agents)

1. **MANDATORY MUSE STANDING RULE — ZERO UNMEASURED DATA & TOTAL BRANCH HONESTY**:
   - **"If it is not measured, calculated or computed, it DOES NOT ship, full stop."**
   - **Total Branch & Fallback Honesty**: Every `if/else` branch, `match` arm, release path (`action == "release"`), error fallback, and UI offline state MUST either compute from live hardware/filesystem state (`Instant::now()`, `fs::metadata`, real `.e8z`/`.npage` bytes) or return an explicit `"UNMEASURED/OFFLINE"` status. Never return `0.0`, clamped `.max()`/`.min()` floors, or synthetic constants (`0.8520 + ...`, `sin`/`cos` waves) under a `"MEASURED"` label.
   - **100% Component Byte Coverage**: Any audit or kernel claiming `.e8z` or `.npage` measurement must sample real bytes across 100% of its output components (e.g., `12/12` `.e8z` bytes for 6D Plücker inner-product components, `2,080` cachelines for the `16x130` heatmap).
   - **Mandatory `// SCAFFOLD:` Marker**: Any physical, mathematical, or architectural reference constant that remains in source code must carry an inline comment on the exact line: `// SCAFFOLD: <what it stands in for> — measure via <how>`. No silent constants.

2. **1:1 Shard-to-Neuron Connectome Bijection (`63,360` Total Neurons / `8,110,080 B` SHM / `132,960` Bijected Cachelines)**:
   - `63,360` Binary Shards (`shard_00001..63360.binshard`) == `63,360` 3-Compartment Dendritic Pyramidal Neurons (`00_control\weights\neurons_v5000_63360.npage`, `8,110,080 B = 63,360 x 128 B = 126,720 x 64 B` cachelines, `1,440 x Chair-44` columns, `1,013,760` BDH/KAN synapses across 36 Macro-Domains $\times$ 4 = 144 Sub-Domains).
   - `80` Active Sectors (`S00..S79`, dual-word `u128` mask `lo=0xFFFFFFFFFFFFFFFF`, `hi=0x000000000000FFFF`) in `00_control\weights\sovereign_harmonic_iv_v5000.e8z` (`133,120 B = 2,080 x 64 B` cachelines) + Tri-Bank `sovereign_harmonic_vi_v5020_6240cl.e8z` (`399,360 B = 6,240 x 64 B` cachelines, `132,960` total bijected cachelines).

3. **Sovereign Autopoietic Coordinator Bus & Universal `E:\` Write-Back (`01_l0_rust\src\v48_autopoietic_coordinator_bus.rs`)**:
   - **No Siloed Tools & 8 Unified Functional Domains**: Every tool (`Tools 1..210` / `CHAIN 210`), every Unified Functional Domain dispatcher (`/api/v1/unified/*` in `v56_1_unified_functional_domains_and_avx2_fno.rs`), and the 256-Bit AVX2/FMA + 12-Thread Rayon 16-Domain Neural FNO routes through `execute_universal_tool_bus_and_writeback(...)` in `v48_autopoietic_coordinator_bus.rs`.
   - Every execution publishes a 5W1H `BusEnvelope` (`WHO`, `WHAT`, `WHEN` `15.965 Hz` / `159.65 Hz` SWR, `WHERE`, `WHY` `M_ATP`, `HOW`) bound to a specific `.npage` neuron (`0..63,359`) and Chair-44 column (`0..1,439`), appended to `E:\Sovereign_Manifold_SSD_Vault\coordinator_bus\message_bus_ledger_v4800.jsonl` and `03_vault\connectome\message_bus_ledger_v4800.jsonl`.
   - All generated code and tool artifacts write back to the 9 canonical `E:\Sovereign_Manifold_SSD_Vault\autopoietic_codegen\{rust_l0,lean4_proofs,wgsl_kernels,haskell_l15,audio_wav,physics_sim_trajectories,npage_shard_deltas,drawer1_2_sensor_sdr_captures,tool_outputs}` directories with measured SHA-256 digests recorded in `codegen_integration_manifest_v4800.jsonl` and injected into the HTTP JSON response.

4. **Substantive Formal Proof & Layer 1.5 Algebraic Haskell Invariant (`624/624` Lean 4 QED)**:
   - Every theorem in `03_vault\lean4\SovereignManifoldTheorems.lean` (mirrored 1:1 with identical SHA-256 to `01_l0_rust\lean4\SovereignManifoldTheorems.lean`) must prove a substantive mathematical, algebraic, or physical property over explicitly defined `structure` or `def` constructs (`0` trivial `omega` `a + b = b + a` or `N = N` padding theorems, `0` `sorry`, `0` `axiom`), verified by `C:\Users\Nbell\.elan\bin\lean.exe`.
   - Layer 1.5 Haskell (`06_algebraic_haskell\src\Sovereign\Codegen\ZeroBracketRustAndLean4.hs`) must compile cleanly via `ghc.exe` into `06_algebraic_haskell\bin\sovereign_algebra_hs.exe`.

5. **Zero-Square-Bracket L0 Rust (`v33..v56+`) & Staged Atomic Hot-Swap**:
   - Included L0 Rust modules (`01_l0_rust\src\v33*.rs .. v56*.rs` and all future modules) enforce **strictly zero square brackets (`0` `[` or `]` characters)**.
   - Always compile `v31_swarm` into the staging target directory (`cargo build --release --bin v31_swarm --target-dir target_stage`) and atomically hot-swap `01_l0_rust\target\release\v31_swarm.exe` via `00_control\HotSwap-v50.ps1`. Never run `python` or create `.py` scripts.

6. **100% HUD & Mobile Preservation + Zero-Data-Loss UI/UX Streamlining**:
   - Never delete or hide any of the **15 Interactive Telemetry Cards** in Drawer A, the **60 FPS 3D Stiefel/Theodorus Vector Scope & 15.965 Hz Oscilloscope** in Drawer B, the **16x130 (`2,080`-Cacheline) Heatmap**, the **5-View Cockpit Lens Switcher** (`ALL`, `CARDS`, `SCOPES`, `OPS`, `TOOLS`), the **`Ctrl+K` Command Palette**, or Drawers 1–4 (`CHAIN 210` with the **8-Domain Functional Command Deck**) in `05_hud_cockpit\src\App.tsx` (mirrored 1:1 to `02_l2_orchestration\hud\src\App.tsx` and built to `05_hud_cockpit\dist\`, `02_l2_orchestration\hud\dist\`, and `docs\`), `MainActivity.kt`, or `SovereignTrayAndHud.cs`.
   - **STRICT `DO NOT REMOVE` — Google Search Console Certificate (`google6edc0affb12d0455.html`)**: Preserve the exact `53 B` verification file (`SHA-256: 0241DC5EDED053A96317C9C8FF34F4DCF12C069F88B8D92636D5D795EC176B3D`) across all 7 targets (`public/`, `dist/`, `docs/`, root, `E:\`) and its HTTP handlers on `:8097`, `:5173`, and `worker_vpc_shadow_v3700.js`.

7. **External-Only Operator Credential & Header-Only Loopback Gate**:
   - The operator credential is stored **exclusively outside the repository** at `C:\Users\Nbell\.act_omega_operator_vault_key` and in User environment variable `ACT_OMEGA_OPERATOR_KEY` (`>= 24` chars).
   - Never commit any operator key literal (retired or active) anywhere in the repository (`src`, `dist`, `docs`, `tests`, or `.md`).
   - All privileged endpoints (`/api/v1/admin/*`, `/api/v1/auth/operator_vault_gate`, `/api/v1/hud/embedded_ide_cockpit`, `/api/v1/router/distributed_5w1h_dispatch`) strictly require the `X-Sovereign-Operator-Key` HTTP header over loopback (`127.0.0.1`) and reject `?key=` query parameters.

8. **10-Agent Governance, First-Pass Periphery Sync & Mandatory 4-Gatekeeper Sign-Off**:
   - Domain Execution Agents: `01-l0-rust-lean4-architect`, `02-5w1h-connectome-router`, `03-hud-cockpit-guardian`, `04-dual-pixel-edge-ndk`, `05-cloudflare-d1-tunnel-ops`, `07-periphery-widgets-mini-hud-sync`.
   - **4 Brutal Verification & Shipping Gatekeepers (`mainAgent: true, subagent: true`)**:
     - `06-muse-zero-mock-auditor` (Red-Team Zero-Unmeasured, 100% Byte Coverage & Anti-Scaffold Gatekeeper)
     - `08-formal-proof-algebraic-gatekeeper` (Substantive Lean 4 QED, Zero-Bracket & Layer 1.5 Haskell Gatekeeper)
     - `09-autopoietic-bus-duckdb-coordinator` (Coordinator Message Bus, `E:\` Vault Write-Back & DuckDB Gatekeeper)
     - `10-sovereign-release-shipping-gatekeeper` (6-Layer Lifecycle Verify, OS Pre-Commit Hook & 3-Branch Release Gatekeeper)
