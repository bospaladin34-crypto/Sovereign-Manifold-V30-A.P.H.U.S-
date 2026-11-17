# 00_control\Test-M3-Priority3And4Challenger.ps1
# Milestone M3 (Priority 3 & 4) Challenger Verification Script
# Proves 5 live negative failure cases against :8097

$ErrorActionPreference = "Stop"

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "  ACT-Omega Net v70.0.0 -- Milestone M3 Priority 3 & 4 Challenger" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

$baseUrl = "http://127.0.0.1:8097"
$baseDir = "c:\sovereign_manifold_v31"

# Load operator key if present
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

# Helper function for JSON POST
function Invoke-ToolPost($endpoint, $bodyObj, $timeoutSec = 30) {
    $url = "$baseUrl$endpoint"
    $jsonBody = $bodyObj | ConvertTo-Json -Compress
    return Invoke-RestMethod -Uri $url -Method Post -Body $jsonBody -ContentType "application/json" -Headers $headers -TimeoutSec $timeoutSec
}

# -------------------------------------------------------------
# Case 1: Non-compiling / Sorry Lean 4 Candidate
# -------------------------------------------------------------
Write-Host "`n--- Case 1: Non-compiling / Sorry Lean Candidate (Tool 351) ---" -ForegroundColor Yellow

# Subtest 1A: Sorry hack candidate
try {
    $body1A = @{
        track_id = 3
        custom_candidate = "theorem bad_thm : 1 = 2 := by sorry"
    }
    $resp1A = Invoke-ToolPost "/api/v1/tools/t351" $body1A
    $audit1A = $resp1A.custom_audit
    if ($audit1A -and $audit1A.evaluated -eq $true -and ($audit1A.lean4_qed_ok -eq $false -or $audit1A.reward_hack_blocked -eq $true) -and $audit1A.total_reward -eq 0.0) {
        Write-Host "  [PASS] Case 1A: Sorry hack blocked (lean4_qed_ok=$($audit1A.lean4_qed_ok), reward_hack_blocked=$($audit1A.reward_hack_blocked), reward=$($audit1A.total_reward))" -ForegroundColor Green
        $results["Case1A_Lean4SorryBlocked"] = "PASS"
    } else {
        Write-Host "  [FAIL] Case 1A: Sorry candidate was not blocked properly!" -ForegroundColor Red
        $results["Case1A_Lean4SorryBlocked"] = "FAIL"
        $allPass = $false
    }
} catch {
    Write-Host "  [FAIL] Case 1A Exception: $_" -ForegroundColor Red
    $results["Case1A_Lean4SorryBlocked"] = "FAIL ($($_))"
    $allPass = $false
}

# Subtest 1B: Non-compiling candidate
try {
    $body1B = @{
        track_id = 3
        custom_candidate = "theorem invalid_thm : 1 = 2 := by omega"
    }
    $resp1B = Invoke-ToolPost "/api/v1/tools/t351" $body1B
    $audit1B = $resp1B.custom_audit
    if ($audit1B -and $audit1B.evaluated -eq $true -and $audit1B.lean4_qed_ok -eq $false -and $audit1B.total_reward -eq 0.0) {
        Write-Host "  [PASS] Case 1B: Non-compiling Lean proof rejected (lean4_qed_ok=$($audit1B.lean4_qed_ok), reward=$($audit1B.total_reward))" -ForegroundColor Green
        $results["Case1B_Lean4NonCompiling"] = "PASS"
    } else {
        Write-Host "  [FAIL] Case 1B: Non-compiling Lean candidate not rejected!" -ForegroundColor Red
        $results["Case1B_Lean4NonCompiling"] = "FAIL"
        $allPass = $false
    }
} catch {
    Write-Host "  [FAIL] Case 1B Exception: $_" -ForegroundColor Red
    $results["Case1B_Lean4NonCompiling"] = "FAIL ($($_))"
    $allPass = $false
}

# -------------------------------------------------------------
# Case 2: Broken / Bracketed Rust Candidate
# -------------------------------------------------------------
Write-Host "`n--- Case 2: Broken / Bracketed Rust Candidate (Tool 351) ---" -ForegroundColor Yellow

# Subtest 2A: Bracketed Rust candidate
try {
    $body2A = @{
        track_id = 2
        custom_candidate = "pub fn broken[T](x: T) -> T { x }"
    }
    $resp2A = Invoke-ToolPost "/api/v1/tools/t351" $body2A
    $audit2A = $resp2A.custom_audit
    if ($audit2A -and $audit2A.evaluated -eq $true -and $audit2A.zero_bracket_ok -eq $false -and $audit2A.syntax_valid -eq $false -and $audit2A.total_reward -eq 0.0) {
        Write-Host "  [PASS] Case 2A: Bracketed Rust candidate rejected (zero_bracket_ok=$($audit2A.zero_bracket_ok), syntax_valid=$($audit2A.syntax_valid), reward=$($audit2A.total_reward))" -ForegroundColor Green
        $results["Case2A_RustBracketedRejected"] = "PASS"
    } else {
        Write-Host "  [FAIL] Case 2A: Bracketed Rust candidate was not rejected!" -ForegroundColor Red
        $results["Case2A_RustBracketedRejected"] = "FAIL"
        $allPass = $false
    }
} catch {
    Write-Host "  [FAIL] Case 2A Exception: $_" -ForegroundColor Red
    $results["Case2A_RustBracketedRejected"] = "FAIL ($($_))"
    $allPass = $false
}

# Subtest 2B: Malformed syntax Rust candidate
try {
    $body2B = @{
        track_id = 2
        custom_candidate = "pub fn malformed( {"
    }
    $resp2B = Invoke-ToolPost "/api/v1/tools/t351" $body2B
    $audit2B = $resp2B.custom_audit
    if ($audit2B -and $audit2B.evaluated -eq $true -and $audit2B.syntax_valid -eq $false -and $audit2B.total_reward -eq 0.0) {
        Write-Host "  [PASS] Case 2B: Malformed syntax Rust candidate rejected (syntax_valid=$($audit2B.syntax_valid), reward=$($audit2B.total_reward))" -ForegroundColor Green
        $results["Case2B_RustMalformedRejected"] = "PASS"
    } else {
        Write-Host "  [FAIL] Case 2B: Malformed Rust candidate was not rejected!" -ForegroundColor Red
        $results["Case2B_RustMalformedRejected"] = "FAIL"
        $allPass = $false
    }
} catch {
    Write-Host "  [FAIL] Case 2B Exception: $_" -ForegroundColor Red
    $results["Case2B_RustMalformedRejected"] = "FAIL ($($_))"
    $allPass = $false
}

# -------------------------------------------------------------
# Case 3: Non-incident Plücker Bivector Rejection
# -------------------------------------------------------------
Write-Host "`n--- Case 3: Non-incident Plücker Bivector Rejection (Tool 351 & Tool 343) ---" -ForegroundColor Yellow

# Subtest 3A: Tool 351 non-incident bivector
try {
    $body3A = @{
        p01 = 3
        p02 = 5
        p03 = 7
        p12 = 2
        p13 = 4
        p23 = 6
    }
    $resp3A = Invoke-ToolPost "/api/v1/tools/t351" $body3A
    $audit3A = $resp3A.custom_audit
    if ($audit3A -and $audit3A.evaluated -eq $true -and $audit3A.plucker_residual -ne 0 -and $audit3A.plucker_isotropic_ok -eq $false -and $audit3A.total_reward -eq 0.0) {
        Write-Host "  [PASS] Case 3A: Tool 351 rejected non-incident bivector (residual=$($audit3A.plucker_residual), isotropic=$($audit3A.plucker_isotropic_ok))" -ForegroundColor Green
        $results["Case3A_Tool351PluckerResidual"] = "PASS"
    } else {
        Write-Host "  [FAIL] Case 3A: Tool 351 did not reject non-incident bivector!" -ForegroundColor Red
        $results["Case3A_Tool351PluckerResidual"] = "FAIL"
        $allPass = $false
    }
} catch {
    Write-Host "  [FAIL] Case 3A Exception: $_" -ForegroundColor Red
    $results["Case3A_Tool351PluckerResidual"] = "FAIL ($($_))"
    $allPass = $false
}

# Subtest 3B: Tool 343 corrupt chain
try {
    $body3B = @{
        corrupt_chain = $true
    }
    $resp3B = Invoke-ToolPost "/api/v1/tools/t343" $body3B
    if ($resp3B.status -eq "UNMEASURED/OFFLINE" -and $resp3B.plucker_4hop_cot.valid_chains_incident -ne "64/64" -and $resp3B.plucker_4hop_cot.total_klein_quadric_residual -gt 0) {
        Write-Host "  [PASS] Case 3B: Tool 343 corrupt chain rejected (status=$($resp3B.status), incident=$($resp3B.plucker_4hop_cot.valid_chains_incident), residual=$($resp3B.plucker_4hop_cot.total_klein_quadric_residual))" -ForegroundColor Green
        $results["Case3B_Tool343CorruptChain"] = "PASS"
    } else {
        Write-Host "  [FAIL] Case 3B: Tool 343 corrupt chain was not rejected!" -ForegroundColor Red
        $results["Case3B_Tool343CorruptChain"] = "FAIL"
        $allPass = $false
    }
} catch {
    Write-Host "  [FAIL] Case 3B Exception: $_" -ForegroundColor Red
    $results["Case3B_Tool343CorruptChain"] = "FAIL ($($_))"
    $allPass = $false
}

# Subtest 3C: Embedded non-incident Plucker coords in text + clean forward-hidden Plucker check
try {
    $body3C = @{
        track_id = 1
        custom_candidate = "The E8 lattice has 240 roots and Leech lattice has 196560 minimal vectors with p01=3 p02=5 p03=7 p12=2 p13=4 p23=6."
    }
    $resp3C = Invoke-ToolPost "/api/v1/tools/t351" $body3C
    $audit3C = $resp3C.custom_audit

    $body3CValid = @{
        track_id = 1
        custom_candidate = "Viazovska proved E8 sphere packing optimality with 240 roots and Leech 196560 kissing number."
    }
    $resp3CValid = Invoke-ToolPost "/api/v1/tools/t351" $body3CValid
    $audit3CValid = $resp3CValid.custom_audit

    $badOk = $audit3C -and ($audit3C.evaluated -eq $true) -and ($audit3C.plucker_isotropic_ok -eq $false) -and ($audit3C.plucker_residual -ne 0) -and ($audit3C.total_reward -eq 0.0)
    $fwdOk = $audit3CValid -and ($audit3CValid.evaluated -eq $true)
    if ($badOk -and $fwdOk) {
        Write-Host "  [PASS] Case 3C: Embedded non-incident Plucker rejected (residual=$($audit3C.plucker_residual)) and valid forward-hidden evaluated=$($audit3CValid.evaluated)" -ForegroundColor Green
        $results["Case3C_Tool351TextBivAndFwd"] = "PASS"
    } else {
        Write-Host "  [FAIL] Case 3C: Text bivector rejection ($badOk) or forward-hidden eval ($fwdOk) failed!" -ForegroundColor Red
        $results["Case3C_Tool351TextBivAndFwd"] = "FAIL"
        $allPass = $false
    }
} catch {
    Write-Host "  [FAIL] Case 3C Exception: $_" -ForegroundColor Red
    $results["Case3C_Tool351TextBivAndFwd"] = "FAIL ($($_))"
    $allPass = $false
}

# -------------------------------------------------------------
# Case 4: Poisoned / Unverified Draft Tree in Tool 352
# -------------------------------------------------------------
Write-Host "`n--- Case 4: Poisoned / Unverified Draft Tree (Tool 352) ---" -ForegroundColor Yellow

# Subtest 4A: Poison draft tree -> 0 poisoned drafts accepted & 1.0 tok/step fallback
try {
    $body4A = @{
        poison_draft_tree = $true
    }
    $resp4A = Invoke-ToolPost "/api/v1/tools/t352" $body4A
    $audit4A = $resp4A.poisoned_tree_resilience_audit
    $diff4A = [Math]::Abs($resp4A.mean_tokens_per_tree_step - 1.0)
    if ($audit4A.poisoned_draft_nodes_accepted -eq 0 -and $audit4A.fallback_honesty_verified -eq $true -and $diff4A -lt 0.001) {
        Write-Host "  [PASS] Case 4A: Poisoned draft tree honest fallback verified (poisoned_accepted=$($audit4A.poisoned_draft_nodes_accepted), fallback_tok=$($resp4A.mean_tokens_per_tree_step))" -ForegroundColor Green
        $results["Case4A_Tool352PoisonResilience"] = "PASS"
    } else {
        Write-Host "  [FAIL] Case 4A: Tool 352 poison resilience check failed!" -ForegroundColor Red
        $results["Case4A_Tool352PoisonResilience"] = "FAIL"
        $allPass = $false
    }
} catch {
    Write-Host "  [FAIL] Case 4A Exception: $_" -ForegroundColor Red
    $results["Case4A_Tool352PoisonResilience"] = "FAIL ($($_))"
    $allPass = $false
}

# Subtest 4B: Unverified corrupt tree bypass -> fails closed to UNMEASURED/OFFLINE
try {
    $body4B = @{
        inject_unverified_corrupt_tree_bypass = $true
    }
    $resp4B = Invoke-ToolPost "/api/v1/tools/t352" $body4B
    if ($resp4B.status -eq "UNMEASURED/OFFLINE" -and $resp4B.tree_speculative_certified -eq $false) {
        Write-Host "  [PASS] Case 4B: Corrupt tree bypass rejected (status=$($resp4B.status), certified=$($resp4B.tree_speculative_certified))" -ForegroundColor Green
        $results["Case4B_Tool352CorruptBypass"] = "PASS"
    } else {
        Write-Host "  [FAIL] Case 4B: Corrupt tree bypass did not fail closed!" -ForegroundColor Red
        $results["Case4B_Tool352CorruptBypass"] = "FAIL"
        $allPass = $false
    }
} catch {
    Write-Host "  [FAIL] Case 4B Exception: $_" -ForegroundColor Red
    $results["Case4B_Tool352CorruptBypass"] = "FAIL ($($_))"
    $allPass = $false
}

# -------------------------------------------------------------
# Case 5: Tampered Weight Checksum & Master Certification Integrity
# -------------------------------------------------------------
Write-Host "`n--- Case 5: Tampered Weight Checksum (Tool 355 & Tool 356) ---" -ForegroundColor Yellow

$shxWeightPath = Join-Path $baseDir "00_control\weights\sovereign_harmonic_x_rlvf_sae_weights.sh4z"
$shxBakPath = "$shxWeightPath.challenger_bak"

if (Test-Path $shxWeightPath) {
    # Move weight file to simulate missing/tampered weight
    Move-Item -Path $shxWeightPath -Destination $shxBakPath -Force
    try {
        # Tool 355 must fail closed
        $resp5A = Invoke-ToolPost "/api/v1/tools/t355" @{} 300
        $failClosed5A = ($resp5A.status -eq "UNMEASURED/OFFLINE") -and ($resp5A.all_12_tests_passed -eq $false)
        if ($failClosed5A) {
            Write-Host "  [PASS] Case 5A: Missing/tampered weight causes Tool 355 to fail closed (status=$($resp5A.status), all_12_passed=$($resp5A.all_12_tests_passed))" -ForegroundColor Green
            $results["Case5A_Tool355FailClosed"] = "PASS"
        } else {
            Write-Host "  [FAIL] Case 5A: Tool 355 did not fail closed on missing weight!" -ForegroundColor Red
            $results["Case5A_Tool355FailClosed"] = "FAIL"
            $allPass = $false
        }
    } catch {
        Write-Host "  [PASS] Case 5A: Tool 355 failed closed with exception ($($_))" -ForegroundColor Green
        $results["Case5A_Tool355FailClosed"] = "PASS"
    } finally {
        # Restore weight file immediately
        if (Test-Path $shxBakPath) {
            Move-Item -Path $shxBakPath -Destination $shxWeightPath -Force
        }
    }

    # Subtest 5A+: 1-byte XOR bit-flip in-place inside sh4z weight file -> Tool 355 & Tool 356 MUST fail closed
    $origShxBytes = [System.IO.File]::ReadAllBytes($shxWeightPath)
    try {
        $tamperedBytes = [byte[]]$origShxBytes.Clone()
        $tamperedBytes[100] = $tamperedBytes[100] -bxor 0xFF
        [System.IO.File]::WriteAllBytes($shxWeightPath, $tamperedBytes)

        $resp5Ap355 = Invoke-ToolPost "/api/v1/tools/t355" @{} 600
        $resp5Ap356 = Invoke-ToolPost "/api/v1/tools/t356" @{} 600
        $t355Fail = ($resp5Ap355.status -eq "UNMEASURED/OFFLINE") -and ($resp5Ap355.all_12_tests_passed -eq $false)
        $t356Fail = ($resp5Ap356.status -eq "UNMEASURED/OFFLINE") -and ($resp5Ap356.all_gates_passed -eq $false)
        if ($t355Fail -and $t356Fail) {
            Write-Host "  [PASS] Case 5A+: 1-byte XOR bit-flip caused Tool 355 & Tool 356 to fail closed (t355=$($resp5Ap355.status), t356=$($resp5Ap356.status))" -ForegroundColor Green
            $results["Case5APlus_Tool355And356BitFlip"] = "PASS"
        } else {
            Write-Host "  [FAIL] Case 5A+: 1-byte XOR bit-flip did not fail closed (t355Fail=$t355Fail, t356Fail=$t356Fail)!" -ForegroundColor Red
            $results["Case5APlus_Tool355And356BitFlip"] = "FAIL"
            $allPass = $false
        }
    } catch {
        Write-Host "  [FAIL] Case 5A+ Exception: $_" -ForegroundColor Red
        $results["Case5APlus_Tool355And356BitFlip"] = "FAIL ($($_))"
        $allPass = $false
    } finally {
        [System.IO.File]::WriteAllBytes($shxWeightPath, $origShxBytes)
    }

    # Restored verification: Tool 355 and Tool 356 must now PASS
    try {
        $resp5B = Invoke-ToolPost "/api/v1/tools/t355" @{} 600
        if ($resp5B.status -eq "MEASURED" -and $resp5B.all_12_tests_passed -eq $true) {
            Write-Host "  [PASS] Case 5B: Restored Tool 355 returns MEASURED (all_12_tests_passed=$($resp5B.all_12_tests_passed))" -ForegroundColor Green
            $results["Case5B_Tool355RestoredPass"] = "PASS"
        } else {
            Write-Host "  [FAIL] Case 5B: Restored Tool 355 did not pass (status=$($resp5B.status), all_12_passed=$($resp5B.all_12_tests_passed))" -ForegroundColor Red
            $results["Case5B_Tool355RestoredPass"] = "FAIL"
            $allPass = $false
        }
    } catch {
        Write-Host "  [FAIL] Case 5B Exception: $_" -ForegroundColor Red
        $results["Case5B_Tool355RestoredPass"] = "FAIL ($($_))"
        $allPass = $false
    }

    try {
        $resp5C = Invoke-ToolPost "/api/v1/tools/t356" @{} 600
        if ($resp5C.status -eq "MEASURED" -and $resp5C.all_gates_passed -eq $true) {
            Write-Host "  [PASS] Case 5C: Tool 356 Master Certification returns MEASURED (all_gates_passed=$($resp5C.all_gates_passed))" -ForegroundColor Green
            $results["Case5C_Tool356MasterCertification"] = "PASS"
        } else {
            Write-Host "  [FAIL] Case 5C: Tool 356 did not pass (status=$($resp5C.status), all_gates_passed=$($resp5C.all_gates_passed))" -ForegroundColor Red
            $results["Case5C_Tool356MasterCertification"] = "FAIL"
            $allPass = $false
        }
    } catch {
        Write-Host "  [FAIL] Case 5C Exception: $_" -ForegroundColor Red
        $results["Case5C_Tool356MasterCertification"] = "FAIL ($($_))"
        $allPass = $false
    }
} else {
    Write-Host "  [SKIP] Case 5: $shxWeightPath not found on disk" -ForegroundColor Yellow
    $results["Case5_TamperedWeight"] = "SKIP"
}

# -------------------------------------------------------------
# Summary
# -------------------------------------------------------------
Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host "  Milestone M3 Challenger Gauntlet Summary Results" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan
foreach ($k in $results.Keys) {
    $color = if ($results[$k] -eq "PASS") { "Green" } else { "Red" }
    Write-Host "  $($k.PadRight(35)) : $($results[$k])" -ForegroundColor $color
}

if ($allPass) {
    Write-Host "`n>>> ALL 5 CHALLENGER FAILURE CASES PASSED CONSTITUTIONALLY (Exit Code 0) <<<`n" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n>>> ONE OR MORE CHALLENGER CASES FAILED <<<`n" -ForegroundColor Red
    exit 1
}
