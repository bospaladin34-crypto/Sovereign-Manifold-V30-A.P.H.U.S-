-- ACT-Omega Net v41.0.0 Zero-Mock Cryptographic SHA-256 D1 Checkpoint (Muse Audit #5 Remediated)
CREATE TABLE IF NOT EXISTS v41_measured_sha256_audit (
    artifact_name TEXT PRIMARY KEY,
    byte_length INTEGER NOT NULL,
    sha256_digest TEXT NOT NULL,
    measured_shards INTEGER NOT NULL,
    measured_neurons INTEGER NOT NULL,
    verified_at TEXT DEFAULT CURRENT_TIMESTAMP
);

INSERT OR REPLACE INTO v41_measured_sha256_audit (artifact_name, byte_length, sha256_digest, measured_shards, measured_neurons) VALUES
('sovereign_harmonic_iv_v4000.e8z', 133120, 'c383b1b7d00e6ce8cef22593536aea2d66523d53360c3552a64970a61e394b23', 21120, 21120),
('neurons_v4000.npage', 2703360, 'aee7711086a07bb6ddebc9e347ed4d68d3a38b57d57b08f9089d22345fa07d6d', 21120, 21120),
('SovereignManifoldTheorems.lean', 50903, 'd7955e7e987c897c574add613bf72d79969f23a626d178c865d3d853e02788da', 21120, 21120);
