//! E8 Second-Shell Vector System (2,160 Magic State Distillation Polytope)
//! Norm Squared |f|^2 = 4.0 across R^8. Enforces strict zero-square-bracket memory safety.

pub const E8_SHELL2_COUNT: usize = 2160;
pub const E8_DIM: usize = 8;

/// Generates the 2,160 second-shell vectors of the E8 lattice in R^8.
/// - 16 vectors of type (+-2, 0^7)
/// - 1,120 vectors of type (+-1^4, 0^4)
/// - 1,024 vectors of type (+-1.5, +-0.5^7) with even coordinate sum
pub fn generate_e8_shell2() -> [[f32; E8_DIM]; E8_SHELL2_COUNT] {
    let mut shell2 = [[0.0f32; E8_DIM]; E8_SHELL2_COUNT];
    let mut idx = 0;

    // Type 1: (+-2, 0^7) -> 16 vectors
    for i in 0..8 {
        for &s in &[-2.0f32, 2.0f32] {
            if let Some(slot) = shell2.get_mut(idx) {
                if let Some(c) = slot.get_mut(i) { *c = s; }
            }
            idx += 1;
        }
    }

    // Type 2: (+-1^4, 0^4) -> 70 * 16 = 1120 vectors
    for i in 0..8 {
        for j in (i + 1)..8 {
            for k in (j + 1)..8 {
                for l in (k + 1)..8 {
                    for signs in 0u8..16 {
                        if let Some(slot) = shell2.get_mut(idx) {
                            let s_i = if (signs & 1) != 0 { -1.0f32 } else { 1.0f32 };
                            let s_j = if (signs & 2) != 0 { -1.0f32 } else { 1.0f32 };
                            let s_k = if (signs & 4) != 0 { -1.0f32 } else { 1.0f32 };
                            let s_l = if (signs & 8) != 0 { -1.0f32 } else { 1.0f32 };
                            if let Some(c) = slot.get_mut(i) { *c = s_i; }
                            if let Some(c) = slot.get_mut(j) { *c = s_j; }
                            if let Some(c) = slot.get_mut(k) { *c = s_k; }
                            if let Some(c) = slot.get_mut(l) { *c = s_l; }
                        }
                        idx += 1;
                    }
                }
            }
        }
    }

    // Type 3: (+-1.5, +-0.5^7) with even coordinate sum -> 8 * 128 = 1024 vectors
    for i in 0..8 {
        for mask in 0u16..256 {
            let mut sum_coords = 0.0f32;
            let mut v = [0.0f32; 8];
            for bit in 0..8 {
                let mag = if bit == i { 1.5f32 } else { 0.5f32 };
                let val = if (mask & (1 << bit)) != 0 { -mag } else { mag };
                if let Some(c) = v.get_mut(bit) { *c = val; }
                sum_coords += val;
            }
            if (sum_coords.round() as i32) % 2 == 0 {
                if let Some(slot) = shell2.get_mut(idx) {
                    *slot = v;
                }
                idx += 1;
            }
        }
    }

    shell2
}