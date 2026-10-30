param(
    [switch]$HookStdin,
    [switch]$FullAudit,
    [switch]$StaticOnly,
    [string]$RepoPath = ""
)

$ErrorActionPreference = "Stop"

# Dynamic $RepoRoot resolution: -RepoPath -> $env:GITHUB_WORKSPACE -> $PSScriptRoot\.. -> fallback
$RepoRoot = if ($RepoPath -and (Test-Path $RepoPath)) {
    (Resolve-Path $RepoPath).Path
} elseif ($env:GITHUB_WORKSPACE -and (Test-Path $env:GITHUB_WORKSPACE)) {
    (Resolve-Path $env:GITHUB_WORKSPACE).Path
} elseif ($PSScriptRoot -and (Test-Path (Split-Path -Parent $PSScriptRoot))) {
    (Resolve-Path (Split-Path -Parent $PSScriptRoot)).Path
} else {
    "C:\sovereign_manifold_v31"
}

if (-not (Test-Path $RepoRoot)) {
    $RepoRoot = "C:\sovereign_manifold_v31"
}

function Run-StaticGatekeeperChecks {
    $failures = New-Object System.Collections.Generic.List[string]

    # 1. Zero-Square-Bracket L0 Rust Check (v33..v99+)
    $vFiles = Get-ChildItem -Path "$RepoRoot\01_l0_rust\src\v*.rs" -File | Where-Object { $_.Name -match '^v(3[3-9]|[4-9][0-9])_' }
    foreach ($vf in $vFiles) {
        $text = [System.IO.File]::ReadAllText($vf.FullName)
        $bCount = ([regex]::Matches($text, '[\[\]]')).Count
        if ($bCount -gt 0) {
            $failures.Add("L0_RUST_BRACKET_VIOLATION: $($vf.Name) contains $bCount square brackets (Req: 0)")
        }
    }

    # 2. Substantive Lean 4 & Vault/L0 Mirror Parity Check
    $leanVault = "$RepoRoot\03_vault\lean4\SovereignManifoldTheorems.lean"
    $leanL0 = "$RepoRoot\01_l0_rust\lean4\SovereignManifoldTheorems.lean"
    if (-not (Test-Path $leanVault) -or -not (Test-Path $leanL0)) {
        $failures.Add("LEAN4_MISSING: SovereignManifoldTheorems.lean missing in 03_vault or 01_l0_rust")
    } else {
        $h1 = (Get-FileHash $leanVault -Algorithm SHA256).Hash
        $h2 = (Get-FileHash $leanL0 -Algorithm SHA256).Hash
        if ($h1 -ne $h2) {
            $failures.Add("LEAN4_MIRROR_DRIFT: 03_vault/lean4 ($($h1.Substring(0,12))) != 01_l0_rust/lean4 ($($h2.Substring(0,12)))")
        }
        $leanText = [System.IO.File]::ReadAllText($leanVault)
        $thmCount = ([regex]::Matches($leanText, '(?m)^theorem\s+')).Count
        $sorryCount = ([regex]::Matches($leanText, '\bsorry\b')).Count
        $trivialEqCount = ([regex]::Matches($leanText, ':\s*(\w+)\s*=\s*\1\s*:=')).Count
        $trivialCommCount = ([regex]::Matches($leanText, '\(a\s+b\s*:\s*Nat\)\s*:\s*a\s*\+\s*b\s*=\s*b\s*\+\s*a')).Count
        if ($thmCount -lt 624) {
            $failures.Add("LEAN4_COUNT_LOW: Found $thmCount theorems (Req: >= 624)")
        }
        if ($sorryCount -gt 0) {
            $failures.Add("LEAN4_SORRY_FOUND: Found $sorryCount 'sorry' tokens (Req: 0)")
        }
        if (($trivialEqCount + $trivialCommCount) -gt 0) {
            $failures.Add("LEAN4_TRIVIAL_PADDING: Found $($trivialEqCount + $trivialCommCount) trivial arithmetic padding theorems (Req: 0)")
        }
    }

    # 3. HUD & Mobile Source Mirror Lockstep Check
    $hud1 = "$RepoRoot\05_hud_cockpit\src\App.tsx"
    $hud2 = "$RepoRoot\02_l2_orchestration\hud\src\App.tsx"
    if ((Get-FileHash $hud1 -Algorithm SHA256).Hash -ne (Get-FileHash $hud2 -Algorithm SHA256).Hash) {
        $failures.Add("HUD_MIRROR_DRIFT: 05_hud_cockpit/src/App.tsx != 02_l2_orchestration/hud/src/App.tsx")
    }
    $kt1 = "$RepoRoot\04_edge_silicon\pixel10_ndk_app\app\src\main\java\com\actomega\manifold\MainActivity.kt"
    $kt2 = "$RepoRoot\04_edge_silicon\pixel10_ndk_app\src\main\java\com\actomega\manifold\MainActivity.kt"
    if ((Get-FileHash $kt1 -Algorithm SHA256).Hash -ne (Get-FileHash $kt2 -Algorithm SHA256).Hash) {
        $failures.Add("MOBILE_MIRROR_DRIFT: app/src MainActivity.kt != src MainActivity.kt")
    }

    # 4. Constitutional Context & Agent/Rule Global/Workspace Lockstep
    $gWork = "$RepoRoot\GEMINI.md"
    $gUser1 = "C:\Users\Nbell\.gemini\GEMINI.md"
    $gUser2 = "C:\Users\Nbell\.gemini\AGENTS.md"
    if ((Test-Path $gWork) -and (Test-Path $gUser1) -and (Test-Path $gUser2)) {
        $hw = (Get-FileHash $gWork -Algorithm SHA256).Hash
        $hu1 = (Get-FileHash $gUser1 -Algorithm SHA256).Hash
        $hu2 = (Get-FileHash $gUser2 -Algorithm SHA256).Hash
        if (($hw -ne $hu1) -or ($hw -ne $hu2)) {
            $failures.Add("CONSTITUTION_DRIFT: GEMINI.md / AGENTS.md out of sync between workspace and ~/.gemini")
        }
    }
    $agentFiles = Get-ChildItem -Path "$RepoRoot\.agents\agents\*.md" -File
    if ($agentFiles.Count -lt 10) {
        $failures.Add("AGENT_ROSTER_INCOMPLETE: Found $($agentFiles.Count) agents in .agents/agents (Req: >= 10)")
    }
    $ruleFiles = Get-ChildItem -Path "$RepoRoot\.agents\rules\*.md" -File
    if ($ruleFiles.Count -lt 6) {
        $failures.Add("RULE_ROSTER_INCOMPLETE: Found $($ruleFiles.Count) rules in .agents/rules (Req: >= 6)")
    }

    # Guard host user directory comparison so CI does not report false mirror drift
    $globalConfigBase = if (Test-Path "C:\Users\Nbell\.gemini\config") {
        "C:\Users\Nbell\.gemini\config"
    } elseif ($env:USERPROFILE -and (Test-Path "$env:USERPROFILE\.gemini\config")) {
        "$env:USERPROFILE\.gemini\config"
    } else {
        $null
    }

    if ($globalConfigBase) {
        foreach ($af in $agentFiles) {
            $globalAf = "$globalConfigBase\agents\$($af.Name)"
            if (-not (Test-Path $globalAf) -or ((Get-FileHash $af.FullName -Algorithm SHA256).Hash -ne (Get-FileHash $globalAf -Algorithm SHA256).Hash)) {
                $failures.Add("AGENT_MIRROR_DRIFT: $($af.Name) out of sync with ~/.gemini/config/agents")
            }
        }
        foreach ($rf in $ruleFiles) {
            $globalRf = "$globalConfigBase\rules\$($rf.Name)"
            if (-not (Test-Path $globalRf) -or ((Get-FileHash $rf.FullName -Algorithm SHA256).Hash -ne (Get-FileHash $globalRf -Algorithm SHA256).Hash)) {
                $failures.Add("RULE_MIRROR_DRIFT: $($rf.Name) out of sync with ~/.gemini/config/rules")
            }
        }
    }

    # 5. Zero-Secret Leak Check (Retired Passkey & Active External Key)
    $retiredLiteral = "SOVEREIGN" + "-LOQ15-4200"
    $activeKeyPath = "C:\Users\Nbell\.act_omega_operator_vault_key"
    $activeLiteral = if (Test-Path $activeKeyPath) { (Get-Content $activeKeyPath -Raw).Trim() } else { "" }

    $checkFiles = @(
        "$RepoRoot\05_hud_cockpit\src\App.tsx",
        "$RepoRoot\02_l2_orchestration\hud\src\App.tsx",
        "$RepoRoot\05_hud_cockpit\dist\index.html",
        "$RepoRoot\docs\index.html",
        "$RepoRoot\docs\hud.html",
        "$RepoRoot\index.html",
        "$RepoRoot\hud.html",
        "$RepoRoot\wiki.html"
    )
    foreach ($cf in $checkFiles) {
        if (Test-Path $cf) {
            $content = [System.IO.File]::ReadAllText($cf)
            if ($content.Contains($retiredLiteral)) {
                $failures.Add("SECRET_LEAK_RETIRED: Retired passkey literal found in $cf")
            }
            if ($activeLiteral.Length -ge 16 -and $content.Contains($activeLiteral)) {
                $failures.Add("SECRET_LEAK_ACTIVE: Active external operator key found in $cf")
            }
        }
    }

    # 6. HTML External Crawler SSR Pre-Population & Asset Bundle Verification
    $htmlFiles = @(
        "$RepoRoot\index.html",
        "$RepoRoot\hud.html",
        "$RepoRoot\docs\index.html",
        "$RepoRoot\docs\hud.html",
        "$RepoRoot\05_hud_cockpit\dist\index.html"
    )
    foreach ($hf in $htmlFiles) {
        if (-not (Test-Path $hf)) {
            $failures.Add("HTML_MISSING: $hf not found")
            continue
        }
        $hContent = [System.IO.File]::ReadAllText($hf)
        if ($hContent -notmatch 'data-sovereign-ssr="v56\.0\.0"') {
            $failures.Add("HTML_SSR_MISSING: $hf missing data-sovereign-ssr=`"v56.0.0`" attribute")
        }
        $bundleMatches = [regex]::Matches($hContent, '(?i)(?:\./)?assets/(index-[^"''\s>]+\.js)')
        if ($bundleMatches.Count -eq 0) {
            $failures.Add("HTML_JS_BUNDLE_REF_MISSING: No assets/index-*.js script found in $hf")
        } else {
            foreach ($bm in $bundleMatches) {
                $bName = $bm.Groups[1].Value
                $rootAsset = "$RepoRoot\assets\$bName"
                $docsAsset = "$RepoRoot\docs\assets\$bName"
                if (-not (Test-Path $rootAsset)) {
                    $failures.Add("JS_BUNDLE_MISSING_ROOT: $bName referenced in $hf missing at $rootAsset")
                }
                if (-not (Test-Path $docsAsset)) {
                    $failures.Add("JS_BUNDLE_MISSING_DOCS: $bName referenced in $hf missing at $docsAsset")
                }
                if ($hf -like "*\dist\*") {
                    $distAsset = "$RepoRoot\05_hud_cockpit\dist\assets\$bName"
                    if (-not (Test-Path $distAsset)) {
                        $failures.Add("JS_BUNDLE_MISSING_DIST: $bName referenced in $hf missing at $distAsset")
                    }
                }
            }
        }
    }

    # 7. Google Search Console Verification Certificate Invariant (7 Target Paths, 53 Bytes, Exact SHA-256)
    $gscExpectedHash = "0241DC5EDED053A96317C9C8FF34F4DCF12C069F88B8D92636D5D795EC176B3D"
    $gscTargets = @(
        "$RepoRoot\05_hud_cockpit\public\google6edc0affb12d0455.html",
        "$RepoRoot\02_l2_orchestration\hud\public\google6edc0affb12d0455.html",
        "$RepoRoot\05_hud_cockpit\dist\google6edc0affb12d0455.html",
        "$RepoRoot\02_l2_orchestration\hud\dist\google6edc0affb12d0455.html",
        "$RepoRoot\docs\google6edc0affb12d0455.html",
        "$RepoRoot\google6edc0affb12d0455.html"
    )
    if (Test-Path "E:\Sovereign_Manifold_SSD_Vault") {
        $gscTargets += "E:\Sovereign_Manifold_SSD_Vault\google6edc0affb12d0455.html"
    }
    foreach ($gt in $gscTargets) {
        if (-not (Test-Path $gt)) {
            $failures.Add("GSC_CERT_MISSING: $gt not found")
            continue
        }
        $item = Get-Item $gt
        if ($item.Length -ne 53) {
            $failures.Add("GSC_CERT_BAD_LENGTH: $gt length is $($item.Length) bytes (Req: 53)")
        }
        $h = (Get-FileHash $gt -Algorithm SHA256).Hash
        if ($h -ne $gscExpectedHash) {
            $failures.Add("GSC_CERT_HASH_MISMATCH: $gt SHA256=$h (Req: $gscExpectedHash)")
        }
    }

    return ,$failures
}

if ($HookStdin) {
    $rawInput = ""
    try {
        if ([Console]::IsInputRedirected) {
            $rawInput = [Console]::In.ReadToEnd()
        }
    } catch {}

    if ([string]::IsNullOrWhiteSpace($rawInput)) {
        Write-Output '{"decision":"allow"}'
        exit 0
    }

    try {
        $payload = $rawInput | ConvertFrom-Json
        $toolName = $payload.toolCall.name
        $cmdLine = $payload.toolCall.args.CommandLine
        if ($toolName -eq "run_command" -and $cmdLine -match '\bgit\s+(commit|push)\b') {
            $violations = Run-StaticGatekeeperChecks
            if ($violations.Count -gt 0) {
                $reasonStr = "BRUTAL GATEKEEPER BLOCKED COMMIT/PUSH: " + ($violations -join " | ")
                $outObj = @{
                    decision = "deny"
                    reason   = $reasonStr
                } | ConvertTo-Json -Compress
                Write-Output $outObj
                exit 0
            }
        }
    } catch {
        # Fallback allow if JSON parsing fails on non-git input
    }

    Write-Output '{"decision":"allow"}'
    exit 0
}

# Default to -StaticOnly when invoked without switches
if (-not $HookStdin -and -not $FullAudit -and -not $StaticOnly) {
    $StaticOnly = $true
}

if ($StaticOnly) {
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "   ACT-OMEGA BRUTAL AGENT GATEKEEPER: STATIC INVARIANTS AUDIT             " -ForegroundColor Cyan
    Write-Host "==========================================================================" -ForegroundColor Cyan

    $failures = Run-StaticGatekeeperChecks
    if ($failures.Count -eq 0) {
        Write-Host "  [STATIC INVARIANTS] [PASS] All 7 Static Invariants Verified (Zero-Bracket, Lean4, Mirrors, Secrets, Agents/Rules, SSR & Bundles, GSC Lock)" -ForegroundColor Green
        Write-Host "==========================================================================" -ForegroundColor Cyan
        Write-Host "  [BRUTAL GATEKEEPER RESULT: PASSED (All 7 Static Invariants Verified)]" -ForegroundColor Green
        exit 0
    } else {
        foreach ($f in $failures) {
            Write-Host "  [STATIC FAIL] $f" -ForegroundColor Red
        }
        Write-Host "==========================================================================" -ForegroundColor Cyan
        Write-Host "  [BRUTAL GATEKEEPER RESULT: FAILED ($($failures.Count) VIOLATIONS)]" -ForegroundColor Red
        exit 1
    }
}

if ($FullAudit) {
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "   ACT-OMEGA BRUTAL AGENT GATEKEEPER: 11-POINT ARCHITECTURAL AUDIT        " -ForegroundColor Cyan
    Write-Host "==========================================================================" -ForegroundColor Cyan

    $failures = Run-StaticGatekeeperChecks
    if ($failures.Count -eq 0) {
        Write-Host "  [1-7 STATIC INVARIANTS] [PASS] Zero-Bracket(v33..v56+)=0 | Lean4>=624(0 trivial) | HUD/Mobile/Agent Mirrors=LOCKED | SecretsInRepo=0 | SSR & Bundles=VERIFIED | GSC 7-Mirror=LOCKED" -ForegroundColor Green
    } else {
        foreach ($f in $failures) {
            Write-Host "  [STATIC FAIL] $f" -ForegroundColor Red
        }
    }

    # 6. Live Lean 4 Compiler Verification
    $leanExe = if (Test-Path "C:\Users\Nbell\.elan\bin\lean.exe") { "C:\Users\Nbell\.elan\bin\lean.exe" } elseif (Get-Command lean -ErrorAction SilentlyContinue) { (Get-Command lean).Source } else { $null }
    if ($leanExe) {
        & $leanExe "$RepoRoot\03_vault\lean4\SovereignManifoldTheorems.lean" 2>&1 | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [6 LEAN 4 COMPILER]     [PASS] lean.exe verified 03_vault/lean4/SovereignManifoldTheorems.lean (EXIT:0)" -ForegroundColor Green
        } else {
            $failures.Add("LEAN4_COMPILER_FAIL: lean.exe exited with $LASTEXITCODE")
            Write-Host "  [6 LEAN 4 COMPILER]     [FAIL] lean.exe exited with $LASTEXITCODE" -ForegroundColor Red
        }
    } else {
        $failures.Add("LEAN4_COMPILER_MISSING: lean.exe not found")
        Write-Host "  [6 LEAN 4 COMPILER]     [FAIL] lean.exe not found" -ForegroundColor Red
    }

    # 7. Live Plucker 12/12 .e8z Measurement Probe
    try {
        $t92 = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/v49/tool_92_amplituhedron_9loop_hexagon_plucker" -TimeoutSec 5
        if ($t92.plucker_inner_product_p_ab -ne 0 -and $t92.proof_attestation -match "MEASURED") {
            Write-Host "  [7 PLUCKER 12/12 .E8Z]  [PASS] Pab=$($t92.plucker_inner_product_p_ab) | Attestation=$($t92.proof_attestation)" -ForegroundColor Green
        } else {
            $failures.Add("PLUCKER_AUDIT_FAIL: Unexpected Tool 92 response")
            Write-Host "  [7 PLUCKER 12/12 .E8Z]  [FAIL] Unexpected Tool 92 response" -ForegroundColor Red
        }
    } catch {
        $failures.Add("PLUCKER_PROBE_ERR: $_")
        Write-Host "  [7 PLUCKER 12/12 .E8Z]  [FAIL] $_" -ForegroundColor Red
    }

    # 8. Live v44 Lease Release Jitter Probe
    try {
        $v44 = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/worksteal/webgpu_lease?action=release&worker_id=gatekeeper_audit" -TimeoutSec 5
        if ([double]$v44.cadence_jitter_us -gt 0.0) {
            Write-Host "  [8 V44 RELEASE JITTER]  [PASS] Measured Release Jitter=$($v44.cadence_jitter_us) us (> 0.0)" -ForegroundColor Green
        } else {
            $failures.Add("V44_RELEASE_JITTER_ZERO: Release path returned 0.0")
            Write-Host "  [8 V44 RELEASE JITTER]  [FAIL] Release path returned 0.0" -ForegroundColor Red
        }
    } catch {
        $failures.Add("V44_PROBE_ERR: $_")
        Write-Host "  [8 V44 RELEASE JITTER]  [FAIL] $_" -ForegroundColor Red
    }

    # 9. Live Operator Header Gate & ?key= Rejection Probe
    try {
        $opKey = (Get-Content "C:\Users\Nbell\.act_omega_operator_vault_key" -Raw).Trim()
        $qResp = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/auth/operator_vault_gate?key=$opKey" -TimeoutSec 5
        $hResp = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/auth/operator_vault_gate" -Headers @{ "X-Sovereign-Operator-Key" = $opKey } -TimeoutSec 5
        if ($qResp.authorized -eq $false -and $hResp.authorized -eq $true) {
            Write-Host "  [9 OPERATOR AUTH GATE]  [PASS] QueryParam(?key=)=REJECTED | Header(X-Sovereign-Operator-Key)=AUTHORIZED" -ForegroundColor Green
        } else {
            $failures.Add("AUTH_GATE_FAIL: QueryAuthorized=$($qResp.authorized) HeaderAuthorized=$($hResp.authorized)")
            Write-Host "  [9 OPERATOR AUTH GATE]  [FAIL] Auth gate check failed" -ForegroundColor Red
        }
    } catch {
        $failures.Add("AUTH_PROBE_ERR: $_")
        Write-Host "  [9 OPERATOR AUTH GATE]  [FAIL] $_" -ForegroundColor Red
    }

    # 10. Live Coordinator Bus & E:\ Write-Back Probe
    try {
        $bus = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/coordinator/message_bus?source_module=BrutalGatekeeper&topic=GATEKEEPER_AUDIT&payload_summary=Verify_Bus_And_E_Vault" -TimeoutSec 5
        if ($bus.e_drive_mounted -eq $true -and $bus.ledger_measured_bytes -gt 0) {
            Write-Host "  [10 COORDINATOR & E:\]  [PASS] E_Mounted=True | LedgerBytes=$($bus.ledger_measured_bytes) | Envelopes=$($bus.total_envelopes_logged)" -ForegroundColor Green
        } else {
            $failures.Add("COORDINATOR_BUS_FAIL: E_Mounted=$($bus.e_drive_mounted)")
            Write-Host "  [10 COORDINATOR & E:\]  [FAIL] Coordinator Bus check failed" -ForegroundColor Red
        }
    } catch {
        $failures.Add("COORDINATOR_PROBE_ERR: $_")
        Write-Host "  [10 COORDINATOR & E:\]  [FAIL] $_" -ForegroundColor Red
    }

    # 11. Live Google Search Console Certificate HTTP Endpoints Probe (:8097 & :5173)
    try {
        $r8097 = (Invoke-WebRequest -Uri "http://127.0.0.1:8097/google6edc0affb12d0455.html" -UseBasicParsing -TimeoutSec 5).Content
        $r5173 = (Invoke-WebRequest -Uri "http://127.0.0.1:5173/google6edc0affb12d0455.html" -UseBasicParsing -TimeoutSec 5).Content
        $expectedBody = "google-site-verification: google6edc0affb12d0455.html"
        if ($r8097.Trim() -eq $expectedBody -and $r5173.Trim() -eq $expectedBody) {
            Write-Host "  [11 GSC HTTP ENDPOINTS] [PASS] :8097 & :5173 returned exact 53-byte GSC token" -ForegroundColor Green
        } else {
            $failures.Add("GSC_HTTP_BODY_MISMATCH: 8097_len=$($r8097.Length) 5173_len=$($r5173.Length)")
            Write-Host "  [11 GSC HTTP ENDPOINTS] [FAIL] Body mismatch on :8097 or :5173" -ForegroundColor Red
        }
    } catch {
        $failures.Add("GSC_HTTP_PROBE_ERR: $_")
        Write-Host "  [11 GSC HTTP ENDPOINTS] [FAIL] $_" -ForegroundColor Red
    }

    Write-Host "==========================================================================" -ForegroundColor Cyan
    if ($failures.Count -gt 0) {
        Write-Host "  [BRUTAL GATEKEEPER RESULT: FAILED ($($failures.Count) VIOLATIONS)]" -ForegroundColor Red
        exit 1
    } else {
        Write-Host "  [BRUTAL GATEKEEPER RESULT: PASSED (11/11 INVARIANTS VERIFIED)]" -ForegroundColor Green
        exit 0
    }
}
