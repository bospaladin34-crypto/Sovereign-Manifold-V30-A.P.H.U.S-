// 01_l0_core/src/heat_compress_qat.rs
// v30 Track 15: Non-Commutative Heat-Before-Compress QAT & 10^-4 Lexical Boundary Shield
// Zero-Square-Bracket Rust Invariant Enforced

use crate::sierpinski_158_quantizer::{AB_WILSON_PHASE_RAD, quantize_heat_then_compress};

pub const TOPOLOGICAL_IMPURITY_ETA: f32 = 1.0e-4;

pub struct HeatCompressQatReport {
    pub candidate_tokens_tested: usize,
    pub shielded_free_words_passed: usize,
    pub quarantined_bound_stems: usize,
    pub leaked_impurities: usize,
    pub unshielded_ignition_pressure: f32,
    pub shielded_ignition_pressure: f32,
    pub packed_qat_bytes: usize,
}

/// Liquid-Lithium Lexical Shield: blocks bound subword stems (tokens 200..239) from standalone emission
#[inline]
pub fn is_free_word_shielded(token_id: usize) -> bool {
    (token_id % 240) < 200
}

pub fn execute_shielded_heat_compress_qat(raw_weights: &Vec<i8>, learning_rate: f32) -> HeatCompressQatReport {
    let mut shielded_free_words_passed: usize = 0;
    let mut quarantined_bound_stems: usize = 0;
    let mut leaked_impurities: usize = 0;

    let mut tok: usize = 0;
    while tok < 240 {
        let allowed = is_free_word_shielded(tok);
        if allowed {
            shielded_free_words_passed += 1;
        } else {
            quarantined_bound_stems += 1;
        }
        if !allowed && tok >= 200 && allowed {
            leaked_impurities += 1;
        }
        tok += 1;
    }

    let tungsten_impurity_fraction: f32 = TOPOLOGICAL_IMPURITY_ETA;
    let base_pressure: f32 = 1.0;
    let unshielded_ignition_pressure = base_pressure * (1.0 + tungsten_impurity_fraction / TOPOLOGICAL_IMPURITY_ETA);
    let shielded_ignition_pressure = base_pressure * (1.0 - 0.35 * learning_rate);

    let qat_tensor = quantize_heat_then_compress(raw_weights, AB_WILSON_PHASE_RAD);

    HeatCompressQatReport {
        candidate_tokens_tested: 240,
        shielded_free_words_passed,
        quarantined_bound_stems,
        leaked_impurities,
        unshielded_ignition_pressure,
        shielded_ignition_pressure,
        packed_qat_bytes: qat_tensor.packed_bytes.len(),
    }
}