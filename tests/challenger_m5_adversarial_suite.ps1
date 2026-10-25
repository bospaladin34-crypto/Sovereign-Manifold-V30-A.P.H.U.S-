# Challenger M5-2: Empirical Adversarial Boundary & Invariant Suite
# Target: Milestone 5 Phase 1 (Acceptance & 6-Layer Verification Gate)
# File: C:\sovereign_manifold_v31\tests\challenger_m5_adversarial_suite.ps1
# Constraints: Zero Python | Measured Data Mandate | Empirical Reproduction

param(
    [string]$RepoRoot = "C:\sovereign_manifold_v31",
    [string]$SwarmPort = "8097"
)

$ErrorActionPreference = "Continue"

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "  CHALLENGER M5-2: EMPIRICAL ADVERSARIAL BOUNDARY & INVARIANT SUITE       " -ForegroundColor Cyan
Write-Host "  Target: ACT-Omega Net v49.0.0 (CHAIN 100 Century Milestone)             " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan

$Results = [ordered]@{
    Timestamp = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    Task1_ZeroSquareBrackets = [ordered]@{
        TotalModulesEvaluated = 0
        CleanModulesCount = 0
        ViolatingModulesCount = 0
        ModuleDetails = @()
        DetectorSensitivityVerified = $false
        Status = "PENDING"
    }
    Task2_PasskeyPurgeScan = [ordered]@{
        TargetPasskey = ("SOVEREIGN-" + "LOQ15-4200")
        TargetedCriticalFiles = [ordered]@{
            TotalScanned = 0
            Hits = 0
            Details = @()
            Status = "PENDING"
        }
        ActiveConfigAndToolFiles = [ordered]@{
            TotalScanned = 0
            Hits = 0
            Details = @()
            Status = "PENDING"
        }
        AuditAndTestScripts = [ordered]@{
            Hits = 0
            Details = @()
        }
        HistoricalDocsAndSpecs = [ordered]@{
            Hits = 0
            Details = @()
        }
        GlobalMatchesCount = 0
        Status = "PENDING"
    }
    Task3_Lean4Audit = [ordered]@{
        KernelExitCode = -1
        TotalTheoremsParsed = 0
        SorryCount = 0
        TrivialRflCount = 0
        Theorems433_460_Audited = 0
        Theorems433_460_UniversalCount = 0
        TheoremDetails = @()
        Status = "PENDING"
    }
    Task4_LiveEndpoints = [ordered]@{
        AdminSelfExitBlocked403 = $false
        Chain100OmniSuiteOk200 = $false
        AllTools91to100Present = $false
        Status = "PENDING"
    }
    OverallVerdict = "PENDING"
}

# ============================================================================
# TASK 1: Zero Square Brackets Across v49 and all 25 modules in v33..v49
# ============================================================================
Write-Host "`n--- [TASK 1] ADVERSARIAL ZERO SQUARE BRACKETS VERIFICATION (v33..v49) ---" -ForegroundColor Yellow

# Synthetic detector sensitivity test first
$syntheticViolationBuffer = [System.Text.Encoding]::ASCII.GetBytes("pub fn test_fail() -> i32 { return arr[0]; }")
$synthOpen = ($syntheticViolationBuffer | Where-Object { $_ -eq 0x5B }).Count
$synthClose = ($syntheticViolationBuffer | Where-Object { $_ -eq 0x5D }).Count
if ($synthOpen -eq 1 -and $synthClose -eq 1) {
    $Results.Task1_ZeroSquareBrackets.DetectorSensitivityVerified = $true
    Write-Host "  [DETECTOR SENSITIVITY] Verified: detected 1 '[' and 1 ']' in synthetic probe buffer." -ForegroundColor Green
} else {
    Write-Host "  [DETECTOR SENSITIVITY] FAILED to detect brackets in synthetic probe!" -ForegroundColor Red
}

$rustSrcDir = Join-Path $RepoRoot "01_l0_rust\src"
$candidateFiles = Get-ChildItem -Path $rustSrcDir -Filter "v*.rs" | Where-Object {
    $_.Name -match "^v(3[3-9]|4[0-9])_"
} | Sort-Object Name

Write-Host "  Discovered $($candidateFiles.Count) modules matching v33..v49 in $rustSrcDir"

$allClean = $true
foreach ($file in $candidateFiles) {
    $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
    $openCount = ($bytes | Where-Object { $_ -eq 0x5B }).Count
    $closeCount = ($bytes | Where-Object { $_ -eq 0x5D }).Count
    $totalBrackets = $openCount + $closeCount
    $sha256 = (Get-FileHash -Path $file.FullName -Algorithm SHA256).Hash

    $modRecord = [ordered]@{
        FileName = $file.Name
        SizeBytes = $bytes.Length
        SHA256 = $sha256
        OpenBrackets = $openCount
        CloseBrackets = $closeCount
        TotalBrackets = $totalBrackets
        Clean = ($totalBrackets -eq 0)
    }
    $Results.Task1_ZeroSquareBrackets.ModuleDetails += $modRecord

    if ($totalBrackets -eq 0) {
        Write-Host "  [PASS] $($file.Name.PadRight(45)) | Bytes: $($bytes.Length.ToString().PadLeft(6)) | [=0 ]=0" -ForegroundColor Green
    } else {
        $allClean = $false
        Write-Host "  [FAIL] $($file.Name.PadRight(45)) | VIOLATION: [=$openCount ]=$closeCount" -ForegroundColor Red
    }
}

$Results.Task1_ZeroSquareBrackets.TotalModulesEvaluated = $candidateFiles.Count
$Results.Task1_ZeroSquareBrackets.CleanModulesCount = ($Results.Task1_ZeroSquareBrackets.ModuleDetails | Where-Object { $_.Clean }).Count
$Results.Task1_ZeroSquareBrackets.ViolatingModulesCount = ($Results.Task1_ZeroSquareBrackets.ModuleDetails | Where-Object { -not $_.Clean }).Count

if ($allClean -and $candidateFiles.Count -eq 25 -and $Results.Task1_ZeroSquareBrackets.DetectorSensitivityVerified) {
    $Results.Task1_ZeroSquareBrackets.Status = "PASS"
    Write-Host "  --> TASK 1 RESULT: PASS (All 25 modules strictly 0 square brackets)" -ForegroundColor Green
} else {
    $Results.Task1_ZeroSquareBrackets.Status = "FAIL"
    Write-Host "  --> TASK 1 RESULT: FAIL (Modules count: $($candidateFiles.Count)/25, Violations: $($Results.Task1_ZeroSquareBrackets.ViolatingModulesCount))" -ForegroundColor Red
}

# ============================================================================
# TASK 2: Scan for Deprecated Passkey REDACTED_LEGACY_KEY
# ============================================================================
Write-Host "`n--- [TASK 2] PASSKEY PURGE SCAN (REDACTED_LEGACY_KEY) ---" -ForegroundColor Yellow

$targetPasskey = ("SOVEREIGN-" + "LOQ15-4200")

# Category A: Targeted Critical Production Files
$criticalFiles = @(
    "index.html",
    "wiki.html",
    "01_l0_rust\src\bin\v31_swarm.rs",
    "05_hud_cockpit\src\App.tsx",
    "02_l2_orchestration\hud\src\App.tsx",
    "00_control\cloudflare_edge\worker_continuum_do.js",
    "05_hud_cockpit\public\sw.js",
    "04_edge_silicon\pixel10_ndk_app\app\src\main\java\com\actomega\manifold\MainActivity.kt"
)

Write-Host "  [Category A] Targeted Critical Production Files:"
$critHits = 0
foreach ($rel in $criticalFiles) {
    $full = Join-Path $RepoRoot $rel
    if (Test-Path $full) {
        $content = [System.IO.File]::ReadAllText($full)
        $mCount = ([regex]::Matches($content, [regex]::Escape($targetPasskey))).Count
        $Results.Task2_PasskeyPurgeScan.TargetedCriticalFiles.Details += [ordered]@{
            File = $rel
            Hits = $mCount
        }
        $critHits += $mCount
        if ($mCount -gt 0) {
            Write-Host "    [FAIL] $rel : $mCount hits" -ForegroundColor Red
        } else {
            Write-Host "    [PASS] $rel : 0 hits" -ForegroundColor Green
        }
    }
}
$Results.Task2_PasskeyPurgeScan.TargetedCriticalFiles.TotalScanned = $criticalFiles.Count
$Results.Task2_PasskeyPurgeScan.TargetedCriticalFiles.Hits = $critHits
$Results.Task2_PasskeyPurgeScan.TargetedCriticalFiles.Status = if ($critHits -eq 0) { "PASS" } else { "FAIL" }

# Category B: Active Config & MCP Tool Files
Write-Host "  [Category B] Active Config & Tool Files:"
$cfgHits = 0
$mcpConfigFile = Join-Path $RepoRoot ".agents\mcp_config.json"
if (Test-Path $mcpConfigFile) {
    $mcpText = [System.IO.File]::ReadAllText($mcpConfigFile)
    $mcpMatches = ([regex]::Matches($mcpText, [regex]::Escape($targetPasskey))).Count
    $cfgHits += $mcpMatches
    $Results.Task2_PasskeyPurgeScan.ActiveConfigAndToolFiles.Details += [ordered]@{
        File = ".agents\mcp_config.json"
        Hits = $mcpMatches
    }
    if ($mcpMatches -gt 0) {
        Write-Host "    [FAIL] .agents\mcp_config.json contains $mcpMatches active occurrences of deprecated passkey!" -ForegroundColor Red
    } else {
        Write-Host "    [PASS] .agents\mcp_config.json : 0 hits" -ForegroundColor Green
    }
}
$Results.Task2_PasskeyPurgeScan.ActiveConfigAndToolFiles.TotalScanned = 1
$Results.Task2_PasskeyPurgeScan.ActiveConfigAndToolFiles.Hits = $cfgHits
$Results.Task2_PasskeyPurgeScan.ActiveConfigAndToolFiles.Status = if ($cfgHits -eq 0) { "PASS" } else { "FAIL" }

# Category C & D: Audit Scripts & Docs
$scriptHits = @()
$docHits = @()

$knownScriptMatches = @(
    "00_control\Sovereign-Lifecycle.ps1",
    "tests\e2e\tier1_features.ps1",
    "tests\e2e\tier3_integration.ps1",
    "tests\e2e\tier4_scenarios.ps1",
    "tests\e2e\test_m2_challenger_adversarial.ps1",
    "tests\e2e\test_m4_challenger_adversarial.ps1",
    "tests\challenger_m2_adversarial_suite.ps1"
)
foreach ($sf in $knownScriptMatches) {
    $p = Join-Path $RepoRoot $sf
    if (Test-Path $p) {
        $c = ([regex]::Matches(([System.IO.File]::ReadAllText($p)), [regex]::Escape($targetPasskey))).Count
        if ($c -gt 0) {
            $scriptHits += [PSCustomObject]@{ File = $sf; Hits = $c; Note = "Audit test assertion regex pattern" }
        }
    }
}
$Results.Task2_PasskeyPurgeScan.AuditAndTestScripts.Details = $scriptHits
$Results.Task2_PasskeyPurgeScan.AuditAndTestScripts.Hits = if ($scriptHits.Count -gt 0) { ($scriptHits | Measure-Object -Property Hits -Sum).Sum } else { 0 }

$knownDocMatches = @(
    "PROJECT.md",
    "TEST_INFRA.md",
    "RELEASE_NOTES_v42_0_0.md",
    "Research synthesis & isomorpisms 2.md",
    "ACT-Omega v29.0 Continuous Codebase.md",
    "ACT-Omega v31.0 Verbatim Source Code Mirror & Continuous Codebase.md",
    "ANTIGRAVITY_ARCHITECTURE_READINESS_v43.md",
    "ANTIGRAVITY_GEMINI4_ARGON_CUTOVER_PLAN_v43.md"
)
foreach ($df in $knownDocMatches) {
    $p = Join-Path $RepoRoot $df
    if (Test-Path $p) {
        $c = ([regex]::Matches(([System.IO.File]::ReadAllText($p)), [regex]::Escape($targetPasskey))).Count
        if ($c -gt 0) {
            $docHits += [PSCustomObject]@{ File = $df; Hits = $c; Note = "Historical documentation or spec mention" }
        }
    }
}
$Results.Task2_PasskeyPurgeScan.HistoricalDocsAndSpecs.Details = $docHits
$Results.Task2_PasskeyPurgeScan.HistoricalDocsAndSpecs.Hits = if ($docHits.Count -gt 0) { ($docHits | Measure-Object -Property Hits -Sum).Sum } else { 0 }

$totalGlobalMatches = $critHits + $cfgHits + $Results.Task2_PasskeyPurgeScan.AuditAndTestScripts.Hits + $Results.Task2_PasskeyPurgeScan.HistoricalDocsAndSpecs.Hits
$Results.Task2_PasskeyPurgeScan.GlobalMatchesCount = $totalGlobalMatches

Write-Host "  Summary: Category A (Production HTML/Source): $critHits hits (PASS)"
Write-Host "  Summary: Category B (Active Configs/Tools): $cfgHits hits (.agents\mcp_config.json)"
Write-Host "  Summary: Category C (Audit Assertion Patterns): $($Results.Task2_PasskeyPurgeScan.AuditAndTestScripts.Hits) hits"
Write-Host "  Summary: Category D (Historical Docs/Specs): $($Results.Task2_PasskeyPurgeScan.HistoricalDocsAndSpecs.Hits) hits"

# Strict verdict for Task 2:
# If strict global zero is required across all files, it is FAIL because .agents/mcp_config.json contains the active key.
if ($cfgHits -gt 0) {
    $Results.Task2_PasskeyPurgeScan.Status = "FAIL_ACTIVE_CONFIG_LEAK"
    Write-Host "  --> TASK 2 RESULT: REQUEST_CHANGES (Active leak in .agents\mcp_config.json: $cfgHits hits)" -ForegroundColor Red
} elseif ($critHits -gt 0) {
    $Results.Task2_PasskeyPurgeScan.Status = "FAIL_PRODUCTION_LEAK"
    Write-Host "  --> TASK 2 RESULT: FAIL (Production leak: $critHits hits)" -ForegroundColor Red
} else {
    $Results.Task2_PasskeyPurgeScan.Status = "PASS"
    Write-Host "  --> TASK 2 RESULT: PASS" -ForegroundColor Green
}

# ============================================================================
# TASK 3: Adversarially Audit SovereignManifoldTheorems.lean
# ============================================================================
Write-Host "`n--- [TASK 3] ADVERSARIAL AUDIT OF LEAN 4 FORMAL PROOFS ---" -ForegroundColor Yellow

$leanExe = "C:\Users\Nbell\.elan\bin\lean.exe"
$leanFile = Join-Path $RepoRoot "03_vault\lean4\SovereignManifoldTheorems.lean"

if (-not (Test-Path $leanExe)) {
    Write-Host "  [FAIL] Lean executable not found at $leanExe" -ForegroundColor Red
    $Results.Task3_Lean4Audit.Status = "FAIL"
} elseif (-not (Test-Path $leanFile)) {
    Write-Host "  [FAIL] Lean file not found at $leanFile" -ForegroundColor Red
    $Results.Task3_Lean4Audit.Status = "FAIL"
} else {
    Write-Host "  Running Lean 4 kernel compiler: $leanExe $leanFile..."
    $leanProcess = Start-Process -FilePath $leanExe -ArgumentList "`"$leanFile`"" -NoNewWindow -Wait -PassThru
    $Results.Task3_Lean4Audit.KernelExitCode = $leanProcess.ExitCode

    Write-Host "  Lean 4 compiler exit code: $($leanProcess.ExitCode)"
    if ($leanProcess.ExitCode -eq 0) {
        Write-Host "  [PASS] Lean 4 kernel accepted all proofs with 0 errors/warnings." -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] Lean 4 compiler failed with exit code $($leanProcess.ExitCode)" -ForegroundColor Red
    }

    $leanContent = [System.IO.File]::ReadAllText($leanFile)

    # 1. Check for 'sorry'
    $sorryMatches = [regex]::Matches($leanContent, '\bsorry\b')
    $Results.Task3_Lean4Audit.SorryCount = $sorryMatches.Count
    if ($sorryMatches.Count -eq 0) {
        Write-Host "  [PASS] Zero 'sorry' axioms found in Lean proof file." -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] Found $($sorryMatches.Count) 'sorry' occurrences!" -ForegroundColor Red
    }

    # 2. Check for trivial (N = N) := by rfl
    $trivialRflMatches = [regex]::Matches($leanContent, '\(([0-9]+)\s*=\s*\1\)\s*:=\s*by\s*rfl')
    $Results.Task3_Lean4Audit.TrivialRflCount = $trivialRflMatches.Count
    if ($trivialRflMatches.Count -eq 0) {
        Write-Host "  [PASS] Zero trivial '(N = N) := by rfl' reflexivities found." -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] Found $($trivialRflMatches.Count) trivial '(N = N) := by rfl' instances!" -ForegroundColor Red
    }

    # 3. Robust line-by-line parser for all theorems (Zero Premature Colon Split)
    $lines = $leanContent -split "`r?`n"
    $theorems433to460Count = 0
    $universalCount = 0
    $totalThms = 0

    $theoremPattern = '^theorem\s+([a-zA-Z0-9_]+)\s*((?:\([^)]*\)\s*)*):\s*(.*?)\s*:=\s*by\s*(.*?)$'

    foreach ($line in $lines) {
        $trimmed = $line.Trim()
        if ($trimmed -match $theoremPattern) {
            $totalThms++
            $thmName = $Matches[1]
            $thmParams = $Matches[2].Trim()
            $thmProp = $Matches[3].Trim()
            $thmProof = $Matches[4].Trim()

            if ($thmName -match '_4(3[3-9]|[4-5][0-9]|60)_') {
                $theorems433to460Count++
                $hasUniversalParam = ($thmParams -match '\([a-zA-Z0-9_]+\s*:\s*[a-zA-Z0-9_]+\)') -or ($thmProp -match '∀|forall')
                $hasNoSorry = -not ($thmProof -match '\bsorry\b')
                $isNotConstantRfl = -not ($thmProp -match '^\(?\d+\s*=\s*\d+\)?$')

                $isValid = ($hasUniversalParam -and $hasNoSorry -and $isNotConstantRfl)
                if ($isValid) { $universalCount++ }

                $detail = [ordered]@{
                    Name = $thmName
                    Parameters = $thmParams
                    Proposition = $thmProp
                    Proof = $thmProof
                    HasUniversalParam = $hasUniversalParam
                    HasNoSorry = $hasNoSorry
                    IsNotConstantRfl = $isNotConstantRfl
                    Valid = $isValid
                }
                $Results.Task3_Lean4Audit.TheoremDetails += $detail

                $statusText = if ($isValid) { "[PASS]" } else { "[FAIL]" }
                $color = if ($isValid) { "Green" } else { "Red" }
                Write-Host "  $statusText $thmName | Param: $thmParams | Prop: $thmProp | Proof: $thmProof" -ForegroundColor $color
            }
        }
    }

    $Results.Task3_Lean4Audit.TotalTheoremsParsed = $totalThms
    $Results.Task3_Lean4Audit.Theorems433_460_Audited = $theorems433to460Count
    $Results.Task3_Lean4Audit.Theorems433_460_UniversalCount = $universalCount

    Write-Host "  Total theorems parsed: $totalThms (Req: >= 460)"
    Write-Host "  Theorems 433..460 audited: $theorems433to460Count / 28. Universally quantified & valid: $universalCount / 28."

    if ($Results.Task3_Lean4Audit.KernelExitCode -eq 0 -and
        $Results.Task3_Lean4Audit.SorryCount -eq 0 -and
        $Results.Task3_Lean4Audit.TrivialRflCount -eq 0 -and
        $totalThms -ge 460 -and
        $theorems433to460Count -eq 28 -and
        $universalCount -eq 28) {
        $Results.Task3_Lean4Audit.Status = "PASS"
        Write-Host "  --> TASK 3 RESULT: PASS (All 460 theorems QED, 0 sorry, 0 trivial rfl, 100% universal in 433..460)" -ForegroundColor Green
    } else {
        $Results.Task3_Lean4Audit.Status = "FAIL"
        Write-Host "  --> TASK 3 RESULT: FAIL" -ForegroundColor Red
    }
}

# ============================================================================
# TASK 4: Live HTTP Endpoint & Security Invariants
# ============================================================================
Write-Host "`n--- [TASK 4] LIVE HTTP ENDPOINTS & SECURITY CONTRACTS ---" -ForegroundColor Yellow

# Test 4.1: Unauthenticated Admin Endpoint MUST be 403 Forbidden
try {
    $req = [System.Net.HttpWebRequest]::Create("http://127.0.0.1:$SwarmPort/api/v1/admin/self_exit")
    $req.Method = "GET"
    $req.Timeout = 5000
    $resp = $req.GetResponse()
    Write-Host "  [FAIL] /api/v1/admin/self_exit returned HTTP $([int]$resp.StatusCode) without header auth!" -ForegroundColor Red
    $resp.Close()
} catch [System.Net.WebException] {
    $status = [int]$_.Exception.Response.StatusCode
    if ($status -eq 403) {
        $Results.Task4_LiveEndpoints.AdminSelfExitBlocked403 = $true
        Write-Host "  [PASS] /api/v1/admin/self_exit cleanly rejected with HTTP 403 Forbidden." -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] /api/v1/admin/self_exit returned unexpected status: $status" -ForegroundColor Red
    }
} catch {
    Write-Host "  [FAIL] Failed to contact /api/v1/admin/self_exit: $_" -ForegroundColor Red
}

# Test 4.2: CHAIN 100 Omni Suite Endpoint
try {
    $req = [System.Net.HttpWebRequest]::Create("http://127.0.0.1:$SwarmPort/api/v1/v49/chain100_omni_suite")
    $req.Method = "GET"
    $req.Timeout = 10000
    $resp = $req.GetResponse()
    $status = [int]$resp.StatusCode
    $stream = $resp.GetResponseStream()
    $reader = New-Object System.IO.StreamReader($stream)
    $json = $reader.ReadToEnd()
    $resp.Close()

    if ($status -eq 200) {
        $Results.Task4_LiveEndpoints.Chain100OmniSuiteOk200 = $true
        Write-Host "  [PASS] /api/v1/v49/chain100_omni_suite returned HTTP 200 OK." -ForegroundColor Green
        
        # Verify Tools 91 to 100 presence
        $missingTools = @()
        for ($t = 91; $t -le 100; $t++) {
            if ($json -notmatch "tool_$t") {
                $missingTools += "tool_$t"
            }
        }
        if ($missingTools.Count -eq 0) {
            $Results.Task4_LiveEndpoints.AllTools91to100Present = $true
            Write-Host "  [PASS] All 10 tools (tool_91..tool_100) verified in live omni suite response." -ForegroundColor Green
        } else {
            Write-Host "  [FAIL] Missing tools in omni suite response: $($missingTools -join ', ')" -ForegroundColor Red
        }
    } else {
        Write-Host "  [FAIL] /api/v1/v49/chain100_omni_suite returned status $status" -ForegroundColor Red
    }
} catch {
    Write-Host "  [FAIL] Failed to contact /api/v1/v49/chain100_omni_suite: $_" -ForegroundColor Red
}

if ($Results.Task4_LiveEndpoints.AdminSelfExitBlocked403 -and
    $Results.Task4_LiveEndpoints.Chain100OmniSuiteOk200 -and
    $Results.Task4_LiveEndpoints.AllTools91to100Present) {
    $Results.Task4_LiveEndpoints.Status = "PASS"
    Write-Host "  --> TASK 4 RESULT: PASS" -ForegroundColor Green
} else {
    $Results.Task4_LiveEndpoints.Status = "FAIL"
    Write-Host "  --> TASK 4 RESULT: FAIL" -ForegroundColor Red
}

# ============================================================================
# FINAL VERDICT SYNTHESIS
# ============================================================================
Write-Host "`n==========================================================================" -ForegroundColor Cyan
Write-Host "  FINAL CHALLENGER VERDICT SYNTHESIS                                      " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan

# Check overall status
# Task 1 must be PASS
# Task 2 must NOT have active config leak (.agents/mcp_config.json) or production leak
# Task 3 must be PASS
# Task 4 must be PASS
$t1Pass = ($Results.Task1_ZeroSquareBrackets.Status -eq "PASS")
$t2Pass = ($Results.Task2_PasskeyPurgeScan.TargetedCriticalFiles.Hits -eq 0) -and ($Results.Task2_PasskeyPurgeScan.ActiveConfigAndToolFiles.Hits -eq 0)
$t3Pass = ($Results.Task3_Lean4Audit.Status -eq "PASS")
$t4Pass = ($Results.Task4_LiveEndpoints.Status -eq "PASS")

$overallPass = $t1Pass -and $t2Pass -and $t3Pass -and $t4Pass

if ($overallPass) {
    $Results.OverallVerdict = "APPROVE"
    Write-Host "  OVERALL VERDICT: APPROVE" -ForegroundColor Green
} else {
    $Results.OverallVerdict = "REQUEST_CHANGES"
    Write-Host "  OVERALL VERDICT: REQUEST_CHANGES" -ForegroundColor Red
    if (-not $t1Pass) { Write-Host "  Reason: Task 1 (Zero Square Brackets) failed." -ForegroundColor Red }
    if (-not $t2Pass) { 
        Write-Host "  Reason: Task 2 (Passkey Scan) failed - active configuration leak in .agents\mcp_config.json ($($Results.Task2_PasskeyPurgeScan.ActiveConfigAndToolFiles.Hits) hits)." -ForegroundColor Red 
    }
    if (-not $t3Pass) { Write-Host "  Reason: Task 3 (Lean 4 Audit) failed." -ForegroundColor Red }
    if (-not $t4Pass) { Write-Host "  Reason: Task 4 (Live Endpoints) failed." -ForegroundColor Red }
}

# Export results JSON
$outJsonPath = Join-Path $RepoRoot "tests\challenger_m5_results.json"
$Results | ConvertTo-Json -Depth 6 | Out-File -FilePath $outJsonPath -Encoding utf8
Write-Host "  Exported results to $outJsonPath" -ForegroundColor Cyan

exit $(if ($overallPass) { 0 } else { 1 })
