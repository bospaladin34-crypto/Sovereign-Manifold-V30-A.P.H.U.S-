INSERT OR REPLACE INTO npage_tier_snapshots (snapshot_id, schema_version, total_neurons, total_bytes, active_synapses, swr_sub_epochs, swr_compression_ratio, metabolic_atp_score, rtx3050_temp_c, recorded_at_ms) VALUES
(11, 'SH4Z_v4700_CONNECTOME_42240_NEURONS', 42240, 5406720, 337920, 10, 24.0, 0.9554, 49.0, 1761248400000),
(12, 'SH4Z_v4900_CHAIN100_42240_NEURONS', 42240, 5406720, 337920, 10, 24.0, 0.9562, 51.0, 1792919694142),
(13, 'SH4Z_v5000_CHAIN135_63360_NEURONS', 63360, 8110080, 1013760, 10, 24.0, 0.9648, 48.0, 1793218000000);

INSERT OR REPLACE INTO v41_measured_sha256_audit (artifact_name, byte_length, sha256_digest, measured_shards, measured_neurons) VALUES
('sovereign_harmonic_iv_v5000.e8z', 133120, 'a2ca34144fc3051f503d6b615e35b4e0074b260a04406c6d3b7377c4ef4e4ae5', 63360, 63360),
('neurons_v5000_63360.npage', 8110080, '91c42afd2adc4b55de20edb593ff95a9d831f7991db13c832f87a6f3ac4c7ef3', 63360, 63360),
('neurons_v4600_42240.npage', 5406720, 'f6ced1facaa8285fb06f36a3e0a4bae0d5e606e7d6d178cf20036a3a702c934f', 42240, 42240),
('neurons_v4000.npage', 2703360, '7b4862645aa4c0b4bbd4755556e58b76b9c17310de3f15ea88f737c4d34e11d4', 21120, 21120),
('SovereignManifoldTheorems.lean', 128309, 'c59808ec903c37f8ad7e68678284c99581bf477bb12ce76000d5ce882e300c87', 63360, 63360);

INSERT OR REPLACE INTO v43_antigravity_agent_roster (agent_id, agent_name, agent_file, model_tier, domain_scope, bound_npage_neurons, bound_sectors, mcp_server_url, status) VALUES
(1, 'l0-rust-lean4-architect', '.agents/agents/01-l0-rust-lean4-architect.md', 'Gemini-4-Argon (pro)', 'L0 Rust (v31_swarm.rs + v33..v52+), .e8z/.npage weights, Haskell codegen, 564/564 Lean 4 QED', 63360, 'S00..S47', 'http://127.0.0.1:8097/api/v1/mcp/rpc', 'ACTIVE_READY'),
(2, '5w1h-connectome-router', '.agents/agents/02-5w1h-connectome-router.md', 'Gemini-4-Argon (pro)', '5W1H Metabolic Harness, 63,360-Neuron Connectome (neurons_v5000_63360.npage, 8.11MB SHM), 144 Sub-Domains', 63360, 'S00..S79', 'http://127.0.0.1:8097/api/v1/mcp/rpc', 'ACTIVE_READY'),
(3, 'hud-cockpit-guardian', '.agents/agents/03-hud-cockpit-guardian.md', 'Gemini-4-Argon (pro)', 'Host WebGPU React HUD (:5173), 15 Cards, 60 FPS Scopes, 16x130 Heatmap, CHAIN 135 Drawer 4', 63360, 'S00..S47', 'http://127.0.0.1:8097/api/v1/mcp/rpc', 'ACTIVE_READY'),
(4, 'dual-pixel-edge-ndk', '.agents/agents/04-dual-pixel-edge-ndk.md', 'Gemini-4-Argon (pro)', 'Android NDK/JNI C++ & Jetpack Compose across Pixel 10 (58170DLCR0004V) & Pixel 8 (3A121FDJH00BW5)', 63360, 'S48..S79', 'http://127.0.0.1:8097/api/v1/mcp/rpc', 'ACTIVE_READY'),
(5, 'cloudflare-d1-tunnel-ops', '.agents/agents/05-cloudflare-d1-tunnel-ops.md', 'Gemini-4-Argon (pro)', 'Cloudflare Named Tunnel (act-omega-net.dev), SovereignEdgeShadowDO, 10-Table D1 Vault, E:/G: Sync', 63360, 'S00..S79', 'http://127.0.0.1:8097/api/v1/mcp/rpc', 'ACTIVE_READY'),
(6, 'muse-zero-mock-auditor', '.agents/agents/06-muse-zero-mock-auditor.md', 'Gemini-4-Argon (pro)', 'BRUTAL GATEKEEPER #1: Zero-Unmeasured-Data, 100% Byte Coverage, Total Branch Honesty & Secret Auditor', 63360, 'S00..S79', 'http://127.0.0.1:8097/api/v1/mcp/rpc', 'ACTIVE_READY'),
(7, 'periphery-widgets-mini-hud-sync', '.agents/agents/07-periphery-widgets-mini-hud-sync.md', 'Gemini-4-Argon (pro)', 'Win11 Native Tray HUD + Android Widget/Wallpaper + PWA sw.js + Cloudflare Edge + First-Pass Periphery Sync', 63360, 'S00..S79', 'http://127.0.0.1:8097/api/v1/mcp/rpc', 'ACTIVE_READY'),
(8, 'formal-proof-algebraic-gatekeeper', '.agents/agents/08-formal-proof-algebraic-gatekeeper.md', 'Gemini-4-Argon (pro)', 'BRUTAL GATEKEEPER #2: 564/564 Substantive Lean 4 QED + Layer 1.5 Algebraic Haskell + Zero-Bracket L0 Rust', 63360, 'S00..S79', 'http://127.0.0.1:8097/api/v1/mcp/rpc', 'ACTIVE_READY'),
(9, 'autopoietic-bus-duckdb-coordinator', '.agents/agents/09-autopoietic-bus-duckdb-coordinator.md', 'Gemini-4-Argon (pro)', 'BRUTAL GATEKEEPER #3: Sovereign Autopoietic Coordinator Bus + E:/ SSD Write-Back + DuckDB Columnar Engine', 63360, 'S00..S79', 'http://127.0.0.1:8097/api/v1/mcp/rpc', 'ACTIVE_READY'),
(10, 'sovereign-release-shipping-gatekeeper', '.agents/agents/10-sovereign-release-shipping-gatekeeper.md', 'Gemini-4-Argon (pro)', 'BRUTAL GATEKEEPER #4: 6-Layer Lifecycle Audit + OS Pre-Commit Hook + Multi-Target Bundle Parity + 3-Branch Release', 63360, 'S00..S79', 'http://127.0.0.1:8097/api/v1/mcp/rpc', 'ACTIVE_READY');
