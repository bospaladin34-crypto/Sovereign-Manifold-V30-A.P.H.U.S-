# =============================================================================
# ACT-OMEGA NET v71.3.0 -- WEEK 3 12-TEST TORTURE, STRESS & ABLATION SUITE
# Executes Tools 341..346 (CHAIN 346 | 935/935 Lean 4 QED) + Hard Gate 0 (Tool 322)
# and verifies all 12 Week 3 Torture, Stress & Ablation Tests (W3-1..W3-12)
# =============================================================================
$ErrorActionPreference = "Stop"
$baseUrl = "http://127.0.0.1:8097"

Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host "  ACT-OMEGA v71.3.0 -- WEEK 3 12-TEST SPECULATIVE k=4 & 4K HORIZON SUITE (W3)  " -ForegroundColor Cyan
Write-Host "===============================================================================" -ForegroundColor Cyan

function Invoke-SovereignJson($endpoint, $method = "POST", $body = "{}") {
    $uri = "$baseUrl$endpoint"
    if ($method -eq "GET") {
        $resp = Invoke-RestMethod -Uri $uri -Method Get -TimeoutSec 120
    } else {
        $resp = Invoke-RestMethod -Uri $uri -Method Post -Body $body -ContentType "application/json" -TimeoutSec 120
    }
    return $resp
}

# 1. Execute Tool 341: Tri-Silicon k=4 Speculative Cascade Engine
Write-Host "`n[1/7] Tool 341: Tri-Silicon k=4 Speculative Cascade (Pixel 8 :8098 -> Host + RTX 3050 PTX)..." -ForegroundColor Yellow
$t341 = Invoke-SovereignJson "/api/v1/sovereign_harmonic/week3/k4_speculative_cascade" "POST" '{"k":4,"max_tokens":128}'
Write-Host ("  -> Status: {0} | Alpha: {1} | Tok/Step: {2} | Speedup: {3}x | KL Divergence: {4} | P8(:8098): {5}" -f `
    $t341.status, $t341.speculative_cascade.acceptance_rate_alpha, `
    $t341.speculative_cascade.mean_tokens_per_verifier_step, `
    $t341.speculative_cascade.measured_speedup_factor, `
    $t341.speculative_cascade.exact_leviathan_kl_divergence, `
    $t341.tri_silicon_nodes.edge2_p8_bearer) -ForegroundColor Green

# 2. Execute Tool 342: Long-Horizon 4,096-Token O(1) 448-Byte Dual Recurrent Memory & 5-Depth NIAH
Write-Host "`n[2/7] Tool 342: Long-Horizon 4,096-Token O(1) 448B Recurrent Memory & 5-Depth NIAH Gauntlet..." -ForegroundColor Yellow
$t342 = Invoke-SovereignJson "/api/v1/sovereign_harmonic/week3/long_horizon_4096_memory" "POST" "{}"
Write-Host ("  -> Status: {0} | Horizon: {1} toks ({2} turns) | State: {3} B ({4}x vs FP16 KV) | NIAH Recall: {5} | RoPE Drift: {6}" -f `
    $t342.status, $t342.o1_recurrent_memory.horizon_tokens_stepped, `
    $t342.o1_recurrent_memory.conversational_turns, `
    $t342.o1_recurrent_memory.total_recurrent_state_bytes, `
    $t342.o1_recurrent_memory.memory_compression_factor_x, `
    $t342.needle_in_4096_haystack_gauntlet.exact_recalls, `
    $t342.o1_recurrent_memory.rope_4096_max_symplectic_drift) -ForegroundColor Green

# 3. Execute Tool 343: 4-Hop Grassmannian Plucker G(2,4) Chain-of-Thought & Hallucination Gate
Write-Host "`n[3/7] Tool 343: 4-Hop Grassmannian Plucker G(2,4) Chain-of-Thought & Hallucination Gate..." -ForegroundColor Yellow
$t343 = Invoke-SovereignJson "/api/v1/sovereign_harmonic/week3/multi_hop_plucker_cot" "POST" "{}"
Write-Host ("  -> Status: {0} | Valid 4-Hop Chains Incident: {1} | Klein Residual: {2} | Hallucinations Rejected: {3}" -f `
    $t343.status, $t343.plucker_4hop_cot.valid_chains_incident, `
    $t343.plucker_4hop_cot.total_klein_quadric_residual, `
    $t343.plucker_4hop_cot.hallucinated_non_incident_chains_rejected) -ForegroundColor Green

# 4. Execute Tool 344: Contrastive Hard-Negative Stiefel Preference Alignment Trainer (512 Pairs)
Write-Host "`n[4/7] Tool 344: Contrastive Hard-Negative Stiefel Preference Alignment Trainer (512 Pairs)..." -ForegroundColor Yellow
$t344 = Invoke-SovereignJson "/api/v1/sovereign_harmonic/week3/contrastive_stiefel_preference_trainer" "POST" "{}"
Write-Host ("  -> Status: {0} | Wins: {1}/{2} | Mean Margin: {3} | Holdout PPL: {4} (W2) -> {5} (W3) | OrthoRes: {6}" -f `
    $t344.status, $t344.contrastive_preference_alignment.chosen_wins, `
    $t344.contrastive_preference_alignment.total_pairs, `
    $t344.contrastive_preference_alignment.measured_mean_margin, `
    $t344.contrastive_preference_alignment.week2_holdout_ppl, `
    $t344.contrastive_preference_alignment.week3_holdout_ppl, `
    $t344.contrastive_preference_alignment.stiefel_max_ortho_residual) -ForegroundColor Green

# 5. Execute Tool 322: Hard Gate 0 (Frozen Holdout v2 on F:\) Read-Only Scoring
Write-Host "`n[5/7] Tool 322: Hard Gate 0 (Frozen Holdout v2 -- 32 Prompts on F:\) Read-Only Evaluation..." -ForegroundColor Yellow
$t322 = Invoke-SovereignJson "/api/v1/tools/t322" "POST" "{}"
Write-Host ("  -> Status: {0} | Gate 0 Passed: {1} | Overlap: {2} | Frozen v2 PPL: {3} -> {4} (Human-16: {5} | Ext-16: {6})" -f `
    $t322.status, $t322.hard_gate_0_frozen_holdout_v2.gate_0_passed, `
    $t322.hard_gate_0_frozen_holdout_v2.trainer_overlap_count, `
    $t322.hard_gate_0_frozen_holdout_v2.frozen_v2_pre_perplexity, `
    $t322.hard_gate_0_frozen_holdout_v2.frozen_v2_post_perplexity, `
    $t322.hard_gate_0_frozen_holdout_v2.frozen_v2_human_16_post_ppl, `
    $t322.hard_gate_0_frozen_holdout_v2.frozen_v2_external_16_post_ppl) -ForegroundColor Green

# 6. Execute Tool 345: Week 3 12-Test Torture, Stress & 6-Way Ablation Gauntlet (W3-1..W3-12)
Write-Host "`n[6/7] Tool 345: Week 3 12-Test Torture, Stress & 6-Way Ablation Gauntlet (W3-1..W3-12)..." -ForegroundColor Yellow
$t345 = Invoke-SovereignJson "/api/v1/sovereign_harmonic/week3/torture_and_ablation_gauntlet" "POST" "{}"
Write-Host ("  -> Status: {0} | All 12 Passed: {1} | Eval-256 PPL: {2} (W1) -> {3} (W2) -> {4} (W3)" -f `
    $t345.status, $t345.all_12_tests_passed, `
    $t345.w3_6_sh_eval_256_3week_progression.week1_eval256_ppl, `
    $t345.w3_6_sh_eval_256_3week_progression.week2_eval256_ppl, `
    $t345.w3_6_sh_eval_256_3week_progression.week3_eval256_ppl) -ForegroundColor Green
Write-Host ("  -> [W3-8 6-Way Ablation] FullW3={0} < NoPluckerCoT={1} < NoYaRN4K={2} < NoApical384B={3} < NoStiefelDPO={4} < W2Base={5}" -f `
    $t345.w3_8_six_way_week3_ablation_matrix.full_week3_ppl, `
    $t345.w3_8_six_way_week3_ablation_matrix.no_plucker_4hop_cot_ppl, `
    $t345.w3_8_six_way_week3_ablation_matrix.no_4k_yarn_rope_ppl, `
    $t345.w3_8_six_way_week3_ablation_matrix.no_384b_apical_mamba3_ppl, `
    $t345.w3_8_six_way_week3_ablation_matrix.no_contrastive_stiefel_dpo_ppl, `
    $t345.w3_8_six_way_week3_ablation_matrix.week2_baseline_ppl) -ForegroundColor Cyan
Write-Host ("  -> [W3-9 Speculative k-Sweep] k=1: {0} tok/s | k=2: {1} tok/s | k=4: {2} tok/s | k=8: {3} tok/s" -f `
    $t345.w3_9_speculative_k_horizon_sweep.k1_toks_per_step, `
    $t345.w3_9_speculative_k_horizon_sweep.k2_toks_per_step, `
    $t345.w3_9_speculative_k_horizon_sweep.k4_toks_per_step, `
    $t345.w3_9_speculative_k_horizon_sweep.k8_toks_per_step) -ForegroundColor Cyan
Write-Host ("  -> [W3-10..12 Stress] 64-Decoy Flood={0} | P8 Bearer={1} | 100-Step (1,200-Retraction) Ortho={2}" -f `
    $t345.w3_10_adversarial_64_distractor_flood.distractors_rejected, `
    $t345.w3_11_wireless_p8_drafter_failover.active_bearer, `
    $t345.w3_12_stiefel_100step_1200retraction_torture.max_100step_ortho_frobenius_residual) -ForegroundColor Cyan

# 7. Execute Tool 346: Week 3 Master Certification (v71.3.0 | CHAIN 346 | 935/935 Lean 4 QED)
Write-Host "`n[7/9] Tool 346: Week 3 Master Certification (CHAIN 346 | 935/935 Lean 4 QED)..." -ForegroundColor Yellow
$t346 = Invoke-SovereignJson "/api/v1/sovereign_harmonic/week3/master_certification" "POST" "{}"
Write-Host ("  -> Status: {0} | All Week 3 Gates: {1} | Lean 4 QED: {2} | Proof: {3}" -f `
    $t346.status, $t346.gates.all_week3_gates_passed, $t346.lean4_theorems_qed, $t346.proof) -ForegroundColor Green

# 8. Execute Tool 347: Red-Team 10-Failure-Mode Diagnostic & Remediation Gauntlet (RT-1..RT-10)
Write-Host "`n[8/9] Tool 347: Red-Team 10-Failure-Mode Diagnostic & Remediation Gauntlet (RT-1..RT-10)..." -ForegroundColor Yellow
$t347 = Invoke-SovereignJson "/api/v1/sovereign_harmonic/week3/redteam_diagnostic_and_remediation" "POST" "{}"
Write-Host ("  -> Status: {0} | All 10 RT Modes Remediated: {1}" -f `
    $t347.status, $t347.all_10_redteam_failures_remediated) -ForegroundColor Green
Write-Host ("  -> [RT-1 16K BPE] Scanned={0} | RawBytes-256 Roundtrip={1} | Tier-3 Active={2}" -f `
    $t347.rt1_bpe_16k_full_vocab_and_raw256_bytes.post_remediation_scanned_vocab, `
    $t347.rt1_bpe_16k_full_vocab_and_raw256_bytes.raw_256_byte_identity_verified, `
    $t347.rt1_bpe_16k_full_vocab_and_raw256_bytes.tier3_concept_tokens_active) -ForegroundColor Cyan
Write-Host ("  -> [RT-2 Free-Form Gen] 4-Tier Stiefel Backoff Unseen Completions={0} | Zero-Token Halts={1}" -f `
    $t347.rt2_freeform_unseen_prompt_zero_halts.post_remediation_4tier_stiefel_backoff_completions, `
    $t347.rt2_freeform_unseen_prompt_zero_halts.zero_token_halts) -ForegroundColor Cyan
Write-Host ("  -> [RT-3 Drafter No-Peek] Honest Drafter Alpha={0} ({1}/{2} accepted, {3} rejections) | KL={4}" -f `
    $t347.rt3_honest_2layer_drafter_no_target_peeking.honest_acceptance_rate_alpha, `
    $t347.rt3_honest_2layer_drafter_no_target_peeking.post_remediation_accepted, `
    $t347.rt3_honest_2layer_drafter_no_target_peeking.post_remediation_drafted, `
    $t347.rt3_honest_2layer_drafter_no_target_peeking.post_remediation_genuine_rejections, `
    $t347.rt3_honest_2layer_drafter_no_target_peeking.exact_leviathan_kl_divergence) -ForegroundColor Cyan
Write-Host ("  -> [RT-4..RT-6] Cuckoo NIAH={0} (Overwrites={1}) | DPO LogProb Wins={2} ({3} vs {4}) | PPL Valid={5} vs Rep={6} vs Gib={7}" -f `
    $t347.rt4_content_addressed_16slot_cuckoo_niah.post_remediation_arbitrary_depths_recalled, `
    $t347.rt4_content_addressed_16slot_cuckoo_niah.dynamic_key_overwrites_verified, `
    $t347.rt5_measured_token_logprob_contrastive_dpo.measured_nll_margin_wins, `
    $t347.rt5_measured_token_logprob_contrastive_dpo.post_remediation_chosen_mean_nll, `
    $t347.rt5_measured_token_logprob_contrastive_dpo.post_remediation_rejected_mean_nll, `
    $t347.rt6_degenerate_repetition_and_gibberish_separation.coherent_domain_ppl, `
    $t347.rt6_degenerate_repetition_and_gibberish_separation.degenerate_repetition_ppl, `
    $t347.rt6_degenerate_repetition_and_gibberish_separation.random_gibberish_ppl) -ForegroundColor Cyan
Write-Host ("  -> [RT-7..RT-10] 4-Hop Spoof Rejected={0} | 8K Horizon={1}x ({2} NIAH) | Negation Router=({3},{4}) | NaN/Inf={5}" -f `
    $t347.rt7_content_parsed_4hop_plucker_chain_auditor.corrupted_chains_rejected, `
    $t347.rt8_extreme_8192_token_2x_horizon_extrapolation.horizon_8192_compression_x, `
    $t347.rt8_extreme_8192_token_2x_horizon_extrapolation.horizon_8192_niah_recalled, `
    $t347.rt9_negation_aware_adversarial_intent_router.adv1_not_lean_routed_to_rust_track2, `
    $t347.rt9_negation_aware_adversarial_intent_router.adv2_not_rust_routed_to_lean_track3, `
    $t347.rt10_pathological_input_and_nan_inf_guard.nan_or_inf_count) -ForegroundColor Cyan

# 9. Execute Tool 348: CHAIN 348 Red-Team Master Certification (945/945 Lean 4 QED)
Write-Host "`n[9/11] Tool 348: CHAIN 348 Red-Team Master Certification (945/945 Lean 4 QED)..." -ForegroundColor Yellow
$t348 = Invoke-SovereignJson "/api/v1/chain348/master_certification" "POST" "{}"
Write-Host ("  -> Status: {0} | All CHAIN 348 Gates: {1} | Lean 4 QED: {2} | Proof: {3}" -f `
    $t348.status, $t348.all_gates_passed, $t348.lean4_theorems_qed, $t348.proof) -ForegroundColor Green

# 10. Execute Tool 349: 12-Prompt Human Vagueness, Sloppy Idea & Metaphor Transducer Gauntlet (AMBIG-1..AMBIG-5)
Write-Host "`n[10/11] Tool 349: 12-Prompt Human Vagueness, Sloppy Idea & Metaphor Gauntlet (AMBIG-1..AMBIG-5)..." -ForegroundColor Yellow
$t349 = Invoke-SovereignJson "/api/v1/sovereign_harmonic/week3/human_ambiguity_and_metaphor_gauntlet" "POST" "{}"
Write-Host ("  -> Status: {0} | All 5 Ambiguity Modes Remediated: {1}" -f `
    $t349.status, $t349.all_5_ambiguity_modes_remediated) -ForegroundColor Green
Write-Host ("  -> [AMBIG-1..3] Metaphors Resolved={0} | Track Matches={1} | Non-Truncated={2} | Compound Plucker Bridges={3}" -f `
    $t349.ambig1_metaphor_to_manifold_transduction.metaphors_resolved, `
    $t349.ambig1_metaphor_to_manifold_transduction.exact_track_and_concept_matches, `
    $t349.ambig2_single_token_truncation_eliminated.post_remediation_full_completions, `
    $t349.ambig3_compound_multi_intent_plucker_synthesis.compound_prompts_bridged) -ForegroundColor Cyan
Write-Host ("  -> [AMBIG-4..5] Unicode Escapes Clean={0} | Zero-Bracket Rust={1} | Sloppy Raw PPL={2} -> Transduced PPL={3}" -f `
    $t349.ambig4_unicode_escape_and_colloquial_stopword_filter.unicode_escapes_decoded_cleanly, `
    $t349.ambig5_week3_speculative_memory_and_muse_honesty_synthesis.zero_bracket_rust_prompts_verified, `
    $t349.ambig5_week3_speculative_memory_and_muse_honesty_synthesis.raw_sloppy_untransduced_ppl, `
    $t349.ambig5_week3_speculative_memory_and_muse_honesty_synthesis.transduced_canonical_grounded_ppl) -ForegroundColor Cyan

# 11. Execute Tool 350: CHAIN 350 Master Certification (v71.3.2 | 950/950 Lean 4 QED)
Write-Host "`n[11/11] Tool 350: CHAIN 350 Master Certification (950/950 Lean 4 QED)..." -ForegroundColor Yellow
$t350 = Invoke-SovereignJson "/api/v1/chain350/master_certification" "POST" "{}"
Write-Host ("  -> Status: {0} | All CHAIN 350 Gates: {1} | Lean 4 QED: {2} | Proof: {3}" -f `
    $t350.status, $t350.all_gates_passed, $t350.lean4_theorems_qed, $t350.proof) -ForegroundColor Green

if (-not $t345.all_12_tests_passed -or -not $t346.gates.all_week3_gates_passed -or -not $t347.all_10_redteam_failures_remediated -or -not $t348.all_gates_passed -or -not $t349.all_5_ambiguity_modes_remediated -or -not $t350.all_gates_passed -or -not $t322.hard_gate_0_frozen_holdout_v2.gate_0_passed) {
    Write-Error "WEEK 3 12-TEST TORTURE + 10-MODE RED-TEAM + 12-PROMPT METAPHOR SUITE FAILED ONE OR MORE GATES!"
    exit 1
}

Write-Host "`n===============================================================================" -ForegroundColor Cyan
Write-Host "  WEEK 3 + RED-TEAM SUITE: 12/12 W3 + 10/10 RT-1..10 & CHAIN 348 PASSED!       " -ForegroundColor Green
Write-Host "===============================================================================" -ForegroundColor Cyan
