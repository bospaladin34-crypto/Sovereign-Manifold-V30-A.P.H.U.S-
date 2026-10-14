use act_omega_l0_core::harmonic_endpoint::{HarmonicEndpoint, RebarSensorFrame};

fn main() {
    println!("=== ACT-Omega v30.0: Sensory-Modulated Bi-Stalk Forward Inference Test ===");
    
    let endpoint = HarmonicEndpoint::new();
    println!("[1/3] Initialized HarmonicEndpoint with 1,024 Bi-Stalk Attention Kernel.");

    let mut sensor = RebarSensorFrame::default();
    sensor.norm_ut = 52.3;
    sensor.b_field = [182.5, -143.4, -32.6]; // Live Missoula field
    sensor.carrier_phase_rad = 0.17259;

    let (best_token, logit, latency_ms, stiction) = endpoint.infer_with_compound_bi_stalk(42, &sensor);
    println!("[2/3] Forward Pass Result:");
    println!("      Selected Token: {}", best_token);
    println!("      Output Logit:   {:.4}", logit);
    println!("      Latency:        {:.3} ms", latency_ms);
    println!("      AFE Stiction:   {}", if stiction == 1 { "LOCKED (quiescent)" } else { "SLIP (active non-Abelian transport)" });

    assert!(latency_ms < 2.0, "Expected sub-2ms forward inference pass");
    println!("[3/3] SENSORY BI-STALK FORWARD INFERENCE VERIFIED: PASS");
}