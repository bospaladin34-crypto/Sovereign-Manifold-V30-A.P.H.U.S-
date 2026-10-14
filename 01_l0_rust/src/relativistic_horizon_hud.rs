// 01_l0_core/src/relativistic_horizon_hud.rs
// v30 Track 5: Black-Hole Event Horizon Shadow (r_s, b_c) & Relativistic Doppler Beaming HUD
// I(theta) = I_0 * [gamma * (1 - beta * cos(theta))]^-3
// Zero-Square-Bracket Rust Invariant Enforced

use crate::sierpinski_158_quantizer::MANIFOLD_STALKS;

pub const DEFAULT_ORBITAL_BETA: f32 = 0.50;
pub const EXPECTED_BEAMING_CONTRAST_27: f32 = 27.0;

pub struct RelativisticHorizonReport {
    pub schwarzschild_radius_rs: f32,
    pub photon_sphere_radius_rph: f32,
    pub critical_shadow_radius_bc: f32,
    pub lorentz_gamma: f32,
    pub approaching_intensity_i0: f32,
    pub receding_intensity_ipi: f32,
    pub beaming_contrast_ratio: f32,
    pub stalk_beamed_intensities: Vec<f32>,
}

pub fn compute_event_horizon_and_beaming(schwarzschild_rs: f32, beta: f32) -> RelativisticHorizonReport {
    let clamped_beta = beta.clamp(0.0, 0.99);
    let lorentz_gamma = 1.0 / (1.0 - clamped_beta * clamped_beta).sqrt();
    let photon_sphere_radius_rph = 1.5 * schwarzschild_rs;
    let critical_shadow_radius_bc = 1.5 * 3.0_f32.sqrt() * schwarzschild_rs;

    let d_app = 1.0 / (lorentz_gamma * (1.0 - clamped_beta));
    let d_rec = 1.0 / (lorentz_gamma * (1.0 + clamped_beta));
    let approaching_intensity_i0 = d_app * d_app * d_app;
    let receding_intensity_ipi = d_rec * d_rec * d_rec;
    let beaming_contrast_ratio = approaching_intensity_i0 / receding_intensity_ipi.max(1.0e-6);

    let mut stalk_beamed_intensities: Vec<f32> = Vec::with_capacity(MANIFOLD_STALKS);
    let two_pi = 2.0 * std::f32::consts::PI;
    let mut s: usize = 0;
    while s < MANIFOLD_STALKS {
        let theta = two_pi * (s as f32) / (MANIFOLD_STALKS as f32);
        let doppler_factor = 1.0 / (lorentz_gamma * (1.0 - clamped_beta * theta.cos()));
        stalk_beamed_intensities.push(doppler_factor * doppler_factor * doppler_factor);
        s += 1;
    }

    RelativisticHorizonReport {
        schwarzschild_radius_rs: schwarzschild_rs,
        photon_sphere_radius_rph,
        critical_shadow_radius_bc,
        lorentz_gamma,
        approaching_intensity_i0,
        receding_intensity_ipi,
        beaming_contrast_ratio,
        stalk_beamed_intensities,
    }
}