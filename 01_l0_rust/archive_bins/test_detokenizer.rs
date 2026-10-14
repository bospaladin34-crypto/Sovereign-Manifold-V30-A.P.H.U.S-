use std::time::Instant;
use act_omega_l0_core::vocab_e8_table::VocabE8Table;

fn main() {
    println!("============================================================");
    println!("ACT-Omega v30.0: Dual E8-Phonetic Detokenizer Verification");
    println!("Hardware Target: Lenovo LOQ 15IAX9 (garlock00)");
    println!("============================================================");

    // 1. Lossless Text Roundtrip Test
    let sample_texts = [
        "act-omega v30 sovereign manifold.",
        "artin braid group and sheaf cohomology.",
        "geomagnetic flux -16.15 ut at 15hz resonance.",
    ];

    println!("[TEST 1] Bidirectional Text Round-Trip Invariance:");
    for &txt in &sample_texts {
        let tokens = VocabE8Table::tokenize_text(txt);
        let recovered = VocabE8Table::detokenize_text(&tokens);
        let ipa = VocabE8Table::detokenize_phonetic(&tokens);
        println!("  Original:  '{}'", txt);
        println!("  Tokens:    {:?}", tokens);
        println!("  IPA:       {}", ipa);
        println!("  Recovered: '{}'", recovered);
        assert_eq!(txt, recovered, "Lossless detokenization mismatch!");
        println!("  -> Invariant: PASS (Zero Divergence)\n");
    }

    // Mixed-case normalization test
    let mixed = "ACT-Omega v30 Sovereign Manifold.";
    let mixed_tokens = VocabE8Table::tokenize_text(mixed);
    let mixed_rec = VocabE8Table::detokenize_text(&mixed_tokens);
    println!("  Mixed-Case Input:     '{}'", mixed);
    println!("  Normalized Recovered: '{}'", mixed_rec);
    assert_eq!(mixed.to_lowercase(), mixed_rec);
    println!("  -> Mixed-Case Invariant: PASS\n");

    // 2. Autoregressive Sequence Detokenization
    let ar_tokens = [42, 6, 48, 46, 6, 26, 60, 10, 48, 24, 14, 14, 24, 42, 34, 26, 56, 60, 6, 52];
    let ar_text = VocabE8Table::detokenize_text(&ar_tokens);
    let ar_ipa = VocabE8Table::detokenize_phonetic(&ar_tokens);
    let ar_acoustic = VocabE8Table::detokenize_acoustic(&ar_tokens);

    println!("[TEST 2] 20-Token Autoregressive Sequence Projection:");
    println!("  Raw Tokens: {:?}", ar_tokens);
    println!("  Decoded Text: '{}'", ar_text);
    println!("  Phonetic IPA: {}", ar_ipa);
    println!("  Acoustic Formants (First 3 tokens):");
    for (i, f) in ar_acoustic.iter().take(3).enumerate() {
        println!("    Token {}: F1={:.1}Hz, F2={:.1}Hz, F3={:.1}Hz", ar_tokens[i], f.f1_hz, f.f2_hz, f.f3_hz);
    }

    // 3. Performance Benchmark
    let benchmark_text = "act-omega sovereign manifold continuous topological computing architecture.";
    let bench_tokens = VocabE8Table::tokenize_text(benchmark_text);
    let iterations = 100_000;

    let t0 = Instant::now();
    for _ in 0..iterations {
        let _ = VocabE8Table::detokenize_text(&bench_tokens);
    }
    let elapsed = t0.elapsed().as_secs_f64();
    let total_tokens = bench_tokens.len() * iterations;
    let tok_per_sec = total_tokens as f64 / elapsed;

    println!("\n[TEST 3] High-Throughput Detokenization Benchmark:");
    println!("  Processed: {} tokens across {} iterations in {:.3} s", total_tokens, iterations, elapsed);
    println!("  Throughput: {:.1} tokens/second", tok_per_sec);
    assert!(tok_per_sec > 1_000_000.0, "Throughput below 1M tok/s floor!");
    println!("  -> Detokenizer Latency Invariant: PASS (> 1M tok/s)\n");

    println!("============================================================");
    println!("DUAL E8-PHONETIC DETOKENIZATION VERIFIED: ALL TESTS PASSED");
    println!("============================================================");
}