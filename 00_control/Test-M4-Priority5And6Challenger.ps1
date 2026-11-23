# 00_control\Test-M4-Priority5And6Challenger.ps1
# Milestone M4 (Priority 5 & 6) Adversarial Challenger Verification Script
# Proves positive + negative + live weight perturbation + fail-closed invariants against :8097
# Features:
#   - Feature M5:  5-Track Decontaminated Corpus Builder & 13-gram MinHash (Tool 357)
#   - Feature M7:  Multi-Turn SFT JSONL & Zero-Prompt-Gradient Loss Masking (Tool 364)
#   - Feature M8:  Autoregressive Inference, Pushdown JSON FSM, Perturbation & 503 Fail-Closed (/v1/chat/completions, /converse, Tool 361)
#   - Feature M15: Long Context 4,096 Uniform 448B Propagation, Input Perturbation & Missing-Weight Fail-Closed (Tool 342)
#   - Feature M18: Pure Signed 384D Cosine RAG vs Independent Lexical Baseline + Read-Only Zero-Mutation (Tool 365)

$ErrorActionPreference = "Stop"

$baseUrl = "http://127.0.0.1:8097"
$baseDir = "c:\sovereign_manifold_v31"
$cffVer = "UNMEASURED"
$cffPath = Join-Path $baseDir "CITATION.cff"
if (Test-Path $cffPath) {
    $cffRaw = [System.IO.File]::ReadAllText($cffPath)
    if ($cffRaw -match '(?m)^version:\s*"?([^"\r\n]+)"?\s*$') {
        $vTok = $Matches[1].Trim()
        $cffVer = if ($vTok.StartsWith("v")) { $vTok } else { "v$vTok" }
    }
}

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "  ACT-Omega Net $cffVer -- Milestone M4 Priority 5 & 6 Challenger" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# Load external operator key
$headers = @{}
$keyFile = "C:\Users\Nbell\.act_omega_operator_vault_key"
if (Test-Path $keyFile) {
    $opKey = (Get-Content -Path $keyFile -Raw).Trim()
    if ($opKey.Length -ge 24) {
        $headers["X-Sovereign-Operator-Key"] = $opKey
    }
}

$results = [ordered]@{}
$allPass = $true

function Invoke-ToolPost($endpoint, $bodyObj, $timeoutSec = 60) {
    $url = "$baseUrl$endpoint"
    $jsonBody = $bodyObj | ConvertTo-Json -Compress -Depth 6
    return Invoke-RestMethod -Uri $url -Method Post -Body $jsonBody -ContentType "application/json" -Headers $headers -TimeoutSec $timeoutSec
}

function Invoke-RawHttpPost($endpoint, $bodyObj, $timeoutSec = 60) {
    $url = "$baseUrl$endpoint"
    $jsonBody = $bodyObj | ConvertTo-Json -Compress -Depth 6
    $req = [System.Net.HttpWebRequest]::Create($url)
    $req.Method = "POST"
    $req.ContentType = "application/json"
    $req.Timeout = $timeoutSec * 1000
    foreach ($hk in $headers.Keys) {
        $req.Headers.Add($hk, $headers[$hk])
    }
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($jsonBody)
    $req.ContentLength = $bytes.Length
    $reqStream = $req.GetRequestStream()
    $reqStream.Write($bytes, 0, $bytes.Length)
    $reqStream.Close()
    try {
        $resp = [System.Net.HttpWebResponse]$req.GetResponse()
        $sr = New-Object System.IO.StreamReader($resp.GetResponseStream())
        $txt = $sr.ReadToEnd()
        $sr.Close()
        $code = [int]$resp.StatusCode
        $resp.Close()
        return @{ StatusCode = $code; Body = $txt }
    } catch [System.Net.WebException] {
        $resp = [System.Net.HttpWebResponse]$_.Exception.Response
        if ($null -eq $resp) {
            return @{ StatusCode = 0; Body = "$_" }
        }
        $sr = New-Object System.IO.StreamReader($resp.GetResponseStream())
        $txt = $sr.ReadToEnd()
        $sr.Close()
        $code = [int]$resp.StatusCode
        $resp.Close()
        return @{ StatusCode = $code; Body = $txt }
    }
}

function Get-BytesSha256([byte[]]$bytes) {
    $hasher = [System.Security.Cryptography.SHA256]::Create()
    try {
        return ([System.BitConverter]::ToString($hasher.ComputeHash($bytes))).Replace("-", "").ToLower()
    } finally {
        $hasher.Dispose()
    }
}

function Flip-StiefelP0SignBits([byte[]]$srcBytes) {
    $mut = New-Object byte[] $srcBytes.Length
    [System.Array]::Copy($srcBytes, $mut, $srcBytes.Length)
    for ($r = 1; $r -lt 48; $r += 2) {
        for ($d = 0; $d -lt 384; $d++) {
            $off = 128 + (($r * 384 + $d) * 4) + 3
            if ($off -lt $mut.Length) {
                $mut[$off] = $mut[$off] -bxor 0x80
            }
        }
    }
    return $mut
}

# -------------------------------------------------------------
# Case 1: Feature M5 -- 5-Track Decontaminated Corpus (Tool 357)
# -------------------------------------------------------------
Write-Host "`n--- Case 1: Feature M5 -- Decontaminated Corpus & MinHash Audit (Tool 357) ---" -ForegroundColor Yellow

try {
    $resp1A = Invoke-ToolPost "/api/v1/tools/t357" @{ action = "audit" } 60
    $canariesCaught = $resp1A.synthetic_contamination_canary_fixture.canaries_caught
    $canariesTested = $resp1A.synthetic_contamination_canary_fixture.canaries_tested
    $canaryExcluded = $resp1A.synthetic_contamination_canary_fixture.included_in_training_corpus
    $cleanDocs = $resp1A.corpus_tracks.total_clean_docs
    $maxJaccard = $resp1A.max_pairwise_5gram_jaccard
    $overlapShingles = $resp1A.decontamination_audit.surviving_overlap_shingles

    $manifestPath = "$baseDir\03_vault\corpus\corpus_manifest_v1.json"
    $manifestOnDisk = Test-Path $manifestPath
    $mDisk = Get-Content -Path $manifestPath -Raw | ConvertFrom-Json

    if ($resp1A.status -eq "MEASURED" -and `
        $canariesCaught -eq 5 -and $canariesTested -eq 5 -and $canaryExcluded -eq $false -and `
        $cleanDocs -ge 512 -and $maxJaccard -le 0.50 -and $overlapShingles -eq 0 -and `
        $manifestOnDisk -and `
        $mDisk.source_files_read -gt 0 -and `
        $mDisk.raw_doc_count -ge $mDisk.deduplicated_doc_count -and `
        $mDisk.deduplicated_doc_count -eq $mDisk.total_clean_docs -and `
        $mDisk.max_pairwise_5gram_jaccard -le 0.50 -and `
        (-not [string]::IsNullOrWhiteSpace($mDisk.corpus_sha256))) {
        Write-Host "  [PASS] Case 1A: Corpus manifest & decontamination verified (files=$($mDisk.source_files_read), raw=$($mDisk.raw_doc_count), dedup=$($mDisk.deduplicated_doc_count), jaccard=$maxJaccard, overlap=$overlapShingles)" -ForegroundColor Green
        $results["Case1A_CorpusDecontamination"] = "PASS"
    } else {
        Write-Host "  [FAIL] Case 1A: Corpus decontamination or manifest fields incomplete!" -ForegroundColor Red
        $results["Case1A_CorpusDecontamination"] = "FAIL"
        $allPass = $false
    }
} catch {
    Write-Host "  [FAIL] Case 1A Exception: $_" -ForegroundColor Red
    $results["Case1A_CorpusDecontamination"] = "FAIL ($($_))"
    $allPass = $false
}

try {
    $manifestContent = Get-Content -Path "$baseDir\03_vault\corpus\corpus_manifest_v1.json" -Raw | ConvertFrom-Json
    if ($manifestContent.canaries_caught -eq 5 -and $manifestContent.surviving_overlap_shingles -eq 0 -and $manifestContent.total_clean_docs -ge 512) {
        Write-Host "  [PASS] Case 1B: Canary trap excluded contaminated synthetic leaks (canaries=$($manifestContent.canaries_caught)/5)" -ForegroundColor Green
        $results["Case1B_CanaryTrapExclusion"] = "PASS"
    } else {
        Write-Host "  [FAIL] Case 1B: Canary trap exclusion mismatch!" -ForegroundColor Red
        $results["Case1B_CanaryTrapExclusion"] = "FAIL"
        $allPass = $false
    }
} catch {
    Write-Host "  [FAIL] Case 1B Exception: $_" -ForegroundColor Red
    $results["Case1B_CanaryTrapExclusion"] = "FAIL ($($_))"
    $allPass = $false
}

# -------------------------------------------------------------
# Case 2: Feature M7 -- Multi-Turn SFT & Zero-Prompt-Gradient (Tool 364)
# -------------------------------------------------------------
Write-Host "`n--- Case 2: Feature M7 -- Multi-Turn SFT & Masked Gradient Verification (Tool 364) ---" -ForegroundColor Yellow

try {
    $sftJsonl = "$baseDir\03_vault\corpus\sh_xi_sourced_multiturn_sft_v1.jsonl"
    $sftLines = Get-Content -LiteralPath $sftJsonl
    $sftRawText = Get-Content -LiteralPath $sftJsonl -Raw
    $forbiddenHits = @([regex]::Matches($sftRawText, '(sorry|axiom |v71|v72)')).Count

    $resp2A = Invoke-ToolPost "/api/v1/tools/t364" @{ force_retrain = $false } 30
    $dh = $resp2A.dataset_hygiene
    $mg = $resp2A.masked_gradient_verification

    if ($resp2A.status -eq "MEASURED" -and `
        $sftLines.Count -ge 64 -and $forbiddenHits -eq 0 -and `
        $dh.sft_dialogues -ge 64 -and $dh.deduplicated_doc_count -ge 64 -and `
        $dh.source_files_read -ge 8 -and $dh.max_pairwise_5gram_jaccard -le 0.50 -and `
        $dh.min_turns -eq 1 -and $dh.max_turns -eq 8 -and `
        $mg.measured_prompt_grad_norm -eq 0.0 -and $mg.measured_assistant_grad_norm -gt 0.0 -and `
        $mg.zero_prompt_gradient_leakage -eq $true -and $mg.ce_loss_improved -eq $true) {
        Write-Host "  [PASS] Case 2A: SFT hygiene & masked gradients verified (files=$($dh.source_files_read), raw=$($dh.raw_doc_count), dedup=$($dh.deduplicated_doc_count), max_jacc=$($dh.max_pairwise_5gram_jaccard), forbidden=$forbiddenHits, prompt_grad=$($mg.measured_prompt_grad_norm))" -ForegroundColor Green
        $results["Case2A_SFTDatasetHygiene"] = "PASS"
    } else {
        Write-Host "  [FAIL] Case 2A: SFT hygiene failed (status=$($resp2A.status), lines=$($sftLines.Count), forbidden=$forbiddenHits, dedup=$($dh.deduplicated_doc_count), max_jacc=$($dh.max_pairwise_5gram_jaccard))" -ForegroundColor Red
        $results["Case2A_SFTDatasetHygiene"] = "FAIL"
        $allPass = $false
    }
} catch {
    Write-Host "  [FAIL] Case 2A Exception: $_" -ForegroundColor Red
    $results["Case2A_SFTDatasetHygiene"] = "FAIL ($($_))"
    $allPass = $false
}

try {
    $sftJsonl = "$baseDir\03_vault\corpus\sh_xi_sourced_multiturn_sft_v1.jsonl"
    $computedSha = Get-BytesSha256 ([System.IO.File]::ReadAllBytes($sftJsonl))
    $manifest = Get-Content -Path "$baseDir\03_vault\connectome\sh_xi_week2_chatml_sft_manifest.json" -Raw | ConvertFrom-Json
    if ($manifest.sha256 -eq $computedSha -and $manifest.deduplicated_doc_count -ge 64 -and $manifest.max_pairwise_5gram_jaccard -le 0.50) {
        Write-Host "  [PASS] Case 2B: Live SFT SHA-256 locked to manifest ($computedSha)" -ForegroundColor Green
        $results["Case2B_SFTHashLock"] = "PASS"
    } else {
        Write-Host "  [FAIL] Case 2B: SFT manifest SHA or dedup metadata mismatch!" -ForegroundColor Red
        $results["Case2B_SFTHashLock"] = "FAIL"
        $allPass = $false
    }
} catch {
    Write-Host "  [FAIL] Case 2B Exception: $_" -ForegroundColor Red
    $results["Case2B_SFTHashLock"] = "FAIL ($($_))"
    $allPass = $false
}

# -------------------------------------------------------------
# Case 3: Feature M8 -- Honest Autoregressive Inference, FSM, Missing-Weight 503 & Live Weight Perturbation
# -------------------------------------------------------------
Write-Host "`n--- Case 3: Feature M8 -- Honest Autoregressive Inference & Live Weight Sensitivity ---" -ForegroundColor Yellow

$baselineChatP1 = $null
$baselineConverseOut = $null
$baselineT361Out = $null

try {
    $p1 = "Summarize the 3-Shell Matryoshka architecture of Sovereign Harmonic XI."
    $p2 = "Explain how extended Golay G24 checks syndromes over 24 code bits."

    $r3A_1 = Invoke-ToolPost "/v1/chat/completions" @{
        model = "sovereign-harmonic-xi-3shell-moe"
        messages = @(@{ role = "user"; content = $p1 })
        max_tokens = 24
        temperature = 0.0
    } 30
    $r3A_2 = Invoke-ToolPost "/v1/chat/completions" @{
        model = "sovereign-harmonic-xi-3shell-moe"
        messages = @(@{ role = "user"; content = $p1 })
        max_tokens = 24
        temperature = 0.0
    } 30
    $r3A_diff = Invoke-ToolPost "/v1/chat/completions" @{
        model = "sovereign-harmonic-xi-3shell-moe"
        messages = @(@{ role = "user"; content = $p2 })
        max_tokens = 24
        temperature = 0.0
    } 30

    $c1 = $r3A_1.choices[0].message.content
    $c2 = $r3A_2.choices[0].message.content
    $cDiff = $r3A_diff.choices[0].message.content
    $toks = $r3A_1.usage.completion_tokens
    $hasCanned = $c1.Contains("Comprehensive Engineering Essay") -or `
                 $c1.Contains("Detailed Mathematical Analysis of") -or `
                 $c1.Contains("evaluated the prompt across 3-Shell Matryoshka and Sparse MoE.") -or `
                 $c1.Contains("UNMEASURED/OFFLINE: Requested external")

    if (-not [string]::IsNullOrWhiteSpace($c1) -and $toks -gt 0 -and ($c1 -eq $c2) -and ($c1 -ne $cDiff) -and -not $hasCanned) {
        Write-Host "  [PASS] Case 3A: Deterministic greedy emission (temp=0.0 identical; distinct prompt yields distinct tokens=$toks; canned=$hasCanned)" -ForegroundColor Green
        $results["Case3A_AutoregressiveDeterminism"] = "PASS"
        $baselineChatP1 = $c1
    } else {
        Write-Host "  [FAIL] Case 3A: Autoregressive determinism or non-template check failed (eq=$($c1 -eq $c2), diff=$($c1 -ne $cDiff), toks=$toks, canned=$hasCanned)" -ForegroundColor Red
        $results["Case3A_AutoregressiveDeterminism"] = "FAIL"
        $allPass = $false
    }
} catch {
    Write-Host "  [FAIL] Case 3A Exception: $_" -ForegroundColor Red
    $results["Case3A_AutoregressiveDeterminism"] = "FAIL ($($_))"
    $allPass = $false
}

try {
    $body3B = @{
        model = "sovereign-harmonic-xi-3shell-moe"
        messages = @(@{ role = "user"; content = "Emit a valid JSON summary of neuron count and carrier frequency." })
        mode = "json"
        max_tokens = 32
        temperature = 0.0
        response_format = @{ type = "json_object" }
    }
    $resp3B = Invoke-ToolPost "/v1/chat/completions" $body3B 30
    $content3B = $resp3B.choices[0].message.content
    $parsedJson = $content3B | ConvertFrom-Json
    $propCount = @($parsedJson.PSObject.Properties).Count

    if ($null -ne $parsedJson -and $propCount -ge 1) {
        Write-Host "  [PASS] Case 3B: Pushdown JSON FSM produced genuine parseable JSON ($propCount keys): $content3B" -ForegroundColor Green
        $results["Case3B_PushdownJsonFsm"] = "PASS"
    } else {
        Write-Host "  [FAIL] Case 3B: Pushdown JSON FSM returned empty or unparseable JSON: $content3B" -ForegroundColor Red
        $results["Case3B_PushdownJsonFsm"] = "FAIL"
        $allPass = $false
    }
} catch {
    Write-Host "  [FAIL] Case 3B Exception: $_" -ForegroundColor Red
    $results["Case3B_PushdownJsonFsm"] = "FAIL ($($_))"
    $allPass = $false
}

# Subtest 3C: Live Missing-Weight HTTP 503 Fail-Closed Test (restored in finally)
$baseSh4z = "$baseDir\00_control\weights\sovereign_harmonic_xi_rw384_768_base.sh4z"
$baseSh4zBak = "$baseSh4z.m4bak"
try {
    if (Test-Path $baseSh4zBak) { Remove-Item -Force $baseSh4zBak }
    Move-Item -LiteralPath $baseSh4z -Destination $baseSh4zBak -Force

    $pMissing = @{
        model = "sovereign-harmonic-xi-3shell-moe"
        messages = @(@{ role = "user"; content = "Probe missing weights" })
        max_tokens = 16
        temperature = 0.0
    }
    $rChatJson = Invoke-RawHttpPost "/v1/chat/completions" $pMissing 30
    $rChatSse  = Invoke-RawHttpPost "/v1/chat/completions" @{ model = "sovereign-harmonic-xi-3shell-moe"; prompt = "Probe missing weights"; stream = $true } 30
    $rConvJson = Invoke-RawHttpPost "/api/v1/sovereign_harmonic/converse" @{ prompt = "Probe missing weights"; temperature = 0.0 } 30
    $rConvSse  = Invoke-RawHttpPost "/api/v1/sovereign_harmonic/converse" @{ prompt = "Probe missing weights"; stream = $true } 30
    $rT361     = Invoke-RawHttpPost "/api/v1/tools/t361" @{ prompt = "Probe missing weights"; temperature = 0.0 } 30

    $all503 = ($rChatJson.StatusCode -eq 503) -and ($rChatJson.Body -match "GENERATION_UNAVAILABLE_WEIGHTS_NOT_LOADED") `
         -and ($rChatSse.StatusCode -eq 503)  -and ($rChatSse.Body -match "GENERATION_UNAVAILABLE_WEIGHTS_NOT_LOADED") `
         -and ($rConvJson.StatusCode -eq 503) -and ($rConvJson.Body -match "GENERATION_UNAVAILABLE_WEIGHTS_NOT_LOADED") `
         -and ($rConvSse.StatusCode -eq 503)  -and ($rConvSse.Body -match "GENERATION_UNAVAILABLE_WEIGHTS_NOT_LOADED") `
         -and ($rT361.StatusCode -eq 503)     -and ($rT361.Body -match "GENERATION_UNAVAILABLE_WEIGHTS_NOT_LOADED")

    if ($all503) {
        Write-Host "  [PASS] Case 3C: Live missing-weight test returned HTTP 503 + GENERATION_UNAVAILABLE_WEIGHTS_NOT_LOADED across all 5 inference/SSE routes" -ForegroundColor Green
        $results["Case3C_LiveMissingWeight503"] = "PASS"
    } else {
        Write-Host "  [FAIL] Case 3C: Missing-weight 503 check failed! Codes: Chat=$($rChatJson.StatusCode), ChatSSE=$($rChatSse.StatusCode), Conv=$($rConvJson.StatusCode), ConvSSE=$($rConvSse.StatusCode), T361=$($rT361.StatusCode)" -ForegroundColor Red
        $results["Case3C_LiveMissingWeight503"] = "FAIL"
        $allPass = $false
    }
} catch {
    Write-Host "  [FAIL] Case 3C Exception: $_" -ForegroundColor Red
    $results["Case3C_LiveMissingWeight503"] = "FAIL ($($_))"
    $allPass = $false
} finally {
    if (Test-Path $baseSh4zBak) {
        Move-Item -LiteralPath $baseSh4zBak -Destination $baseSh4z -Force
    }
}

# Subtest 3D: Live Weight Perturbation Proving Real Weight Sensitivity (Tool 361 + /converse)
function Write-BytesAtomicRetry {
    param([string]$TargetPath, [byte[]]$Bytes)
    $tmp = "$TargetPath.m4tmp"
    [System.IO.File]::WriteAllBytes($tmp, $Bytes)
    for ($i = 0; $i -lt 10; $i++) {
        try {
            Move-Item -LiteralPath $tmp -Destination $TargetPath -Force
            return
        } catch {
            Start-Sleep -Milliseconds 150
        }
    }
    [System.IO.File]::WriteAllBytes($TargetPath, $Bytes)
    if (Test-Path $tmp) { Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue }
}
$manifestFile = "$baseDir\00_control\weights\sovereign_harmonic_weights_manifest.json"
$trainMetaFile = "$baseDir\00_control\weights\sh_xi_base_train_meta.json"
$origSh4zBytes = [System.IO.File]::ReadAllBytes($baseSh4z)
$origManifestBytes = [System.IO.File]::ReadAllBytes($manifestFile)
$origManifestText = [System.Text.Encoding]::UTF8.GetString($origManifestBytes)
$origTrainMetaBytes = [System.IO.File]::ReadAllBytes($trainMetaFile)
$origTrainMetaText = [System.Text.Encoding]::UTF8.GetString($origTrainMetaBytes)
try {
    try { $null = Invoke-ToolPost "/api/v1/aegis/cron_status" @{ enabled = $false } 15 } catch {}
    $probeBody = @{ prompt = "Describe Viviani 1000 mV dendritic conservation in Rust."; max_tokens = 24; temperature = 0.0 }
    $baselineConv = Invoke-ToolPost "/api/v1/sovereign_harmonic/converse" $probeBody 30
    $baselineT361 = Invoke-ToolPost "/api/v1/tools/t361" $probeBody 30
    $baselineConverseOut = $baselineConv.output_text
    $baselineT361Out = $baselineT361.output_text

    $mutBytes = Flip-StiefelP0SignBits $origSh4zBytes
    $origSha = Get-BytesSha256 $origSh4zBytes
    $mutSha = Get-BytesSha256 $mutBytes

    $utf8NoBom = [System.Text.UTF8Encoding]::new($false)
    Write-BytesAtomicRetry -TargetPath $baseSh4z -Bytes $mutBytes
    Write-BytesAtomicRetry -TargetPath $manifestFile -Bytes ($utf8NoBom.GetBytes($origManifestText.Replace($origSha, $mutSha)))
    Write-BytesAtomicRetry -TargetPath $trainMetaFile -Bytes ($utf8NoBom.GetBytes($origTrainMetaText.Replace($origSha, $mutSha)))

    $mutConv = Invoke-ToolPost "/api/v1/sovereign_harmonic/converse" $probeBody 30
    $mutT361 = Invoke-ToolPost "/api/v1/tools/t361" $probeBody 30

    if (($mutConv.output_text -ne $baselineConverseOut) -and ($mutT361.output_text -ne $baselineT361Out)) {
        Write-Host "  [PASS] Case 3D: Live stiefel_p0 sign-bit perturbation changed both Tool 361 and /converse outputs deterministically" -ForegroundColor Green
        $results["Case3D_LiveWeightPerturbation"] = "PASS"
    } else {
        Write-Host "  [FAIL] Case 3D: Live weight perturbation did NOT change outputs (convChanged=$($mutConv.output_text -ne $baselineConverseOut), t361Changed=$($mutT361.output_text -ne $baselineT361Out))!" -ForegroundColor Red
        $results["Case3D_LiveWeightPerturbation"] = "FAIL"
        $allPass = $false
    }
} catch {
    Write-Host "  [FAIL] Case 3D Exception: $_" -ForegroundColor Red
    $results["Case3D_LiveWeightPerturbation"] = "FAIL ($($_))"
    $allPass = $false
} finally {
    Write-BytesAtomicRetry -TargetPath $baseSh4z -Bytes $origSh4zBytes
    Write-BytesAtomicRetry -TargetPath $manifestFile -Bytes $origManifestBytes
    Write-BytesAtomicRetry -TargetPath $trainMetaFile -Bytes $origTrainMetaBytes
    try { $null = Invoke-ToolPost "/api/v1/aegis/cron_status" @{ enabled = $true } 15 } catch {}
    # Trigger clean cache reload back to restored weights
    $null = Invoke-ToolPost "/api/v1/tools/t361" @{ prompt = "cache restore"; max_tokens = 4; temperature = 0.0 } 30
}

# -------------------------------------------------------------
# Case 4: Feature M15 -- Long Context 4,096 Uniform Propagation, Perturbation & Fail-Closed (Tool 342)
# -------------------------------------------------------------
Write-Host "`n--- Case 4: Feature M15 -- Long Context 4,096 & Distractor/Weight Challenges (Tool 342) ---" -ForegroundColor Yellow

$baselineT342 = $null
try {
    $resp4A = Invoke-ToolPost "/api/v1/tools/t342" @{ action = "gauntlet" } 30
    $baselineT342 = $resp4A
    $stepped = $resp4A.o1_recurrent_memory.horizon_tokens_stepped
    $recurrentBytes = $resp4A.o1_recurrent_memory.total_recurrent_state_bytes
    $recalls = $resp4A.needle_in_4096_haystack_gauntlet.exact_recalls
    $margin = [double]$resp4A.needle_in_4096_haystack_gauntlet.mean_needle_logit_margin
    $roundtripOk = $resp4A.recurrent_buffer_roundtrip_fixture.verified
    $distractorsRejected = $resp4A.recurrent_buffer_roundtrip_fixture.distractors_rejected

    if ($resp4A.status -eq "MEASURED" -and `
        $stepped -eq 4096 -and $recurrentBytes -eq 448 -and `
        ($recalls -match '^\d+/5$') -and (-not [double]::IsNaN($margin)) -and (-not [double]::IsInfinity($margin)) -and `
        $roundtripOk -eq $true -and $distractorsRejected -eq 64) {
        Write-Host "  [PASS] Case 4A: 4,096 uniform propagation verified (stepped=$stepped, bytes=$recurrentBytes, recalls=$recalls, margin=$margin, fixture=$roundtripOk/$distractorsRejected)" -ForegroundColor Green
        $results["Case4A_LongHorizon4KGauntlet"] = "PASS"
    } else {
        Write-Host "  [FAIL] Case 4A: 4K gauntlet failed (status=$($resp4A.status), stepped=$stepped, bytes=$recurrentBytes, recalls=$recalls, margin=$margin)" -ForegroundColor Red
        $results["Case4A_LongHorizon4KGauntlet"] = "FAIL"
        $allPass = $false
    }
} catch {
    Write-Host "  [FAIL] Case 4A Exception: $_" -ForegroundColor Red
    $results["Case4A_LongHorizon4KGauntlet"] = "FAIL ($($_))"
    $allPass = $false
}

$w3Contrastive = "$baseDir\00_control\weights\sovereign_harmonic_week3_contrastive_weights.sh4z"
$w3ContrastiveBak = "$w3Contrastive.m4bak"
try {
    $respCorrupt = Invoke-ToolPost "/api/v1/tools/t342" @{ inject_corruption = $true } 30
    $respSeed    = Invoke-ToolPost "/api/v1/tools/t342" @{ haystack_seed = 99991; needle_override = 12345; depth_shift = 200 } 30

    $corruptChanged = ($respCorrupt.o1_recurrent_memory.state_digest_fnv1a64_hex -ne $baselineT342.o1_recurrent_memory.state_digest_fnv1a64_hex) `
                   -or ([double]$respCorrupt.needle_in_4096_haystack_gauntlet.mean_needle_logit_margin -ne [double]$baselineT342.needle_in_4096_haystack_gauntlet.mean_needle_logit_margin)
    $seedChanged    = ($respSeed.o1_recurrent_memory.state_digest_fnv1a64_hex -ne $baselineT342.o1_recurrent_memory.state_digest_fnv1a64_hex) `
                   -or ([double]$respSeed.needle_in_4096_haystack_gauntlet.mean_needle_logit_margin -ne [double]$baselineT342.needle_in_4096_haystack_gauntlet.mean_needle_logit_margin)

    if (Test-Path $w3ContrastiveBak) { Remove-Item -Force $w3ContrastiveBak }
    Move-Item -LiteralPath $w3Contrastive -Destination $w3ContrastiveBak -Force
    $respMissingW = Invoke-ToolPost "/api/v1/tools/t342" @{ action = "gauntlet" } 30
    $missingFailedClosed = ($respMissingW.status -eq "UNMEASURED/OFFLINE")

    if ($corruptChanged -and $seedChanged -and $missingFailedClosed) {
        Write-Host "  [PASS] Case 4B: NIAH responded to needle/haystack perturbations AND missing weight failed closed ($($respMissingW.status))" -ForegroundColor Green
        $results["Case4B_NIAHPerturbAndFailClosed"] = "PASS"
    } else {
        Write-Host "  [FAIL] Case 4B: NIAH perturbation or fail-closed failed (corrupt=$corruptChanged, seed=$seedChanged, missing=$missingFailedClosed)" -ForegroundColor Red
        $results["Case4B_NIAHPerturbAndFailClosed"] = "FAIL"
        $allPass = $false
    }
} catch {
    Write-Host "  [FAIL] Case 4B Exception: $_" -ForegroundColor Red
    $results["Case4B_NIAHPerturbAndFailClosed"] = "FAIL ($($_))"
    $allPass = $false
} finally {
    if (Test-Path $w3ContrastiveBak) {
        Move-Item -LiteralPath $w3ContrastiveBak -Destination $w3Contrastive -Force
    }
}

# -------------------------------------------------------------
# Case 5: Feature M18 -- Signed 384D RAG vs Independent Lexical Baseline + Fail-Closed + Zero-Mutation Audit
# -------------------------------------------------------------
Write-Host "`n--- Case 5: Feature M18 -- RAG Perturbation Independence, Fail-Closed & Read-Only Audit ---" -ForegroundColor Yellow

try {
    $q5 = @{ query = "sovereign manifold architecture zero square brackets"; top_k = 3 }
    $resp5Base = Invoke-ToolPost "/api/v1/tools/t365" $q5 30
    $baseTopIds = @($resp5Base.workspace_rag_384d.rag_top_chunks | ForEach-Object { $_.chunk_id }) -join ","
    $baseLexJson = ($resp5Base.workspace_rag_384d.lexical_baseline_chunks | ConvertTo-Json -Compress -Depth 6)

    $mutBytes5 = Flip-StiefelP0SignBits $origSh4zBytes
    $origSha5 = Get-BytesSha256 $origSh4zBytes
    $mutSha5 = Get-BytesSha256 $mutBytes5
    [System.IO.File]::WriteAllBytes($baseSh4z, $mutBytes5)
    [System.IO.File]::WriteAllText($manifestFile, $origManifestText.Replace($origSha5, $mutSha5))
    [System.IO.File]::WriteAllText($trainMetaFile, $origTrainMetaText.Replace($origSha5, $mutSha5))

    $resp5Mut = Invoke-ToolPost "/api/v1/tools/t365" $q5 30
    $mutTopIds = @($resp5Mut.workspace_rag_384d.rag_top_chunks | ForEach-Object { $_.chunk_id }) -join ","
    $mutLexJson = ($resp5Mut.workspace_rag_384d.lexical_baseline_chunks | ConvertTo-Json -Compress -Depth 6)

    $hasV721Source = $false
    foreach ($chunk in $resp5Base.workspace_rag_384d.rag_top_chunks) {
        if ($chunk.path -and $chunk.path.Contains("v72_1")) { $hasV721Source = $true }
    }

    if ($resp5Base.status -eq "MEASURED" -and -not $hasV721Source -and `
        ($baseTopIds -ne $mutTopIds) -and ($baseLexJson -eq $mutLexJson)) {
        Write-Host "  [PASS] Case 5A: Shell 0 perturbation changed rag_top_chunks ($baseTopIds -> $mutTopIds) while lexical_baseline_chunks stayed 100% invariant" -ForegroundColor Green
        $results["Case5A_RagShell0SensitivityLexicalInvariant"] = "PASS"
    } else {
        Write-Host "  [FAIL] Case 5A: RAG sensitivity/independence check failed (base=$baseTopIds, mut=$mutTopIds, lexSame=$($baseLexJson -eq $mutLexJson), v72_1=$hasV721Source)" -ForegroundColor Red
        $results["Case5A_RagShell0SensitivityLexicalInvariant"] = "FAIL"
        $allPass = $false
    }
} catch {
    Write-Host "  [FAIL] Case 5A Exception: $_" -ForegroundColor Red
    $results["Case5A_RagShell0SensitivityLexicalInvariant"] = "FAIL ($($_))"
    $allPass = $false
} finally {
    [System.IO.File]::WriteAllBytes($baseSh4z, $origSh4zBytes)
    [System.IO.File]::WriteAllText($manifestFile, $origManifestText)
    [System.IO.File]::WriteAllText($trainMetaFile, $origTrainMetaText)
    $null = Invoke-ToolPost "/api/v1/tools/t365" @{ query = "restore cache" } 30
}

try {
    if (Test-Path $baseSh4zBak) { Remove-Item -Force $baseSh4zBak }
    Move-Item -LiteralPath $baseSh4z -Destination $baseSh4zBak -Force
    $resp5Miss = Invoke-ToolPost "/api/v1/tools/t365" @{ query = "missing weights probe" } 30
    if ($resp5Miss.status -eq "RAG_UNAVAILABLE_UNTRAINED_OR_MISSING_WEIGHTS") {
        Write-Host "  [PASS] Case 5B: Tool 365 failed closed cleanly on missing weights ($($resp5Miss.status))" -ForegroundColor Green
        $results["Case5B_RagMissingWeightsFailClosed"] = "PASS"
    } else {
        Write-Host "  [FAIL] Case 5B: Tool 365 unexpected status ($($resp5Miss.status))" -ForegroundColor Red
        $results["Case5B_RagMissingWeightsFailClosed"] = "FAIL"
        $allPass = $false
    }
} catch {
    Write-Host "  [FAIL] Case 5B Exception: $_" -ForegroundColor Red
    $results["Case5B_RagMissingWeightsFailClosed"] = "FAIL ($($_))"
    $allPass = $false
} finally {
    if (Test-Path $baseSh4zBak) {
        Move-Item -LiteralPath $baseSh4zBak -Destination $baseSh4z -Force
    }
    $null = Invoke-ToolPost "/api/v1/tools/t365" @{ query = "restore cache" } 30
}

try {
    $resp5C = Invoke-ToolPost "/api/v1/tools/t365" @{ query = "tri-silicon live telemetry" } 30
    $telemetry = $resp5C.trisilicon_live_telemetry
    $rtxTemp = $telemetry.host_rtx3050.temp_c
    if ($telemetry -and $rtxTemp -gt 0) {
        Write-Host "  [PASS] Case 5C: Tri-Silicon telemetry grounded (RTX=${rtxTemp}C, P10=$($telemetry.edge1_pixel10.status), P8=$($telemetry.edge2_pixel8_rooted.status))" -ForegroundColor Green
        $results["Case5C_TriSiliconTelemetry"] = "PASS"
    } else {
        Write-Host "  [FAIL] Case 5C: Tri-Silicon telemetry offline or unmeasured!" -ForegroundColor Red
        $results["Case5C_TriSiliconTelemetry"] = "FAIL"
        $allPass = $false
    }
} catch {
    Write-Host "  [FAIL] Case 5C Exception: $_" -ForegroundColor Red
    $results["Case5C_TriSiliconTelemetry"] = "FAIL ($($_))"
    $allPass = $false
}

try {
    # Pause background 60s AEGIS autonomous STDP cron during read-only snapshot window (restored in finally)
    $null = Invoke-ToolPost "/api/v1/aegis/cron_status" @{ enabled = $false } 15
    Start-Sleep -Milliseconds 350

    $weightsDir = "$baseDir\00_control\weights"
    $snapBefore = @{}
    Get-ChildItem -LiteralPath $weightsDir -File | ForEach-Object {
        $snapBefore[$_.Name] = (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
    }

    $null = Invoke-ToolPost "/api/v1/tools/t342" @{ action = "gauntlet" } 30
    $null = Invoke-ToolPost "/api/v1/tools/t357" @{ action = "audit" } 30
    $null = Invoke-ToolPost "/api/v1/tools/t358" @{ text = "read-only probe" } 30
    $null = Invoke-ToolPost "/api/v1/tools/t360" @{ force_retrain = $false } 30
    $null = Invoke-ToolPost "/api/v1/tools/t361" @{ prompt = "read-only probe"; max_tokens = 8; temperature = 0.0 } 30
    $null = Invoke-ToolPost "/api/v1/tools/t363" @{ force_retrain = $false } 30
    $null = Invoke-ToolPost "/api/v1/tools/t364" @{ force_retrain = $false } 30
    $null = Invoke-ToolPost "/api/v1/tools/t365" @{ query = "read-only probe" } 30
    $null = Invoke-ToolPost "/api/v1/tools/t366" @{} 30
    $null = Invoke-ToolPost "/api/v1/sovereign_harmonic/converse" @{ prompt = "read-only probe"; max_tokens = 8; temperature = 0.0 } 30
    $null = Invoke-ToolPost "/v1/chat/completions" @{ model = "sovereign-harmonic-xi-3shell-moe"; messages = @(@{ role = "user"; content = "read-only probe" }); max_tokens = 8; temperature = 0.0 } 30

    $mutated = @()
    Get-ChildItem -LiteralPath $weightsDir -File | ForEach-Object {
        $afterH = (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash
        if ($snapBefore[$_.Name] -ne $afterH) {
            $mutated += $_.Name
        }
    }

    if ($mutated.Count -eq 0) {
        Write-Host "  [PASS] Case 5D: Zero weight mutations confirmed across all 11 read-only endpoints ($($snapBefore.Count) weight/meta files 100% invariant)" -ForegroundColor Green
        $results["Case5D_ReadOnlyZeroMutation"] = "PASS"
    } else {
        Write-Host "  [FAIL] Case 5D: Weight files mutated during read-only probes: $($mutated -join ', ')" -ForegroundColor Red
        $results["Case5D_ReadOnlyZeroMutation"] = "FAIL"
        $allPass = $false
    }
} catch {
    Write-Host "  [FAIL] Case 5D Exception: $_" -ForegroundColor Red
    $results["Case5D_ReadOnlyZeroMutation"] = "FAIL ($($_))"
    $allPass = $false
} finally {
    try { $null = Invoke-ToolPost "/api/v1/aegis/cron_status" @{ enabled = $true } 15 } catch {}
}

# -------------------------------------------------------------
# Summary Report
# -------------------------------------------------------------
Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host "  Milestone M4 Challenger Verification Results Summary" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
foreach ($k in $results.Keys) {
    $val = $results[$k]
    $color = if ($val -eq "PASS") { "Green" } else { "Red" }
    Write-Host "  $k : $val" -ForegroundColor $color
}

if ($allPass) {
    Write-Host "`n>>> ALL M4 CHALLENGER TESTS PASSED ($($results.Count)/$($results.Count)) <<<" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n>>> SOME M4 CHALLENGER TESTS FAILED <<<" -ForegroundColor Red
    exit 1
}
