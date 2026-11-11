# =============================================================================
# ACT-Omega Sovereign Harmonic XI — Week 2 Real-World Verification Gauntlet
# Version: v72.2.0 (SH-XI-SPARSE-MOE-SFT-RAG | Tools 363-368 | CHAIN 368 | 995 QED)
# Hardware: Lenovo LOQ 15 (12T AVX2 + RTX 3050 + UHD WGSL) + Pixel 10 (USB) + Rooted Pixel 8 (Wireless ADB)
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

Write-Host "=== SOVEREIGN HARMONIC XI WEEK 2 (v72.2.0 | CHAIN 368 | 995 QED) REAL-WORLD SUITE ===" -ForegroundColor Cyan

# 1. Tool 363: Shell 2 CPU+SSD Growable Sparse MoE Bank (16 Active / 256 Slots)
$t363 = Invoke-RestMethod -Uri "$BaseUrl/api/v1/sovereign_harmonic/xi/week2/shell2_sparse_moe" -Method Post -Body '{}' -ContentType 'application/json' -TimeoutSec 90
Assert-Gate "W2-G1 Tool 363 Shell 2 Sparse MoE (16/256 Slots, Step0=0.0, 3-Shell BPB Monotonic)" `
    ($t363.status -eq 'MEASURED' -and $t363.zero_gate_step0_invariance.bit_exact_step0_preserved -eq $true -and $t363.three_shell_matryoshka_progression.strictly_monotonic_improvement -eq $true -and $t363.moe_architecture.experts_utilized -eq 16 -and $t363.moe_architecture.preallocated_directory_slots -eq 256 -and $t363.coexecution_and_ssd_vault.http206_slot1_verified -eq $true) `
    "BPB: $($t363.three_shell_matryoshka_progression.val_bpb_shell0_384d) -> $($t363.three_shell_matryoshka_progression.val_bpb_shell1_768d) -> $($t363.three_shell_matryoshka_progression.val_bpb_shell2_768d_plus_moe), Experts=$($t363.moe_architecture.experts_utilized)/16 (CV=$($t363.moe_architecture.load_balance_cv)), SSD=$($t363.coexecution_and_ssd_vault.ssd_vault_bytes)B"

# 2. Tool 364: Masked-Prompt ChatML Multi-Turn (1..8 Turns) Instruction SFT Trainer
$t364 = Invoke-RestMethod -Uri "$BaseUrl/api/v1/sovereign_harmonic/xi/week2/chatml_masked_sft" -Method Post -Body '{}' -ContentType 'application/json' -TimeoutSec 60
Assert-Gate "W2-G2 Tool 364 Masked-Prompt ChatML SFT (PromptGrad=0.0, 1..8 Turns, 0% Overlap)" `
    ($t364.status -eq 'MEASURED' -and $t364.masked_gradient_verification.zero_prompt_gradient_leakage -eq $true -and $t364.masked_gradient_verification.ce_loss_improved -eq $true -and $t364.dataset_hygiene.rweval500_overlap_shingles -eq 0 -and $t364.dataset_hygiene.max_turns -eq 8) `
    "Dialogues=$($t364.dataset_hygiene.sft_dialogues), PromptGrad=$($t364.masked_gradient_verification.measured_prompt_grad_norm), CE: $($t364.masked_gradient_verification.init_assistant_ce_nats) -> $($t364.masked_gradient_verification.final_assistant_ce_nats)"

# 3. Tool 365: WGSL 384D Workspace RAG + Live Tri-Silicon Telemetry (RTX 3050 + Pixel 10 USB + Wireless Pixel 8)
$t365 = Invoke-RestMethod -Uri "$BaseUrl/api/v1/sovereign_harmonic/xi/week2/igpu_grounded_rag" -Method Post -Body '{"force_refresh":true,"query":"262,144 bijected cachelines Matryoshka 384D 768D"}' -ContentType 'application/json' -TimeoutSec 45
$p10Live = $t365.trisilicon_live_telemetry.edge1_pixel10
$p8Live  = $t365.trisilicon_live_telemetry.edge2_pixel8_rooted
Assert-Gate "W2-G3 Tool 365 WGSL 384D RAG + Live Dual-Pixel & RTX 3050 Telemetry" `
    ($t365.status -eq 'MEASURED' -and $t365.wgsl_compute_shader.valid_workgroup64_vec4x96 -eq $true -and $t365.workspace_rag_384d.indexed_chunks -ge 32 -and $p10Live.status -eq 'MEASURED' -and $p8Live.status -eq 'MEASURED') `
    "Chunks=$($t365.workspace_rag_384d.indexed_chunks), RTX=$($t365.trisilicon_live_telemetry.host_rtx3050.temp_c)C, P10=$($p10Live.serial) ($($p10Live.battery_pct)% / $($p10Live.temp_c)C), P8=$($p8Live.serial) [$($p8Live.transport)] ($($p8Live.battery_pct)% / $($p8Live.temp_c)C, PID=$($p8Live.p8_ksu_apex_daemon_pid))"

# 4. Tool 366: Pushdown JSON Grammar FSM (100/100 Valid JSON) + 5W1H Bus + Abstention
$t366 = Invoke-RestMethod -Uri "$BaseUrl/api/v1/sovereign_harmonic/xi/week2/fsm_json_tool" -Method Post -Body '{"tool":"cluster_telemetry"}' -ContentType 'application/json' -TimeoutSec 45
Assert-Gate "W2-G4 Tool 366 Pushdown JSON FSM (100/100 Valid) & 5W1H Bus Roundtrip" `
    ($t366.status -eq 'MEASURED' -and $t366.json_pushdown_fsm.valid_json_parses -eq 100 -and $t366.json_pushdown_fsm.malformed_json_outputs -eq 0 -and $t366.json_pushdown_fsm.negative_syntax_traps_rejected -eq $true -and $t366.live_tool_call_roundtrip.bus_dispatched -eq $true -and $t366.epistemic_abstention_gate.abstention_calibrated -eq $true) `
    "ValidJSON=$($t366.json_pushdown_fsm.valid_json_parses)/100, Malformed=0, BusNeuron=N$($t366.live_tool_call_roundtrip.bound_neuron_id)"

# 5. Live Conversational Grounding on Connected Dual-Pixel + RTX 3050 Hardware
$telBody = @{ prompt = "What are the live battery percentages, temperatures, and RAM availability on my connected Pixel 10 and Wireless Pixel 8, plus RTX 3050 status right now?" } | ConvertTo-Json
$telResp = Invoke-RestMethod -Uri "$BaseUrl/api/v1/sovereign_harmonic/converse" -Method Post -Body $telBody -ContentType 'application/json' -TimeoutSec 30
Assert-Gate "W2-G5 Live Grounded Tri-Silicon Hardware Chat Query" `
    ($telResp.status -eq 'MEASURED' -and $telResp.trisilicon_grounded -eq $true -and $telResp.output_text -match 'Pixel 10' -and $telResp.output_text -match 'Pixel 8' -and $telResp.output_text -match 'WIRELESS_ADB') `
    "Mode=$($telResp.active_mode), Top2=($($telResp.matryoshka_shells.shell2_top1_expert), $($telResp.matryoshka_shells.shell2_top2_expert))"

# 6. Live Conversational Workspace RAG Grounding
$ragBody = @{ prompt = "How is the 262,144 bijected cacheline manifold partitioned across .npage, .spage, and .e8z?" } | ConvertTo-Json
$ragResp = Invoke-RestMethod -Uri "$BaseUrl/api/v1/sovereign_harmonic/converse" -Method Post -Body $ragBody -ContentType 'application/json' -TimeoutSec 30
Assert-Gate "W2-G6 Workspace 384D RAG Grounded Architecture Query" `
    ($ragResp.status -eq 'MEASURED' -and $ragResp.output_text -match '168,960' -and $ragResp.output_text -match '84,480' -and $ragResp.output_text -match '8,704') `
    "RAGSource=$($ragResp.matryoshka_shells.rag_top_source), Cos384=$($ragResp.matryoshka_shells.rag_top_cosine_384d)"

# 7. OpenAI /v1/chat/completions Multi-Turn `messages` Array Working Memory
$oaiMsgs = '{"model":"sovereign-harmonic-xi-3shell-moe","messages":[{"role":"user","content":"Register project identifier `SIGMA-7788` with baseline rate 30."},{"role":"assistant","content":"Registered identifier `SIGMA-7788` with baseline value `30`."},{"role":"user","content":"Recall the exact identifier registered in Turn 1."}]}'
$oaiResp = Invoke-RestMethod -Uri "$BaseUrl/v1/chat/completions" -Method Post -Body $oaiMsgs -ContentType 'application/json' -TimeoutSec 30
Assert-Gate "W2-G7 OpenAI /v1/chat/completions Multi-Turn Messages Recall" `
    ($oaiResp.choices[0].message.content -match 'SIGMA-7788') `
    "Reply=$($oaiResp.choices[0].message.content)"

# 8. Cross-Turn Standard Rust -> Zero-Bracket L0 Rust Refactor + Live rustc --test
$s1Body = @{ session_id = "ps_w2_refactor_test"; reset_session = $true; prompt = "Write a Standard Rust function `pub fn compute_burst(base: u64) -> u64` that triples base and adds 15." } | ConvertTo-Json
$null = Invoke-RestMethod -Uri "$BaseUrl/api/v1/sovereign_harmonic/converse" -Method Post -Body $s1Body -ContentType 'application/json' -TimeoutSec 30
$s2Body = @{ session_id = "ps_w2_refactor_test"; reset_session = $false; prompt = "Convert that function from the previous turn into Zero-Bracket L0 Rust over `&Vec<u64>`." } | ConvertTo-Json
$s2Resp = Invoke-RestMethod -Uri "$BaseUrl/api/v1/sovereign_harmonic/converse" -Method Post -Body $s2Body -ContentType 'application/json' -TimeoutSec 30
$l0Code = ($s2Resp.output_text -replace '(?s)^```rust\s*', '' -replace '(?s)\s*```$', '').Trim()
$l0Brackets = ([regex]::Matches($l0Code, '[\[\]]')).Count
$tmpDir2 = Join-Path $env:TEMP "sh_xi_ps_w2_l0_gate"
New-Item -ItemType Directory -Force -Path $tmpDir2 | Out-Null
$l0Rs = Join-Path $tmpDir2 "l0_burst_check.rs"
$l0Exe = Join-Path $tmpDir2 "l0_burst_check.exe"
$l0Harness = @"
$l0Code

#[test]
fn test_cross_turn_l0_burst() {
    let mut vals: Vec<u64> = Vec::new();
    vals.push(4);
    vals.push(10);
    assert_eq!(compute_burst_l0(&vals), (4 * 3 + 15) + (10 * 3 + 15));
}
"@
[IO.File]::WriteAllText($l0Rs, $l0Harness)
$rustcExe = if (Test-Path "$env:USERPROFILE\.cargo\bin\rustc.exe") { "$env:USERPROFILE\.cargo\bin\rustc.exe" } else { "rustc" }
$prevEap = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
& $rustcExe --edition=2021 --test $l0Rs -o $l0Exe 2>&1 | Out-Null
$l0CompExit = $LASTEXITCODE
$ErrorActionPreference = $prevEap
$l0RunExit = 1
if ($l0CompExit -eq 0 -and (Test-Path $l0Exe)) {
    & $l0Exe | Out-Null
    $l0RunExit = $LASTEXITCODE
}
Assert-Gate "W2-G8 Cross-Turn Std Rust -> Zero-Bracket L0 Refactor + rustc --test" `
    ($l0Brackets -eq 0 -and $l0CompExit -eq 0 -and $l0RunExit -eq 0) `
    "Brackets=$l0Brackets, rustcExit=$l0CompExit, testExit=$l0RunExit"

# 9. Live <|tool_call|> -> <|tool_result|> Roundtrip Mode
$tcBody = @{ mode = "tool_call"; prompt = "Evaluate 27 * 14 + 9 via math_eval tool." } | ConvertTo-Json
$tcResp = Invoke-RestMethod -Uri "$BaseUrl/api/v1/sovereign_harmonic/converse" -Method Post -Body $tcBody -ContentType 'application/json' -TimeoutSec 30
Assert-Gate "W2-G9 Live <|tool_call|> -> <|tool_result|> Bus Execution" `
    ($tcResp.output_text -match '<\|tool_call\|>' -and $tcResp.output_text -match '<\|tool_result\|>' -and $tcResp.output_text -match '387') `
    "Output=$($tcResp.output_text)"

# 10. Tool 367: Programmatic IFEval-Lite-64 + 8-Turn Stateful Gauntlet
$t367 = Invoke-RestMethod -Uri "$BaseUrl/api/v1/sovereign_harmonic/xi/week2/ifeval_lite_64" -Method Post -Body '{}' -ContentType 'application/json' -TimeoutSec 90
Assert-Gate "W2-G10 Tool 367 IFEval-Lite-64 & 8-Turn Stateful Gauntlet" `
    ($t367.status -eq 'MEASURED' -and $t367.ifeval_lite_64.tasks_passed -ge 58 -and $t367.ifeval_lite_64.rweval500_overlap_shingles -eq 0 -and $t367.stateful_8turn_gauntlet.turns_passed -eq 8) `
    "IFEval=$($t367.ifeval_lite_64.tasks_passed)/64 ($($t367.ifeval_lite_64.pass_rate_pct)%), MultiTurn=$($t367.stateful_8turn_gauntlet.turns_passed)/8, Overlap=0"

# 11. Multi-Turn OpenAI SSE Stream (stream: true)
$sseBody2 = '{"model":"sovereign-harmonic-xi-3shell-moe","stream":true,"messages":[{"role":"user","content":"Give 2 bullet points on why cacheline alignment matters."}]}'
$sseResp2 = Invoke-WebRequest -Uri "$BaseUrl/v1/chat/completions" -Method Post -Body $sseBody2 -ContentType 'application/json' -UseBasicParsing -TimeoutSec 30
Assert-Gate "W2-G11 OpenAI 3-Shell MoE SSE Stream (stream: true)" `
    ($sseResp2.StatusCode -eq 200 -and $sseResp2.Content -match 'sovereign-harmonic-xi-3shell-moe' -and $sseResp2.Content -match '\[DONE\]') `
    "SSEBytes=$($sseResp2.Content.Length)"

# 12. Tool 368: CHAIN 368 Master Certification & 995/995 Lean 4 QED
$t368 = Invoke-RestMethod -Uri "$BaseUrl/api/v1/chain368/master_certification" -Method Post -Body '{}' -ContentType 'application/json' -TimeoutSec 90
Assert-Gate "W2-G12 Tool 368 CHAIN 368 Master Certification (995/995 QED)" `
    ($t368.status -eq 'MEASURED' -and $t368.all_week2_gates_passed -eq $true -and $t368.gate_6_lean4_formal_proofs.theorem_count -ge 995 -and $t368.gate_6_lean4_formal_proofs.vault_l0_sha256_synced -eq $true) `
    "Proof=$($t368.proof)"

Write-Host "`n=== WEEK 2 SUMMARY: $PassCount PASSED, $FailCount FAILED ===" -ForegroundColor $(if ($FailCount -eq 0) { 'Green' } else { 'Red' })
if ($FailCount -gt 0) { exit 1 }
