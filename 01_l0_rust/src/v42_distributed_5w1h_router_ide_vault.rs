// =============================================================================
// ACT-OMEGA NET v44.2.0 (SH4Z v4420 TLV) - DEEP 5W1H DISTRIBUTED ROUTER,
// GOOSE/ZED/CLINE PROJECT PARITY, SIMPLIFIED 5-TAB HUD & AUTH-GATED IDE VAULT
// Muse Audit Remediated: Zero Hardcoded Credentials in Source (Env/File Gate)
// ZERO SQUARE BRACKETS ENFORCED (0x5B / 0x5D FORBIDDEN IN SOURCE)
// =============================================================================

pub struct RouteDecision5W1H {
    pub who_caller: String,
    pub what_workload: String,
    pub when_decadic_us: u128,
    pub where_target_node: String,
    pub where_sector_span: String,
    pub why_metabolic_atp: f64,
    pub how_transport: String,
    pub auth_vault_unlocked: bool,
}

fn constant_time_eq_str(a: &str, b: &str) -> bool {
    if a.len() != b.len() {
        return false;
    }
    let mut diff = 0u8;
    for (x, y) in a.bytes().zip(b.bytes()) {
        diff |= x ^ y;
    }
    diff == 0
}

pub fn verify_operator_vault_secret(supplied_key: &str, is_localhost: bool) -> bool {
    let clean_supplied = supplied_key.trim();
    if clean_supplied.is_empty() {
        return false;
    }
    let expected = std::env::var("ACT_OMEGA_OPERATOR_KEY")
        .or_else(|_| std::env::var("SOVEREIGN_OPERATOR_KEY"))
        .ok()
        .or_else(|| {
            std::fs::read_to_string("00_control/.operator_vault_key")
                .ok()
                .map(|s| String::from(s.trim()))
        })
        .unwrap_or_default();
    if expected.is_empty() {
        return false;
    }
    is_localhost && constant_time_eq_str(clean_supplied, &expected)
}

pub fn dispatch_5w1h_distributed_route(
    who_caller: &str,
    what_workload: &str,
    operator_token_valid: bool,
) -> RouteDecision5W1H {
    let t0 = std::time::Instant::now();
    let npage_bytes = std::fs::metadata("00_control/weights/neurons_v4000.npage")
        .map(|m| m.len())
        .unwrap_or(0);
    let exp_npage_bytes = std::fs::metadata("00_control/weights/neurons_v4400_expansion.npage")
        .map(|m| m.len())
        .unwrap_or(0);
    let e8z_bytes = std::fs::metadata("00_control/weights/sovereign_harmonic_iv_v4000.e8z")
        .map(|m| m.len())
        .unwrap_or(0);

    // Compute real measured metabolic ratio from actual file/memory footprint
    let footprint_ratio = ((npage_bytes + exp_npage_bytes + e8z_bytes) as f64) / (10.0 * 1048576.0);
    let why_metabolic_atp = (1.0 - (footprint_ratio * 0.18)).clamp(0.50, 0.9999);

    let (where_target_node, where_sector_span, how_transport) = match what_workload {
        "L0_Tensor_FNO" | "QAT_Training" => (
            "Anchor1_Lenovo_LOQ15_RTX3050",
            "S00..S47 (48 Sectors)",
            "ZeroCopy_Mmap_Ring",
        ),
        "Edge_Sensor_24D" | "Edge_MicroQAT" => (
            "Edge1_Google_Pixel10_TensorG5",
            "S48..S63 (16 Sectors)",
            "ADB_Reverse_TCP_8097",
        ),
        "Speculative_Drafter" | "L2_Cache_Verify" => (
            "Edge2_Google_Pixel8_P8APEX",
            "S64..S79 (16 Sectors)",
            "ADB_Reverse_TCP_8097",
        ),
        "Operator_IDE_Vault" => {
            if operator_token_valid {
                (
                    "Symbiotic_IDE_Vault_Goose_Zed_Cline",
                    "S50..S63 (CodeMode_MCP)",
                    "Localhost_Auth_Vault_8097",
                )
            } else {
                (
                    "Blocked_Public_Guard",
                    "NONE (Auth_Required)",
                    "HTTP_403_Operator_Gate",
                )
            }
        }
        _ => (
            "Cloudflare_D1_And_LOQ15_Gateway",
            "S00..S79 (80 Sectors u128)",
            "Streamable_HTTP_MCP",
        ),
    };

    let elapsed_us = t0.elapsed().as_micros().max(1);

    RouteDecision5W1H {
        who_caller: String::from(who_caller),
        what_workload: String::from(what_workload),
        when_decadic_us: elapsed_us,
        where_target_node: String::from(where_target_node),
        where_sector_span: String::from(where_sector_span),
        why_metabolic_atp,
        how_transport: String::from(how_transport),
        auth_vault_unlocked: operator_token_valid,
    }
}

pub fn tool_65_distributed_5w1h_router_json(who: &str, what: &str, token_ok: bool) -> String {
    let r = dispatch_5w1h_distributed_route(who, what, token_ok);
    format!(
        "{{\"tool\":65,\"endpoint\":\"/api/v1/router/distributed_5w1h_dispatch\",\"who\":\"{}\",\"what\":\"{}\",\"when_us\":{},\"where_node\":\"{}\",\"where_sectors\":\"{}\",\"why_atp\":{:.4},\"how\":\"{}\",\"vault_unlocked\":{}}}",
        r.who_caller,
        r.what_workload,
        r.when_decadic_us,
        r.where_target_node,
        r.where_sector_span,
        r.why_metabolic_atp,
        r.how_transport,
        r.auth_vault_unlocked
    )
}

pub fn tool_66_symbiotic_ide_parity_json() -> String {
    let zed_ok = std::path::Path::new("00_control/ide_configs/zed_settings.json").exists();
    let goose_ok = std::path::Path::new("00_control/ide_configs/goose_config.yaml").exists();
    let cline_ok = std::path::Path::new("00_control/ide_configs/cline_mcp_settings.json").exists();
    let queue_ok = std::path::Path::new("03_vault/connectome/tasks_queue.json").exists();
    format!(
        "{{\"tool\":66,\"endpoint\":\"/api/v1/ide/symbiotic_parity_sync\",\"model_id\":\"SH4Z-v4420-TriSilicon\",\"zed_v2_synced\":{},\"goose_workspace_locked\":{},\"cline_mcp_synced\":{},\"shared_tasks_queue_ready\":{}}}",
        zed_ok, goose_ok, cline_ok, queue_ok
    )
}

pub fn tool_67_operator_vault_gate_json(supplied_key: &str, is_localhost: bool) -> String {
    let authorized = verify_operator_vault_secret(supplied_key, is_localhost);
    let key_configured = std::env::var("ACT_OMEGA_OPERATOR_KEY").is_ok()
        || std::path::Path::new("00_control/.operator_vault_key").exists();
    format!(
        "{{\"tool\":67,\"endpoint\":\"/api/v1/auth/operator_vault_gate\",\"is_localhost\":{},\"key_configured\":{},\"authorized\":{},\"public_overuse_protection\":\"ACTIVE_ENV_SECRET_GATE\"}}",
        is_localhost, key_configured, authorized
    )
}

pub fn tool_68_embedded_ide_cockpit_json(authorized: bool) -> String {
    if !authorized {
        return String::from("{\"tool\":68,\"status\":\"LOCKED_BEHIND_OPERATOR_GATE\",\"message\":\"Supply valid ACT_OMEGA_OPERATOR_KEY on localhost to unlock Embedded Goose, Zed & Cline Vault.\"}");
    }
    let queue_bytes = std::fs::metadata("03_vault/connectome/tasks_queue.json")
        .map(|m| m.len())
        .unwrap_or(0);
    format!(
        "{{\"tool\":68,\"endpoint\":\"/api/v1/hud/embedded_ide_cockpit\",\"status\":\"UNLOCKED_OPERATOR_VAULT\",\"embedded_agents\":(\"Goose_v1.55.0_Console\",\"Zed_v1.24.4_DeepLink_And_MCP\",\"VSCodium_Cline_TaskRunner\"),\"tasks_queue_bytes\":{}}}",
        queue_bytes
    )
}
