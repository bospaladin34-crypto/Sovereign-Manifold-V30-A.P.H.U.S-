// 01_l0_core/src/bin/test_triality_braid_suite.rs
// Unified Verification for v30 Tracks 11, 12, and 17 (E8 Triality, Chromatic Sheaf, BraidIR, PSL2(Z))

use std::time::Instant;
use act_omega_l0_core::braid_polyglot_ir::reduce_braid_word_kolmogorov;
use act_omega_l0_core::chromatic_triality_sheaf::{
    E8_TOTAL_ROOTS, evaluate_triality_and_chromatic_sheaf,
};
use act_omega_l0_core::modular_braid_sl2z::verify_modular_braid_representation;

fn main() {
    println!("============================================================================");
    println!(" ACT-OMEGA v30.0 | TRACKS 11, 12 & 17: TRIALITY, CHROMATIC SHEAF & BRAID-IR ");
    println!("============================================================================");

    let t0 = Instant::now();
    let tri = evaluate_triality_and_chromatic_sheaf();
    let tri_us = t0.elapsed().as_secs_f64() * 1.0e6;

    let mut sample_opcodes: Vec<u8> = Vec::with_capacity(16);
    sample_opcodes.push(0);
    sample_opcodes.push(2);
    sample_opcodes.push(3);
    sample_opcodes.push(1);
    sample_opcodes.push(4);
    sample_opcodes.push(6);
    sample_opcodes.push(7);
    sample_opcodes.push(8);
    sample_opcodes.push(9);
    sample_opcodes.push(2);

    let t1 = Instant::now();
    let braid = reduce_braid_word_kolmogorov(&sample_opcodes);
    let braid_us = t1.elapsed().as_secs_f64() * 1.0e6;

    let t2 = Instant::now();
    let sl2z = verify_modular_braid_representation(&braid.reduced_generators);
    let sl2z_us = t2.elapsed().as_secs_f64() * 1.0e6;

    let total_e8_partition = tri.vector_8v_roots + tri.spinor_8plus_roots + tri.spinor_8minus_roots;

    println!("1. [Track 11] E8 Triality Partition : {} (8_v) + {} (8_+) + {} (8_-) = {} roots", tri.vector_8v_roots, tri.spinor_8plus_roots, tri.spinor_8minus_roots, total_e8_partition);
    println!("2. [Track 11] Out(D4)=S3 Cycle Check: {} / {} roots invariant under S3 orbit", tri.tau_cubed_identity_matches, E8_TOTAL_ROOTS);
    println!("3. [Track 11] Klein V4 Sheaf Clashes: {} monochromatic clashes (Packed: {} B)", tri.chromatic_edge_clashes, tri.packed_v4_blocks_bytes);
    println!("4. [Track 12] BraidIR Reidemeister 2: {} -> {} generators ({} inverse pairs cancelled)", braid.initial_word_len, braid.reduced_word_len, braid.cancelled_reidemeister_pairs);
    println!("5. [Track 12] Writhe Charge Invariant: Q_init = {} == Q_reduced = {} (Words: {:?})", braid.initial_writhe_charge, braid.reduced_writhe_charge, braid.reduced_generators);
    println!("6. [Track 17] Yang-Baxter SL_2(Z)   : s1*s2*s1 = {:?} == s2*s1*s2 (Verified: {})", sl2z.lhs_s1_s2_s1, sl2z.yang_baxter_verified);
    println!("7. [Track 17] Central (s1*s2)^3     : {:?} == -I_2 in PSL_2(Z) (det = {})", sl2z.central_cube_matrix, sl2z.compiled_word_det);
    println!("8. Execution Latencies (Tri/Br/SL2Z): {:.2} us / {:.2} us / {:.2} us", tri_us, braid_us, sl2z_us);

    assert_eq!(total_e8_partition, E8_TOTAL_ROOTS);
    assert_eq!(tri.tau_cubed_identity_matches, E8_TOTAL_ROOTS);
    assert_eq!(tri.chromatic_edge_clashes, 0);
    assert!(braid.reduced_word_len < braid.initial_word_len);
    assert_eq!(braid.initial_writhe_charge, braid.reduced_writhe_charge);
    assert!(sl2z.yang_baxter_verified);
    assert!(sl2z.psl2z_identity_verified);
    assert_eq!(sl2z.compiled_word_det, 1);
    println!("=== TRACKS 11, 12 & 17 VERIFICATION: ALL ASSERTIONS PASSED ===");
}