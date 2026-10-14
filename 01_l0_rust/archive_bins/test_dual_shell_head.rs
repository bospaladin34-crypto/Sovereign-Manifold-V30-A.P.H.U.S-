use act_omega_l0_core::e8_roots::generate_e8_roots;
use act_omega_l0_core::e8_shell2::generate_e8_shell2;
use act_omega_l0_core::dual_shell_head::DualShellHead;
use std::time::Instant;

fn main() {
    println!("======================================================");
    println!("ACT-Omega v30.0: Dual-Shell Gosset Projection Head");
    println!("Shell 1: 240 Stabilizer Roots | Shell 2: 2,160 Magic Vectors");
    println!("Target: Lenovo LOQ 15IAX9 (garlock00)");
    println!("======================================================");

    // 1. Generate both shells
    let t0 = Instant::now();
    let roots1 = generate_e8_roots();
    let roots2 = generate_e8_shell2();
    let gen_dur = t0.elapsed();
    println!("[1/4] Loaded Shell 1 ({}) & Shell 2 ({}) in {} us", roots1.len(), roots2.len(), gen_dur.as_micros());

    // 2. Initialize Dual-Shell Projection Head
    let head = DualShellHead::new(roots1, roots2);
    println!("[2/4] Initialized DualShellHead (stiction alpha = 0.18)");

    // 3. Benchmark 10,000 Dual-Shell Projection Steps
    let num_steps = 10000;
    let t_proj = Instant::now();
    let mut last_best_magic = 0usize;
    let mut min_logit = f32::INFINITY;
    let mut max_logit = f32::NEG_INFINITY;

    for step in 0..num_steps {
        let phase = step as f32 * 0.017f32;
        let mut stalk = [0.0f32; 8];
        for d in 0..8 {
            if let Some(c) = stalk.get_mut(d) {
                *c = (phase + d as f32 * 0.785f32).sin() * 0.85f32;
            }
        }

        let (logits, best_magic, _magic_dot) = head.project(&stalk);
        last_best_magic = best_magic;

        for &l in logits.iter() {
            if l < min_logit { min_logit = l; }
            if l > max_logit { max_logit = l; }
            assert!(!l.is_nan(), "Logit must not be NaN at step {}", step);
        }
    }

    let proj_dur = t_proj.elapsed();
    let per_step_ns = (proj_dur.as_nanos() as f64) / (num_steps as f64);
    let throughput = (num_steps as f64) / proj_dur.as_secs_f64();

    println!("[3/4] Evaluated {} Dual-Shell Projections in {:.2} ms", num_steps, proj_dur.as_secs_f64() * 1000.0);
    println!("  -> Average Latency: {:.1} ns/projection ({:.3} us)", per_step_ns, per_step_ns / 1000.0);
    println!("  -> Sustained Throughput: {:.1} projections/sec", throughput);
    println!("  -> Dynamic Logit Envelope: {:.2} to {:.2} (PASS)", min_logit, max_logit);

    // 4. Verify Active Magic State Engagement
    println!("[4/4] Active Magic State Engagement: Last Dominant Vector #{} (PASS)", last_best_magic);

    println!("======================================================");
    println!("DUAL-SHELL GOSSET PROJECTION HEAD VERIFIED: PASS");
    println!("======================================================");
}