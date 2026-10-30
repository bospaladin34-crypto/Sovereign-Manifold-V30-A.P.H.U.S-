# ACT-Omega Net v56.1.0 (Functional Tool Consolidation, Universal E:\ Write-Back, Vectorized 16-Domain FNO, GSC Lock & Graceful Reboot)
# E2E Test Infrastructure Specification & Developer Guide (`TEST_INFRA.md`)

- **Milestone**: ACT-Omega Net v56.1.0 (`CHAIN 210` Master Milestone / `SH4Z v5600 TLV` / `v56.1.0`)
- **System**: Sovereign Manifold Tri-Silicon Cluster (`C:\sovereign_manifold_v31`)
- **Author**: E2E Testing Track Test Writer (`teamwork_test_writer_e2e_1`)
- **Date**: October 29, 2026
- **Test Harness Framework**: Native Windows PowerShell 5.1 / PowerShell Core (Strict Zero Python)
- **Status**: **DEPLOYED & ACTIVE (DUAL-TRACK MASTER SUITE)**

---

## 1. Executive Summary & Purpose

The ACT-Omega Net v56.1.0 test infrastructure establishes a rigorous, automated, opaque-box end-to-end verification harness across all 14 architectural features cataloged in `PROJECT.md`. It validates the 5 core milestones of the v56.1.0 Master Plan:
1. **Milestone 0: Permanent Google Search Console Certificate Lock (`R1`)**: File mirroring of `google6edc0affb12d0455.html` (exact 53 bytes) across 7 deployment targets, explicit L0 Rust HTTP handlers on ports `:8097` and `:5173`, Cloudflare Edge Worker route handling, and invariant script checks.
2. **Milestone 1: Universal Autopoietic Coordinator Bus & 9-Directory Write-Back (`R2`)**: Addition of the 9th codegen sink (`tool_outputs`), implementation of `execute_universal_tool_bus_and_writeback(...)` with strict zero square brackets, routing of all 210 tools (`T01..T210`) to write authentic files on `E:\Sovereign_Manifold_SSD_Vault\autopoietic_codegen\<domain>\` and inject response telemetry (`e_vault_writeback_path`, `e_vault_writeback_bytes`, `e_vault_writeback_sha256`, `autopoietic_bus_seq`).
3. **Milestone 2: 8 Functional Domain Dispatchers & 256-Bit AVX2/Rayon FNO (`R3` & `R4`)**: Zero-square-bracket module `v56_1_unified_functional_domains_and_avx2_fno.rs` implementing `/api/v1/unified/catalog` and 8 unified domain dispatchers, coupled with a 256-bit AVX2/FMA + 12-thread Rayon spectral Fourier Neural Operator kernel over 63,360 neurons and 80 sectors with live telemetry wiring.
4. **Milestone 3: UI/UX Decluttering & Functional Consolidation Across HUD, Mobile & Tray (`R5`)**: Drawer 4 replacement with the 8-Domain Functional Command Deck, while strictly preserving 100% of all 15 Telemetry Cards, 60 FPS Scopes, 16x130 Heatmap, 5 Lenses, Ctrl+K Palette, Drawers 1–3, and 5 interactive Drawer 4 panels across Web HUD, Android NDK (`MainActivity.kt`), and Win11 Tray HUD (`SovereignTrayAndHud.cs`).
5. **Milestone 4: Lifecycle Script Hardening, 4-Gatekeeper Audit & Graceful Shutdown (`R6`)**: Hardening of `Sovereign-Lifecycle.ps1` for clean process termination (Tray HUD, port 8098 apex daemon), continuum capsule flush, full 4-gatekeeper verification, and graceful cluster shutdown for physical device reboot.

---

## 2. Hard Testing Constraints & Architectural Invariants

### 2.1 Strict Zero-Python Mandate
- **Rule**: Under no circumstances shall Python (`python`, `python3`, `.py`) be executed or created for any test, runner, assertion script, fixture, or build step.
- **Enforcement**: All test runners, assertions, and harness utilities are implemented strictly in native Windows PowerShell (`.ps1`) leveraging Windows native APIs, WebSockets, REST methods, and binary byte scanners.

### 2.2 Muse Zero-Unmeasured-Data Mandate & Total Branch Honesty Law
- **Rule**: **"If it is not measured, calculated or computed, it DOES NOT ship, full stop."**
- **Enforcement**:
  - No mock fixtures, no synthetic `sin`/`cos` fallbacks disguising unmeasured data, no hardcoded synthetic hash digests, and no unconditional passes.
  - Every `if/else` branch, `match` arm, and error fallback MUST either compute from live hardware/filesystem state (`Instant::now()`, `fs::metadata`, real `.e8z`/`.npage` bytes) or return an explicit `"UNMEASURED/OFFLINE"` status.
  - 100% component byte coverage: all audits claiming `.e8z` or `.npage` measurements sample authentic bytes across all output components.
  - Mandatory `// SCAFFOLD:` marker on any unavoidable reference constant.

### 2.3 Zero-Square-Bracket L0 Rust Invariant (`v33..v56_1+`)
- **Rule**: All L0 Rust modules (`01_l0_rust\src\v33*.rs .. v56_1*.rs` and all future modules) must contain **strictly zero square brackets (`0` `[` or `]` characters)**.
- **Enforcement**: Binary byte scan tests inspect all source files for byte values `0x5B` (`[`) and `0x5D` (`]`), requiring count `== 0`.

### 2.4 Substantive Lean 4 Proof Invariant (624/624 QED)
- **Rule**: All theorems in `03_vault\lean4\SovereignManifoldTheorems.lean` (mirrored 1:1 to `01_l0_rust\lean4\SovereignManifoldTheorems.lean`) must prove substantive mathematical/algebraic properties over explicitly defined `structure` or `def` constructs.
- **Enforcement**: Strict prohibition of trivial padding theorems (`(N = N)`, `a + b = b + a` via `omega`), zero `sorry`, zero `axiom`, verified by `lean.exe`.

### 2.5 100% HUD & Mobile Preservation Law
- **Rule**: Never delete, collapse, or degrade any of the 15 Telemetry Cards (Drawer A), 60 FPS Scopes (Drawer B), 16x130 Heatmap (2,080 Bank-0 cachelines / 132,960 total bijected), 5-View Lens Switcher, Ctrl+K Palette, Drawers 1–3, or the 5 interactive panels in Drawer 4.
- **Enforcement**: AST and regex verification tests assert 100% component presence across `05_hud_cockpit\src\App.tsx` and mirrors.

### 2.6 Header-Only Loopback Credential Gate Law
- **Rule**: Operator credentials reside exclusively outside the repository at `C:\Users\Nbell\.act_omega_operator_vault_key`. Never commit operator key literals into the repo. All privileged endpoints strictly require `X-Sovereign-Operator-Key` over loopback and reject `?key=` query parameters.

### 2.7 Opaque-Box Independence & Progressive Testability
- Tests interact with the Sovereign Manifold purely from the outside:
  - HTTP REST endpoints on host (`:8097`, `:5173`) and Cloudflare Edge (`act-omega-net.dev`).
  - Raw TCP socket commands on port `:8098` for Pixel 8 `p8_ksu_apex_daemon`.
  - Source code structural byte inspections (zero brackets, passkey absence, invariant proofs).
  - Formal proof kernel invocations (`C:\Users\Nbell\.elan\bin\lean.exe`).
  - File system artifacts (`.npage` SHM 8,110,080 bytes, `.e8z` cachelines 133,120 bytes, GSC exact 53 bytes).
- During milestone implementation, tests are verifiable progressively using milestone filters (`-Milestone M0..M4`).

---

## 3. Directory Layout & Test Suite Architecture

```
C:\sovereign_manifold_v31\tests\e2e\
├── test_runner_v56.ps1          # Master CLI test runner (Tiers 1..4, milestone/feature filters, dual-track modes, JSON export)
├── e2e_common.ps1               # Common assertions, TestResult class, HTTP clients, byte scanners
├── tier1_features_v56_1.ps1     # Tier 1: Feature Coverage (All 14 features F01..F14 for v56.1.0)
├── tier2_boundaries_v56_1.ps1   # Tier 2: Boundary & Corner Cases (10 tests B01..B10 for v56.1.0)
├── tier3_integration_v56_1.ps1  # Tier 3: Cross-Feature Integration Combinations (6 tests INT01..INT06 for v56.1.0)
├── tier4_scenarios_v56_1.ps1    # Tier 4: Real-World Tri-Silicon Application Scenarios (4 tests SCEN01..SCEN04 for v56.1.0)
├── tier1_features_v56.ps1       # Baseline Tier 1 Regression Suite (20 features of v56.0.0)
├── tier2_boundaries_v56.ps1     # Baseline Tier 2 Regression Suite (10 boundary tests)
├── tier3_integration_v56.ps1    # Baseline Tier 3 Regression Suite (6 integration tests)
├── tier4_scenarios_v56.ps1      # Baseline Tier 4 Regression Suite (4 scenario tests)
├── Run-All-E2E-Tests.ps1        # Unified root runner dispatching to test_runner_v56.ps1
└── reports\                     # Automated JSON and markdown test execution logs
```

---

## 4. 4-Tier Test Suite Specification (v56.1.0)

### 4.1 Tier 1: Feature Coverage (All 14 Features in `PROJECT.md`)
Validates every individual feature in the `PROJECT.md` Feature Inventory with targeted assertions:
- **Milestone 0: Permanent Google Search Console Certificate Lock (Features 1–3)**:
  - `F01`: **GSC Certificate Ingestion**: Validates that `google6edc0affb12d0455.html` exists with exact 53 bytes and identical content across all 7 deployment targets: Drive Bridge (`G:\My Drive\ACT_OMEGA_GEMINI_BRIDGE\`), `05_hud_cockpit\public\`, `02_l2_orchestration\hud\public\`, `05_hud_cockpit\dist\`, `02_l2_orchestration\hud\dist\`, `docs\`, repo root, and `E:\Sovereign_Manifold_SSD_Vault\`.
  - `F02`: **GSC L0 Rust & Edge Worker Handlers**: Verifies `// STRICT DO NOT REMOVE:` handler markers in `v31_swarm.rs` and `worker_vpc_shadow_v3700.js`, and confirms live `GET` requests to `:8097`, `:5173`, and `https://act-omega-net.dev` return `200 OK` with exact 53 bytes.
  - `F03`: **GSC Invariant Script Checks**: Asserts that `Invoke-BrutalAgentGatekeeper.ps1`, `Sovereign-Lifecycle.ps1`, and `tests\e2e\test_runner_v56.ps1` contain permanent GSC verification logic.
- **Milestone 1: Universal Autopoietic Coordinator Bus & 9-Directory Write-Back (Features 4–6)**:
  - `F04`: **9th Codegen Sink `tool_outputs`**: Validates declaration of `E_CODEGEN_TOOL_OUTPUTS_DIR` and `C_CODEGEN_TOOL_OUTPUTS_DIR` in `v48_autopoietic_coordinator_bus.rs` and verifies directory presence.
  - `F05`: **Universal Tool Bus & Write-Back Function**: Validates `pub fn execute_universal_tool_bus_and_writeback(...)` with strict 0 square brackets, ledger append, and manifest recording.
  - `F06`: **210 Tools Write-Back Routing**: Verifies that all 210 tools in `v31_swarm.rs` invoke the universal writeback helper, creating real artifacts on `E:\` and returning telemetry keys (`e_vault_writeback_path`, `e_vault_writeback_bytes`, `e_vault_writeback_sha256`, `autopoietic_bus_seq`).
- **Milestone 2: 8 Functional Domain Groups & 256-Bit AVX2/Rayon FNO (Features 7–9)**:
  - `F07`: **8 Unified Functional Domain Dispatchers**: Validates zero-bracket module `v56_1_unified_functional_domains_and_avx2_fno.rs`, `/api/v1/unified/catalog` with exact 210-tool partitioning across 8 domains, and single-action dispatch endpoints.
  - `F08`: **256-Bit AVX2/FMA + 12-Thread Rayon FNO**: Vectorized 16-Domain Spectral FNO over 63,360 neurons & 80 sectors in `v56_1` and `v35_fno_liquid_connectome.rs` with 12 Rayon worker threads and paired `__m256` registers.
  - `F09`: **Live FNO Telemetry Integration**: Wires live-measured L2 error, vorticity norm, Reynolds number, and AVX2 GFLOPS into Tool 22, Domain 3, and the 15.965 Hz telemetry loop.
- **Milestone 3: UI/UX Decluttering & Functional Consolidation (Features 10–11)**:
  - `F10`: **8-Domain Command Deck in Cockpit HUD**: Verifies Drawer 4 replacement with the 8-Domain Deck, 100% preservation of all 15 Cards, Scopes, Heatmap, Drawers 1–3, and 5 interactive panels, with zero leaked secrets.
  - `F11`: **Mobile NDK & Win11 Tray HUD Parity**: Verifies 8 unified domain dispatches and live FNO readouts in `MainActivity.kt` and `SovereignTrayAndHud.cs`.
- **Milestone 4: Lifecycle Hardening, 4-Gatekeeper Audit & Graceful Shutdown (Features 12–14)**:
  - `F12`: **Lifecycle Script Hardening**: Verifies `Sovereign-Lifecycle.ps1` process teardown (`SovereignCockpitHUD.exe`, port 8098 `p8_ksu_apex_daemon`), capsule flush, and auto-relaunch.
  - `F13`: **4-Gatekeeper Full Audit & Verification**: Verifies `Invoke-BrutalAgentGatekeeper.ps1 -FullAudit`, `Sovereign-Lifecycle.ps1 -Action verify` (6/6 layers), and E2E test runner.
  - `F14`: **Graceful Cluster Shutdown**: Verifies cluster shutdown readiness for physical device reboot via `Sovereign-Lifecycle.ps1 -Action stop-all`.

---

### 4.2 Tier 2: Boundary & Corner Cases (10 Tests: B01..B10)
Stresses system boundaries, edge conditions, invalid input combinations, and architectural constraints:
- `B01`: **GSC Certificate Exact Byte Length & Immutability**: Validates that any deployed GSC certificate is strictly 53 bytes, contains exact verification token string, and rejects any byte alterations (e.g. 52B or 54B).
- `B02`: **Zero-Square-Bracket Scanner on `v56_1` & L0 Modules**: Scans all `v33..v56_1` modules in `01_l0_rust/src/` for 0x5B and 0x5D brackets.
- `B03`: **Unified Domain Catalog Tool Partition Completeness**: Verifies the 8 domains in `/api/v1/unified/catalog` partition exactly 210 tools with zero overlapping or missing tools (43+29+19+26+16+13+34+30 = 210).
- `B04`: **AVX2 16-Domain FNO Boundary & Reynolds Number Range**: Verifies FNO inputs and outputs across boundary modes (16 Fourier modes, Reynolds number > 0, L2 error < 0.15, positive GFLOPS).
- `B05`: **Universal Write-Back Directory Bounds & Path Traversal Rejection**: Verifies that `execute_universal_tool_bus_and_writeback` writes strictly within `E:\Sovereign_Manifold_SSD_Vault\autopoietic_codegen\` and rejects path traversal sequences (`../`).
- `B06`: **HUD 100% Component Preservation Boundary**: Checks source code of `App.tsx` and mirrors ensuring all 15 Cards, 60 FPS Scopes, 16x130 Heatmap, 5 Lenses, and 5 interactive Drawer 4 panels are 100% preserved.
- `B07`: **Zero Secret Leak Boundary (Retired & Active Operator Key)**: Verifies that neither the retired passkey nor the active operator key appears anywhere in `App.tsx`, `index.html`, `docs/`, or any public file.
- `B08`: **Substantive Lean 4 Proof Boundary (624 QED)**: Verifies that `SovereignManifoldTheorems.lean` maintains >= 624 theorems, 0 sorry, 0 axiom, and 0 trivial padding theorems.
- `B09`: **Raw Socket Port 8098 Apex Daemon Ping & Protocol Boundary**: Directly sends `{"cmd":"ping"}\n` over raw TCP to 127.0.0.1:8098 and verifies PONG response with valid PID and SELinux context (`u:r:ksu:s0`).
- `B10`: **Cloudflare Edge GSC Handler & Worker Route Boundary**: Verifies edge route handling for `/google6edc0affb12d0455.html` returning 200 OK and 53 bytes.

---

### 4.3 Tier 3: Cross-Feature Integration Combinations (6 Tests: INT01..INT06)
Validates interactions across language and architectural boundaries:
- `INT01`: **GSC Certificate Multi-Ingress Integration (F01 ↔ F02 ↔ F03)**: Verifies that GSC certificate file is identical across all 7 target paths and responds identically across host L0 port 8097, static port 5173, and Edge worker.
- `INT02`: **Universal Write-Back ↔ 210 Tools ↔ E:\ SSD Vault Integration (F04 ↔ F05 ↔ F06)**: Invokes representative tools from CHAIN 210 and verifies write-back fields (`e_vault_writeback_path`, `e_vault_writeback_bytes`, `e_vault_writeback_sha256`) match actual files written to `E:\Sovereign_Manifold_SSD_Vault\autopoietic_codegen\` and recorded in ledger/manifest.
- `INT03`: **8 Unified Domains ↔ AVX2 FNO ↔ Telemetry Loop Integration (F07 ↔ F08 ↔ F09)**: Verifies that Unified Domain 3 (`physics_16d_fno_speech`) invokes the vectorized 16-domain FNO kernel and propagates live metrics into the 15.965 Hz telemetry feed.
- `INT04`: **8-Domain HUD Command Deck ↔ Mobile NDK ↔ Win11 Tray HUD Parity (F10 ↔ F11)**: Verifies that Web HUD, Android `MainActivity.kt`, and Win11 `SovereignTrayAndHud.cs` have consistent 8-domain dispatches and FNO readouts.
- `INT05`: **Lifecycle Script Hardening ↔ Port 8098 Apex Daemon ↔ Process Teardown (F12 ↔ F14)**: Verifies that `Sovereign-Lifecycle.ps1` correctly enumerates and manages all cluster daemons (v31_swarm, cloudflared, SovereignCockpitHUD, and Pixel 8 p8_ksu_apex_daemon).
- `INT06`: **Gatekeeper FullAudit ↔ E2E Suite ↔ Six-Layer Lifecycle Verification (F13)**: Verifies that Gatekeeper, E2E suite, and Lifecycle verification pass in unison without conflicting invariants.

---

### 4.4 Tier 4: Real-World Tri-Silicon Application Scenarios (4 Tests: SCEN01..SCEN04)
Simulates end-to-end cluster lifecycle workflows under production conditions:
- `SCEN01`: **Full Cluster Multi-Silicon Telemetry & Universal Write-Back**: Executes an end-to-end telemetry cycle across Anchor-1 (Host LOQ 15), Edge-1 (Pixel 10), and Edge-2 (Pixel 8), verifying live kops, 63,360 neurons, 1,013,760 synapses, and universal SSD write-back telemetry.
- `SCEN02`: **Live 16-Domain AVX2/Rayon FNO Solve & Vorticity Lifecycle**: Triggers `/api/v1/operator/fno_solve` and `/api/v1/physics/neural_fno_16domains` with live parameters, asserting solution convergence, L2 error < 0.15, vorticity norm computation, and Rayon parallel thread execution.
- `SCEN03`: **Production HUD Build, 8-Domain Deck & Crawlable SSR Snapshot**: Verifies that the production HUD distribution bundle in `05_hud_cockpit/dist/` and `docs/` contains the 8-domain command deck, relative `./` assets, and crawlable SSR snapshot with 0 missing dependencies.
- `SCEN04`: **Full Cluster Pre-Reboot Verification & Quiescence Readiness**: Runs 6-layer verification and validates that the cluster state, continuum handover capsule, and daemon processes are primed for graceful shutdown.

---

## 5. Feature Coverage Matrix (14 Features)

| Feature # | Feature Name | Milestone | Tier 1 Test ID | Tier 2/3/4 Links | Verification Target & Authoritative Contract |
| :---: | :--- | :---: | :---: | :---: | :--- |
| **F01** | GSC Certificate Ingestion | M0 | `F01_v56_1` | `B01`, `INT01` | Copy `google6edc0affb12d0455.html` (53 B) from Drive Bridge into all 7 target paths |
| **F02** | GSC L0 Rust & Edge Worker Handlers | M0 | `F02_v56_1` | `B10`, `INT01` | Inject `// STRICT DO NOT REMOVE:` handlers into `v31_swarm.rs` (:8097, :5173) and `worker_vpc_shadow_v3700.js` |
| **F03** | GSC Invariant Script Checks | M0 | `F03_v56_1` | `B01`, `INT01` | Add GSC existence and length checks into Gatekeeper, Lifecycle, and E2E runner |
| **F04** | 9th Codegen Sink `tool_outputs` | M1 | `F04_v56_1` | `B05`, `INT02` | Add `E_CODEGEN_TOOL_OUTPUTS_DIR` and `C_CODEGEN_TOOL_OUTPUTS_DIR` in `v48_autopoietic_coordinator_bus.rs` |
| **F05** | Universal Tool Bus & Write-Back Function | M1 | `F05_v56_1` | `B02`, `B05`, `INT02` | Implement `execute_universal_tool_bus_and_writeback(...)` with strict zero square brackets |
| **F06** | 210 Tools Write-Back Routing | M1 | `F06_v56_1` | `INT02`, `SCEN01` | Route all 210 tools and `chain135_json` in `v31_swarm.rs` to write real files on `E:\` and inject response telemetry |
| **F07** | 8 Unified Functional Domain Dispatchers | M2 | `F07_v56_1` | `B03`, `INT03` | Create zero-bracket `v56_1_unified_functional_domains_and_avx2_fno.rs` with `/api/v1/unified/*` and `/catalog` |
| **F08** | 256-Bit AVX2/FMA + 12-Thread Rayon FNO | M2 | `F08_v56_1` | `B04`, `INT03`, `SCEN02` | Vectorized 16-Domain Spectral FNO over 63,360 neurons & 80 sectors in `v56_1` and `v35_fno_liquid_connectome.rs` |
| **F09** | Live FNO Telemetry Integration | M2 | `F09_v56_1` | `INT03`, `SCEN02` | Wire live measured L2 error, vorticity norm, Reynolds number, and GFLOPS into Tool 22, Domain 3, and 15.965 Hz loop |
| **F10** | 8-Domain Command Deck in Cockpit HUD | M3 | `F10_v56_1` | `B06`, `B07`, `INT04`, `SCEN03` | Replace 7 version banners in Drawer 4 with 8-Domain Deck while preserving 100% of Cards, Scopes, Heatmap, Drawers 1-3 |
| **F11** | Mobile NDK & Win11 Tray HUD Parity | M3 | `F11_v56_1` | `INT04` | Add 8 unified domain dispatches and live FNO readouts to `MainActivity.kt` and `SovereignTrayAndHud.cs` |
| **F12** | Lifecycle Script Hardening | M4 | `F12_v56_1` | `INT05`, `SCEN04` | Harden `Sovereign-Lifecycle.ps1` for clean process termination (Tray HUD, port 8098 daemon) and auto-relaunch on start |
| **F13** | 4-Gatekeeper Full Audit & Verification | M4 | `F13_v56_1` | `B08`, `INT06`, `SCEN04` | Verify `test_runner_v56.ps1` (40/40), `Invoke-BrutalAgentGatekeeper.ps1 -FullAudit`, and `Sovereign-Lifecycle.ps1 -Action verify` |
| **F14** | Graceful Cluster Shutdown | M4 | `F14_v56_1` | `INT05`, `SCEN04` | Execute `Sovereign-Lifecycle.ps1 -Action stop-all` to put Host, Pixel 10, and Pixel 8 in safe quiescent state for reboot |

---

## 6. CLI Usage & Execution Guide

### 6.1 Running the Master Test Runner (Dual-Track Mode)
```powershell
# Runs dual-track verification: Baseline Regression (40 tests) + v56.1 Capability Matrix
powershell -ExecutionPolicy Bypass -File C:\sovereign_manifold_v31\tests\e2e\test_runner_v56.ps1
```

### 6.2 Running Milestone-Specific Progressive Tests
```powershell
# Milestone 0: Permanent Google Search Console Certificate Lock (Features 1–3)
powershell -ExecutionPolicy Bypass -File C:\sovereign_manifold_v31\tests\e2e\test_runner_v56.ps1 -Milestone M0

# Milestone 1: Universal Autopoietic Coordinator Bus & 9-Directory Write-Back (Features 4–6)
powershell -ExecutionPolicy Bypass -File C:\sovereign_manifold_v31\tests\e2e\test_runner_v56.ps1 -Milestone M1

# Milestone 2: 8 Functional Domain Groups & 256-Bit AVX2 FNO (Features 7–9)
powershell -ExecutionPolicy Bypass -File C:\sovereign_manifold_v31\tests\e2e\test_runner_v56.ps1 -Milestone M2

# Milestone 3: UI/UX Decluttering & Functional Consolidation (Features 10–11)
powershell -ExecutionPolicy Bypass -File C:\sovereign_manifold_v31\tests\e2e\test_runner_v56.ps1 -Milestone M3

# Milestone 4: Lifecycle Hardening, 4-Gatekeeper Audit & Graceful Shutdown (Features 12–14)
powershell -ExecutionPolicy Bypass -File C:\sovereign_manifold_v31\tests\e2e\test_runner_v56.ps1 -Milestone M4
```

### 6.3 Running Specific Test Tiers (v56.1.0)
```powershell
# Tier 1: Feature Coverage (All 14 individual features)
powershell -ExecutionPolicy Bypass -File C:\sovereign_manifold_v31\tests\e2e\test_runner_v56.ps1 -Suite v56.1 -Tier 1

# Tier 2: Boundary & Corner Cases (10 edge-stress tests)
powershell -ExecutionPolicy Bypass -File C:\sovereign_manifold_v31\tests\e2e\test_runner_v56.ps1 -Suite v56.1 -Tier 2

# Tier 3: Cross-Feature Integration Combinations (6 cross-module tests)
powershell -ExecutionPolicy Bypass -File C:\sovereign_manifold_v31\tests\e2e\test_runner_v56.ps1 -Suite v56.1 -Tier 3

# Tier 4: Real-World Tri-Silicon Application Scenarios (4 lifecycle scenarios)
powershell -ExecutionPolicy Bypass -File C:\sovereign_manifold_v31\tests\e2e\test_runner_v56.ps1 -Suite v56.1 -Tier 4
```

### 6.4 Running an Individual Feature Test
```powershell
# Test Feature 1 (GSC Certificate Ingestion across 7 targets)
powershell -ExecutionPolicy Bypass -File C:\sovereign_manifold_v31\tests\e2e\test_runner_v56.ps1 -Suite v56.1 -Feature 1

# Test Feature 7 (8 Unified Functional Domain Dispatchers & Catalog)
powershell -ExecutionPolicy Bypass -File C:\sovereign_manifold_v31\tests\e2e\test_runner_v56.ps1 -Suite v56.1 -Feature 7

# Test Feature 8 (256-Bit AVX2/Rayon 16-Domain Spectral FNO)
powershell -ExecutionPolicy Bypass -File C:\sovereign_manifold_v31\tests\e2e\test_runner_v56.ps1 -Suite v56.1 -Feature 8
```

### 6.5 Running Baseline Regression Suite Only
```powershell
powershell -ExecutionPolicy Bypass -File C:\sovereign_manifold_v31\tests\e2e\test_runner_v56.ps1 -Suite Baseline
```

### 6.6 Exporting Test Execution Reports
```powershell
# Export JSON execution report
powershell -ExecutionPolicy Bypass -File C:\sovereign_manifold_v31\tests\e2e\test_runner_v56.ps1 -ReportFormat JSON -OutputPath C:\sovereign_manifold_v31\tests\e2e\reports\v56_1_results.json
```

---

## 7. Pass/Fail Semantics & Opaque-Box Test Architecture

### 7.1 Exit Codes & Pipeline Semantics
| Exit Code | Meaning | Action Required |
| :---: | :--- | :--- |
| `0` | **All Executed Tests Passed (100%)** | Proceed to gate verification, staged hot-swap, or release deployment. |
| `1` | **One or More Tests Failed** | Inspect test failure message, identify missing milestone requirement, and escalate to responsible implementing agent. |

### 7.2 Opaque-Box Test Architecture
The test suite treats the Sovereign Manifold as an opaque box:
- **HTTP/REST Ingress**: Sends live HTTP requests over loopback (`127.0.0.1:8097` and `:5173`) using PowerShell's native `Invoke-RestMethod` and `System.Net.HttpWebRequest`.
- **Raw Socket Ingress**: Direct TCP socket communication on port `:8098` verifying rooted Pixel 8 `p8_ksu_apex_daemon`.
- **Hardware & Filesystem State Observation**: Inspects actual file lengths (`.npage` SHM 8,110,080 bytes, `.e8z` 133,120 bytes, GSC certificate 53 bytes), directory contents, and JSON certification metadata.
- **Binary Byte Scanners**: Validates zero-square-bracket compliance via direct byte reads (`[System.IO.File]::ReadAllBytes()`) verifying `0x5B` and `0x5D` counts.
- **External Toolchain Invocations**: Executes `lean.exe` and `ghc.exe` as sub-processes, validating exit codes and stdout diagnostic output without mock wrappers.
- **Fail-Fast Defect Isolation**: Every assertion records measured values, expected values, execution duration in milliseconds, and diagnostic context in a structured `TestResult` object.

---

## 8. Defect Escalation & QA Protocols

When an assertion fails during test execution:
1. **Determine Failure Classification**:
   - **Implementation Defect**: Feature implementation is missing, returns invalid data, or violates architectural invariants.
     - *Action*: Record exact failure log, file path, line number, and expected vs observed value in `handoff.md`. Escalate to the responsible domain agent (`01-l0-rust-lean4-architect`, `04-dual-pixel-edge-ndk`, `03-hud-cockpit-guardian`, etc.).
   - **Test Defect**: Test specification contains an outdated assumption or conflicting interface contract with `PROJECT.md`.
     - *Action*: Update the test assertion to strictly match the authoritative requirements in `PROJECT.md` and `ORIGINAL_REQUEST.md`. Never weaken assertions to mask bugs.
2. **Strict Zero-Mock Enforcement**:
   - Tests MUST NEVER be altered to pass unconditionally or mock missing hardware/services.
   - During progressive testing of planned milestones, pre-implementation failures are expected and serve as the true specification oracle.
