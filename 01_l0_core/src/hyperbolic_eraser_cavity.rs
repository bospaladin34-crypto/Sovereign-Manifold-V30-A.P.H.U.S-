// 01_l0_core/src/hyperbolic_eraser_cavity.rs
// v30 Track 3 & Track 6: Hyperbolic Wave Attractor Cavity Boundary
// & Complementary cos^2 / sin^2 Quantum Eraser Dual-Clause SVO Gate
// Zero-Square-Bracket Rust Invariant Enforced

use crate::sierpinski_158_quantizer::{MANIFOLD_LAYERS, MANIFOLD_STALKS};

pub const VOCAB_SIZE_240: usize = 240;
pub const SVO_CLAUSE_LEN: usize = 7;
pub const TOTAL_SVO_SLOTS: usize = 14;

pub struct HyperbolicCavityReport {
    pub stalk_energies: Vec<f32>,
    pub initial_l2_norm: f32,
    pub final_l2_norm: f32,
    pub initial_top3_concentration: f32,
    pub final_top3_concentration: f32,
    pub attractor_focus_gain: f32,
}

pub struct DualClauseEraserReport {
    pub clause1_tokens: Vec<usize>,
    pub clause2_tokens: Vec<usize>,
    pub inter_clause_overlap_count: usize,
    pub mean_orthogonality_sum: f32,
}

/// Tilted Hyperbolic Cavity Boundary Walls at stalks s in {0, 7, 15, 23, 31}
#[inline]
pub fn is_tilted_cavity_wall(stalk: usize) -> bool {
    stalk == 0 || stalk == 7 || stalk == 15 || stalk == 23 || stalk == 31
}

/// Propagate 30-Layer Sheaf Diffusion inside the Tilted Hyperbolic Wave Attractor Cavity
pub fn propagate_hyperbolic_cavity(initial_stalks: &Vec<f32>) -> HyperbolicCavityReport {
    let mut current = Vec::with_capacity(MANIFOLD_STALKS);
    let mut init_norm_sq: f32 = 0.0;
    let mut s_idx: usize = 0;
    while s_idx < MANIFOLD_STALKS {
        let v = *initial_stalks.get(s_idx).unwrap_or(&0.0);
        init_norm_sq += v * v;
        current.push(v);
        s_idx += 1;
    }
    let initial_l2_norm = init_norm_sq.sqrt().max(1.0e-6);
    let initial_top3_concentration = top3_energy_fraction(&current);

    let mut next_buf = Vec::with_capacity(MANIFOLD_STALKS);
    let mut k: usize = 0;
    while k < MANIFOLD_STALKS {
        next_buf.push(0.0);
        k += 1;
    }

    let mut layer: usize = 0;
    while layer < MANIFOLD_LAYERS {
        let mut stalk: usize = 0;
        while stalk < MANIFOLD_STALKS {
            let prev_s = if stalk == 0 { MANIFOLD_STALKS - 1 } else { stalk - 1 };
            let next_s = (stalk + 1) % MANIFOLD_STALKS;
            let focal_target = (stalk * 3 + 7) % MANIFOLD_STALKS;

            let e_self = *current.get(stalk).unwrap_or(&0.0);
            let e_prev = *current.get(prev_s).unwrap_or(&0.0);
            let e_next = *current.get(next_s).unwrap_or(&0.0);
            let e_focal = *current.get(focal_target).unwrap_or(&0.0);

            let updated = if stalk == 3 || stalk == 11 || stalk == 19 {
                0.76 * e_self + 0.14 * (e_prev + e_next) + 0.12 * e_focal
            } else if is_tilted_cavity_wall(stalk) {
                0.42 * e_self + 0.38 * e_next - 0.18 * e_prev
            } else {
                0.58 * e_self + 0.16 * (e_prev + e_next)
            };
            if let Some(slot) = next_buf.get_mut(stalk) {
                *slot = updated;
            }
            stalk += 1;
        }

        let mut step_norm_sq: f32 = 0.0;
        for val in next_buf.iter() {
            step_norm_sq += val * val;
        }
        let renorm = initial_l2_norm / step_norm_sq.sqrt().max(1.0e-6);
        let mut copy_idx: usize = 0;
        while copy_idx < MANIFOLD_STALKS {
            let v = *next_buf.get(copy_idx).unwrap_or(&0.0) * renorm;
            if let Some(c_slot) = current.get_mut(copy_idx) {
                *c_slot = v;
            }
            copy_idx += 1;
        }
        layer += 1;
    }

    let mut final_norm_sq: f32 = 0.0;
    for val in current.iter() {
        final_norm_sq += val * val;
    }
    let final_l2_norm = final_norm_sq.sqrt();
    let final_top3_concentration = top3_energy_fraction(&current);
    let attractor_focus_gain = final_top3_concentration / initial_top3_concentration.max(1.0e-6);

    HyperbolicCavityReport {
        stalk_energies: current,
        initial_l2_norm,
        final_l2_norm,
        initial_top3_concentration,
        final_top3_concentration,
        attractor_focus_gain,
    }
}

fn top3_energy_fraction(stalks: &Vec<f32>) -> f32 {
    let mut total_sq: f32 = 0.0;
    let mut max1: f32 = 0.0;
    let mut max2: f32 = 0.0;
    let mut max3: f32 = 0.0;
    for val in stalks.iter() {
        let sq = val * val;
        total_sq += sq;
        if sq > max1 {
            max3 = max2;
            max2 = max1;
            max1 = sq;
        } else if sq > max2 {
            max3 = max2;
            max2 = sq;
        } else if sq > max3 {
            max3 = sq;
        }
    }
    (max1 + max2 + max3) / total_sq.max(1.0e-6)
}

/// Complementary cos^2(Delta_phi/2) (Clause 1) & sin^2(Delta_phi/2) (Clause 2) Quantum Eraser SVO Gate
pub fn evaluate_dual_clause_quantum_eraser(stalk_energies: &Vec<f32>, prompt_phase_rad: f32) -> DualClauseEraserReport {
    let mut clause1_tokens: Vec<usize> = Vec::with_capacity(SVO_CLAUSE_LEN);
    let mut clause2_tokens: Vec<usize> = Vec::with_capacity(SVO_CLAUSE_LEN);
    let mut orth_sum_acc: f32 = 0.0;
    let mut orth_count: usize = 0;

    let mut slot: usize = 0;
    while slot < SVO_CLAUSE_LEN {
        let mut best_c1_tok: usize = 0;
        let mut best_c1_score: f32 = -1.0e9;
        let mut tok: usize = 0;
        while tok < 200 {
            let stalk_idx = (tok + slot * 5) % MANIFOLD_STALKS;
            let base_amp = stalk_energies.get(stalk_idx).unwrap_or(&0.0).abs() + 0.1;
            let delta_phi = prompt_phase_rad + (tok as f32) * 0.13089969 + (slot as f32) * 0.44879895;
            let half_phi = 0.5 * delta_phi;
            let cos_w = half_phi.cos() * half_phi.cos();
            let sin_w = half_phi.sin() * half_phi.sin();
            orth_sum_acc += cos_w + sin_w;
            orth_count += 1;

            let already_used_c1 = clause1_tokens.iter().any(|&x| x == tok);
            if !already_used_c1 && cos_w > 0.55 {
                let score = base_amp * cos_w;
                if score > best_c1_score {
                    best_c1_score = score;
                    best_c1_tok = tok;
                }
            }
            tok += 1;
        }
        clause1_tokens.push(best_c1_tok);
        slot += 1;
    }

    let mut slot2: usize = 0;
    while slot2 < SVO_CLAUSE_LEN {
        let mut best_c2_tok: usize = 0;
        let mut best_c2_score: f32 = -1.0e9;
        let mut tok: usize = 0;
        while tok < 200 {
            let stalk_idx = (tok + (slot2 + SVO_CLAUSE_LEN) * 5) % MANIFOLD_STALKS;
            let base_amp = stalk_energies.get(stalk_idx).unwrap_or(&0.0).abs() + 0.1;
            let delta_phi = prompt_phase_rad + (tok as f32) * 0.13089969 + (slot2 as f32) * 0.44879895;
            let half_phi = 0.5 * delta_phi;
            let sin_w = half_phi.sin() * half_phi.sin();

            let in_c1 = clause1_tokens.iter().any(|&x| x == tok);
            let in_c2 = clause2_tokens.iter().any(|&x| x == tok);
            if !in_c1 && !in_c2 && sin_w > 0.55 {
                let score = base_amp * sin_w;
                if score > best_c2_score {
                    best_c2_score = score;
                    best_c2_tok = tok;
                }
            }
            tok += 1;
        }
        clause2_tokens.push(best_c2_tok);
        slot2 += 1;
    }

    let mut overlap: usize = 0;
    for c1 in clause1_tokens.iter() {
        if clause2_tokens.iter().any(|c2| c2 == c1) {
            overlap += 1;
        }
    }

    DualClauseEraserReport {
        clause1_tokens,
        clause2_tokens,
        inter_clause_overlap_count: overlap,
        mean_orthogonality_sum: orth_sum_acc / (orth_count as f32),
    }
}