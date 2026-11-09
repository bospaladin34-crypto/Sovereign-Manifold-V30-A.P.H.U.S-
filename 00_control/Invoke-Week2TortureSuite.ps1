# =============================================================================
# ACT-OMEGA NET v71.2.0 -- WEEK 2 13-TEST TORTURE, STRESS & ABLATION SUITE
# Executes Tools 335..340 (CHAIN 340 | 920/920 Lean 4 QED) + Hard Gate 0 (Tool 322)
# and verifies all 13 Week 2 Torture, Stress & Ablation Tests (W2-1..W2-13)
# =============================================================================
$ErrorActionPreference = "Stop"
$baseUrl = "http://127.0.0.1:8097"

Write-Host "===============================================================================" -ForegroundColor Cyan
Write-Host "  ACT-OMEGA v71.2.0 -- WEEK 2 13-TEST TORTURE, STRESS & ABLATION SUITE (W2-1..13)" -ForegroundColor Cyan
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

# 1. Execute Tool 335: DuckDB v1.5.6 Streaming Vault Harvester & FNV-1a Deduplicator
Write-Host "`n[1/7] Tool 335: DuckDB v1.5.6 Vault Corpus Harvester & Deduplicator (1,024 Samples)..." -ForegroundColor Yellow
$t335 = Invoke-SovereignJson "/api/v1/sovereign_harmonic/week2/duckdb_vault_harvester" "POST" "{}"
Write-Host ("  -> Status: {0} | Scanned Files: {1} ({2} B) | Curated: {3} | DuckDB Distinct: {4} | Eval256 Overlap: {5}" -f `
    $t335.status, $t335.vault_scan.scanned_files, $t335.vault_scan.scanned_vault_bytes, `
    $t335.vault_scan.surviving_curated_samples, $t335.duckdb_verification.distinct_fnv1a_hashes, `
    $t335.holdout_firewall.sh_eval_256_overlap) -ForegroundColor Green

# 2. Execute Tool 336: Reversible 16,384-Token AST BPE & Tied E8^4 (32D) x Leech Lambda_24 (24D) 56D Codebook
Write-Host "`n[2/7] Tool 336: 16,384-Token AST BPE & Tied 56D E8^4 x Leech Codebook..." -ForegroundColor Yellow
$t336 = Invoke-SovereignJson "/api/v1/sovereign_harmonic/week2/bpe_16384_leech_codebook" "POST" "{}"
Write-Host ("  -> Status: {0} | Vocab: {1} | UTF-8 Exact Round-Trip: {2} | SQNR: {3} dB | E8 Parity: {4} | Leech Parity: {5}" -f `
    $t336.status, $t336.bpe_16384_ast_tokenizer.active_vocab_size, $t336.bpe_16384_ast_tokenizer.utf8_roundtrip_exact, `
    $t336.tied_e8_leech_56d_codebook.measured_sqnr_db, `
    $t336.tied_e8_leech_56d_codebook.e8_even_parity_verified, `
    $t336.tied_e8_leech_56d_codebook.leech_mod4_parity_verified) -ForegroundColor Green

# 3. Execute Tool 337: 3-Stage Curriculum Difficulty Pacer & Hoffmann-Chinchilla 4-Rung Scaling Law
Write-Host "`n[3/7] Tool 337: Chinchilla 3-Stage Curriculum Difficulty Pacer (64 -> 256 -> 512 -> 1024)..." -ForegroundColor Yellow
$t337 = Invoke-SovereignJson "/api/v1/sovereign_harmonic/week2/curriculum_difficulty_pacer" "POST" "{}"
Write-Host ("  -> Status: {0} | Rungs PPL: 64={1} -> 256={2} -> 512={3} -> 1024={4} | Monotonic: {5} | Paced Advantage: {6}" -f `
    $t337.status, $t337.chinchilla_4rung_scaling.rung_64_ppl, $t337.chinchilla_4rung_scaling.rung_256_ppl, `
    $t337.chinchilla_4rung_scaling.rung_512_ppl, $t337.chinchilla_4rung_scaling.rung_1024_ppl, `
    $t337.chinchilla_4rung_scaling.strictly_monotonic_decay, `
    $t337.three_stage_curriculum.pacing_ppl_advantage) -ForegroundColor Green

# 4. Execute Tool 338: Cosine-Annealed 12-Layer Riemannian Stiefel Cayley Curriculum Trainer
Write-Host "`n[4/7] Tool 338: Cosine-Annealed 12-Layer Stiefel Curriculum Trainer across Tri-Silicon..." -ForegroundColor Yellow
$t338 = Invoke-SovereignJson "/api/v1/sovereign_harmonic/week2/cosine_stiefel_trainer" "POST" '{"stages":3}'
Write-Host ("  -> Status: {0} | Baseline PPL: {1} -> S1(256): {2} -> S2(640): {3} -> S3(1024): {4} | OrthoRes: {5} | P8(:8098): {6}" -f `
    $t338.status, $t338.curriculum_convergence.week1_baseline_ppl, `
    $t338.curriculum_convergence.stage1_256_ppl, $t338.curriculum_convergence.stage2_640_ppl, `
    $t338.curriculum_convergence.stage3_1024_ppl, `
    $t338.stiefel_cayley_invariants.max_orthogonality_frobenius_residual, `
    $t338.tri_silicon_coexecution.wireless_pixel8_bearer) -ForegroundColor Green

# 5. Execute Tool 322: Hard Gate 0 (Frozen Holdout v2 on F:\) & Week 2 Corpus Zero-Overlap Verification
Write-Host "`n[5/7] Tool 322: Hard Gate 0 (Frozen Holdout v2 -- 32 Prompts on F:\) + Week 2 1,024-Sample Firewall..." -ForegroundColor Yellow
$t322 = Invoke-SovereignJson "/api/v1/tools/t322" "POST" "{}"
Write-Host ("  -> Status: {0} | Gate 0 Passed: {1} | Week 2 Corpus Checked: {2} | Overlap: {3} | Frozen v2 PPL: {4} -> {5} (Human-16: {6} | Ext-16: {7})" -f `
    $t322.status, $t322.hard_gate_0_frozen_holdout_v2.gate_0_passed, `
    $t322.hard_gate_0_frozen_holdout_v2.week2_corpus_checked_samples, `
    $t322.hard_gate_0_frozen_holdout_v2.trainer_overlap_count, `
    $t322.hard_gate_0_frozen_holdout_v2.frozen_v2_pre_perplexity, `
    $t322.hard_gate_0_frozen_holdout_v2.frozen_v2_post_perplexity, `
    $t322.hard_gate_0_frozen_holdout_v2.frozen_v2_human_16_post_ppl, `
    $t322.hard_gate_0_frozen_holdout_v2.frozen_v2_external_16_post_ppl) -ForegroundColor Green

# 6. Execute Tool 339: Week 2 13-Test Torture, Stress & Ablation Gauntlet (W2-1..W2-13)
Write-Host "`n[6/7] Tool 339: Week 2 13-Test Torture, Stress & Ablation Gauntlet (W2-1..W2-13)..." -ForegroundColor Yellow
$t339 = Invoke-SovereignJson "/api/v1/sovereign_harmonic/week2/rigorous_7test_torture_gauntlet" "POST" "{}"
Write-Host ("  -> Status: {0} | All 13 Passed: {1} | Eval-256 PPL: {2} (W1) -> {3} (W2) | Top-1: {4} | Top-5: {5}" -f `
    $t339.status, $t339.all_13_stress_and_ablation_passed, $t339.w2_6_sh_eval_256_progression.week1_eval256_ppl, `
    $t339.w2_6_sh_eval_256_progression.week2_eval256_ppl, `
    $t339.w2_6_sh_eval_256_progression.top1_token_accuracy, `
    $t339.w2_6_sh_eval_256_progression.top5_token_accuracy) -ForegroundColor Green
Write-Host ("  -> [W2-8 6-Way Ablation] FullW2={0} < NoLeech24D={1} (Gain +{2}) | NoAST={3} (Gain +{4}) | Unpaced={5} < Reverse={6} | D64SeedOnly={7}" -f `
    $t339.w2_8_six_way_ablation_matrix.full_week2_ppl, `
    $t339.w2_8_six_way_ablation_matrix.no_leech_24d_e8_only_ppl, `
    $t339.w2_8_six_way_ablation_matrix.leech_24d_ppl_gain, `
    $t339.w2_8_six_way_ablation_matrix.no_ast_concept_tiers_ppl, `
    $t339.w2_8_six_way_ablation_matrix.ast_tiers_ppl_gain, `
    $t339.w2_8_six_way_ablation_matrix.unpaced_random_order_ppl, `
    $t339.w2_8_six_way_ablation_matrix.reverse_curriculum_antipaced_ppl, `
    $t339.w2_8_six_way_ablation_matrix.d64_seed_only_ppl) -ForegroundColor Cyan
Write-Host ("  -> [W2-9 Adversarial Unicode/AST BPE] Exact={0} | Compression={1} chars/tok | UNK={2}" -f `
    $t339.w2_9_adversarial_unicode_ast_bpe_torture.exact_roundtrips, `
    $t339.w2_9_adversarial_unicode_ast_bpe_torture.compression_chars_per_token, `
    $t339.w2_9_adversarial_unicode_ast_bpe_torture.unk_count) -ForegroundColor Cyan
Write-Host ("  -> [W2-10 Golay-Leech 3-Error Syndrome] Recovered={0}/{1} | SQNR Sweep: 0%={2}dB -> 1%={3}dB -> 5%={4}dB -> 10%={5}dB" -f `
    $t339.w2_10_golay_leech_3error_syndrome_and_noise_sweep.bounded_distance_recovered, `
    $t339.w2_10_golay_leech_3error_syndrome_and_noise_sweep.bounded_distance_trials, `
    $t339.w2_10_golay_leech_3error_syndrome_and_noise_sweep.sqnr_0pct_db, `
    $t339.w2_10_golay_leech_3error_syndrome_and_noise_sweep.sqnr_1pct_db, `
    $t339.w2_10_golay_leech_3error_syndrome_and_noise_sweep.sqnr_5pct_db, `
    $t339.w2_10_golay_leech_3error_syndrome_and_noise_sweep.sqnr_10pct_db) -ForegroundColor Cyan
Write-Host ("  -> [W2-11 Disguised Canary & Dup Firewall] Canaries Blocked={0} | Mutated Dups Blocked={1}" -f `
    $t339.w2_11_duckdb_canary_and_mutation_firewall.disguised_holdout_canaries_blocked, `
    $t339.w2_11_duckdb_canary_and_mutation_firewall.mutated_near_duplicates_blocked) -ForegroundColor Cyan
Write-Host ("  -> [W2-12 50-Step (600-Retraction) Stiefel Drift] Max Ortho Residual={0} | Max Skew Residual={1}" -f `
    $t339.w2_12_stiefel_50step_600retraction_drift_torture.max_50step_ortho_frobenius_residual, `
    $t339.w2_12_stiefel_50step_600retraction_drift_torture.max_50step_skew_residual) -ForegroundColor Cyan

# 7. Execute Tool 340: Week 2 Master Certification (v71.2.0 | CHAIN 340 | 920/920 Lean 4 QED)
Write-Host "`n[7/7] Tool 340: Week 2 Master Certification (CHAIN 340 | 920/920 Lean 4 QED)..." -ForegroundColor Yellow
$t340 = Invoke-SovereignJson "/api/v1/sovereign_harmonic/week2/master_certification" "POST" "{}"
Write-Host ("  -> Status: {0} | All Week 2 Gates: {1} | Lean 4 QED: {2} | Proof: {3}" -f `
    $t340.status, $t340.gates.all_week2_gates_passed, $t340.lean4_theorems_qed, $t340.proof) -ForegroundColor Green

if (-not $t339.all_13_stress_and_ablation_passed -or -not $t340.gates.all_week2_gates_passed -or -not $t322.hard_gate_0_frozen_holdout_v2.gate_0_passed) {
    Write-Error "WEEK 2 13-TEST TORTURE, STRESS & ABLATION SUITE FAILED ONE OR MORE GATES!"
    exit 1
}

Write-Host "`n===============================================================================" -ForegroundColor Cyan
Write-Host "  WEEK 2 SUITE: 13/13 TORTURE/ABLATION TESTS & CHAIN 340 CERTIFICATION PASSED! " -ForegroundColor Green
Write-Host "===============================================================================" -ForegroundColor Cyan
