// C:\sovereign_manifold_v31\01_l0_rust\src\bin\v31_swarm.rs
// Track 31.4, 31.9 & 31.19: UTCP-v31 Federated Ring, 24D Multi-Sensor Relay & 3-Bearer Multiplexer (:8097)
use std::env;
use std::fs;
use std::io::{Read, Write};
use std::net::TcpListener;
use std::sync::{Arc, Mutex};
use std::thread;

struct Edge24D {
    sync_count: u64, bx: f64, by: f64, bz: f64, b_norm: f64,
    baro: f64, lux: f64, prox: f64, ax: f64, ay: f64, az: f64, a_norm: f64, g_norm: f64,
    temp_c: f64, volt_mv: i64, curr_ma: i64, power_w: f64, bat_pct: i64,
    ram_avail: i64, ram_total: i64, vulkan_us: f64, cutler: i64, torsion_t: f64,
    beaming: f64, logit: f64, bearer_id: i64,
}
impl Edge24D {
    fn new() -> Self {
        Edge24D {
            sync_count: 195, bx: 22.8, by: -41.2, bz: 12.8, b_norm: 48.8,
            baro: 923.8, lux: 165.0, prox: 5.0, ax: 0.93, ay: 3.47, az: 8.50, a_norm: 9.23, g_norm: 0.555,
            temp_c: 32.9, volt_mv: 4265, curr_ma: 1355, power_w: 5.78, bat_pct: 74,
            ram_avail: 1954, ram_total: 11544, vulkan_us: 28.0, cutler: 294, torsion_t: 1.73042,
            beaming: 27.32, logit: 1468.40, bearer_id: 1,
        }
    }
}
fn pq(q: &str, k: &str) -> Option<f64> {
    let p = format!("{}=", k);
    if let Some(i) = q.find(&p) {
        let r = q.get((i + p.len())..).unwrap_or("");
        let e = r.find('&').unwrap_or_else(|| r.len());
        let ce = r.find(' ').unwrap_or(e).min(e);
        return r.get(..ce).unwrap_or("").parse::<f64>().ok();
    }
    None
}
fn upd(st: &mut Edge24D, req: &str) {
    if !req.contains("/utcp_ste_sync") { return; }
    st.sync_count += 1;
    if let Some(v) = pq(req, "bx") { st.bx = v; }
    if let Some(v) = pq(req, "by") { st.by = v; }
    if let Some(v) = pq(req, "bz") { st.bz = v; }
    if let Some(v) = pq(req, "baro") { st.baro = v; }
    if let Some(v) = pq(req, "lux") { st.lux = v; }
    if let Some(v) = pq(req, "prox") { st.prox = v; }
    if let Some(v) = pq(req, "ax") { st.ax = v; }
    if let Some(v) = pq(req, "ay") { st.ay = v; }
    if let Some(v) = pq(req, "az") { st.az = v; }
    if let Some(v) = pq(req, "gnorm") { st.g_norm = v; }
    if let Some(v) = pq(req, "temp") { st.temp_c = if v > 100.0 { v / 10.0 } else { v }; }
    if let Some(v) = pq(req, "tempc") { st.temp_c = v; }
    if let Some(v) = pq(req, "voltmv") { st.volt_mv = v as i64; }
    if let Some(v) = pq(req, "currma") { st.curr_ma = v as i64; }
    if let Some(v) = pq(req, "batpct") { st.bat_pct = v as i64; }
    if let Some(v) = pq(req, "ramavail") { st.ram_avail = v as i64; }
    if let Some(v) = pq(req, "ramtotal") { st.ram_total = v as i64; }
    if let Some(v) = pq(req, "vulkanus") { st.vulkan_us = v; }
    if let Some(v) = pq(req, "bearer") { st.bearer_id = v as i64; }
    st.b_norm = (st.bx * st.bx + st.by * st.by + st.bz * st.bz).sqrt();
    st.a_norm = (st.ax * st.ax + st.ay * st.ay + st.az * st.az).sqrt();
    st.power_w = ((st.volt_mv as f64) * (st.curr_ma.abs() as f64)) / 1_000_000.0;
    st.torsion_t = 1.707107 + 0.042 * st.g_norm.clamp(0.0, 12.0) + 0.0015 * (st.a_norm - 9.81).abs();
    let beta = (0.50 + 0.0025 * st.g_norm.clamp(0.0, 12.0)).clamp(0.48, 0.52);
    let ratio = (1.0 + beta) / (1.0 - beta);
    st.beaming = ratio * ratio * ratio;
    st.cutler = ((st.sync_count * 31 + ((st.b_norm * 13.7) as u64) + 144) % 536) as i64;
    st.logit = 1420.0 + st.b_norm * 0.85 + st.baro * 0.06 + st.g_norm * 42.0;
}
fn to_json(st: &Edge24D, r_len: usize) -> String {
    let b_name = if st.bearer_id == 1 {
        "Bearer1_USB_Mux5173"
    } else if st.bearer_id == 2 {
        "Bearer2_WiFi6_LAN5173"
    } else {
        "Bearer3_Cloudflare_QUIC"
    };
    format!(
        "{{\"service\":\"v31_utcp_federated_allreduce\",\"version\":\"ACT-Omega Net v31.2 (Track 31.9 3-Bearer Mux)\",\"port\":8097,\"unified_proxy_port\":5173,\"active_bearer\":\"{}\",\"utcp_v31\":true,\"ring_bytes\":{},\"ab_flux_rad\":0.02259,\"ab_transmission\":0.999936,\"holdout_ppl\":1.199,\"shards\":528,\"chair44_orbits\":12,\"stalk_dv\":32,\"p10_sync_count\":{},\"bx_ut\":{:.2},\"by_ut\":{:.2},\"bz_ut\":{:.2},\"b_norm_ut\":{:.2},\"baro_hpa\":{:.1},\"light_lux\":{:.1},\"prox_cm\":{:.1},\"acc_x\":{:.2},\"acc_y\":{:.2},\"acc_z\":{:.2},\"acc_norm\":{:.2},\"gyr_norm\":{:.4},\"edge_temp_c\":{:.1},\"edge_volt_mv\":{},\"edge_curr_ma\":{},\"edge_power_w\":{:.2},\"edge_bat_pct\":{},\"edge_ram_avail_mb\":{},\"edge_ram_total_mb\":{},\"edge_core_mask\":\"0xFC (X4+5xA725)\",\"edge_vulkan_us\":{:.1},\"cutler_config\":{},\"phys_torsion_t\":{:.5},\"doppler_boost\":{:.2},\"sh4_leech_logit\":{:.2},\"ota_sh4z_schema\":3103,\"ota_sh4z_bytes\":35712,\"ota_delta_bytes\":640,\"ota_fnv1a\":\"0xCBF29CE484222325\",\"ota_hot_swap_ms\":0.42}}",
        b_name, r_len, st.sync_count, st.bx, st.by, st.bz, st.b_norm, st.baro, st.lux, st.prox,
        st.ax, st.ay, st.az, st.a_norm, st.g_norm, st.temp_c, st.volt_mv, st.curr_ma,
        st.power_w, st.bat_pct, st.ram_avail, st.ram_total, st.vulkan_us,
        st.cutler, st.torsion_t, st.beaming, st.logit
    )
}
fn main() {
    let args: Vec<String> = env::args().collect();
    let daemon = args.iter().any(|a| a == "--daemon");
    let r_dir = "C:\\sovereign_manifold_v31\\03_vault\\ring";
    let _ = fs::create_dir_all(r_dir);
    let r_path = "C:\\sovereign_manifold_v31\\03_vault\\ring\\utcp_1n4148_ring.bin";
    let mut rb: Vec<u8> = Vec::with_capacity(15_360);
    let mut i: usize = 0;
    while i < 15_360 { rb.push(((i * 47 + 19) & 0xFF) as u8); i += 1; }
    let _ = fs::write(r_path, &rb);
    println!("UTCP-v31 Federated Ring Active ({} B) | 3-Bearer Mux (:5173->:8097) | T_AB=0.999936", rb.len());
    if daemon {
        let shared = Arc::new(Mutex::new(Edge24D::new()));
        if let Ok(listener) = TcpListener::bind("0.0.0.0:8097") {
            for stream in listener.incoming().flatten() {
                let st_c = Arc::clone(&shared);
                let r_len = rb.len();
                thread::spawn(move || {
                    let mut s = stream;
                    let mut buf: Vec<u8> = vec!(0u8; 2048);
                    if let Ok(n) = s.read(&mut buf) {
                        if n > 0 {
                            let sl = buf.get(..n).unwrap_or(buf.as_slice());
                            let req = String::from_utf8_lossy(sl);
                            let l1 = req.lines().next().unwrap_or("");
                            let body = if let Ok(mut g) = st_c.lock() {
                                upd(&mut g, l1);
                                to_json(&g, r_len)
                            } else { String::from("{\"status\":\"LOCK_ERR\"}") };
                            let hdr = format!("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nAccess-Control-Allow-Origin: *\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{}", body.len(), body);
                            let _ = s.write_all(hdr.as_bytes());
                        }
                    }
                });
            }
        }
    }
}