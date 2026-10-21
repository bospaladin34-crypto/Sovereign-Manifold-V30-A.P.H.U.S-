---
trigger: glob
globs: "01_l0_rust/**/*.rs, 01_l0_rust/**/*.lean, 03_vault/lean4/*.lean"
description: "L0 Rust Swarm Daemon (v31_swarm.exe), Zero-Mock telemetry, 5W1H-Neuron Connectome, and 364 Lean 4 QED rules."
---
# L0 Rust & Lean 4 Rules (ACT-Omega v43.0.0)
1. `01_l0_rust/src/bin/v31_swarm.rs` compiles into `01_l0_rust/target/release/v31_swarm.exe` and serves BOTH `:8097` (API/Telemetry) and `:5173` (Static WebGPU HUD from `05_hud_cockpit/dist`).
2. Whenever any `.rs` file in `01_l0_rust/src` is modified, always stage-build via `cargo build --release --bin v31_swarm --target-dir target_stage` and atomically hot-swap `target/release/v31_swarm.exe`.
3. Keep zero square brackets in `v35_fno_liquid_connectome.rs`, `v36_torchtpu_pagefile_dendritic.rs`, `v37_metabolic_harness_5w1h.rs`, `v37_mcp_openai_cloudflare_d1.rs`, `v37_recursive_compound_speech.rs`, and `v38_symbiotic_ide_memory_a2a_delta.rs`.
