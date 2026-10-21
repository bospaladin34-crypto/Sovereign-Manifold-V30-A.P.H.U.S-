// =============================================================================
// ACT-OMEGA NET v41.0.0 (SH4Z v4100 TLV) - DYNAMIC HARDWARE & DISK PROBES
// FOR TOOLS 55..58 (Muse Audit #2 Remediated: Zero Canned Static JSON)
// =============================================================================

use std::fs;
use std::io::Read;
use std::path::Path;
use std::time::Instant;

#[derive(Clone, Copy, Debug)]
pub struct DualWordMaskU128 {
    pub mask_lo: u64,
    pub mask_hi: u64,
}

impl DualWordMaskU128 {
    pub fn from_disk_header(path: &str) -> Self {
        let mut header = Vec::with_capacity(24);
        if let Ok(mut f) = fs::File::open(path) {
            let _ = (&mut f).take(24).read_to_end(&mut header);
        }
        if header.len() >= 24 {
            let mut lo_bytes = 0u64.to_le_bytes();
            let mut hi_bytes = 0u64.to_le_bytes();
            lo_bytes.copy_from_slice(&header.get(8..16).unwrap_or(&lo_bytes));
            hi_bytes.copy_from_slice(&header.get(16..24).unwrap_or(&hi_bytes));
            Self {
                mask_lo: u64::from_le_bytes(lo_bytes),
                mask_hi: u64::from_le_bytes(hi_bytes),
            }
        } else {
            Self { mask_lo: 0, mask_hi: 0 }
        }
    }

    pub const fn active_sectors(&self) -> u32 {
        self.mask_lo.count_ones() + self.mask_hi.count_ones()
    }
}

pub fn tool_55_gemini_bidirectional_bridge_json() -> String {
    let t0 = Instant::now();
    let drive_path = "G:\My Drive\ACT_OMEGA_GEMINI_BRIDGE\v40_omni_audit_and_training.json";
    let local_snap = "telemetry_snapshot.json";
    let drive_exists = Path::new(drive_path).exists();
    let snap_bytes = fs::metadata(local_snap).map(|m| m.len()).unwrap_or(0);
    let latency_ms = t0.elapsed().as_secs_f64() * 1000.0;
    format!(
        "{{"tool":55,"endpoint":"/api/v1/gemini/bridge","drive_mounted":{},"telemetry_snapshot_bytes":{},"probe_latency_ms":{:.4}}}",
        drive_exists, snap_bytes, latency_ms
    )
}

pub fn tool_56_autonomous_coder_swarm_json() -> String {
    let zed_cfg = Path::new("00_control/ide_configs/zed_settings.json").exists();
    let cline_cfg = Path::new("00_control/ide_configs/cline_mcp_settings.json").exists();
    let goose_cfg = Path::new("00_control/ide_configs/goose_config.yaml").exists();
    let configured_count = usize::from(zed_cfg) + usize::from(cline_cfg) + usize::from(goose_cfg);
    format!(
        "{{"tool":56,"endpoint":"/api/v1/swarm/autonomous_coder","configured_ides":{},"zed_ready":{},"cline_ready":{},"goose_ready":{}}}",
        configured_count, zed_cfg, cline_cfg, goose_cfg
    )
}

pub fn tool_57_online_ternary_distill_json() -> String {
    let t0 = Instant::now();
    let mask = DualWordMaskU128::from_disk_header("00_control/weights/sovereign_harmonic_iv_v4000.e8z");
    let npage_bytes = fs::metadata("00_control/weights/neurons_v4000.npage").map(|m| m.len()).unwrap_or(0);
    let neurons = npage_bytes / 128;
    let elapsed_ms = t0.elapsed().as_secs_f64() * 1000.0;
    format!(
        "{{"tool":57,"endpoint":"/api/v1/training/online_ternary_distill","active_sectors_on_disk":{},"neurons_on_disk":{},"npage_bytes":{},"verify_ms":{:.4}}}",
        mask.active_sectors(),
        neurons,
        npage_bytes,
        elapsed_ms
    )
}

pub fn tool_58_mobile_action_trigger_json() -> String {
    let kt_path = "04_edge_silicon/pixel10_ndk_app/app/src/main/java/com/actomega/manifold/MainActivity.kt";
    let kt_bytes = fs::metadata(kt_path).map(|m| m.len()).unwrap_or(0);
    let asset_bytes = fs::metadata("04_edge_silicon/pixel10_ndk_app/app/src/main/assets/sh4_leech_720.e8z")
        .map(|m| m.len())
        .unwrap_or(0);
    format!(
        "{{"tool":58,"endpoint":"/api/v1/edge/mobile_action_trigger","main_activity_kt_bytes":{},"bundled_e8z_asset_bytes":{}}}",
        kt_bytes, asset_bytes
    )
}
