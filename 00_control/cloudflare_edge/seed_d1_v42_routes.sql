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

INSERT OR REPLACE INTO v42_5w1h_distributed_routes (route_id, who_caller, what_workload, when_clock_hz, where_silicon_node, where_sector_span, why_metabolic_atp, how_transport, operator_vault_gated) VALUES
(1, 'Host_LOQ15_Operator', 'L0_Tensor_FNO_And_10Session_QAT', 15.965, 'Anchor1_Lenovo_LOQ15_RTX3050', 'S00..S47', 0.9482, 'ZeroCopy_Mmap_Ring', 0),
(2, 'Edge1_Pixel10_58170DLCR0004V', 'Edge_24D_Sensor_Stiefel_And_MicroQAT', 15.965, 'Edge1_Google_Pixel10_TensorG5', 'S48..S63', 0.9490, 'ADB_Reverse_TCP_8097', 0),
(3, 'Edge2_Pixel8_3A121FDJH00BW5', 'Speculative_Drafter_And_L2_Verify', 15.965, 'Edge2_Google_Pixel8_P8APEX', 'S64..S79', 0.9510, 'ADB_Reverse_TCP_8097', 0),
(4, 'Symbiotic_IDE_Goose_Zed_Cline', 'Embedded_Operator_Vault_CodeMode_AST', 15.965, 'Operator_Vault_Localhost_8080', 'S50..S63', 0.9485, 'Auth_Gated_Operator_Passkey', 1),
(5, 'Gemini_Task_Mode_Bridge', 'Bidirectional_GDrive_And_D1_Sync', 15.965, 'Cloudflare_D1_And_G_My_Drive', 'S00..S79', 0.9495, 'GDrive_Desktop_And_Wrangler_D1', 1);
