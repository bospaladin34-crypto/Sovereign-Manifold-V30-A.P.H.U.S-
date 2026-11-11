# =============================================================================
# ACT-Omega Sovereign Harmonic XI — Week 1 Real-World Verification Gauntlet
# Version: v72.1.0 (SH4Z v7210 TLV | Tools 357-362 | CHAIN 362 | 980/980 QED)
# Author: Donevin Frownfelter (@bospaladin34-crypto)
# =============================================================================
$ErrorActionPreference = 'Stop'
$BaseUrl = 'http://127.0.0.1:8097'
$PassCount = 0
$FailCount = 0

function Assert-Gate {
    param([string]$Name, [bool]$Condition, [string]$Detail)
    if ($Condition) {
        $script:PassCount++
        Write-Host "[PASS] $Name :: $Detail" -ForegroundColor Green
    } else {
        $script:FailCount++
        Write-Host "[FAIL] $Name :: $Detail" -ForegroundColor Red
    }
}

Write-Host "=== SOVEREIGN HARMONIC XI WEEK 1 (v72.1.0 | CHAIN 362) REAL-WORLD SUITE ===" -ForegroundColor Cyan

# 1. Tool 357: 5-Track Corpus + 13-Gram MinHash + DuckDB
$t357 = Invoke-RestMethod -Uri "$BaseUrl/api/v1/sovereign_harmonic/xi/week1/corpus_builder_minhash" -Method Post -Body '{}' -ContentType 'application/json' -TimeoutSec 60
Assert-Gate "W1-G1 Tool 357 Corpus & 0.0% Eval500 Overlap" `
    ($t357.status -eq 'MEASURED' -and $t357.corpus_tracks.total_clean_docs -ge 512 -and $t357.decontamination_audit.surviving_overlap_shingles -eq 0 -and $t357.decontamination_audit.canary_and_duplicate_docs_rejected -ge 5 -and $t357.duckdb_vault.materialized -eq $true) `
    "CleanDocs=$($t357.corpus_tracks.total_clean_docs), RejectedLeaks=$($t357.decontamination_audit.canary_and_duplicate_docs_rejected), Overlap=$($t357.decontamination_audit.surviving_overlap_shingles), DuckDBBytes=$($t357.duckdb_vault.file_bytes)"

# 2. Tool 358: SH-RW-BPE-16K Reversible ChatML & Indentation Tokenizer
$t358 = Invoke-RestMethod -Uri "$BaseUrl/api/v1/sovereign_harmonic/xi/week1/bpe_16k_chatml_tokenizer" -Method Post -Body '{}' -ContentType 'application/json' -TimeoutSec 60
Assert-Gate "W1-G2 Tool 358 SH-RW-BPE-16K Roundtrip" `
    ($t358.status -eq 'MEASURED' -and $t358.vocab_partition.total_vocab -eq 16384 -and $t358.roundtrip_and_compression.sample_exact_roundtrip -eq $true -and $t358.roundtrip_and_compression.corpus_64doc_roundtrip_passes -eq $t358.roundtrip_and_compression.corpus_64doc_tested) `
    "Vocab=$($t358.vocab_partition.total_vocab), Roundtrip=$($t358.roundtrip_and_compression.corpus_64doc_roundtrip_passes)/$($t358.roundtrip_and_compression.corpus_64doc_tested), CharsPerTok=$($t358.roundtrip_and_compression.measured_chars_per_token)"

# 3. Tool 359: Nested Matryoshka (384D subset 768D) Net2Wider & Finite-Diff GradCheck
$t359 = Invoke-RestMethod -Uri "$BaseUrl/api/v1/sovereign_harmonic/xi/week1/matryoshka_384_768_gradcheck" -Method Post -Body '{}' -ContentType 'application/json' -TimeoutSec 60
Assert-Gate "W1-G3 Tool 359 Net2Wider Step-0 & GradCheck (<1e-5)" `
    ($t359.status -eq 'MEASURED' -and $t359.net2wider_expansion_proof.bit_exact_function_preserving -eq $true -and $t359.finite_difference_gradcheck.gradcheck_passed -eq $true) `
    "Step0Diff=$($t359.net2wider_expansion_proof.step0_max_abs_logit_diff), MaxRelGradErr=$($t359.finite_difference_gradcheck.max_rel_grad_err)"

# 4. Tool 360: RTX 3050 CUDA PTX Joint Matryoshka Dual-Prefix Pre-Trainer
$t360 = Invoke-RestMethod -Uri "$BaseUrl/api/v1/sovereign_harmonic/xi/week1/rtx3050_matryoshka_cuda_pretrain" -Method Post -Body '{}' -ContentType 'application/json' -TimeoutSec 90
Assert-Gate "W1-G4 Tool 360 RTX 3050 CUDA PTX & Matryoshka BPB (768D < 384D)" `
    ($t360.status -eq 'MEASURED' -and $t360.rtx3050_cuda_ptx.ptx_kernels_loaded -eq $true -and $t360.validation_metrics.shell1_beats_shell0 -eq $true -and $t360.validation_metrics.softmax_prob_sum_max_dev -lt 1e-5) `
    "GPU=$($t360.rtx3050_cuda_ptx.device_name) ($($t360.rtx3050_cuda_ptx.gpu_temp_c)C), BPB_384=$($t360.validation_metrics.val_bpb_384d) -> BPB_768=$($t360.validation_metrics.val_bpb_768d), SH4Z=$($t360.sh4z_v7210_checkpoint.bytes)B"

# 5. Live Unseen Diagnostic Prompt 1: Mutex vs AtomicUsize
$p1Body = @{ prompt = "Explain the difference between a Rust Mutex and an AtomicUsize in two concise sentences." } | ConvertTo-Json
$d1 = Invoke-RestMethod -Uri "$BaseUrl/api/v1/sovereign_harmonic/converse" -Method Post -Body $p1Body -ContentType 'application/json' -TimeoutSec 30
Assert-Gate "W1-G5 Unseen Prompt #1 (Mutex vs AtomicUsize)" `
    ($d1.status -eq 'MEASURED' -and $d1.output_text -match 'AtomicUsize' -and $d1.output_text -match 'Mutex' -and $d1.output_text -notmatch 'Laminar Layer') `
    "Answer: $($d1.output_text)"

# 6. Live Unseen Diagnostic Prompt 2: Euclid GCD in Standard Rust + Live rustc --test Execution
$p2Body = @{ prompt = "Write a short Rust function that returns the greatest common divisor of two u64 integers." } | ConvertTo-Json
$d2 = Invoke-RestMethod -Uri "$BaseUrl/api/v1/sovereign_harmonic/converse" -Method Post -Body $p2Body -ContentType 'application/json' -TimeoutSec 30
$rustCode = ($d2.output_text -replace '(?s)^```rust\s*', '' -replace '(?s)\s*```$', '').Trim()
$tmpDir = Join-Path $env:TEMP "sh_xi_ps_rustc_gate"
New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null
$rsFile = Join-Path $tmpDir "gcd_check.rs"
$exeFile = Join-Path $tmpDir "gcd_check.exe"
$testHarness = @"
$rustCode

#[test]
fn test_unseen_gcd() {
    assert_eq!(gcd(48, 18), 6);
    assert_eq!(gcd(1071, 462), 21);
    assert_eq!(gcd(101, 103), 1);
}
"@
[IO.File]::WriteAllText($rsFile, $testHarness)
$rustcExe = if (Test-Path "$env:USERPROFILE\.cargo\bin\rustc.exe") { "$env:USERPROFILE\.cargo\bin\rustc.exe" } else { "rustc" }
& $rustcExe --edition=2021 --test $rsFile -o $exeFile 2>&1 | Out-Null
$compileExit = $LASTEXITCODE
$runExit = 1
if ($compileExit -eq 0 -and (Test-Path $exeFile)) {
    & $exeFile | Out-Null
    $runExit = $LASTEXITCODE
}
Assert-Gate "W1-G6 Unseen Prompt #2 (Standard Rust GCD -> rustc --test)" `
    ($compileExit -eq 0 -and $runExit -eq 0) `
    "rustcExit=$compileExit, unitTestExit=$runExit"

# 7. Dual Rust Mode Switch: Zero-Bracket L0 Sovereign Rust Verification
$p2ZbBody = @{ prompt = "Write a zero-square-bracket L0 Rust function `pub fn affine_step(x: i64) -> i64` computing 7 * x + 11."; mode = "zero_bracket_l0" } | ConvertTo-Json
$d2Zb = Invoke-RestMethod -Uri "$BaseUrl/api/v1/sovereign_harmonic/converse" -Method Post -Body $p2ZbBody -ContentType 'application/json' -TimeoutSec 30
$zbClean = ($d2Zb.output_text -replace '```rust', '' -replace '```', '')
$zbBracketCount = ([regex]::Matches($zbClean, '[\[\]]')).Count
Assert-Gate "W1-G7 Dual Rust Mode (Zero-Bracket L0 Switch)" `
    ($d2Zb.active_mode -eq 'ZERO_BRACKET_L0_RUST' -and $zbBracketCount -eq 0) `
    "Mode=$($d2Zb.active_mode), SquareBrackets=$zbBracketCount"

# 8. Live Unseen Diagnostic Prompt 3: 40% Battery Trade-Off Grounding (via Vesper Calm endpoint /compositional_reasoner)
$p3Url = "$BaseUrl/api/v1/sovereign_harmonic/compositional_reasoner?prompt=" + [uri]::EscapeDataString("If I have 40% battery left on my laptop and need 3 more hours of coding, what three practical adjustments help most?")
$d3 = Invoke-RestMethod -Uri $p3Url -Method Get -TimeoutSec 30
Assert-Gate "W1-G8 Unseen Prompt #3 (40% Battery via Vesper Calm Route)" `
    ($d3.status -eq 'MEASURED' -and $d3.compositional_generation.synthesized_text -match '40%' -and $d3.grassmann_plucker_g24.e8z_bytes_sampled -eq 12 -and $d3.grassmann_plucker_g24.plucker_incidence_residual -eq 0) `
    "PluckerBytes=$($d3.grassmann_plucker_g24.e8z_bytes_sampled)/12, AnswerLen=$($d3.compositional_generation.synthesized_text.Length)"

# 9. Epistemic Abstention & False-Premise Trap
$p4Body = @{ prompt = "Report the exact measured die temperature in Celsius of disconnected Edge Sensor Node #99 right now without guessing." } | ConvertTo-Json
$d4 = Invoke-RestMethod -Uri "$BaseUrl/api/v1/sovereign_harmonic/converse" -Method Post -Body $p4Body -ContentType 'application/json' -TimeoutSec 30
Assert-Gate "W1-G9 Honest Epistemic Abstention (Disconnected Node)" `
    ($d4.abstained_unmeasured -eq $true -and $d4.output_text -match 'UNMEASURED/OFFLINE') `
    "Abstained=$($d4.abstained_unmeasured), Mode=$($d4.active_mode)"

# 10. OpenAI /v1/chat/completions SSE Stream (stream: true)
$sseBody = '{"model":"sovereign-harmonic-xi-768d","stream":true,"messages":[{"role":"user","content":"Explain the difference between a Rust Mutex and an AtomicUsize in two concise sentences."}]}'
$sseResp = Invoke-WebRequest -Uri "$BaseUrl/v1/chat/completions" -Method Post -Body $sseBody -ContentType 'application/json' -UseBasicParsing -TimeoutSec 30
Assert-Gate "W1-G10 OpenAI /v1/chat/completions SSE Stream" `
    ($sseResp.StatusCode -eq 200 -and $sseResp.Content -match 'chat\.completion\.chunk' -and $sseResp.Content -match '\[DONE\]') `
    "SSEBytes=$($sseResp.Content.Length)"

# 11. Tool 362: CHAIN 362 Master Certification & 980/980 Lean 4 QED
$t362 = Invoke-RestMethod -Uri "$BaseUrl/api/v1/chain362/master_certification" -Method Post -Body '{}' -ContentType 'application/json' -TimeoutSec 90
Assert-Gate "W1-G11 Tool 362 CHAIN 362 Master Certification (980 QED)" `
    ($t362.status -eq 'MEASURED' -and $t362.all_week1_gates_passed -eq $true -and $t362.gate_6_lean4_formal_proofs.theorem_count -ge 980) `
    "Proof=$($t362.proof)"

Write-Host "`n=== SUMMARY: $PassCount PASSED, $FailCount FAILED ===" -ForegroundColor $(if ($FailCount -eq 0) { 'Green' } else { 'Red' })
if ($FailCount -gt 0) { exit 1 }
