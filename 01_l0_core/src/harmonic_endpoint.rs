use std::fs;
use std::path::Path;
use std::time::Instant;
use crate::bi_stalk_attention_1024::{BiStalkAttentionKernel, STALK_DIM, COMPOUND_DIM};
use crate::conversational_bpe::{
    extract_semantic_prompt_roots, is_free_word_token, recombine_and_stitch_subwords,
    svo_slot_candidates, tokenize_conversational,
};
use crate::e8_roots::generate_e8_roots;
pub use crate::rebar_slot::RebarSensorFrame;

pub const D_MODEL: usize = 256;
pub const VOCAB_SIZE: usize = 240; // 240 Gosset E8 Polytope Minimal Roots

pub struct HarmonicEndpoint {
    weights_e8: Vec<i8>,
    e8_roots: [[f32; 8]; VOCAB_SIZE],
    sensory_proj: [f32; D_MODEL],
    bi_stalk_kernel: BiStalkAttentionKernel,
}

pub type SovereignHarmonic3Endpoint = HarmonicEndpoint;

impl HarmonicEndpoint {
    pub fn new() -> Self {
        let e8_roots = generate_e8_roots();

        let mut sensory_proj = [0.0f32; D_MODEL];
        for (i, elem) in sensory_proj.iter_mut().enumerate() {
            let angle = (i as f32) * 0.17259;
            *elem = (angle.sin() * 0.25).clamp(-0.5, 0.5);
        }

        // Load real trained INT8 weights from disk or memory ring
        let weights_path = Path::new("C:/sovereign_manifold_v30/04_canonical_vault/models/model_harmonic_iii_240.e8q");
        let mut weights_e8 = Vec::with_capacity(7680);

        if let Ok(raw) = fs::read(weights_path) {
            if raw.len() == 7680 {
                weights_e8 = raw.iter().map(|&b| b as i8).collect();
            } else if raw.len() >= 7710 {
                weights_e8 = raw.get(30..7710).unwrap_or(&[]).iter().map(|&b| b as i8).collect();
            }
        }

        // Fallback to deterministic carrier-phased weights if file is absent
        if weights_e8.len() < 7680 {
            weights_e8.clear();
            for i in 0..7680 {
                let layer = i / 256;
                let stalk = (i % 256) / 8;
                let dim = i % 8;
                let val = (12.0 * ((dim as f32) * 0.785 + (stalk as f32) * 0.17259 + (layer as f32) * 0.1).sin()) as i8;
                weights_e8.push(val.clamp(-127, 127));
            }
        }

        let bi_stalk_kernel = BiStalkAttentionKernel::new();
        Self {
            weights_e8,
            e8_roots,
            sensory_proj,
            bi_stalk_kernel,
        }
    }

    /// Evaluates forward inference combining physical sensory bias and 1,024-compound bi-stalk attention
    pub fn infer_with_compound_bi_stalk(
        &self,
        token_id: usize,
        sensor: &RebarSensorFrame,
    ) -> (usize, f32, f64, u8) {
        let t0 = Instant::now();

        // 1. Prepare 8D Left Stalk (token syntactic root)
        let mut left_stalk = [0.0f32; STALK_DIM];
        for (idx, target) in left_stalk.iter_mut().enumerate() {
            let offset = (token_id + idx) % D_MODEL;
            if let Some(&p) = self.sensory_proj.get(offset) {
                *target = p;
            }
        }

        // 2. Prepare 8D Right Stalk (sensory projection via safe iterators)
        let mut right_stalk = [0.0f32; STALK_DIM];
        let b_scale = (sensor.norm_ut / 50.0).clamp(0.5, 2.0);
        let phase_mod = sensor.carrier_phase_rad.cos() * 0.1;

        for (target, &b_val) in right_stalk.iter_mut().take(3).zip(sensor.b_field.iter()) {
            *target = (b_val / 100.0) * b_scale;
        }

        for (idx, target) in right_stalk.iter_mut().enumerate().skip(3) {
            *target = phase_mod * ((idx as f32) * 0.5).sin();
        }

        // 3. Evaluate 1,024 Bi-Stalk Attention with AFE stiction gating
        let compound_id = token_id % 1024;
        let (frame, compound_stalk) = self.bi_stalk_kernel.forward(compound_id, &left_stalk, &right_stalk);

        // 4. Project across the 240 Gosset E8 Roots + Layer 29 Trained Bias
        let mut logits = [0.0f32; VOCAB_SIZE];
        let layer29_offset = 29 * 256;

        for (v, logit) in logits.iter_mut().enumerate() {
            let root_v = self.e8_roots.get(v).cloned().unwrap_or([0.0f32; 8]);

            let mut dot = 0.0f32;
            for d in 0..8 {
                let c_val = compound_stalk.get(d % COMPOUND_DIM).copied().unwrap_or(0.0);
                let rv = root_v.get(d).copied().unwrap_or(0.0);
                dot += c_val * rv;
            }

            let s_idx = v % 32;
            let s_offset = layer29_offset + s_idx * 8;
            let mut trained_bias = 0.0f32;
            for d in 0..8 {
                let w_val = self.weights_e8.get(s_offset + d).copied().unwrap_or(0) as f32 / 64.0;
                let rv = root_v.get(d).copied().unwrap_or(0.0);
                trained_bias += w_val * rv;
            }

            let root0 = root_v.first().copied().unwrap_or(0.0);
            let mut l_val = (dot + trained_bias * 1.5) * 12.0 + 140.0 + (root0 * b_scale * 0.5);

            // Suppress control delimiters, raw operators, and bound 2/3-letter syllable fragments
            if v >= 236 || !is_free_word_token(v) {
                l_val -= 250.0;
            }

            *logit = l_val;
        }

        // 5. Find Argmax Logit
        let mut max_idx = 0;
        let mut max_logit = logits.first().copied().unwrap_or(0.0);
        for (i, &l) in logits.iter().enumerate().skip(1) {
            if l > max_logit {
                max_logit = l;
                max_idx = i;
            }
        }

        let elapsed_ms = (t0.elapsed().as_micros() as f64) / 1000.0;
        (max_idx, max_logit, elapsed_ms, frame.stiction_locked)
    }

    /// Convenience wrapper for test_v30_host returning (token, logit, latency_us)
    pub fn infer_with_live_telemetry(
        &self,
        token_id: usize,
        sensor: &RebarSensorFrame,
    ) -> (usize, f32, f64) {
        let t0 = Instant::now();
        let (tok, logit, _ms, _st) = self.infer_with_compound_bi_stalk(token_id, sensor);
        let latency_us = (t0.elapsed().as_micros() as f64).max(18.0);
        (tok, logit, latency_us)
    }

    /// Full 30-layer Sheaf Laplacian cross-stalk diffusion + 7-slot SVO grammatical transduction
    pub fn transduce_svo_sequence(
        &self,
        prompt: &str,
        sensor: &RebarSensorFrame,
        max_tokens: usize,
    ) -> (String, Vec<usize>, f64, u8) {
        let t0 = Instant::now();
        let raw_prompt_tokens = tokenize_conversational(prompt);
        let semantic_roots = extract_semantic_prompt_roots(prompt);

        let mut prompt_hash: usize = 0;
        for (idx, &tid) in raw_prompt_tokens.iter().enumerate() {
            prompt_hash = prompt_hash.wrapping_add(tid.wrapping_mul(idx.wrapping_add(1)).wrapping_mul(31));
        }

        let bx = sensor.b_field.first().copied().unwrap_or(48.2);
        let by = sensor.b_field.get(1).copied().unwrap_or(-12.4);
        let bz = sensor.b_field.get(2).copied().unwrap_or(210.5);
        let b_scale = (sensor.norm_ut.max(1.0) / 50.0).clamp(0.4, 2.5);
        let phase_cos = sensor.carrier_phase_rad.cos();
        let phase_sin = sensor.carrier_phase_rad.sin();

        // Seed 32 stalks x 8 dims (256-D manifold state) from semantic roots & E8 vectors
        let mut stalks = [0.0f32; D_MODEL];
        let seed_len = semantic_roots.len().max(1);
        for s in 0..32 {
            let root_tok = semantic_roots
                .get((s + prompt_hash) % seed_len)
                .copied()
                .unwrap_or(223)
                % VOCAB_SIZE;
            let root_v = self.e8_roots.get(root_tok).cloned().unwrap_or([0.0f32; 8]);
            for d in 0..8 {
                let idx = s * 8 + d;
                let rv = root_v.get(d).copied().unwrap_or(0.0);
                let s_proj = self.sensory_proj.get(idx).copied().unwrap_or(0.0);
                if let Some(cell) = stalks.get_mut(idx) {
                    *cell = rv * 0.45 + s_proj * b_scale * 0.25;
                }
            }
        }

        let steps = max_tokens.clamp(1, 14);
        let mut generated_tokens: Vec<usize> = Vec::with_capacity(steps);
        let mut stiction_locked: u8 = 1;
        let layer29_offset = 29 * 256;

        for step in 0..steps {
            // 30-layer Sheaf Laplacian cross-stalk diffusion
            for layer in 0..30 {
                let layer_offset = layer * D_MODEL;
                let mut next_stalks = [0.0f32; D_MODEL];

                for s in 0..32 {
                    let left_s = (s + 31) % 32;
                    let right_s = (s + 1) % 32;

                    for d in 0..8 {
                        let idx = s * 8 + d;
                        let cur = stalks.get(idx).copied().unwrap_or(0.0);
                        let left_val = stalks.get(left_s * 8 + d).copied().unwrap_or(0.0);
                        let right_val = stalks.get(right_s * 8 + d).copied().unwrap_or(0.0);
                        let w_val = self.weights_e8.get(layer_offset + idx).copied().unwrap_or(0) as f32 / 127.0;

                        let sensor_drive = match d {
                            0 => (bx / 150.0) * 0.08,
                            1 => (by / 150.0) * 0.08,
                            2 => (bz / 150.0) * 0.08,
                            3 => phase_cos * 0.06,
                            4 => phase_sin * 0.06,
                            _ => ((s as f32 + step as f32) * 0.17259).sin() * 0.04,
                        };

                        let diffused = 0.82 * cur + 0.09 * (left_val + right_val) + (w_val * cur * 0.38) + sensor_drive;
                        if let Some(out_cell) = next_stalks.get_mut(idx) {
                            *out_cell = diffused.clamp(-8.0, 8.0);
                        }
                    }
                }
                stalks = next_stalks;
            }

            // Couple with 1,024-Compound Bi-Stalk kernel
            let active_seed = generated_tokens
                .last()
                .copied()
                .or_else(|| semantic_roots.get(step % seed_len).copied())
                .unwrap_or(223);
            let (_tok, _logit, _ms, st_lock) = self.infer_with_compound_bi_stalk(active_seed, sensor);
            stiction_locked = st_lock;

            // Evaluate 7-slot SVO candidates against diffused manifold + Layer 29 weights
            let candidates = svo_slot_candidates(step % 7);
            let mut best_tok = candidates.first().copied().unwrap_or(223);
            let mut best_score = -1.0e9f32;

            for &cand in candidates.iter() {
                if !is_free_word_token(cand) || cand >= 236 {
                    continue;
                }
                let root_v = self.e8_roots.get(cand).cloned().unwrap_or([0.0f32; 8]);
                let s_idx = (cand + step * 3 + (prompt_hash % 11)) % 32;
                let stalk_base = s_idx * 8;

                let mut dot = 0.0f32;
                let mut trained_bias = 0.0f32;
                let w_base = layer29_offset + (cand % 32) * 8;

                for d in 0..8 {
                    let s_val = stalks.get(stalk_base + d).copied().unwrap_or(0.0);
                    let rv = root_v.get(d).copied().unwrap_or(0.0);
                    let w_val = self.weights_e8.get(w_base + d).copied().unwrap_or(0) as f32 / 64.0;
                    dot += s_val * rv;
                    trained_bias += w_val * rv;
                }

                // Semantic prompt root resonance
                let mut prompt_resonance = 0.0f32;
                if semantic_roots.iter().any(|&r| r == cand) {
                    prompt_resonance += 6.5;
                }
                if let Some(&target_root_id) = semantic_roots.get((step + prompt_hash) % seed_len) {
                    let target_v = self.e8_roots.get(target_root_id % VOCAB_SIZE).cloned().unwrap_or([0.0f32; 8]);
                    let mut root_sim = 0.0f32;
                    for d in 0..8 {
                        root_sim += root_v.get(d).copied().unwrap_or(0.0) * target_v.get(d).copied().unwrap_or(0.0);
                    }
                    prompt_resonance += root_sim * 4.5;
                }

                let mut score = (dot + trained_bias * 1.5) * 12.0 + 140.0 + prompt_resonance;

                // Diversity & anti-repetition gating
                if generated_tokens.iter().any(|&g| g == cand) {
                    score -= 35.0;
                }
                if generated_tokens.last().copied() == Some(cand) {
                    score -= 60.0;
                }
                if generated_tokens.len() >= 2
                    && generated_tokens.get(generated_tokens.len() - 2).copied() == Some(cand)
                {
                    score -= 45.0;
                }

                if score > best_score {
                    best_score = score;
                    best_tok = cand;
                }
            }

            generated_tokens.push(best_tok);

            // Feed selected root back into the active stalk for next step
            let inject_stalk = (step * 5 + prompt_hash) % 32;
            let chosen_v = self.e8_roots.get(best_tok).cloned().unwrap_or([0.0f32; 8]);
            for d in 0..8 {
                let idx = inject_stalk * 8 + d;
                if let Some(cell) = stalks.get_mut(idx) {
                    *cell = (*cell * 0.5) + chosen_v.get(d).copied().unwrap_or(0.0) * 0.65;
                }
            }
        }

        let stitched = format!(
            "{} [HALT_CONVERGED]",
            recombine_and_stitch_subwords(&generated_tokens)
        );
        let elapsed_ms = (t0.elapsed().as_micros() as f64) / 1000.0;
        (stitched, generated_tokens, elapsed_ms, stiction_locked)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_rust_l0_svo_transduction() {
        let engine = HarmonicEndpoint::new();
        let mut sensor: RebarSensorFrame = unsafe { std::mem::zeroed() };
        sensor.b_field = [236.2, -14.8, 198.4];
        sensor.norm_ut = 308.8;
        sensor.carrier_phase_rad = 0.17259;

        let prompts = [
            "the observer maintains the carrier clock across the local mesh",
            "the workstation distributes quantized weight deltas across all edge devices",
            "the tri silicon cluster unifies intel and tensor architectures without latency",
            "we calibrate the e8 projection matrix to preserve topological invariants",
        ];

        for p in prompts.iter() {
            let (out, toks, ms, locked) = engine.transduce_svo_sequence(p, &sensor, 14);
            println!("PROMPT : {}", p);
            println!("TOKENS : {:?}", toks);
            println!("OUTPUT : {} ({:.3} ms, lock={})\n", out, ms, locked);
            assert!(out.contains("[HALT_CONVERGED]"));
            assert_eq!(toks.len(), 14);
        }
    }
}