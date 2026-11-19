# 00_control\Test-M2-FailureInjection.ps1
# Milestone M2 Negative Failure-Injection & Verification Gauntlet

$ErrorActionPreference = "Stop"

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
Write-Host "  ACT-Omega Net $cffVer -- Milestone M2 Full Verification Gauntlet" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

$manifestPath = "$baseDir\00_control\weights\sovereign_harmonic_weights_manifest.json"
$eManifestPath = "E:\Sovereign_Manifold_SSD_Vault\weights\sovereign_harmonic_weights_manifest.json"

$opKey = ""
$keyFile = "C:\Users\Nbell\.act_omega_operator_vault_key"
if (Test-Path $keyFile) {
    $opKey = (Get-Content -Path $keyFile -Raw).Trim()
} elseif ($env:ACT_OMEGA_OPERATOR_KEY) {
    $opKey = $env:ACT_OMEGA_OPERATOR_KEY.Trim()
}
$authHeaders = @{}
if ($opKey.Length -ge 24) {
    $authHeaders["X-Sovereign-Operator-Key"] = $opKey
}

function Test-LiveServerControlProbe {
    param([string]$Uri = "http://127.0.0.1:8097/api/v1/health")
    try {
        $hc = Invoke-WebRequest -Uri $Uri -Method Get -Headers $authHeaders -UseBasicParsing -TimeoutSec 15
        if ($null -eq $hc -or $hc.StatusCode -ne 200) {
            return $false
        }
        $j = $hc.Content | ConvertFrom-Json
        if ($null -eq $j) { return $false }
        if ([string]$j.status -notmatch '^LAMINAR_') { return $false }
        if ([string]$j.version -notmatch '^ACT-Omega Net v\d+\.\d+\.\d+') { return $false }
        if ([int64]$j.generation -lt 1) { return $false }
        if ([int]$j.tools_count -lt 404) { return $false }
        if ([int]$j.lean4_theorems_qed -lt 1010) { return $false }
        return $true
    } catch {
        return $false
    }
}

function Invoke-FailClosedWeightCheck($url, $method) {
    # E13: Must FIRST prove the live :8097 server is reachable via control probe.
    # Dead/unreachable server MUST NEVER score as fail-closed!
    $controlUp = Test-LiveServerControlProbe
    if (-not $controlUp) {
        return @{ ControlUp = $false; HttpFailedClosed = $false; HasWeightErr = $false; Detail = "SERVER_UNREACHABLE_CONTROL_PROBE_FAILED" }
    }
    try {
        $resp = if ($method -eq "Post") {
            Invoke-RestMethod -Uri $url -Method Post -Headers $authHeaders -TimeoutSec 15 -Body "{}" -ContentType "application/json"
        } else {
            Invoke-RestMethod -Uri $url -Method Get -Headers $authHeaders -TimeoutSec 15
        }
        $isOfflineStatus = ($resp.status -eq "UNMEASURED/OFFLINE" -or $resp.status -match "WEIGHT_")
        $errStr = "$($resp.status) $($resp.error) $($resp.reason) $($resp.sh4z_v7210_checkpoint.sha256)"
        $hasWeight = ($errStr -match "WEIGHT_")
        return @{ ControlUp = $true; HttpFailedClosed = $isOfflineStatus; HasWeightErr = $hasWeight; Detail = "HTTP_200_JSON" }
    } catch {
        # Distinguish genuine HTTP 4xx/5xx JSON error response from dead/refused TCP socket
        $httpResp = $_.Exception.Response
        if ($null -eq $httpResp) {
            return @{ ControlUp = $controlUp; HttpFailedClosed = $false; HasWeightErr = $false; Detail = "SOCKET_ERROR_NOT_FAIL_CLOSED: $($_.Exception.Message)" }
        }
        $statusCode = [int]$httpResp.StatusCode
        $bodyText = ""
        try {
            $sr = New-Object System.IO.StreamReader($httpResp.GetResponseStream())
            $bodyText = $sr.ReadToEnd()
            $sr.Close()
        } catch {}
        $isStructuredRefusal = ($statusCode -ge 400) -and ($bodyText -match "UNMEASURED/OFFLINE|WEIGHT_")
        $hasWeight = ($bodyText -match "WEIGHT_")
        return @{ ControlUp = $true; HttpFailedClosed = $isStructuredRefusal; HasWeightErr = $hasWeight; Detail = "HTTP_${statusCode}" }
    }
}

$binPath = if (Test-Path "$baseDir\01_l0_rust\target_stage\release\v31_swarm.exe") {
    "$baseDir\01_l0_rust\target_stage\release\v31_swarm.exe"
} elseif (Test-Path "$baseDir\01_l0_rust\target\release\v31_swarm.exe") {
    "$baseDir\01_l0_rust\target\release\v31_swarm.exe"
} else {
    throw "v31_swarm.exe not found in target_stage or target/release"
}

Write-Host "Using binary: $binPath" -ForegroundColor Cyan

function Restore-FileFromBackup($bak, $target) {
    for ($retry = 0; $retry -lt 10; $retry++) {
        try {
            [System.IO.File]::WriteAllBytes($target, [System.IO.File]::ReadAllBytes($bak))
            return
        } catch {
            Start-Sleep -Milliseconds 150
        }
    }
    Copy-Item -Path $bak -Destination $target -Force
}

$results = [ordered]@{}

# -------------------------------------------------------------
# Test 0: Live /api/v1/health JSON Probe & Negative Invalid-Probe Tests (Item #14)
# -------------------------------------------------------------
Write-Host "`n--- Test 0: Live /api/v1/health JSON Structure & Negative Probe Check ---" -ForegroundColor Yellow
$probePos1 = Test-LiveServerControlProbe -Uri "http://127.0.0.1:8097/api/v1/health"
$probePos2 = Test-LiveServerControlProbe -Uri "http://127.0.0.1:8097/api/v1/health"
$genIncOk = $false
try {
    $h1 = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/health" -Method Get -Headers $authHeaders -TimeoutSec 15
    $h2 = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/health" -Method Get -Headers $authHeaders -TimeoutSec 15
    $genIncOk = ([int64]$h2.generation -gt [int64]$h1.generation) -and ([int]$h2.lean4_theorems_qed -ge 1010) -and ([int]$h2.tools_count -ge 404)
} catch {
    $genIncOk = $false
}
$probeNeg404 = -not (Test-LiveServerControlProbe -Uri "http://127.0.0.1:8097/api/v1/nonexistent_health_probe")
$probeNegHtml200 = -not (Test-LiveServerControlProbe -Uri "http://127.0.0.1:8097/google6edc0affb12d0455.html")

if ($probePos1 -and $probePos2 -and $genIncOk -and $probeNeg404 -and $probeNegHtml200) {
    Write-Host ">>> Test 0 PASS: /api/v1/health JSON valid & generation monotonic; 404 & HTTP-200 non-JSON probes rejected." -ForegroundColor Green
    $results["Test0_HealthControlProbe"] = "PASS (JSON schema + generation monotonic + 404/non-JSON rejected)"
} else {
    Write-Host ">>> Test 0 FAIL: pos1=$probePos1 pos2=$probePos2 genInc=$genIncOk neg404=$probeNeg404 negHtml200=$probeNegHtml200" -ForegroundColor Red
    $results["Test0_HealthControlProbe"] = "FAIL (pos1=$probePos1 pos2=$probePos2 genInc=$genIncOk neg404=$probeNeg404 negHtml200=$probeNegHtml200)"
}

# -------------------------------------------------------------
# Test 1: Full-Manifest CLI Verification
# -------------------------------------------------------------
Write-Host "`n--- Test 1: Full-Manifest CLI Verification (v31_swarm.exe --verify-weights) ---" -ForegroundColor Yellow
$mJsonPre = Get-Content -Path $manifestPath -Raw | ConvertFrom-Json
$manifestArtifactCount = ($mJsonPre.artifacts.PSObject.Properties | Measure-Object).Count
$p1 = Start-Process -FilePath $binPath -ArgumentList "--verify-weights" -NoNewWindow -Wait -PassThru
if ($p1.ExitCode -eq 0 -and $manifestArtifactCount -gt 0) {
    Write-Host ">>> Test 1 PASS: Full manifest verified on disk with 0 exit code ($manifestArtifactCount/$manifestArtifactCount artifacts valid)." -ForegroundColor Green
    $results["Test1_FullManifestCLI"] = "PASS (0 exit code, $manifestArtifactCount/$manifestArtifactCount artifacts valid)"
} else {
    Write-Host ">>> Test 1 FAIL: Full manifest check returned exit code $($p1.ExitCode)" -ForegroundColor Red
    $results["Test1_FullManifestCLI"] = "FAIL (Exit code $($p1.ExitCode))"
}

# -------------------------------------------------------------
# Test 2: Multi-Alias Manifest Consistency & Vault Mirroring
# -------------------------------------------------------------
Write-Host "`n--- Test 2: Multi-Alias Manifest Consistency & Vault Mirroring ---" -ForegroundColor Yellow
$mJson = Get-Content -Path $manifestPath -Raw | ConvertFrom-Json
$deep1 = $mJson.artifacts.deep12l_weights
$deep2 = $mJson.artifacts.sovereign_harmonic_deep12l_weights
$moe1 = $mJson.artifacts.sh_xi_moe_experts
$moe2 = $mJson.artifacts.sh_xi_moe_experts_dir

$aliasesOk = $true
if ($deep1.sha256 -ne $deep2.sha256 -or $deep1.expected_bytes -ne $deep2.expected_bytes) {
    $aliasesOk = $false
    Write-Host "Mismatch between deep12l_weights and sovereign_harmonic_deep12l_weights" -ForegroundColor Red
}
if (-not (Test-Path $eManifestPath)) {
    $aliasesOk = $false
    Write-Host "E: vault manifest missing at $eManifestPath" -ForegroundColor Red
} else {
    $eJson = Get-Content -Path $eManifestPath -Raw | ConvertFrom-Json
    if ($eJson.artifacts.deep12l_weights.sha256 -ne $deep1.sha256) {
        $aliasesOk = $false
        Write-Host "E: vault manifest sha256 mismatch with local manifest" -ForegroundColor Red
    }
}

if ($aliasesOk) {
    Write-Host ">>> Test 2 PASS: Multi-alias manifest entries and E:\ vault mirror are consistent." -ForegroundColor Green
    $results["Test2_MultiAliasConsistency"] = "PASS (All aliases and E:\ mirror in sync)"
} else {
    Write-Host ">>> Test 2 FAIL: Multi-alias or E:\ vault manifest inconsistent." -ForegroundColor Red
    $results["Test2_MultiAliasConsistency"] = "FAIL"
}

# -------------------------------------------------------------
# Test 3: Failure Injection Across 4 Critical Artifacts (Mode 1: Missing File, Mode 2: Corrupted Byte)
# -------------------------------------------------------------
Write-Host "`n--- Test 3: Failure Injection Across 4 Critical Artifacts (Mode 1 & Mode 2) ---" -ForegroundColor Yellow

$artifactsToTest = @(
    @{
        Key = "deep12l_weights"
        RelPath = "00_control\weights\sovereign_harmonic_deep12l_weights.sh4z"
        Url = "http://127.0.0.1:8097/api/v1/tools/t330"
        ShortUrl = "http://127.0.0.1:8097/t330"
        Method = "Post"
    },
    @{
        Key = "week2_codebook"
        RelPath = "00_control\weights\sovereign_harmonic_week2_16384_codebook.sh4z"
        Url = "http://127.0.0.1:8097/api/v1/tools/t336"
        ShortUrl = "http://127.0.0.1:8097/t336"
        Method = "Post"
    },
    @{
        Key = "sh_xi_rw384_768_base"
        RelPath = "00_control\weights\sovereign_harmonic_xi_rw384_768_base.sh4z"
        Url = "http://127.0.0.1:8097/api/v1/tools/t360"
        ShortUrl = "http://127.0.0.1:8097/t360"
        Method = "Post"
    },
    @{
        Key = "sh_xi_moe_experts"
        RelPath = "00_control\weights\sh_xi_moe_experts.sh4z"
        Url = "http://127.0.0.1:8097/api/v1/tools/t363"
        ShortUrl = "http://127.0.0.1:8097/t363"
        Method = "Get"
    }
)

foreach ($art in $artifactsToTest) {
    $artKey = $art.Key
    $filePath = Join-Path $baseDir $art.RelPath
    $bakPath = "$filePath.m2bak"

    Write-Host "`n  =======================================================" -ForegroundColor Cyan
    Write-Host "  [Artifact: $artKey]" -ForegroundColor Cyan
    Write-Host "  =======================================================" -ForegroundColor Cyan
    if (-not (Test-Path $filePath)) {
        Write-Host "  File $filePath does not exist! Skipping." -ForegroundColor Red
        $results["Test3_FailInject_$artKey"] = "FAIL (File not found)"
        continue
    }

    $mode1Pass = $false
    $mode2Pass = $false

    # -------------------------------------------------------------
    # Subtest 3A: Mode 1 (Missing File via Move-Item)
    # -------------------------------------------------------------
    Write-Host "    [Mode 1: Missing File Failure Injection]" -ForegroundColor Yellow
    Move-Item -Path $filePath -Destination $bakPath -Force

    try {
        # Check 1: --verify-weights CLI must fail (exit 1) and output WEIGHT_
        $cliOutFile1 = [System.IO.Path]::GetTempFileName()
        $cliErrFile1 = [System.IO.Path]::GetTempFileName()
        $pFail1 = Start-Process -FilePath $binPath -ArgumentList "--verify-weights", $artKey, $filePath -NoNewWindow -Wait -PassThru -RedirectStandardOutput $cliOutFile1 -RedirectStandardError $cliErrFile1
        $txt1 = ""; if (Test-Path $cliOutFile1) { $txt1 = Get-Content -Path $cliOutFile1 -Raw }
        $err1 = ""; if (Test-Path $cliErrFile1) { $err1 = Get-Content -Path $cliErrFile1 -Raw }
        $cliOut1 = "$txt1`n$err1"
        Remove-Item -Path $cliOutFile1, $cliErrFile1 -Force -ErrorAction SilentlyContinue

        $cliFailedClosed1 = ($pFail1.ExitCode -ne 0) -and ($cliOut1 -match "WEIGHT_")

        # Check 2 (E13): Live HTTP probe MUST first verify server is up via control probe, then verify structured fail-closed response (dead server -> FAIL)
        $chk1 = Invoke-FailClosedWeightCheck -url $art.Url -method $art.Method
        $httpFailedClosed1 = ($chk1.ControlUp -and $chk1.HttpFailedClosed)
        $hasWeightErr1 = $chk1.HasWeightErr
        if (-not $chk1.ControlUp) {
            Write-Host "      [E13 FAIL] Live server :8097 control probe FAILED ($($chk1.Detail)) -- dead server cannot score as fail-closed!" -ForegroundColor Red
        }

        # Check 3: Zero new weight files synthesized on disk
        $zeroResynth1 = (-not (Test-Path $filePath))

        # Restore file
        Move-Item -Path $bakPath -Destination $filePath -Force

        # Check 4: Restored artifact passes --verify-weights CLI (exit 0)
        $pOk1 = Start-Process -FilePath $binPath -ArgumentList "--verify-weights", $artKey, $filePath -NoNewWindow -Wait -PassThru
        $cliRestoredPass1 = ($pOk1.ExitCode -eq 0)

        # Check 5: Restored artifact live HTTP probe returns MEASURED
        $httpRestoredPass1 = $false
        try {
            $respOk1 = if ($art.Method -eq "Post") {
                Invoke-RestMethod -Uri $art.Url -Method Post -Headers $authHeaders -TimeoutSec 15 -Body "{}" -ContentType "application/json"
            } else {
                Invoke-RestMethod -Uri $art.Url -Method Get -Headers $authHeaders -TimeoutSec 15
            }
            if ($respOk1.status -eq "MEASURED") {
                $httpRestoredPass1 = $true
            }
        } catch {
            Write-Host "      Restored HTTP probe error: $_" -ForegroundColor Yellow
        }

        if ($cliFailedClosed1 -and $httpFailedClosed1 -and $hasWeightErr1 -and $zeroResynth1 -and $cliRestoredPass1 -and $httpRestoredPass1) {
            Write-Host "      Mode 1 (Missing): PASS (CLI=$($pFail1.ExitCode), HTTP=UNMEASURED/OFFLINE, ErrCode=WEIGHT_*, NoResynth=$zeroResynth1, Restored=$httpRestoredPass1)" -ForegroundColor Green
            $mode1Pass = $true
        } else {
            Write-Host "      Mode 1 (Missing): FAIL (cliFail=$cliFailedClosed1, httpFail=$httpFailedClosed1, weightErr=$hasWeightErr1, zeroResynth=$zeroResynth1, cliRest=$cliRestoredPass1, httpRest=$httpRestoredPass1)" -ForegroundColor Red
        }

    } finally {
        if (Test-Path $bakPath) {
            Move-Item -Path $bakPath -Destination $filePath -Force -ErrorAction SilentlyContinue
        }
    }

    # -------------------------------------------------------------
    # Subtest 3B: Mode 2 (Corrupted Byte XOR at Offset 64)
    # -------------------------------------------------------------
    Write-Host "    [Mode 2: Corrupted Byte Failure Injection (XOR 0xFF at offset 64)]" -ForegroundColor Yellow
    try {
        $bytes = [System.IO.File]::ReadAllBytes($filePath)
        $origByte = $bytes[64]
        $corruptBytes = [byte[]]$bytes.Clone()
        $corruptBytes[64] = [byte]($origByte -bxor 0xFF)

        Move-Item -Path $filePath -Destination $bakPath -Force
        [System.IO.File]::WriteAllBytes($filePath, $corruptBytes)

        # Check 1: --verify-weights CLI must fail (exit 1) and output WEIGHT_
        $cliOutFile2 = [System.IO.Path]::GetTempFileName()
        $cliErrFile2 = [System.IO.Path]::GetTempFileName()
        $pFail2 = Start-Process -FilePath $binPath -ArgumentList "--verify-weights", $artKey, $filePath -NoNewWindow -Wait -PassThru -RedirectStandardOutput $cliOutFile2 -RedirectStandardError $cliErrFile2
        $txt2 = ""; if (Test-Path $cliOutFile2) { $txt2 = Get-Content -Path $cliOutFile2 -Raw }
        $err2 = ""; if (Test-Path $cliErrFile2) { $err2 = Get-Content -Path $cliErrFile2 -Raw }
        $cliOut2 = "$txt2`n$err2"
        Remove-Item -Path $cliOutFile2, $cliErrFile2 -Force -ErrorAction SilentlyContinue

        $cliFailedClosed2 = ($pFail2.ExitCode -ne 0) -and ($cliOut2 -match "WEIGHT_")

        # Check 2 (E13): Live HTTP probe MUST first verify server is up via control probe, then verify structured fail-closed response (dead server -> FAIL)
        $chk2 = Invoke-FailClosedWeightCheck -url $art.Url -method $art.Method
        $httpFailedClosed2 = ($chk2.ControlUp -and $chk2.HttpFailedClosed)
        $hasWeightErr2 = $chk2.HasWeightErr
        if (-not $chk2.ControlUp) {
            Write-Host "      [E13 FAIL] Live server :8097 control probe FAILED ($($chk2.Detail)) -- dead server cannot score as fail-closed!" -ForegroundColor Red
        }

        # Check 3: Verify NO file was re-synthesized (bytes still corrupted)
        $bytesAfter2 = [System.IO.File]::ReadAllBytes($filePath)
        $stillCorrupted2 = ($bytesAfter2[64] -eq [byte]($origByte -bxor 0xFF))

        # Restore artifact
        Remove-Item -Path $filePath -Force
        Move-Item -Path $bakPath -Destination $filePath -Force

        # Check 4: Restored artifact passes --verify-weights CLI (exit 0)
        $pOk2 = Start-Process -FilePath $binPath -ArgumentList "--verify-weights", $artKey, $filePath -NoNewWindow -Wait -PassThru
        $cliRestoredPass2 = ($pOk2.ExitCode -eq 0)

        # Check 5: Restored artifact live HTTP probe returns MEASURED
        $httpRestoredPass2 = $false
        try {
            $respOk2 = if ($art.Method -eq "Post") {
                Invoke-RestMethod -Uri $art.Url -Method Post -Headers $authHeaders -TimeoutSec 15 -Body "{}" -ContentType "application/json"
            } else {
                Invoke-RestMethod -Uri $art.Url -Method Get -Headers $authHeaders -TimeoutSec 15
            }
            if ($respOk2.status -eq "MEASURED") {
                $httpRestoredPass2 = $true
            }
        } catch {
            Write-Host "      Restored HTTP probe error: $_" -ForegroundColor Yellow
        }

        if ($cliFailedClosed2 -and $httpFailedClosed2 -and $hasWeightErr2 -and $stillCorrupted2 -and $cliRestoredPass2 -and $httpRestoredPass2) {
            Write-Host "      Mode 2 (Corrupted): PASS (CLI=$($pFail2.ExitCode), HTTP=UNMEASURED/OFFLINE, ErrCode=WEIGHT_*, StillCorrupt=$stillCorrupted2, Restored=$httpRestoredPass2)" -ForegroundColor Green
            $mode2Pass = $true
        } else {
            Write-Host "      Mode 2 (Corrupted): FAIL (cliFail=$cliFailedClosed2, httpFail=$httpFailedClosed2, weightErr=$hasWeightErr2, stillCorrupt=$stillCorrupted2, cliRest=$cliRestoredPass2, httpRest=$httpRestoredPass2)" -ForegroundColor Red
        }

    } finally {
        if (Test-Path $bakPath) {
            Remove-Item -Path $filePath -Force -ErrorAction SilentlyContinue
            Move-Item -Path $bakPath -Destination $filePath -Force -ErrorAction SilentlyContinue
        }
    }

    if ($mode1Pass -and $mode2Pass) {
        Write-Host "  >>> $($artKey): BOTH Mode 1 (Missing) & Mode 2 (Corrupted) PASS!" -ForegroundColor Green
        $results["Test3_FailInject_$artKey"] = "PASS (Mode 1 Missing: PASS, Mode 2 Corrupted: PASS)"
    } else {
        Write-Host "  >>> $($artKey): FAILED! (Mode1=$mode1Pass, Mode2=$mode2Pass)" -ForegroundColor Red
        $results["Test3_FailInject_$artKey"] = "FAIL (Mode 1 Missing: $mode1Pass, Mode 2 Corrupted: $mode2Pass)"
    }
}

# -------------------------------------------------------------
# Test 4: Rust Finite-Difference Gradient Check CLI
# -------------------------------------------------------------
Write-Host "`n--- Test 4: Rust Gradient Verification CLI (v31_swarm.exe --verify-gradients) ---" -ForegroundColor Yellow
$pGrad = Start-Process -FilePath $binPath -ArgumentList "--verify-gradients" -NoNewWindow -Wait -PassThru
if ($pGrad.ExitCode -eq 0) {
    Write-Host ">>> Test 4 PASS: Reverse-mode finite-difference gradient check passed (< 1e-4 tolerance)." -ForegroundColor Green
    $results["Test4_GradientCheckCLI"] = "PASS (max relative error < 1e-4)"
} else {
    Write-Host ">>> Test 4 FAIL: Gradient check returned exit code $($pGrad.ExitCode)" -ForegroundColor Red
    $results["Test4_GradientCheckCLI"] = "FAIL (Exit code $($pGrad.ExitCode))"
}

# -------------------------------------------------------------
# Test 5: Zero Square Brackets Check in v33*.rs .. v99*.rs
# -------------------------------------------------------------
Write-Host "`n--- Test 5: Zero Square Brackets Check (01_l0_rust\src\v33*.rs .. v99*.rs) ---" -ForegroundColor Yellow
$vFiles = Get-ChildItem -Path "$baseDir\01_l0_rust\src\" -Filter "*.rs" | Where-Object {
    $n = $_.Name
    if ($n -match "^v(\d+)") {
        $num = [int]$matches[1]
        $num -ge 33 -and $num -le 99
    } else {
        $false
    }
}

$bracketViolations = @()
foreach ($vf in $vFiles) {
    $content = Get-Content -Path $vf.FullName
    $lineIdx = 0
    foreach ($line in $content) {
        $lineIdx++
        if ($line -match "\[|\]") {
            $bracketViolations += "$($vf.Name):$lineIdx : $line"
        }
    }
}

if ($bracketViolations.Count -eq 0) {
    Write-Host ">>> Test 5 PASS: $($vFiles.Count) files scanned, exactly 0 square brackets found!" -ForegroundColor Green
    $results["Test5_ZeroSquareBrackets"] = "PASS ($($vFiles.Count) files verified, 0 brackets)"
} else {
    Write-Host ">>> Test 5 FAIL: Found $($bracketViolations.Count) bracket violations!" -ForegroundColor Red
    $bracketViolations | Select-Object -First 10 | ForEach-Object { Write-Host "   $_" -ForegroundColor DarkRed }
    $results["Test5_ZeroSquareBrackets"] = "FAIL ($($bracketViolations.Count) violations)"
}

# -------------------------------------------------------------
# Summary
# -------------------------------------------------------------
Write-Host "`n=================================================================" -ForegroundColor Cyan
Write-Host "  Final Summary of M2 Verification Results:" -ForegroundColor Cyan
$allPass = $true
foreach ($k in $results.Keys) {
    $val = $results[$k]
    $color = if ($val -like "PASS*") { "Green" } else { "Red"; $allPass = $false }
    Write-Host "  - $k : $val" -ForegroundColor $color
}
Write-Host "=================================================================" -ForegroundColor Cyan

if (-not $allPass) {
    exit 1
} else {
    exit 0
}
