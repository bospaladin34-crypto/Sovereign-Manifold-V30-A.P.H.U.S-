// 01_l0_core/src/sheaf_context_tensor.rs
// v30 Track 3.1: Deep Multi-Hop 2nd-Order Sheaf Transition Tensor (240 x 240 = 57,600 Couplings)
// Sparse-Aware Active-Nonzero Scale Normalization for Sub-2.0 Perplexity
// Zero-Square-Bracket Rust Invariant Enforced

use crate::sierpinski_158_quantizer::{TRITS_PER_BYTE, pack_five_trits, unpack_five_trits};

pub const CONTEXT_VOCAB_DIM: usize = 240;
pub const TOTAL_CONTEXT_COUPLINGS: usize = 57600;
pub const PACKED_CONTEXT_TER_BYTES: usize = 11520;
pub const VAULT_440_CHIRAL_STRIDE: usize = 47;
pub const VAULT_440_INV_MOD_440: usize = 103;

pub struct SheafContextTensor158 {
    pub packed_bytes: Vec<u8>,
    pub unpacked_trits: Vec<i8>,
    pub scale_gamma: f32,
    pub active_couplings: usize,
}

#[inline]
pub fn permute_shard_440(idx: usize, offset: usize) -> usize {
    ((idx % 440) * VAULT_440_CHIRAL_STRIDE + (offset % 440)) % 440
}

pub fn quantize_sheaf_context_tensor(weights_f32: &Vec<f32>) -> SheafContextTensor158 {
    let mut abs_sum: f32 = 0.0;
    let mut nonzero_count: usize = 0;
    for v in weights_f32.iter() {
        let a = v.abs();
        if a > 1.0e-4 {
            abs_sum += a;
            nonzero_count += 1;
        }
    }
    let scale_gamma = (abs_sum / (nonzero_count.max(1) as f32)).max(1.0e-5);
    let threshold = 0.25 * scale_gamma;

    let mut trits: Vec<i8> = Vec::with_capacity(TOTAL_CONTEXT_COUPLINGS);
    let mut active_couplings: usize = 0;
    let mut idx: usize = 0;
    while idx < TOTAL_CONTEXT_COUPLINGS {
        let w = *weights_f32.get(idx).unwrap_or(&0.0);
        let t: i8 = if w > threshold {
            active_couplings += 1;
            1
        } else if w < -threshold {
            active_couplings += 1;
            -1
        } else {
            0
        };
        trits.push(t);
        idx += 1;
    }

    let mut packed_bytes: Vec<u8> = Vec::with_capacity(PACKED_CONTEXT_TER_BYTES);
    let mut b_idx: usize = 0;
    while b_idx < PACKED_CONTEXT_TER_BYTES {
        let base = b_idx * TRITS_PER_BYTE;
        let t0 = *trits.get(base).unwrap_or(&0);
        let t1 = *trits.get(base + 1).unwrap_or(&0);
        let t2 = *trits.get(base + 2).unwrap_or(&0);
        let t3 = *trits.get(base + 3).unwrap_or(&0);
        let t4 = *trits.get(base + 4).unwrap_or(&0);
        packed_bytes.push(pack_five_trits(t0, t1, t2, t3, t4));
        b_idx += 1;
    }

    SheafContextTensor158 {
        packed_bytes,
        unpacked_trits: trits,
        scale_gamma,
        active_couplings,
    }
}

#[inline]
pub fn query_context_trit_zero_mul(packed_bytes: &Vec<u8>, prev2_tok: usize, prev1_tok: usize, tgt_tok: usize) -> i8 {
    let ctx_row = (prev2_tok * 31 + prev1_tok) % CONTEXT_VOCAB_DIM;
    let col = tgt_tok % CONTEXT_VOCAB_DIM;
    let flat_idx = ctx_row * CONTEXT_VOCAB_DIM + col;
    let byte_idx = flat_idx / TRITS_PER_BYTE;
    let sub_idx = flat_idx % TRITS_PER_BYTE;
    let b = *packed_bytes.get(byte_idx).unwrap_or(&0);
    let (t0, t1, t2, t3, t4) = unpack_five_trits(b);
    match sub_idx {
        0 => t0,
        1 => t1,
        2 => t2,
        3 => t3,
        _ => t4,
    }
}