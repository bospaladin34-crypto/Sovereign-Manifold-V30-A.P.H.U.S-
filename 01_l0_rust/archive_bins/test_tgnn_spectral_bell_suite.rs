// 01_l0_core/src/bin/test_tgnn_spectral_bell_suite.rs
// Unified Verification for v30 Tracks 7, 14, 15, and 16 (Bell-CHSH, Cardy CFT, Heat-Compress QAT, 6-Op Sheaf)

use std::time::Instant;
use act_omega_l0_core::bell_chsh_witness::{
    BI_STALK_HALF_DIM, CLASSICAL_BELL_BOUND, TSIRELSON_QUANTUM_BOUND,
    evaluate_bell_chsh_bi_stalk,
};
use act_omega_l0_core::cft_energy_ladder::{
    ISING_CFT_SPIN_DELTA, calibrate_cardy_cft_energy_ladder,
};
use act_omega_l0_core::elastic_sheaf_ops::evaluate_six_operators_and_poly_sheaf;
use act_omega_l0_core::heat_compress_qat::execute_shielded_heat_compress_qat;
use act_omega_l0_core::sierpinski_158_quantizer::{
    PACKED_SIERPINSKI_BYTES, TOTAL_MANIFOLD_TRITS,
};

fn main() {
    println!("============================================================================");
    println!(" ACT-OMEGA v30.0 | TRACKS 7, 14, 15 & 16: TG-NN SPECTRAL & BELL-CHSH SUITE ");
    println!("============================================================================");

    let mut left_stalk: Vec<f32> = Vec::with_capacity(BI_STALK_HALF_DIM);
    let mut right_stalk: Vec<f32> = Vec::with_capacity(BI_STALK_HALF_DIM);
    let mut i: usize = 0;
    while i < BI_STALK_HALF_DIM {
        let val = ((i % 7) as f32) + 1.0;
        left_stalk.push(val);
        right_stalk.push(val);
        i += 1;
    }

    let mut raw_weights: Vec<i8> = Vec::with_capacity(TOTAL_MANIFOLD_TRITS);
    let mut k: usize = 0;
    while k < TOTAL_MANIFOLD_TRITS {
        raw_weights.push(((k % 3) as i8) - 1);
        k += 1;
    }

    let t0 = Instant::now();
    let bell = evaluate_bell_chsh_bi_stalk(&left_stalk, &right_stalk);
    let bell_us = t0.elapsed().as_secs_f64() * 1.0e6;

    let t1 = Instant::now();
    let cft = calibrate_cardy_cft_energy_ladder(1.50, 15.0);
    let cft_us = t1.elapsed().as_secs_f64() * 1.0e6;

    let t2 = Instant::now();
    let qat = execute_shielded_heat_compress_qat(&raw_weights, 0.50);
    let qat_us = t2.elapsed().as_secs_f64() * 1.0e6;

    let t3 = Instant::now();
    let ops = evaluate_six_operators_and_poly_sheaf(&raw_weights, 1.8849556, 0.618034);
    let ops_us = t3.elapsed().as_secs_f64() * 1.0e6;

    println!("1. [Track 7] Bell-CHSH Witness S    : {:.7} > {:.1} (Tsirelson 2*sqrt(2): {:.7})", bell.s_chsh_witness, CLASSICAL_BELL_BOUND, TSIRELSON_QUANTUM_BOUND);
    println!("2. [Track 14] Cardy CFT Energy Gap  : dE = {:.6} | Variance = {:.10} (L = 32 Stalks)", cft.mean_level_spacing, cft.spacing_variance);
    println!("3. [Track 14] CFT Scaling Dimension : Delta_0 = {:.6} (Ising 1/8 = {:.6})", cft.recovered_scaling_delta, ISING_CFT_SPIN_DELTA);
    println!("4. [Track 15] Lexical Shield Filter : {} Free Words / {} Quarantined Stems (Leaks: {})", qat.shielded_free_words_passed, qat.quarantined_bound_stems, qat.leaked_impurities);
    println!("5. [Track 15] Ignition Pressure     : {:.4} (Unshielded 10^-4) -> {:.4} (Shielded C*H QAT)", qat.unshielded_ignition_pressure, qat.shielded_ignition_pressure);
    println!("6. [Track 16] 6-Op Determinants     : det(R)={:.5}, det(H)={:.5}, det(C)={:.5}", ops.rotation_det, ops.shear_det, ops.homotopy_contraction_det);
    println!("7. [Track 16] Sheaf Kernel & Inverse: |L_F v_0|={:.7}, P^2!=P Errors={}, InvErr={:.8}, PolyNorm={:.4}", ops.harmonic_eigenvector_residual, ops.projection_idempotence_errors, ops.inverse_roundtrip_max_err, ops.poly_sheaf_output_norm);
    println!("8. Latencies (Bell/CFT/QAT/6-Op)    : {:.2} us / {:.2} us / {:.2} us / {:.2} us", bell_us, cft_us, qat_us, ops_us);

    assert!(bell.classical_bound_exceeded);
    assert!((bell.s_chsh_witness - TSIRELSON_QUANTUM_BOUND).abs() < 1.0e-4);
    assert!(cft.spacing_variance < 1.0e-10);
    assert!((cft.recovered_scaling_delta - ISING_CFT_SPIN_DELTA).abs() < 1.0e-5);
    assert_eq!(qat.leaked_impurities, 0);
    assert!(qat.shielded_ignition_pressure < qat.unshielded_ignition_pressure * 0.5);
    assert_eq!(qat.packed_qat_bytes, PACKED_SIERPINSKI_BYTES);
    assert!((ops.rotation_det - 1.0).abs() < 1.0e-5);
    assert!((ops.shear_det - 1.0).abs() < 1.0e-5);
    assert!((ops.homotopy_contraction_det - 0.70).abs() < 1.0e-5);
    assert!(ops.harmonic_eigenvector_residual < 1.0e-6);
    assert_eq!(ops.projection_idempotence_errors, 0);
    assert!(ops.inverse_roundtrip_max_err < 1.0e-6);
    println!("=== TRACKS 7, 14, 15 & 16 VERIFICATION: ALL ASSERTIONS PASSED ===");
}