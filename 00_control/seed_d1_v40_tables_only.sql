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

INSERT OR REPLACE INTO v40_qat_training_sessions (session_id, session_name, epochs, start_epoch, end_epoch, domain_focus, grad_l2_norm, atp_score, holdout_ppl, shards_active) VALUES
(1, 'QAT-S01-Decadic-10Laplacian', 128, 1, 128, '15.965 Hz Decadic Epoch & 10-Laplacian Biharmonic Stiffness', 0.000182, 0.9210, 4.658958, 13200),
(2, 'QAT-S02-Stiefel-Theodorus-Phones', 128, 129, 256, 'Per-Sensor Stiefel St(16,80) & Theodorus sqrt(n) Dual-Phone Coupling', 0.000168, 0.9265, 4.542180, 14080),
(3, 'QAT-S03-Leech-Sierpinski-158b', 128, 257, 384, '24D Leech Lattice Lambda_24 & 1.58-Bit Sierpinski Ternary Quantizer', 0.000154, 0.9312, 4.431050, 14960),
(4, 'QAT-S04-Dendritic-Pyramidal-SWR', 128, 385, 512, '3-Compartment Dendritic Pyramidal Neurons & 159.65 Hz SWR Replay', 0.000141, 0.9358, 4.328410, 15840),
(5, 'QAT-S05-Skyrmion-Fermi-Amygdala', 128, 513, 640, 'Innsbruck Fractional Fermi Sea, Skyrmion Hall & Amygdala Kerr Recoil', 0.000129, 0.9394, 4.219640, 16720),
(6, 'QAT-S06-Metabolic-5W1H-Welch', 128, 641, 768, '4-Band 5W1H Metabolic ATP Load-Shift & Welch PSD / Khys Mnemosyne', 0.000118, 0.9421, 4.148220, 17600),
(7, 'QAT-S07-CodeMode-MCP-Delta', 128, 769, 896, 'CodeMode Meta-Tool (<1,000 Tok), Roots Guard & Atomic GZip Delta AST', 0.000107, 0.9445, 4.095110, 18480),
(8, 'QAT-S08-AutoLearn-BiTemporal-D1', 128, 897, 1024, 'Symbiotic AutoLearn Bi-Temporal Memory Bank & 5GB Cloudflare D1 Sync', 0.000096, 0.9462, 4.051840, 19360),
(9, 'QAT-S09-A2A-Symbiotic-IDE-Swarm', 128, 1025, 1152, 'A2A v1.0 Multi-Agent Coding Swarm (Zed + VSCodium/Cline + Goose)', 0.000088, 0.9474, 4.028910, 20240),
(10, 'QAT-S10-OmniMesh-80Sector-u128', 128, 1153, 1280, 'Full 64-Tool (CHAIN 64) 80-Sector u128 Cross-Domain Synthesis', 0.000079, 0.9482, 4.012657, 21120);

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

INSERT OR REPLACE INTO v40_shard_registry (batch_id, shard_range, chair44_column_range, shard_count, npage_bytes, sinai_entropy_h, storage_tiers, verified_qed) VALUES
(1, 'shard_00001..shard_05500', 'Chair44_001..Chair44_125', 5500, 704000, 0.4812, 'C:\03_vault + E:\SSD_Vault + D1', 1),
(2, 'shard_05501..shard_10560', 'Chair44_126..Chair44_240', 5060, 647680, 0.4820, 'C:\03_vault + E:\SSD_Vault + D1', 1),
(3, 'shard_10561..shard_12320', 'Chair44_241..Chair44_280', 1760, 225280, 0.4825, 'C:\03_vault + E:\SSD_Vault + D1', 1),
(4, 'shard_12321..shard_16720', 'Chair44_281..Chair44_380', 4400, 563200, 0.4831, 'C:\03_vault + E:\SSD_Vault + D1', 1),
(5, 'shard_16721..shard_21120', 'Chair44_381..Chair44_480', 4400, 563200, 0.4838, 'C:\03_vault + E:\SSD_Vault + D1', 1);
