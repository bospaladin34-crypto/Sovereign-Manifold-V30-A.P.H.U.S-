// 01_l0_core/src/bin/test_tri_silicon_horizon_suite.rs
// Unified Verification for Final v30 Tracks 13 & 5 (Tri-Silicon Affinity & Event Horizon Beaming HUD)

use std::time::Instant;
use act_omega_l0_core::relativistic_horizon_hud::{
    DEFAULT_ORBITAL_BETA, EXPECTED_BEAMING_CONTRAST_27,
    compute_event_horizon_and_beaming,
};
use act_omega_l0_core::sierpinski_158_quantizer::MANIFOLD_STALKS;
use act_omega_l0_core::tri_silicon_affinity::{
    MALI_G715_L2_CACHE_BYTES, POWERVR_VULKAN_HEAP0_MB, TOTAL_CLUSTER_CORES,
    TOTAL_CLUSTER_THREADS, verify_tri_silicon_affinity_and_l2_pinning,
};

fn main() {
    println!("=============================================================================");
    println!(" ACT-OMEGA v30.0 | TRACKS 13 & 5: TRI-SILICON AFFINITY & HORIZON BEAMING HUD ");
    println!("=============================================================================");

    let t0 = Instant::now();
    let aff = verify_tri_silicon_affinity_and_l2_pinning();
    let aff_us = t0.elapsed().as_secs_f64() * 1.0e6;

    let t1 = Instant::now();
    let hud = compute_event_horizon_and_beaming(1.0, DEFAULT_ORBITAL_BETA);
    let hud_us = t1.elapsed().as_secs_f64() * 1.0e6;

    println!("1. [Track 13] Tri-Silicon Cores     : {} Physical Cores / {} HW Threads (8 LOQ + 8 P10 + 9 P8)", aff.total_physical_cores, aff.total_hardware_threads);
    println!("2. [Track 13] Core Affinity Masks   : LOQ=0x{:04X} | Pixel10=0x{:04X} (Vulkan {}MB) | Pixel8=0x{:04X}", aff.loq_pcore_mask, aff.pixel10_x4_a725_mask, POWERVR_VULKAN_HEAP0_MB, aff.pixel8_x3_a715_mask);
    println!("3. [Track 13] Mali-G715 4MB L2 Cache: {} B Total | INT8 Headroom: {} B | 1.58-Bit Headroom: {} B ({:.2}%)", MALI_G715_L2_CACHE_BYTES, aff.mali_g715_int8_l2_headroom_bytes, aff.mali_g715_ternary_l2_headroom_bytes, aff.mali_g715_ternary_headroom_pct);
    println!("4. [Track 5] Horizon & Photon Sphere: r_s = {:.4} | r_ph = {:.4} | Shadow b_c = {:.7}", hud.schwarzschild_radius_rs, hud.photon_sphere_radius_rph, hud.critical_shadow_radius_bc);
    println!("5. [Track 5] Relativistic Beaming   : I(0) = {:.6} vs I(pi) = {:.6} (Contrast Ratio: {:.6}x)", hud.approaching_intensity_i0, hud.receding_intensity_ipi, hud.beaming_contrast_ratio);
    println!("6. [Track 5] Orbiting Stalks Beamed : {} stalks @ 60 FPS (gamma = {:.7})", hud.stalk_beamed_intensities.len(), hud.lorentz_gamma);
    println!("7. Latencies (Affinity / Horizon)   : {:.2} us / {:.2} us", aff_us, hud_us);

    assert_eq!(aff.total_physical_cores, TOTAL_CLUSTER_CORES);
    assert_eq!(aff.total_hardware_threads, TOTAL_CLUSTER_THREADS);
    assert!(aff.l2_cache_pinned_resident);
    assert!(aff.mali_g715_ternary_headroom_pct > 80.0);
    assert!((hud.beaming_contrast_ratio - EXPECTED_BEAMING_CONTRAST_27).abs() < 1.0e-4);
    assert_eq!(hud.stalk_beamed_intensities.len(), MANIFOLD_STALKS);
    println!("=== TRACKS 13 & 5 VERIFICATION: ALL ASSERTIONS PASSED ===");
}