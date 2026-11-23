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
