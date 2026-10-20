-- ACT-Omega Net v37.0.0 Cloudflare D1 Serverless SQLite Schema (act_omega_d1_vault)
-- Account ID: a37cf8ab07e7c5f886c302be3f098744 -- Free Tier: 5 GB Storage, 5M Reads/Day, 100k Writes/Day

CREATE TABLE IF NOT EXISTS npage_tier_snapshots (
    snapshot_id INTEGER PRIMARY KEY AUTOINCREMENT,
    schema_version TEXT NOT NULL DEFAULT 'SH4Z_v3700_TLV',
    total_neurons INTEGER NOT NULL DEFAULT 9680,
    total_bytes INTEGER NOT NULL DEFAULT 1239040,
    active_synapses INTEGER NOT NULL DEFAULT 77440,
    swr_sub_epochs INTEGER NOT NULL DEFAULT 8,
    swr_compression_ratio REAL NOT NULL DEFAULT 20.0,
    metabolic_atp_score REAL NOT NULL,
    rtx3050_temp_c REAL NOT NULL,
    recorded_at_ms INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS harness_5w1h_audit_log (
    event_id INTEGER PRIMARY KEY AUTOINCREMENT,
    chain_level TEXT NOT NULL DEFAULT 'CHAIN_48',
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
    e8z_filename TEXT NOT NULL DEFAULT 'sovereign_harmonic_v3700.e8z',
    e8z_bytes INTEGER NOT NULL DEFAULT 102400,
    shard_count INTEGER NOT NULL DEFAULT 9680,
    lean4_proofs_qed INTEGER NOT NULL DEFAULT 276,
    sha256_digest TEXT NOT NULL,
    recorded_at_ms INTEGER NOT NULL
);
