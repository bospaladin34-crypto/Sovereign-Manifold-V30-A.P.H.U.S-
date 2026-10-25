---
trigger: model_decision
description: "Apply whenever working with the 5W1H Metabolic Harness, 42,240-Neuron Connectome (.npage), Cloudflare Durable Objects (worker_vpc_shadow_v3700.js), Named Tunnel, or Cloudflare D1 10-table database synchronization."
---
# 5W1H Harness, 42,240-Neuron Connectome, Cloudflare Durable Objects & D1 Rules (ACT-Omega v49.0.0+ | CHAIN 100)

1. **42,240-Neuron Connectome Bijection (`5,406,720 B` SHM)**:
   - `21,120` Core Shards (`03_vault\shards\shard_00001..21120.binshard`, `00_control\weights\neurons_v4000.npage`, `2,703,360 B`) + `21,120` Expansion Shards (`03_vault\shards_expansion\shard_21121..42240.binshard`, `00_control\weights\neurons_v4400_expansion.npage`, `2,703,360 B`) == `42,240` Total 3-Compartment Dendritic Neurons (`00_control\weights\neurons_v4600_42240.npage` & `neurons_v4400_p8_shm.npage`, `5,406,720 B = 42,240 x 128 B`, `960 x Chair-44` columns, `337,920` synapses).

2. **Cloudflare Durable Object Zero-Overhead SQLite & Anti-502 Tunnel Rules**:
   - Active Cloudflare Worker entrypoint in `wrangler.toml` is `00_control/cloudflare_edge/worker_vpc_shadow_v3700.js` (`SovereignContinuumDO` synced to `worker_continuum_do.js`).
   - `SovereignContinuumDO` MUST serve `GET` requests from in-memory `this.memState` (`0` SQLite read queries on `GET` hot path) and only execute `this.ctx.storage.sql.exec("INSERT OR REPLACE ...")` when `generation !== prevGen || action !== prevAction` to prevent Durable Object storage/CPU throttling.
   - `00_control/cloudflare_named_config.yml` enforces `protocol: http2`, `keepAliveConnections: 100`, `keepAliveTimeout: 90s`, `connectTimeout: 10s`, and explicit `httpHostHeader` routing to `127.0.0.1:5173` and `127.0.0.1:8097`.

3. **Remote Cloudflare D1 (`act_omega_d1_vault`, 10 Tables)**:
   - Synchronize all 10 tables in `act_omega_d1_vault` (`9f46d56a-ef3e-4232-a9ac-c4bd12e20a87`) via `npx wrangler d1 execute act_omega_d1_vault --remote --file=00_control/cloudflare_edge/sync_d1_v4900_chain100.sql`:
     `harness_5w1h_audit_log`, `npage_tier_snapshots`, `wal_merkle_checkpoints`, `v40_qat_training_sessions`, `v40_shard_registry`, `v41_measured_sha256_audit`, `v42_5w1h_distributed_routes`, `v43_antigravity_agent_roster`, `v44_worksteal_webgpu_leases`, and `v44_expansion_shard_audit`.

4. **HARD CONSTRAINT (MUSE MANDATE)**:
   - **"If it is not measured, calculated or computed, it DOES NOT ship, full stop."** Every SQL row and Durable Object state payload must contain real measured SHA-256 digests, real byte counts, and real hardware timestamps.
