-- =============================================================================
-- ACT-OMEGA NET v47.0.0 (SH4Z v4700 TLV) - FULL 10-TABLE CLOUDFLARE D1 SYNC
-- Synchronizes all 10 tables in act_omega_d1_vault (9f46d56a-ef3e-4232-a9ac-c4bd12e20a87):
-- 1. harness_5w1h_audit_log
-- 2. npage_tier_snapshots
-- 3. wal_merkle_checkpoints
-- 4. v40_qat_training_sessions
-- 5. v40_shard_registry
-- 6. v41_measured_sha256_audit
-- 7. v42_5w1h_distributed_routes
-- 8. v43_antigravity_agent_roster
-- 9. v44_visiting_llm_agent_ledger (NEW in v44.0.0)
-- 10. v44_multiturn_working_memory_ring (NEW in v44.0.0)
-- =============================================================================

CREATE TABLE IF NOT EXISTS npage_tier_snapshots (
    snapshot_id INTEGER PRIMARY KEY AUTOINCREMENT,
    schema_version TEXT NOT NULL DEFAULT 'SH4Z_v4700_TLV',
    total_neurons INTEGER NOT NULL DEFAULT 42240,
    total_bytes INTEGER NOT NULL DEFAULT 5406720,
    active_synapses INTEGER NOT NULL DEFAULT 337920,
    swr_sub_epochs INTEGER NOT NULL DEFAULT 10,
    swr_compression_ratio REAL NOT NULL DEFAULT 24.0,
    metabolic_atp_score REAL NOT NULL,
    rtx3050_temp_c REAL NOT NULL,
    recorded_at_ms INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS harness_5w1h_audit_log (
    event_id INTEGER PRIMARY KEY AUTOINCREMENT,
    chain_level TEXT NOT NULL DEFAULT 'CHAIN_89',
    metabolic_band TEXT NOT NULL,
    atp_score REAL NOT NULL,
    why_motivation TEXT NOT NULL,
    what_tools_invoked TEXT NOT NULL,
    where_silicon_target TEXT NOT NULL,
    when_schedule_window TEXT NOT NULL,
    how_execution_kernel TEXT NOT NULL,
    recorded_at_ms INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS wal_merkle_checkpoints (
    checkpoint_id INTEGER PRIMARY KEY AUTOINCREMENT,
    e8z_filename TEXT NOT NULL DEFAULT 'sovereign_harmonic_iv_v4000.e8z',
    e8z_bytes INTEGER NOT NULL DEFAULT 133120,
    shard_count INTEGER NOT NULL DEFAULT 42240,
    lean4_proofs_qed INTEGER NOT NULL DEFAULT 432,
    sha256_digest TEXT NOT NULL,
    recorded_at_ms INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS v40_qat_training_sessions (
    session_id INTEGER PRIMARY KEY,
    session_name TEXT NOT NULL,
    epochs INTEGER NOT NULL,
    start_epoch INTEGER NOT NULL,
    end_epoch INTEGER NOT NULL,
    domain_focus TEXT NOT NULL,
    grad_l2_norm REAL NOT NULL,
    atp_score REAL NOT NULL,
    holdout_ppl REAL NOT NULL,
    shards_active INTEGER NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS v40_shard_registry (
    batch_id INTEGER PRIMARY KEY,
    shard_range TEXT NOT NULL,
    chair44_column_range TEXT NOT NULL,
    shard_count INTEGER NOT NULL,
    npage_bytes INTEGER NOT NULL,
    sinai_entropy_h REAL NOT NULL,
    storage_tiers TEXT NOT NULL,
    verified_qed INTEGER NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS v41_measured_sha256_audit (
    artifact_name TEXT PRIMARY KEY,
    byte_length INTEGER NOT NULL,
    sha256_digest TEXT NOT NULL,
    measured_shards INTEGER NOT NULL,
    measured_neurons INTEGER NOT NULL,
    verified_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS v42_5w1h_distributed_routes (
    route_id INTEGER PRIMARY KEY,
    who_caller TEXT NOT NULL,
    what_workload TEXT NOT NULL,
    when_clock_hz REAL NOT NULL,
    where_silicon_node TEXT NOT NULL,
    where_sector_span TEXT NOT NULL,
    why_metabolic_atp REAL NOT NULL,
    how_transport TEXT NOT NULL,
    operator_vault_gated INTEGER NOT NULL,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS v43_antigravity_agent_roster (
    agent_id INTEGER PRIMARY KEY,
    agent_name TEXT NOT NULL,
    agent_file TEXT NOT NULL,
    model_tier TEXT NOT NULL,
    domain_scope TEXT NOT NULL,
    bound_npage_neurons INTEGER NOT NULL,
    bound_sectors TEXT NOT NULL,
    mcp_server_url TEXT NOT NULL,
    status TEXT NOT NULL,
    updated_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS v44_visiting_llm_agent_ledger (
    visit_id INTEGER PRIMARY KEY,
    agent_id TEXT NOT NULL,
    protocol TEXT NOT NULL,
    dominant_domain TEXT NOT NULL,
    token_count INTEGER NOT NULL,
    compression_ratio REAL NOT NULL,
    mapped_sector INTEGER NOT NULL,
    mapped_chair44_col INTEGER NOT NULL,
    crystallized_neuron_id INTEGER NOT NULL,
    crystallized_shard_id INTEGER NOT NULL,
    attestation_sig TEXT NOT NULL,
    prompt_excerpt TEXT NOT NULL,
    recorded_at_ms INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS v44_multiturn_working_memory_ring (
    turn_id INTEGER PRIMARY KEY,
    dominant_domain TEXT NOT NULL,
    token_count INTEGER NOT NULL,
    mapped_sector INTEGER NOT NULL,
    mapped_chair44_col INTEGER NOT NULL,
    mapped_neuron_id INTEGER NOT NULL,
    prompt_text TEXT NOT NULL,
    synthesis_excerpt TEXT NOT NULL,
    recorded_at_ms INTEGER NOT NULL
);

INSERT OR REPLACE INTO npage_tier_snapshots (snapshot_id, schema_version, total_neurons, total_bytes, active_synapses, swr_sub_epochs, swr_compression_ratio, metabolic_atp_score, rtx3050_temp_c, recorded_at_ms) VALUES
(9, 'SH4Z_v4300_EXPANSION_BANK_24640', 24640, 3153920, 197120, 10, 24.0, 0.9524, 49.0, 1761102000000),
(10, 'SH4Z_v4400_EXPANSION_BANK_28160', 28160, 3604480, 225280, 10, 24.0, 0.9548, 49.0, 1761110400000),
(11, 'SH4Z_v4700_CONNECTOME_42240_NEURONS', 42240, 5406720, 337920, 10, 24.0, 0.9554, 49.0, 1761248400000);

INSERT OR REPLACE INTO harness_5w1h_audit_log (event_id, chain_level, metabolic_band, atp_score, why_motivation, what_tools_invoked, where_silicon_target, when_schedule_window, how_execution_kernel, recorded_at_ms) VALUES
(10, 'CHAIN_72', 'BAND_1_24640_CONNECTOME_128_8D_LEXICON_HUD_INSPECTOR', 0.9524, 'Expand Connectome to 24,640 Neurons/Shards (+3,520 = 80x Chair-44), 128 8-Domain Compound Phrases & Interactive 65K BPE HUD/APK Inspector', 'Tools 25, 27, 42, 45, 48, 50 & 70 + /api/v1/tokenizer/bpe_65k', 'LOQ15 + Pixel 10 + Pixel 8 + E: SSD + G: Bridge + Cloudflare D1/Worker/DO', '*/15 * * * * Cron + 15.965 Hz Decadic Lockstep', 'neurons_v4300_expansion.npage (450,560B, 3,520N) -> 24,640 Combined Neurons (560x Chair-44, 197,120 Synapses)', 1761102000100),
(11, 'CHAIN_76', 'BAND_1_V4400_ARCHITECTURE_FACELIFT_28160_NEURONS_16DOMAINS', 0.9548, 'Execute v44.0.0 5-Cycle Facelift: 16 Domains (256 Compounds), 28,160 Neurons (640x Chair-44), Safe LLM Gateway, Multi-Turn Memory (T73), Socratic Debate (T74), Self-Profiler (T75) & Omni-Snapshot (T76)', 'Tools 01-76 (CHAIN 76 Parallel DAG + 10-Table D1 + Dual-Pixel C++ JNI SH4Z v4400)', 'LOQ15 RTX 3050 (S00..S47) + Pixel 10 G5 (S48..S63) + Pixel 8 P8-APEX (S64..S79) + E: SSD + 10-Table D1', '*/15 * * * * Cron + 15.965 Hz Decadic Epoch + 159.65 Hz SWR Replay', 'neurons_v4400_expansion.npage (901,120B, 7,040N) -> 28,160 Combined Neurons (640x Chair-44, 225,280 Synapses, 384/384 Lean 4 QED)', 1761110400100),
(12, 'CHAIN_89', 'BAND_1_V4700_42240_NEURONS_131K_24D_89TOOLS_432QED', 0.9554, 'Execute v47.0.0 42,240-Neuron Connectome (960x Chair-44, 5,406,720 B .npage), 131,072 24-Domain Open-Vocabulary BPE, 89 Tools (T85..T89) & 432/432 Lean 4 QED', 'Tools 01-89 (CHAIN 89 Parallel DAG + Real Synaptic QAT + Measured SHA-256)', 'LOQ15 RTX 3050 (S00..S47) + Pixel 10 G5 (S48..S63) + Pixel 8 P8-APEX (S64..S79) + E: SSD + 10-Table D1', '*/15 * * * * Cron + 15.965 Hz Decadic Epoch + 159.65 Hz SWR Replay', 'neurons_v4600_42240.npage (5,406,720B, 42,240N) -> 42,240 Combined Neurons == 42,240 Shards (960x Chair-44, 337,920 Synapses, 432/432 Lean 4 QED)', 1761248400100);

INSERT OR REPLACE INTO wal_merkle_checkpoints (checkpoint_id, e8z_filename, e8z_bytes, shard_count, lean4_proofs_qed, sha256_digest, recorded_at_ms) VALUES
(9, 'neurons_v4300_expansion.npage', 450560, 24640, 364, 'ac8899c6b6c00b213727ad82a08f3eeff56dbaebd63cd14c33661b2774200768', 1761102000200),
(10, 'neurons_v4400_expansion.npage', 901120, 28160, 416, '0cf1f9d23730bf24d9bb5df389fbbf8757054f34789c78306281c2b9fb5928ef', 1761110400200),
(11, 'neurons_v4600_42240.npage', 5406720, 42240, 432, '542d7b47dc657c0ba00ab1fb8d45d8b35e7895df4a2a0c8b0bd9bc9b44cf7a08', 1761248400200);

INSERT OR REPLACE INTO v40_qat_training_sessions (session_id, session_name, epochs, start_epoch, end_epoch, domain_focus, grad_l2_norm, atp_score, holdout_ppl, shards_active) VALUES
(13, 'QAT-S13-24640-Neurons-128Phrase-8Domain-Lexicon', 128, 1537, 1664, '24,640 Combined Neurons (560x Chair-44, 197,120 Synapses) + 128 Multi-Word 8-Domain Compound Phrases', 0.000058, 0.9524, 1.119476, 24640),
(14, 'QAT-S14-28160-Neurons-256Phrase-16Domain-And-Dialectics', 128, 1665, 1792, '28,160 Combined Neurons (640x Chair-44, 225,280 Synapses) + 256 16-Domain Compound Phrases (D1..D16: Law, Economics, History) + Multi-Turn Memory & Socratic Debate', 0.000049, 0.9548, 1.119476, 28160),
(15, 'QAT-S15-42240-Neurons-131K-24Domain-E8Leech-SynapticQAT', 192, 1793, 1984, '42,240 Combined Neurons (960x Chair-44, 337,920 Synapses) + 131,072 24-Domain Open-Vocabulary BPE & Real Synaptic Weight Updates', 0.088435, 0.9554, 4.012657, 42240);

INSERT OR REPLACE INTO v40_shard_registry (batch_id, shard_range, chair44_column_range, shard_count, npage_bytes, sinai_entropy_h, storage_tiers, verified_qed) VALUES
(7, 'shard_22881..shard_24640', 'Chair44_521..Chair44_560', 1760, 225280, 0.4846, 'C:\03_vault\shards_expansion + E:\SSD_Vault\shards_expansion + G:\Bridge + D1', 1),
(8, 'shard_24641..shard_28160', 'Chair44_561..Chair44_640', 3520, 450560, 0.4852, 'C:\03_vault\shards_expansion + E:\SSD_Vault\shards_expansion + G:\Bridge + D1', 1),
(9, 'shard_28161..shard_42240', 'Chair44_641..Chair44_960', 14080, 1802240, 0.4864, 'C:\03_vault\shards_expansion + E:\SSD_Vault\shards_expansion + G:\Bridge + D1', 1);

INSERT OR REPLACE INTO v41_measured_sha256_audit (artifact_name, byte_length, sha256_digest, measured_shards, measured_neurons) VALUES
('sovereign_harmonic_iv_v4000.e8z', 133120, 'c383b1b7d00e6ce8cef22593536aea2d66523d53360c3552a64970a61e394b23', 21120, 21120),
('neurons_v4000.npage', 2703360, 'aee7711086a07bb6ddebc9e347ed4d68d3a38b57d57b08f9089d22345fa07d6d', 21120, 21120),
('neurons_v4400_expansion.npage', 901120, '0cf1f9d23730bf24d9bb5df389fbbf8757054f34789c78306281c2b9fb5928ef', 7040, 7040),
('neurons_v4600_42240.npage', 5406720, '542d7b47dc657c0ba00ab1fb8d45d8b35e7895df4a2a0c8b0bd9bc9b44cf7a08', 42240, 42240),
('SovereignManifoldTheorems.lean', 79750, 'fca430cb0d323ee8274d336034c70365180c0d752408c55c0635d61a02c5048a', 42240, 42240);

INSERT OR REPLACE INTO v42_5w1h_distributed_routes (route_id, who_caller, what_workload, when_clock_hz, where_silicon_node, where_sector_span, why_metabolic_atp, how_transport, operator_vault_gated) VALUES
(1, 'Host_LOQ15_Operator', 'L0_Tensor_FNO_And_16Domain_QAT', 15.965, 'Anchor1_Lenovo_LOQ15_RTX3050', 'S00..S47', 0.9548, 'ZeroCopy_Mmap_Ring', 0),
(2, 'Edge1_Pixel10_58170DLCR0004V', 'Edge_24D_Sensor_Stiefel_And_SH4Z_v4400', 15.965, 'Edge1_Google_Pixel10_TensorG5', 'S48..S63', 0.9532, 'ADB_Reverse_TCP_8097', 0),
(3, 'Edge2_Pixel8_3A121FDJH00BW5', 'Speculative_Drafter_And_L2_Verify', 15.965, 'Edge2_Google_Pixel8_P8APEX', 'S64..S79', 0.9540, 'ADB_Reverse_TCP_8097', 0),
(4, 'Symbiotic_IDE_Goose_Zed_Cline', 'Embedded_Operator_Vault_CodeMode_AST', 15.965, 'Operator_Vault_Localhost_8097', 'S50..S63', 0.9520, 'Auth_Gated_Operator_Passkey', 1),
(5, 'Visiting_LLM_Agent_Gateway', 'Safe_LLM_Gateway_Converse_And_Crystallize', 15.965, 'ZeroTrust_Sandbox_And_Expansion_Vault', 'S00..S79', 0.9545, 'MCP_OpenAI_v1_A2A_OpenAPI31', 0),
(6, 'Google_Antigravity_Gemini4_Argon', 'Multi_Agent_Teamwork_And_5W1H_Connectome_28160', 15.965, 'TriSilicon_And_Cloudflare_10Tables', 'S00..S79', 0.9548, 'Antigravity_ServerUrl_MCP_8097', 1);

INSERT OR REPLACE INTO v43_antigravity_agent_roster (agent_id, agent_name, agent_file, model_tier, domain_scope, bound_npage_neurons, bound_sectors, mcp_server_url, status) VALUES
(1, 'l0-rust-lean4-architect', '.agents/agents/01-l0-rust-lean4-architect.md', 'Gemini-4-Argon (pro)', '01_l0_rust + v31_swarm.exe + 432/432 Lean 4 QED', 42240, 'S00..S47', 'http://127.0.0.1:8097/api/v1/mcp/rpc', 'ACTIVE_READY'),
(2, '5w1h-connectome-router', '.agents/agents/02-5w1h-connectome-router.md', 'Gemini-4-Argon (pro)', 'Tool 45/65/70 5W1H Harness + 21,120 Core + 21,120 Expansion Neurons', 42240, 'S00..S79', 'http://127.0.0.1:8097/api/v1/mcp/rpc', 'ACTIVE_READY'),
(3, 'hud-cockpit-guardian', '.agents/agents/03-hud-cockpit-guardian.md', 'Gemini-4-Argon (pro)', '05_hud_cockpit (15 Cards + 5-Node Ribbon + 16x130 Heatmap + 24D BPE + T73..T89)', 42240, 'S00..S79', 'http://127.0.0.1:8097/api/v1/mcp/rpc', 'ACTIVE_READY'),
(4, 'dual-pixel-edge-ndk', '.agents/agents/04-dual-pixel-edge-ndk.md', 'Gemini-4-Argon (pro)', '04_edge_silicon Pixel 10 (58170DLCR0004V) & Pixel 8 (3A121FDJH00BW5) SH4Z v4700', 42240, 'S48..S79', 'http://127.0.0.1:8097/api/v1/mcp/rpc', 'ACTIVE_READY'),
(5, 'cloudflare-d1-tunnel-ops', '.agents/agents/05-cloudflare-d1-tunnel-ops.md', 'Gemini-4-Argon (pro)', 'act-omega-net.dev Tunnel + Remote 5GB D1 (10 Tables) + E:/G: Vaults', 42240, 'S00..S79', 'https://mcp.act-omega-net.dev/mcp', 'ACTIVE_READY'),
(6, 'muse-zero-mock-auditor', '.agents/agents/06-muse-zero-mock-auditor.md', 'Gemini-4-Argon (pro)', 'Pre-Commit Zero-Mock Gate + SHA-256 Audit + GitHub 3-Branch Release', 42240, 'S00..S79', 'http://127.0.0.1:8097/api/v1/mcp/rpc', 'ACTIVE_READY'),
(7, 'periphery-widgets-mini-hud-sync', '.agents/agents/07-periphery-widgets-mini-hud-sync.md', 'Gemini-4-Argon (pro)', 'Win11 Native Tray HUD + Android Widget/Wallpaper + PWA sw.js + Cloudflare Edge + First-Pass Periphery Sync', 42240, 'S00..S79', 'http://127.0.0.1:8097/api/v1/mcp/rpc', 'ACTIVE_READY');

INSERT OR REPLACE INTO v44_visiting_llm_agent_ledger (visit_id, agent_id, protocol, dominant_domain, token_count, compression_ratio, mapped_sector, mapped_chair44_col, crystallized_neuron_id, crystallized_shard_id, attestation_sig, prompt_excerpt, recorded_at_ms) VALUES
(1, 'Claude-3.7-Sonnet-MCP', 'MCP-2026-07-28', 'D13:Moral_Ethics_Deontology_Virtue', 21, 6.48, 15, 512, 22567, 22568, '0xA4F93329E84400C1', 'evaluate moral ethics virtue ethics eudaimonia deontological duty and epistemic humility across 28160 dendritic neurons', 1761110400300),
(2, 'OpenAI-GPT-4o-Client', 'OpenAI-/v1/chat/completions', 'D14:Law_Jurisprudence_Constitutional', 19, 6.12, 29, 548, 24112, 24113, '0xB8E23329E84400C2', 'synthesize first principles dialectic synthesis constitutional jurisprudence and pareto optimal equilibrium', 1761110400400),
(3, 'Gemini-4-Argon-A2A', 'Google-A2A-Mesh-1.0', 'D9:Psychology_Cognitive_Affective', 18, 6.35, 52, 590, 25960, 25961, '0xC1D43329E84400C3', 'cognitive appraisal emotional regulation working memory jungian individuation and interoceptive awareness', 1761110400500);

INSERT OR REPLACE INTO v44_multiturn_working_memory_ring (turn_id, dominant_domain, token_count, mapped_sector, mapped_chair44_col, mapped_neuron_id, prompt_text, synthesis_excerpt, recorded_at_ms) VALUES
(1, 'D14:Law_Jurisprudence_Constitutional', 15, 29, 242, 10663, 'constitutional jurisprudence and pareto optimal equilibrium', 'D14 LAW, JURISPRUDENCE & CONSTITUTIONAL GOVERNANCE: Grounded in constitutional sovereignty, due process, and stare decisis precedent across Sector S29 (Neuron N10663/28159).', 1761110400600),
(2, 'D15:Economics_GameTheory_MechanismDesign', 16, 65, 637, 28044, 'mechanism design incentive compatibility and sovereign treaty order', 'D15 ECONOMICS, GAME THEORY & MECHANISM DESIGN: Through VCG incentive compatibility, Coasean bargaining, and Shapley value attribution, resource allocation converges to a Pareto-optimal Nash equilibrium.', 1761110400700);

SELECT snapshot_id, schema_version, total_neurons, total_bytes, active_synapses FROM npage_tier_snapshots ORDER BY snapshot_id DESC LIMIT 2;
SELECT visit_id, agent_id, protocol, dominant_domain, crystallized_neuron_id, crystallized_shard_id FROM v44_visiting_llm_agent_ledger ORDER BY visit_id ASC;
SELECT turn_id, dominant_domain, mapped_sector, mapped_neuron_id FROM v44_multiturn_working_memory_ring ORDER BY turn_id ASC;
