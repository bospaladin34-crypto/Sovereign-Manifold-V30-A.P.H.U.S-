// 01_l0_core/src/braid_attention.rs
// Cycle 1: Non-Abelian Braid-IR Attention Coupling (Harmonic III-B)
// Replaces quadratic O(N^2) softmax with O(N) 2-Phase Alternating Braid Loom
// Enforces strict Zero-Square-Bracket slice bounds safety and unitary energy conservation

use crate::rebar_slot::RebarSensorFrame;

pub const NUM_STALKS: usize = 32;
pub const STALK_DIM: usize = 8;
pub const LATENT_DIM: usize = NUM_STALKS * STALK_DIM; // 256
pub const THALAMIC_PHASE_DELTA: f32 = 0.17259029; // nu_p invariant

pub struct BraidAttentionLayer {
    pub base_theta: f32,
    pub coupling_weight: f32,
}

impl BraidAttentionLayer {
    pub fn new() -> Self {
        Self {
            base_theta: THALAMIC_PHASE_DELTA,
            coupling_weight: 1.0,
        }
    }

    /// Executes the 2-Phase Alternating Braid Loom across all 32 8D stalks in-place
    /// Phase 1: Even crossings sigma_0, sigma_2, ..., sigma_30 (far-commuting parallel)
    /// Phase 2: Odd crossings sigma_1, sigma_3, ..., sigma_29 (far-commuting parallel)
    pub fn forward_braid_loom(&self, state: &mut [f32], sensor: &RebarSensorFrame) {
        if state.len() < LATENT_DIM {
            return;
        }

        // Live hardware modulation of the braiding angle
        let phase_mod = (sensor.carrier_phase_rad.cos() * 0.05).clamp(-0.1, 0.1);
        let b_scale = (sensor.norm_ut / 50.0).clamp(0.8, 1.2);
        let theta = (self.base_theta + phase_mod) * b_scale;
        let c = theta.cos();
        let s = theta.sin();

        // Phase 1: Even Crossings sigma_{2k} (Strand 2k and 2k+1)
        for k in 0..(NUM_STALKS / 2) {
            let idx_a = (2 * k) * STALK_DIM;
            let idx_b = (2 * k + 1) * STALK_DIM;
            Self::rotate_stalk_pair(state, idx_a, idx_b, c, s);
        }

        // Phase 2: Odd Crossings sigma_{2k+1} (Strand 2k+1 and 2k+2)
        for k in 0..((NUM_STALKS - 2) / 2) {
            let idx_a = (2 * k + 1) * STALK_DIM;
            let idx_b = (2 * k + 2) * STALK_DIM;
            Self::rotate_stalk_pair(state, idx_a, idx_b, c, s);
        }
    }

    /// Unitary Givens rotation of two adjacent 8D stalks: H'_a = c*Ha - s*Hb, H'_b = s*Ha + c*Hb
    /// Preserves exact L2 norm: ||H'_a||^2 + ||H'_b||^2 == ||Ha||^2 + ||Hb||^2
    fn rotate_stalk_pair(state: &mut [f32], idx_a: usize, idx_b: usize, c: f32, s: f32) {
        if idx_b + STALK_DIM > state.len() {
            return;
        }

        // Safe split without unchecked square brackets
        let (first_part, rest) = state.split_at_mut(idx_b);
        let stalk_a = first_part.split_at_mut(idx_a).1;
        let stalk_b = rest;

        for (ha, hb) in stalk_a.iter_mut().take(STALK_DIM).zip(stalk_b.iter_mut().take(STALK_DIM)) {
            let a = *ha;
            let b = *hb;
            *ha = c * a - s * b;
            *hb = s * a + c * b;
        }
    }

    /// Compute L2 norm of the entire 256D latent state
    pub fn compute_l2_norm(state: &[f32]) -> f32 {
        state.iter().map(|&x| x * x).sum::<f32>().sqrt()
    }
}