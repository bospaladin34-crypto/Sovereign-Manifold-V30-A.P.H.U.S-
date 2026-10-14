// 01_l0_core/src/bin/test_v30_full_integration.rs
// End-to-End Verification of All 17 v30 Modules in the Unified TG-NN Pipeline

use std::fs;
use std::time::Instant;
use act_omega_l0_core::tgnn_unified_pipeline::execute_tgnn_v30_unified_pass;

fn main() {
    println!("=============================================================================");
    println!(" ACT-OMEGA v30.0 | UNIFIED 17-MODULE TG-NN END-TO-END INTEGRATION BENCHMARK ");
    println!("=============================================================================");

    let mut prompt_opcodes: Vec<u8> = Vec::with_capacity(10);
    prompt_opcodes.push(0);
    prompt_opcodes.push(2);
    prompt_opcodes.push(3);
    prompt_opcodes.push(1);
    prompt_opcodes.push(4);
    prompt_opcodes.push(6);
    prompt_opcodes.push(7);
    prompt_opcodes.push(8);
    prompt_opcodes.push(9);
    prompt_opcodes.push(2);

    let t0 = Instant::now();
    let rep = execute_tgnn_v30_unified_pass(&prompt_opcodes, 3030);
    let total_us = t0.elapsed().as_secs_f64() * 1.0e6;

    let json_path = "C:\\sovereign_manifold_v30\\03_weights_e8\\v30_unified_telemetry.json";
    fs::write(json_path, &rep.json_telemetry).expect("Failed to write unified telemetry JSON");

    println!("1. [Stage 0: Affinity & BraidIR]  : {} Cores | Mali L2 Free: {:.2}% | Braid Len: {} | SL2Z OK: {}", rep.cluster_physical_cores, rep.mali_g715_ternary_headroom_pct, rep.braid_reduced_len, rep.sl2z_yang_baxter_ok);
    println!("2. [Stage 1: Chair44 & Triality]  : {}/415 Shards | Klein V4 Clashes: {}", rep.chair44_shards_visited, rep.chromatic_sheaf_clashes);
    println!("3. [Stage 2: Cavity & Cardy CFT]  : Hyperbolic Gain: {:.2}x | CFT Delta_0: {:.6}", rep.hyperbolic_focus_gain, rep.cft_scaling_delta);
    println!("4. [Stage 3: Bell-CHSH Witness]   : S_CHSH = {:.7} > 2.0", rep.bell_s_chsh);
    println!("5. [Stage 4: Eraser & Polyforms]  : C1={:?} | C2={:?} | Overlap={} | Cutler=#{}/536 | Tangram={}u", rep.svo_clause1_tokens, rep.svo_clause2_tokens, rep.svo_inter_clause_overlap, rep.stomachion_cutler_config, rep.tangram_dual_stalk_units);
    println!("6. [Stage 5: QAT & Plaquette Sync]: Pressure={:.4} | AB Flux={:.5} rad | Packed={} B | Dot={:.4}", rep.qat_shielded_pressure, rep.plaquette_ab_flux_rad, rep.packed_sierpinski_bytes, rep.zero_mul_dot_score);
    println!("7. [Stage 6: Horizon Beaming HUD] : Contrast Ratio = {:.6}x | JSON -> {}", rep.horizon_beaming_contrast, json_path);
    println!("8. Full 17-Module Pipeline Latency: {:.2} us ({:.4} ms)", total_us, total_us / 1000.0);
    println!("9. Live Telemetry JSON Payload    : {}", rep.json_telemetry);

    assert_eq!(rep.cluster_physical_cores, 25);
    assert!(rep.sl2z_yang_baxter_ok);
    assert_eq!(rep.chair44_shards_visited, 415);
    assert_eq!(rep.chromatic_sheaf_clashes, 0);
    assert!(rep.bell_s_chsh > 2.828);
    assert_eq!(rep.svo_inter_clause_overlap, 0);
    assert_eq!(rep.tangram_dual_stalk_units, 32);
    assert_eq!(rep.packed_sierpinski_bytes, 1536);
    assert!((rep.horizon_beaming_contrast - 27.0).abs() < 1.0e-3);
    println!("=== UNIFIED 17-MODULE v30 PIPELINE: ALL ASSERTIONS PASSED ===");
}