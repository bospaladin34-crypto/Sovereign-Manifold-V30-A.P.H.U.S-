---
trigger: glob
globs: "01_l0_rust/src/v48_*.rs, 01_l0_rust/src/bin/v31_swarm.rs, 03_vault/connectome/*.jsonl"
description: "Sovereign Autopoietic Coordinator Bus, Universal E:\ SSD Vault Write-Back Pipeline, and DuckDB Columnar Analytical Engine rules."
---
# Sovereign Autopoietic Coordinator Bus, `E:\` Write-Back & DuckDB Rules (ACT-Omega v49.0.0+ | CHAIN 100)

1. **No-Siloed-Tools Law (`v48_autopoietic_coordinator_bus.rs`)**:
   - Every tool (`Tools 1..100+`), codegen operation, and autonomous engine in `01_l0_rust/src/bin/v31_swarm.rs` must publish a 5W1H `BusEnvelope` via `publish_tool_execution_to_coordinator_bus()` or `/api/v1/coordinator/message_bus`.
   - Each `BusEnvelope` must record a measured SHA-256 payload digest, timestamp, decadic sub-epoch (`0..9`), `.npage` neuron index (`0..42,239`), Chair-44 column (`0..959`), sector (`S00..S79`), and write to both:
     - `E:\Sovereign_Manifold_SSD_Vault\coordinator_bus\message_bus_ledger_v4800.jsonl`
     - `C:\sovereign_manifold_v31\03_vault\connectome\message_bus_ledger_v4800.jsonl`

2. **Universal `E:\` Autopoietic Codegen Persistence**:
   - All codegen operations (`/api/v1/coordinator/codegen_vault_sink`, `/api/v1/coordinator/dag_orchestrator`, `/api/v1/coordinator/autopoietic_integrator`, Tool 87 Haskell codegen, Tool 48/74 synthesis) must persist real files to:
     - `E:\Sovereign_Manifold_SSD_Vault\autopoietic_codegen\rust_l0\`
     - `E:\Sovereign_Manifold_SSD_Vault\autopoietic_codegen\lean4_proofs\`
     - `E:\Sovereign_Manifold_SSD_Vault\autopoietic_codegen\wgsl_kernels\`
     - `E:\Sovereign_Manifold_SSD_Vault\autopoietic_codegen\hs_algebra\`
     - `E:\Sovereign_Manifold_SSD_Vault\autopoietic_codegen\tool_outputs\`
   - Every persisted artifact must be verified (`0` square brackets for Rust L0) and logged to `E:\Sovereign_Manifold_SSD_Vault\autopoietic_codegen\codegen_integration_manifest_v4800.jsonl` and `03_vault\connectome\codegen_integration_manifest_v4800.jsonl`.

3. **DuckDB Columnar Analytical & Hamiltonian $k=4$ Model Integrity (`v48_haskell_duckdb_hamiltonian_model.rs`)**:
   - Analytical queries execute via `C:\sovereign_manifold_v31\00_control\foss_bin\duckdb.exe` (`read_json_auto`) against real `.jsonl` ledgers in `03_vault\connectome\`.
   - Speculative $k=4$ Hamiltonian beam decoding metrics (`acceptance_rate`, `measured_speedup_factor`) must be computed dynamically from measured beam action (`action_s < 0.0`), never hardcoded.
