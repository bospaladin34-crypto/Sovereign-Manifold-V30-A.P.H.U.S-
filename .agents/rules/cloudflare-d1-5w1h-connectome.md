---
trigger: model_decision
description: "Apply whenever working with the 5W1H Metabolic Harness, 63,360-Neuron Connectome (.npage), Cloudflare Durable Objects (worker_vpc_shadow_v3700.js), Named Tunnel, or Cloudflare D1 10-table database synchronization."
---
# 5W1H Harness, 63,360-Neuron Connectome, Cloudflare Durable Objects & D1 Rules (ACT-Omega v50.0.0+ | CHAIN 135)

1. **63,360-Neuron Connectome Bijection (`8,110,080 B` SHM)**:
   - `21,120` Core Shards (`03_vault\shards\shard_00001..21120.binshard`) + `21,120` Expansion Shards (`03_vault\shards_expansion\shard_21121..42240.binshard`) + `21,120` Tier-3 Scale-Up Shards (`03_vault\shards_tier3\shard_42241..63360.binshard`) == `63,360` Total 3-Compartment Dendritic Neurons (`00_control\weights\neurons_v5000_63360.npage`, `8,110,080 B = 63,360 x 128 B`, `1,440 x Chair-44` columns, `1,013,760` synapses across 36 Macro-Domains / 144 Sub-Domains).

2. **Cloudflare Durable Object Zero-Overhead SQLite, Batched D1 & Anti-502 Tunnel Rules**:
   - Active Cloudflare Worker entrypoint in `wrangler.toml` is `00_control/cloudflare_edge/worker_vpc_shadow_v3700.js` (`SovereignEdgeShadowDO` synced 1:1 to `worker_continuum_do.js`).
   - `SovereignEdgeShadowDO` MUST serve `GET` requests from in-memory caches (`0` SQLite read queries on `GET` hot path), debounce SQLite writes, and batch D1 reads via single-round-trip `env.ACT_OMEGA_D1.batch([...])`.
   - `00_control/cloudflare_named_config.yml` enforces `protocol: http2`, `keepAliveConnections: 100`, `keepAliveTimeout: 90s`, `connectTimeout: 10s`, and explicit `httpHostHeader` routing to `127.0.0.1:5173` and `127.0.0.1:8097`.

3. **Remote Cloudflare D1 (`act_omega_d1_vault`, 10 Tables)**:
   - Synchronize all 10 tables in `act_omega_d1_vault` (`9f46d56a-ef3e-4232-a9ac-c4bd12e20a87`) via `npx wrangler d1 execute act_omega_d1_vault --remote --file=00_control/cloudflare_edge/sync_d1_v4900_chain100.sql`:
     `harness_5w1h_audit_log`, `npage_tier_snapshots`, `wal_merkle_checkpoints`, `v40_qat_training_sessions`, `v40_shard_registry`, `v41_measured_sha256_audit`, `v42_5w1h_distributed_routes`, `v43_antigravity_agent_roster`, `v44_multiturn_working_memory_ring`, and `v44_visiting_llm_agent_ledger`.

4. **HARD CONSTRAINT (MUSE MANDATE)**:
   - **"If it is not measured, calculated or computed, it DOES NOT ship, full stop."** Every SQL row and Durable Object state payload must contain real measured SHA-256 digests, real byte counts, and real hardware timestamps.
