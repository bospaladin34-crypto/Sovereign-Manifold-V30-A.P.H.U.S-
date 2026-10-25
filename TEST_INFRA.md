# ACT-Omega Net v49.0.0 (CHAIN 100 Century Milestone)
# E2E Test Infrastructure Specification & Developer Guide (`TEST_INFRA.md`)

- **Milestone**: ACT-Omega Net v49.0.0 (`CHAIN 100` Century Milestone / `SH4Z v4900 TLV`)
- **System**: Sovereign Manifold Tri-Silicon Cluster (`C:\sovereign_manifold_v31`)
- **Author**: E2E Testing Track Test Writer (`test_writer_e2e`)
- **Date**: October 25, 2026
- **Test Harness Framework**: Native Windows PowerShell 5.1 / PowerShell Core (Zero Python)

---

## 1. Executive Summary & Purpose

The ACT-Omega Net v49.0.0 test infrastructure establishes a rigorous, automated, opaque-box end-to-end verification harness across all 34 architectural features defined in `PROJECT.md`. It validates the 4 core requirements (R1–R4) of the Century Milestone:
1. **R1**: Cloudflare Durable Objects `5,000,000 rows_read` quota reduction and `cloudflared` QUIC tunnel socket/keep-alive stabilization.
2. **R2**: Remediation of all 3 minor findings from `muse-2026-10-24-sweep` (6D Plücker CPU fallback $P_{ab}$, universally quantified Lean 4 structural theorems 433..460, and header-based operator auth with passkey purging).
3. **R3**: Zero-square-bracket L0 Rust module (`v49_muse_clean_and_chain100_synthesis.rs`) completing `Tools 91–100` (`CHAIN 100`) and exposing `/api/v1/v49/chain100_omni_suite`.
4. **R4**: 100% UI preservation across WebGPU HUD Cockpit and Mobile Android NDK APK, zero-unmeasured data compliance, and 6-layer cluster verification.

---

## 2. Hard Testing Constraints & Architectural Invariants

### 2.1 Strict Zero-Python Mandate
- **Rule**: Under no circumstances shall Python (`python`, `python3`, `.py`) be used for any test, runner, assertion script, or build step.
- **Enforcement**: All test runners, assertions, and harness utilities are implemented strictly in PowerShell (`.ps1`) leveraging Windows native APIs, WebSockets, REST methods, and file byte inspection.

### 2.2 Muse Zero-Unmeasured-Data Mandate
- **Rule**: **"If it is not measured, calculated or computed, it DOES NOT ship, full stop."**
- **Enforcement**: No mock fixtures, no synthetic `sin`/`cos` fallbacks disguising unmeasured data, no hardcoded hash digests, and no unconditional passes. Every test exercises real hardware measurements, live TCP sockets, genuine filesystem bytes (`fs::metadata`), authentic SHA-256 digests, and actual Lean 4 kernel compilations.

### 2.3 Opaque-Box Independence & Progressive Testability
- Tests interact with the Sovereign Manifold purely from the outside:
  - HTTP REST endpoints on host (`:8097`, `:5173`) and Cloudflare Edge (`act-omega-net.dev`).
  - Source code structural byte inspections (zero brackets, passkey absence, invariant proofs).
  - Formal proof kernel invocations (`lean.exe`).
  - File system artifacts (`.npage` SHM 5,406,720 bytes, `.e8z` cachelines 133,120 bytes).
- Each test sets up its own state, executes independently, and reports clear diagnostics without depending on execution order.

---

## 3. Directory Layout & Test Suite Map

```
C:\sovereign_manifold_v31\tests\e2e\
├── Run-All-E2E-Tests.ps1      # Master CLI test runner (Tiers 1..4, milestone filtering, JSON export)
├── e2e_common.ps1             # Common assertions, TestResult class, HTTP clients, byte scanners
├── tier1_features.ps1         # Tier 1: Feature Coverage (All 34 features F01..F34)
├── tier2_boundaries.ps1       # Tier 2: Boundary & Corner Cases (10 tests B01..B10)
├── tier3_integration.ps1      # Tier 3: Cross-Feature Integration Combinations (6 tests INT01..INT06)
├── tier4_scenarios.ps1        # Tier 4: Real-World Tri-Silicon Application Scenarios (4 tests SCEN01..SCEN04)
└── reports\                   # Automated JSON and markdown test execution logs
```

---

## 4. Test Tiers Specification

### Tier 1: Feature Coverage (All 34 Features in `PROJECT.md`)
Validates every individual feature in the `PROJECT.md` Feature Inventory with targeted assertions:
- **M1 (Features 1–5)**: Cloudflare DO row pruning, in-memory counter, write debounce, D1 cache, 25s TCP read timeout, 24h static asset cache headers.
- **M2 (Features 6–12)**: Plücker 6D CPU fallback, measured CRC label, universally quantified Theorems 433..440, Lean 4 Theorems 441..460, Haskell generator update, root HTML passkey purge, `X-Sovereign-Operator-Key` header auth.
- **M3 (Features 13–25)**: Tools 91 through 100 individual executions, zero-square-bracket byte check on `v49_muse_clean_and_chain100_synthesis.rs`, `/api/v1/v49/chain100_omni_suite` endpoint, Muse zero-unmeasured data compliance.
- **M4 (Features 26–29)**: HUD Cockpit 100% preservation (Drawer A 15 cards, Drawer B scopes, Heatmap, Drawer 4 CHAIN 100), Android APK & widget sync, Win11 Tray HUD sync, PWA `sw.js` cache bumping.
- **M5 (Features 30–34)**: Opaque-box E2E test infra readiness, 6-Layer Verification Gate audits (L1 Rust, L2 Lean 4, L3 Connectome, L4 HUD bundle, L5 Dual Pixel SHM, L6 Cloudflare WAN).

### Tier 2: Boundary & Corner Cases (10 Tests)
Stresses system boundaries, edge conditions, invalid inputs, and security gates:
- **B01**: Unauthenticated `/api/v1/admin/self_exit` query rejection (HTTP 403 electron trap, host process remains active).
- **B02**: Forged header key rejection on `/api/v1/admin/self_exit` (HTTP 403 Forbidden).
- **B03**: Zero-square-bracket byte scanner sensitivity verification on synthetic clean vs bracketed buffers.
- **B04**: Tool 94 dimension parsing with negative, zero, and special character inputs.
- **B05**: Tool 97 Quaternionic Nabla flatline boundary (zero spatial variance verifies $\nabla \cdot (\nabla \times \mathbf{F}) \equiv 0.0$).
- **B06**: Tool 98 Poincaré-Bendixson bifurcation boundary ($\alpha = 0, \beta < 0$ classifies strictly as `CENTER`).
- **B07**: Tool 100 Euler angular momentum conservation under vanishing intermediate velocity ($\omega_2 \to 0$).
- **B08**: Cloudflare DO ring buffer capacity boundary ($\le 8$ rows in `edge_heartbeat`).
- **B09**: Swarm TCP keep-alive read timeout idle boundary ($\ge 20,000$ ms prevents cloudflared socket dropouts).
- **B10**: Lean 4 structural proof rigor boundary (0 trivial identities `(N = N)` in AST).

### Tier 3: Cross-Feature Integration Combinations (6 Tests)
Validates interactions across language and architectural boundaries:
- **INT01**: Plücker 6D TypeScript fallback in `App.tsx` $\leftrightarrow$ Rust Tool 92 `compute_cpu_plucker_6d_inner_product_audit` mathematical parity.
- **INT02**: Zero-square-bracket Rust module $\leftrightarrow$ CHAIN 100 Omni-Suite $\leftrightarrow$ Swarm HTTP router link.
- **INT03**: Cloudflare DO 8-row ring buffer $\leftrightarrow$ SQLite 60s write debounce $\leftrightarrow$ Worker 30s D1 cache quota triple-protection.
- **INT04**: Swarm 25s keep-alive timeout $\leftrightarrow$ Static asset 24h edge cache headers $\leftrightarrow$ Cloudflare tunnel stability.
- **INT05**: Haskell algebraic generator $\leftrightarrow$ Lean 4 formal proof kernel ($\ge 460$ theorems QED).
- **INT06**: Root HTML passkey purge $\leftrightarrow$ `X-Sovereign-Operator-Key` header auth $\leftrightarrow$ 6-layer gate L4 credential hygiene.

### Tier 4: Real-World Tri-Silicon Application Scenarios (4 Tests)
Simulates end-to-end cluster lifecycle workflows under production conditions:
- **SCEN01**: Full cluster telemetry lifecycle audit (42,240 neurons, decadic clock at 15.965 Hz, health score $> 80$).
- **SCEN02**: Remote Cloudflare Edge continuum handover & DO SQLite state sync.
- **SCEN03**: WebGPU Cockpit static production distribution bundle & asset integrity scan (0 leaked passkeys in `dist\assets\*.js`).
- **SCEN04**: Programmatic execution of the complete 6-layer true-data verification lifecycle audit.

---

## 5. Feature Coverage Matrix (34 Features)

| Feature # | Feature Name | Milestone | Tier 1 Test ID | Tier 2/3/4 Links | Verification Target |
| :---: | :--- | :---: | :---: | :---: | :--- |
| **F01** | CF DO `rows_read` Optimization | M1 | `F01` | `B08`, `INT03` | 0 `SELECT COUNT(*)`, prune to $\le 8$ rows in `worker_continuum_do.js` |
| **F02** | CF DO SQLite Write Debounce | M1 | `F02` | `INT03` | Debounce `shm_continuum_state` writes to $\le 1$ / 60s per node |
| **F03** | CF DO D1 Read Cache | M1 | `F03` | `INT03` | Cache D1 snapshot reads for 30 seconds in Worker memory |
| **F04** | Swarm Keep-Alive Expansion | M1 | `F04` | `B09`, `INT04` | Socket `set_read_timeout` set to 25,000 ms in `v31_swarm.rs` |
| **F05** | Static Asset Edge Caching | M1 | `F05` | `INT04` | Emit `Cache-Control: public, max-age=86400, immutable` for static files |
| **F06** | Plücker 6D Inner Product Fallback | M2 | `F06` | `INT01` | Replace `Math.sin/cos` fallback with 6D Plücker $P_{ab}$ in `App.tsx` |
| **F07** | Plücker Measured CRC Label | M2 | `F07` | `INT01` | Label CPU fallback with `_CPU_E8_PLUCKER_6D_INNER_MEASURED` |
| **F08** | Structural Lean 4 Proofs 433..440 | M2 | `F08` | `B10`, `INT05` | Universally quantified (`∀`) structural invariants (0 constant `rfl`) |
| **F09** | Lean 4 Theorems 441..460 | M2 | `F09` | `INT05`, `SCEN04` | Total 460 theorems QED in `SovereignManifoldTheorems.lean` |
| **F10** | Haskell Lean 4 Generator Update | M2 | `F10` | `INT05` | `ZeroBracketRustAndLean4.hs` emits universal structural proofs |
| **F11** | Root HTML Passkey Purge | M2 | `F11` | `INT06`, `SCEN03` | 0 occurrences of `SOVEREIGN-LOQ15-4200` in `index.html` & `wiki.html` |
| **F12** | Admin Header Authentication | M2 | `F12` | `B01`, `B02`, `INT06` | `X-Sovereign-Operator-Key` header auth on `/api/v1/admin/*` |
| **F13** | Tool 91 (Triangulated $\text{dS}_3$ Gravity) | M3 | `F13` | `INT02` | arXiv:2610.30126 pants gluing (genus 3, 4 pants, 42,240 neurons) |
| **F14** | Tool 92 (Amplituhedron SYM Hexagon) | M3 | `F14` | `INT01`, `INT02` | 6-particle 9-loop Plücker determinants and CPU 6D inner product |
| **F15** | Tool 93 (Holographic L2 SHM Bound) | M3 | `F15` | `INT02` | Bekenstein-Hawking area bound $S_{\max} = A/4$ over 64KB SHM ring |
| **F16** | Tool 94 (3-Pyramid Cube Partition) | M3 | `F16` | `B04`, `INT02` | Discrete $\sum(3t^2+3t+1)=x^3$ and integral partition $x^3/3$ |
| **F17** | Tool 95 (Bell 6-Polytope Correlation) | M3 | `F17` | `INT02` | Quantum correlation $0.6 < 1.0$ (scaled $3 < 5$) across Tri-Silicon |
| **F18** | Tool 96 (Bipolar Dual-Focus Caustic) | M3 | `F18` | `INT02` | Dual-focus caustic identity $r_1^2 - r_2^2 = -4ax$ for mobile NPUs |
| **F19** | Tool 97 (Quaternionic Nabla Operator) | M3 | `F19` | `B05`, `INT02` | Quaternionic Nabla $\nabla q$ verifying $\nabla \cdot (\nabla \times \mathbf{F}) = 0.0$ |
| **F20** | Tool 98 (Poincaré-Bendixson Atlas) | M3 | `F20` | `B06`, `INT02` | $(\alpha, \beta)$ dynamical classification across 960 Chair-44 columns |
| **F21** | Tool 99 (Stanford/Together HybridLink) | M3 | `F21` | `INT02` | $h' = h + W_2\,\text{GELU}(W_1 h)$ 256D latent $E_8$ $\leftrightarrow$ 65K BPE text |
| **F22** | Tool 100 (Dzhanibekov Intermediate Axis) | M3 | `F22` | `B07`, `INT02` | Euler intermediate axis stabilizer and $\|\vec{L}\|^2$ conservation |
| **F23** | Zero-Square-Bracket Rust Module | M3 | `F23` | `B03`, `INT02`, `SCEN04` | 0 bytes of 0x5B and 0x5D in `v49_muse_clean_and_chain100_synthesis.rs` |
| **F24** | CHAIN 100 Omni-Suite Endpoint | M3 | `F24` | `INT02`, `SCEN01` | `/api/v1/v49/chain100_omni_suite` aggregates Tools 91..100 |
| **F25** | Muse Zero-Unmeasured Compliance | M3 | `F25` | `INT02` | Tools 91..100 derive strictly from real hardware/filesystem timing |
| **F26** | HUD Cockpit 100% Preservation | M4 | `F26` | `SCEN03` | Preserve 15 cards, 3D Scope, Heatmap; expand Drawer 4 to CHAIN 100 |
| **F27** | Android App & Widget Sync | M4 | `F27` | `SCEN04` | Synchronize `MainActivity.kt` and `sovereign_heatmap_widget.xml` to v49 |
| **F28** | Win11 Native Tray HUD Sync | M4 | `F28` | — | Synchronize `SovereignTrayAndHud.cs` / `SovereignCockpitHUD.exe` to v49 |
| **F29** | PWA Service Worker Cache Busting | M4 | `F29` | `SCEN03` | Bump `sw.js` cache name to `act-omega-cockpit-v49` |
| **F30** | Opaque-Box E2E Test Infra | M5 | `F30` | All | `TEST_INFRA.md` published and `Run-All-E2E-Tests.ps1` operational |
| **F31** | 6-Layer Verification Gate (L1) | M5 | `F31` | `SCEN04` | 0 brackets in `v33..v49`, holdout QAT PPL $> 1.0001$ |
| **F32** | 6-Layer Verification Gate (L2) | M5 | `F32` | `B10`, `INT05`, `SCEN04` | 460 theorems Lean 4 QED, 0 sorry, 0 constant `(N = N)` |
| **F33** | 6-Layer Verification Gate (L3-L5) | M5 | `F33` | `SCEN01`, `SCEN03`, `SCEN04` | 42,240 neurons; HUD dist ready; Dual-Pixel SHM 5,406,720 bytes |
| **F34** | 6-Layer Verification Gate (L6) | M5 | `F34` | `INT04`, `SCEN02`, `SCEN04` | Cloudflare tunnel HTTP 200, Edge DO handover OK, 0 unbounded scans |

---

## 6. CLI Usage & Execution Guide

### 6.1 Running the Full Test Suite
```powershell
powershell -ExecutionPolicy Bypass -File C:\sovereign_manifold_v31\tests\e2e\Run-All-E2E-Tests.ps1
```

### 6.2 Running a Specific Tier
```powershell
# Tier 1 (All 34 Feature Tests)
powershell -ExecutionPolicy Bypass -File C:\sovereign_manifold_v31\tests\e2e\Run-All-E2E-Tests.ps1 -Tier 1

# Tier 2 (Boundary & Corner Cases)
powershell -ExecutionPolicy Bypass -File C:\sovereign_manifold_v31\tests\e2e\Run-All-E2E-Tests.ps1 -Tier 2

# Tier 3 (Cross-Feature Integration)
powershell -ExecutionPolicy Bypass -File C:\sovereign_manifold_v31\tests\e2e\Run-All-E2E-Tests.ps1 -Tier 3

# Tier 4 (Real-World Scenarios)
powershell -ExecutionPolicy Bypass -File C:\sovereign_manifold_v31\tests\e2e\Run-All-E2E-Tests.ps1 -Tier 4
```

### 6.3 Filtering by Milestone (Progressive Testability)
```powershell
# Test Milestone 1 features only
powershell -ExecutionPolicy Bypass -File C:\sovereign_manifold_v31\tests\e2e\Run-All-E2E-Tests.ps1 -Tier 1 -Milestone M1

# Test Milestone 2 features only
powershell -ExecutionPolicy Bypass -File C:\sovereign_manifold_v31\tests\e2e\Run-All-E2E-Tests.ps1 -Tier 1 -Milestone M2

# Test Milestone 3 features only
powershell -ExecutionPolicy Bypass -File C:\sovereign_manifold_v31\tests\e2e\Run-All-E2E-Tests.ps1 -Tier 1 -Milestone M3
```

### 6.4 Running an Individual Feature Test
```powershell
# Test Feature 12 (Admin Header Auth)
powershell -ExecutionPolicy Bypass -File C:\sovereign_manifold_v31\tests\e2e\Run-All-E2E-Tests.ps1 -Feature 12

# Test Feature 23 (Zero-Square-Bracket Module)
powershell -ExecutionPolicy Bypass -File C:\sovereign_manifold_v31\tests\e2e\Run-All-E2E-Tests.ps1 -Feature 23
```

### 6.5 Exporting Test Execution Reports
```powershell
powershell -ExecutionPolicy Bypass -File C:\sovereign_manifold_v31\tests\e2e\Run-All-E2E-Tests.ps1 -ReportFormat JSON -OutputPath C:\sovereign_manifold_v31\tests\e2e\reports\ci_results.json
```

---

## 7. Exit Codes & CI/CD Pipeline Semantics

| Exit Code | Meaning | Action Required |
| :---: | :--- | :--- |
| `0` | **All Executed Tests Passed (100%)** | Proceed to gate verification or release publication. |
| `1` | **One or More Tests Failed** | Inspect test failure message, identify missing milestone requirement, and escalate to responsible worker. |

---

## 8. Defect Escalation & QA Protocols

When a test fails during implementation:
1. **Determine Failure Type**:
   - Implementation Bug / Missing Feature: Escalate to the appropriate Milestone implementing agent (e.g. `l0-rust-lean4-architect`, `cloudflare-d1-tunnel-ops`, `hud-cockpit-guardian`).
   - Test Defect: Update test assertions strictly if specification interpretation changed, ensuring alignment with `PROJECT.md` and `ORIGINAL_REQUEST.md`.
2. **Zero-Mock Policy Enforcement**:
   - Never suppress or bypass a failing test with hardcoded return values or mocked responses.
   - All tests must pass against real measured hardware and filesystem outputs.
