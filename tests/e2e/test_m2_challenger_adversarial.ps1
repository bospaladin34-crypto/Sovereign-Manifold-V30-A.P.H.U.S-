# ==============================================================================
# ACT-OMEGA NET v49.0.0 — MILESTONE 2: ADVERSARIAL CHALLENGER VERIFICATION SUITE
# Challenger M2-1: Mathematical Parity, Lean 4 Rigor & Admin Security Fuzzing
# File: C:\sovereign_manifold_v31\tests\e2e\test_m2_challenger_adversarial.ps1
# STRICT ZERO-PYTHON MANDATE | ZERO-UNMEASURED DATA MANDATE
# ==============================================================================

$ErrorActionPreference = "Stop"
$RepoRoot = "C:\sovereign_manifold_v31"
$BaseSwarmUrl = "http://127.0.0.1:8097"
$PassCount = 0
$FailCount = 0
$Findings = @()

function Report-Pass($desc) {
    Write-Host "  [PASS] $desc" -ForegroundColor Green
    $global:PassCount++
}

function Report-Fail($desc, $details) {
    Write-Host "  [FAIL] $desc" -ForegroundColor Red
    Write-Host "         Details: $details" -ForegroundColor DarkYellow
    $global:FailCount++
    $global:Findings += [PSCustomObject]@{
        Test = $desc
        Details = $details
    }
}

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "   MILESTONE 2: ADVERSARIAL CHALLENGER M2-1 RIGOR & SECURITY PROBE        " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan

# ------------------------------------------------------------------------------
# SECTION 1: PLÜCKER 6D CPU FALLBACK & MATHEMATICAL PARITY
# ------------------------------------------------------------------------------
Write-Host "`n--- [SECTION 1] Plücker 6D CPU Fallback & Mathematical Parity ---" -ForegroundColor Yellow

# Test 1.1: Run the node mathematical stress test engine
try {
    $nodeOut = & node "$RepoRoot\tests\e2e\stress_plucker_parity.mjs" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Report-Pass "Plücker 6D stress engine (matrix parity, quadric form, edge cases, e8z) passed cleanly"
    } else {
        Report-Fail "Plücker 6D stress engine failed" ($nodeOut -join "`n")
    }
} catch {
    Report-Fail "Could not execute node stress_plucker_parity.mjs" $_.Exception.Message
}

# Test 1.2: Check App.tsx AST in 05_hud_cockpit and 02_l2_orchestration
$app1 = "$RepoRoot\05_hud_cockpit\src\App.tsx"
$app2 = "$RepoRoot\02_l2_orchestration\hud\src\App.tsx"

if ((Test-Path $app1) -and (Test-Path $app2)) {
    $h1 = (Get-FileHash $app1).Hash
    $h2 = (Get-FileHash $app2).Hash
    if ($h1 -eq $h2) {
        Report-Pass "App.tsx hash parity between 05_hud_cockpit and 02_l2_orchestration ($h1)"
    } else {
        Report-Fail "App.tsx hash mismatch between 05_hud_cockpit and 02_l2_orchestration" "h1=$h1, h2=$h2"
    }

    $c1 = Get-Content -Raw $app1
    # Verify zero synthetic sin/cos loop
    if ($c1 -match "Math\.sin\(i\s*\*\s*0\.015965\)") {
        Report-Fail "Synthetic Math.sin loop still present in App.tsx" "Matched Math.sin(i * 0.015965)"
    } else {
        Report-Pass "Synthetic Math.sin(i * 0.015965) completely purged from App.tsx"
    }

    # Verify Plücker formula in App.tsx
    if ($c1 -match "v_a0\s*\*\s*v_b5\s*-\s*v_a1\s*\*\s*v_b4\s*\+\s*v_a2\s*\*\s*v_b3\s*\+\s*v_a3\s*\*\s*v_b2\s*-\s*v_a4\s*\*\s*v_b1\s*\+\s*v_a5\s*\*\s*v_b0") {
        Report-Pass "Exact 6D Plücker quadratic inner product formula present in App.tsx"
    } else {
        Report-Fail "Plücker 6D formula mismatch in App.tsx" "Regex did not find exact algebraic signs (+ - + + - +)"
    }

    # Verify digest discrimination
    if ($c1 -match "_CPU_E8_PLUCKER_6D_INNER_MEASURED" -and $c1 -match "_PLUCKER_POS_QED") {
        Report-Pass "Strict compute tier discrimination: _CPU_E8_PLUCKER_6D_INNER_MEASURED vs _PLUCKER_POS_QED"
    } else {
        Report-Fail "Missing compute tier digest labels in App.tsx" "Check _CPU_E8_PLUCKER_6D_INNER_MEASURED"
    }

    # Verify initial state at line 610
    if ($c1 -match 'useState<string>\("0xFC6EB2_CPU_E8_PLUCKER_6D_INNER_MEASURED"\)') {
        Report-Pass "Initial webgpuPocHash state labeled with _CPU_E8_PLUCKER_6D_INNER_MEASURED"
    } else {
        Report-Fail "Initial webgpuPocHash state not updated" "Expected 0xFC6EB2_CPU_E8_PLUCKER_6D_INNER_MEASURED"
    }
} else {
    Report-Fail "App.tsx files missing" "Checked $app1 and $app2"
}


# ------------------------------------------------------------------------------
# SECTION 2: LEAN 4 FORMAL PROOF RIGOR & UNIVERSAL QUANTIFICATION
# ------------------------------------------------------------------------------
Write-Host "`n--- [SECTION 2] Lean 4 Formal Proof Rigor (Theorems 433..460) ---" -ForegroundColor Yellow

$leanExe = "C:\Users\Nbell\.elan\bin\lean.exe"
$leanFiles = @(
    "$RepoRoot\03_vault\lean4\SovereignManifoldTheorems.lean",
    "$RepoRoot\01_l0_rust\lean4\SovereignManifoldTheorems.lean"
)

foreach ($lf in $leanFiles) {
    $shortName = [System.IO.Path]::GetFileName([System.IO.Path]::GetDirectoryName($lf)) + "\" + [System.IO.Path]::GetFileName($lf)
    if (-not (Test-Path $lf)) {
        Report-Fail "Lean 4 theorem file missing: $shortName" "File not found"
        continue
    }

    # Lean compilation check
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $leanOut = & $leanExe $lf 2>&1
    $sw.Stop()
    if ($LASTEXITCODE -eq 0) {
        Report-Pass "Lean 4 kernel compiled $shortName cleanly with 0 errors in $([math]::Round($sw.Elapsed.TotalSeconds, 2))s"
    } else {
        Report-Fail "Lean 4 compilation failed for $shortName" ($leanOut -join "`n")
    }

    $raw = Get-Content -Raw $lf

    # Check for sorry / admit / axiom in the file
    $hasSorry = [regex]::IsMatch($raw, '\b(sorry|admit)\b')
    if (-not $hasSorry) {
        Report-Pass "Zero sorry or admit axioms in $shortName"
    } else {
        Report-Fail "Found sorry or admit axioms in $shortName" "Check file for sorry/admit"
    }

    # Verify total theorem count >= 460
    $thmMatches = [regex]::Matches($raw, '(?m)^theorem\s+([A-Za-z0-9_]+)')
    $thmCount = $thmMatches.Count
    if ($thmCount -ge 460) {
        Report-Pass "Theorem count in $shortName = $thmCount (>= 460 required)"
    } else {
        Report-Fail "Theorem count below 460 in $shortName" "Found $thmCount"
    }

    # Verify theorems 433..460 specifically
    $v48_433_440 = 433..440 | ForEach-Object { "thm_v48_$_" }
    $v49_441_460 = 441..460 | ForEach-Object { "thm_v49_$_" }
    $targetTheorems = @($v48_433_440) + @($v49_441_460)

    $missingTheorems = @()
    $trivialConstantTheorems = @()
    $nonUniversalTheorems = @()

    foreach ($tName in $targetTheorems) {
        $pattern = "(?m)^theorem\s+${tName}(?:_[a-zA-Z0-9_]+)?\b[^\n]+"
        $m = [regex]::Match($raw, $pattern)
        if (-not $m.Success) {
            $missingTheorems += $tName
        } else {
            $line = $m.Value
            # Check for constant tautology: ":= by exact And.intro rfl" or ":= by rfl" without parameters
            if ($line -match ':=\s*by\s*(exact\s+)?(And\.intro\s+)?rfl' -and -not ($line -match '\([a-zA-Z0-9_\s]+:\s*Nat\)')) {
                $trivialConstantTheorems += $tName
            }
            # Check for universal quantification: must take at least one parameter like (k : Nat), (x : Nat), (col : Nat), etc.
            if (-not ($line -match '\([a-zA-Z0-9_\s]+:\s*Nat\)')) {
                $nonUniversalTheorems += $tName
            }
        }
    }

    if ($missingTheorems.Count -eq 0) {
        Report-Pass "All 28 target theorems (433..460) present in $shortName"
    } else {
        Report-Fail "Missing target theorems in $shortName" ($missingTheorems -join ", ")
    }

    if ($trivialConstantTheorems.Count -eq 0) {
        Report-Pass "Zero trivial constant (N = N) rfl theorems in 433..460 ($shortName)"
    } else {
        Report-Fail "Found trivial constant theorems in 433..460" ($trivialConstantTheorems -join ", ")
    }

    if ($nonUniversalTheorems.Count -eq 0) {
        Report-Pass "All 28 theorems (433..460) are universally quantified with typed parameters ($shortName)"
    } else {
        Report-Fail "Found non-universally-quantified theorems in 433..460" ($nonUniversalTheorems -join ", ")
    }
}

# Check Haskell Codegen files
$hsGen = "$RepoRoot\06_algebraic_haskell\src\Sovereign\Codegen\ZeroBracketRustAndLean4.hs"
if (Test-Path $hsGen) {
    $hsRaw = Get-Content -Raw $hsGen
    if ($hsRaw -match "forall|Nat\.mul_comm|omega|Nat\.mul_add") {
        Report-Pass "Haskell codegen contains universal structural theorem emitters"
    } else {
        Report-Fail "Haskell codegen missing universal structural theorem emitters" "Check $hsGen"
    }
}


# ------------------------------------------------------------------------------
# SECTION 3: ADMIN ENDPOINT SECURITY ADVERSARIAL STRESS & FUZZING
# ------------------------------------------------------------------------------
Write-Host "`n--- [SECTION 3] Admin Endpoint Security Adversarial Fuzzing ---" -ForegroundColor Yellow

function Invoke-RawAdminProbe($endpoint, $headerValue = $null, $method = "GET") {
    try {
        $client = New-Object System.Net.Sockets.TcpClient("127.0.0.1", 8097)
        $client.ReceiveTimeout = 4000
        $client.SendTimeout = 4000
        $stream = $client.GetStream()
        $req = "$method $endpoint HTTP/1.1`r`nHost: 127.0.0.1:8097`r`nConnection: close`r`n"
        if ($null -ne $headerValue) {
            $req += "X-Sovereign-Operator-Key: $headerValue`r`n"
        }
        $req += "`r`n"
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($req)
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Flush()
        $reader = New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::UTF8)
        $statusLine = $reader.ReadLine()
        $statusCode = 0
        if ($statusLine -match 'HTTP/1\.[01]\s+(\d{3})') {
            $statusCode = [int]$matches[1]
        }
        $body = $reader.ReadToEnd()
        $client.Close()
        return [PSCustomObject]@{
            StatusCode = $statusCode
            Body = $body
        }
    } catch {
        return [PSCustomObject]@{
            StatusCode = 0
            Body = $_.Exception.Message
        }
    }
}

function Invoke-AdminProbe($endpoint, $headerValue = $null, $method = "GET") {
    $uri = "$BaseSwarmUrl$endpoint"
    try {
        $headers = @{}
        if ($null -ne $headerValue) {
            $headers["X-Sovereign-Operator-Key"] = $headerValue
        }
        $res = Invoke-WebRequest -Uri $uri -Method $method -Headers $headers -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
        return [PSCustomObject]@{
            StatusCode = [int]$res.StatusCode
            Body = $res.Content
        }
    } catch [System.Net.WebException] {
        $resp = $_.Exception.Response
        if ($null -ne $resp) {
            $reader = New-Object System.IO.StreamReader($resp.GetResponseStream())
            $body = $reader.ReadToEnd()
            return [PSCustomObject]@{
                StatusCode = [int]$resp.StatusCode
                Body = $body
            }
        }
        return Invoke-RawAdminProbe $endpoint $headerValue $method
    } catch {
        # Fallback to raw TCP socket probe if .NET client library rejects malformed headers
        return Invoke-RawAdminProbe $endpoint $headerValue $method
    }
}

# Test 3.1: Completely unauthenticated request to /api/v1/admin/self_exit
$probe1 = Invoke-AdminProbe "/api/v1/admin/self_exit"
if ($probe1.StatusCode -eq 403) {
    Report-Pass "Unauthenticated GET /api/v1/admin/self_exit strictly returns 403 Forbidden"
} else {
    Report-Fail "Unauthenticated GET /api/v1/admin/self_exit did not return 403" "Returned $($probe1.StatusCode)"
}

# Test 3.2: Forged / Wrong Keys
$forgedKeys = @(
    "invalid_secret_key_12345",
    "SOVEREIGN-LOQ15-4200",      # Leaked legacy key
    "admin",
    "root",
    "12345678",
    "bearer_token_xyz",
    "ACT_OMEGA_SUPERUSER"
)

$forgedFailures = @()
foreach ($fk in $forgedKeys) {
    $res = Invoke-AdminProbe "/api/v1/admin/self_exit" -headerValue $fk
    if ($res.StatusCode -ne 403) {
        $forgedFailures += "$fk -> Status $($res.StatusCode)"
    }
}
if ($forgedFailures.Count -eq 0) {
    Report-Pass "All forged/incorrect keys strictly rejected with 403 Forbidden ($($forgedKeys.Count) test cases)"
} else {
    Report-Fail "Forged keys not rejected with 403" ($forgedFailures -join "; ")
}

# Test 3.3: Empty & Whitespace Keys
$emptyKeys = @(
    "",
    " ",
    "   ",
    "`t",
    "`r`n"
)
$emptyFailures = @()
foreach ($ek in $emptyKeys) {
    $res = Invoke-AdminProbe "/api/v1/admin/self_exit" -headerValue $ek
    if ($res.StatusCode -ne 403) {
        $emptyFailures += "[$ek] -> Status $($res.StatusCode)"
    }
}
if ($emptyFailures.Count -eq 0) {
    Report-Pass "All empty/whitespace keys strictly rejected with 403 Forbidden ($($emptyKeys.Count) test cases)"
} else {
    Report-Fail "Empty/whitespace keys not rejected with 403" ($emptyFailures -join "; ")
}

# Test 3.4: Extremely Long Keys (Buffer overflow & DoS stress)
$longKeys = @(
    ("A" * 512),
    ("B" * 2048),
    ("C" * 8192),
    ("D" * 32768)
)
$longFailures = @()
foreach ($lk in $longKeys) {
    $res = Invoke-AdminProbe "/api/v1/admin/self_exit" -headerValue $lk
    if ($res.StatusCode -ne 403) {
        $longFailures += "Len $($lk.Length) -> Status $($res.StatusCode)"
    }
}
if ($longFailures.Count -eq 0) {
    Report-Pass "Extremely long keys (up to 32KB) safely handled with 403 Forbidden without crash ($($longKeys.Count) test cases)"
} else {
    Report-Fail "Long keys failed or crashed" ($longFailures -join "; ")
}

# Test 3.5: Injection Payloads (SQLi, Command Injection, Special Chars)
$injectionKeys = @(
    "' OR '1'='1",
    "'; DROP TABLE edge_heartbeat; --",
    "; calc.exe ;",
    "| dir |",
    "& echo hacked",
    "`$((Get-Process).Count)",
    "{`"key`": `"admin`"}",
    "<script>alert(1)</script>",
    "admin`0hidden",
    ([char]::ConvertFromUtf32(0x1F511) + "_SOVEREIGN_UNICODE_KEY"),
    "../../etc/passwd"
)
$injectionFailures = @()
foreach ($ik in $injectionKeys) {
    $res = Invoke-AdminProbe "/api/v1/admin/self_exit" -headerValue $ik
    if ($res.StatusCode -ne 403) {
        $injectionFailures += "$ik -> Status $($res.StatusCode)"
    }
}
if ($injectionFailures.Count -eq 0) {
    Report-Pass "All injection payloads (SQL, CMD, null-bytes, unicode) strictly rejected with 403 Forbidden ($($injectionKeys.Count) cases)"
} else {
    Report-Fail "Injection payloads not rejected with 403" ($injectionFailures -join "; ")
}

# Test 3.6: URL Query Parameter Credential Leak Attempt (MUST BE REJECTED)
$queryParamAttempts = @(
    "/api/v1/admin/self_exit?key=invalid",
    "/api/v1/admin/self_exit?key=SOVEREIGN-LOQ15-4200",
    "/api/v1/admin/self_exit?key=",
    "/api/v1/admin/status?key=secret",
    "/api/v1/admin/audit?key=test"
)
$queryFailures = @()
foreach ($qp in $queryParamAttempts) {
    $res = Invoke-AdminProbe $qp
    if ($res.StatusCode -ne 403) {
        $queryFailures += "$qp -> Status $($res.StatusCode)"
    }
}
if ($queryFailures.Count -eq 0) {
    Report-Pass "URL query parameter '?key=' attempts strictly rejected with 403 Forbidden ($($queryParamAttempts.Count) cases)"
} else {
    Report-Fail "URL query parameter '?key=' not rejected with 403" ($queryFailures -join "; ")
}

# Test 3.7: Arbitrary Sub-routes under /api/v1/admin/
$adminSubRoutes = @(
    "/api/v1/admin/",
    "/api/v1/admin/status",
    "/api/v1/admin/settings",
    "/api/v1/admin/vault_dump",
    "/api/v1/admin/reboot",
    "/api/v1/admin/nonexistent_subroute_42"
)
$subRouteFailures = @()
foreach ($sr in $adminSubRoutes) {
    $res = Invoke-AdminProbe $sr
    if ($res.StatusCode -ne 403) {
        $subRouteFailures += "$sr -> Status $($res.StatusCode)"
    }
}
if ($subRouteFailures.Count -eq 0) {
    Report-Pass "All /api/v1/admin/* sub-routes strictly protected by 403 Forbidden gate ($($adminSubRoutes.Count) routes)"
} else {
    Report-Fail "/api/v1/admin/* sub-route not protected by 403" ($subRouteFailures -join "; ")
}

# Test 3.8: Non-GET HTTP Methods to /api/v1/admin/self_exit
$httpMethods = @("POST", "PUT", "DELETE")
$methodFailures = @()
foreach ($hm in $httpMethods) {
    $res = Invoke-AdminProbe "/api/v1/admin/self_exit" -method $hm
    if ($res.StatusCode -ne 403 -and $res.StatusCode -ne 405) {
        $methodFailures += "$hm -> Status $($res.StatusCode)"
    }
}
if ($methodFailures.Count -eq 0) {
    Report-Pass "Non-GET HTTP methods to /api/v1/admin/self_exit strictly return 403/405 without leak"
} else {
    Report-Fail "Non-GET HTTP methods returned unexpected status" ($methodFailures -join "; ")
}

# Test 3.9: Daemon Liveness Verification Post-Stress
$liveRes = Invoke-AdminProbe "/api/v1/auth/operator_vault_gate"
if ($liveRes.StatusCode -eq 200) {
    Report-Pass "Swarm daemon healthy and responsive after adversarial fuzzing battery"
} else {
    Report-Fail "Swarm daemon unresponsive after adversarial fuzzing" "Status $($liveRes.StatusCode)"
}


# ------------------------------------------------------------------------------
# SECTION 4: SECURITY HYGIENE & ZERO-BRACKET INVARIANT AUDIT
# ------------------------------------------------------------------------------
Write-Host "`n--- [SECTION 4] Security Hygiene & Zero-Bracket Verification ---" -ForegroundColor Yellow

# Test 4.1: Root HTML Passkey Purge
$htmlFiles = @("$RepoRoot\index.html", "$RepoRoot\wiki.html")
$passkeyHits = 0
foreach ($hf in $htmlFiles) {
    if (Test-Path $hf) {
        $count = @(Select-String -Path $hf -Pattern "SOVEREIGN-LOQ15-4200" -ErrorAction SilentlyContinue).Count
        $passkeyHits += $count
    }
}
if ($passkeyHits -eq 0) {
    Report-Pass "Strict zero hardcoded passkey 'SOVEREIGN-LOQ15-4200' in index.html & wiki.html"
} else {
    Report-Fail "Found $passkeyHits occurrences of SOVEREIGN-LOQ15-4200 in HTML files" "Check index.html/wiki.html"
}

# Test 4.2: Zero square brackets in v42_distributed_5w1h_router_ide_vault.rs
$v42Path = "$RepoRoot\01_l0_rust\src\v42_distributed_5w1h_router_ide_vault.rs"
if (Test-Path $v42Path) {
    $bytes = [System.IO.File]::ReadAllBytes($v42Path)
    $bracketCount = ($bytes | Where-Object { $_ -eq 91 -or $_ -eq 93 }).Count
    if ($bracketCount -eq 0) {
        Report-Pass "Strict zero square brackets in v42_distributed_5w1h_router_ide_vault.rs ($($bytes.Length) bytes, 0 brackets)"
    } else {
        Report-Fail "Square brackets detected in v42_distributed_5w1h_router_ide_vault.rs" "Count: $bracketCount"
    }
} else {
    Report-Fail "v42_distributed_5w1h_router_ide_vault.rs missing" "File not found"
}

# Test 4.3: HUD Cockpit Build Verification
try {
    $swBuild = [System.Diagnostics.Stopwatch]::StartNew()
    $buildOut = & npm --prefix "$RepoRoot\05_hud_cockpit" run build 2>&1
    $swBuild.Stop()
    if ($LASTEXITCODE -eq 0) {
        Report-Pass "HUD Cockpit built cleanly via npm run build in $([math]::Round($swBuild.Elapsed.TotalSeconds, 2))s"
    } else {
        Report-Fail "HUD Cockpit npm run build failed" ($buildOut -join "`n")
    }
} catch {
    Report-Fail "Could not execute npm run build for HUD Cockpit" $_.Exception.Message
}


# ------------------------------------------------------------------------------
# SUMMARY & VERDICT
# ------------------------------------------------------------------------------
Write-Host "`n==========================================================================" -ForegroundColor Cyan
Write-Host "   CHALLENGER M2-1 SUMMARY: $PassCount PASSED, $FailCount FAILED         " -ForegroundColor $(if($FailCount -eq 0){"Green"}else{"Red"})
Write-Host "==========================================================================" -ForegroundColor Cyan

if ($FailCount -gt 0) {
    Write-Host "`nFAILED TESTS:" -ForegroundColor Red
    foreach ($f in $Findings) {
        Write-Host "  - $($f.Test): $($f.Details)" -ForegroundColor DarkYellow
    }
    Write-Host "`nVERDICT: REQUEST_CHANGES" -ForegroundColor Red
    exit 1
} else {
    Write-Host "`nVERDICT: APPROVE (ALL ADVERSARIAL STRESS CHALLENGES MET WITH 100% RIGOR)" -ForegroundColor Green
    exit 0
}
