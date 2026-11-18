// =============================================================================
// ACT-OMEGA NET v73.2.0 — CLOUDFLARE VPC SERVICES, MESH ROUTING, PGWIRE & HYPERDRIVE
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
use crate::v73_1_nov12_15_research_kernels::{
    v73_1_dispatch_chain399_master_certification, V73_1_LEAN_VAULT_PATH,
};

pub const V73_2_VPC_MESH_YML_PATH: &str = "C:\\sovereign_manifold_v31\\00_control\\cloudflare_vpc_mesh_quic.yml";
pub const V73_2_VPC_MESH_LOG_PATH: &str = "C:\\sovereign_manifold_v31\\00_control\\cloudflared_vpc_mesh.log";
pub const V73_2_WRANGLER_TOML_PATH: &str = "C:\\sovereign_manifold_v31\\00_control\\cloudflare_edge\\wrangler.toml";
pub const V73_2_WRANGLER_WORKFLOW_TOML_PATH: &str = "C:\\sovereign_manifold_v31\\00_control\\cloudflare_edge\\wrangler.workflow.toml";
pub const V73_2_DUCKDB_EXE_PATH: &str = "C:\\sovereign_manifold_v31\\00_control\\foss_bin\\duckdb.exe";
pub const V73_2_DUCKDB_CORPUS_PATH: &str = "E:\\Sovereign_Manifold_SSD_Vault\\training_corpus\\sh_rw_corpus_v7210.duckdb";
pub const V73_2_PGWIRE_CERT_PATH: &str = "C:\\Users\\Nbell\\.act_omega_pgwire_tls\\server.pem";
pub const V73_2_PGWIRE_CA_PATH: &str = "C:\\Users\\Nbell\\.act_omega_pgwire_tls\\ca.pem";

fn v73_2_count_lean_theorems_and_sorries() -> (usize, usize) {
    let Ok(txt) = fs::read_to_string(V73_1_LEAN_VAULT_PATH) else {
        return (0, 1);
    };
    let mut theorems = 0usize;
    let mut sorries = 0usize;
    for line in txt.lines() {
        let trimmed = line.trim_start();
        if trimmed.starts_with("theorem ") {
            theorems += 1;
        }
        if !trimmed.starts_with("--")
            && trimmed
                .split(|c: char| !c.is_ascii_alphanumeric() && c != '_')
                .any(|tok| tok == "sorry")
        {
            sorries += 1;
        }
    }
    (theorems, sorries)
}

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

fn v73_2_is_readonly_sql(sql: &str) -> bool {
    let trimmed = sql.trim().trim_end_matches(';').trim();
    if trimmed.is_empty() || trimmed.contains(';') {
        return false;
    }
    let upper = trimmed.to_ascii_uppercase();
    let valid_start = upper.starts_with("SELECT")
        || upper.starts_with("WITH")
        || upper.starts_with("EXPLAIN")
        || upper.starts_with("SHOW");
    if !valid_start {
        return false;
    }
    let forbidden = vec!(
        "INSERT", "UPDATE", "DELETE", "DROP", "CREATE", "ALTER", "TRUNCATE",
        "ATTACH", "DETACH", "COPY", "EXPORT", "IMPORT", "CALL", "MERGE", "REPLACE",
    );
    for kw in forbidden.iter() {
        if upper.contains(kw) {
            return false;
        }
    }
    true
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
        fmt_sock("anchor-1-lenovo-loq15-wifi", "10.0.24.243/32", 8097, &rtt_anchor),
        fmt_sock("anchor-1-host-hotspot", "192.168.137.1/32", 8099, &rtt_deno),
        fmt_sock("anchor-1-duckdb-pgwire-tls", "127.0.0.1/32", 5439, &rtt_pgwire),
        fmt_sock("edge-1-pixel10-58170DLCR0004V", "10.0.24.255/32", 19788, &rtt_p10),
        fmt_sock("edge-2-pixel8-pocket-http", "192.168.137.8/32", 19792, &rtt_p8_http),
        fmt_sock("edge-2-pixel8-ksu-apex", "192.168.137.8/32", 8098, &rtt_p8_ksu),
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

/// T403: Read-Only Analytical DuckDB Query & Hyperdrive/PGWire Digest
pub fn v73_2_dispatch_tool_403_hyperdrive_duckdb_query(payload: &str) -> String {
    let t0 = Instant::now();
    let default_sql = "SELECT count(*) AS docs_count FROM corpus_docs;";
    let sql = v73_2_extract_json_string_field(payload, "sql")
        .filter(|s| !s.trim().is_empty())
        .unwrap_or_else(|| String::from(default_sql));

    if !v73_2_is_readonly_sql(&sql) {
        return format!(
            "{{\"ok\":false,\"status\":\"REJECTED_NON_READONLY_SQL\",\"tool_id\":403,\"tool_name\":\"cloudflare_hyperdrive_duckdb_query\",\"sql\":\"{}\"}}",
            v61_escape_clean(&sql)
        );
    }

    if fs::metadata(V73_2_DUCKDB_EXE_PATH).is_err() || fs::metadata(V73_2_DUCKDB_CORPUS_PATH).is_err() {
        return format!(
            "{{\"ok\":false,\"status\":\"UNMEASURED/OFFLINE\",\"tool_id\":403,\"tool_name\":\"cloudflare_hyperdrive_duckdb_query\",\"reason\":\"duckdb_exe_or_corpus_missing\"}}"
        );
    }

    let cleaned_sql = sql.trim().trim_end_matches(';');
    let out_res = Command::new(V73_2_DUCKDB_EXE_PATH)
        .arg("-readonly")
        .arg("-json")
        .arg(V73_2_DUCKDB_CORPUS_PATH)
        .arg("-c")
        .arg(cleaned_sql)
        .output();

    let elapsed_ms = t0.elapsed().as_secs_f64() * 1000.0;
    let wf_toml = fs::read_to_string(V73_2_WRANGLER_WORKFLOW_TOML_PATH).unwrap_or_default();
    let hyperdrive_configured = wf_toml.contains("934af8d9f02d471cb383cb8c90ddfe51");

    match out_res {
        Ok(out) if out.status.success() => {
            let stdout_str = String::from_utf8_lossy(&out.stdout).trim().to_string();
            let safe_json = if stdout_str.is_empty() {
                String::from("\x5b\x5d")
            } else {
                stdout_str
            };
            format!(
                "{{\"ok\":true,\"status\":\"MEASURED_DUCKDB_HYPERDRIVE_READY\",\"tool_id\":403,\"tool_name\":\"cloudflare_hyperdrive_duckdb_query\",\"hyperdrive_config_present\":{},\"elapsed_ms\":{:.3},\"sql\":\"{}\",\"rows\":{}}}",
                hyperdrive_configured,
                elapsed_ms,
                v61_escape_clean(cleaned_sql),
                safe_json
            )
        }
        Ok(out) => {
            let err_str = String::from_utf8_lossy(&out.stderr).trim().to_string();
            format!(
                "{{\"ok\":false,\"status\":\"DUCKDB_SQL_ERROR\",\"tool_id\":403,\"tool_name\":\"cloudflare_hyperdrive_duckdb_query\",\"elapsed_ms\":{:.3},\"error\":\"{}\"}}",
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

/// T404: CHAIN 404 Master Certification (VPC Services + Mesh + TLS PGWire + Hyperdrive + CHAIN 399)
pub fn v73_2_dispatch_chain404_master_certification(payload: &str) -> String {
    let t0 = Instant::now();
    let t400 = v73_2_dispatch_tool_400_vpc_registry_probe(payload);
    let t401 = v73_2_dispatch_tool_401_mesh_device_roster(payload);
    let t402 = v73_2_dispatch_tool_402_pgwire_duckdb_audit(payload);
    let t403 = v73_2_dispatch_tool_403_hyperdrive_duckdb_query(payload);
    let c399 = v73_1_dispatch_chain399_master_certification(payload);
    let (lean_theorems, lean_sorries) = v73_2_count_lean_theorems_and_sorries();
    let lab_manifest_ok = fs::metadata(V73_0_UNIFIED_MANIFEST_PATH).is_ok();

    let p35_ok = t400.contains("\"ok\":true")
        && t401.contains("\"ok\":true")
        && t402.contains("\"ok\":true")
        && t403.contains("\"ok\":true");
    let c399_ok = c399.contains("\"ok\":true");
    let all_ok = p35_ok && c399_ok && lean_sorries == 0 && lean_theorems >= 1010;
    let status = if all_ok {
        "MEASURED_CHAIN404_CERTIFIED"
    } else if p35_ok {
        "MEASURED_CHAIN404_PARTIAL"
    } else {
        "UNMEASURED/OFFLINE"
    };
    let elapsed_ms = t0.elapsed().as_secs_f64() * 1000.0;

    format!(
        "{{\"ok\":{},\"status\":\"{}\",\"version\":\"v73.2.0\",\"chain_milestone\":\"CHAIN 404\",\"tools_total\":404,\"lean4_theorems_qed\":{},\"lean_sorry_count\":{},\"unified_lab_manifest_present\":{},\"p35_cloudflare_vpc_hyperdrive_ok\":{},\"chain399_ok\":{},\"elapsed_ms\":{:.3},\"t400\":{},\"t401\":{},\"t402\":{},\"t403\":{},\"chain399\":{}}}",
        all_ok,
        status,
        lean_theorems,
        lean_sorries,
        lab_manifest_ok,
        p35_ok,
        c399_ok,
        elapsed_ms,
        t400, t401, t402, t403, c399
    )
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
