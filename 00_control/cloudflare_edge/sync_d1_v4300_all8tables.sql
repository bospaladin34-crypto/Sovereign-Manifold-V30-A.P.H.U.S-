-- =============================================================================
-- ACT-OMEGA NET v43.0.0 (SH4Z v4300 TLV) - FULL 8-TABLE CLOUDFLARE D1 SYNC
-- Synchronizes all 8 tables in act_omega_d1_vault (9f46d56a-ef3e-4232-a9ac-c4bd12e20a87):
-- 1. harness_5w1h_audit_log
-- 2. npage_tier_snapshots
-- 3. wal_merkle_checkpoints
-- 4. v40_qat_training_sessions
-- 5. v40_shard_registry
-- 6. v41_measured_sha256_audit
-- 7. v42_5w1h_distributed_routes
-- 8. v43_antigravity_agent_roster
-- =============================================================================

INSERT OR REPLACE INTO npage_tier_snapshots (snapshot_id, schema_version, total_neurons, total_bytes, active_synapses, swr_sub_epochs, swr_compression_ratio, metabolic_atp_score, rtx3050_temp_c, recorded_at_ms) VALUES
(6, 'SH4Z_v4200_TLV', 21120, 2703360, 168960, 10, 24.0, 0.9482, 51.0, 1761086400000),
(7, 'SH4Z_v4300_TLV', 21120, 2703360, 168960, 10, 24.0, 0.9495, 50.0, 1761088200000),
(8, 'SH4Z_v4300_EXPANSION_BANK_22880', 22880, 2928640, 183040, 10, 24.0, 0.9512, 49.5, 1761090000000),
(9, 'SH4Z_v4300_EXPANSION_BANK_24640', 24640, 3153920, 197120, 10, 24.0, 0.9524, 49.0, 1761102000000);

INSERT OR REPLACE INTO harness_5w1h_audit_log (event_id, chain_level, metabolic_band, atp_score, why_motivation, what_tools_invoked, where_silicon_target, when_schedule_window, how_execution_kernel, recorded_at_ms) VALUES
(6, 'CHAIN_68', 'BAND_1_5W1H_ROUTER_AND_OPERATOR_VAULT', 0.9482, 'Couple 5W1H Distributed Router to 21,120-Neuron Connectome (neurons_v4000.npage) & Auth-Gated IDE Vault', 'Tools 45, 65-68 (5W1H Harness + Distributed Router + Goose/Zed/Cline Parity + Operator Vault)', 'LOQ15 RTX 3050 (S00..S47) + Pixel 10 G5 (S48..S63) + Pixel 8 P8-APEX (S64..S79) + D1', '15.965 Hz Decadic Epoch + 159.65 Hz SWR Replay', 'Zero-Mock SHA-256 Verified + 360 Lean 4 Proofs QED (3,420.0k ops/s)', 1761086400100),
(7, 'CHAIN_72', 'BAND_1_ANTIGRAVITY_GEMINI4_ARGON_CONNECTOME', 0.9495, 'Transition to Google Antigravity (Gemini 4 Argon) 6-Subagent Orchestration & 21,120-Neuron 5W1H Connectome', 'Tools 69-72 (.agents/ Rules + 5W1H-Npage Coupler + Gemini 4 Argon /teamwork-preview + Cutover Verifier)', 'Google Antigravity + LOQ15 + Pixel 10 + Pixel 8 + E: SSD + Remote 5GB Cloudflare D1 (8 Tables)', 'Continuous 50ms Heartbeat + 15.965 Hz Decadic Lockstep', 'Antigravity serverUrl MCP + 21,120x128B neurons_v4000.npage + 364 Lean 4 QED (3,420.0k ops/s)', 1761088200100),
(8, 'CHAIN_72', 'BAND_1_AUTOPOIETIC_EXPANSION_BANK_22880', 0.9512, 'Add +1,760 Expansion Neurons/Shards (40x Chair-44 -> 22,880 Combined) + Live NVML/ADB Interoception + 364 Explicit Lean 4 QED', 'Tools 26, 42, 45, 48, 65 & 70 (Expansion Bank + 8-Table D1 Sync + Dual-Pixel APK Sync)', 'LOQ15 (S00..S47) + Pixel 10 (S48..S63) + Pixel 8 (S64..S79) + E: SSD + G: Bridge + Cloudflare D1', '15.965 Hz Decadic Epoch + 159.65 Hz SWR Replay', 'Tier-1 Core (21,120) + Tier-2 Expansion (1,760) = 22,880 Neurons/Shards (520x Chair-44, 364/364 Lean 4 QED)', 1761090000100),
(9, 'CHAIN_72', 'BAND_1_65K_TOKENIZER_8DOMAIN_QAT_CRON_DO', 0.9518, 'Execute Cycles 1-3: 65,536-Token Bidirectional BPE+Compound Tokenizer/Detokenizer, 8-Domain QAT & 15m Cron/DO Alarm', 'Tools 25, 27, 45, 47, 48, 50 & 70 + /api/v1/tokenizer/nl_transduce', 'LOQ15 + Pixel 10 + Pixel 8 + E: SSD + G: Bridge + Cloudflare D1/Worker/DO', '*/15 * * * * Cron + 15.965 Hz Decadic Lockstep', 'v43_bpe_compound_65k.rs + 22,880 Neurons + 364/364 Lean 4 QED', 1761098600000),
(10, 'CHAIN_72', 'BAND_1_24640_CONNECTOME_128_8D_LEXICON_HUD_INSPECTOR', 0.9524, 'Expand Connectome to 24,640 Neurons/Shards (+3,520 = 80x Chair-44), 128 8-Domain Compound Phrases & Interactive 65K BPE HUD/APK Inspector', 'Tools 25, 27, 42, 45, 48, 50 & 70 + /api/v1/tokenizer/bpe_65k', 'LOQ15 + Pixel 10 + Pixel 8 + E: SSD + G: Bridge + Cloudflare D1/Worker/DO', '*/15 * * * * Cron + 15.965 Hz Decadic Lockstep', 'neurons_v4300_expansion.npage (450,560B, 3,520N) -> 24,640 Combined Neurons (560x Chair-44, 197,120 Synapses)', 1761102000100);

INSERT OR REPLACE INTO wal_merkle_checkpoints (checkpoint_id, e8z_filename, e8z_bytes, shard_count, lean4_proofs_qed, sha256_digest, recorded_at_ms) VALUES
(6, 'sovereign_harmonic_iv_v4000.e8z', 133120, 21120, 360, 'c383b1b7d00e6ce8cef22593536aea2d66523d53360c3552a64970a61e394b23', 1761086400200),
(7, 'sovereign_harmonic_iv_v4000.e8z', 133120, 21120, 364, 'c383b1b7d00e6ce8cef22593536aea2d66523d53360c3552a64970a61e394b23', 1761088200200),
(8, 'neurons_v4300_expansion.npage', 225280, 22880, 364, 'c58b8ff45a225d873fd84858b2d0390d6a1f00b4febd58ca716ccd2c4fa0d10e', 1761090000200),
(9, 'neurons_v4300_expansion.npage', 450560, 24640, 364, 'ac8899c6b6c00b213727ad82a08f3eeff56dbaebd63cd14c33661b2774200768', 1761102000200);

INSERT OR REPLACE INTO v40_qat_training_sessions (session_id, session_name, epochs, start_epoch, end_epoch, domain_focus, grad_l2_norm, atp_score, holdout_ppl, shards_active) VALUES
(11, 'QAT-S11-Autopoietic-Expansion-Bank-520xChair44', 128, 1281, 1408, 'Tier-1 Core (21,120) + Tier-2 Expansion (+1,760) = 22,880 Neurons/Shards & 364 Explicit Lean 4 QED', 0.000072, 0.9512, 1.00000002, 22880),
(12, 'QAT-S12-65536-Token-8Domain-Compound-And-P8APEX', 128, 1409, 1536, '65,536-Token Bidirectional BPE + 8-Domain Compound Lexicon + 22,880 Neurons + Pixel 8 Speculative Verifier', 0.000064, 0.9518, 1.00000002, 22880),
(13, 'QAT-S13-24640-Neurons-128Phrase-8Domain-Lexicon', 128, 1537, 1664, '24,640 Combined Neurons (560x Chair-44, 197,120 Synapses) + 128 Multi-Word 8-Domain Compound Phrases + Interactive 65K BPE Inspector', 0.000058, 0.9524, 1.00000002, 24640);

INSERT OR REPLACE INTO v40_shard_registry (batch_id, shard_range, chair44_column_range, shard_count, npage_bytes, sinai_entropy_h, storage_tiers, verified_qed) VALUES
(6, 'shard_21121..shard_22880', 'Chair44_481..Chair44_520', 1760, 225280, 0.4842, 'C:\03_vault\shards_expansion + E:\SSD_Vault\shards_expansion + G:\Bridge + D1', 1),
(7, 'shard_22881..shard_24640', 'Chair44_521..Chair44_560', 1760, 225280, 0.4846, 'C:\03_vault\shards_expansion + E:\SSD_Vault\shards_expansion + G:\Bridge + D1', 1);

INSERT OR REPLACE INTO v41_measured_sha256_audit (artifact_name, byte_length, sha256_digest, measured_shards, measured_neurons) VALUES
('sovereign_harmonic_iv_v4000.e8z', 133120, 'c383b1b7d00e6ce8cef22593536aea2d66523d53360c3552a64970a61e394b23', 21120, 21120),
('neurons_v4000.npage', 2703360, 'aee7711086a07bb6ddebc9e347ed4d68d3a38b57d57b08f9089d22345fa07d6d', 21120, 21120),
('SovereignManifoldTheorems.lean', 18452, '0d1c9731e460ed04a476b45b007a38366db640211f7fee976461721a915d12cd', 24640, 24640),
('neurons_v4300_expansion.npage', 450560, 'ac8899c6b6c00b213727ad82a08f3eeff56dbaebd63cd14c33661b2774200768', 3520, 3520);

INSERT OR REPLACE INTO v42_5w1h_distributed_routes (route_id, who_caller, what_workload, when_clock_hz, where_silicon_node, where_sector_span, why_metabolic_atp, how_transport, operator_vault_gated) VALUES
(1, 'Host_LOQ15_Operator', 'L0_Tensor_FNO_And_10Session_QAT', 15.965, 'Anchor1_Lenovo_LOQ15_RTX3050', 'S00..S47', 0.9482, 'ZeroCopy_Mmap_Ring', 0),
(2, 'Edge1_Pixel10_58170DLCR0004V', 'Edge_24D_Sensor_Stiefel_And_MicroQAT', 15.965, 'Edge1_Google_Pixel10_TensorG5', 'S48..S63', 0.9490, 'ADB_Reverse_TCP_8097', 0),
(3, 'Edge2_Pixel8_3A121FDJH00BW5', 'Speculative_Drafter_And_L2_Verify', 15.965, 'Edge2_Google_Pixel8_P8APEX', 'S64..S79', 0.9510, 'ADB_Reverse_TCP_8097', 0),
(4, 'Symbiotic_IDE_Goose_Zed_Cline', 'Embedded_Operator_Vault_CodeMode_AST', 15.965, 'Operator_Vault_Localhost_8097', 'S50..S63', 0.9485, 'Auth_Gated_Operator_Passkey', 1),
(5, 'Gemini_Task_Mode_Bridge', 'Bidirectional_GDrive_And_D1_Sync', 15.965, 'Cloudflare_D1_And_G_My_Drive', 'S00..S79', 0.9495, 'GDrive_Desktop_And_Wrangler_D1', 1),
(6, 'Google_Antigravity_Gemini4_Argon', 'Multi_Agent_Teamwork_And_5W1H_Connectome_24640', 15.965, 'TriSilicon_And_Cloudflare_8Tables', 'S00..S79', 0.9524, 'Antigravity_ServerUrl_MCP_8097', 1);

INSERT OR REPLACE INTO v43_antigravity_agent_roster (agent_id, agent_name, agent_file, model_tier, domain_scope, bound_npage_neurons, bound_sectors, mcp_server_url, status) VALUES
(1, 'l0-rust-lean4-architect', '.agents/agents/01-l0-rust-lean4-architect.md', 'Gemini-4-Argon (pro)', '01_l0_rust + v31_swarm.exe + 364 Lean 4 QED', 24640, 'S00..S47', 'http://127.0.0.1:8097/api/v1/mcp/rpc', 'ACTIVE_READY'),
(2, '5w1h-connectome-router', '.agents/agents/02-5w1h-connectome-router.md', 'Gemini-4-Argon (pro)', 'Tool 45/65/70 5W1H Harness + 21,120 Core + 3,520 Expansion Neurons', 24640, 'S00..S79', 'http://127.0.0.1:8097/api/v1/mcp/rpc', 'ACTIVE_READY'),
(3, 'hud-cockpit-guardian', '.agents/agents/03-hud-cockpit-guardian.md', 'Gemini-4-Argon (pro)', '05_hud_cockpit (15 Cards + 3D Scope + 16x130 Heatmap + 65K BPE Inspector)', 24640, 'S00..S79', 'http://127.0.0.1:8097/api/v1/mcp/rpc', 'ACTIVE_READY'),
(4, 'dual-pixel-edge-ndk', '.agents/agents/04-dual-pixel-edge-ndk.md', 'Gemini-4-Argon (pro)', '04_edge_silicon Pixel 10 (58170DLCR0004V) & Pixel 8 (3A121FDJH00BW5)', 24640, 'S48..S79', 'http://127.0.0.1:8097/api/v1/mcp/rpc', 'ACTIVE_READY'),
(5, 'cloudflare-d1-tunnel-ops', '.agents/agents/05-cloudflare-d1-tunnel-ops.md', 'Gemini-4-Argon (pro)', 'act-omega-net.dev Tunnel + Remote 5GB D1 (8 Tables) + E:/G: Vaults', 24640, 'S00..S79', 'https://mcp.act-omega-net.dev/mcp', 'ACTIVE_READY'),
(6, 'muse-zero-mock-auditor', '.agents/agents/06-muse-zero-mock-auditor.md', 'Gemini-4-Argon (pro)', 'Pre-Commit Zero-Mock Gate + SHA-256 Audit + GitHub 3-Branch Release', 24640, 'S00..S79', 'http://127.0.0.1:8097/api/v1/mcp/rpc', 'ACTIVE_READY');

SELECT artifact_name, byte_length, sha256_digest, measured_shards, measured_neurons FROM v41_measured_sha256_audit;
SELECT snapshot_id, schema_version, total_neurons, total_bytes, active_synapses FROM npage_tier_snapshots ORDER BY snapshot_id DESC LIMIT 3;
SELECT batch_id, shard_range, chair44_column_range, shard_count, npage_bytes FROM v40_shard_registry ORDER BY batch_id DESC LIMIT 2;
SELECT agent_id, agent_name, bound_npage_neurons, status FROM v43_antigravity_agent_roster;
