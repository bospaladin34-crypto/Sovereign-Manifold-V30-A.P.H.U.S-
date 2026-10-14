// 01_l0_core/src/bin/test_sierpinski_158.rs
// Verification & Microsecond Benchmark for v30 Track 1: Sierpinski 1.58-Bit Quantizer

use std::fs;
use std::time::Instant;
use act_omega_l0_core::sierpinski_158_quantizer::{
    AB_WILSON_PHASE_RAD, HAUSDORFF_LOG2_3, MANIFOLD_LAYERS, MANIFOLD_STALKS,
    PACKED_SIERPINSKI_BYTES, TOTAL_MANIFOLD_TRITS, benchmark_non_commutative_order,
    is_sierpinski_boundary, quantize_heat_then_compress, ternary_dot_zero_mul,
    unpack_sierpinski_tensor,
};

fn main() {
    println!("==================================================================");
    println!(" ACT-OMEGA v30.0 | TRACK 1: SIERPINSKI 1.58-BIT TERNARY QUANTIZER ");
    println!("==================================================================");

    let mut raw_int8: Vec<i8> = Vec::with_capacity(TOTAL_MANIFOLD_TRITS);
    let mut activations: Vec<f32> = Vec::with_capacity(TOTAL_MANIFOLD_TRITS);
    let mut idx: usize = 0;
    while idx < TOTAL_MANIFOLD_TRITS {
        let layer = idx / 256;
        let stalk = (idx % 256) / 8;
        let dim = idx % 8;
        let on_gasket = is_sierpinski_boundary(layer, stalk);
        let base_val: i8 = if on_gasket {
            if (idx + dim) % 2 == 0 { 64 } else { -64 }
        } else {
            ((idx % 17) as i8) - 8
        };
        raw_int8.push(base_val);
        activations.push(((idx % 11) as f32 - 5.0) * 0.125);
        idx += 1;
    }

    let mut gasket_sites: usize = 0;
    let mut l: usize = 0;
    while l < MANIFOLD_LAYERS {
        let mut s: usize = 0;
        while s < MANIFOLD_STALKS {
            if is_sierpinski_boundary(l, s) {
                gasket_sites += 1;
            }
            s += 1;
        }
        l += 1;
    }

    let t0 = Instant::now();
    let tensor = quantize_heat_then_compress(&raw_int8, AB_WILSON_PHASE_RAD);
    let quant_us = t0.elapsed().as_secs_f64() * 1.0e6;

    let unpacked = unpack_sierpinski_tensor(&tensor.packed_bytes);
    let mut roundtrip_matches: usize = 0;
    let mut k: usize = 0;
    while k < TOTAL_MANIFOLD_TRITS {
        if *unpacked.get(k).unwrap_or(&9) == *tensor.unpacked_trits.get(k).unwrap_or(&-9) {
            roundtrip_matches += 1;
        }
        k += 1;
    }

    let t1 = Instant::now();
    let zero_mul_out = ternary_dot_zero_mul(&tensor.packed_bytes, &activations, tensor.scale_gamma);
    let dot_us = t1.elapsed().as_secs_f64() * 1.0e6;

    let bench = benchmark_non_commutative_order(&raw_int8, &activations);
    let out_path = "C:\\sovereign_manifold_v30\\03_weights_e8\\sierpinski_158_manifold.e8t";
    fs::write(out_path, &tensor.packed_bytes).expect("Failed to write .e8t ternary checkpoint");

    println!("1. Fractal Dimension (log2(3))      : {:.5} bits/trit", HAUSDORFF_LOG2_3);
    println!("2. Sierpinski Gasket Sites (30x32)  : {} / 960 boundary stalks", gasket_sites);
    println!("3. Tensor Footprint Compression     : {} B -> {} B ({:.1}x)", TOTAL_MANIFOLD_TRITS, tensor.packed_bytes.len(), bench.compression_ratio);
    println!("4. Lossless Radix-243 Round-Trip    : {} / {} trits matched", roundtrip_matches, TOTAL_MANIFOLD_TRITS);
    println!("5. Boundary Active (+/-1) Trits     : {}", tensor.boundary_active_count);
    println!("6. Bulk Insulator (0-Trit) States   : {}", tensor.bulk_zero_insulator_count);
    println!("7. Elastic Net (L1+L2) Loss         : {:.5}", tensor.elastic_net_loss);
    println!("8. Non-Commutative Order (C*H MSE)  : {:.4} vs (H*C MSE): {:.4} (Delta: {:.4})", bench.heat_then_compress_mse, bench.compress_then_heat_mse, bench.non_commutativity_delta);
    println!("9. Zero-Multiply Dot Product        : {:.4} (Exact Float: {:.4})", zero_mul_out, bench.exact_float_dot_product);
    println!("10. Quantize Latency / Dot Latency  : {:.2} us / {:.2} us", quant_us, dot_us);
    println!("11. Saved Ternary Checkpoint        : {} ({} bytes)", out_path, PACKED_SIERPINSKI_BYTES);
    assert_eq!(tensor.packed_bytes.len(), PACKED_SIERPINSKI_BYTES);
    assert_eq!(roundtrip_matches, TOTAL_MANIFOLD_TRITS);
    assert!(bench.heat_then_compress_mse < bench.compress_then_heat_mse);
    println!("=== TRACK 1 VERIFICATION: ALL ASSERTIONS PASSED ===");
}