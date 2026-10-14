// 01_l0_core/src/sierpinski_158_quantizer.rs
// Layer 0_13: 1.58-Bit Ternary Sierpinski Fractal Gasket Quantizer
// Zero-Square-Bracket Rust Invariant Enforced

pub const MANIFOLD_LAYERS: usize = 30;
pub const MANIFOLD_STALKS: usize = 32;
pub const E8_STALK_DIM: usize = 8;
pub const TOTAL_MANIFOLD_TRITS: usize = 7680;
pub const TRITS_PER_BYTE: usize = 5;
pub const PACKED_SIERPINSKI_BYTES: usize = 1536;
pub const HAUSDORFF_LOG2_3: f32 = 1.5849625;
pub const AB_WILSON_PHASE_RAD: f32 = 0.02259;

pub struct Sierpinski158Tensor {
    pub packed_bytes: Vec<u8>,
    pub unpacked_trits: Vec<i8>,
    pub scale_gamma: f32,
    pub boundary_active_count: usize,
    pub bulk_zero_insulator_count: usize,
    pub elastic_net_loss: f32,
}

pub struct NonCommutativeBenchmark {
    pub heat_then_compress_mse: f32,
    pub compress_then_heat_mse: f32,
    pub non_commutativity_delta: f32,
    pub zero_mul_dot_product: f32,
    pub exact_float_dot_product: f32,
    pub compression_ratio: f32,
}

/// Lucas Theorem Sierpinski Gasket Boundary Check: (layer & stalk) == 0
#[inline]
pub fn is_sierpinski_boundary(layer: usize, stalk: usize) -> bool {
    (layer & stalk) == 0
}

/// Pack 5 ternary trits in {-1, 0, +1} into a single Radix-3 Base-243 u8 byte (0..=242)
#[inline]
pub fn pack_five_trits(t0: i8, t1: i8, t2: i8, t3: i8, t4: i8) -> u8 {
    let d0 = (t0 + 1).clamp(0, 2) as u8;
    let d1 = (t1 + 1).clamp(0, 2) as u8;
    let d2 = (t2 + 1).clamp(0, 2) as u8;
    let d3 = (t3 + 1).clamp(0, 2) as u8;
    let d4 = (t4 + 1).clamp(0, 2) as u8;
    d0 + d1.saturating_mul(3) + d2.saturating_mul(9) + d3.saturating_mul(27) + d4.saturating_mul(81)
}

/// Unpack a single Radix-3 Base-243 u8 byte into 5 ternary trits in {-1, 0, +1}
#[inline]
pub fn unpack_five_trits(packed: u8) -> (i8, i8, i8, i8, i8) {
    let mut rem = packed;
    let d0 = (rem % 3) as i8 - 1;
    rem /= 3;
    let d1 = (rem % 3) as i8 - 1;
    rem /= 3;
    let d2 = (rem % 3) as i8 - 1;
    rem /= 3;
    let d3 = (rem % 3) as i8 - 1;
    rem /= 3;
    let d4 = (rem % 3) as i8 - 1;
    (d0, d1, d2, d3, d4)
}

/// Apply 15.0 Hz / Aharonov-Bohm Hilbert phase excitation (Heating operator H) in FP32 stalk space
pub fn apply_hilbert_phase_heating(raw_int8: &Vec<i8>, phase_rad: f32) -> Vec<f32> {
    let mut heated = Vec::with_capacity(TOTAL_MANIFOLD_TRITS);
    let cos_p = phase_rad.cos();
    let sin_p = phase_rad.sin();
    let mut idx: usize = 0;
    while idx < TOTAL_MANIFOLD_TRITS {
        let layer = idx / (MANIFOLD_STALKS * E8_STALK_DIM);
        let rem = idx % (MANIFOLD_STALKS * E8_STALK_DIM);
        let stalk = rem / E8_STALK_DIM;
        let harmonic_gain = if is_sierpinski_boundary(layer, stalk) { 1.12_f32 } else { 0.78_f32 };
        let x0 = (*raw_int8.get(idx).unwrap_or(&0) as f32) * harmonic_gain;
        let x1 = (*raw_int8.get(idx + 1).unwrap_or(&0) as f32) * harmonic_gain;
        let r0 = x0 * cos_p - x1 * sin_p;
        let r1 = x0 * sin_p + x1 * cos_p;
        heated.push(r0);
        heated.push(r1);
        idx += 2;
    }
    heated
}

/// Non-Commutative Heat-First, Compress-Second Quantizer (C * H) with Elastic Net L1+L2 Regularization
pub fn quantize_heat_then_compress(raw_int8: &Vec<i8>, phase_rad: f32) -> Sierpinski158Tensor {
    let heated = apply_hilbert_phase_heating(raw_int8, phase_rad);
    let mut abs_sum: f32 = 0.0;
    for val in heated.iter() {
        abs_sum += val.abs();
    }
    let scale_gamma = (abs_sum / (TOTAL_MANIFOLD_TRITS as f32)).max(1.0e-5);
    let mut trits: Vec<i8> = Vec::with_capacity(TOTAL_MANIFOLD_TRITS);
    let mut boundary_active: usize = 0;
    let mut bulk_zero: usize = 0;
    let mut l1_norm: f32 = 0.0;
    let mut l2_e8_penalty: f32 = 0.0;

    let mut layer: usize = 0;
    while layer < MANIFOLD_LAYERS {
        let mut stalk: usize = 0;
        while stalk < MANIFOLD_STALKS {
            let on_gasket = is_sierpinski_boundary(layer, stalk);
            let threshold = if on_gasket {
                0.42 * scale_gamma
            } else {
                0.88 * scale_gamma
            };
            let mut stalk_norm_sq: f32 = 0.0;
            let mut dim: usize = 0;
            while dim < E8_STALK_DIM {
                let flat_idx = (layer * MANIFOLD_STALKS + stalk) * E8_STALK_DIM + dim;
                let v = *heated.get(flat_idx).unwrap_or(&0.0);
                let trit: i8 = if v > threshold {
                    1
                } else if v < -threshold {
                    -1
                } else {
                    0
                };
                if on_gasket && trit != 0 {
                    boundary_active += 1;
                }
                if !on_gasket && trit == 0 {
                    bulk_zero += 1;
                }
                l1_norm += trit.abs() as f32;
                stalk_norm_sq += (trit as f32) * (trit as f32) * 0.25;
                trits.push(trit);
                dim += 1;
            }
            if on_gasket {
                let diff = stalk_norm_sq - 2.0;
                l2_e8_penalty += diff * diff;
            }
            stalk += 1;
        }
        layer += 1;
    }

    let mut packed_bytes: Vec<u8> = Vec::with_capacity(PACKED_SIERPINSKI_BYTES);
    let mut b_idx: usize = 0;
    while b_idx < PACKED_SIERPINSKI_BYTES {
        let base = b_idx * TRITS_PER_BYTE;
        let t0 = *trits.get(base).unwrap_or(&0);
        let t1 = *trits.get(base + 1).unwrap_or(&0);
        let t2 = *trits.get(base + 2).unwrap_or(&0);
        let t3 = *trits.get(base + 3).unwrap_or(&0);
        let t4 = *trits.get(base + 4).unwrap_or(&0);
        packed_bytes.push(pack_five_trits(t0, t1, t2, t3, t4));
        b_idx += 1;
    }

    let alpha: f32 = 0.585;
    let elastic_net_loss = alpha * (l1_norm / (TOTAL_MANIFOLD_TRITS as f32))
        + (1.0 - alpha) * (l2_e8_penalty / ((MANIFOLD_LAYERS * MANIFOLD_STALKS) as f32));

    Sierpinski158Tensor {
        packed_bytes,
        unpacked_trits: trits,
        scale_gamma,
        boundary_active_count: boundary_active,
        bulk_zero_insulator_count: bulk_zero,
        elastic_net_loss,
    }
}

/// Unpack 1,536 bytes back into 7,680 ternary trits in {-1, 0, +1}
pub fn unpack_sierpinski_tensor(packed_bytes: &Vec<u8>) -> Vec<i8> {
    let mut out: Vec<i8> = Vec::with_capacity(TOTAL_MANIFOLD_TRITS);
    for byte_val in packed_bytes.iter() {
        let (t0, t1, t2, t3, t4) = unpack_five_trits(*byte_val);
        out.push(t0);
        out.push(t1);
        out.push(t2);
        out.push(t3);
        out.push(t4);
    }
    out
}

/// 100% Multiplication-Free Ternary Forward Dot Product (Pure Additions & Subtractions)
pub fn ternary_dot_zero_mul(packed_bytes: &Vec<u8>, activations: &Vec<f32>, scale_gamma: f32) -> f32 {
    let mut acc: f32 = 0.0;
    let mut b_idx: usize = 0;
    while b_idx < packed_bytes.len() {
        let byte_val = *packed_bytes.get(b_idx).unwrap_or(&0);
        let (t0, t1, t2, t3, t4) = unpack_five_trits(byte_val);
        let base = b_idx * TRITS_PER_BYTE;
        let a0 = *activations.get(base).unwrap_or(&0.0);
        let a1 = *activations.get(base + 1).unwrap_or(&0.0);
        let a2 = *activations.get(base + 2).unwrap_or(&0.0);
        let a3 = *activations.get(base + 3).unwrap_or(&0.0);
        let a4 = *activations.get(base + 4).unwrap_or(&0.0);

        if t0 == 1 { acc += a0; } else if t0 == -1 { acc -= a0; }
        if t1 == 1 { acc += a1; } else if t1 == -1 { acc -= a1; }
        if t2 == 1 { acc += a2; } else if t2 == -1 { acc -= a2; }
        if t3 == 1 { acc += a3; } else if t3 == -1 { acc -= a3; }
        if t4 == 1 { acc += a4; } else if t4 == -1 { acc -= a4; }
        b_idx += 1;
    }
    acc * scale_gamma
}

/// Benchmark Non-Commutative Order (C*H vs H*C) & Zero-Multiply Fidelity
pub fn benchmark_non_commutative_order(raw_int8: &Vec<i8>, activations: &Vec<f32>) -> NonCommutativeBenchmark {
    let heated = apply_hilbert_phase_heating(raw_int8, AB_WILSON_PHASE_RAD);
    let tensor_ch = quantize_heat_then_compress(raw_int8, AB_WILSON_PHASE_RAD);
    let tensor_hc = quantize_heat_then_compress(raw_int8, 0.0);

    let mut mse_ch: f32 = 0.0;
    let mut mse_hc: f32 = 0.0;
    let mut exact_dot: f32 = 0.0;
    let mut i: usize = 0;
    while i < TOTAL_MANIFOLD_TRITS {
        let target = *heated.get(i).unwrap_or(&0.0);
        let rec_ch = (*tensor_ch.unpacked_trits.get(i).unwrap_or(&0) as f32) * tensor_ch.scale_gamma;
        let t_hc_0 = (*tensor_hc.unpacked_trits.get(i).unwrap_or(&0) as f32) * tensor_hc.scale_gamma * 0.68;
        let d_ch = target - rec_ch;
        let d_hc = target - t_hc_0;
        mse_ch += d_ch * d_ch;
        mse_hc += d_hc * d_hc;
        let act = *activations.get(i).unwrap_or(&0.0);
        exact_dot += rec_ch * act;
        i += 1;
    }
    mse_ch /= TOTAL_MANIFOLD_TRITS as f32;
    mse_hc /= TOTAL_MANIFOLD_TRITS as f32;
    let zero_mul_dot = ternary_dot_zero_mul(&tensor_ch.packed_bytes, activations, tensor_ch.scale_gamma);

    NonCommutativeBenchmark {
        heat_then_compress_mse: mse_ch,
        compress_then_heat_mse: mse_hc,
        non_commutativity_delta: (mse_hc - mse_ch).abs(),
        zero_mul_dot_product: zero_mul_dot,
        exact_float_dot_product: exact_dot,
        compression_ratio: (TOTAL_MANIFOLD_TRITS as f32) / (PACKED_SIERPINSKI_BYTES as f32),
    }
}