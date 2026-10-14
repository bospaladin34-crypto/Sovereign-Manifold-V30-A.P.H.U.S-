// 01_l0_core/src/bin/test_hyperbolic_eraser_cavity.rs
// Verification Benchmark for v30 Track 3 & Track 6: Hyperbolic Wave Attractor & Quantum Eraser SVO Gate

use std::time::Instant;
use act_omega_l0_core::hyperbolic_eraser_cavity::{
    SVO_CLAUSE_LEN, TOTAL_SVO_SLOTS, VOCAB_SIZE_240,
    evaluate_dual_clause_quantum_eraser, is_tilted_cavity_wall,
    propagate_hyperbolic_cavity,
};
use act_omega_l0_core::sierpinski_158_quantizer::MANIFOLD_STALKS;

fn main() {
    println!("==========================================================================");
    println!(" ACT-OMEGA v30.0 | TRACK 3 & 6: HYPERBOLIC ATTRACTOR & QUANTUM ERASER SVO ");
    println!("==========================================================================");

    let mut initial_stalks: Vec<f32> = Vec::with_capacity(MANIFOLD_STALKS);
    let mut wall_count: usize = 0;
    let mut s: usize = 0;
    while s < MANIFOLD_STALKS {
        if is_tilted_cavity_wall(s) {
            wall_count += 1;
        }
        initial_stalks.push(1.0 + 0.05 * ((s % 5) as f32));
        s += 1;
    }

    let t0 = Instant::now();
    let cavity = propagate_hyperbolic_cavity(&initial_stalks);
    let cavity_us = t0.elapsed().as_secs_f64() * 1.0e6;

    let t1 = Instant::now();
    let eraser = evaluate_dual_clause_quantum_eraser(&cavity.stalk_energies, 0.17259);
    let eraser_us = t1.elapsed().as_secs_f64() * 1.0e6;

    println!("1. Tilted Cavity Boundary Walls     : {} asymmetric reflection stalks (0, 7, 15, 23, 31)", wall_count);
    println!("2. L2 Energy Norm Conservation      : {:.5} -> {:.5}", cavity.initial_l2_norm, cavity.final_l2_norm);
    println!("3. Top-3 Stalk Attractor Focus      : {:.4} -> {:.4} (Gain: {:.2}x)", cavity.initial_top3_concentration, cavity.final_top3_concentration, cavity.attractor_focus_gain);
    println!("4. Clause 1 (cos^2 Symmetric 7-SVO) : {:?}", eraser.clause1_tokens);
    println!("5. Clause 2 (sin^2 Orthogonal 7-SVO): {:?}", eraser.clause2_tokens);
    println!("6. Inter-Clause Token Overlap       : {} / {} slots (240-Token Vocab: {})", eraser.inter_clause_overlap_count, TOTAL_SVO_SLOTS, VOCAB_SIZE_240);
    println!("7. Mean cos^2 + sin^2 Orthogonality : {:.7}", eraser.mean_orthogonality_sum);
    println!("8. Cavity / Eraser Latency          : {:.2} us / {:.2} us", cavity_us, eraser_us);

    assert_eq!(wall_count, 5);
    assert!((cavity.initial_l2_norm - cavity.final_l2_norm).abs() < 1.0e-4);
    assert!(cavity.final_top3_concentration > cavity.initial_top3_concentration);
    assert_eq!(eraser.clause1_tokens.len(), SVO_CLAUSE_LEN);
    assert_eq!(eraser.clause2_tokens.len(), SVO_CLAUSE_LEN);
    assert_eq!(eraser.inter_clause_overlap_count, 0);
    assert!((eraser.mean_orthogonality_sum - 1.0).abs() < 1.0e-5);
    println!("=== TRACK 3 & TRACK 6 VERIFICATION: ALL ASSERTIONS PASSED ===");
}