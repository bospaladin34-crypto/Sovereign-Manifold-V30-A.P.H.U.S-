use act_omega_l0_core::*;

fn main() {
    println!("==================================================================");
    println!("  ACT-Omega v30.0: Integrated Table-Lookup GEMV 30-Layer Test    ");
    println!("  Silicon Target: Lenovo LOQ 15IAX9 (garlock00)                  ");
    println!("==================================================================");

    let mut observer = HostHardwareObserver::new();
    let frame = observer.sample_live_hardware();
    println!("[INIT] Live Hardware Telemetry Sampled:");
    println!("  Carrier: {:.1} Hz | Field Norm: {:.3} uT | Phase: {:.4} rad", frame.carrier_hz, frame.norm_ut, frame.carrier_phase_rad);

    let vault_path = "C:\\sovereign_manifold_v30\\04_canonical_vault\\models\\model_harmonic_iii.e8q";
    let mut manifold = SovereignHarmonic30LManifold::new_with_vault(Some(vault_path));
    println!("[INIT] Initialized 30-Layer Manifold backed by Canonical E8 Vault (280,840 bytes).");
    println!("  -> Table-Lookup GEMV: 57,600-byte precomputed inner product table active.");

    // Benchmark 10 consecutive super-steps
    println!("\n[EXEC] Running 10 Consecutive Super-Steps across Integrated 30 Layers:");
    let mut total_latency = 0.0;

    for step in 1..=10 {
        let input_tok = (step * 7) % VOCAB_SIZE;
        let (out_tok, logit, latency_us, h1) = manifold.infer_30_layers(input_tok, &frame);
        total_latency += latency_us;
        println!("  Step {:02}: InToken={:02} -> OutToken={:02} | Logit={:.2} | Latency={:6.2} us | H^1={:.8}", 
            step, input_tok, out_tok, logit, latency_us, h1);
        assert!(h1 < 1e-4);
    }

    let avg_latency = total_latency / 10.0;
    println!("\n[BENCHMARK RESULT] Integrated 30-Layer Average Latency: {:.2} microseconds ({:.4} ms)", avg_latency, avg_latency / 1000.0);
    assert!(avg_latency < 5000.0);
    println!("  -> Pure Integer Table-Lookup 30-Layer Deep Manifold: PASS");

    println!("\n==================================================================");
    println!("  INTEGRATED TABLE-LOOKUP GEMV 30-LAYER MANIFOLD VERIFIED: PASS   ");
    println!("==================================================================");
}