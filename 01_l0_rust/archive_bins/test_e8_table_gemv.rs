use std::time::Instant;
use act_omega_l0_core::*;

fn main() {
    println!("==================================================================");
    println!("  ACT-Omega v30.0: Table-Lookup GEMV & E8 Quantizer Verification ");
    println!("  Hardware Target: Lenovo LOQ 15IAX9 (garlock00)                 ");
    println!("==================================================================");

    // 1. Initialize E8 Root System & Inner-Product Table
    let t0 = Instant::now();
    let gemv = E8TableGEMV::new();
    let init_time = t0.elapsed();
    println!("[INIT] Generated 240 Gosset E8 Roots & 57,600-byte Table in {:.3} ms.", init_time.as_secs_f64() * 1000.0);

    // 2. Verify Mathematical Invariants
    println!("\n[TEST 1/3] Verifying E8 Root System Geometric Invariants:");
    let mut all_norms_valid = true;
    for (i, root) in gemv.roots.iter().enumerate() {
        let mut sq_norm = 0.0f32;
        for &x in root.iter() {
            sq_norm += x * x;
        }
        if (sq_norm - 2.0).abs() > 1e-5 {
            println!("  FAIL: Root {} has invalid squared norm: {:.4}", i, sq_norm);
            all_norms_valid = false;
            break;
        }
    }
    assert!(all_norms_valid);
    println!("  -> All 240 Roots strictly satisfy ||r||^2 = 2.000000: PASS");

    let mut discrete_dots_valid = true;
    for &entry in gemv.table.iter() {
        if entry < -2 || entry > 2 {
            discrete_dots_valid = false;
            break;
        }
    }
    assert!(discrete_dots_valid);
    println!("  -> All 57,600 Table entries strictly bounded to [-2, -1, 0, 1, 2]: PASS");

    // 3. Benchmark Table-Lookup GEMV Row Multiplications
    println!("\n[TEST 2/3] Benchmarking 100,000 Integer-Only Table-Lookup GEMV Rows:");
    let test_weights = [12u8; 32];
    let test_inputs  = [42u8; 32];

    let t_bench = Instant::now();
    let mut dummy_acc = 0i32;
    for _ in 0..100_000 {
        dummy_acc = dummy_acc.wrapping_add(gemv.gemv_row(&test_weights, &test_inputs));
    }
    let bench_elapsed = t_bench.elapsed();
    let per_row_ns = bench_elapsed.as_nanos() as f64 / 100_000.0;
    println!("  Accumulated Value: {}", dummy_acc);
    println!("  100,000 Rows Completed in: {:.3} ms", bench_elapsed.as_secs_f64() * 1000.0);
    println!("  Per-Row Latency: {:.2} nanoseconds", per_row_ns);
    assert!(per_row_ns < 100.0); // Sub-100ns per 256D vector inner product
    println!("  -> Sub-100ns Integer-Only Matrix-Vector Row Computation: PASS");

    // 4. Synthesize Canonical Vault Binary (model_harmonic_iii.e8q)
    println!("\n[TEST 3/3] Exporting Canonical E8 Quantized Vault Binary:");
    let vault_path = "C:\\sovereign_manifold_v30\\04_canonical_vault\\models\\model_harmonic_iii.e8q";
    gemv.export_canonical_e8q(vault_path).expect("Failed to write e8q file");

    let file_meta = std::fs::metadata(vault_path).expect("Failed to read e8q metadata");
    println!("  Target Artifact: {}", vault_path);
    println!("  Exported Size:   {} bytes", file_meta.len());
    assert_eq!(file_meta.len() as usize, CANONICAL_E8Q_BYTES);
    println!("  -> Exact 280,840-Byte Canonical Serialization: PASS");

    println!("\n==================================================================");
    println!("  TABLE-LOOKUP GEMV & CANONICAL VAULT VERIFICATION COMPLETE: PASS ");
    println!("==================================================================");
}