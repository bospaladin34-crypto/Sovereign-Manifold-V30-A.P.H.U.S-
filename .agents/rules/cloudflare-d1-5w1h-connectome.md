---
trigger: model_decision
description: "Apply whenever working with the 5W1H Metabolic Harness, 84,480-Neuron Connectome (.npage), 262,144 Bijected Cachelines, MIT Cold-to-Hot Ingestion Pipeline (F:\ -> E:\), Cloudflare Durable Objects (worker_vpc_shadow_v3700.js), Named Tunnel, or Cloudflare D1 10-table database synchronization."
---
# 5W1H Harness, 84,480-Neuron Connectome (`4,055,040` Synapses, `262,144` CLs), MIT `F:\` $\rightarrow$ `E:\` Vault, Cloudflare DO & D1 Rules (`v70.0.0` | `CHAIN 316` | `840/840 QED`)

1. **84,480-Neuron Connectome & $2^{18}$ Cacheline Bijection (`10,813,440 B` `.npage` + `5,406,720 B` `.spage` + `557,056 B` `.e8z` = `16,777,216 B` / `262,144` Bijected Cachelines / `4,055,040` Synapses)**:
   - `21,120` Core Shards (`03_vault\shards\shard_00001..21120.binshard`) + `21,120` Expansion Shards (`03_vault\shards_expansion\shard_21121..42240.binshard`) + `21,120` Tier-3 Shards (`03_vault\shards_tier3\shard_42241..63360.binshard`) + `21,120` Tier-4 MIT Curriculum Shards (`03_vault\shards_tier4\shard_63361..84480.binshard`) == `84,480` Total 3-Compartment Dendritic Neurons (`00_control\weights\neurons_v6900_84480.npage`, `10,813,440 B = 84,480 x 128 B = 168,960 x 64 B` cachelines, `1,920 x Chair-44` columns, `1,351,680` primary synapses) + `00_control\weights\synapses_v6900_2703360.spage` (`5,406,720 B = 84,480 x 64 B` cachelines, `2,703,360` auxiliary plastic synapses) = **`4,055,040` Total Synapses** across `48` Macro-Domains (`192` Sub-Domains), plus `8,704` Quad-Bank `.e8z` cachelines (`sovereign_harmonic_viii_v6900_8704cl.e8z`, `557,056 B`) = **`262,144` ($2^{18}$) bijected 64-byte cachelines (`16,777,216 B = 16.00 MiB = 2^{24}\text{ B}`)** in 1:2 bijection with **`524,288` ($2^{19}$) 19-Bit Open-Vocabulary BPE tokens**.
   - **Backward Compatibility Invariant**: Always preserve `neurons_v5000_63360.npage` (`8,110,080 B`), `synapses_v5700_2027520.spage` (`4,055,040 B`), and `sovereign_harmonic_iv_v5000.e8z` (`133,120 B`) intact so all v50 tools and Layer 3 verification pass 100%.

2. **Tri-Drive MIT Hot-Index Ingestion Pipeline (`F:\` 3.0 TB Cold $\rightarrow$ `E:\` 1.5 TB SSD Hot)**:
   - Cold Archive (`F:\Sovereign_Cold_Vault\MIT_Corpus\{ocw_zips, ocw_extracted, dspace_theses, datasets, staging_3_2_sigma}`) stores raw MIT OpenCourseWare bundles (including `MIT6_451S05_FullLecNotes.pdf`) and $3.2\sigma$ quarantine candidates.
   - Hot Index (`E:\Sovereign_Manifold_SSD_Vault\mit_hot_index\{e8_polytonic_32d_shards, lean4_candidates_5_0_sigma, manifests}`) stores the 10 64B-aligned `SH4Z v3101 .e8q` 32D Polytonic $E_8^{\oplus 4}$ shards (`18_701.e8q` .. `8_04.e8q`) with Fibonacci $F_{15} = 610$ golden-angle tags and $5.0\sigma$ + `lean4_qed` promoted theorems.

3. **Cloudflare Durable Object Zero-Overhead SQLite, Batched D1 & Anti-502 Tunnel Rules**:
   - Active Cloudflare Worker entrypoint in `wrangler.toml` is `00_control/cloudflare_edge/worker_vpc_shadow_v3700.js` (`SovereignEdgeShadowDO` synced 1:1 to `00_control/cloudflare_edge/worker_continuum_do.js` and root `worker_vpc_shadow_v3700.js`). Whenever `worker_vpc_shadow_v3700.js` is modified locally, mirror it to both copies AND run `npx wrangler deploy` (preserving the `/google6edc0affb12d0455.html` `53 B` route).
   - `00_control/cloudflare_named_config.yml` enforces `protocol: http2` and tunnel UUID `9cdea4c4-831d-4ccc-983d-5f7587a98206` routing `act-omega-net.dev` -> `127.0.0.1:5173` and `api.act-omega-net.dev` / `mcp.act-omega-net.dev` -> `127.0.0.1:8097`.

4. **Remote Cloudflare D1 (`act_omega_d1_vault`, 10 Tables)**:
   - Synchronize all 10 tables in `act_omega_d1_vault` (`9f46d56a-ef3e-4232-a9ac-c4bd12e20a87`) with real measured SHA-256 digests, real byte counts, and real hardware timestamps.
