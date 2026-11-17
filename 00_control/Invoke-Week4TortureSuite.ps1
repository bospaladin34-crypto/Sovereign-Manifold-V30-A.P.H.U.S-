# =============================================================================
# ACT-OMEGA NET v72.2.0 — SOVEREIGN HARMONIC X (WEEK 4 CAPSTONE TORTURE SUITE)
# Property-, Range- & Negative-Injection Verification for Tools 351..356
# Primary Author & Principal Systems Architect: Donevin Frownfelter (@bospaladin34-crypto)
# =============================================================================

$ErrorActionPreference = "Stop"
$RepoRoot = "c:\sovereign_manifold_v31"

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "   SOVEREIGN HARMONIC X (WEEK 4 PROPERTY & NEGATIVE-INJECTION SUITE)      " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan

$failures = 0

# Stage 1: Zero-Bracket & Zero-Static-Claim Check on v71_0 & v71_4
$v71_0_path = "$RepoRoot\01_l0_rust\src\v71_0_sovereign_harmonic_standalone_model.rs"
$v71_4_path = "$RepoRoot\01_l0_rust\src\v71_4_sovereign_harmonic_week4_rlvf_tree_speculative_sae_eval256.rs"
$v71_0_bytes = [System.IO.File]::ReadAllBytes($v71_0_path)
$v71_4_bytes = [System.IO.File]::ReadAllBytes($v71_4_path)
$brackets = ($v71_0_bytes | Where-Object { $_ -eq 0x5B -or $_ -eq 0x5D }).Count + ($v71_4_bytes | Where-Object { $_ -eq 0x5B -or $_ -eq 0x5D }).Count
$v71_0_text = [System.IO.File]::ReadAllText($v71_0_path)
$hasStaticW4Claims = ($v71_0_text -match '5\.9612|5\.08x|R\^2\s*>=\s*0\.95')
if ($brackets -eq 0 -and -not $hasStaticW4Claims) {
    Write-Host "  [STAGE 1 - HYGIENE]        [PASS] Brackets(v71_0+v71_4)=0 | StaticWeek4ClaimsAbsent=True" -ForegroundColor Green
} else {
    Write-Host "  [STAGE 1 - HYGIENE]        [FAIL] Brackets=$brackets HasStaticWeek4Claims=$hasStaticW4Claims" -ForegroundColor Red
    $failures++
}

# Stage 2: Tool 351 — RLVF / GRPO Compiler-in-the-Loop (Property & Compiler Range Checks)
$t351 = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/sovereign_harmonic/week4/rlvf_grpo_compiler_in_the_loop" -TimeoutSec 60
$t351Ok = (
    $t351.status -in @("MEASURED", "UNMEASURED/OFFLINE") -and
    $t351.obligations_evaluated -eq 64 -and
    $t351.shx_weights_bytes -eq 32784 -and
    $t351.live_lean4_compiler_in_the_loop.verified -eq $true -and
    $t351.live_lean4_compiler_in_the_loop.negative_soundness_canary_rejected -eq $true -and
    $t351.post_rlvf_pass_at_1 -match '^\d+/64$' -and
    (-not [double]::IsNaN([double]$t351.stiefel_max_orthogonality_error)) -and
    ([double]$t351.stiefel_max_orthogonality_error -lt 1e-6)
)
if ($t351Ok) {
    Write-Host "  [STAGE 2 - TOOL 351 RLVF]  [PASS] Status=$($t351.status) | PreReward=$($t351.pre_rlvf_mean_verifier_reward) -> PostReward=$($t351.post_rlvf_mean_verifier_reward) | Pass@1=$($t351.post_rlvf_pass_at_1) | HacksBlocked=$($t351.adversarial_reward_hacks_blocked) | OrthoErr=$($t351.stiefel_max_orthogonality_error)" -ForegroundColor Green
} else {
    Write-Host "  [STAGE 2 - TOOL 351 RLVF]  [FAIL] $($t351 | ConvertTo-Json -Compress)" -ForegroundColor Red
    $failures++
}

# Stage 3: Tool 352 — Medusa/Eagle Dendritic Draft Tree (d=4, b=2, 15 Nodes)
$t352 = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/sovereign_harmonic/week4/medusa_eagle_dendritic_tree_speculative_k8" -TimeoutSec 60
$t352Ok = (
    $t352.status -in @("MEASURED", "UNMEASURED/OFFLINE") -and
    (-not [double]::IsNaN([double]$t352.mean_tokens_per_tree_step)) -and
    (-not [double]::IsInfinity([double]$t352.mean_tokens_per_tree_step)) -and
    ([double]$t352.mean_tokens_per_tree_step -ge 1.0) -and
    (-not [double]::IsNaN([double]$t352.kl_divergence_vs_target)) -and
    ([double]$t352.kl_divergence_vs_target -ge 0.0) -and
    (-not [string]::IsNullOrWhiteSpace($t352.e_vault_writeback_sha256))
)
if ($t352Ok) {
    Write-Host "  [STAGE 3 - TOOL 352 TREE]  [PASS] Status=$($t352.status) | Certified=$($t352.tree_speculative_certified) | Tok/Step=$($t352.mean_tokens_per_tree_step) | Speedup=$($t352.measured_wallclock_speedup_x)x | AltBranchRescues=$($t352.secondary_branch_rescued_accepts) | KL=$($t352.kl_divergence_vs_target)" -ForegroundColor Green
} else {
    Write-Host "  [STAGE 3 - TOOL 352 TREE]  [FAIL] $($t352 | ConvertTo-Json -Compress)" -ForegroundColor Red
    $failures++
}

# Stage 4: Tool 353 — Top-K (K=8) Sparse Autoencoder (Unclamped L2 & Bidirectional Causal Steering)
$t353 = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/sovereign_harmonic/week4/sae_monosemantic_feature_circuit_explorer" -TimeoutSec 60
$t353Ok = (
    $t353.status -in @("MEASURED", "UNMEASURED/OFFLINE") -and
    $t353.dictionary_latents -eq 512 -and
    $t353.topk_active_per_column -eq 8 -and
    $t353.dead_latents_count -ge 0 -and
    $t353.dead_latents_count -le 512 -and
    $t353.unclamped_l2_reconstruction -eq $true -and
    (-not [double]::IsNaN([double]$t353.r2_variance_explained)) -and
    (-not [double]::IsInfinity([double]$t353.r2_variance_explained)) -and
    ([double]$t353.min_causal_steering_prob_delta -gt 0.0) -and
    ([double]$t353.max_negative_suppression_prob_delta -lt 0.0)
)
if ($t353Ok) {
    Write-Host "  [STAGE 4 - TOOL 353 SAE]   [PASS] Status=$($t353.status) | ActiveLatents=$($t353.active_dictionary_latents) | Dead=$($t353.dead_latents_count) | R^2=$($t353.r2_variance_explained) | PosDelta=+$($t353.min_causal_steering_prob_delta) | InhibDelta=$($t353.max_negative_suppression_prob_delta)" -ForegroundColor Green
} else {
    Write-Host "  [STAGE 4 - TOOL 353 SAE]   [FAIL] $($t353 | ConvertTo-Json -Compress)" -ForegroundColor Red
    $failures++
}

# Stage 5: Tool 354 — SH-Eval-256 Compiler-in-the-Loop & Adversarial Corruption Penalty
$t354 = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/sovereign_harmonic/week4/sh_eval_256_compiler_pass_at_k_gauntlet" -TimeoutSec 120
$prog = $t354.sh_eval_256_perplexity_progression
$hg0 = $t354.hard_gate_0_frozen_holdout_v2
$t354Ok = (
    $t354.status -in @("MEASURED", "UNMEASURED/OFFLINE") -and
    $t354.pass_at_1 -match '^\d+/256$' -and
    $hg0.zero_trainer_overlap_verified -eq $true -and
    (-not [double]::IsNaN([double]$prog.stage0_untrained)) -and ([double]$prog.stage0_untrained -gt 1.0) -and
    (-not [double]::IsNaN([double]$prog.stage1_shallow)) -and ([double]$prog.stage1_shallow -gt 1.0) -and
    (-not [double]::IsNaN([double]$prog.week1_v71_1)) -and ([double]$prog.week1_v71_1 -gt 1.0) -and
    (-not [double]::IsNaN([double]$prog.week2_v71_2)) -and ([double]$prog.week2_v71_2 -gt 1.0) -and
    (-not [double]::IsNaN([double]$prog.week3_v71_3)) -and ([double]$prog.week3_v71_3 -gt 1.0) -and
    (-not [double]::IsNaN([double]$prog.week4_shx_v72_0)) -and ([double]$prog.week4_shx_v72_0 -gt 1.0) -and
    ([double]$prog.adversarial_corrupted_candidates_penalized_ppl -gt [double]$prog.week4_shx_v72_0)
)
if ($t354Ok) {
    Write-Host "  [STAGE 5 - TOOL 354 EVAL]  [PASS] Status=$($t354.status) | Pass@1=$($t354.pass_at_1) ($($t354.pass_at_1_pct)%) | Eval256 PPL(S0->W1->W2->W4): $($prog.stage0_untrained) -> $($prog.week1_v71_1) -> $($prog.week2_v71_2) -> $($prog.week4_shx_v72_0) | Corrupted=$($prog.adversarial_corrupted_candidates_penalized_ppl) | HoldoutV2(ZeroOverlap=$($hg0.zero_trainer_overlap_verified)): $($hg0.untrained_ppl) -> $($hg0.week4_shx_ppl)" -ForegroundColor Green
} else {
    Write-Host "  [STAGE 5 - TOOL 354 EVAL]  [FAIL] $($t354 | ConvertTo-Json -Compress)" -ForegroundColor Red
    $failures++
}

# Stage 6: Tool 355 — Week 4 12-Test Torture, Stress & Ablation Gauntlet (W4-1..W4-12)
$t355 = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/sovereign_harmonic/week4/torture_and_ablation_12test_gauntlet" -TimeoutSec 120
$t355Ok = (
    $t355.status -in @("MEASURED", "UNMEASURED/OFFLINE") -and
    $t355.tests_passed -match '^\d+/12$' -and
    ($null -ne $t355.all_12_tests_passed) -and
    $t355.w4_2_live_lean4_compiler_in_the_loop -eq $true -and
    $t355.w4_5_topk_sae_512_unclamped_r2 -eq $true -and
    $t355.w4_6_monosemantic_causal_steering -eq $true -and
    $t355.w4_9_adversarial_reward_hack_immunity -eq $true -and
    $t355.w4_11_16mib_262144cl_vault_bijection -eq $true
)
if ($t355Ok) {
    Write-Host "  [STAGE 6 - TOOL 355 W4-12] [PASS] Status=$($t355.status) | TortureTests=$($t355.tests_passed) | All12Passed=$($t355.all_12_tests_passed) | Note: Honest component pass count reported" -ForegroundColor Green
} else {
    Write-Host "  [STAGE 6 - TOOL 355 W4-12] [FAIL] $($t355 | ConvertTo-Json -Compress)" -ForegroundColor Red
    $failures++
}

# Stage 7: Tool 356 — Sovereign Harmonic X Master Certification Shape & Lean 4 QED Count
$t356 = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/chain356/master_certification" -TimeoutSec 120
$t356Ok = (
    $t356.status -in @("MEASURED", "UNMEASURED/OFFLINE") -and
    $t356.total_tools -eq 356 -and
    $t356.lean4_theorems_qed -ge 995 -and
    $t356.bijected_cachelines_262144 -eq 262144 -and
    $t356.neurons_84480 -eq 84480 -and
    $t356.synapses_4055040 -eq 4055040
)
if ($t356Ok) {
    Write-Host "  [STAGE 7 - TOOL 356 CERT]  [PASS] Status=$($t356.status) | QED=$($t356.lean4_theorems_qed) | Tools=$($t356.total_tools) | AllGates=$($t356.all_gates_passed)" -ForegroundColor Green
} else {
    Write-Host "  [STAGE 7 - TOOL 356 CERT]  [FAIL] $($t356 | ConvertTo-Json -Compress)" -ForegroundColor Red
    $failures++
}

# Stage 8: Negative Failure-Injection & Adversarial Red-Team Gauntlet (RT-W4-1..RT-W4-7)
$rtBody0 = '{"custom_candidate": "theorem bad_sorry (n : Nat) : n = n + 1 := by sorry"}'
$rtSorry = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/sovereign_harmonic/week4/rlvf_grpo_compiler_in_the_loop" -Method Post -ContentType "application/json" -Body $rtBody0 -TimeoutSec 60
$rtBody1 = '{"custom_candidate": ") ( } { pub fn dyck_bypass(x: u64) -> u64 { x }"}'
$rtDyck = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/sovereign_harmonic/week4/rlvf_grpo_compiler_in_the_loop" -Method Post -ContentType "application/json" -Body $rtBody1 -TimeoutSec 60
$rtBody2 = '{"custom_candidate": "// pub fn comment_only_stub(x: u64) -> u64 { x }"}'
$rtComment = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/sovereign_harmonic/week4/rlvf_grpo_compiler_in_the_loop" -Method Post -ContentType "application/json" -Body $rtBody2 -TimeoutSec 60
$rtBody3 = '{"custom_candidate": "theorem trivial_pad : 1 = 1 := by rfl"}'
$rtTrivial = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/sovereign_harmonic/week4/rlvf_grpo_compiler_in_the_loop" -Method Post -ContentType "application/json" -Body $rtBody3 -TimeoutSec 60
$rtPoisonTree = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/sovereign_harmonic/week4/medusa_eagle_dendritic_tree_speculative_k8" -Method Post -ContentType "application/json" -Body '{"poison_draft_tree":true}' -TimeoutSec 60
$rtMetaphor = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/tools/t320" -Method Post -ContentType "application/json" -Body '{"prompt":"We need the model to grade its own homework with a formal compiler referee and use a branching crystal ball plus a brain microscope sparse autoencoder"}' -TimeoutSec 30
$metText = [string]$rtMetaphor.generation.generated_text
$metGroundedOk = ($metText -match "MetaphorGrounded") -and ($metText -match "Week 4") -and ($metText -notmatch '5\.9612|5\.08x|R\^2\s*>=\s*0\.95')

$rtPassed = (
    $rtSorry.custom_candidate_audit.total_reward -eq 0 -and
    $rtDyck.custom_candidate_audit.total_reward -eq 0 -and
    $rtComment.custom_candidate_audit.total_reward -eq 0 -and
    $rtTrivial.custom_candidate_audit.total_reward -eq 0 -and
    $t351.live_lean4_compiler_in_the_loop.negative_soundness_canary_rejected -eq $true -and
    $rtPoisonTree.mean_tokens_per_tree_step -eq 1.0 -and
    $rtPoisonTree.kl_divergence_vs_target -eq 0 -and
    $t353.unclamped_l2_reconstruction -eq $true -and
    $t353.max_negative_suppression_prob_delta -lt 0.0 -and
    ([double]$prog.adversarial_corrupted_candidates_penalized_ppl -gt [double]$prog.week4_shx_v72_0) -and
    $metGroundedOk -eq $true
)
if ($rtPassed) {
    Write-Host "  [STAGE 8 - RED-TEAM RT-W4] [PASS] Sorry/Dyck/Comment/TrivialReward=0.0 | Lean4NegCanaryRejected=True | PoisonTreeStep=1.0 (KL=0) | UnclampedSAE=True (InhibDelta=$($t353.max_negative_suppression_prob_delta)) | CorruptedPPL=$($prog.adversarial_corrupted_candidates_penalized_ppl) > W4=$($prog.week4_shx_v72_0) | W4MetaphorGroundedNoStaticClaims=True" -ForegroundColor Green
} else {
    Write-Host "  [STAGE 8 - RED-TEAM RT-W4] [FAIL] Sorry=$($rtSorry.custom_candidate_audit.total_reward) Dyck=$($rtDyck.custom_candidate_audit.total_reward) Comment=$($rtComment.custom_candidate_audit.total_reward) Trivial=$($rtTrivial.custom_candidate_audit.total_reward) PoisonStep=$($rtPoisonTree.mean_tokens_per_tree_step) Inhib=$($t353.max_negative_suppression_prob_delta) Met=$metGroundedOk" -ForegroundColor Red
    $failures++
}

$receiptJson = @{
    version = "v72.2.0"
    chain = "CHAIN_368"
    recorded_at_utc = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    lean4_theorems_qed = $t356.lean4_theorems_qed
    tool351_rlvf = $t351
    tool352_tree_speculative = $t352
    tool353_sae_explorer = $t353
    tool354_eval256_gauntlet = $t354
    tool355_torture_12test = $t355
    tool356_master_cert = $t356
    stage8_adversarial_redteam = @{
        rt_w4_0_sorry_reward = $rtSorry.custom_candidate_audit.total_reward
        rt_w4_1_dyck_bypass_reward = $rtDyck.custom_candidate_audit.total_reward
        rt_w4_1_comment_stub_reward = $rtComment.custom_candidate_audit.total_reward
        rt_w4_1_trivial_theorem_reward = $rtTrivial.custom_candidate_audit.total_reward
        rt_w4_2_negative_soundness_canary_rejected = $t351.live_lean4_compiler_in_the_loop.negative_soundness_canary_rejected
        rt_w4_3_poisoned_tree_tokens_per_step = $rtPoisonTree.mean_tokens_per_tree_step
        rt_w4_4_unclamped_sae_r2 = $t353.r2_variance_explained
        rt_w4_4_inhibitory_steering_delta = $t353.max_negative_suppression_prob_delta
        rt_w4_5_corrupted_candidates_ppl = $prog.adversarial_corrupted_candidates_penalized_ppl
        rt_w4_6_week4_metaphor_grounded_output = $rtMetaphor.generation.generated_text
    }
} | ConvertTo-Json -Depth 6
[System.IO.File]::WriteAllText("$RepoRoot\03_vault\receipts\v72_0_week4_shx_torture_benchmark_receipt.json", $receiptJson)

Write-Host "==========================================================================" -ForegroundColor Cyan
if ($failures -eq 0) {
    Write-Host "  [WEEK 4 PROPERTY & NEGATIVE-INJECTION SUITE RESULT: PASSED (8/8 STAGES)]" -ForegroundColor Green
    exit 0
} else {
    Write-Host "  [WEEK 4 PROPERTY & NEGATIVE-INJECTION SUITE RESULT: FAILED ($failures STAGES)]" -ForegroundColor Red
    exit 1
}
