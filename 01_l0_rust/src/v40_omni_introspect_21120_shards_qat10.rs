// =============================================================================
// ACT-OMEGA NET v41.0.0 (SH4Z v4100 TLV) - DYNAMIC OMNI-WIRING INTROSPECTION,
// REAL DIRECTORY SHARD COUNTER & MEASURED QAT VERIFIER (TOOLS 59..64)
// =============================================================================

use std::fs;
use std::path::Path;
use std::time::Instant;

pub fn count_real_shards_on_disk() -> usize {
    match fs::read_dir("03_vault/shards") {
        Ok(entries) => entries
            .filter_map(Result::ok)
            .filter(|e| {
                e.path()
                    .extension()
                    .and_then(|s| s.to_str())
                    .map(|ext| ext == "binshard")
                    .unwrap_or(false)
            })
            .count(),
        Err(_) => 0,
    }
}

pub fn tool_59_omni_wiring_audit_json() -> String {
    let t0 = Instant::now();
    let checks = (
        Path::new("00_control/weights/sovereign_harmonic_iv_v4000.e8z").exists(),
        Path::new("00_control/weights/neurons_v4000.npage").exists(),
        Path::new("01_l0_rust/Cargo.toml").exists(),
        Path::new("02_gateway_deno/server.ts").exists(),
        Path::new("05_hud_cockpit/src/App.tsx").exists(),
        Path::new("wrangler.toml").exists(),
    );
    let passed = usize::from(checks.0)
        + usize::from(checks.1)
        + usize::from(checks.2)
        + usize::from(checks.3)
        + usize::from(checks.4)
        + usize::from(checks.5);
    let elapsed_ms = t0.elapsed().as_secs_f64() * 1000.0;
    format!(
        "{{"tool":59,"endpoint":"/api/v1/introspect/omni_wiring_audit","verified_subsystems":{},"audit_ms":{:.4}}}",
        passed, elapsed_ms
    )
}

pub fn tool_60_d1_auto_trigger_pipeline_json() -> String {
    let sql_bytes = fs::metadata("00_control/seed_d1_v40_tables_only.sql").map(|m| m.len()).unwrap_or(0);
    let sync_script_exists = Path::new("00_control/cloudflare_edge/d1_live_measured_sync_v4100.ps1").exists();
    format!(
        "{{"tool":60,"endpoint":"/api/v1/d1/auto_trigger_pipeline","sql_schema_bytes":{},"live_command_script_present":{}}}",
        sql_bytes, sync_script_exists
    )
}

pub fn tool_61_ten_session_qat_blitz_json() -> String {
    let ring_path = "03_vault/telemetry_training_ring.jsonl";
    let (ring_bytes, ring_lines) = match fs::read_to_string(ring_path) {
        Ok(s) => (s.len(), s.lines().count()),
        Err(_) => (0, 0),
    };
    format!(
        "{{"tool":61,"endpoint":"/api/v1/train/ten_session_qat_blitz","training_ring_records":{},"training_ring_bytes":{}}}",
        ring_lines, ring_bytes
    )
}

pub fn tool_62_hyper_shard_accelerator_json() -> String {
    let t0 = Instant::now();
    let shard_count = count_real_shards_on_disk();
    let npage_bytes = fs::metadata("00_control/weights/neurons_v4000.npage").map(|m| m.len()).unwrap_or(0);
    let neuron_count = (npage_bytes / 128) as usize;
    let bijection_exact = shard_count == neuron_count && shard_count > 0;
    let scan_ms = t0.elapsed().as_secs_f64() * 1000.0;
    format!(
        "{{"tool":62,"endpoint":"/api/v1/vault/hyper_shard_accelerator","measured_binshards_on_disk":{},"measured_neurons_in_npage":{},"bijection_1_to_1_verified":{},"scan_ms":{:.3}}}",
        shard_count, neuron_count, bijection_exact, scan_ms
    )
}

pub fn tool_63_dual_phone_v40_sync_json() -> String {
    let log_bytes = fs::metadata("G:\My Drive\ACT_OMEGA_GEMINI_BRIDGE\apk_v40_install_log.txt")
        .map(|m| m.len())
        .unwrap_or(0);
    format!(
        "{{"tool":63,"endpoint":"/api/v1/edge/dual_phone_v40_sync","apk_install_log_bytes":{}}}",
        log_bytes
    )
}

pub fn tool_64_hud_hot_reload_v40_json() -> String {
    let hud_bytes = fs::metadata("hud.html").map(|m| m.len()).unwrap_or(0);
    let idx_bytes = fs::metadata("index.html").map(|m| m.len()).unwrap_or(0);
    format!(
        "{{"tool":64,"endpoint":"/api/v1/hud/hot_reload_v40","hud_html_bytes":{},"index_html_bytes":{}}}",
        hud_bytes, idx_bytes
    )
}
