// =============================================================================
// ACT-OMEGA NET v73.2.2 — CLOUDFLARE VPC SERVICES, MESH ROUTING, PGWIRE & HYPERDRIVE
// Tools T400..T404 + CHAIN 404 Master Certification
// Muse-Compliant: Live Socket, Config, File Metadata & Native DuckDB Measurements Only
// Constitutionally Strictly Zero Square Brackets (0x5B / 0x5D = 0)
// =============================================================================

use std::fs;
use std::io::Write;
use std::net::{IpAddr, Ipv4Addr, SocketAddr, TcpStream};
use std::process::Command;
use std::time::{Duration, Instant};

use crate::v61_gemma4_multimodal_ple_speculative_cascade_and_mcp_suite::v61_escape_clean;
use crate::v73_0_unified_standalone_lab_bridge::{
    v73_0_probe_station_live_json, V73_0_UNIFIED_MANIFEST_PATH,
};
use crate::v73_1_nov12_15_research_kernels::v73_1_dispatch_chain399_master_certification;

pub const V73_2_VPC_MESH_YML_PATH: &str = "C:\\sovereign_manifold_v31\\00_control\\cloudflare_vpc_mesh_quic.yml";
pub const V73_2_VPC_MESH_LOG_PATH: &str = "C:\\sovereign_manifold_v31\\00_control\\cloudflared_vpc_mesh.log";
pub const V73_2_WRANGLER_TOML_PATH: &str = "C:\\sovereign_manifold_v31\\00_control\\cloudflare_edge\\wrangler.toml";
pub const V73_2_WRANGLER_WORKFLOW_TOML_PATH: &str = "C:\\sovereign_manifold_v31\\00_control\\cloudflare_edge\\wrangler.workflow.toml";
pub const V73_2_DUCKDB_EXE_PATH: &str = "C:\\sovereign_manifold_v31\\00_control\\foss_bin\\duckdb.exe";
pub const V73_2_DUCKDB_CORPUS_PATH: &str = "E:\\Sovereign_Manifold_SSD_Vault\\training_corpus\\sh_rw_corpus_v7210.duckdb";
pub const V73_2_PGWIRE_CERT_PATH: &str = "C:\\Users\\Nbell\\.act_omega_pgwire_tls\\server.pem";
pub const V73_2_PGWIRE_CA_PATH: &str = "C:\\Users\\Nbell\\.act_omega_pgwire_tls\\ca.pem";
pub const V73_2_HEALTH_ENDPOINT: &str = "/api/v1/health";
pub const V73_2_TELEMETRY_INGEST_ENDPOINT: &str = "/api/v1/telemetry/ingest";
pub const V73_2_TELEMETRY_KEY_FILE_PATH: &str = "C:\\Users\\Nbell\\.act_omega_telemetry_ingest_key";
pub const V73_2_OPERATOR_KEY_FILE_PATH: &str = "C:\\Users\\Nbell\\.act_omega_operator_vault_key";

fn v73_2_tcp_connect_ms(port: u16, timeout_ms: u64, send_pg_cancel: bool) -> Result<f64, &'static str> {
    let addr = SocketAddr::new(IpAddr::V4(Ipv4Addr::LOCALHOST), port);
    let t0 = Instant::now();
    let mut stream = TcpStream::connect_timeout(&addr, Duration::from_millis(timeout_ms))
        .map_err(|_| "UNMEASURED/OFFLINE")?;
    if send_pg_cancel {
        // Send PGWire CancelRequest (length=8, code=80877102) so PGWire closes without error
        let _ = stream.write_all(&vec!(0u8, 0u8, 0u8, 8u8, 4u8, 210u8, 22u8, 46u8));
    }
    Ok(t0.elapsed().as_secs_f64() * 1000.0)
}

fn v73_2_extract_json_string_field(payload: &str, key: &str) -> Option<String> {
    let needle = format!("\"{}\"", key);
    let pos = payload.find(&needle)?;
    let rest = payload.get((pos + needle.len())..)?;
    let colon_pos = rest.find(':')?;
    let after_colon = rest.get((colon_pos + 1)..)?.trim_start();
    if !after_colon.starts_with('"') {
        return None;
    }
    let mut out = String::new();
    let mut escaped = false;
    for ch in after_colon.chars().skip(1) {
        if escaped {
            out.push(ch);
            escaped = false;
        } else if ch == '\\' {
            escaped = true;
        } else if ch == '"' {
            return Some(out);
        } else {
            out.push(ch);
        }
    }
    None
}

fn v73_2_has_raw_sql_param(payload: &str) -> bool {
    if let Ok(val) = serde_json::from_str::<serde_json::Value>(payload) {
        if let Some(obj) = val.as_object() {
            if obj.contains_key("sql") {
                return true;
            }
        }
    }
    let trimmed = payload.trim();
    if trimmed.contains("\"sql\"") || trimmed.contains("?sql=") || trimmed.contains("&sql=") || trimmed.starts_with("sql=") {
        return true;
    }
    false
}

fn v73_2_extract_query_param_str(raw: &str, key: &str) -> Option<String> {
    let q_start = raw.find('?')?;
    let qs = raw.get((q_start + 1)..)?;
    let prefix = format!("{}=", key);
    for pair in qs.split('&') {
        if let Some(val) = pair.strip_prefix(&prefix) {
            let clean = val.trim();
            if !clean.is_empty() {
                return Some(String::from(clean));
            }
        }
    }
    None
}

fn v73_2_resolve_allowlisted_duckdb_query(payload: &str) -> Result<(String, String), (&'static str, &'static str)> {
    if v73_2_has_raw_sql_param(payload) {
        return Err((
            "REJECTED_ARBITRARY_SQL_FORBIDDEN",
            "Free-form SQL is prohibited; specify allowlisted query_id",
        ));
    }
    let parsed_json = serde_json::from_str::<serde_json::Value>(payload).ok();
    let query_id = parsed_json
        .as_ref()
        .and_then(|v| v.get("query_id"))
        .and_then(|x| x.as_str())
        .map(|s| String::from(s.trim()))
        .or_else(|| v73_2_extract_json_string_field(payload, "query_id"))
        .or_else(|| v73_2_extract_query_param_str(payload, "query_id"))
        .filter(|s| !s.is_empty())
        .unwrap_or_else(|| String::from("corpus_doc_count"));

    if query_id == "corpus_doc_count" {
        Ok((
            query_id,
            String::from("SELECT count(*) AS docs_count, COALESCE(sum(char_bytes), 0) AS total_char_bytes FROM corpus_docs"),
        ))
    } else if query_id == "corpus_track_summary" {
        Ok((
            query_id,
            String::from("SELECT track_id, track_name, count(*) AS docs_count, COALESCE(sum(char_bytes), 0) AS track_char_bytes FROM corpus_docs GROUP BY track_id, track_name ORDER BY track_id ASC"),
        ))
    } else if query_id == "corpus_docs_by_track" {
        let track_id = parsed_json
            .as_ref()
            .and_then(|v| v.get("track_id"))
            .and_then(|x| x.as_u64())
            .or_else(|| v73_2_extract_query_param_str(payload, "track_id").and_then(|s| s.parse::<u64>().ok()))
            .unwrap_or(0)
            .min(15);
        let limit = parsed_json
            .as_ref()
            .and_then(|v| v.get("limit"))
            .and_then(|x| x.as_u64())
            .or_else(|| v73_2_extract_query_param_str(payload, "limit").and_then(|s| s.parse::<u64>().ok()))
            .unwrap_or(10)
            .clamp(1, 50);
        let sql = format!(
            "SELECT doc_id, track_id, track_name, char_bytes, is_zero_bracket, minhash64 FROM corpus_docs WHERE track_id = {} ORDER BY doc_id ASC LIMIT {}",
            track_id, limit
        );
        Ok((query_id, sql))
    } else if query_id == "corpus_zero_bracket_stats" {
        Ok((
            query_id,
            String::from("SELECT is_zero_bracket, count(*) AS docs_count FROM corpus_docs GROUP BY is_zero_bracket ORDER BY is_zero_bracket DESC"),
        ))
    } else {
        Err((
            "REJECTED_UNKNOWN_QUERY_ID",
            "Unknown query_id; allowed: corpus_doc_count, corpus_track_summary, corpus_docs_by_track, corpus_zero_bracket_stats",
        ))
    }
}

/// T400: Cloudflare Workers VPC Service Registry & Endpoint Health Probe
pub fn v73_2_dispatch_tool_400_vpc_registry_probe(_payload: &str) -> String {
    let t0 = Instant::now();
    let wrangler_txt = fs::read_to_string(V73_2_WRANGLER_TOML_PATH).unwrap_or_default();
    let wf_txt = fs::read_to_string(V73_2_WRANGLER_WORKFLOW_TOML_PATH).unwrap_or_default();
    let yml_txt = fs::read_to_string(V73_2_VPC_MESH_YML_PATH).unwrap_or_default();
    let log_txt = fs::read_to_string(V73_2_VPC_MESH_LOG_PATH).unwrap_or_default();

    let registered_conns = log_txt.matches("Registered tunnel connection").count();
    let quic_protocol = yml_txt.contains("protocol: quic");
    let has_vpc_anchor = wrangler_txt.contains("ANCHOR_L0_VPC");
    let has_vpc_deno = wrangler_txt.contains("DENO_L2_VPC");
    let has_vpc_p10 = wrangler_txt.contains("PIXEL10_EDGE_VPC");
    let has_vpc_p8 = wrangler_txt.contains("PIXEL8_APEX_VPC");
    let has_hyperdrive = wrangler_txt.contains("ACT_OMEGA_HYPERDRIVE") && wf_txt.contains("ACT_OMEGA_HYPERDRIVE");

    let p_anchor = v73_0_probe_station_live_json(8097, "/api/v1/status", 250);
    let p_deno = v73_0_probe_station_live_json(8099, "/api/v1/pgwire/status", 250);
    let p_p10 = v73_0_probe_station_live_json(19788, "/api/health", 350);
    let p_p8 = v73_0_probe_station_live_json(19792, "/api/health", 350);

    let mut online_http = 0usize;
    if p_anchor.is_ok() { online_http += 1; }
    if p_deno.is_ok() { online_http += 1; }
    if p_p10.is_ok() { online_http += 1; }
    if p_p8.is_ok() { online_http += 1; }

    let fmt_probe = |name: &str, binding: &str, port: u16, res: &Result<(String, f64), &'static str>| -> String {
        match res {
            Ok((body, rtt)) => format!(
                "{{\"service\":\"{}\",\"binding\":\"{}\",\"port\":{},\"online\":true,\"status\":\"MEASURED_VPC_TARGET_READY\",\"rtt_ms\":{:.3},\"body_bytes\":{}}}",
                name, binding, port, rtt, body.len()
            ),
            Err(e) => format!(
                "{{\"service\":\"{}\",\"binding\":\"{}\",\"port\":{},\"online\":false,\"status\":\"{}\"}}",
                name, binding, port, e
            ),
        }
    };

    let targets_json = format!(
        "\x5b{},{},{},{}\x5d",
        fmt_probe("act-omega-anchor-l0-vpc", "ANCHOR_L0_VPC", 8097, &p_anchor),
        fmt_probe("act-omega-deno-l2-vpc", "DENO_L2_VPC", 8099, &p_deno),
        fmt_probe("act-omega-pixel10-edge-vpc", "PIXEL10_EDGE_VPC", 19788, &p_p10),
        fmt_probe("act-omega-pixel8-apex-vpc", "PIXEL8_APEX_VPC", 19792, &p_p8),
    );

    let all_configured = has_vpc_anchor && has_vpc_deno && has_vpc_p10 && has_vpc_p8 && has_hyperdrive && quic_protocol;
    let status = if all_configured && online_http == 4 && registered_conns > 0 {
        "MEASURED_VPC_SERVICES_ONLINE"
    } else if all_configured && online_http > 0 {
        "MEASURED_VPC_PARTIAL"
    } else {
        "UNMEASURED/OFFLINE"
    };
    let elapsed_ms = t0.elapsed().as_secs_f64() * 1000.0;

    format!(
        "{{\"ok\":{},\"status\":\"{}\",\"tool_id\":400,\"tool_name\":\"cloudflare_vpc_service_registry_probe\",\"tunnel_name\":\"sovereign-vpc-mesh\",\"quic_protocol\":{},\"tunnel_registered_connections\":{},\"hyperdrive_configured\":{},\"http_targets_online\":{},\"total_http_targets\":4,\"elapsed_ms\":{:.3},\"targets\":{}}}",
        all_configured && online_http >= 2,
        status,
        quic_protocol,
        registered_conns,
        has_hyperdrive,
        online_http,
        elapsed_ms,
        targets_json
    )
}

/// T401: Cloudflare Mesh Cluster Device Roster & Tunnel Connector Audit
pub fn v73_2_dispatch_tool_401_mesh_device_roster(_payload: &str) -> String {
    let t0 = Instant::now();
    let log_txt = fs::read_to_string(V73_2_VPC_MESH_LOG_PATH).unwrap_or_default();
    let yml_present = fs::metadata(V73_2_VPC_MESH_YML_PATH).is_ok();
    let reg_conns = log_txt.matches("Registered tunnel connection").count();

    let rtt_anchor = v73_2_tcp_connect_ms(8097, 200, false);
    let rtt_deno = v73_2_tcp_connect_ms(8099, 200, false);
    let rtt_pgwire = v73_2_tcp_connect_ms(5439, 200, true);
    let rtt_p10 = v73_2_tcp_connect_ms(19788, 250, false);
    let rtt_p8_http = v73_2_tcp_connect_ms(19792, 250, false);
    let rtt_p8_ksu = v73_2_tcp_connect_ms(8098, 250, false);

    let mut reach_count = 0usize;
    if rtt_anchor.is_ok() { reach_count += 1; }
    if rtt_deno.is_ok() { reach_count += 1; }
    if rtt_pgwire.is_ok() { reach_count += 1; }
    if rtt_p10.is_ok() { reach_count += 1; }
    if rtt_p8_http.is_ok() { reach_count += 1; }
    if rtt_p8_ksu.is_ok() { reach_count += 1; }

    let fmt_sock = |dev: &str, cidr: &str, port: u16, res: &Result<f64, &'static str>| -> String {
        match res {
            Ok(ms) => format!(
                "{{\"device\":\"{}\",\"mesh_cidr\":\"{}\",\"port\":{},\"reachable\":true,\"status\":\"MEASURED_ONLINE\",\"tcp_rtt_ms\":{:.3}}}",
                dev, cidr, port, ms
            ),
            Err(e) => format!(
                "{{\"device\":\"{}\",\"mesh_cidr\":\"{}\",\"port\":{},\"reachable\":false,\"status\":\"{}\"}}",
                dev, cidr, port, e
            ),
        }
    };

    let nodes_json = format!(
        "\x5b{},{},{},{},{},{}\x5d",
        fmt_sock("anchor-1-lenovo-loq15-wifi", "lan-wifi/32", 8097, &rtt_anchor),
        fmt_sock("anchor-1-host-hotspot", "lan-hotspot/32", 8099, &rtt_deno),
        fmt_sock("anchor-1-duckdb-pgwire-tls", "127.0.0.1/32", 5439, &rtt_pgwire),
        fmt_sock("edge-1-pixel10-npu", "edge-1-lan/32", 19788, &rtt_p10),
        fmt_sock("edge-2-pixel8-pocket-http", "edge-2-lan/32", 19792, &rtt_p8_http),
        fmt_sock("edge-2-pixel8-ksu-apex", "edge-2-lan/32", 8098, &rtt_p8_ksu),
    );

    let elapsed_ms = t0.elapsed().as_secs_f64() * 1000.0;
    let status = if reach_count >= 4 { "MEASURED_MESH_CLUSTER_ONLINE" } else { "UNMEASURED/OFFLINE" };

    format!(
        "{{\"ok\":{},\"status\":\"{}\",\"tool_id\":401,\"tool_name\":\"cloudflare_mesh_cluster_device_roster\",\"cf_vnet\":\"default\",\"tunnel\":\"sovereign-vpc-mesh\",\"tunnel_config_present\":{},\"quic_connectors_logged\":{},\"reachable_sockets\":{},\"total_sockets\":6,\"elapsed_ms\":{:.3},\"nodes\":{}}}",
        reach_count >= 3,
        status,
        yml_present,
        reg_conns,
        reach_count,
        elapsed_ms,
        nodes_json
    )
}

/// T402: Zero-Dependency TLS PGWire v3 -> Native DuckDB Bridge Audit
pub fn v73_2_dispatch_tool_402_pgwire_duckdb_audit(_payload: &str) -> String {
    let t0 = Instant::now();
    let db_bytes = fs::metadata(V73_2_DUCKDB_CORPUS_PATH).map(|m| m.len()).unwrap_or(0);
    let cert_present = fs::metadata(V73_2_PGWIRE_CERT_PATH).is_ok() && fs::metadata(V73_2_PGWIRE_CA_PATH).is_ok();
    let duckdb_bin_present = fs::metadata(V73_2_DUCKDB_EXE_PATH).is_ok();

    let status_res = v73_0_probe_station_live_json(8099, "/api/v1/pgwire/status", 300);
    let pgwire_http_online = status_res.is_ok();
    let pgwire_preview = match &status_res {
        Ok((body, _)) => body.clone(),
        Err(_) => String::from("UNMEASURED/OFFLINE"),
    };
    let tcp_5439 = v73_2_tcp_connect_ms(5439, 200, true);
    let elapsed_ms = t0.elapsed().as_secs_f64() * 1000.0;
    let ok = db_bytes > 0 && cert_present && duckdb_bin_present && pgwire_http_online && tcp_5439.is_ok();
    let status = if ok { "MEASURED_PGWIRE_TLS_ONLINE" } else { "UNMEASURED/OFFLINE" };

    format!(
        "{{\"ok\":{},\"status\":\"{}\",\"tool_id\":402,\"tool_name\":\"pgwire_duckdb_tls_bridge_audit\",\"pgwire_port\":5439,\"pgwire_tcp_ok\":{},\"pgwire_status_http_online\":{},\"tls_certs_present\":{},\"duckdb_bin_present\":{},\"duckdb_corpus_bytes\":{},\"elapsed_ms\":{:.3},\"pgwire_status_snapshot\":\"{}\"}}",
        ok,
        status,
        tcp_5439.is_ok(),
        pgwire_http_online,
        cert_present,
        duckdb_bin_present,
        db_bytes,
        elapsed_ms,
        v61_escape_clean(&pgwire_preview)
    )
}

/// T403: Allowlisted Parameterized Read-Only Analytical DuckDB Query (External Access Disabled per S1)
pub fn v73_2_dispatch_tool_403_hyperdrive_duckdb_query(payload: &str) -> String {
    let t0 = Instant::now();
    let (query_id, canned_sql) = match v73_2_resolve_allowlisted_duckdb_query(payload) {
        Ok(pair) => pair,
        Err((code, msg)) => {
            return format!(
                "{{\"ok\":false,\"status\":\"{}\",\"tool_id\":403,\"tool_name\":\"cloudflare_hyperdrive_duckdb_query\",\"error\":\"{}\"}}",
                code,
                v61_escape_clean(msg)
            );
        }
    };

    if fs::metadata(V73_2_DUCKDB_EXE_PATH).is_err() || fs::metadata(V73_2_DUCKDB_CORPUS_PATH).is_err() {
        return String::from(
            "{\"ok\":false,\"status\":\"UNMEASURED/OFFLINE\",\"tool_id\":403,\"tool_name\":\"cloudflare_hyperdrive_duckdb_query\",\"reason\":\"duckdb_exe_or_corpus_missing\"}",
        );
    }

    let out_res = Command::new(V73_2_DUCKDB_EXE_PATH)
        .arg("-readonly")
        .arg("-json")
        .arg(V73_2_DUCKDB_CORPUS_PATH)
        .arg("-cmd")
        .arg("SET enable_external_access=false; SET lock_configuration=true;")
        .arg("-c")
        .arg(&canned_sql)
        .output();

    let elapsed_ms = t0.elapsed().as_secs_f64() * 1000.0;
    let wf_toml = fs::read_to_string(V73_2_WRANGLER_WORKFLOW_TOML_PATH).unwrap_or_default();
    let hyperdrive_configured = wf_toml.contains("ACT_OMEGA_HYPERDRIVE");

    match out_res {
        Ok(out) if out.status.success() => {
            let stdout_str = String::from_utf8_lossy(&out.stdout).trim().to_string();
            let safe_json = if stdout_str.is_empty() {
                String::from("\x5b\x5d")
            } else {
                stdout_str
            };
            format!(
                "{{\"ok\":true,\"status\":\"MEASURED_DUCKDB_HYPERDRIVE_READY\",\"tool_id\":403,\"tool_name\":\"cloudflare_hyperdrive_duckdb_query\",\"query_id\":\"{}\",\"external_access_disabled\":true,\"hyperdrive_config_present\":{},\"elapsed_ms\":{:.3},\"rows\":{}}}",
                v61_escape_clean(&query_id),
                hyperdrive_configured,
                elapsed_ms,
                safe_json
            )
        }
        Ok(out) => {
            let err_str = String::from_utf8_lossy(&out.stderr).trim().to_string();
            format!(
                "{{\"ok\":false,\"status\":\"DUCKDB_SQL_ERROR\",\"tool_id\":403,\"tool_name\":\"cloudflare_hyperdrive_duckdb_query\",\"query_id\":\"{}\",\"elapsed_ms\":{:.3},\"error\":\"{}\"}}",
                v61_escape_clean(&query_id),
                elapsed_ms,
                v61_escape_clean(&err_str)
            )
        }
        Err(e) => format!(
            "{{\"ok\":false,\"status\":\"UNMEASURED/OFFLINE\",\"tool_id\":403,\"tool_name\":\"cloudflare_hyperdrive_duckdb_query\",\"error\":\"{}\"}}",
            v61_escape_clean(&e.to_string())
        ),
    }
}

fn v73_2_json_ok_flag(raw_json: &str) -> bool {
    serde_json::from_str::<serde_json::Value>(raw_json)
        .ok()
        .and_then(|v| v.get("ok").and_then(|b| b.as_bool()))
        .unwrap_or(false)
}

/// T404: CHAIN 404 Master Certification (Strict serde_json + Manifest Weight SHA-256 + Lean 4 Compiler Proof per C1/E5)
pub fn v73_2_dispatch_chain404_master_certification(payload: &str) -> String {
    let t0 = Instant::now();
    let t400 = v73_2_dispatch_tool_400_vpc_registry_probe(payload);
    let t401 = v73_2_dispatch_tool_401_mesh_device_roster(payload);
    let t402 = v73_2_dispatch_tool_402_pgwire_duckdb_audit(payload);
    let t403 = v73_2_dispatch_tool_403_hyperdrive_duckdb_query("{}");
    let c399 = v73_1_dispatch_chain399_master_certification(payload);

    let (lean_verified, lean_theorems, lean_sorries, lean_sha256) =
        crate::v73_1_nov12_15_research_kernels::v73_1_verify_lean4_compiler_and_mirror();
    let weights_res = crate::v72_1_sh_xi_matryoshka_384_768_cuda_pretrainer::v72_1_verify_entire_weight_manifest();
    let weights_manifest_ok = weights_res.is_ok();
    let weights_verified_count = weights_res.unwrap_or(0);
    let lab_manifest_ok = fs::metadata(V73_0_UNIFIED_MANIFEST_PATH).is_ok();

    let p35_ok = v73_2_json_ok_flag(&t400)
        && v73_2_json_ok_flag(&t401)
        && v73_2_json_ok_flag(&t402)
        && v73_2_json_ok_flag(&t403);
    let c399_ok = v73_2_json_ok_flag(&c399);
    let all_ok = p35_ok
        && c399_ok
        && weights_manifest_ok
        && lab_manifest_ok
        && lean_verified
        && lean_sorries == 0
        && validate_live_lean_theorems_with_floor(lean_theorems);
    let status = if all_ok {
        "MEASURED_CHAIN404_CERTIFIED"
    } else if p35_ok && weights_manifest_ok && lean_verified {
        "MEASURED_CHAIN404_PARTIAL"
    } else {
        "UNMEASURED/OFFLINE"
    };
    let live_ver = v73_2_read_live_release_version();
    let elapsed_ms = t0.elapsed().as_secs_f64() * 1000.0;

    format!(
        "{{\"ok\":{},\"certified\":{},\"status\":\"{}\",\"version\":\"{}\",\"chain_milestone\":\"CHAIN 404\",\"tools_total\":404,\"weights_manifest_ok\":{},\"weights_verified_count\":{},\"lean4_compiler_verified\":{},\"lean4_sha256\":\"{}\",\"lean4_theorems_qed\":{},\"lean_sorry_count\":{},\"unified_lab_manifest_present\":{},\"p35_cloudflare_vpc_hyperdrive_ok\":{},\"chain399_ok\":{},\"elapsed_ms\":{:.3},\"t400\":{},\"t401\":{},\"t402\":{},\"t403\":{},\"chain399\":{}}}",
        all_ok,
        all_ok,
        status,
        v61_escape_clean(&live_ver),
        weights_manifest_ok,
        weights_verified_count,
        lean_verified,
        lean_sha256,
        lean_theorems,
        lean_sorries,
        lab_manifest_ok,
        p35_ok,
        c399_ok,
        elapsed_ms,
        t400, t401, t402, t403, c399
    )
}

pub fn v73_2_resolve_allowed_l0_cors_origin(origin: &str) -> &'static str {
    match origin.trim() {
        "https://act-omega-net.dev" => "https://act-omega-net.dev",
        "https://api.act-omega-net.dev" => "https://api.act-omega-net.dev",
        "https://mcp.act-omega-net.dev" => "https://mcp.act-omega-net.dev",
        "http://127.0.0.1:5173" => "http://127.0.0.1:5173",
        "http://localhost:5173" => "http://localhost:5173",
        "http://127.0.0.1:8097" => "http://127.0.0.1:8097",
        _ => "",
    }
}

fn v73_2_parse_bounded_kops_field(
    obj: &serde_json::Map<String, serde_json::Value>,
    primary: &str,
    alias: &str,
    err_code: &'static str,
) -> Result<Option<f64>, &'static str> {
    let mut primary_val: Option<f64> = None;
    if let Some(raw_v) = obj.get(primary) {
        let num = raw_v.as_f64().ok_or(err_code)?;
        if !num.is_finite() || !(0.0..=100_000.0).contains(&num) {
            return Err(err_code);
        }
        primary_val = Some(num);
    }
    let mut alias_val: Option<f64> = None;
    if let Some(raw_v) = obj.get(alias) {
        let num = raw_v.as_f64().ok_or(err_code)?;
        if !num.is_finite() || !(0.0..=100_000.0).contains(&num) {
            return Err(err_code);
        }
        alias_val = Some(num);
    }
    Ok(primary_val.or(alias_val))
}

pub fn v73_2_parse_sync_matrix_json(body: &str) -> Result<(Option<f64>, Option<f64>), &'static str> {
    let trimmed = body.trim();
    if trimmed.is_empty() {
        return Err("EMPTY_SYNC_MATRIX_BODY");
    }
    let parsed = serde_json::from_str::<serde_json::Value>(trimmed).map_err(|_| "INVALID_JSON_BODY")?;
    let obj = parsed.as_object().ok_or("JSON_BODY_MUST_BE_OBJECT")?;
    let p10 = v73_2_parse_bounded_kops_field(obj, "pixel10_kops", "pixel10", "INVALID_OR_OOB_PIXEL10_KOPS")?;
    let p8 = v73_2_parse_bounded_kops_field(obj, "pixel8_kops", "pixel8", "INVALID_OR_OOB_PIXEL8_KOPS")?;
    if p10.is_none() && p8.is_none() {
        return Err("MISSING_PIXEL_KOPS_FIELDS");
    }
    Ok((p10, p8))
}

fn v73_2_hex_nibble(b: u8) -> Option<u8> {
    match b {
        b'0'..=b'9' => Some(b - b'0'),
        b'a'..=b'f' => Some(b - b'a' + 10),
        b'A'..=b'F' => Some(b - b'A' + 10),
        _ => None,
    }
}

pub fn v73_2_percent_decode_ascii(input: &str) -> String {
    let bytes = input.as_bytes();
    let mut out: Vec<u8> = Vec::with_capacity(bytes.len());
    let mut i: usize = 0;
    while i < bytes.len() {
        let b = *bytes.get(i).unwrap_or(&0);
        if b == b'%' && i + 2 < bytes.len() {
            let hi = v73_2_hex_nibble(*bytes.get(i + 1).unwrap_or(&0));
            let lo = v73_2_hex_nibble(*bytes.get(i + 2).unwrap_or(&0));
            if let (Some(h), Some(l)) = (hi, lo) {
                out.push((h << 4) | l);
                i += 3;
                continue;
            }
        }
        out.push(b);
        i += 1;
    }
    String::from_utf8_lossy(&out).into_owned()
}

fn v73_2_decode_query_param_name(raw_name: &str) -> String {
    let mut cur = String::from(raw_name.trim());
    let mut pass: usize = 0;
    while pass < 4 {
        let next = v73_2_percent_decode_ascii(&cur);
        if next == cur {
            break;
        }
        cur = next;
        pass += 1;
    }
    cur.trim().to_ascii_lowercase()
}

pub fn v73_2_has_query_key_param(raw_target: &str) -> bool {
    let qs = match raw_target.split_once('?') {
        Some((_, q)) => q,
        None => return false,
    };
    for pair in qs.split('&') {
        let raw_name = pair.split('=').next().unwrap_or("");
        let key_name = v73_2_decode_query_param_name(raw_name);
        if key_name == "key" {
            return true;
        }
    }
    false
}

pub fn v73_2_has_telemetry_write_query_param(raw_target: &str) -> bool {
    let qs = match raw_target.split_once('?') {
        Some((_, q)) => q,
        None => return false,
    };
    for pair in qs.split('&') {
        let raw_name = pair.split('=').next().unwrap_or("");
        let key_low = v73_2_decode_query_param_name(raw_name);
        let is_write = key_low == "node"
            || key_low == "kops"
            || key_low == "p8_kops"
            || key_low == "pixel10_kops"
            || key_low == "pixel10"
            || key_low == "pixel8_kops"
            || key_low == "pixel8"
            || key_low == "loq15_kops"
            || key_low == "loq15"
            || key_low == "anchor1_kops"
            || key_low == "p8_free"
            || key_low == "col"
            || key_low == "mx"
            || key_low == "my"
            || key_low == "mz"
            || key_low == "bn"
            || key_low == "baro"
            || key_low == "lux"
            || key_low == "acc"
            || key_low == "gyro"
            || key_low == "temp"
            || key_low == "mv"
            || key_low == "bat"
            || key_low == "ram_u"
            || key_low == "ram_t"
            || key_low == "shz"
            || key_low == "thz"
            || key_low == "rtt"
            || key_low == "bearer";
        if is_write {
            return true;
        }
    }
    false
}

pub fn v73_2_constant_time_compare_key(supplied: &str, expected: &str) -> bool {
    if supplied.is_empty() || expected.is_empty() {
        return false;
    }
    let sup_vec = supplied.as_bytes().to_vec();
    let exp_vec = expected.as_bytes().to_vec();
    let h_sup = crate::v72_1_sh_xi_matryoshka_384_768_cuda_pretrainer::v72_1_sha256_hex(&sup_vec);
    let h_exp = crate::v72_1_sh_xi_matryoshka_384_768_cuda_pretrainer::v72_1_sha256_hex(&exp_vec);
    crate::v73_1_nov12_15_research_kernels::v73_1_constant_time_eq_hex_64(&h_sup, &h_exp)
}

pub fn v73_2_resolve_expected_telemetry_key() -> String {
    let raw = std::env::var("ACT_OMEGA_TELEMETRY_KEY")
        .ok()
        .or_else(|| fs::read_to_string(V73_2_TELEMETRY_KEY_FILE_PATH).ok())
        .unwrap_or_default();
    let trimmed = raw.trim();
    if trimmed.len() < 24 {
        String::new()
    } else {
        String::from(trimmed)
    }
}

pub fn v73_2_resolve_expected_operator_key() -> String {
    let raw = std::env::var("ACT_OMEGA_OPERATOR_KEY")
        .or_else(|_| std::env::var("SOVEREIGN_OPERATOR_KEY"))
        .ok()
        .or_else(|| fs::read_to_string(V73_2_OPERATOR_KEY_FILE_PATH).ok())
        .unwrap_or_default();
    let trimmed = raw.trim();
    if trimmed.len() < 24 {
        String::new()
    } else {
        String::from(trimmed)
    }
}

pub fn v73_2_verify_telemetry_or_operator_auth_with_keys(
    is_loopback: bool,
    telemetry_header_key: &str,
    operator_header_key: &str,
    raw_target: &str,
    expected_telemetry_key: &str,
    expected_operator_key: &str,
) -> Result<&'static str, (&'static str, &'static str)> {
    if !is_loopback {
        return Err(("NON_LOOPBACK_TELEMETRY_INGEST_DENIED", "Telemetry ingest requires 127.0.0.1 loopback"));
    }
    if v73_2_has_query_key_param(raw_target) {
        return Err((
            "QUERY_KEY_PARAMETER_FORBIDDEN_USE_TELEMETRY_OR_OPERATOR_HEADER",
            "Passing ?key= in URL query is forbidden",
        ));
    }
    let clean_tel = telemetry_header_key.trim();
    if clean_tel.len() >= 24
        && expected_telemetry_key.len() >= 24
        && v73_2_constant_time_compare_key(clean_tel, expected_telemetry_key)
    {
        return Ok("X-Sovereign-Telemetry-Key");
    }
    let clean_op = operator_header_key.trim();
    if clean_op.len() >= 24
        && expected_operator_key.len() >= 24
        && v73_2_constant_time_compare_key(clean_op, expected_operator_key)
    {
        return Ok("X-Sovereign-Operator-Key");
    }
    Err((
        "INVALID_OR_MISSING_TELEMETRY_OR_OPERATOR_HEADER",
        "Requires valid X-Sovereign-Telemetry-Key or X-Sovereign-Operator-Key header",
    ))
}

pub fn v73_2_require_loopback_and_telemetry_or_operator_header(
    is_loopback: bool,
    telemetry_header_key: &str,
    operator_header_key: &str,
    raw_target: &str,
) -> Result<&'static str, (&'static str, &'static str)> {
    let exp_tel = v73_2_resolve_expected_telemetry_key();
    let exp_op = v73_2_resolve_expected_operator_key();
    v73_2_verify_telemetry_or_operator_auth_with_keys(
        is_loopback,
        telemetry_header_key,
        operator_header_key,
        raw_target,
        &exp_tel,
        &exp_op,
    )
}

pub struct V732TelemetryIngestPayload {
    pub node: Option<String>,
    pub kops: Option<f64>,
    pub p8_kops: Option<f64>,
    pub pixel10_kops: Option<f64>,
    pub pixel8_kops: Option<f64>,
    pub loq15_kops: Option<f64>,
    pub p8_free: Option<f64>,
    pub col: Option<u64>,
    pub mx: Option<f64>,
    pub my: Option<f64>,
    pub mz: Option<f64>,
    pub bn: Option<f64>,
    pub baro: Option<f64>,
    pub lux: Option<f64>,
    pub acc: Option<f64>,
    pub gyro: Option<f64>,
    pub temp: Option<f64>,
    pub mv: Option<u64>,
    pub bat: Option<u64>,
    pub ram_u: Option<u64>,
    pub ram_t: Option<u64>,
    pub shz: Option<f64>,
    pub thz: Option<f64>,
    pub rtt: Option<f64>,
    pub bearer: Option<String>,
}

fn v73_2_opt_bounded_f64(
    obj: &serde_json::Map<String, serde_json::Value>,
    key: &str,
    min_val: f64,
    max_val: f64,
    err_code: &'static str,
) -> Result<Option<f64>, (&'static str, &'static str)> {
    match obj.get(key) {
        None => Ok(None),
        Some(raw) => {
            let num = raw.as_f64().ok_or((err_code, "Field must be a finite JSON number"))?;
            if !num.is_finite() || num < min_val || num > max_val {
                return Err((err_code, "Numeric telemetry field out of physical bounds"));
            }
            Ok(Some(num))
        }
    }
}

fn v73_2_opt_bounded_u64(
    obj: &serde_json::Map<String, serde_json::Value>,
    key: &str,
    max_val: u64,
    err_code: &'static str,
) -> Result<Option<u64>, (&'static str, &'static str)> {
    match obj.get(key) {
        None => Ok(None),
        Some(raw) => {
            if let Some(u) = raw.as_u64() {
                if u > max_val {
                    return Err((err_code, "Integer telemetry field exceeds maximum bound"));
                }
                return Ok(Some(u));
            }
            let f = raw.as_f64().ok_or((err_code, "Field must be a non-negative finite number"))?;
            if !f.is_finite() || f < 0.0 || f > (max_val as f64) {
                return Err((err_code, "Numeric telemetry field out of physical bounds"));
            }
            Ok(Some(f.round() as u64))
        }
    }
}

fn v73_2_opt_strict_bounded_u64(
    obj: &serde_json::Map<String, serde_json::Value>,
    key: &str,
    max_val: u64,
    err_code: &'static str,
) -> Result<Option<u64>, (&'static str, &'static str)> {
    match obj.get(key) {
        None => Ok(None),
        Some(raw) => {
            let u = raw
                .as_u64()
                .ok_or((err_code, "Integer telemetry field must be a non-negative integer"))?;
            if u > max_val {
                return Err((err_code, "Integer telemetry field exceeds maximum bound"));
            }
            Ok(Some(u))
        }
    }
}

pub fn v73_2_validate_telemetry_bounds(
    body: &str,
) -> Result<V732TelemetryIngestPayload, (&'static str, &'static str)> {
    let trimmed = body.trim();
    if trimmed.is_empty() {
        return Err(("EMPTY_TELEMETRY_BODY", "Request body must be a non-empty JSON object"));
    }
    let parsed = serde_json::from_str::<serde_json::Value>(trimmed)
        .map_err(|_| ("INVALID_TELEMETRY_JSON", "Malformed or non-finite JSON payload"))?;
    let obj = parsed
        .as_object()
        .ok_or(("TELEMETRY_BODY_MUST_BE_OBJECT", "JSON payload must be an object"))?;

    let node = match obj.get("node") {
        None => None,
        Some(v) => {
            let s = v.as_str().ok_or(("INVALID_NODE_FIELD", "node must be a string"))?.trim();
            if s != "pixel10" && s != "pixel8" && s != "loq15" {
                return Err(("UNKNOWN_TELEMETRY_NODE", "node must be pixel10, pixel8, or loq15"));
            }
            Some(String::from(s))
        }
    };

    let bearer = match obj.get("bearer") {
        None => None,
        Some(v) => {
            let s = v.as_str().ok_or(("INVALID_BEARER_FIELD", "bearer must be a string"))?.trim();
            if s.is_empty() || s.len() > 128 || s.bytes().any(|b| b < 0x20 || b == 0x7F) {
                return Err(("INVALID_BEARER_VALUE", "bearer must be 1..=128 printable chars"));
            }
            Some(String::from(s))
        }
    };

    let kops = v73_2_opt_bounded_f64(obj, "kops", 0.0, 1_000_000.0, "INVALID_OR_OOB_KOPS")?;
    let p8_kops = v73_2_opt_bounded_f64(obj, "p8_kops", 0.0, 1_000_000.0, "INVALID_OR_OOB_P8_KOPS")?;
    let p10_kops = v73_2_opt_bounded_f64(obj, "pixel10_kops", 0.0, 1_000_000.0, "INVALID_OR_OOB_PIXEL10_KOPS")?;
    let p10_alias = v73_2_opt_bounded_f64(obj, "pixel10", 0.0, 1_000_000.0, "INVALID_OR_OOB_PIXEL10_KOPS")?;
    let p8_kops_full = v73_2_opt_bounded_f64(obj, "pixel8_kops", 0.0, 1_000_000.0, "INVALID_OR_OOB_PIXEL8_KOPS")?;
    let p8_alias = v73_2_opt_bounded_f64(obj, "pixel8", 0.0, 1_000_000.0, "INVALID_OR_OOB_PIXEL8_KOPS")?;
    let loq_kops = v73_2_opt_bounded_f64(obj, "loq15_kops", 0.0, 1_000_000.0, "INVALID_OR_OOB_LOQ15_KOPS")?;
    let loq_alias = v73_2_opt_bounded_f64(obj, "loq15", 0.0, 1_000_000.0, "INVALID_OR_OOB_LOQ15_KOPS")?;
    let anchor1_alias = v73_2_opt_bounded_f64(obj, "anchor1_kops", 0.0, 1_000_000.0, "INVALID_OR_OOB_LOQ15_KOPS")?;

    let p8_free = v73_2_opt_bounded_f64(obj, "p8_free", 0.0, 1_000_000.0, "INVALID_OR_OOB_P8_FREE")?;
    let col = v73_2_opt_strict_bounded_u64(obj, "col", 1_919, "INVALID_OR_OOB_COL")?;
    let mx = v73_2_opt_bounded_f64(obj, "mx", -100_000.0, 100_000.0, "INVALID_OR_OOB_MAG")?;
    let my = v73_2_opt_bounded_f64(obj, "my", -100_000.0, 100_000.0, "INVALID_OR_OOB_MAG")?;
    let mz = v73_2_opt_bounded_f64(obj, "mz", -100_000.0, 100_000.0, "INVALID_OR_OOB_MAG")?;
    let bn = v73_2_opt_bounded_f64(obj, "bn", 0.0, 1_000_000.0, "INVALID_OR_OOB_BN")?;
    let baro = v73_2_opt_bounded_f64(obj, "baro", 300.0, 1_200.0, "INVALID_OR_OOB_BARO")?;
    let lux = v73_2_opt_bounded_f64(obj, "lux", 0.0, 1_000_000.0, "INVALID_OR_OOB_LUX")?;
    let acc = v73_2_opt_bounded_f64(obj, "acc", 0.0, 1_000_000.0, "INVALID_OR_OOB_ACC")?;
    let gyro = v73_2_opt_bounded_f64(obj, "gyro", 0.0, 1_000_000.0, "INVALID_OR_OOB_GYRO")?;
    let temp = v73_2_opt_bounded_f64(obj, "temp", -40.0, 150.0, "INVALID_OR_OOB_TEMP")?;
    let mv = v73_2_opt_bounded_u64(obj, "mv", 10_000, "INVALID_OR_OOB_MV")?;
    let bat = v73_2_opt_bounded_u64(obj, "bat", 100, "INVALID_OR_OOB_BAT")?;
    let ram_u = v73_2_opt_bounded_u64(obj, "ram_u", 1_048_576, "INVALID_OR_OOB_RAM_U")?;
    let ram_t = v73_2_opt_bounded_u64(obj, "ram_t", 1_048_576, "INVALID_OR_OOB_RAM_T")?;
    let shz = v73_2_opt_bounded_f64(obj, "shz", 0.0, 1_000_000.0, "INVALID_OR_OOB_SHZ")?;
    let thz = v73_2_opt_bounded_f64(obj, "thz", 0.0, 1_000_000.0, "INVALID_OR_OOB_THZ")?;
    let rtt = v73_2_opt_bounded_f64(obj, "rtt", 0.0, 1_000_000.0, "INVALID_OR_OOB_RTT")?;

    let pixel10_kops = p10_kops.or(p10_alias);
    let pixel8_kops = p8_kops_full.or(p8_alias);
    let loq15_kops = loq_kops.or(loq_alias).or(anchor1_alias);

    let has_any_metric = kops.is_some()
        || p8_kops.is_some()
        || pixel10_kops.is_some()
        || pixel8_kops.is_some()
        || loq15_kops.is_some()
        || p8_free.is_some()
        || col.is_some()
        || mx.is_some()
        || my.is_some()
        || mz.is_some()
        || bn.is_some()
        || baro.is_some()
        || lux.is_some()
        || acc.is_some()
        || gyro.is_some()
        || temp.is_some()
        || mv.is_some()
        || bat.is_some()
        || ram_u.is_some()
        || ram_t.is_some()
        || shz.is_some()
        || thz.is_some()
        || rtt.is_some()
        || bearer.is_some();

    if !has_any_metric {
        return Err(("EMPTY_TELEMETRY_METRICS", "At least one bounded telemetry metric is required"));
    }

    Ok(V732TelemetryIngestPayload {
        node,
        kops,
        p8_kops,
        pixel10_kops,
        pixel8_kops,
        loq15_kops,
        p8_free,
        col,
        mx,
        my,
        mz,
        bn,
        baro,
        lux,
        acc,
        gyro,
        temp,
        mv,
        bat,
        ram_u,
        ram_t,
        shz,
        thz,
        rtt,
        bearer,
    })
}

pub const SOVEREIGN_LEAN4_MIN_THEOREMS: usize = 1010;

pub fn count_live_lean_theorems_at_path(path: &str) -> Option<usize> {
    let txt = fs::read_to_string(path).ok()?;
    let count = txt
        .lines()
        .filter(|l| {
            let trimmed = l.trim_start();
            !trimmed.starts_with("--") && trimmed.starts_with("theorem ")
        })
        .count();
    Some(count)
}

pub fn count_live_lean_theorems_canonical() -> Option<usize> {
    count_live_lean_theorems_at_path("03_vault/lean4/SovereignManifoldTheorems.lean")
        .or_else(|| count_live_lean_theorems_at_path("C:\\sovereign_manifold_v31\\03_vault\\lean4\\SovereignManifoldTheorems.lean"))
}

pub fn validate_live_lean_threshold(measured_theorems: usize, live_lean_count: usize) -> bool {
    measured_theorems >= SOVEREIGN_LEAN4_MIN_THEOREMS
        && live_lean_count >= SOVEREIGN_LEAN4_MIN_THEOREMS
        && measured_theorems == live_lean_count
}

pub fn validate_live_lean_theorems_with_floor(measured_theorems: usize) -> bool {
    match count_live_lean_theorems_canonical() {
        Some(live_count) => validate_live_lean_threshold(measured_theorems, live_count),
        None => false,
    }
}

pub fn v73_2_count_live_lean_theorems() -> usize {
    count_live_lean_theorems_canonical().unwrap_or(0)
}

pub struct V732LiveOtaMetadata {
    pub ota_version: String,
    pub tlv_schema: u64,
    pub tools_count: u64,
    pub lean4_qed: usize,
    pub shards: u64,
    pub expansion_shards: u64,
    pub tier3_shards: u64,
    pub tier4_shards: u64,
    pub combined_shards: u64,
    pub total_synapses: u64,
    pub bijected_cachelines: u64,
    pub chair44_cols: u64,
}

fn v73_2_file_len_dual(rel: &str, abs: &str) -> u64 {
    fs::metadata(rel)
        .or_else(|_| fs::metadata(abs))
        .map(|m| m.len())
        .unwrap_or(0)
}

pub fn v73_2_read_live_release_version() -> String {
    if let Ok(gemini) = fs::read_to_string("GEMINI.md")
        .or_else(|_| fs::read_to_string("C:\\sovereign_manifold_v31\\GEMINI.md"))
    {
        if let Some(first_line) = gemini.lines().next() {
            let ver_tok = first_line
                .split("ACT-Omega Net ")
                .nth(1)
                .and_then(|s| s.split_whitespace().next())
                .map(|s| s.trim_matches(|c: char| c == '(' || c == ')' || c == '|'))
                .unwrap_or("");
            if !ver_tok.is_empty() {
                return String::from(ver_tok);
            }
        }
    }
    if let Ok(cit) = fs::read_to_string("CITATION.cff")
        .or_else(|_| fs::read_to_string("C:\\sovereign_manifold_v31\\CITATION.cff"))
    {
        for line in cit.lines() {
            if let Some(rest) = line.trim_start().strip_prefix("version:") {
                let v = rest.trim().trim_matches('"').trim_matches('\'');
                if !v.is_empty() {
                    return format!("v{}", v);
                }
            }
        }
    }
    String::from("UNMEASURED/OFFLINE")
}

pub fn v73_2_read_live_ota_metadata() -> V732LiveOtaMetadata {
    let live_release_ver = v73_2_read_live_release_version();
    let mut ota_version = live_release_ver.clone();
    let mut tlv_schema: u64 = 0;
    let mut tools_count: u64 = 0;

    if let Ok(gemini) = fs::read_to_string("GEMINI.md")
        .or_else(|_| fs::read_to_string("C:\\sovereign_manifold_v31\\GEMINI.md"))
    {
        if let Some(first_line) = gemini.lines().next() {
            let sh4z_tok = first_line
                .split("SH4Z ")
                .nth(1)
                .and_then(|s| s.split_whitespace().next())
                .map(|s| s.trim_matches(|c: char| c == '(' || c == ')' || c == '|'))
                .unwrap_or("");
            if live_release_ver != "UNMEASURED/OFFLINE" && !sh4z_tok.is_empty() {
                ota_version = format!("{}-sh4z-{}", live_release_ver, sh4z_tok);
            }
            let digits: String = sh4z_tok.chars().filter(|c| c.is_ascii_digit()).collect();
            if let Ok(n) = digits.parse::<u64>() {
                tlv_schema = n;
            }
            if let Some(chain_tok) = first_line
                .split("CHAIN ")
                .nth(1)
                .and_then(|s| s.split_whitespace().next())
            {
                let c_digits: String = chain_tok.chars().filter(|c| c.is_ascii_digit()).collect();
                if let Ok(n) = c_digits.parse::<u64>() {
                    tools_count = n;
                }
            }
        }
    }

    let lean4_qed = v73_2_count_live_lean_theorems();
    let rec_bytes = crate::v69_0_omegalang_v16_primary_tlv_compiler_and_84480_connectome::V69_NPAGE_RECORD_BYTES as u64;
    let prim_syn_per_neuron = crate::v69_0_omegalang_v16_primary_tlv_compiler_and_84480_connectome::V69_PRIMARY_SYNAPSES_PER_NEURON as u64;
    let neurons_per_col = crate::v69_0_omegalang_v16_primary_tlv_compiler_and_84480_connectome::V69_NEURONS_PER_COLUMN as u64;

    let core_b = v73_2_file_len_dual(
        "00_control/weights/neurons_v4000.npage",
        "C:\\sovereign_manifold_v31\\00_control\\weights\\neurons_v4000.npage",
    );
    let exp_b = v73_2_file_len_dual(
        "00_control/weights/neurons_v4400_expansion.npage",
        "C:\\sovereign_manifold_v31\\00_control\\weights\\neurons_v4400_expansion.npage",
    );
    let t3_b = v73_2_file_len_dual(
        "00_control/weights/neurons_v5000_tier3_expansion.npage",
        "C:\\sovereign_manifold_v31\\00_control\\weights\\neurons_v5000_tier3_expansion.npage",
    );
    let t4_b = v73_2_file_len_dual(
        "00_control/weights/neurons_v6900_tier4_expansion.npage",
        "C:\\sovereign_manifold_v31\\00_control\\weights\\neurons_v6900_tier4_expansion.npage",
    );
    let npage_b = v73_2_file_len_dual(
        "00_control/weights/neurons_v6900_84480.npage",
        "C:\\sovereign_manifold_v31\\00_control\\weights\\neurons_v6900_84480.npage",
    );
    let spage_b = v73_2_file_len_dual(
        "00_control/weights/synapses_v6900_2703360.spage",
        "C:\\sovereign_manifold_v31\\00_control\\weights\\synapses_v6900_2703360.spage",
    );
    let e8z_b = v73_2_file_len_dual(
        "00_control/weights/sovereign_harmonic_viii_v6900_8704cl.e8z",
        "C:\\sovereign_manifold_v31\\00_control\\weights\\sovereign_harmonic_viii_v6900_8704cl.e8z",
    );

    let shards = core_b / rec_bytes;
    let expansion_shards = exp_b / rec_bytes;
    let tier3_shards = t3_b / rec_bytes;
    let tier4_shards = t4_b / rec_bytes;
    let combined_shards = npage_b / rec_bytes;
    let total_synapses = (combined_shards * prim_syn_per_neuron) + (spage_b / 2);
    let bijected_cachelines = (npage_b + spage_b + e8z_b) / 64;
    let chair44_cols = if neurons_per_col > 0 { combined_shards / neurons_per_col } else { 0 };

    V732LiveOtaMetadata {
        ota_version,
        tlv_schema,
        tools_count,
        lean4_qed,
        shards,
        expansion_shards,
        tier3_shards,
        tier4_shards,
        combined_shards,
        total_synapses,
        bijected_cachelines,
        chair44_cols,
    }
}

pub fn v73_2_dispatch_tool(tool_id: u64, payload: &str) -> String {
    match tool_id {
        400 => v73_2_dispatch_tool_400_vpc_registry_probe(payload),
        401 => v73_2_dispatch_tool_401_mesh_device_roster(payload),
        402 => v73_2_dispatch_tool_402_pgwire_duckdb_audit(payload),
        403 => v73_2_dispatch_tool_403_hyperdrive_duckdb_query(payload),
        404 => v73_2_dispatch_chain404_master_certification(payload),
        _ => format!("{{\"ok\":false,\"status\":\"UNKNOWN_V73_2_TOOL\",\"tool_id\":{}}}", tool_id),
    }
}

fn v73_2_read_u16_le(buf: &Vec<u8>, off: usize) -> Option<u16> {
    let b0 = *buf.get(off)? as u16;
    let b1 = *buf.get(off.checked_add(1)?)? as u16;
    Some(b0 | (b1 << 8))
}

fn v73_2_read_u32_le(buf: &Vec<u8>, off: usize) -> Option<u32> {
    let b0 = *buf.get(off)? as u32;
    let b1 = *buf.get(off.checked_add(1)?)? as u32;
    let b2 = *buf.get(off.checked_add(2)?)? as u32;
    let b3 = *buf.get(off.checked_add(3)?)? as u32;
    Some(b0 | (b1 << 8) | (b2 << 16) | (b3 << 24))
}

fn v73_2_read_u64_le(buf: &Vec<u8>, off: usize) -> Option<u64> {
    let lo = v73_2_read_u32_le(buf, off)? as u64;
    let hi = v73_2_read_u32_le(buf, off.checked_add(4)?)? as u64;
    Some(lo | (hi << 32))
}

struct V732DeflateBitReader<'a> {
    src: &'a Vec<u8>,
    byte_pos: usize,
    bit_buf: u32,
    bit_cnt: u8,
}

impl<'a> V732DeflateBitReader<'a> {
    fn new(src: &'a Vec<u8>) -> Self {
        Self {
            src,
            byte_pos: 0,
            bit_buf: 0,
            bit_cnt: 0,
        }
    }

    fn ensure_bits(&mut self, n: u8) -> Option<()> {
        while self.bit_cnt < n {
            let b = *self.src.get(self.byte_pos)? as u32;
            self.byte_pos += 1;
            self.bit_buf |= b << self.bit_cnt;
            self.bit_cnt += 8;
        }
        Some(())
    }

    fn read_bits(&mut self, n: u8) -> Option<u32> {
        if n == 0 {
            return Some(0);
        }
        self.ensure_bits(n)?;
        let mask = (1u32 << n) - 1;
        let val = self.bit_buf & mask;
        self.bit_buf >>= n;
        self.bit_cnt -= n;
        Some(val)
    }

    fn align_to_byte(&mut self) {
        let rem = self.bit_cnt % 8;
        if rem > 0 {
            self.bit_buf >>= rem;
            self.bit_cnt -= rem;
        }
    }

    fn read_aligned_u16_le(&mut self) -> Option<u16> {
        self.align_to_byte();
        let b0 = self.read_bits(8)? as u16;
        let b1 = self.read_bits(8)? as u16;
        Some(b0 | (b1 << 8))
    }
}

struct V732HuffTree {
    counts: Vec<u16>,
    symbols: Vec<u16>,
}

impl V732HuffTree {
    fn build(code_lengths: &Vec<u8>) -> Option<Self> {
        let mut counts: Vec<u16> = Vec::new();
        counts.resize(16, 0);
        for &len in code_lengths {
            let l = len as usize;
            if l > 15 {
                return None;
            }
            if l > 0 {
                let slot = counts.get_mut(l)?;
                *slot = slot.checked_add(1)?;
            }
        }
        let mut left: i32 = 1;
        let mut bits: usize = 1;
        while bits <= 15 {
            left <<= 1;
            left -= *counts.get(bits)? as i32;
            if left < 0 {
                return None;
            }
            bits += 1;
        }
        let mut offsets: Vec<u16> = Vec::new();
        offsets.resize(16, 0);
        let mut total: u16 = 0;
        let mut b: usize = 1;
        while b <= 15 {
            if let Some(o) = offsets.get_mut(b) {
                *o = total;
            }
            total = total.checked_add(*counts.get(b)?)?;
            b += 1;
        }
        let mut symbols: Vec<u16> = Vec::new();
        symbols.resize(total as usize, 0);
        let mut sym_idx: usize = 0;
        for &len in code_lengths {
            let l = len as usize;
            if l > 0 {
                let wp_slot = offsets.get_mut(l)?;
                let wp = *wp_slot as usize;
                *wp_slot = wp_slot.checked_add(1)?;
                if let Some(dst) = symbols.get_mut(wp) {
                    *dst = sym_idx as u16;
                }
            }
            sym_idx += 1;
        }
        Some(Self { counts, symbols })
    }

    fn decode(&self, reader: &mut V732DeflateBitReader) -> Option<u16> {
        let mut code: i32 = 0;
        let mut first: i32 = 0;
        let mut index: i32 = 0;
        let mut len: usize = 1;
        while len <= 15 {
            code |= reader.read_bits(1)? as i32;
            let count = *self.counts.get(len)? as i32;
            if code - count < first {
                let sym_pos = (index + (code - first)) as usize;
                return self.symbols.get(sym_pos).copied();
            }
            index += count;
            first += count;
            first <<= 1;
            code <<= 1;
            len += 1;
        }
        None
    }
}

fn v73_2_deflate_cl_order(idx: usize) -> Option<usize> {
    match idx {
        0 => Some(16),
        1 => Some(17),
        2 => Some(18),
        3 => Some(0),
        4 => Some(8),
        5 => Some(7),
        6 => Some(9),
        7 => Some(6),
        8 => Some(10),
        9 => Some(5),
        10 => Some(11),
        11 => Some(4),
        12 => Some(12),
        13 => Some(3),
        14 => Some(13),
        15 => Some(2),
        16 => Some(14),
        17 => Some(1),
        18 => Some(15),
        _ => None,
    }
}

fn v73_2_deflate_len_base_extra(sym: u16) -> Option<(usize, u8)> {
    match sym {
        257 => Some((3, 0)),
        258 => Some((4, 0)),
        259 => Some((5, 0)),
        260 => Some((6, 0)),
        261 => Some((7, 0)),
        262 => Some((8, 0)),
        263 => Some((9, 0)),
        264 => Some((10, 0)),
        265 => Some((11, 1)),
        266 => Some((13, 1)),
        267 => Some((15, 1)),
        268 => Some((17, 1)),
        269 => Some((19, 2)),
        270 => Some((23, 2)),
        271 => Some((27, 2)),
        272 => Some((31, 2)),
        273 => Some((35, 3)),
        274 => Some((43, 3)),
        275 => Some((51, 3)),
        276 => Some((59, 3)),
        277 => Some((67, 4)),
        278 => Some((83, 4)),
        279 => Some((99, 4)),
        280 => Some((115, 4)),
        281 => Some((131, 5)),
        282 => Some((163, 5)),
        283 => Some((195, 5)),
        284 => Some((227, 5)),
        285 => Some((258, 0)),
        _ => None,
    }
}

fn v73_2_deflate_dist_base_extra(sym: u16) -> Option<(usize, u8)> {
    if sym <= 3 {
        Some((sym as usize + 1, 0))
    } else if sym <= 29 {
        let extra = ((sym - 2) / 2) as u8;
        let base = 1usize + ((2usize + ((sym as usize) & 1usize)) << (extra as usize));
        Some((base, extra))
    } else {
        None
    }
}

fn v73_2_build_fixed_trees() -> Option<(V732HuffTree, V732HuffTree)> {
    let mut lit_lens: Vec<u8> = Vec::new();
    lit_lens.resize(288, 0);
    let mut i: usize = 0;
    while i < 288 {
        let val = if i <= 143 {
            8u8
        } else if i <= 255 {
            9u8
        } else if i <= 279 {
            7u8
        } else {
            8u8
        };
        if let Some(slot) = lit_lens.get_mut(i) {
            *slot = val;
        }
        i += 1;
    }
    let mut dist_lens: Vec<u8> = Vec::new();
    dist_lens.resize(32, 5);
    Some((V732HuffTree::build(&lit_lens)?, V732HuffTree::build(&dist_lens)?))
}

fn v73_2_build_dynamic_trees(reader: &mut V732DeflateBitReader) -> Option<(V732HuffTree, V732HuffTree)> {
    let hlit = (reader.read_bits(5)? as usize).checked_add(257)?;
    let hdist = (reader.read_bits(5)? as usize).checked_add(1)?;
    let hclen = (reader.read_bits(4)? as usize).checked_add(4)?;
    if hlit > 286 || hdist > 30 || hclen > 19 {
        return None;
    }
    let mut cl_lens: Vec<u8> = Vec::new();
    cl_lens.resize(19, 0);
    let mut i: usize = 0;
    while i < hclen {
        let ord = v73_2_deflate_cl_order(i)?;
        let v = reader.read_bits(3)? as u8;
        if let Some(slot) = cl_lens.get_mut(ord) {
            *slot = v;
        }
        i += 1;
    }
    let cl_tree = V732HuffTree::build(&cl_lens)?;
    let total_codes = hlit + hdist;
    let mut all_lens: Vec<u8> = Vec::with_capacity(total_codes);
    while all_lens.len() < total_codes {
        let sym = cl_tree.decode(reader)?;
        if sym < 16 {
            all_lens.push(sym as u8);
        } else if sym == 16 {
            let prev = *all_lens.last()?;
            let rep = (reader.read_bits(2)? as usize) + 3;
            if all_lens.len() + rep > total_codes {
                return None;
            }
            for _ in 0..rep {
                all_lens.push(prev);
            }
        } else if sym == 17 {
            let rep = (reader.read_bits(3)? as usize) + 3;
            if all_lens.len() + rep > total_codes {
                return None;
            }
            for _ in 0..rep {
                all_lens.push(0);
            }
        } else if sym == 18 {
            let rep = (reader.read_bits(7)? as usize) + 11;
            if all_lens.len() + rep > total_codes {
                return None;
            }
            for _ in 0..rep {
                all_lens.push(0);
            }
        } else {
            return None;
        }
    }
    let lit_lens = all_lens.get(0..hlit)?.to_vec();
    let dist_lens = all_lens.get(hlit..total_codes)?.to_vec();
    Some((V732HuffTree::build(&lit_lens)?, V732HuffTree::build(&dist_lens)?))
}

fn v73_2_inflate_raw_deflate(comp: &Vec<u8>, expected_len: usize) -> Option<Vec<u8>> {
    if expected_len == 0 || expected_len > 16 * 1024 * 1024 {
        return None;
    }
    let mut reader = V732DeflateBitReader::new(comp);
    let mut out: Vec<u8> = Vec::with_capacity(expected_len);
    loop {
        let bfinal = reader.read_bits(1)?;
        let btype = reader.read_bits(2)?;
        if btype == 0 {
            let len = reader.read_aligned_u16_le()? as usize;
            let nlen = reader.read_aligned_u16_le()?;
            if (len as u16) ^ 0xFFFF != nlen {
                return None;
            }
            if out.len().checked_add(len)? > expected_len {
                return None;
            }
            for _ in 0..len {
                out.push(reader.read_bits(8)? as u8);
            }
        } else if btype == 1 || btype == 2 {
            let (lit_tree, dist_tree) = if btype == 1 {
                v73_2_build_fixed_trees()?
            } else {
                v73_2_build_dynamic_trees(&mut reader)?
            };
            loop {
                let sym = lit_tree.decode(&mut reader)?;
                if sym < 256 {
                    if out.len() >= expected_len {
                        return None;
                    }
                    out.push(sym as u8);
                } else if sym == 256 {
                    break;
                } else {
                    let (len_base, len_extra) = v73_2_deflate_len_base_extra(sym)?;
                    let length = len_base + (reader.read_bits(len_extra)? as usize);
                    let dist_sym = dist_tree.decode(&mut reader)?;
                    let (dist_base, dist_extra) = v73_2_deflate_dist_base_extra(dist_sym)?;
                    let dist = dist_base + (reader.read_bits(dist_extra)? as usize);
                    if dist == 0 || dist > out.len() || out.len().checked_add(length)? > expected_len {
                        return None;
                    }
                    for _ in 0..length {
                        let copy_idx = out.len() - dist;
                        let b = *out.get(copy_idx)?;
                        out.push(b);
                    }
                }
            }
        } else {
            return None;
        }
        if bfinal == 1 {
            break;
        }
    }
    if out.len() != expected_len {
        return None;
    }
    Some(out)
}

fn v73_2_parse_axml_version_code(axml: &Vec<u8>) -> Option<u32> {
    if axml.len() < 8 {
        return None;
    }
    let root_type = v73_2_read_u16_le(axml, 0)?;
    let root_hdr_sz = v73_2_read_u16_le(axml, 2)? as usize;
    let root_total_sz = v73_2_read_u32_le(axml, 4)? as usize;
    if root_type != 0x0003 || root_hdr_sz < 8 || root_total_sz > axml.len() || root_hdr_sz > root_total_sz {
        return None;
    }

    let mut pos = root_hdr_sz;
    let mut ver_code_res_idx: Option<i32> = None;

    while pos.checked_add(8)? <= root_total_sz {
        let c_type = v73_2_read_u16_le(axml, pos)?;
        let c_hdr_sz = v73_2_read_u16_le(axml, pos + 2)? as usize;
        let c_sz = v73_2_read_u32_le(axml, pos + 4)? as usize;
        if c_sz < 8 || c_hdr_sz < 8 || c_hdr_sz > c_sz || pos.checked_add(c_sz)? > root_total_sz {
            return None;
        }

        if c_type == 0x0180 {
            let map_start = pos.checked_add(c_hdr_sz)?;
            let map_end = pos.checked_add(c_sz)?;
            let mut r_pos = map_start;
            let mut r_idx: i32 = 0;
            while r_pos.checked_add(4)? <= map_end {
                let res_id = v73_2_read_u32_le(axml, r_pos)?;
                if res_id == 0x0101_021B {
                    ver_code_res_idx = Some(r_idx);
                    break;
                }
                r_pos += 4;
                r_idx += 1;
            }
        } else if c_type == 0x0102 {
            let ext_base = pos.checked_add(c_hdr_sz)?;
            let chunk_end = pos.checked_add(c_sz)?;
            if ext_base.checked_add(20)? > chunk_end {
                return None;
            }
            let attr_start = v73_2_read_u16_le(axml, ext_base + 8)? as usize;
            let attr_size = v73_2_read_u16_le(axml, ext_base + 10)? as usize;
            let attr_count = v73_2_read_u16_le(axml, ext_base + 12)? as usize;
            if let Some(target_idx) = ver_code_res_idx {
                if attr_size >= 20 {
                    let attrs_base = ext_base.checked_add(attr_start)?;
                    for ai in 0..attr_count {
                        let a_off = attrs_base.checked_add(ai.checked_mul(attr_size)?)?;
                        if a_off.checked_add(20)? > chunk_end {
                            return None;
                        }
                        let name_idx = v73_2_read_u32_le(axml, a_off + 4)? as i32;
                        let val_type = *axml.get(a_off + 15)?;
                        let val_data = v73_2_read_u32_le(axml, a_off + 16)?;
                        if name_idx == target_idx && (val_type == 0x10 || val_type == 0x11) {
                            return Some(val_data);
                        }
                    }
                }
            }
            return None;
        }
        pos = pos.checked_add(c_sz)?;
    }
    None
}

pub fn v73_2_extract_apk_version_code(apk_bytes: &Vec<u8>) -> Option<u32> {
    if apk_bytes.len() < 22 {
        return None;
    }
    let min_eocd = apk_bytes.len().saturating_sub(22 + 65_535);
    let mut eocd_pos_opt: Option<usize> = None;
    let mut scan = apk_bytes.len() - 22;
    loop {
        if v73_2_read_u32_le(apk_bytes, scan) == Some(0x0605_4B50) {
            let cmt_len = v73_2_read_u16_le(apk_bytes, scan + 20)? as usize;
            if scan + 22 + cmt_len == apk_bytes.len() {
                eocd_pos_opt = Some(scan);
                break;
            }
        }
        if scan == min_eocd {
            break;
        }
        scan -= 1;
    }
    let eocd_pos = eocd_pos_opt?;
    let mut total_entries = v73_2_read_u16_le(apk_bytes, eocd_pos + 10)? as usize;
    let mut cd_size = v73_2_read_u32_le(apk_bytes, eocd_pos + 12)? as usize;
    let mut cd_offset = v73_2_read_u32_le(apk_bytes, eocd_pos + 16)? as usize;

    if total_entries == 0xFFFF || cd_size == 0xFFFF_FFFF || cd_offset == 0xFFFF_FFFF {
        if eocd_pos < 20 {
            return None;
        }
        let loc_pos = eocd_pos - 20;
        if v73_2_read_u32_le(apk_bytes, loc_pos) != Some(0x0706_4B50) {
            return None;
        }
        let z64_off = v73_2_read_u64_le(apk_bytes, loc_pos + 8)? as usize;
        if z64_off.checked_add(56)? > loc_pos || v73_2_read_u32_le(apk_bytes, z64_off) != Some(0x0606_4B50) {
            return None;
        }
        total_entries = v73_2_read_u64_le(apk_bytes, z64_off + 32)? as usize;
        cd_size = v73_2_read_u64_le(apk_bytes, z64_off + 40)? as usize;
        cd_offset = v73_2_read_u64_le(apk_bytes, z64_off + 48)? as usize;
    }

    let cd_end = cd_offset.checked_add(cd_size)?;
    if cd_end > eocd_pos {
        return None;
    }

    let mut pos = cd_offset;
    for _ in 0..total_entries {
        if pos.checked_add(46)? > cd_end {
            return None;
        }
        if v73_2_read_u32_le(apk_bytes, pos) != Some(0x0201_4B50) {
            return None;
        }
        let comp_method = v73_2_read_u16_le(apk_bytes, pos + 10)?;
        let comp_size = v73_2_read_u32_le(apk_bytes, pos + 20)? as usize;
        let uncomp_size = v73_2_read_u32_le(apk_bytes, pos + 24)? as usize;
        let fname_len = v73_2_read_u16_le(apk_bytes, pos + 28)? as usize;
        let extra_len = v73_2_read_u16_le(apk_bytes, pos + 30)? as usize;
        let cmt_len = v73_2_read_u16_le(apk_bytes, pos + 32)? as usize;
        let lfh_offset = v73_2_read_u32_le(apk_bytes, pos + 42)? as usize;

        let name_start = pos.checked_add(46)?;
        let name_end = name_start.checked_add(fname_len)?;
        if name_end > cd_end {
            return None;
        }
        if apk_bytes.get(name_start..name_end) == Some(b"AndroidManifest.xml") {
            if lfh_offset.checked_add(30)? > cd_offset
                || v73_2_read_u32_le(apk_bytes, lfh_offset) != Some(0x0403_4B50)
            {
                return None;
            }
            let lfh_fname_len = v73_2_read_u16_le(apk_bytes, lfh_offset + 26)? as usize;
            let lfh_extra_len = v73_2_read_u16_le(apk_bytes, lfh_offset + 28)? as usize;
            let data_start = lfh_offset
                .checked_add(30)?
                .checked_add(lfh_fname_len)?
                .checked_add(lfh_extra_len)?;
            let data_end = data_start.checked_add(comp_size)?;
            if data_end > cd_offset {
                return None;
            }
            let comp_vec = apk_bytes.get(data_start..data_end)?.to_vec();
            let axml = if comp_method == 0 {
                if comp_vec.len() != uncomp_size {
                    return None;
                }
                comp_vec
            } else if comp_method == 8 {
                v73_2_inflate_raw_deflate(&comp_vec, uncomp_size)?
            } else {
                return None;
            };
            return v73_2_parse_axml_version_code(&axml);
        }
        pos = name_end.checked_add(extra_len)?.checked_add(cmt_len)?;
    }
    None
}

pub const V73_2_CF_LIVE_VERIFICATION_REL_PATH: &str = "03_vault/receipts/s6_cloudflare_live_wrangler_verification.txt";
pub const V73_2_CF_LIVE_VERIFICATION_ABS_PATH: &str = "C:\\sovereign_manifold_v31\\03_vault\\receipts\\s6_cloudflare_live_wrangler_verification.txt";

pub fn v73_2_read_live_d1_database_name() -> Option<String> {
    let txt = fs::read_to_string(V73_2_CF_LIVE_VERIFICATION_REL_PATH)
        .or_else(|_| fs::read_to_string(V73_2_CF_LIVE_VERIFICATION_ABS_PATH))
        .ok()?;
    for line in txt.lines() {
        if let Some(rest) = line.trim_start().strip_prefix("d1_active_database:") {
            let db = rest.trim();
            if !db.is_empty() {
                return Some(String::from(db));
            }
        }
    }
    None
}

pub fn v73_2_parse_d1_user_tables_from_receipt_str(txt: &str) -> (Option<usize>, Vec<String>) {
    let marker = "SELECT name, type FROM sqlite_master";
    let after_marker = match txt.find(marker) {
        Some(pos) => match txt.get(pos..) {
            Some(s) => s,
            None => return (None, Vec::new()),
        },
        None => return (None, Vec::new()),
    };
    let after_cmd_line = match after_marker.find('\n') {
        Some(nl) => match after_marker.get((nl + 1)..) {
            Some(s) => s,
            None => return (None, Vec::new()),
        },
        None => return (None, Vec::new()),
    };
    let section_end = after_cmd_line.find("\n=== ").unwrap_or(after_cmd_line.len());
    let section_body = match after_cmd_line.get(..section_end) {
        Some(s) => s,
        None => return (None, Vec::new()),
    };
    let obj_start = match section_body.find('{') {
        Some(i) => i,
        None => return (None, Vec::new()),
    };
    let obj_slice = match section_body.get(obj_start..) {
        Some(s) => s.trim_end().trim_end_matches(|c: char| c != '}'),
        None => return (None, Vec::new()),
    };
    let parsed: serde_json::Value = match serde_json::from_str(obj_slice) {
        Ok(v) => v,
        Err(_) => return (None, Vec::new()),
    };
    if parsed.get("success").and_then(|b| b.as_bool()) != Some(true) {
        return (None, Vec::new());
    }
    let rows = match parsed.get("results").and_then(|r| r.as_array()) {
        Some(arr) => arr,
        None => return (None, Vec::new()),
    };
    let mut user_tables: Vec<String> = Vec::new();
    for row in rows {
        let row_type = row.get("type").and_then(|t| t.as_str()).unwrap_or("");
        let name = row.get("name").and_then(|n| n.as_str()).unwrap_or("").trim();
        if row_type == "table"
            && !name.is_empty()
            && !name.starts_with("_cf_")
            && !name.starts_with("sqlite_")
        {
            user_tables.push(String::from(name));
        }
    }
    user_tables.sort();
    user_tables.dedup();
    if user_tables.is_empty() {
        (None, Vec::new())
    } else {
        (Some(user_tables.len()), user_tables)
    }
}

pub fn v73_2_read_live_d1_user_tables() -> (Option<usize>, Vec<String>) {
    let txt = match fs::read_to_string(V73_2_CF_LIVE_VERIFICATION_REL_PATH)
        .or_else(|_| fs::read_to_string(V73_2_CF_LIVE_VERIFICATION_ABS_PATH))
    {
        Ok(t) => t,
        Err(_) => return (None, Vec::new()),
    };
    v73_2_parse_d1_user_tables_from_receipt_str(&txt)
}
