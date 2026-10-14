use std::time::Instant;
use act_omega_l0_core::sh3_manifold_30l::SovereignHarmonic30LManifold;
use act_omega_l0_core::rebar_slot::RebarSensorFrame;

fn main() {
    println!("============================================================");
    println!("ACT-Omega v30.0: Multi-Token Autoregressive Generation");
    println!("Hardware Target: Lenovo LOQ 15IAX9 (garlock00)");
    println!("============================================================");

    let mut manifold = SovereignHarmonic30LManifold::new();
    let sensor = RebarSensorFrame::default();

    let seed_token: usize = 42;
    let sequence_length: usize = 32;

    println!("[INIT] Seed Token: {} | Target Length: {} tokens", seed_token, sequence_length);
    println!("-----------------------------------------------------------------------------");
    println!("Step | InToken -> OutToken |   Logit   | Latency (us) |   H^1 Obstruction");
    println!("-----------------------------------------------------------------------------");

    let mut current_token = seed_token;
    let mut generated_sequence = vec![current_token];
    let mut total_latency_us = 0.0f64;

    let t_start = Instant::now();

    for step in 1..=sequence_length {
        let (out_token, logit, latency_us, h1) = manifold.infer_30_layers(current_token, &sensor);
        
        println!(
            "{:04} |    {:02}    ->    {:02}    |  {:>7.2}  |  {:>10.2}  |  {:.8}",
            step, current_token, out_token, logit, latency_us, h1
        );

        total_latency_us += latency_us;
        generated_sequence.push(out_token);
        current_token = out_token;
    }

    let wall_clock_ms = t_start.elapsed().as_secs_f64() * 1000.0;
    let avg_latency_us = total_latency_us / sequence_length as f64;
    let tok_per_sec = sequence_length as f64 / (total_latency_us / 1_000_000.0);

    println!("-----------------------------------------------------------------------------");
    println!("\n[AUTOREGRESSIVE GENERATION SUMMARY]");
    println!("Generated Sequence ({} tokens): {:?}", generated_sequence.len(), generated_sequence);
    println!("Average Step Latency: {:.2} us ({:.4} ms/token)", avg_latency_us, avg_latency_us / 1000.0);
    println!("Total Manifold Latency: {:.3} ms | Total Wall-Clock: {:.3} ms", total_latency_us / 1000.0, wall_clock_ms);
    println!("Sustained Generation Speed: {:.1} tokens/second", tok_per_sec);
}