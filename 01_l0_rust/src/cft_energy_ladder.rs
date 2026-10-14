// 01_l0_core/src/cft_energy_ladder.rs
// v30 Track 14: Cardy CFT Energy Ladder Spectral Calibration over 32 Stalks (L = 32)
// E_n = E_0 + (2 * pi * v_F / L) * (Delta_0 + n)
// Zero-Square-Bracket Rust Invariant Enforced

use crate::sierpinski_158_quantizer::MANIFOLD_STALKS;

pub const ISING_CFT_SPIN_DELTA: f32 = 0.125;
pub const CRITICAL_RESONANCE_HZ: f32 = 15.0;

pub struct CftEnergyLadderReport {
    pub energy_levels: Vec<f32>,
    pub mean_level_spacing: f32,
    pub spacing_variance: f32,
    pub recovered_scaling_delta: f32,
}

pub fn calibrate_cardy_cft_energy_ladder(ground_energy_e0: f32, fermi_velocity: f32) -> CftEnergyLadderReport {
    let l_float = MANIFOLD_STALKS as f32;
    let unit_gap = 2.0 * std::f32::consts::PI * fermi_velocity / l_float;
    let mut energy_levels: Vec<f32> = Vec::with_capacity(MANIFOLD_STALKS);

    let mut n: usize = 0;
    while n < MANIFOLD_STALKS {
        let e_n = ground_energy_e0 + unit_gap * (ISING_CFT_SPIN_DELTA + n as f32);
        energy_levels.push(e_n);
        n += 1;
    }

    let mut gap_sum: f32 = 0.0;
    let mut gaps: Vec<f32> = Vec::with_capacity(MANIFOLD_STALKS - 1);
    let mut k: usize = 0;
    while k + 1 < MANIFOLD_STALKS {
        let e_curr = *energy_levels.get(k).unwrap_or(&0.0);
        let e_next = *energy_levels.get(k + 1).unwrap_or(&0.0);
        let g = e_next - e_curr;
        gap_sum += g;
        gaps.push(g);
        k += 1;
    }
    let mean_level_spacing = gap_sum / (gaps.len() as f32);

    let mut var_acc: f32 = 0.0;
    for g in gaps.iter() {
        let diff = *g - mean_level_spacing;
        var_acc += diff * diff;
    }
    let spacing_variance = var_acc / (gaps.len() as f32);

    let e_first = *energy_levels.first().unwrap_or(&0.0);
    let recovered_scaling_delta = (e_first - ground_energy_e0) / mean_level_spacing.max(1.0e-6);

    CftEnergyLadderReport {
        energy_levels,
        mean_level_spacing,
        spacing_variance,
        recovered_scaling_delta,
}
}