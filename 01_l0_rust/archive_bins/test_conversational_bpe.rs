use act_omega_l0_core::conversational_bpe::{
    tokenize_conversational, detokenize_conversational,
    format_instruction_pair, create_masked_training_pairs,
    VOCAB_SIZE_CONV, TOKEN_PROMPT, TOKEN_RESPONSE, TOKEN_EOS
};
use std::time::Instant;

fn main() {
    println!("======================================================");
    println!("ACT-Omega v30.0: Conversational BPE & Masked QAT Tokenizer");
    println!("Vocabulary: 240 Tokens (Gosset E8 Invariant)");
    println!("Target: Lenovo LOQ 15IAX9 (garlock00)");
    println!("======================================================");

    // 1. Verify Special Delimiters
    println!("[1/4] Validating Special Conversational Delimiters...");
    assert_eq!(VOCAB_SIZE_CONV, 240);
    assert_eq!(TOKEN_PROMPT, 237);
    assert_eq!(TOKEN_RESPONSE, 238);
    assert_eq!(TOKEN_EOS, 239);
    println!("  -> Special Delimiters Mapped: <|prompt|>=237, <|response|>=238, <|eos|>=239 (PASS)");

    // 2. Test Instruction Pair Formatting & Roundtrip
    println!("[2/4] Formatting Instruction Dialogue Pair...");
    let prompt = "Explain the E8 second shell magic state resource";
    let response = "The second shell contains 2160 vectors with norm squared 4 providing non-stabilizer magic states";
    let formatted = format_instruction_pair(prompt, response);
    println!("  -> Formatted Dialogue: \"{}\"", formatted);

    let t0 = Instant::now();
    let tokens = tokenize_conversational(&formatted);
    let tok_dur = t0.elapsed();
    println!("  -> Tokenized {} characters into {} tokens in {} us", formatted.len(), tokens.len(), tok_dur.as_micros());

    // 3. Test Supervised Instruction Masking
    println!("[3/4] Verifying Supervised Instruction Masking...");
    let masked_pairs = create_masked_training_pairs(&tokens);
    let mut prompt_pairs = 0usize;
    let mut response_pairs = 0usize;
    for &(_in_tok, _target_tok, is_response) in masked_pairs.iter() {
        if is_response {
            response_pairs += 1;
        } else {
            prompt_pairs += 1;
        }
    }
    println!("  -> Total Transition Pairs: {}", masked_pairs.len());
    println!("  -> Masked Prompt Pairs (Loss Ignored): {}", prompt_pairs);
    println!("  -> Supervised Response Pairs (Loss Calculated): {}", response_pairs);
    assert!(response_pairs > 0 && prompt_pairs > 0, "Both prompt and response pairs must exist");
    println!("  -> Instruction Mask Separation Verified: PASS");

    // 4. Detokenization Verification
    println!("[4/4] Validating Conversational Detokenization...");
    let recovered = detokenize_conversational(&tokens);
    println!("  -> Recovered Text: \"{}\"", recovered);
    assert!(recovered.contains("<|prompt|>"));
    assert!(recovered.contains("<|response|>"));
    assert!(recovered.contains("<|eos|>"));
    println!("  -> Special Token Preservation: PASS");

    println!("======================================================");
    println!("CONVERSATIONAL BPE MODULE VERIFIED: PASS");
    println!("======================================================");
}