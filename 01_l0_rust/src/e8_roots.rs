//! E8 Root Vector System and 240-Root Polytope Generator
//! Mapped 1:1 to the 240 root vectors of the Gosset 4_21 polytope in R^8.

pub const E8_ROOT_COUNT: usize = 240;
pub const E8_DIM: usize = 8;

/// Generates the canonical 240 root vectors of the E8 lattice in R^8.
/// - 112 roots of type (±1, ±1, 0, 0, 0, 0, 0, 0)
/// - 128 roots of type (±0.5, ±0.5, ..., ±0.5) with an even number of minus signs
pub fn generate_e8_roots() -> [[f32; E8_DIM]; E8_ROOT_COUNT] {
    let mut roots = [[0.0f32; E8_DIM]; E8_ROOT_COUNT];
    let mut idx = 0;

    // Type 1: 112 roots with two non-zero coordinates ±1
    for i in 0..8 {
        for j in (i + 1)..8 {
            for &s1 in &[-1.0f32, 1.0f32] {
                for &s2 in &[-1.0f32, 1.0f32] {
                    if let Some(slot) = roots.get_mut(idx) {
                        if let Some(c) = slot.get_mut(i) { *c = s1; }
                        if let Some(c) = slot.get_mut(j) { *c = s2; }
                    }
                    idx += 1;
                }
            }
        }
    }

    // Type 2: 128 roots with all coordinates ±0.5 and even sign parity (prod sgn = +1)
    for mask in 0u8..=255u8 {
        if mask.count_ones() % 2 == 0 {
            if let Some(slot) = roots.get_mut(idx) {
                for bit in 0..8 {
                    let s = if (mask & (1 << bit)) != 0 { -0.5f32 } else { 0.5f32 };
                    if let Some(c) = slot.get_mut(bit) { *c = s; }
                }
            }
            idx += 1;
        }
    }

    roots
}

/// Precomputed 240x240 integer Gram matrix for E8 roots.
/// For any two roots alpha, beta in Phi(E8), <alpha, beta> in {-2, -1, 0, 1, 2}.
pub fn generate_e8_gram_matrix(roots: &[[f32; E8_DIM]; E8_ROOT_COUNT]) -> [[i8; E8_ROOT_COUNT]; E8_ROOT_COUNT] {
    let mut gram = [[0i8; E8_ROOT_COUNT]; E8_ROOT_COUNT];
    for (i, r1) in roots.iter().enumerate() {
        for (j, r2) in roots.iter().enumerate() {
            let dot: f32 = r1.iter().zip(r2.iter()).map(|(a, b)| a * b).sum();
            let dot_int = dot.round() as i8;
            if let Some(row) = gram.get_mut(i) {
                if let Some(val) = row.get_mut(j) {
                    *val = dot_int;
                }
            }
        }
    }
    gram
}
