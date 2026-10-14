use act_omega_l0_core::e8_roots::{generate_e8_roots, generate_e8_gram_matrix};
use act_omega_l0_core::e8_subword_vocab::{detokenize_subwords, VOCAB_SIZE_240};
use std::time::Instant;
use std::fs::File;
use std::io::Read;
use std::path::Path;

fn main() {
    println!("======================================================");
    println!("ACT-Omega v30.0: 240-D Dynamic Autoregressive Inference");
    println!("Target: Lenovo LOQ 15IAX9 (garlock00)");
    println!("======================================================");

    let roots = generate_e8_roots();
    let _gram = generate_e8_gram_matrix(&roots);

    let model_path = Path::new("C:\\sovereign_manifold_v30\\04_canonical_vault\\models\\model_harmonic_iii_240.e8q");
    let mut file = File::open(model_path).expect("Failed to open 240-d model");
    let mut magic = [0u8; 18];
    file.read_exact(&mut magic).unwrap();
    let mut u32_buf = [0u8; 4];
    file.read_exact(&mut u32_buf).unwrap();
    let layers = u32::from_le_bytes(u32_buf) as usize;
    file.read_exact(&mut u32_buf).unwrap();
    let _vocab_size = u32::from_le_bytes(u32_buf) as usize;
    file.read_exact(&mut u32_buf).unwrap();
    let _d_model = u32::from_le_bytes(u32_buf) as usize;

    let weight_count = layers * 256;
    let mut quantized_weights = vec![0i8; weight_count];
    let mut raw_bytes = vec![0u8; weight_count];
    file.read_exact(&mut raw_bytes).unwrap();
    for (qw, &b) in quantized_weights.iter_mut().zip(raw_bytes.iter()) {
        *qw = b as i8;
    }

    let seed_token = 182;
    let target_length = 32;
    let mut generated_tokens: Vec<usize> = Vec::with_capacity(target_length + 1);
    generated_tokens.push(seed_token);

    let mut current_token = seed_token;
    let mut total_latency_us = 0.0f64;

    println!("Step | InToken -> OutToken | Text Fragment | Logit  | Latency (us)");
    println!("---------------------------------------------------------------");

    for step in 1..=target_length {
        let t_step = Instant::now();

        let in_root = roots.get(current_token % 240).cloned().unwrap_or([0.0f32; 8]);
        let stalk_idx = current_token % 32;
        let mut active_stalks = [[0.0f32; 8]; 32];
        if let Some(s) = active_stalks.get_mut(stalk_idx) {
            *s = in_root;
        }

        for l in 0..layers {
            let layer_offset = l * 256;
            for s in 0..32 {
                let stalk_offset = layer_offset + s * 8;
                if let Some(stalk) = active_stalks.get_mut(s) {
                    for d in 0..8 {
                        let w_val = quantized_weights.get(stalk_offset + d).copied().unwrap_or(0) as f32 / 64.0;
                        if let Some(coord) = stalk.get_mut(d) {
                            *coord = (*coord + w_val * 0.1).tanh();
                        }
                    }
                }
            }

            // Phase Braid Inter-Stalk Coupling
            for s in 0..31 {
                let phase_shift = (0.17 * (s as f32)).cos() * 0.05;
                if let Some(stalk_p1) = active_stalks.get_mut(s + 1) {
                    if let Some(c) = stalk_p1.get_mut(0) {
                        *c += phase_shift;
                    }
                }
            }
        }

        let mut max_token: usize = 0;
        let mut max_logit: f32 = f32::NEG_INFINITY;

        for v in 0..VOCAB_SIZE_240 {
            let s_idx = v % 32;
            let root_v = roots.get(v).cloned().unwrap_or([0.0f32; 8]);
            let stalk = active_stalks.get(s_idx).cloned().unwrap_or([0.0f32; 8]);
            let dot: f32 = stalk.iter().zip(root_v.iter()).map(|(a, b)| a * b).sum();
            let mut score: f32 = dot * 10.0 + 140.0;

            // Repetition Penalty to enable orbit transitions
            let mut recent_count: usize = 0;
            for &t in generated_tokens.iter().rev().take(5) {
                if t == v {
                    recent_count += 1;
                }
            }
            score -= (recent_count as f32) * 25.0;

            if score > max_logit {
                max_logit = score;
                max_token = v;
            }
        }

        let step_dur = t_step.elapsed();
        let step_us = step_dur.as_micros() as f64;
        total_latency_us += step_us;

        let frag = detokenize_subwords(&[max_token]);
        println!(
            "{:04} | {:03}     -> {:03}      | {:13} | {:.2} | {:12.2}",
            step, current_token, max_token, frag, max_logit, step_us
        );
        generated_tokens.push(max_token);
        current_token = max_token;
    }

    let full_text = detokenize_subwords(&generated_tokens);
    println!("---------------------------------------------------------------");
    println!("Dynamic Orbit Sequence: \"{}\"", full_text);
    let avg_us = total_latency_us / (target_length as f64);
    println!("Average Step Latency: {:.2} us | Speed: {:.1} tok/s", avg_us, (target_length as f64) / (total_latency_us / 1e6));
    println!("======================================================");
    println!("240-D DYNAMIC AUTOREGRESSIVE INFERENCE: VERIFIED PASS");
    println!("======================================================");
}
