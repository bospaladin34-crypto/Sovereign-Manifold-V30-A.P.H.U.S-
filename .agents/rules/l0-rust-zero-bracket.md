---
trigger: glob
globs: "01_l0_rust/**/*.rs, 01_l0_rust/**/*.lean, 03_vault/lean4/*.lean, 06_algebraic_haskell/**/*.hs"
description: "L0 Rust Swarm Daemon (v31_swarm.exe), OmegaLang v16.0 Primary 9-Target TLV Compiler (omegalang_tlv_compiler.exe), Heterogeneous CPU+RTX 3050 CUDA Co-Execution, Zero-Square-Bracket v33..v70+ verifier, Layer 1.5 Haskell, and 840/840 Substantive Lean 4 QED rules."
---
# L0 Rust, OmegaLang v16.0 TLV, Substantive Lean 4 & Layer 1.5 Haskell Rules (ACT-Omega v70.0.0 | CHAIN 316 | 840/840 QED)

1. **Zero-Square-Bracket Invariant (`v33..v70+`) & Zero Python**:
   - Strictly `0` `[` or `]` characters are permitted in any `01_l0_rust/src/v33*.rs .. v70*.rs` (and all future modules). Use `.get(idx)`, `.chars().nth(idx)`, `vec!()`, and `serde_json::Value::Array(vec!())`. Never run `python` or create `.py` scripts.
   - Before compiling, always verify with:
     `Get-ChildItem "C:\sovereign_manifold_v31\01_l0_rust\src\v*.rs" | Where-Object { $_.Name -match '^v(3[3-9]|[4-9][0-9])' } | ForEach-Object { $c = [System.IO.File]::ReadAllText($_.FullName); $b = ([regex]::Matches($c, '[\[\]]')).Count; if ($b -gt 0) { throw "BRACKET_VIOLATION: $($_.Name) has $b brackets" } }`

2. **Staged Compilation & Atomic Hot-Swap Protocol**:
   - `01_l0_rust/src/bin/v31_swarm.rs` compiles into `01_l0_rust/target/release/v31_swarm.exe` and serves BOTH `:8097` (API/MCP/Telemetry) and `:5173` (Static WebGPU HUD from `05_hud_cockpit/dist`).
   - Because `v31_swarm.exe` locks `target/release/v31_swarm.exe` while running, ALWAYS compile into `--target-dir target_stage`:
     `cargo build --release --bin v31_swarm --target-dir target_stage`
   - Then atomically hot-swap via `powershell -ExecutionPolicy Bypass -File "C:\sovereign_manifold_v31\00_control\HotSwap-v50.ps1"`.

3. **Substantive Lean 4 Formal Proofs (`840/840` Theorems, Zero Trivial Padding)**:
   - Every theorem in `03_vault/lean4/SovereignManifoldTheorems.lean` MUST operate over an explicitly defined domain `structure` or `def` (e.g., `weylReflect1D`, `encodeChair44Neuron`, `plucker6D`, `GaloisFieldTower256`, `CernLhcbHlt1Sieve`, `OmegaLangV16TlvManifest`, `CpuGpuHeteroSplit`, `BijectedManifold262144`, `TriSiliconConservationSimplex`, `chebyshevP4Scaled`, `leapfrogStep`).
   - Bare arithmetic identities (`a + b = b + a`, `n + 0 = n`, `N = N`) proved by `omega`/`rfl` to pad theorem counts are strictly forbidden.
   - Always verify with `C:\Users\Nbell\.elan\bin\lean.exe "C:\sovereign_manifold_v31\03_vault\lean4\SovereignManifoldTheorems.lean"` (`EXIT: 0`, `0` warnings, `0` `sorry`) and copy 1:1 to `01_l0_rust/lean4/SovereignManifoldTheorems.lean`.

4. **Layer 1.5 Pure Algebraic Haskell (`06_algebraic_haskell`)**:
   - The GHC 9.8.2 compiler on Anchor-1 is located at `C:\sovereign_manifold_v31\00_control\foss_bin\ghc\bin\ghc.exe`.
   - Whenever modifying `06_algebraic_haskell/src/Sovereign/Codegen/ZeroBracketRustAndLean4.hs` or `Main.hs`, recompile with `C:\sovereign_manifold_v31\00_control\foss_bin\ghc\bin\ghc.exe -O2 -i06_algebraic_haskell/src -outputdir 06_algebraic_haskell/build -o 06_algebraic_haskell/bin/sovereign_algebra_hs.exe 06_algebraic_haskell/src/Main.hs` and execute `06_algebraic_haskell\bin\sovereign_algebra_hs.exe` to emit `01_l0_rust/src/v48_haskell_generated_invariants.rs`.

5. **Total Branch Measurement & `// SCAFFOLD:` Mandate**:
   - Every branch (including `action == "release"` in `v44_worksteal_npage_shm_webgpu_lease.rs`, `.e8z` audits in `v49_muse_clean_and_chain100_synthesis.rs`, `v60_sample_manifold_bytes` full-slice folding, `Tool 183` Verifier Sentry, and `Tools 301..316`) must compute from real measurements (`Instant::now()`, `12/12` `.e8z` bytes, full 64B/128B slice folding, `262,144` cachelines) or return `"UNMEASURED/OFFLINE"`. Any reference constant must carry `// SCAFFOLD: <what it stands in for> — measure via <how>`.

6. **OmegaLang v16.0 9-Target Primary TLV Compiler & Heterogeneous CPU+RTX 3050 CUDA Co-Execution (`v69..v70`)**:
   - `01_l0_rust/src/bin/omegalang_tlv_compiler.rs` compiles `03_vault/omegalang_v16/sovereign_harmonic_v69.oml` into `sovereign_harmonic_viii_v6900_8704cl.e8z` (`557,056 B`), `neurons_v6900_84480.npage` (`10,813,440 B`), `synapses_v6900_2703360.spage` (`5,406,720 B`), `shard_63361..84480.binshard`, and Target #9 Ampere `sm_86` PTX (`03_vault/codegen/rtx3050_omegalang_k20_fno_coexec.ptx`).
   - Cross-module helper functions in included `v68_5..v70_0` files (such as `v69_5_load_connectome_and_ptx` and `v69_5_build_gpu_s24_s47_batch`) must be marked `pub fn` so downstream tracks can invoke them cleanly.
