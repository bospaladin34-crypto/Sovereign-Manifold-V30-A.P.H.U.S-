//! Dual-Shell Gosset E8 Projection Head (240 Stabilizer + 2,160 Magic State Polytope)
//! Enforces strict zero-square-bracket memory safety via safe iterators and pattern matching.

use crate::e8_roots::{E8_ROOT_COUNT, E8_DIM};
use crate::e8_shell2::E8_SHELL2_COUNT;

pub const SHELL1_COUNT: usize = E8_ROOT_COUNT;  // 240
pub const SHELL2_COUNT: usize = E8_SHELL2_COUNT; // 2,160

pub struct DualShellHead {
    shell1_roots: [[f32; E8_DIM]; SHELL1_COUNT],
    shell2_roots: [[f32; E8_DIM]; SHELL2_COUNT],
    stiction_alpha: f32, // 0.18 nominal
}

impl DualShellHead {
    pub fn new(
        shell1_roots: [[f32; E8_DIM]; SHELL1_COUNT],
        shell2_roots: [[f32; E8_DIM]; SHELL2_COUNT],
    ) -> Self {
        Self {
            shell1_roots,
            shell2_roots,
            stiction_alpha: 0.18,
        }
    }

    pub fn set_stiction(&mut self, alpha: f32) {
        self.stiction_alpha = alpha.clamp(0.0, 1.0);
    }

    /// Evaluates dual-shell projection for an 8D stalk state.
    /// Returns:
    /// - fused_logits: 240-dimensional logit array for token selection
    /// - best_magic_idx: Index of dominant 2,160 second-shell vector
    /// - magic_activation: Peak projection amplitude onto second shell
    pub fn project(&self, stalk: &[f32; E8_DIM]) -> ([f32; SHELL1_COUNT], usize, f32) {
        let mut shell1_logits = [0.0f32; SHELL1_COUNT];
        let mut best_magic_idx = 0usize;
        let mut max_magic_dot = f32::NEG_INFINITY;

        // 1. Shell 1 Dot Products (240 minimal stabilizer roots)
        for (i, r1) in self.shell1_roots.iter().enumerate() {
            let dot: f32 = stalk.iter().zip(r1.iter()).map(|(&a, &b)| a * b).sum();
            if let Some(slot) = shell1_logits.get_mut(i) {
                *slot = dot * 10.0 + 140.0;
            }
        }

        // 2. Shell 2 Projection (2,160 magic state polytope)
        for (j, r2) in self.shell2_roots.iter().enumerate() {
            let dot: f32 = stalk.iter().zip(r2.iter()).map(|(&a, &b)| a * b).sum();
            if dot > max_magic_dot {
                max_magic_dot = dot;
                best_magic_idx = j;
            }
        }

        // 3. Hierarchical Cross-Shell Mana Modulation
        if let Some(magic_vec) = self.shell2_roots.get(best_magic_idx) {
            for (i, r1) in self.shell1_roots.iter().enumerate() {
                let cross_dot: f32 = r1.iter().zip(magic_vec.iter()).map(|(&a, &b)| a * b).sum();
                if let Some(slot) = shell1_logits.get_mut(i) {
                    *slot += cross_dot * self.stiction_alpha * 2.5;
                }
            }
        }

        (shell1_logits, best_magic_idx, max_magic_dot)
    }
}