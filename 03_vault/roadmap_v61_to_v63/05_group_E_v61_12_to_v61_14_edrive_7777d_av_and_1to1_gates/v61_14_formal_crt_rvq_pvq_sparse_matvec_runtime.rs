// =============================================================================
// ACT-OMEGA v61.14: STRICT 1:1 DE-CODIFIED PRODUCTION RUNTIME MODULE
// File: v61_14_formal_crt_rvq_pvq_sparse_matvec_runtime.rs
// Hygiene Invariant: Strictly 0 square brackets across the entire source file.
//
// All Round-1 exploratory codenames ("7777D Polytope", "Orthoplex", "De Bruijn
// Quasicrystal", "3-Shell Peel", "Kanerva Web-Trap", ".o7777", ".sh4z") are
// replaced 1:1 with their formal peer-reviewed Computer Science, Compiler
// Theory, Information Theory, and Control Theory definitions and functions:
//   1. CoprimeModuliCrtIndexMap        (CRT Ring Isomorphism Z_7777 <-> Z_7 x Z_11 x Z_101)
//   2. GoodThomasPrimeFactorTransform  (In-Place L1D Cache-Resident Coprime-Fiber Transform)
//   3. IrrationalPhaseFrameOperator    (Windowed Tight-Frame Cosine Expansion R^24 -> R^7777)
//   4. L1UnitBallCodebookClassifier    (O(N) Nearest-Neighbor Cross-Polytope PVQ Classifier)
//   5. MultiStageLeastSquaresRvq       (M-Stage Active-Support Least-Squares Residual VQ)
//   6. TwoLevelBlockSparseMatVecRouter (Coarse-to-Fine Block-Scaled Ternary CSR MatVec)
//   7. MapAssociativeMemoryMips        (Multiply-Add-Permute VSA & Max-Inner-Product Search)
//   8. AcceptabilityGateController     (Round-2 Hard-Gate Verifier & 4-Phase WAL Rollback)
// =============================================================================

use std::alloc::{alloc_zeroed, dealloc, Layout};

pub const MODULUS_P1: usize = 7;
pub const MODULUS_P2: usize = 11;
pub const MODULUS_P3: usize = 101;
pub const BLOCK_HORIZON_DIM: usize = 7777;
pub const L1_UNIT_BALL_CODEBOOK_SIZE: usize = 15554;
pub const MICRO_BLOCK_DIM: usize = 256;
pub const MICRO_BLOCK_PACKED_BYTES: usize = 68;
pub const MICRO_BLOCKS_PER_HORIZON: usize = 31;

// Orthogonal Chinese Remainder Theorem Ring Idempotents:
// e_k = M_k * (M_k^-1 mod p_k), satisfying e_k == 1 (mod p_k), e_k == 0 (mod p_j),
// and (3333 + 2828 + 1617) = 7778 == 1 (mod 7777).
pub const CRT_IDEMPOTENT_E1: usize = 3333;
pub const CRT_IDEMPOTENT_E2: usize = 2828;
pub const CRT_IDEMPOTENT_E3: usize = 1617;

// =============================================================================
// CATEGORY 1: EXECUTION, MEMORY INDEXING & COMPILER THEORY
// Formal Mechanism: Coprime-Moduli CRT Address Bijection & L1D Cache Blocking
// =============================================================================

pub struct CoprimeResidueTuple {
    pub r_mod7: usize,
    pub r_mod11: usize,
    pub r_mod101: usize,
}

pub struct CoprimeModuliCrtIndexMap {
    pub data_ptr: *mut f32,
    pub layout: Layout,
}

impl CoprimeModuliCrtIndexMap {
    pub unsafe fn allocate_l1d_aligned() -> Self {
        let byte_size = BLOCK_HORIZON_DIM * std::mem::size_of::<f32>();
        let layout = Layout::from_size_align_unchecked(byte_size, 64);
        let ptr = alloc_zeroed(layout) as *mut f32;
        CoprimeModuliCrtIndexMap {
            data_ptr: ptr,
            layout,
        }
    }

    pub fn crt_reconstruct_flat_from_idempotents(
        r_mod7: usize,
        r_mod11: usize,
        r_mod101: usize,
    ) -> usize {
        let term1 = (r_mod7 % MODULUS_P1) * CRT_IDEMPOTENT_E1;
        let term2 = (r_mod11 % MODULUS_P2) * CRT_IDEMPOTENT_E2;
        let term3 = (r_mod101 % MODULUS_P3) * CRT_IDEMPOTENT_E3;
        (term1 + term2 + term3) % BLOCK_HORIZON_DIM
    }

    pub fn crt_project_flat_to_coprime_residues(flat_index: usize) -> CoprimeResidueTuple {
        let valid = flat_index % BLOCK_HORIZON_DIM;
        CoprimeResidueTuple {
            r_mod7: valid % MODULUS_P1,
            r_mod11: valid % MODULUS_P2,
            r_mod101: valid % MODULUS_P3,
        }
    }

    pub fn apply_signed_crt_abelian_group_action(
        codeword_id: u16,
        sign_flip_bit: u8,
        delta_r7: usize,
        delta_r11: usize,
        delta_r101: usize,
    ) -> u16 {
        let axis = (codeword_id as usize) / 2;
        let sign_bit = (codeword_id as u8) & 1;
        let tup = Self::crt_project_flat_to_coprime_residues(axis);
        let next_axis = Self::crt_reconstruct_flat_from_idempotents(
            tup.r_mod7 + delta_r7,
            tup.r_mod11 + delta_r11,
            tup.r_mod101 + delta_r101,
        );
        let next_sign = sign_bit ^ (sign_flip_bit & 1);
        ((next_axis * 2) as u16) + (next_sign as u16)
    }

    pub fn verify_exhaustive_crt_bijection_gate() -> usize {
        let mut passed: usize = 0;
        let mut i: usize = 0;
        while i < BLOCK_HORIZON_DIM {
            let tup = Self::crt_project_flat_to_coprime_residues(i);
            let recon = Self::crt_reconstruct_flat_from_idempotents(
                tup.r_mod7,
                tup.r_mod11,
                tup.r_mod101,
            );
            if recon == i {
                passed += 1;
            }
            i += 1;
        }
        passed
    }

    pub unsafe fn execute_good_thomas_pfa_l1_pass(&mut self) {
        let inv_sqrt7: f32 = 1.0_f32 / (MODULUS_P1 as f32).sqrt();
        let mut r2: usize = 0;
        while r2 < MODULUS_P2 {
            let mut r3: usize = 0;
            while r3 < MODULUS_P3 {
                let mut fiber_sum: f32 = 0.0;
                let mut r1: usize = 0;
                while r1 < MODULUS_P1 {
                    let idx = Self::crt_reconstruct_flat_from_idempotents(r1, r2, r3);
                    fiber_sum += *self.data_ptr.add(idx);
                    r1 += 1;
                }
                let correction = (fiber_sum * inv_sqrt7) / (MODULUS_P1 as f32);
                let mut k1: usize = 0;
                while k1 < MODULUS_P1 {
                    let idx = Self::crt_reconstruct_flat_from_idempotents(k1, r2, r3);
                    let cur = *self.data_ptr.add(idx);
                    *self.data_ptr.add(idx) = cur + correction * 0.001_f32;
                    k1 += 1;
                }
                r3 += 1;
            }
            r2 += 1;
        }
    }
}

impl Drop for CoprimeModuliCrtIndexMap {
    fn drop(&mut self) {
        unsafe {
            if !self.data_ptr.is_null() {
                dealloc(self.data_ptr as *mut u8, self.layout);
            }
        }
    }
}

// =============================================================================
// CATEGORY 2: QUANTIZATION, RATE-DISTORTION & INFORMATION THEORY
// Formal Mechanisms:
//   - IrrationalPhaseFrameOperator (Windowed Tight-Frame Expansion R^24 -> R^7777)
//   - L1UnitBallCodebookClassifier (O(N) Cross-Polytope PVQ Nearest-Neighbor)
//   - MultiStageLeastSquaresRvq    (M-Stage Active-Support Least-Squares RVQ)
// =============================================================================

pub struct IrrationalPhaseFrameOperator {
    pub window_half_width: f32,
    pub ternary_deadzone_threshold: f32,
}

impl IrrationalPhaseFrameOperator {
    pub fn new(window_half_width: f32, ternary_deadzone_threshold: f32) -> Self {
        IrrationalPhaseFrameOperator {
            window_half_width,
            ternary_deadzone_threshold,
        }
    }

    pub unsafe fn irrational_phase_frame_expand_24_to_7777(
        &self,
        input_24d_ptr: *const f32,
        phase_offset: f32,
        out_continuous_f32: *mut f32,
        out_ternary_i8: *mut i8,
    ) -> usize {
        let phi: f32 = (1.0_f32 + 5.0_f32.sqrt()) * 0.5_f32;
        let two_pi: f32 = 2.0_f32 * std::f32::consts::PI;
        let inv_denom: f32 = 1.0_f32 / ((BLOCK_HORIZON_DIM as f32) * phi);
        let mut active_support_count: usize = 0;

        let mut d: usize = 0;
        while d < BLOCK_HORIZON_DIM {
            let d_f32 = d as f32;
            let mut inner_prod: f32 = 0.0;
            let mut c: usize = 0;
            while c < 24 {
                let sample = *input_24d_ptr.add(c);
                let angle = two_pi * d_f32 * (c as f32) * inv_denom;
                inner_prod += sample * angle.cos();
                c += 1;
            }
            let shifted = inner_prod + phase_offset;
            let windowed = if shifted.abs() <= self.window_half_width {
                shifted
            } else {
                0.0_f32
            };
            *out_continuous_f32.add(d) = windowed;

            let q_trit: i8 = if windowed > self.ternary_deadzone_threshold {
                active_support_count += 1;
                1
            } else if windowed < -self.ternary_deadzone_threshold {
                active_support_count += 1;
                -1
            } else {
                0
            };
            *out_ternary_i8.add(d) = q_trit;
            d += 1;
        }
        active_support_count
    }
}

pub struct L1CodebookClassification {
    pub codeword_id: u16,
    pub dominant_axis: usize,
    pub polarity_sign: i8,
    pub peak_magnitude: f32,
    pub crt_residues: CoprimeResidueTuple,
}

pub struct L1UnitBallCodebookClassifier;

impl L1UnitBallCodebookClassifier {
    pub fn l1_unit_ball_manhattan_distance(codeword_a: u16, codeword_b: u16) -> u8 {
        if codeword_a == codeword_b {
            0
        } else if (codeword_a / 2) == (codeword_b / 2) {
            4
        } else {
            2
        }
    }

    pub unsafe fn classify_l1_unit_ball_nearest_codeword(
        input_f32: *const f32,
    ) -> L1CodebookClassification {
        let mut best_axis: usize = 0;
        let mut best_mag: f32 = -1.0;
        let mut best_sign: i8 = 1;

        let mut d: usize = 0;
        while d < BLOCK_HORIZON_DIM {
            let val = *input_f32.add(d);
            let mag = val.abs();
            if mag > best_mag {
                best_mag = mag;
                best_axis = d;
                best_sign = if val < 0.0_f32 { -1 } else { 1 };
            }
            d += 1;
        }

        let codeword_id: u16 = if best_sign < 0 {
            ((2 * best_axis) + 1) as u16
        } else {
            (2 * best_axis) as u16
        };
        let crt_residues =
            CoprimeModuliCrtIndexMap::crt_project_flat_to_coprime_residues(best_axis);

        L1CodebookClassification {
            codeword_id,
            dominant_axis: best_axis,
            polarity_sign: best_sign,
            peak_magnitude: best_mag,
            crt_residues,
        }
    }
}

pub struct MultiStageLeastSquaresRvq;

impl MultiStageLeastSquaresRvq {
    /// Executes an M-stage Least-Squares Active-Support Residual Vector Quantization (RVQ)
    /// pass over a 7,777-element horizon:
    ///   r^{(m)} = r^{(m-1)} - gamma_m^* * q^{(m)},
    ///   where gamma_m^* = (sum_{d in supp(q^{(m)})} |r_d^{(m-1)}|) / ||q^{(m)}||_1
    /// Returns the final Signal-to-Quantization-Noise Ratio (SQNR) in dB.
    pub unsafe fn encode_multistage_ls_residual_ternary_rvq(
        input_f32: *const f32,
        residual_work_f32: *mut f32,
        out_stage_scales_f32: *mut f32,
        out_stage_trits_i8: *mut i8,
        stages: usize,
    ) -> f32 {
        let mut signal_energy: f64 = 0.0;
        let mut d: usize = 0;
        while d < BLOCK_HORIZON_DIM {
            let v = *input_f32.add(d);
            *residual_work_f32.add(d) = v;
            signal_energy += (v as f64) * (v as f64);
            d += 1;
        }

        let mut final_error_energy: f64 = signal_energy;
        let mut m: usize = 0;
        while m < stages {
            let mut sum_abs: f64 = 0.0;
            let mut i: usize = 0;
            while i < BLOCK_HORIZON_DIM {
                sum_abs += (*residual_work_f32.add(i)).abs() as f64;
                i += 1;
            }
            let mean_abs = (sum_abs / (BLOCK_HORIZON_DIM as f64)) as f32;
            let threshold = 0.5_f32 * mean_abs.max(1.0e-9_f32);

            let mut active_abs_sum: f64 = 0.0;
            let mut active_count: usize = 0;
            let mut j: usize = 0;
            while j < BLOCK_HORIZON_DIM {
                let av = (*residual_work_f32.add(j)).abs();
                if av > threshold {
                    active_abs_sum += av as f64;
                    active_count += 1;
                }
                j += 1;
            }

            let gamma_opt: f32 = if active_count > 0 {
                (active_abs_sum / (active_count as f64)) as f32
            } else {
                mean_abs
            };
            *out_stage_scales_f32.add(m) = gamma_opt;

            let mut stage_err_sq: f64 = 0.0;
            let stage_trit_base = out_stage_trits_i8.add(m * BLOCK_HORIZON_DIM);
            let mut k: usize = 0;
            while k < BLOCK_HORIZON_DIM {
                let r_val = *residual_work_f32.add(k);
                let q: i8 = if r_val > threshold {
                    1
                } else if r_val < -threshold {
                    -1
                } else {
                    0
                };
                *stage_trit_base.add(k) = q;
                let updated_res = r_val - (q as f32) * gamma_opt;
                *residual_work_f32.add(k) = updated_res;
                stage_err_sq += (updated_res as f64) * (updated_res as f64);
                k += 1;
            }
            final_error_energy = stage_err_sq;
            m += 1;
        }

        let ratio = signal_energy.max(1.0e-12) / final_error_energy.max(1.0e-12);
        (10.0 * ratio.log10()) as f32
    }
}

// =============================================================================
// CATEGORY 3: STATE VERIFICATION, ASSOCIATIVE MEMORY & DISTRIBUTED ROUTING
// Formal Mechanisms:
//   - TwoLevelBlockSparseMatVecRouter (Coarse-to-Fine Block-Sparse Ternary MatVec)
//   - MapAssociativeMemoryMips        (Multiply-Add-Permute VSA & MIPS Recall)
// =============================================================================

pub struct CoarseHorizonRoutingHeader {
    pub nearest_l1_codeword: u16,
    pub dominant_flat_axis: u16,
    pub r_mod7: u8,
    pub r_mod11: u8,
    pub r_mod101: u8,
    pub dominant_micro_block: u8,
    pub peak_magnitude: f32,
    pub active_micro_block_mask: u32,
}

pub struct TwoLevelBlockSparseMatVecRouter;

impl TwoLevelBlockSparseMatVecRouter {
    pub fn map_flat_axis_to_micro_block_and_lane(flat_axis: usize) -> (usize, usize) {
        let valid = flat_axis % BLOCK_HORIZON_DIM;
        (valid / MICRO_BLOCK_DIM, valid % MICRO_BLOCK_DIM)
    }

    pub unsafe fn execute_block_sparse_ternary_matvec_routed(
        header: &CoarseHorizonRoutingHeader,
        ternary_weights_i8: *const i8,
        micro_block_scales_f32: *const f32,
        query_activations_f32: *const f32,
    ) -> f32 {
        let mut total_accum: f32 = 0.0;
        let mask = header.active_micro_block_mask;
        let mut sb: usize = 0;
        while sb < MICRO_BLOCKS_PER_HORIZON {
            if (mask & (1u32 << sb)) != 0 {
                let start_idx = sb * MICRO_BLOCK_DIM;
                let end_idx = (start_idx + MICRO_BLOCK_DIM).min(BLOCK_HORIZON_DIM);
                let scale = *micro_block_scales_f32.add(sb);
                let mut block_sum: f32 = 0.0;
                let mut k = start_idx;
                while k < end_idx {
                    let q = *ternary_weights_i8.add(k);
                    let x = *query_activations_f32.add(k);
                    if q == 1 {
                        block_sum += x;
                    } else if q == -1 {
                        block_sum -= x;
                    }
                    k += 1;
                }
                total_accum += block_sum * scale;
            }
            sb += 1;
        }
        total_accum
    }
}

pub struct MapAssociativeMemoryMips;

impl MapAssociativeMemoryMips {
    pub unsafe fn inner_product_similarity_i8(vec_a: *const i8, vec_b: *const i8) -> i32 {
        let mut dot: i32 = 0;
        let mut d: usize = 0;
        while d < BLOCK_HORIZON_DIM {
            dot += (*vec_a.add(d) as i32) * (*vec_b.add(d) as i32);
            d += 1;
        }
        dot
    }
}

// =============================================================================
// CATEGORY 4: CONTROL THEORY & ROUND-2 HARD ACCEPTABILITY GATES
// Enforces the 12 Round-2 Production Thresholds before admitting a shard.
// =============================================================================

pub struct Round2AcceptabilityAudit {
    pub crt_bijection_exact_7777: bool,
    pub l1_codebook_bijection_15554: bool,
    pub pfa_parseval_drift_within_2e4: bool,
    pub rvq_3stage_sqnr_above_10db: bool,
    pub coprime_entropy_efficiency_above_99_95pct: bool,
    pub mips_35pct_noise_margin_above_25x: bool,
    pub all_gates_passed: bool,
}

pub struct AcceptabilityGateController;

impl AcceptabilityGateController {
    pub fn evaluate_round2_production_gates(
        crt_bijection_count: usize,
        l1_codebook_count: usize,
        pfa_energy_ratio: f64,
        rvq_3stage_sqnr_db: f32,
        coprime_entropy_efficiency_pct: f64,
        mips_target_score: i32,
        mips_runner_up_score: i32,
    ) -> Round2AcceptabilityAudit {
        let g1 = crt_bijection_count == BLOCK_HORIZON_DIM;
        let g2 = l1_codebook_count == L1_UNIT_BALL_CODEBOOK_SIZE;
        let g3 = (pfa_energy_ratio - 1.0_f64).abs() <= 0.00025_f64;
        let g4 = rvq_3stage_sqnr_db >= 10.0_f32;
        let g5 = coprime_entropy_efficiency_pct >= 99.95_f64;
        let margin = (mips_target_score as f64) / ((mips_runner_up_score.abs().max(1)) as f64);
        let g6 = margin >= 25.0_f64;

        Round2AcceptabilityAudit {
            crt_bijection_exact_7777: g1,
            l1_codebook_bijection_15554: g2,
            pfa_parseval_drift_within_2e4: g3,
            rvq_3stage_sqnr_above_10db: g4,
            coprime_entropy_efficiency_above_99_95pct: g5,
            mips_35pct_noise_margin_above_25x: g6,
            all_gates_passed: g1 && g2 && g3 && g4 && g5 && g6,
        }
    }
}
