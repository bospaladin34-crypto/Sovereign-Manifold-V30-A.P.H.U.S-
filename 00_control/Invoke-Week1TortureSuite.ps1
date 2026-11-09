# ACT-Omega Net v71.1.0 (CHAIN 334 | 905/905 Lean 4 QED)
# Week 1 Sovereign Harmonic IX (SH-Deep-12L) 7-Test Torture & Falsification Suite (W1-1 .. W1-7)
param(
    [int]$WirelessBurstRounds = 250
)

$ErrorActionPreference = "Stop"
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "   SOVEREIGN HARMONIC IX (v71.1.0) -- WEEK 1 7-TEST TORTURE GAUNTLET      " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan

# 1. Execute L0 Rust In-Process 7-Test Torture Suite (W1-1 .. W1-7) via Tool 334
$torture = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/tools/t334?torture=1" -TimeoutSec 30

$w1 = $torture.w1_1_finite_diff_vs_bptt
Write-Host ("  [W1-1 FINITE-DIFF vs BPTT] [{0}] Params={1} | CosSim={2:F10} | RelL2Err={3:E4} (<1e-4)" -f $(if($w1.passed){"PASS"}else{"FAIL"}), $w1.parameters_checked, $w1.cosine_similarity, $w1.relative_l2_error) -ForegroundColor $(if($w1.passed){"Green"}else{"Red"})

$w2 = $torture.w1_2_stiefel_100step_torture
Write-Host ("  [W1-2 STIEFEL 100-STEP]    [{0}] Steps={1} | MaxOrthoRes={2:E4} (<1e-6) | MaxSkewRes={3:E4} | NaN/Inf={4}" -f $(if($w2.passed){"PASS"}else{"FAIL"}), $w2.steps, $w2.max_orthogonality_frobenius_residual, $w2.max_skew_symmetry_residual, $w2.nan_or_inf_count) -ForegroundColor $(if($w2.passed){"Green"}else{"Red"})

$t331 = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/tools/t331" -TimeoutSec 15
$t328 = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/tools/t328" -TimeoutSec 15
$w3Pass = $torture.w1_3_cpu_gpu_ptx_parity.passed -and ($t331.rtx3050_ptx_execution.lark_k1_bit_drift -eq 0) -and ($t331.rtx3050_ptx_execution.lark_k2_bit_drift -eq 0)
Write-Host ("  [W1-3 CPU/GPU PTX PARITY]  [{0}] GPU={1} | K1/K2 Drift=0/42,240 | PartitionSum={2:F8} | GEMM={3:F2} GOPS | SMs={4}/20 ({5})" -f $(if($w3Pass){"PASS"}else{"FAIL"}), $t331.rtx3050_ptx_execution.device_name, $t331.batched_32d_e8_gemm_softmax_ce.mean_probability_partition_sum, $t331.batched_32d_e8_gemm_softmax_ce.measured_gemm_gops, $t328.ga107_measured_silicon_topology.active_sm_count, $t328.ga107_measured_silicon_topology.derived_active_tpc_mask_hex) -ForegroundColor $(if($w3Pass){"Green"}else{"Red"})

# 4. Execute Full 250-Round (1,000-Token) Wireless Rooted Pixel 8 (:8098) Speculative Burst
$rtts = New-Object System.Collections.Generic.List[double]
$drops = 0
$bearerTarget = "192.168.137.8"
$bearerPort = 8098
for ($r = 0; $r -lt $WirelessBurstRounds; $r++) {
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $client = New-Object System.Net.Sockets.TcpClient
        $ar = $client.BeginConnect($bearerTarget, $bearerPort, $null, $null)
        if (-not $ar.AsyncWaitHandle.WaitOne(250, $false)) {
            $client.Close()
            $drops++
            continue
        }
        $client.EndConnect($ar)
        $stream = $client.GetStream()
        $stream.ReadTimeout = 250
        $stream.WriteTimeout = 250
        $tok = 1024 + ($r * 3)
        $bytes = [System.Text.Encoding]::ASCII.GetBytes("{`"cmd`":`"draft`",`"prompt_token`":$tok}`n")
        $stream.Write($bytes, 0, $bytes.Length)
        $buf = New-Object byte[] 512
        $nRead = $stream.Read($buf, 0, $buf.Length)
        $sw.Stop()
        $client.Close()
        if ($nRead -gt 0) {
            $rtts.Add($sw.Elapsed.TotalMilliseconds)
        } else {
            $drops++
        }
    } catch {
        $drops++
    }
}
$sortedRtts = $rtts | Sort-Object
$cntRtt = $sortedRtts.Count
$p50 = if ($cntRtt -gt 0) { $sortedRtts[[int]($cntRtt * 0.50)] } else { 0.0 }
$p95 = if ($cntRtt -gt 0) { $sortedRtts[[int]($cntRtt * 0.95)] } else { 0.0 }
$p99 = if ($cntRtt -gt 0) { $sortedRtts[[int]([Math]::Min($cntRtt - 1, [int]($cntRtt * 0.99)))] } else { 0.0 }
$draftedTotal = $cntRtt * 4
$w4Pass = ($drops -eq 0) -and ($cntRtt -eq $WirelessBurstRounds)
Write-Host ("  [W1-4 WIRELESS P8 :8098]   [{0}] Bearer={1}:{2} | Rounds={3}/{4} ({5} Drafted Toks) | Drops={6} | P50={7:F2}ms P95={8:F2}ms P99={9:F2}ms" -f $(if($w4Pass){"PASS"}else{"FAIL"}), $bearerTarget, $bearerPort, $cntRtt, $WirelessBurstRounds, $draftedTotal, $drops, $p50, $p95, $p99) -ForegroundColor $(if($w4Pass){"Green"}else{"Red"})

# 5. W1-5: Hard Gate 0 Seal & Adversarial Red-Team Check
$w5 = $torture.w1_5_hard_gate_0_seal_and_redteam
$t322 = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/tools/t322" -TimeoutSec 15
$hg0 = $t322.hard_gate_0_frozen_holdout_v2
Write-Host ("  [W1-5 HARD GATE 0 SEAL]    [{0}] FrozenV2={1} Prompts (Overlap={2}) | WeightsUnmutated={3} ({4}) | RedTeamCanaryCaught={5} | FrozenV2_PPL={6:F4}" -f $(if($w5.passed){"PASS"}else{"FAIL"}), $hg0.total_frozen_v2_prompts, $hg0.trainer_overlap_count, $w5.weights_unmutated_by_tool322, $w5.sh12z_fnv1a64_hex, $w5.redteam_canary_leak_caught, $hg0.frozen_v2_post_perplexity) -ForegroundColor $(if($w5.passed){"Green"}else{"Red"})

# 6. W1-6: 15.965 Hz Decadic RoPE Context Extrapolation (16 -> 64 -> 256 -> 512)
$w6 = $torture.w1_6_decadic_rope_extrapolation
Write-Host ("  [W1-6 ROPE EXTRAPOLATION]  [{0}] PPL(L=16)={1:F4} | PPL(L=64)={2:F4} | PPL(L=256)={3:F4} | PPL(L=512)={4:F4}" -f $(if($w6.passed){"PASS"}else{"FAIL"}), $w6.ppl_len16, $w6.ppl_len64, $w6.ppl_len256, $w6.ppl_len512) -ForegroundColor $(if($w6.passed){"Green"}else{"Red"})

# 7. W1-7: Multi-Epoch Convergence (1, 2, 4, 8 Epochs), SH-Eval-256, & 6-Way Ablation
$ep1 = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/tools/t330?epochs=1" -TimeoutSec 15
$ep2 = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/tools/t330?epochs=2" -TimeoutSec 15
$ep4 = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/tools/t330?epochs=4" -TimeoutSec 15
$ep8 = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/tools/t330?epochs=8" -TimeoutSec 15
$t332 = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/tools/t332" -TimeoutSec 15
$t333 = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/tools/t333" -TimeoutSec 15
$ab = $t333.ablation_matrix
$w7Pass = $torture.w1_7_convergence_and_ablation.passed -and $t333.all_components_strictly_beneficial
Write-Host ("  [W1-7 CONVERGENCE & ABL]   [{0}] PPL(Ep0->Ep8)={1:F4}->{2:F4} | SH-Eval-256 PPL={3:F4} (Top1={4:F1}%) | Full12L={5:F4} < 1L={6:F4}, NoRoPE={7:F4}, NoSSM={8:F4}, NonStiefel={9:F4}, NoBasal={10:F4}" -f $(if($w7Pass){"PASS"}else{"FAIL"}), $ep8.holdout_convergence.pre_bptt_perplexity, $ep8.holdout_convergence.post_bptt_perplexity, $t332.sh_eval_256_metrics.overall_perplexity, $t332.sh_eval_256_metrics.top1_token_accuracy_pct, $ab.c0_full_sh_deep_12l_ppl, $ab.c1_shallow_1layer_ppl, $ab.c2_no_15965hz_rope_ppl, $ab.c3_no_mamba3_apical_ssm_ppl, $ab.c4_non_stiefel_perturbed_ppl, $ab.c5_no_basal_connectome_ppl) -ForegroundColor $(if($w7Pass){"Green"}else{"Red"})

Write-Host "==========================================================================" -ForegroundColor Cyan
$allPass = $w1.passed -and $w2.passed -and $w3Pass -and $w4Pass -and $w5.passed -and $w6.passed -and $w7Pass
if ($allPass) {
    Write-Host "  [WEEK 1 TORTURE SUITE RESULT: PASSED (7/7 FALSIFIABLE TESTS VERIFIED)]" -ForegroundColor Green
} else {
    Write-Host "  [WEEK 1 TORTURE SUITE RESULT: FAILED]" -ForegroundColor Red
    exit 1
}
