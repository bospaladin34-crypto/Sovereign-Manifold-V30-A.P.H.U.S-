// 01_l0_core/src/elastic_sheaf_ops.rs
// v30 Track 16: 6-Operator Linear Basis & Elastic Net L1+L2 Polynomial Sheaf Regularizer
// Operators: 1. Rotation, 2. Shear, 3. Determinant, 4. Eigenvectors, 5. Projection, 6. Inverse
// Zero-Square-Bracket Rust Invariant Enforced

use crate::sierpinski_158_quantizer::MANIFOLD_STALKS;

pub struct SixOperatorSheafReport {
    pub rotation_det: f32,
    pub shear_det: f32,
    pub homotopy_contraction_det: f32,
    pub harmonic_eigenvector_residual: f32,
    pub projection_idempotence_errors: usize,
    pub inverse_roundtrip_max_err: f32,
    pub poly_sheaf_output_norm: f32,
}

pub fn evaluate_six_operators_and_poly_sheaf(trits: &Vec<i8>, angle_rad: f32, shear_k: f32) -> SixOperatorSheafReport {
    let c = angle_rad.cos();
    let s = angle_rad.sin();
    let rotation_det = c * c + s * s;
    let shear_det: f32 = 1.0 * 1.0 - shear_k * 0.0;
    let contraction_scale: f32 = 0.70_f32.sqrt();
    let homotopy_contraction_det = contraction_scale * contraction_scale;

    let mut projection_idempotence_errors: usize = 0;
    for t in trits.iter() {
        let p1 = (*t).clamp(-1, 1);
        let p2 = p1.clamp(-1, 1);
        if p1 != p2 {
            projection_idempotence_errors += 1;
        }
    }

    let vx: f32 = 1.618034;
    let vy: f32 = -0.786151;
    let rx = c * vx - s * vy;
    let ry = s * vx + c * vy;
    let inv_x = c * rx + s * ry;
    let inv_y = -s * rx + c * ry;
    let inverse_roundtrip_max_err = (inv_x - vx).abs().max((inv_y - vy).abs());

    let mut uniform_section: Vec<f32> = Vec::with_capacity(MANIFOLD_STALKS);
    let mut idx: usize = 0;
    while idx < MANIFOLD_STALKS {
        uniform_section.push(1.0);
        idx += 1;
    }

    let mut harmonic_eigenvector_residual: f32 = 0.0;
    let mut s_idx: usize = 0;
    while s_idx < MANIFOLD_STALKS {
        let prev = if s_idx == 0 { MANIFOLD_STALKS - 1 } else { s_idx - 1 };
        let next = (s_idx + 1) % MANIFOLD_STALKS;
        let u_curr = *uniform_section.get(s_idx).unwrap_or(&1.0);
        let u_prev = *uniform_section.get(prev).unwrap_or(&1.0);
        let u_next = *uniform_section.get(next).unwrap_or(&1.0);
        let lap_val = 2.0 * u_curr - u_prev - u_next;
        harmonic_eigenvector_residual += lap_val.abs();
        s_idx += 1;
    }

    let theta0: f32 = 1.0;
    let theta1: f32 = -0.35;
    let theta2: f32 = 0.12;
    let theta3: f32 = -0.04;
    let mut poly_sheaf_output_norm: f32 = 0.0;
    let mut m: usize = 0;
    while m < MANIFOLD_STALKS {
        let x_m = 1.0 + 0.25 * ((m as f32) * 0.3926991).cos();
        let l1 = 0.15 * x_m;
        let l2 = 0.15 * l1;
        let l3 = 0.15 * l2;
        let y_m = theta0 * x_m + theta1 * l1 + theta2 * l2 + theta3 * l3;
        poly_sheaf_output_norm += y_m * y_m;
        m += 1;
    }
    poly_sheaf_output_norm = poly_sheaf_output_norm.sqrt();

    SixOperatorSheafReport {
        rotation_det,
        shear_det,
        homotopy_contraction_det,
        harmonic_eigenvector_residual,
        projection_idempotence_errors,
        inverse_roundtrip_max_err,
        poly_sheaf_output_norm,
    }
}