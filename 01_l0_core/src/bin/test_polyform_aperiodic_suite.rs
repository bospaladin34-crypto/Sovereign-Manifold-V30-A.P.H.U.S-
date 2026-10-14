// 01_l0_core/src/bin/test_polyform_aperiodic_suite.rs
// Unified Verification for v30 Tracks 4, 9, and 10 (Chair44, Stomachion, Tangram/Penrose)

use std::time::Instant;
use act_omega_l0_core::chair44_automorphism::{
    CANONICAL_VAULT_SHARDS, execute_chair44_automorphism,
};
use act_omega_l0_core::sierpinski_158_quantizer::TOTAL_MANIFOLD_TRITS;
use act_omega_l0_core::stomachion_router::{
    CUTLER_CONFIGURATIONS, STOMACHION_GRID_AREA, STOMACHION_PIECES,
    route_stomachion_14_clauses,
};
use act_omega_l0_core::tangram_penrose_field::{
    DUAL_TANGRAM_STALK_AREA, GOLDEN_RATIO_PHI, TANGRAM_CLAUSE_AREA_UNITS,
    project_tangram_penrose_field,
};

fn main() {
    println!("============================================================================");
    println!(" ACT-OMEGA v30.0 | TRACKS 4, 9 & 10: CHAIR44, STOMACHION & TANGRAM/PENROSE ");
    println!("============================================================================");

    let mut sample_trits: Vec<i8> = Vec::with_capacity(TOTAL_MANIFOLD_TRITS);
    let mut i: usize = 0;
    while i < TOTAL_MANIFOLD_TRITS {
        let v = ((i % 3) as i8) - 1;
        sample_trits.push(v);
        i += 1;
    }

    let mut svo_tokens: Vec<usize> = Vec::with_capacity(STOMACHION_PIECES);
    let mut t: usize = 0;
    while t < STOMACHION_PIECES {
        svo_tokens.push((t * 17 + 43) % 240);
        t += 1;
    }

    let t0 = Instant::now();
    let c44 = execute_chair44_automorphism(&sample_trits, 19);
    let c44_us = t0.elapsed().as_secs_f64() * 1.0e6;

    let t1 = Instant::now();
    let stom = route_stomachion_14_clauses(&svo_tokens, 3001);
    let stom_us = t1.elapsed().as_secs_f64() * 1.0e6;

    let t2 = Instant::now();
    let tang = project_tangram_penrose_field(&svo_tokens, 0.618034);
    let tang_us = t2.elapsed().as_secs_f64() * 1.0e6;

    println!("1. [Track 4] Chair44 Vault Bijection: {} / {} unique shards visited (gcd(44,415)=1)", c44.unique_shards_visited, CANONICAL_VAULT_SHARDS);
    println!("2. [Track 4] Chair44 Inverse Checks : {}/{} shards & {}/{} 3D trits restored", c44.shard_roundtrip_matches, CANONICAL_VAULT_SHARDS, c44.trit_roundtrip_matches, TOTAL_MANIFOLD_TRITS);
    println!("3. [Track 9] Stomachion 14-Piece Sum: {} / {} (12x12 Grid) | Cutler Config #{}/{}", stom.total_area_sum, STOMACHION_GRID_AREA, stom.active_cutler_config_id, CUTLER_CONFIGURATIONS);
    println!("4. [Track 9] Dirichlet Boundary Flux: {:.6} (Zero-Leakage Quarantine Verified)", stom.dirichlet_boundary_leakage);
    println!("5. [Track 10] Tangram Clause Areas  : {} (1-Clause) -> {} (2-Clause = 32 Stalks)", tang.single_clause_area_units, tang.dual_clause_stalk_units);
    println!("6. [Track 10] Parallelogram Shear   : det(H) = {:.7} (Area-Preserving)", tang.parallelogram_shear_det);
    println!("7. [Track 10] Penrose Rhombus Ratio : sin(72)/sin(36) = {:.7} (Phi: {:.7})", tang.penrose_rhombus_area_ratio, GOLDEN_RATIO_PHI);
    println!("8. Execution Latencies (C44/Stom/Tg): {:.2} us / {:.2} us / {:.2} us", c44_us, stom_us, tang_us);

    assert_eq!(c44.unique_shards_visited, CANONICAL_VAULT_SHARDS);
    assert_eq!(c44.shard_roundtrip_matches, CANONICAL_VAULT_SHARDS);
    assert_eq!(c44.trit_roundtrip_matches, TOTAL_MANIFOLD_TRITS);
    assert_eq!(stom.total_area_sum, STOMACHION_GRID_AREA);
    assert!(stom.active_cutler_config_id < CUTLER_CONFIGURATIONS);
    assert_eq!(stom.dirichlet_boundary_leakage, 0.0);
    assert_eq!(tang.single_clause_area_units, TANGRAM_CLAUSE_AREA_UNITS);
    assert_eq!(tang.dual_clause_stalk_units, DUAL_TANGRAM_STALK_AREA);
    assert!((tang.parallelogram_shear_det - 1.0).abs() < 1.0e-6);
    assert!((tang.penrose_rhombus_area_ratio - GOLDEN_RATIO_PHI).abs() < 1.0e-5);
    println!("=== TRACKS 4, 9 & 10 VERIFICATION: ALL ASSERTIONS PASSED ===");
}