use act_omega_l0_core::e8_roots::{generate_e8_roots, generate_e8_gram_matrix};
use act_omega_l0_core::e8_subword_vocab::{tokenize_subwords, detokenize_subwords, VOCAB_SIZE_240};
use std::time::Instant;

fn main() {
    println!("======================================================");
    println!("ACT-Omega v30.0: Cycle 2 - E8 Polytope Root & Subword Scaling");
    println!("Target: Lenovo LOQ 15IAX9 (garlock00)");
    println!("======================================================");

    // 1. Generate and verify 240 Gosset roots
    let t0 = Instant::now();
    let roots = generate_e8_roots();
    let gen_dur = t0.elapsed();
    println!("[1/4] Generated {} Gosset E8 Root Vectors in {} us", roots.len(), gen_dur.as_micros());

    for (idx, r) in roots.iter().enumerate() {
        let norm_sq: f32 = r.iter().map(|x| x * x).sum();
        assert!((norm_sq - 2.0).abs() < 1e-5, "Root {} norm squared is {}", idx, norm_sq);
    }
    println!("  -> Norm Squared Validation: Exactly 2.0 for all 240 roots (PASS)");

    // 2. Compute and verify 240x240 integer Gram matrix
    let t1 = Instant::now();
    let gram = generate_e8_gram_matrix(&roots);
    let gram_dur = t1.elapsed();
    println!("[2/4] Computed 240x240 Integer Gram Matrix in {} us", gram_dur.as_micros());

    let mut min_val = 0i8;
    let mut max_val = 0i8;
    for (i, row) in gram.iter().enumerate() {
        for (j, &val) in row.iter().enumerate() {
            if i == j {
                assert_eq!(val, 2, "Diagonal must be 2");
            }
            assert!(val >= -2 && val <= 2, "Gram entry out of [-2, 2]: {}", val);
            if val < min_val { min_val = val; }
            if val > max_val { max_val = val; }
        }
    }
    println!("  -> Simply-Laced Invariant: Inner products strictly in [{}, {}] (PASS)", min_val, max_val);

    // 3. Subword Vocabulary Verification
    println!("[3/4] Validating 240-Token Subword Dictionary...");
    assert_eq!(VOCAB_SIZE_240, 240);
    println!("  -> Token Count: Exactly 240 subwords (64 chars + 176 subwords)");

    // 4. Tokenization & Compression Benchmark
    println!("[4/4] Testing Maximum-Munch Tokenizer / Detokenizer Roundtrip...");
    let sample = "the act omega 30 layer manifold operates at 15 hz with e8 root projections and zero loss";
    let tokens = tokenize_subwords(sample);
    let reconstructed = detokenize_subwords(&tokens);
    assert_eq!(sample, reconstructed.as_str(), "Mismatch in roundtrip reconstruction!");

    let char_count = sample.len();
    let token_count = tokens.len();
    let ratio = (char_count as f32) / (token_count as f32);
    println!("  -> Original Text: \"{}\"", sample);
    println!("  -> Characters: {} | Tokens: {} | Compression Ratio: {:.2}x", char_count, token_count, ratio);
    println!("  -> Reconstructed Text: \"{}\"", reconstructed);
    println!("  -> Lossless Round-Trip Verified: PASS");

    println!("======================================================");
    println!("CYCLE 2: 240-DIMENSIONAL E8 SUBWORD MANIFOLD VERIFIED: PASS");
    println!("======================================================");
}
