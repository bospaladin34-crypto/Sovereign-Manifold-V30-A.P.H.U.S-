//! Inter-Stalk Sheaf Cross-Attention Engine (Discrete 0-Laplacian Diffusion)
//! Enforces strict zero-square-bracket memory safety via safe iterators and pattern matching.

pub const NUM_STALKS: usize = 32;
pub const STALK_DIM: usize = 8;
pub const INV_SQRT_D: f32 = 0.35355339f32; // 1.0 / sqrt(8.0)

/// Block-diagonal SO(8) Givens rotation for stalk connection transport.
#[inline(always)]
pub fn apply_givens_so8(vec: &[f32; STALK_DIM], phase_shift: f32) -> [f32; STALK_DIM] {
    let mut out = [0.0f32; STALK_DIM];
    for b in 0..4 {
        let theta = phase_shift * (b as f32 + 1.0) * 1.61803398875f32;
        let c = theta.cos();
        let s = theta.sin();
        let x0 = vec.get(b * 2).copied().unwrap_or(0.0);
        let x1 = vec.get(b * 2 + 1).copied().unwrap_or(0.0);
        if let Some(slot) = out.get_mut(b * 2) {
            *slot = c * x0 - s * x1;
        }
        if let Some(slot) = out.get_mut(b * 2 + 1) {
            *slot = s * x0 + c * x1;
        }
    }
    out
}

pub struct SheafCrossAttention {
    diffusion_step: f32, // 0.18 nominal stiction
}

impl SheafCrossAttention {
    pub fn new() -> Self {
        Self { diffusion_step: 0.18 }
    }

    pub fn set_step(&mut self, gamma: f32) {
        self.diffusion_step = gamma.clamp(0.01, 0.5);
    }

    /// Evaluates 1 layer of discrete Sheaf Cross-Attention across all 32 stalks.
    /// Returns:
    /// - updated_stalks: [[f32; 8]; 32]
    /// - dirichlet_energy: f32 (total topological obstruction)
    pub fn forward(
        &self,
        stalks: &[[f32; STALK_DIM]; NUM_STALKS],
    ) -> ([[f32; STALK_DIM]; NUM_STALKS], f32) {
        let mut updated = [[0.0f32; STALK_DIM]; NUM_STALKS];
        let mut total_dirichlet_energy = 0.0f32;

        let nbr_offsets: [(isize, f32); 4] = [
            (-1, -0.17f32),
            (1, 0.17f32),
            (8, 0.68f32),
            (-8, -0.68f32),
        ];

        for u in 0..NUM_STALKS {
            let x_u = stalks.get(u).cloned().unwrap_or([0.0f32; STALK_DIM]);

            // 1. Transport neighbor stalks through SO(8) connection matrices
            let mut transported = [[0.0f32; STALK_DIM]; 4];
            let mut raw_scores = [0.0f32; 4];

            for (k, &(offset, phase)) in nbr_offsets.iter().enumerate() {
                let v = ((u as isize + offset + NUM_STALKS as isize) as usize) % NUM_STALKS;
                let x_v = stalks.get(v).cloned().unwrap_or([0.0f32; STALK_DIM]);
                let w_k = apply_givens_so8(&x_v, phase);
                if let Some(slot) = transported.get_mut(k) {
                    *slot = w_k;
                }
                let dot: f32 = x_u.iter().zip(w_k.iter()).map(|(&a, &b)| a * b).sum();
                if let Some(slot) = raw_scores.get_mut(k) {
                    *slot = dot * INV_SQRT_D;
                }
            }

            // 2. Softmax attention weights over the 4 topological neighbors
            let max_score = raw_scores.iter().cloned().fold(f32::NEG_INFINITY, f32::max);
            let mut exp_scores = [0.0f32; 4];
            let mut sum_exp = 0.0f32;
            for (k, &s) in raw_scores.iter().enumerate() {
                let e = (s - max_score).exp();
                if let Some(slot) = exp_scores.get_mut(k) {
                    *slot = e;
                }
                sum_exp += e;
            }
            let sum_exp_safe = sum_exp.max(1e-12);
            let mut attn = [0.0f32; 4];
            for (k, &e) in exp_scores.iter().enumerate() {
                if let Some(slot) = attn.get_mut(k) {
                    *slot = e / sum_exp_safe;
                }
            }

            // 3. Sheaf Laplacian diffusion step: Delta x_u = sum_k A_k (w_k - x_u)
            let mut diff = [0.0f32; STALK_DIM];
            for (k, &w_k) in transported.iter().enumerate() {
                let a_k = attn.get(k).copied().unwrap_or(0.25f32);
                let mut dist_sq = 0.0f32;
                for d in 0..STALK_DIM {
                    let u_val = x_u.get(d).copied().unwrap_or(0.0);
                    let w_val = w_k.get(d).copied().unwrap_or(0.0);
                    let delta = w_val - u_val;
                    if let Some(slot) = diff.get_mut(d) {
                        *slot += a_k * delta;
                    }
                    dist_sq += delta * delta;
                }
                total_dirichlet_energy += a_k * dist_sq;
            }

            // 4. Update stalk state with stiction damping
            if let Some(slot) = updated.get_mut(u) {
                for d in 0..STALK_DIM {
                    let u_val = x_u.get(d).copied().unwrap_or(0.0);
                    let d_val = diff.get(d).copied().unwrap_or(0.0);
                    if let Some(c) = slot.get_mut(d) {
                        *c = u_val + self.diffusion_step * d_val;
                    }
                }
            }
        }

        (updated, total_dirichlet_energy)
    }
}