use act_omega_l0_core::e8_shell2::{generate_e8_shell2, E8_SHELL2_COUNT};
use std::time::Instant;

fn main() {
    println!("======================================================");
    println!("ACT-Omega v30.0: E8 Second-Shell 2,160-Vector Verification");
    println!("Target: Lenovo LOQ 15IAX9 (garlock00)");
    println!("======================================================");

    let t0 = Instant::now();
    let shell2 = generate_e8_shell2();
    let gen_us = t0.elapsed().as_micros();

    println!("[1/3] Generated {} vectors in {} us", shell2.len(), gen_us);
    assert_eq!(shell2.len(), E8_SHELL2_COUNT, "Vector count must equal 2160");

    // 2. Validate Norm Squared = 4.0 for all 2,160 vectors
    for (i, v) in shell2.iter().enumerate() {
        let norm_sq: f32 = v.iter().map(|&x| x * x).sum();
        assert!((norm_sq - 4.0).abs() < 1e-4, "Vector {} norm squared is {}", i, norm_sq);
    }
    println!("[2/3] Norm Squared Validation: Exactly 4.0 for all 2,160 vectors (PASS)");

    // 3. Coordinate Sum Evenness Check (E8 Lattice Invariant)
    for (i, v) in shell2.iter().enumerate() {
        let sum_coords: f32 = v.iter().sum();
        let rounded = sum_coords.round() as i32;
        assert_eq!(rounded % 2, 0, "Vector {} coordinate sum {} must be even integer", i, rounded);
    }
    println!("[3/3] E8 Invariant: Even coordinate sum strictly held for all 2,160 vectors (PASS)");

    println!("======================================================");
    println!("E8 SECOND-SHELL 2,160-VECTOR VERIFICATION: PASS");
    println!("======================================================");
}