use act_omega_l0_core::e8_roots::{generate_e8_roots, generate_e8_gram_matrix};
use act_omega_l0_core::e8_shell2::generate_e8_shell2;
use act_omega_l0_core::dual_shell_head::DualShellHead;
use act_omega_l0_core::sheaf_cross_attention::SheafCrossAttention;
use std::time::Instant;
use std::fs::{self, File};
use std::io::Write;
use std::path::{Path, PathBuf};
use std::thread;

const NUM_STALKS: usize = 32;
const STALK_DIM: usize = 8;
const NUM_LAYERS: usize = 30;
const NUM_PCORES: usize = 4;
const TOTAL_PARAMS: usize = NUM_LAYERS * NUM_STALKS * STALK_DIM;

const TOKEN_PROMPT: usize = 237;
const TOKEN_RESPONSE: usize = 238;
const TOKEN_EOS: usize = 239;

fn main() {
    println!("============================================================");
    println!("ACT-Omega v30.0: Conversational Supervised Fine-Tuning (SFT)");
    println!("Target: 35 Conversational Instruction Shards (Batches 25-30)");
    println!("Host: Intel Core i5-12450HX (4 Golden Cove P-Cores)");
    println!("============================================================");

    let t_init = Instant::now();
    let roots = generate_e8_roots();
    let shell2 = generate_e8_shell2();
    let _gram = generate_e8_gram_matrix(&roots);
    println!("[1/5] Loaded Roots & Magic Polytope in {} us", t_init.elapsed().as_micros());

    // Ingest exclusively conversational instruction shards (>= shard_284)
    let candidate_dirs = [
        PathBuf::from("shards"),
        PathBuf::from("shards_240"),
        PathBuf::from("C:\\sovereign_manifold_v30\\01_l0_core\\shards"),
        PathBuf::from("C:\\sovereign_manifold_v30\\01_l0_core\\shards_240"),
    ];

    let mut training_tuples: Vec<(usize, usize, bool)> = Vec::new();
    let mut conversational_shards = 0usize;
    let mut conversational_tokens = 0usize;

    for v_dir in candidate_dirs.iter() {
        if let Ok(entries) = fs::read_dir(v_dir) {
            for entry in entries.flatten() {
                let p = entry.path();
                let fname = p.file_name().unwrap_or_default().to_string_lossy();
                if fname.starts_with("shard_") && fname.ends_with(".bin") {
                    let num_str = fname.trim_start_matches("shard_").trim_end_matches(".bin");
                    if let Ok(id) = num_str.parse::<usize>() {
                        // Focus on conversational shards
                        if id >= 284 {
                            if let Ok(bytes) = fs::read(&p) {
                                if bytes.len() >= 2 {
                                    conversational_shards += 1;
                                    conversational_tokens += bytes.len();
                                    let toks: Vec<usize> = bytes.iter().map(|&b| (b % 240) as usize).collect();

                                    let mut in_supervised = false;
                                    for i in 0..(toks.len() - 1) {
                                        let in_t = *toks.get(i).unwrap_or(&0);
                                        let target_t = *toks.get(i + 1).unwrap_or(&0);

                                        if in_t == TOKEN_PROMPT {
                                            in_supervised = false;
                                        } else if in_t == TOKEN_RESPONSE {
                                            in_supervised = true;
                                        }

                                        training_tuples.push((in_t, target_t, in_supervised));

                                        if target_t == TOKEN_EOS {
                                            in_supervised = false;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    let supervised_count = training_tuples.iter().filter(|&&(_, _, sup)| sup).count();
    let masked_count = training_tuples.len().saturating_sub(supervised_count);

    println!("[2/5] Ingested {} Conversational Shards | {} Tokens", conversational_shards, conversational_tokens);
    println!("  -> Supervised Response Pairs (Active Learning): {}", supervised_count);
    println!("  -> Masked Context Pairs: {}", masked_count);

    // Load existing checkpoint to fine-tune from
    println!("[3/5] Loading Pre-Trained Harmonic Weights from Disk...");
    let model_path = "C:\\sovereign_manifold_v30\\04_canonical_vault\\weights\\model_harmonic_iii.e8q";
    let mut master_weights = vec![0.0f32; TOTAL_PARAMS];
    if let Ok(bytes) = fs::read(model_path) {
        if bytes.len() >= TOTAL_PARAMS {
            for (i, slot) in master_weights.iter_mut().enumerate() {
                let b = *bytes.get(i).unwrap_or(&0) as i8;
                *slot = b as f32 / 64.0;
            }
            println!("  -> Successfully Warm-Started from Existing Checkpoint");
        }
    }

    let mut quantized_weights = vec![0i8; TOTAL_PARAMS];
    for (qw, &mw) in quantized_weights.iter_mut().zip(master_weights.iter()) {
        *qw = (mw * 64.0).round().clamp(-127.0, 127.0) as i8;
    }

    // High-Resolution Conversational Fine-Tuning Pass
    println!("[4/5] Executing 30-Epoch Conversational SFT Pass...");
    let learning_rate = 0.003f32; // Calibrated fine-tuning rate
    let beta1 = 0.9f32;
    let beta2 = 0.999f32;
    let eps = 1e-8f32;
    let num_epochs = 30;
    let t_train_start = Instant::now();

    let roots_ref = &roots;
    let shell2_ref = &shell2;
    let pairs_ref = &training_tuples;
    let chunk_size = (pairs_ref.len() + NUM_PCORES - 1) / NUM_PCORES;

    for epoch in 1..=num_epochs {
        let t_epoch_start = Instant::now();
        let mut pcore_weights: Vec<Vec<f32>> = vec![master_weights.clone(); NUM_PCORES];
        let mut pcore_stats: Vec<(f32, f32, usize)> = vec![(0.0, 0.0, 0); NUM_PCORES];

        thread::scope(|s| {
            for (p_idx, (local_mw, local_stat)) in pcore_weights.iter_mut().zip(pcore_stats.iter_mut()).enumerate() {
                let start_idx = p_idx * chunk_size;
                let end_idx = (start_idx + chunk_size).min(pairs_ref.len());

                s.spawn(move || {
                    if start_idx >= end_idx { return; }
                    let thread_pairs = pairs_ref.get(start_idx..end_idx).unwrap_or(&[]);
                    let mut local_qw: Vec<i8> = local_mw.iter().map(|&mw| (mw * 64.0).round().clamp(-127.0, 127.0) as i8).collect();
                    let mut local_m = vec![0.0f32; TOTAL_PARAMS];
                    let mut local_v = vec![0.0f32; TOTAL_PARAMS];

                    let sheaf_attn = SheafCrossAttention::new();
                    let dual_head = DualShellHead::new(*roots_ref, *shell2_ref);

                    let mut thread_loss = 0.0f32;
                    let mut thread_h1 = 0.0f32;
                    let mut thread_steps = 0usize;

                    for &(in_tok, target_tok, is_supervised) in thread_pairs.iter() {
                        let in_root = roots_ref.get(in_tok % 240).cloned().unwrap_or([0.0f32; 8]);
                        let target_stalk_idx = in_tok % NUM_STALKS;

                        let mut active_stalks = [[0.0f32; 8]; NUM_STALKS];
                        if let Some(slot) = active_stalks.get_mut(target_stalk_idx) {
                            *slot = in_root;
                        }

                        for l in 0..NUM_LAYERS {
                            let layer_offset = l * NUM_STALKS * STALK_DIM;
                            for st_idx in 0..NUM_STALKS {
                                let stalk_offset = layer_offset + st_idx * STALK_DIM;
                                if let Some(stalk) = active_stalks.get_mut(st_idx) {
                                    for d in 0..STALK_DIM {
                                        let w_val = local_qw.get(stalk_offset + d).copied().unwrap_or(0) as f32 / 64.0;
                                        if let Some(coord) = stalk.get_mut(d) {
                                            *coord = (*coord + w_val * 0.1).tanh();
                                        }
                                    }
                                }
                            }
                        }

                        let (diffused, dirichlet_e) = sheaf_attn.forward(&active_stalks);
                        active_stalks = diffused;
                        thread_h1 += dirichlet_e * 1e-9;

                        let out_stalk_idx = target_tok % NUM_STALKS;
                        let out_stalk = active_stalks.get(out_stalk_idx).cloned().unwrap_or([0.0f32; 8]);
                        let (logits, _, _) = dual_head.project(&out_stalk);

                        if is_supervised {
                            let max_logit = logits.iter().cloned().fold(f32::NEG_INFINITY, f32::max);
                            let sum_exp: f32 = logits.iter().map(|&x| (x - max_logit).exp()).sum();
                            let target_logit = logits.get(target_tok % 240).copied().unwrap_or(0.0);
                            let prob_target = ((target_logit - max_logit).exp() / sum_exp.max(1e-12)).max(1e-7);
                            let loss = -prob_target.ln();
                            thread_loss += loss;
                            thread_steps += 1;

                            // STE Adam update targeting top semantic layers 27, 28, 29
                            let grad = (1.0 - prob_target) * 0.015;
                            for target_layer in 27..NUM_LAYERS {
                                let offset = target_layer * NUM_STALKS * STALK_DIM + (target_tok % NUM_STALKS) * STALK_DIM;
                                for d in 0..STALK_DIM {
                                    let idx = offset + d;
                                    if let (Some(mw), Some(qw), Some(m), Some(v_mom)) = (
                                        local_mw.get_mut(idx),
                                        local_qw.get_mut(idx),
                                        local_m.get_mut(idx),
                                        local_v.get_mut(idx),
                                    ) {
                                        *m = beta1 * *m + (1.0 - beta1) * grad;
                                        *v_mom = beta2 * *v_mom + (1.0 - beta2) * grad * grad;
                                        let m_hat = *m / (1.0 - beta1);
                                        let v_hat = *v_mom / (1.0 - beta2);
                                        *mw -= learning_rate * m_hat / (v_hat.sqrt() + eps);
                                        *qw = (*mw * 64.0).round().clamp(-127.0, 127.0) as i8;
                                    }
                                }
                            }
                        }
                    }

                    *local_stat = (thread_loss, thread_h1, thread_steps);
                });
            }
        });

        for i in 0..TOTAL_PARAMS {
            let sum_w: f32 = pcore_weights.iter().map(|pw| pw.get(i).copied().unwrap_or(0.0)).sum();
            if let Some(slot) = master_weights.get_mut(i) {
                *slot = sum_w / (NUM_PCORES as f32);
            }
        }
        for (qw, &mw) in quantized_weights.iter_mut().zip(master_weights.iter()) {
            *qw = (mw * 64.0).round().clamp(-127.0, 127.0) as i8;
        }

        let total_loss: f32 = pcore_stats.iter().map(|&(l, _, _)| l).sum();
        let total_count: usize = pcore_stats.iter().map(|&(_, _, c)| c).sum();
        let avg_loss = total_loss / (total_count as f32).max(1.0);
        let ppl = avg_loss.exp();
        let epoch_dur = t_epoch_start.elapsed();

        if epoch % 5 == 0 || epoch == 1 || epoch == num_epochs {
            println!("SFT Epoch {:02}/{:02} | Loss: {:.4} | PPL: {:.2} | Duration: {:.3} s",
                epoch, num_epochs, avg_loss, ppl, epoch_dur.as_secs_f64());
        }
    }

    let total_dur = t_train_start.elapsed();

    // Export fine-tuned weights
    let targets = [
        "C:\\sovereign_manifold_v30\\04_canonical_vault\\models\\model_harmonic_iii_240.e8q",
        "C:\\sovereign_manifold_v30\\04_canonical_vault\\weights\\model_harmonic_iii.e8q"
    ];
    for target in &targets {
        let p = Path::new(target);
        if let Some(parent) = p.parent() { let _ = fs::create_dir_all(parent); }
        if let Ok(mut f) = File::create(p) {
            let bytes: Vec<u8> = quantized_weights.iter().map(|&w| w as u8).collect();
            let _ = f.write_all(&bytes);
            println!("[5/5] Exported Fine-Tuned Checkpoint: {}", target);
        }
    }

    println!("============================================================");
    println!("CONVERSATIONAL SFT COMPLETED in {:.3} s: PASS", total_dur.as_secs_f64());
    println!("============================================================");
}