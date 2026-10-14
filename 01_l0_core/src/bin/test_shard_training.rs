use std::fs::{self, File};
use std::io::Read;
use std::time::Instant;
use act_omega_l0_core::sh3_manifold_30l::SovereignHarmonic30LManifold;
use act_omega_l0_core::rebar_slot::RebarSensorFrame;
use act_omega_l0_core::qat_training::{QatTrainingKernel, QatConfig};

fn load_all_vault_shards(dir: &str) -> Vec<u8> {
    let mut tokens = Vec::new();
    let mut shard_count = 0usize;

    if let Ok(entries) = fs::read_dir(dir) {
        let mut paths: Vec<_> = entries
            .filter_map(|e| e.ok().map(|e| e.path()))
            .filter(|p| p.extension().map_or(false, |ext| ext == "binshard"))
            .collect();
        paths.sort();

        for path in paths {
            if let Ok(mut f) = File::open(&path) {
                let mut buf = Vec::new();
                if f.read_to_end(&mut buf).is_ok() && buf.len() > 64 {
                    tokens.extend_from_slice(&buf[64..]);
                    shard_count += 1;
                }
            }
        }
    }
    println!("[INIT] Ingested Shard Dataset: {} shards ({} total tokens)", shard_count, tokens.len());
    tokens
}

fn main() {
    println!("============================================================");
    println!("ACT-Omega v30.0: Dynamic Multi-Domain Shard QAT Training");
    println!("Hardware Target: Lenovo LOQ 15IAX9 (garlock00)");
    println!("============================================================");

    let shards_dir = "../04_canonical_vault/shards";
    let tokens = load_all_vault_shards(shards_dir);

    if tokens.len() < 2 {
        eprintln!("[ERROR] Insufficient tokens in vault to construct training pairs.");
        return;
    }

    let pairs: Vec<(usize, usize)> = tokens
        .windows(2)
        .map(|w| (w[0] as usize % 64, w[1] as usize % 64))
        .collect();

    let mut manifold = SovereignHarmonic30LManifold::new();
    let config = QatConfig {
        learning_rate: 0.001,
        beta1: 0.9,
        beta2: 0.999,
        epsilon: 1e-8,
        weight_decay: 0.01,
        sheaf_penalty_lambda: 0.0001,
    };
    let mut kernel = QatTrainingKernel::new(config);
    let sensor = RebarSensorFrame::default();

    let epochs = 30;
    let t0 = Instant::now();

    for ep in 1..=epochs {
        let ep_t0 = Instant::now();
        let mut loss_acc = 0.0f32;
        let mut h1_acc = 0.0f32;

        for &(inp, tgt) in &pairs {
            let metrics = kernel.train_step(&mut manifold, inp, tgt, &sensor);
            loss_acc += metrics.total_loss;
            h1_acc += metrics.h1_obstruction;
        }

        let n = pairs.len() as f32;
        let avg_loss = loss_acc / n;
        let avg_h1 = h1_acc / n;
        let ppl = (avg_loss as f64).exp();
        let ep_elapsed = ep_t0.elapsed().as_secs_f64();
        let tok_per_sec = pairs.len() as f64 / ep_elapsed;

        println!(
            "Epoch {:02}/{:02}: Avg Loss = {:.6} | PPL = {:.3} | Avg H^1 = {:.8} | Speed = {:.1} tok/s ({:.3} s)",
            ep, epochs, avg_loss, ppl, avg_h1, tok_per_sec, ep_elapsed
        );
    }

    let total_secs = t0.elapsed().as_secs_f64();
    let total_steps = pairs.len() * epochs;
    println!("\n[CONVERGENCE SUMMARY]");
    println!("Total Duration: {:.3} seconds across {} steps", total_secs, total_steps);
    println!("Overall Training Throughput: {:.1} tokens/second", total_steps as f64 / total_secs);

    let vault_path = "C:\\sovereign_manifold_v30\\04_canonical_vault\\models\\model_harmonic_iii.e8q";
    let _ = manifold.save_to_vault(vault_path);
    println!("\n[CHECKPOINT] Serializing Trained 30-Layer Weights to Vault:");
    println!("Target Artifact: {}", vault_path);
    if let Ok(meta) = fs::metadata(vault_path) {
        println!("Exported Size: {} bytes", meta.len());
        assert_eq!(meta.len(), 280840);
        println!("-> Exact 280,840-Byte Vault Checkpoint: PASS");
    }
}
