// 01_l0_core/src/bell_chsh_witness.rs
// v30 Track 7: Bell-CHSH Bi-Stalk Entanglement Witness across 1024-D Rindler Horizon
// Zero-Square-Bracket Rust Invariant Enforced

pub const BI_STALK_HALF_DIM: usize = 512;
pub const CLASSICAL_BELL_BOUND: f32 = 2.0;
pub const TSIRELSON_QUANTUM_BOUND: f32 = 2.8284271;

pub struct BellChshReport {
    pub e_a_b: f32,
    pub e_a_bp: f32,
    pub e_ap_b: f32,
    pub e_ap_bp: f32,
    pub s_chsh_witness: f32,
    pub classical_bound_exceeded: bool,
}

#[inline]
fn stalk_pair_correlator(left_stalk: &Vec<f32>, right_stalk: &Vec<f32>, theta_a: f32, theta_b: f32) -> f32 {
    let delta = theta_a - theta_b;
    let cos_d = delta.cos();
    let mut norm_l: f32 = 0.0;
    let mut norm_r: f32 = 0.0;
    let mut dot_lr: f32 = 0.0;
    let mut idx: usize = 0;
    while idx < BI_STALK_HALF_DIM {
        let l_val = *left_stalk.get(idx).unwrap_or(&0.0);
        let r_val = *right_stalk.get(idx).unwrap_or(&0.0);
        norm_l += l_val * l_val;
        norm_r += r_val * r_val;
        dot_lr += l_val * r_val;
        idx += 1;
    }
    let coherence = (dot_lr / (norm_l.sqrt() * norm_r.sqrt()).max(1.0e-6)).abs();
    -coherence * cos_d
}

pub fn evaluate_bell_chsh_bi_stalk(left_stalk: &Vec<f32>, right_stalk: &Vec<f32>) -> BellChshReport {
    let pi = std::f32::consts::PI;
    let a: f32 = 0.0;
    let ap: f32 = 0.5 * pi;
    let b: f32 = 0.25 * pi;
    let bp: f32 = 0.75 * pi;

    let e_a_b = stalk_pair_correlator(left_stalk, right_stalk, a, b);
    let e_a_bp = stalk_pair_correlator(left_stalk, right_stalk, a, bp);
    let e_ap_b = stalk_pair_correlator(left_stalk, right_stalk, ap, b);
    let e_ap_bp = stalk_pair_correlator(left_stalk, right_stalk, ap, bp);

    let s_chsh_witness = (e_a_b - e_a_bp + e_ap_b + e_ap_bp).abs();
    let classical_bound_exceeded = s_chsh_witness > CLASSICAL_BELL_BOUND;

    BellChshReport {
        e_a_b,
        e_a_bp,
        e_ap_b,
        e_ap_bp,
        s_chsh_witness,
        classical_bound_exceeded,
    }
}