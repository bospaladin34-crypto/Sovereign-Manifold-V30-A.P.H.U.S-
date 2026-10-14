use act_omega_l0_core::bi_stalk_attention_1024::{BiStalkAttentionKernel, NUM_COMPOUNDS};
use std::time::Instant;

fn main() {
    println!("=== ACT-Omega v30.0: 1,024-Compound-Pair Bi-Stalk Attention Benchmark ===");
    
    let kernel = BiStalkAttentionKernel::new();
    println!("[1/3] Initialized 1,024 SO(8) Artin Braid Operators in memory.");

    let left = [0.12f32, -0.05, 0.44, 0.10, -0.22, 0.15, -0.08, 0.33];
    let right_quiescent = [0.15f32, -0.03, 0.40, 0.12, -0.20, 0.18, -0.06, 0.30]; // Low coboundary (<0.18)
    let right_excited = [0.90f32, 0.60, -0.40, 0.70, 0.80, -0.50, 0.65, -0.30];    // High coboundary (>=0.18)

    // Test AFE Stiction Gating
    let (frame_q, _) = kernel.forward(42, &left, &right_quiescent);
    assert_eq!(frame_q.stiction_locked, 1, "Expected stiction lock on low coboundary");
    println!("[2/3] Quiescent Stiction Verified: ||delta^0|| = {:.4} (< 0.18) -> Stiction LOCKED (PASS)", frame_q.coboundary_norm);

    let (frame_e, compound_stalk) = kernel.forward(105, &left, &right_excited);
    assert_eq!(frame_e.stiction_locked, 0, "Expected polar slip on high coboundary");
    println!("[2/3] Polar Slip Verified: ||delta^0|| = {:.4} (>= 0.18) -> Polar Slip ACTIVE (PASS)", frame_e.coboundary_norm);
    println!("      Compound 16-D Stalk norm: {:.4}", compound_stalk.iter().map(|v| v * v).sum::<f32>().sqrt());

    // Throughput Benchmark across all 1,024 compound pairs
    let t0 = Instant::now();
    let iterations = 10_000usize;
    for i in 0..iterations {
        let cid = i % NUM_COMPOUNDS;
        let _ = kernel.forward(cid, &left, &right_excited);
    }
    let elapsed = t0.elapsed();
    let total_evals = iterations;
    let evals_per_sec = (total_evals as f64) / elapsed.as_secs_f64();
    let us_per_eval = elapsed.as_micros() as f64 / total_evals as f64;

    println!("[3/3] Throughput Benchmark: {} evals in {:.3} ms", total_evals, elapsed.as_secs_f64() * 1000.0);
    println!("      Sustained Attention Rate: {:.1} compound evals/s ({:.3} us/eval)", evals_per_sec, us_per_eval);
    println!("BI-STALK ATTENTION KERNEL BENCHMARK: PASS");
}