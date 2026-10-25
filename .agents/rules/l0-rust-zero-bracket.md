---
trigger: glob
globs: "01_l0_rust/**/*.rs, 01_l0_rust/**/*.lean, 03_vault/lean4/*.lean, 06_algebraic_haskell/**/*.hs"
description: "L0 Rust Swarm Daemon (v31_swarm.exe), Zero-Square-Bracket v33..v49+ verifier, 100% .e8z/.npage byte sampling, Layer 1.5 Haskell, and 460+ Substantive Lean 4 QED rules."
---
# L0 Rust, Substantive Lean 4 & Layer 1.5 Haskell Rules (ACT-Omega v49.0.0+ | CHAIN 100)

1. **Zero-Square-Bracket Invariant (`v33..v49+`)**:
   - Strictly `0` `[` or `]` characters are permitted in any `01_l0_rust/src/v33*.rs .. v49*.rs` (and future `v50+`) module. Use `.get(idx)`, `.chars().nth(idx)`, `vec!()`, and `serde_json::Value::Array(vec!())`.
   - Before compiling, always verify with:
     `Get-ChildItem "C:\sovereign_manifold_v31\01_l0_rust\src\v*.rs" | Where-Object { $_.Name -match '^v(3[3-9]|[4-9][0-9])_' } | ForEach-Object { $c = [System.IO.File]::ReadAllText($_.FullName); $b = ([regex]::Matches($c, '[\[\]]')).Count; if ($b -gt 0) { throw "BRACKET_VIOLATION: $($_.Name) has $b brackets" } }`

2. **Staged Compilation & Atomic Hot-Swap Protocol**:
   - `01_l0_rust/src/bin/v31_swarm.rs` compiles into `01_l0_rust/target/release/v31_swarm.exe` and serves BOTH `:8097` (API/MCP/Telemetry) and `:5173` (Static WebGPU HUD from `05_hud_cockpit/dist`).
   - Because `v31_swarm.exe` locks `target/release/v31_swarm.exe` while running, ALWAYS compile into `--target-dir target_stage`:
     `cargo build --release --bin v31_swarm --target-dir target_stage`
   - Then atomically hot-swap via `powershell -ExecutionPolicy Bypass -File "C:\sovereign_manifold_v31\00_control\HotSwap-v49.ps1"`.

3. **Substantive Lean 4 Formal Proofs (`460+` Theorems, Zero Trivial Padding)**:
   - Every theorem in `03_vault/lean4/SovereignManifoldTheorems.lean` MUST operate over an explicitly defined domain `structure` or `def` (e.g., `weylReflect1D`, `encodeChair44Neuron`, `plucker6D`, `pyramidCubicSum`, `chshCorrelator`, `eulerEnergyRate`).
   - Bare arithmetic identities (`a + b = b + a`, `n + 0 = n`, `N = N`) proved by `omega`/`rfl` to pad theorem counts are strictly forbidden.
   - Always verify with `C:\Users\Nbell\.elan\bin\lean.exe "C:\sovereign_manifold_v31\03_vault\lean4\SovereignManifoldTheorems.lean"` (`EXIT: 0`, `0` warnings, `0` `sorry`) and copy 1:1 to `01_l0_rust/lean4/SovereignManifoldTheorems.lean`.

4. **Layer 1.5 Pure Algebraic Haskell (`06_algebraic_haskell`)**:
   - Whenever modifying `06_algebraic_haskell/src/Sovereign/Codegen/ZeroBracketRustAndLean4.hs` or `Main.hs`, recompile with `C:\ghcup\bin\ghc.exe -O2 -i06_algebraic_haskell/src -outputdir 06_algebraic_haskell/build -o 06_algebraic_haskell/bin/sovereign_algebra_hs.exe 06_algebraic_haskell/src/Main.hs` and verify emitted Lean 4 files with `lean.exe`.

5. **Total Branch Measurement & `// SCAFFOLD:` Mandate**:
   - Every branch (including `action == "release"` in `v44_worksteal_npage_shm_webgpu_lease.rs` and `.e8z` audits in `v49_muse_clean_and_chain100_synthesis.rs`) must compute from real measurements (`Instant::now()`, `12/12` `.e8z` bytes) or return `"UNMEASURED/OFFLINE"`. Any reference constant must carry `// SCAFFOLD: <what it stands in for> — measure via <how>`.
