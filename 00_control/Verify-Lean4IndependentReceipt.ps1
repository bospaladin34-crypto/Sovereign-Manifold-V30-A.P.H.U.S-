param(
    [switch]$VerifyOnly,
    [switch]$TestNegative,
    [string]$RepoRoot = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    if ($PSScriptRoot -and (Test-Path (Split-Path -Parent $PSScriptRoot))) {
        $RepoRoot = (Resolve-Path (Split-Path -Parent $PSScriptRoot)).Path
    } else {
        $RepoRoot = "C:\sovereign_manifold_v31"
    }
}
if (-not (Test-Path $RepoRoot)) {
    throw "FAIL_CLOSED: RepoRoot not found: $RepoRoot"
}

function Get-ExternalOperatorKeyBytes {
    $raw = ""
    if (-not [string]::IsNullOrWhiteSpace($env:ACT_OMEGA_OPERATOR_KEY)) {
        $raw = $env:ACT_OMEGA_OPERATOR_KEY.Trim()
    } else {
        $candidates = @(
            "C:\Users\Nbell\.act_omega_operator_vault_key"
        )
        if (-not [string]::IsNullOrWhiteSpace($env:USERPROFILE)) {
            $candidates += (Join-Path $env:USERPROFILE ".act_omega_operator_vault_key")
        }
        foreach ($p in $candidates) {
            if (Test-Path $p -PathType Leaf) {
                $raw = ([System.IO.File]::ReadAllText($p)).Trim()
                if ($raw.Length -ge 24) { break }
            }
        }
    }
    if ($raw.Length -lt 24) {
        throw "FAIL_CLOSED: External operator key missing or < 24 chars (set ACT_OMEGA_OPERATOR_KEY or C:\Users\Nbell\.act_omega_operator_vault_key)"
    }
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    return $utf8NoBom.GetBytes($raw)
}

function Get-Sha256HexLower {
    param([byte[]]$Bytes)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hash = $sha.ComputeHash($Bytes)
        return ([System.BitConverter]::ToString($hash)).Replace("-", "").ToLowerInvariant()
    } finally {
        $sha.Dispose()
    }
}

function Get-HmacSha256HexLower {
    param(
        [byte[]]$KeyBytes,
        [string]$Payload
    )
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    $hmac = New-Object System.Security.Cryptography.HMACSHA256(,$KeyBytes)
    try {
        $hash = $hmac.ComputeHash($utf8NoBom.GetBytes($Payload))
        return ([System.BitConverter]::ToString($hash)).Replace("-", "").ToLowerInvariant()
    } finally {
        $hmac.Dispose()
    }
}

function Test-ConstantTimeHex64 {
    param(
        [string]$Actual,
        [string]$Expected
    )
    if ($null -eq $Actual -or $null -eq $Expected) { return $false }
    if ($Actual.Length -ne 64 -or $Expected.Length -ne 64) { return $false }
    if ($Actual -notmatch '^[0-9a-f]{64}$' -or $Expected -notmatch '^[0-9a-f]{64}$') { return $false }
    $diff = 0
    for ($i = 0; $i -lt 64; $i++) {
        $diff = $diff -bor ([int][char]$Actual[$i] -bxor [int][char]$Expected[$i])
    }
    return ($diff -eq 0)
}

function Get-CitationReleaseVersion {
    param([string]$Root)
    $cff = Join-Path $Root "CITATION.cff"
    if (-not (Test-Path -LiteralPath $cff -PathType Leaf)) {
        throw "FAIL_CLOSED: Release version source CITATION.cff missing at $cff"
    }
    $txt = [System.IO.File]::ReadAllText($cff)
    if ($txt -match '(?m)^version:\s*"?([^"\r\n"]+)"?\s*$') {
        $v = $Matches[1].Trim()
        if ([string]::IsNullOrWhiteSpace($v)) {
            throw "FAIL_CLOSED: Empty version field in $cff"
        }
        if (-not $v.StartsWith("v")) { return "v$v" }
        return $v
    }
    throw "FAIL_CLOSED: Could not parse release version from $cff"
}

function Get-LeanSourceIntegrity {
    param(
        [string]$VaultPath,
        [string]$MirrorPath
    )
    if (-not (Test-Path $VaultPath -PathType Leaf)) {
        throw "FAIL_CLOSED: Missing vault Lean file: $VaultPath"
    }
    if (-not (Test-Path $MirrorPath -PathType Leaf)) {
        throw "FAIL_CLOSED: Missing L0 mirror Lean file: $MirrorPath"
    }
    $vaultBytes = [System.IO.File]::ReadAllBytes($VaultPath)
    $mirrorBytes = [System.IO.File]::ReadAllBytes($MirrorPath)
    $vaultSha = Get-Sha256HexLower -Bytes $vaultBytes
    $mirrorSha = Get-Sha256HexLower -Bytes $mirrorBytes
    if ($vaultSha -ne $mirrorSha) {
        throw "FAIL_CLOSED: Lean mirror SHA-256 mismatch ($vaultSha != $mirrorSha)"
    }
    $text = [System.Text.Encoding]::UTF8.GetString($vaultBytes)
    $thmCount = ([regex]::Matches($text, '(?m)^\s*theorem\s+')).Count
    $sorryCount = ([regex]::Matches($text, '\bsorry\b')).Count
    $axiomCount = ([regex]::Matches($text, '(?m)^\s*axiom\s+')).Count
    $trivialEq = ([regex]::Matches($text, ':\s*(\w+)\s*=\s*\1\s*:=')).Count
    $trivialComm = ([regex]::Matches($text, '\(a\s+b\s*:\s*Nat\)\s*:\s*a\s*\+\s*b\s*=\s*b\s*\+\s*a')).Count
    if ($thmCount -lt 1010) {
        throw "FAIL_CLOSED: theorem_count=$thmCount < 1010"
    }
    if ($sorryCount -ne 0) {
        throw "FAIL_CLOSED: sorry_count=$sorryCount != 0"
    }
    if ($axiomCount -ne 0) {
        throw "FAIL_CLOSED: axiom_count=$axiomCount != 0"
    }
    if (($trivialEq + $trivialComm) -ne 0) {
        throw "FAIL_CLOSED: trivial_padding_count=$($trivialEq + $trivialComm) != 0"
    }
    return @{
        vault_path = $VaultPath
        mirror_path = $MirrorPath
        lean_sha256 = $vaultSha
        l0_mirror_sha256 = $mirrorSha
        theorem_count = $thmCount
        sorry_count = $sorryCount
        axiom_count = $axiomCount
    }
}

function New-CanonicalLeanPayload {
    param(
        [string]$LeanSha256,
        [string]$LeanVersion,
        [int]$TheoremCount,
        [int]$SorryCount,
        [int]$ExitCode
    )
    return "$LeanSha256||$LeanVersion||$TheoremCount||$SorryCount||$ExitCode"
}

function Test-SignedLeanReceiptFile {
    param(
        [string]$ReceiptPath,
        [hashtable]$LeanInfo,
        [byte[]]$KeyBytes,
        [string]$ExpectedReleaseVersion = ""
    )
    if (-not (Test-Path $ReceiptPath -PathType Leaf)) {
        return @{ ok = $false; reason = "RECEIPT_MISSING: $ReceiptPath" }
    }
    try {
        $r = [System.IO.File]::ReadAllText($ReceiptPath) | ConvertFrom-Json
    } catch {
        return @{ ok = $false; reason = "RECEIPT_INVALID_JSON: $($_.Exception.Message)" }
    }
    if ($null -eq $r) {
        return @{ ok = $false; reason = "RECEIPT_NULL_JSON" }
    }
    if (-not [string]::IsNullOrWhiteSpace($ExpectedReleaseVersion) -and ([string]$r.version -ne $ExpectedReleaseVersion)) {
        return @{ ok = $false; reason = "RELEASE_VERSION_MISMATCH ($($r.version) != $ExpectedReleaseVersion)" }
    }
    if ([string]$r.lean_sha256 -ne $LeanInfo.lean_sha256) {
        return @{ ok = $false; reason = "LEAN_SHA256_MISMATCH" }
    }
    if ([string]$r.l0_mirror_sha256 -ne $LeanInfo.l0_mirror_sha256) {
        return @{ ok = $false; reason = "L0_MIRROR_SHA256_MISMATCH" }
    }
    $rThm = if ($null -ne $r.theorem_count) { [int]$r.theorem_count } else { -1 }
    $rVer = if ($null -ne $r.theorems_verified) { [int]$r.theorems_verified } else { -1 }
    if ($rThm -lt 1010 -or $rThm -ne $LeanInfo.theorem_count -or $rVer -ne $LeanInfo.theorem_count) {
        return @{ ok = $false; reason = "THEOREM_COUNT_MISMATCH" }
    }
    $rSorry = if ($null -ne $r.sorry_count) { [int]$r.sorry_count } else { -1 }
    $rAxiom = if ($null -ne $r.axiom_count) { [int]$r.axiom_count } else { -1 }
    if ($rSorry -ne 0 -or $rAxiom -ne 0) {
        return @{ ok = $false; reason = "SORRY_OR_AXIOM_NONZERO" }
    }
    $rExit = if ($null -ne $r.exit_code) { [int]$r.exit_code } else { -1 }
    $rCompExit = if ($null -ne $r.compiler_exit_code) { [int]$r.compiler_exit_code } else { -1 }
    if ($rExit -ne 0 -or $rCompExit -ne 0 -or ($r.lean_exe_exit_zero -ne $true)) {
        return @{ ok = $false; reason = "EXIT_CODE_NONZERO" }
    }
    $leanVerStr = ([string]$r.lean_version).Trim()
    if ([string]::IsNullOrWhiteSpace($leanVerStr)) {
        return @{ ok = $false; reason = "LEAN_VERSION_EMPTY" }
    }
    if ([string]$r.hmac_algorithm -ne "RFC2104_HMAC_SHA256") {
        return @{ ok = $false; reason = "HMAC_ALGORITHM_MISMATCH" }
    }
    if ([string]::IsNullOrWhiteSpace([string]$r.trust_boundary)) {
        return @{ ok = $false; reason = "TRUST_BOUNDARY_UNDOCUMENTED" }
    }
    $expectedPayload = New-CanonicalLeanPayload -LeanSha256 $LeanInfo.lean_sha256 -LeanVersion $leanVerStr -TheoremCount $LeanInfo.theorem_count -SorryCount 0 -ExitCode 0
    if ([string]$r.canonical_payload -ne $expectedPayload) {
        return @{ ok = $false; reason = "CANONICAL_PAYLOAD_MISMATCH" }
    }
    $expectedHmac = Get-HmacSha256HexLower -KeyBytes $KeyBytes -Payload $expectedPayload
    $actualHmac = ([string]$r.hmac_sha256).Trim().ToLowerInvariant()
    if (-not (Test-ConstantTimeHex64 -Actual $actualHmac -Expected $expectedHmac)) {
        return @{ ok = $false; reason = "HMAC_SIGNATURE_INVALID" }
    }
    return @{ ok = $true; reason = "VERIFIED"; lean_version = $leanVerStr; theorem_count = $rThm; release_version = [string]$r.version }
}

if ($TestNegative) {
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "  VERIFY-LEAN4-INDEPENDENT-RECEIPT: ISOLATED NEGATIVE SELF-TEST (5/5)     " -ForegroundColor Cyan
    Write-Host "==========================================================================" -ForegroundColor Cyan
    $tmpRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("lean4_receipt_neg_" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Force -Path $tmpRoot | Out-Null
    $negFailures = 0
    try {
        $sb = New-Object System.Text.StringBuilder
        for ($i = 1; $i -le 1010; $i++) {
            [void]$sb.AppendLine("theorem neg_test_thm_$i (x : Nat) : x + 0 = x := by simp")
        }
        $tmpVaultLean = Join-Path $tmpRoot "vault.lean"
        $tmpMirrorLean = Join-Path $tmpRoot "mirror.lean"
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($tmpVaultLean, $sb.ToString(), $utf8NoBom)
        [System.IO.File]::WriteAllText($tmpMirrorLean, $sb.ToString(), $utf8NoBom)
        $leanInfo = Get-LeanSourceIntegrity -VaultPath $tmpVaultLean -MirrorPath $tmpMirrorLean
        $testKeyBytes = $utf8NoBom.GetBytes("ephemeral-isolated-hmac-test-key-32bytes!")
        $leanVer = "Lean-compiler-isolated-fixture"
        $expectedVer = Get-CitationReleaseVersion -Root $RepoRoot
        $payload = New-CanonicalLeanPayload -LeanSha256 $leanInfo.lean_sha256 -LeanVersion $leanVer -TheoremCount $leanInfo.theorem_count -SorryCount 0 -ExitCode 0
        $validHmac = Get-HmacSha256HexLower -KeyBytes $testKeyBytes -Payload $payload

        $baseReceipt = [ordered]@{
            schema = "ACT_OMEGA_LEAN4_COMPILER_VERIFICATION_RECEIPT_V2"
            version = $expectedVer
            lean_file = "03_vault/lean4/SovereignManifoldTheorems.lean"
            lean_mirror = "01_l0_rust/lean4/SovereignManifoldTheorems.lean"
            lean_sha256 = $leanInfo.lean_sha256
            l0_mirror_sha256 = $leanInfo.l0_mirror_sha256
            lean_version = $leanVer
            theorem_count = $leanInfo.theorem_count
            theorems_verified = $leanInfo.theorem_count
            sorry_count = 0
            axiom_count = 0
            exit_code = 0
            compiler_exit_code = 0
            lean_exe_exit_zero = $true
            canonical_payload = $payload
            hmac_algorithm = "RFC2104_HMAC_SHA256"
            hmac_sha256 = $validHmac
            trust_boundary = "Isolated test fixture trust boundary documentation."
            compiler_elapsed_ms = 123
            verify_elapsed_ms = 123
            verified_at_utc = "2026-11-19T00:00:00Z"
        }

        # (a) Valid signed passes
        $pValid = Join-Path $tmpRoot "valid.json"
        [System.IO.File]::WriteAllText($pValid, ($baseReceipt | ConvertTo-Json -Depth 4), $utf8NoBom)
        $rValid = Test-SignedLeanReceiptFile -ReceiptPath $pValid -LeanInfo $leanInfo -KeyBytes $testKeyBytes -ExpectedReleaseVersion $expectedVer
        if ($rValid.ok) {
            Write-Host "  [NEG 1/5 VALID SIGNED]     [PASS] Valid HMAC receipt accepted" -ForegroundColor Green
        } else {
            Write-Host "  [NEG 1/5 VALID SIGNED]     [FAIL] $($rValid.reason)" -ForegroundColor Red
            $negFailures++
        }

        # (b) Missing fails
        $rMiss = Test-SignedLeanReceiptFile -ReceiptPath (Join-Path $tmpRoot "missing.json") -LeanInfo $leanInfo -KeyBytes $testKeyBytes -ExpectedReleaseVersion $expectedVer
        if (-not $rMiss.ok -and $rMiss.reason -match "RECEIPT_MISSING") {
            Write-Host "  [NEG 2/5 MISSING]          [PASS] Missing receipt rejected ($($rMiss.reason))" -ForegroundColor Green
        } else {
            Write-Host "  [NEG 2/5 MISSING]          [FAIL]" -ForegroundColor Red
            $negFailures++
        }

        # (c) Unsigned ("") fails
        $rUnsignedObj = [ordered]@{} + $baseReceipt
        $rUnsignedObj["hmac_sha256"] = ""
        $pUnsigned = Join-Path $tmpRoot "unsigned.json"
        [System.IO.File]::WriteAllText($pUnsigned, ($rUnsignedObj | ConvertTo-Json -Depth 4), $utf8NoBom)
        $rUnsigned = Test-SignedLeanReceiptFile -ReceiptPath $pUnsigned -LeanInfo $leanInfo -KeyBytes $testKeyBytes -ExpectedReleaseVersion $expectedVer
        if (-not $rUnsigned.ok -and $rUnsigned.reason -eq "HMAC_SIGNATURE_INVALID") {
            Write-Host "  [NEG 3/5 UNSIGNED]         [PASS] Empty hmac_sha256 rejected ($($rUnsigned.reason))" -ForegroundColor Green
        } else {
            Write-Host "  [NEG 3/5 UNSIGNED]         [FAIL] $($rUnsigned.reason)" -ForegroundColor Red
            $negFailures++
        }

        # (d) Forged HMAC fails
        $rForgedObj = [ordered]@{} + $baseReceipt
        $flipChar = if ($validHmac[0] -eq 'a') { 'b' } else { 'a' }
        $rForgedObj["hmac_sha256"] = $flipChar + $validHmac.Substring(1)
        $pForged = Join-Path $tmpRoot "forged.json"
        [System.IO.File]::WriteAllText($pForged, ($rForgedObj | ConvertTo-Json -Depth 4), $utf8NoBom)
        $rForged = Test-SignedLeanReceiptFile -ReceiptPath $pForged -LeanInfo $leanInfo -KeyBytes $testKeyBytes -ExpectedReleaseVersion $expectedVer
        if (-not $rForged.ok -and $rForged.reason -eq "HMAC_SIGNATURE_INVALID") {
            Write-Host "  [NEG 4/5 FORGED HMAC]      [PASS] 1-char flipped HMAC rejected ($($rForged.reason))" -ForegroundColor Green
        } else {
            Write-Host "  [NEG 4/5 FORGED HMAC]      [FAIL] $($rForged.reason)" -ForegroundColor Red
            $negFailures++
        }

        # (e) Tampered version, theorem_count, exit_code, and lean_sha256 fail
        $tamperPass = $true
        $t1 = [ordered]@{} + $baseReceipt; $t1["theorem_count"] = 1009; $t1["theorems_verified"] = 1009
        $pT1 = Join-Path $tmpRoot "t1.json"; [System.IO.File]::WriteAllText($pT1, ($t1 | ConvertTo-Json -Depth 4), $utf8NoBom)
        if ((Test-SignedLeanReceiptFile -ReceiptPath $pT1 -LeanInfo $leanInfo -KeyBytes $testKeyBytes -ExpectedReleaseVersion $expectedVer).ok) { $tamperPass = $false }

        $t2 = [ordered]@{} + $baseReceipt; $t2["exit_code"] = 1; $t2["compiler_exit_code"] = 1
        $pT2 = Join-Path $tmpRoot "t2.json"; [System.IO.File]::WriteAllText($pT2, ($t2 | ConvertTo-Json -Depth 4), $utf8NoBom)
        if ((Test-SignedLeanReceiptFile -ReceiptPath $pT2 -LeanInfo $leanInfo -KeyBytes $testKeyBytes -ExpectedReleaseVersion $expectedVer).ok) { $tamperPass = $false }

        $t3 = [ordered]@{} + $baseReceipt; $t3["lean_sha256"] = ("0" * 64)
        $pT3 = Join-Path $tmpRoot "t3.json"; [System.IO.File]::WriteAllText($pT3, ($t3 | ConvertTo-Json -Depth 4), $utf8NoBom)
        if ((Test-SignedLeanReceiptFile -ReceiptPath $pT3 -LeanInfo $leanInfo -KeyBytes $testKeyBytes -ExpectedReleaseVersion $expectedVer).ok) { $tamperPass = $false }

        $t4 = [ordered]@{} + $baseReceipt; $t4["version"] = "stale_release_tag"
        $pT4 = Join-Path $tmpRoot "t4.json"; [System.IO.File]::WriteAllText($pT4, ($t4 | ConvertTo-Json -Depth 4), $utf8NoBom)
        if ((Test-SignedLeanReceiptFile -ReceiptPath $pT4 -LeanInfo $leanInfo -KeyBytes $testKeyBytes -ExpectedReleaseVersion $expectedVer).ok) { $tamperPass = $false }

        if ($tamperPass) {
            Write-Host "  [NEG 5/5 TAMPERED FIELDS]  [PASS] Tampered version / theorem_count / exit_code / lean_sha256 all rejected" -ForegroundColor Green
        } else {
            Write-Host "  [NEG 5/5 TAMPERED FIELDS]  [FAIL] One or more tampered fields accepted" -ForegroundColor Red
            $negFailures++
        }
    } finally {
        Remove-Item -Path $tmpRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
    if ($negFailures -gt 0) { exit 1 }
    exit 0
}

$vaultLean = Join-Path $RepoRoot "03_vault\lean4\SovereignManifoldTheorems.lean"
$mirrorLean = Join-Path $RepoRoot "01_l0_rust\lean4\SovereignManifoldTheorems.lean"
$receiptPrimary = Join-Path $RepoRoot "03_vault\receipts\lean4_compiler_verification_receipt.json"
$receiptConnectome = Join-Path $RepoRoot "03_vault\connectome\lean4_compiler_verified_receipt.json"

$keyBytes = Get-ExternalOperatorKeyBytes
$leanInfo = Get-LeanSourceIntegrity -VaultPath $vaultLean -MirrorPath $mirrorLean
$expectedReleaseVersion = Get-CitationReleaseVersion -Root $RepoRoot

if ($VerifyOnly) {
    $res1 = Test-SignedLeanReceiptFile -ReceiptPath $receiptPrimary -LeanInfo $leanInfo -KeyBytes $keyBytes -ExpectedReleaseVersion $expectedReleaseVersion
    $res2 = Test-SignedLeanReceiptFile -ReceiptPath $receiptConnectome -LeanInfo $leanInfo -KeyBytes $keyBytes -ExpectedReleaseVersion $expectedReleaseVersion
    if (-not $res1.ok) {
        throw "FAIL_CLOSED: Primary Lean receipt invalid ($($res1.reason)) at $receiptPrimary"
    }
    if (-not $res2.ok) {
        throw "FAIL_CLOSED: Connectome Lean receipt invalid ($($res2.reason)) at $receiptConnectome"
    }
    Write-Output ("[LEAN4-RECEIPT VERIFY-ONLY PASS] version={0} theorems={1} sha256={2} lean_version=`"{3}`"" -f $res1.release_version, $leanInfo.theorem_count, $leanInfo.lean_sha256.Substring(0, 16), $res1.lean_version)
    exit 0
}

$leanExe = if (Test-Path "C:\Users\Nbell\.elan\bin\lean.exe") {
    "C:\Users\Nbell\.elan\bin\lean.exe"
} elseif (Get-Command lean -ErrorAction SilentlyContinue) {
    (Get-Command lean).Source
} else {
    throw "FAIL_CLOSED: lean.exe not found"
}

$leanVerOut = ((& $leanExe --version 2>&1) | Select-Object -First 1)
$leanVersion = ([string]$leanVerOut).Trim()
if ([string]::IsNullOrWhiteSpace($leanVersion)) {
    throw "FAIL_CLOSED: Failed to read lean.exe --version"
}

$sw = [System.Diagnostics.Stopwatch]::StartNew()
$leanOut = (& $leanExe $vaultLean 2>&1) -join "`n"
$leanExit = $LASTEXITCODE
$sw.Stop()
$elapsedMs = [int64][Math]::Round($sw.Elapsed.TotalMilliseconds)
if ($leanExit -ne 0) {
    throw "FAIL_CLOSED: lean.exe exited with code $leanExit : $leanOut"
}

$canonicalPayload = New-CanonicalLeanPayload -LeanSha256 $leanInfo.lean_sha256 -LeanVersion $leanVersion -TheoremCount $leanInfo.theorem_count -SorryCount $leanInfo.sorry_count -ExitCode $leanExit
$hmacSha256 = Get-HmacSha256HexLower -KeyBytes $keyBytes -Payload $canonicalPayload
$releaseVersion = Get-CitationReleaseVersion -Root $RepoRoot

$receiptObj = [ordered]@{
    schema = "ACT_OMEGA_LEAN4_COMPILER_VERIFICATION_RECEIPT_V2"
    version = $releaseVersion
    lean_file = "03_vault/lean4/SovereignManifoldTheorems.lean"
    lean_mirror = "01_l0_rust/lean4/SovereignManifoldTheorems.lean"
    lean_sha256 = $leanInfo.lean_sha256
    l0_mirror_sha256 = $leanInfo.l0_mirror_sha256
    lean_version = $leanVersion
    theorem_count = $leanInfo.theorem_count
    theorems_verified = $leanInfo.theorem_count
    sorry_count = $leanInfo.sorry_count
    axiom_count = $leanInfo.axiom_count
    exit_code = $leanExit
    compiler_exit_code = $leanExit
    lean_exe_exit_zero = ($leanExit -eq 0)
    canonical_payload = $canonicalPayload
    hmac_algorithm = "RFC2104_HMAC_SHA256"
    hmac_sha256 = $hmacSha256
    trust_boundary = "RFC2104_HMAC_SHA256 signed externally by 00_control/Verify-Lean4IndependentReceipt.ps1 using the local external operator key (ACT_OMEGA_OPERATOR_KEY / ~/.act_omega_operator_vault_key). Closes C1 in-process Rust self-writing and unsigned receipt spoofing; same-OS-user principal isolation would require an offline/FIDO2 asymmetric signature verified against a public key."
    compiler_elapsed_ms = $elapsedMs
    verify_elapsed_ms = $elapsedMs
    verified_at_utc = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$jsonText = ((($receiptObj | ConvertTo-Json -Depth 4) -replace "`r`n", "`n" -replace "`r", "`n").TrimEnd("`n") + "`n")
foreach ($outPath in @($receiptPrimary, $receiptConnectome)) {
    $parent = Split-Path -Parent $outPath
    if (-not (Test-Path $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
    [System.IO.File]::WriteAllText($outPath, $jsonText, $utf8NoBom)
}

Write-Output ("[LEAN4-RECEIPT SIGNED PASS] theorems={0} exit={1} elapsed_ms={2} sha256={3} hmac={4}..." -f $leanInfo.theorem_count, $leanExit, $elapsedMs, $leanInfo.lean_sha256.Substring(0, 16), $hmacSha256.Substring(0, 16))
exit 0
