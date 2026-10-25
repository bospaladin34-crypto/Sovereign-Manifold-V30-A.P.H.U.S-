INSERT OR REPLACE INTO npage_tier_snapshots (snapshot_id, schema_version, total_neurons, total_bytes, active_synapses, swr_sub_epochs, swr_compression_ratio, metabolic_atp_score, rtx3050_temp_c, recorded_at_ms) VALUES
(11, 'SH4Z_v4700_CONNECTOME_42240_NEURONS', 42240, 5406720, 337920, 10, 24.0, 0.9554, 49.0, 1761248400000),
(12, 'SH4Z_v4900_CHAIN100_42240_NEURONS', 42240, 5406720, 337920, 10, 24.0, 0.9562, 51.0, 1792919694142);

INSERT OR REPLACE INTO v41_measured_sha256_audit (artifact_name, byte_length, sha256_digest, measured_shards, measured_neurons) VALUES
('sovereign_harmonic_iv_v4000.e8z', 133120, 'e32cbb03d8df1a343969a0a41d101e90c81930656051160f59492f8bb4adbdb6', 21120, 21120),
('neurons_v4600_42240.npage', 5406720, 'eb969416a8cd2ad992bb333c8a64a5c827c0497db586615af15310370bf6e0b6', 42240, 42240),
('neurons_v4400_p8_shm.npage', 5406720, 'eb969416a8cd2ad992bb333c8a64a5c827c0497db586615af15310370bf6e0b6', 42240, 42240),
('SovereignManifoldTheorems.lean', 85271, 'eb5717e19b061cd0cc7ec78f21b954a833c90c134d958d96abbd4580434a1f1f', 42240, 42240);
