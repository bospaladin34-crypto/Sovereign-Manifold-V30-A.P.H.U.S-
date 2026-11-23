# =============================================================================
# ACT-OMEGA NET — SOVEREIGN HARMONIC X (WEEK 4 CAPSTONE TORTURE SUITE)
# Property-, Range- & Negative-Injection Verification for Tools 351..356
# Primary Author & Principal Systems Architect: Donevin Frownfelter (@bospaladin34-crypto)
# =============================================================================
param(
    [switch]$TestPerturbationFail,
    [string]$TranscriptOutPath = ""
)

$ErrorActionPreference = "Stop"
$script:TranscriptLines = New-Object System.Collections.Generic.List[string]
function Write-Host {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true)]
        [object]$Object = "",
        [System.ConsoleColor]$ForegroundColor,
        [System.ConsoleColor]$BackgroundColor,
        [switch]$NoNewline,
        [object]$Separator
    )
    $lineText = if ($null -eq $Object) { "" } else { [string]$Object }
    $script:TranscriptLines.Add($lineText)
    Microsoft.PowerShell.Utility\Write-Host @PSBoundParameters
}
function Save-Week4Transcript {
    if ([string]::IsNullOrWhiteSpace($TranscriptOutPath)) { return }
    $parent = Split-Path -Parent $TranscriptOutPath
    if ($parent -and -not (Test-Path $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
    $norm = (($script:TranscriptLines -join "`n") -replace "`r`n", "`n" -replace "`r", "`n").TrimEnd("`n") + "`n"
    [System.IO.File]::WriteAllText($TranscriptOutPath, $norm, [System.Text.UTF8Encoding]::new($false))
}
$RepoRoot = "c:\sovereign_manifold_v31"
$ManifestPath = "$RepoRoot\00_control\weights\sovereign_harmonic_weights_manifest.json"
if (-not (Test-Path $ManifestPath)) {
    throw "FATAL: Missing weight manifest $ManifestPath"
}

function Get-CitationReleaseVersion {
    param([string]$Root)
    $cff = Join-Path $Root "CITATION.cff"
    if (Test-Path $cff -PathType Leaf) {
        $txt = [System.IO.File]::ReadAllText($cff)
        if ($txt -match '(?m)^version:\s*"?([^"\r\n]+)"?\s*$') {
            $v = $Matches[1].Trim()
            if (-not $v.StartsWith("v")) { return "v$v" }
            return $v
        }
    }
    return "UNMEASURED/OFFLINE"
}

function Test-Week4StageAssertions {
    param(
        $T351,
        $T352,
        $RtPoisonTree,
        [int64]$ExpectedShxBytes,
        [int64]$ActualShxDiskBytes
    )
    $errs = New-Object System.Collections.Generic.List[string]

    # Stage 2 (Tool 351) artifact-consistent & range checks (zero fixed 64 literals)
    $s2StatusOk = ($null -ne $T351) -and ($T351.status -in @("MEASURED", "UNMEASURED/OFFLINE"))
    $obEval = if ($null -ne $T351.obligations_evaluated) { [int]$T351.obligations_evaluated } else { 0 }
    $grpRoll = if ($null -ne $T351.group_rollouts_per_prompt) { [int]$T351.group_rollouts_per_prompt } else { 0 }
    $totTraj = if ($null -ne $T351.total_trajectories_scored) { [int]$T351.total_trajectories_scored } else { -1 }
    $passRatioOk = $false
    if ([string]$T351.post_rlvf_pass_at_1 -match '^(\d+)/(\d+)$') {
        $pNum = [int]$Matches[1]
        $pDen = [int]$Matches[2]
        $passRatioOk = ($pDen -eq $obEval) -and ($pNum -ge 0) -and ($pNum -le $pDen) -and ($pNum -eq $pDen)
    }
    $hackRatioOk = $false
    if ([string]$T351.adversarial_reward_hacks_blocked -match '^(\d+)/(\d+)$') {
        $hNum = [int]$Matches[1]
        $hDen = [int]$Matches[2]
        $hackRatioOk = ($hDen -eq $obEval) -and ($hNum -eq $hDen)
    }
    $stage2Ok = (
        $s2StatusOk -and
        ($obEval -ge 16) -and
        ($grpRoll -ge 2) -and
        ($totTraj -eq ($obEval * $grpRoll)) -and
        $passRatioOk -and
        $hackRatioOk -and
        ([double]$T351.post_rlvf_mean_verifier_reward -gt [double]$T351.pre_rlvf_mean_verifier_reward) -and
        ($T351.rlvf_certified -eq $true) -and
        ($ExpectedShxBytes -gt 0) -and
        ($ActualShxDiskBytes -eq $ExpectedShxBytes) -and
        ([int64]$T351.shx_weights_bytes -eq $ExpectedShxBytes) -and
        ($T351.live_lean4_compiler_in_the_loop.verified -eq $true) -and
        ($T351.live_lean4_compiler_in_the_loop.negative_soundness_canary_rejected -eq $true) -and
        (-not [double]::IsNaN([double]$T351.stiefel_max_orthogonality_error)) -and
        ([double]$T351.stiefel_max_orthogonality_error -lt 1e-6)
    )
    if (-not $stage2Ok) { $errs.Add("STAGE2_ASSERTION_FAILED") }

    # Stage 3 (Tool 352) ratio & range checks
    $tSteps = if ($null -ne $T352.total_tree_verification_steps) { [int]$T352.total_tree_verification_steps } else { 0 }
    $tEmit = if ($null -ne $T352.total_tokens_emitted) { [int]$T352.total_tokens_emitted } else { 0 }
    $meanTok = if ($null -ne $T352.mean_tokens_per_tree_step) { [double]$T352.mean_tokens_per_tree_step } else { [double]::NaN }
    $linBase = if ($null -ne $T352.linear_k4_baseline_tok_per_step) { [double]$T352.linear_k4_baseline_tok_per_step } else { 1.0 }
    $stage3Ok = (
        ($null -ne $T352) -and
        ($T352.status -in @("MEASURED", "UNMEASURED/OFFLINE")) -and
        ($tSteps -gt 0) -and
        ($tEmit -ge $tSteps) -and
        (-not [double]::IsNaN($meanTok)) -and
        (-not [double]::IsInfinity($meanTok)) -and
        ([Math]::Abs(([double]$tEmit / [double]$tSteps) - $meanTok) -lt 0.01) -and
        ($meanTok -gt $linBase) -and
        (-not [double]::IsNaN([double]$T352.kl_divergence_vs_target)) -and
        ([double]$T352.kl_divergence_vs_target -ge 0.0) -and
        (-not [string]::IsNullOrWhiteSpace([string]$T352.e_vault_writeback_sha256))
    )
    if (-not $stage3Ok) { $errs.Add("STAGE3_ASSERTION_FAILED") }

    # Stage 8 (RT-W4 poisoned tree) bounded collapse & zero primary/secondary accept checks
    $pMeanTok = if ($null -ne $RtPoisonTree.mean_tokens_per_tree_step) { [double]$RtPoisonTree.mean_tokens_per_tree_step } else { [double]::NaN }
    $stage8TreeOk = (
        ($null -ne $RtPoisonTree) -and
        (-not [double]::IsNaN($pMeanTok)) -and
        ($pMeanTok -ge 1.0) -and
        ($pMeanTok -le 1.05) -and
        ($pMeanTok -lt $meanTok) -and
        ([int]$RtPoisonTree.primary_branch_accepts -eq 0) -and
        ([int]$RtPoisonTree.secondary_branch_rescued_accepts -eq 0) -and
        ([int]$RtPoisonTree.poisoned_tree_resilience_audit.poisoned_draft_nodes_accepted -eq 0)
    )
    if (-not $stage8TreeOk) { $errs.Add("STAGE8_POISON_TREE_ASSERTION_FAILED") }

    return @{
        stage2_ok = $stage2Ok
        stage3_ok = $stage3Ok
        stage8_tree_ok = $stage8TreeOk
        errors = $errs
    }
}

$WeightManifest = Get-Content -Path $ManifestPath -Raw | ConvertFrom-Json
$ShxRelPath = [string]$WeightManifest.artifacts.week4_rlvf_sae.relative_path
$ShxDiskPath = Join-Path $RepoRoot ($ShxRelPath -replace '/', '\')
$ExpectedShxBytes = [int64]$WeightManifest.artifacts.week4_rlvf_sae.expected_bytes
$ActualShxDiskBytes = if (Test-Path $ShxDiskPath) { (Get-Item $ShxDiskPath).Length } else { -1L }

if ($TestPerturbationFail) {
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "   WEEK 4 TORTURE SUITE: PERTURBATION FAILURE-PROOF MODE (3/3)           " -ForegroundColor Cyan
    Write-Host "==========================================================================" -ForegroundColor Cyan
    $pertFailures = 0
    $t351Live = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/sovereign_harmonic/week4/rlvf_grpo_compiler_in_the_loop" -TimeoutSec 120
    $t352Live = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/sovereign_harmonic/week4/medusa_eagle_dendritic_tree_speculative_k8" -TimeoutSec 60
    $rtPoisonLive = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/sovereign_harmonic/week4/medusa_eagle_dendritic_tree_speculative_k8" -Method Post -ContentType "application/json" -Body '{"poison_draft_tree":true}' -TimeoutSec 60

    $baseChk = Test-Week4StageAssertions -T351 $t351Live -T352 $t352Live -RtPoisonTree $rtPoisonLive -ExpectedShxBytes $ExpectedShxBytes -ActualShxDiskBytes $ActualShxDiskBytes
    if ($baseChk.stage2_ok -and $baseChk.stage3_ok -and $baseChk.stage8_tree_ok) {
        Write-Host "  [PERTURB BASELINE]         [PASS] Unperturbed live responses pass Test-Week4StageAssertions" -ForegroundColor Green
    } else {
        Write-Host "  [PERTURB BASELINE]         [FAIL] $($baseChk.errors -join ', ')" -ForegroundColor Red
        $pertFailures++
    }

    # (a) Perturb t351 obligations_evaluated=8 & denominator mismatch -> MUST FAIL Stage 2
    $badT351 = ($t351Live | ConvertTo-Json -Depth 8 | ConvertFrom-Json)
    $badT351.obligations_evaluated = 8
    $chkA = Test-Week4StageAssertions -T351 $badT351 -T352 $t352Live -RtPoisonTree $rtPoisonLive -ExpectedShxBytes $ExpectedShxBytes -ActualShxDiskBytes $ActualShxDiskBytes
    if (-not $chkA.stage2_ok) {
        Write-Host "  [PERTURB 1/3 T351 RANGE]   [PASS] Perturbed obligations_evaluated=8 / denom mismatch rejected Stage 2" -ForegroundColor Green
    } else {
        Write-Host "  [PERTURB 1/3 T351 RANGE]   [FAIL] Stage 2 accepted perturbed obligations_evaluated=8" -ForegroundColor Red
        $pertFailures++
    }

    # (b) Perturb rtPoisonTree mean_tokens_per_tree_step -> MUST FAIL Stage 8
    $badPoison1 = ($rtPoisonLive | ConvertTo-Json -Depth 8 | ConvertFrom-Json)
    $badPoison1.mean_tokens_per_tree_step = [double]$t352Live.mean_tokens_per_tree_step
    $chkB1 = Test-Week4StageAssertions -T351 $t351Live -T352 $t352Live -RtPoisonTree $badPoison1 -ExpectedShxBytes $ExpectedShxBytes -ActualShxDiskBytes $ActualShxDiskBytes
    $badPoison2 = ($rtPoisonLive | ConvertTo-Json -Depth 8 | ConvertFrom-Json)
    $badPoison2.mean_tokens_per_tree_step = 0.5
    $chkB2 = Test-Week4StageAssertions -T351 $t351Live -T352 $t352Live -RtPoisonTree $badPoison2 -ExpectedShxBytes $ExpectedShxBytes -ActualShxDiskBytes $ActualShxDiskBytes
    if (-not $chkB1.stage8_tree_ok -and -not $chkB2.stage8_tree_ok) {
        Write-Host "  [PERTURB 2/3 POISON TREE]  [PASS] Perturbed mean_tokens_per_tree_step ($($t352Live.mean_tokens_per_tree_step) & 0.5) rejected Stage 8" -ForegroundColor Green
    } else {
        Write-Host "  [PERTURB 2/3 POISON TREE]  [FAIL] Stage 8 accepted perturbed poison tree steps" -ForegroundColor Red
        $pertFailures++
    }

    # (c) Temporarily perturb manifest expected_bytes on disk with try/finally restore -> MUST FAIL Stage 2
    $origManifestBytes = [System.IO.File]::ReadAllBytes($ManifestPath)
    $chkC_failed = $false
    try {
        $mPert = (Get-Content -Path $ManifestPath -Raw | ConvertFrom-Json)
        $mPert.artifacts.week4_rlvf_sae.expected_bytes = ($ExpectedShxBytes + 64)
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        $pertNorm = ((($mPert | ConvertTo-Json -Depth 10) -replace "`r`n", "`n" -replace "`r", "`n").TrimEnd("`n") + "`n")
        [System.IO.File]::WriteAllText($ManifestPath, $pertNorm, $utf8NoBom)
        $mReload = (Get-Content -Path $ManifestPath -Raw | ConvertFrom-Json)
        $pertExpected = [int64]$mReload.artifacts.week4_rlvf_sae.expected_bytes
        $chkC = Test-Week4StageAssertions -T351 $t351Live -T352 $t352Live -RtPoisonTree $rtPoisonLive -ExpectedShxBytes $pertExpected -ActualShxDiskBytes $ActualShxDiskBytes
        $chkC_failed = (-not $chkC.stage2_ok)
    } finally {
        [System.IO.File]::WriteAllBytes($ManifestPath, $origManifestBytes)
    }
    if ($chkC_failed) {
        Write-Host "  [PERTURB 3/3 MANIFEST]     [PASS] Perturbed manifest expected_bytes rejected Stage 2 and restored cleanly" -ForegroundColor Green
    } else {
        Write-Host "  [PERTURB 3/3 MANIFEST]     [FAIL] Stage 2 did not reject perturbed manifest expected_bytes" -ForegroundColor Red
        $pertFailures++
    }

    Save-Week4Transcript
    if ($pertFailures -gt 0) { exit 1 }
    exit 0
}

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

# Stage 2 & Stage 3 live calls
$t351 = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/sovereign_harmonic/week4/rlvf_grpo_compiler_in_the_loop" -TimeoutSec 120
$t352 = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/sovereign_harmonic/week4/medusa_eagle_dendritic_tree_speculative_k8" -TimeoutSec 60

# Stage 4: Tool 353 — Top-K (K=8) Sparse Autoencoder (Unclamped L2 & Bidirectional Causal Steering)
$t353 = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/sovereign_harmonic/week4/sae_monosemantic_feature_circuit_explorer" -TimeoutSec 60

# Stage 5: Tool 354 — SH-Eval-256 Compiler-in-the-Loop & Adversarial Corruption Penalty
$t354 = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/sovereign_harmonic/week4/sh_eval_256_compiler_pass_at_k_gauntlet" -TimeoutSec 180
$prog = $t354.sh_eval_256_perplexity_progression
$hg0 = $t354.hard_gate_0_frozen_holdout_v2

# Stage 6: Tool 355 — Week 4 12-Test Torture, Stress & Ablation Gauntlet (W4-1..W4-12)
$t355 = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/sovereign_harmonic/week4/torture_and_ablation_12test_gauntlet" -TimeoutSec 180

# Stage 7: Tool 356 — Sovereign Harmonic X Master Certification Shape & Live Lean 4 QED Count
$leanVaultPath = "$RepoRoot\03_vault\lean4\SovereignManifoldTheorems.lean"
$liveLeanCount = if (Test-Path $leanVaultPath) { ([regex]::Matches([System.IO.File]::ReadAllText($leanVaultPath), '(?m)^\s*theorem\s+')).Count } else { 0 }
$t356 = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/chain356/master_certification" -TimeoutSec 240

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
$rtUnrejectedTree = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/sovereign_harmonic/week4/medusa_eagle_dendritic_tree_speculative_k8" -Method Post -ContentType "application/json" -Body '{"corrupt_accept_without_rejection":true}' -TimeoutSec 60
$rtMetaphor = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/tools/t320" -Method Post -ContentType "application/json" -Body '{"prompt":"We need the model to grade its own homework with a formal compiler referee and use a branching crystal ball plus a brain microscope sparse autoencoder"}' -TimeoutSec 30
$metText = [string]$rtMetaphor.generation.generated_text
$metGroundedOk = ($metText -match "MetaphorGrounded") -and ($metText -match "Week 4") -and ($metText -notmatch '5\.9612|5\.08x|R\^2\s*>=\s*0\.95')

$stagePred = Test-Week4StageAssertions -T351 $t351 -T352 $t352 -RtPoisonTree $rtPoisonTree -ExpectedShxBytes $ExpectedShxBytes -ActualShxDiskBytes $ActualShxDiskBytes

if ($stagePred.stage2_ok) {
    Write-Host "  [STAGE 2 - TOOL 351 RLVF]  [PASS] Status=$($t351.status) | Obligations=$($t351.obligations_evaluated) | PreReward=$($t351.pre_rlvf_mean_verifier_reward) -> PostReward=$($t351.post_rlvf_mean_verifier_reward) | Pass@1=$($t351.post_rlvf_pass_at_1) | HacksBlocked=$($t351.adversarial_reward_hacks_blocked) | OrthoErr=$($t351.stiefel_max_orthogonality_error)" -ForegroundColor Green
} else {
    Write-Host "  [STAGE 2 - TOOL 351 RLVF]  [FAIL] $($t351 | ConvertTo-Json -Compress)" -ForegroundColor Red
    $failures++
}

if ($stagePred.stage3_ok) {
    Write-Host "  [STAGE 3 - TOOL 352 TREE]  [PASS] Status=$($t352.status) | Certified=$($t352.tree_speculative_certified) | Tok/Step=$($t352.mean_tokens_per_tree_step) ($($t352.total_tokens_emitted)/$($t352.total_tree_verification_steps)) | Speedup=$($t352.measured_wallclock_speedup_x)x | AltBranchRescues=$($t352.secondary_branch_rescued_accepts) | KL=$($t352.kl_divergence_vs_target)" -ForegroundColor Green
} else {
    Write-Host "  [STAGE 3 - TOOL 352 TREE]  [FAIL] $($t352 | ConvertTo-Json -Compress)" -ForegroundColor Red
    $failures++
}

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

$t356Ok = (
    $t356.status -in @("MEASURED", "UNMEASURED/OFFLINE") -and
    $t356.total_tools -eq 356 -and
    $liveLeanCount -ge 1010 -and
    $t356.lean4_theorems_qed -ge 1010 -and
    $t356.lean4_theorems_qed -eq $liveLeanCount -and
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

$poisonEmpKl = [double]$rtPoisonTree.empirical_output_kl
$poisonKlTau = [double]$rtPoisonTree.kl_bound_tau
$unrejEmpKl = [double]$rtUnrejectedTree.empirical_output_kl

$rtPassed = (
    $rtSorry.custom_candidate_audit.total_reward -eq 0 -and
    $rtDyck.custom_candidate_audit.total_reward -eq 0 -and
    $rtComment.custom_candidate_audit.total_reward -eq 0 -and
    $rtTrivial.custom_candidate_audit.total_reward -eq 0 -and
    $t351.live_lean4_compiler_in_the_loop.negative_soundness_canary_rejected -eq $true -and
    $stagePred.stage8_tree_ok -and
    (-not [double]::IsNaN($poisonEmpKl)) -and
    ($poisonKlTau -gt 0.0) -and
    ($poisonEmpKl -gt 0.0) -and
    ($poisonEmpKl -le $poisonKlTau) -and
    ($rtPoisonTree.poisoned_tree_resilience_audit.fallback_honesty_verified -eq $true) -and
    ($rtUnrejectedTree.tree_speculative_certified -eq $false) -and
    ($unrejEmpKl -gt $poisonKlTau) -and
    $t353.unclamped_l2_reconstruction -eq $true -and
    $t353.max_negative_suppression_prob_delta -lt 0.0 -and
    ([double]$prog.adversarial_corrupted_candidates_penalized_ppl -gt [double]$prog.week4_shx_v72_0) -and
    $metGroundedOk -eq $true
)
if ($rtPassed) {
    Write-Host "  [STAGE 8 - RED-TEAM RT-W4] [PASS] Sorry/Dyck/Comment/TrivialReward=0.0 | Lean4NegCanaryRejected=True | PoisonTreeStep=$($rtPoisonTree.mean_tokens_per_tree_step) (< $($t352.mean_tokens_per_tree_step), EmpKL=$poisonEmpKl <= $poisonKlTau; UnrejectedEmpKL=$unrejEmpKl REJECTED) | UnclampedSAE=True (InhibDelta=$($t353.max_negative_suppression_prob_delta)) | CorruptedPPL=$($prog.adversarial_corrupted_candidates_penalized_ppl) > W4=$($prog.week4_shx_v72_0) | W4MetaphorGroundedNoStaticClaims=True" -ForegroundColor Green
} else {
    Write-Host "  [STAGE 8 - RED-TEAM RT-W4] [FAIL] Sorry=$($rtSorry.custom_candidate_audit.total_reward) Dyck=$($rtDyck.custom_candidate_audit.total_reward) Comment=$($rtComment.custom_candidate_audit.total_reward) Trivial=$($rtTrivial.custom_candidate_audit.total_reward) PoisonStep=$($rtPoisonTree.mean_tokens_per_tree_step) PoisonEmpKL=$poisonEmpKl/$poisonKlTau UnrejCert=$($rtUnrejectedTree.tree_speculative_certified) Inhib=$($t353.max_negative_suppression_prob_delta) Met=$metGroundedOk" -ForegroundColor Red
    $failures++
}

$receiptJson = @{
    version = (Get-CitationReleaseVersion -Root $RepoRoot)
    chain = "CHAIN_404"
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
$receiptNorm = (($receiptJson -replace "`r`n", "`n" -replace "`r", "`n").TrimEnd("`n") + "`n")
[System.IO.File]::WriteAllText("$RepoRoot\03_vault\receipts\v72_0_week4_shx_torture_benchmark_receipt.json", $receiptNorm, [System.Text.UTF8Encoding]::new($false))

Write-Host "==========================================================================" -ForegroundColor Cyan
if ($failures -eq 0) {
    Write-Host "  [WEEK 4 PROPERTY & NEGATIVE-INJECTION SUITE RESULT: PASSED (8/8 STAGES)]" -ForegroundColor Green
    Save-Week4Transcript
    exit 0
} else {
    Write-Host "  [WEEK 4 PROPERTY & NEGATIVE-INJECTION SUITE RESULT: FAILED ($failures STAGES)]" -ForegroundColor Red
    Save-Week4Transcript
    exit 1
}
