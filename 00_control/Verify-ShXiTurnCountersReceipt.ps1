# =============================================================================
# ACT-OMEGA NET — SH-XI TURN COUNTER LEDGER & RECEIPT VERIFIER (v73.2.5 / NF10a)
# Strictly READ-ONLY on 03_vault/connectome/sh_xi_session_turn_counters.json and
# E:\Sovereign_Manifold_SSD_Vault\connectome\sh_xi_session_turn_counters.json.
# In -AuditOnly mode, verifies v73_2_4_sh_xi_turn_counter_receipt.json parity.
# In write mode, regenerates v73_2_4_sh_xi_turn_counter_receipt.json in UTF-8
# without BOM + LF (\n) preserving historical probes, then self-audits.
# Primary Author & Principal Systems Architect: Donevin Frownfelter (@bospaladin34-crypto)
# =============================================================================
[CmdletBinding()]
param(
    [string]$RepoRoot = "",
    [switch]$AuditOnly,
    [string]$Version = ""
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
} else {
    $RepoRoot = (Resolve-Path $RepoRoot).Path
}

$Utf8NoBomStrict = New-Object System.Text.UTF8Encoding($false, $true)
$Utf8NoBomWrite = New-Object System.Text.UTF8Encoding($false)

function Get-Sha256HexFromBytes {
    param([byte[]]$Bytes)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hash = $sha.ComputeHash($Bytes)
        return ([System.BitConverter]::ToString($hash)).Replace("-", "").ToLowerInvariant()
    } finally {
        $sha.Dispose()
    }
}

function Test-Utf8NoBomLfBytes {
    param([byte[]]$Bytes, [string]$Label = "")
    if ($null -eq $Bytes) {
        return @{ ok = $false; reason = "NULL_BYTES ($Label)" }
    }
    if ($Bytes.Length -ge 3 -and $Bytes[0] -eq 0xEF -and $Bytes[1] -eq 0xBB -and $Bytes[2] -eq 0xBF) {
        return @{ ok = $false; reason = "UTF8_BOM_PRESENT ($Label)" }
    }
    if ($Bytes.Length -ge 2 -and (($Bytes[0] -eq 0xFF -and $Bytes[1] -eq 0xFE) -or ($Bytes[0] -eq 0xFE -and $Bytes[1] -eq 0xFF))) {
        return @{ ok = $false; reason = "UTF16_BOM_PRESENT ($Label)" }
    }
    for ($i = 0; $i -lt $Bytes.Length; $i++) {
        if ($Bytes[$i] -eq 0x00) {
            return @{ ok = $false; reason = "NUL_BYTE_PRESENT ($Label)" }
        }
        if ($Bytes[$i] -eq 0x0D) {
            return @{ ok = $false; reason = "CR_BYTE_PRESENT ($Label)" }
        }
    }
    try {
        $null = $Utf8NoBomStrict.GetString($Bytes)
    } catch {
        return @{ ok = $false; reason = "INVALID_UTF8 ($Label): $($_.Exception.Message)" }
    }
    if ($Bytes.Length -gt 0 -and $Bytes[$Bytes.Length - 1] -ne 0x0A) {
        return @{ ok = $false; reason = "MISSING_TRAILING_LF ($Label)" }
    }
    return @{ ok = $true; reason = "OK" }
}

$cLedgerPath = Join-Path $RepoRoot "03_vault\connectome\sh_xi_session_turn_counters.json"
$eLedgerPath = "E:\Sovereign_Manifold_SSD_Vault\connectome\sh_xi_session_turn_counters.json"
$receiptPath = Join-Path $RepoRoot "03_vault\receipts\v73_2_4_sh_xi_turn_counter_receipt.json"

if (-not (Test-Path -LiteralPath $cLedgerPath -PathType Leaf)) {
    Write-Output "[SH-XI-TURN-RECEIPT-FAIL] Missing C: ledger at $cLedgerPath"
    exit 1
}

$cBytes = [System.IO.File]::ReadAllBytes($cLedgerPath)
$cSha = Get-Sha256HexFromBytes -Bytes $cBytes
$cObj = ($Utf8NoBomStrict.GetString($cBytes)) | ConvertFrom-Json

$cGlobalSeq = [int64]$cObj.global_turn_seq
$cHistSeeded = [int64]$cObj.historical_seeded_total
$cSessionCount = [int64]$cObj.session_count

$eMounted = Test-Path -LiteralPath $eLedgerPath -PathType Leaf
$eSha = ""
$eParity = $false
if ($eMounted) {
    $eBytes = [System.IO.File]::ReadAllBytes($eLedgerPath)
    $eSha = Get-Sha256HexFromBytes -Bytes $eBytes
    $eParity = ($eSha -eq $cSha)
} else {
    Write-Output "[SH-XI-TURN-RECEIPT-FAIL] E: vault ledger missing/unmounted at $eLedgerPath"
    exit 1
}

if (-not $eParity) {
    Write-Output "[SH-XI-TURN-RECEIPT-FAIL] C: != E: ledger SHA-256 mismatch (C=$cSha E=$eSha)"
    exit 1
}

function Invoke-ReceiptAudit {
    param(
        [string]$ReceiptFile,
        [string]$ExpectedSha,
        [int64]$ExpectedGlobalSeq,
        [int64]$ExpectedHistSeeded,
        [int64]$ExpectedSessionCount,
        [bool]$ExpectedCeMatch
    )
    if (-not (Test-Path -LiteralPath $ReceiptFile -PathType Leaf)) {
        return @{ ok = $false; reason = "RECEIPT_MISSING: $ReceiptFile" }
    }
    $rBytes = [System.IO.File]::ReadAllBytes($ReceiptFile)
    $encChk = Test-Utf8NoBomLfBytes -Bytes $rBytes -Label (Split-Path -Leaf $ReceiptFile)
    if (-not $encChk.ok) {
        return @{ ok = $false; reason = "RECEIPT_ENCODING_INVALID: $($encChk.reason)" }
    }
    try {
        $rObj = ($Utf8NoBomStrict.GetString($rBytes)) | ConvertFrom-Json
    } catch {
        return @{ ok = $false; reason = "RECEIPT_JSON_INVALID: $($_.Exception.Message)" }
    }
    $rSha = ([string]$rObj.ledger_sha256).Trim().ToLowerInvariant()
    if ($rSha -ne $ExpectedSha) {
        return @{ ok = $false; reason = "LEDGER_SHA256_MISMATCH: receipt=$rSha live_ledger=$ExpectedSha" }
    }
    if ([int64]$rObj.final_global_turn_seq -ne $ExpectedGlobalSeq) {
        return @{ ok = $false; reason = "GLOBAL_TURN_SEQ_MISMATCH: receipt=$($rObj.final_global_turn_seq) live_ledger=$ExpectedGlobalSeq" }
    }
    if ([int64]$rObj.historical_seeded_total -ne $ExpectedHistSeeded) {
        return @{ ok = $false; reason = "HISTORICAL_SEEDED_MISMATCH: receipt=$($rObj.historical_seeded_total) live_ledger=$ExpectedHistSeeded" }
    }
    if ($null -ne $rObj.PSObject.Properties["session_count"] -and [int64]$rObj.session_count -ne $ExpectedSessionCount) {
        return @{ ok = $false; reason = "SESSION_COUNT_MISMATCH: receipt=$($rObj.session_count) live_ledger=$ExpectedSessionCount" }
    }
    if ([bool]$rObj.ledger_c_e_sha256_match -ne $ExpectedCeMatch -or (-not [bool]$rObj.ledger_c_e_sha256_match)) {
        return @{ ok = $false; reason = "CE_MATCH_FLAG_MISMATCH: receipt=$($rObj.ledger_c_e_sha256_match) live=$ExpectedCeMatch" }
    }
    return @{ ok = $true; reason = "OK"; version = [string]$rObj.version }
}

if ($AuditOnly) {
    $res = Invoke-ReceiptAudit -ReceiptFile $receiptPath -ExpectedSha $cSha -ExpectedGlobalSeq $cGlobalSeq -ExpectedHistSeeded $cHistSeeded -ExpectedSessionCount $cSessionCount -ExpectedCeMatch $eParity
    if (-not $res.ok) {
        Write-Output "[SH-XI-TURN-RECEIPT-AUDIT-FAIL] $($res.reason)"
        exit 1
    }
    Write-Output "[SH-XI-TURN-RECEIPT-AUDIT-PASS] version=$($res.version) global_turn_seq=$cGlobalSeq session_count=$cSessionCount historical_seeded_total=$cHistSeeded ce_match=$eParity sha256=$cSha"
    exit 0
}

# Write mode: preserve historical probe payload while updating live ledger telemetry
if (-not (Test-Path -LiteralPath $receiptPath -PathType Leaf)) {
    Write-Output "[SH-XI-TURN-RECEIPT-FAIL] Existing receipt missing at $receiptPath"
    exit 1
}

$resolvedVersion = $Version.Trim()
if ([string]::IsNullOrWhiteSpace($resolvedVersion)) {
    $cffPath = Join-Path $RepoRoot "CITATION.cff"
    if (Test-Path -LiteralPath $cffPath -PathType Leaf) {
        $cffTxt = $Utf8NoBomStrict.GetString([System.IO.File]::ReadAllBytes($cffPath))
        if ($cffTxt -match '(?m)^version:\s*"?([^"\r\n]+)"?\s*$') {
            $vRaw = $Matches[1].Trim()
            $resolvedVersion = if ($vRaw.StartsWith("v")) { $vRaw } else { "v$vRaw" }
        }
    }
}

$existingRaw = $Utf8NoBomStrict.GetString([System.IO.File]::ReadAllBytes($receiptPath))
$existingObj = $existingRaw | ConvertFrom-Json
if ([string]::IsNullOrWhiteSpace($resolvedVersion)) {
    $resolvedVersion = [string]$existingObj.version
}

$histPreserved = [ordered]@{}
foreach ($hk in @("vesper_hud_mwofzb59", "mobile_p10_sh_xi", "ps_w2_refactor_test")) {
    $prop = $cObj.sessions.PSObject.Properties[$hk]
    if ($null -eq $prop) {
        Write-Output "[SH-XI-TURN-RECEIPT-FAIL] Expected historical session '$hk' missing from ledger"
        exit 1
    }
    $histPreserved[$hk] = [int64]$prop.Value
}

$updated = [ordered]@{
    schema = [string]$existingObj.schema
    version = $resolvedVersion
    milestone = [string]$existingObj.milestone
    primary_session_id = [string]$existingObj.primary_session_id
    isolated_reset_session_id = [string]$existingObj.isolated_reset_session_id
    historical_seeded_total = $cHistSeeded
    final_global_turn_seq = $cGlobalSeq
    session_count = $cSessionCount
    c_ledger_path = "03_vault/connectome/sh_xi_session_turn_counters.json"
    e_ledger_path = "E:\Sovereign_Manifold_SSD_Vault\connectome\sh_xi_session_turn_counters.json"
    ledger_c_e_sha256_match = $eParity
    ledger_sha256 = $cSha
    openai_compat_operator_gate_probes = $existingObj.openai_compat_operator_gate_probes
    turns_1_to_12_pre_hotswap = $existingObj.turns_1_to_12_pre_hotswap
    hotswap_executed_between_turn_12_and_13 = $existingObj.hotswap_executed_between_turn_12_and_13
    turns_13_to_14_post_hotswap = $existingObj.turns_13_to_14_post_hotswap
    isolated_reset_probes = $existingObj.isolated_reset_probes
    openai_compat_turn_15 = $existingObj.openai_compat_turn_15
    historical_sessions_preserved = $histPreserved
    generated_at_utc = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
}

$jsonOut = (($updated | ConvertTo-Json -Depth 10) -replace "`r`n", "`n" -replace "`r", "`n").TrimEnd("`n") + "`n"
[System.IO.File]::WriteAllText($receiptPath, $jsonOut, $Utf8NoBomWrite)

$selfAudit = Invoke-ReceiptAudit -ReceiptFile $receiptPath -ExpectedSha $cSha -ExpectedGlobalSeq $cGlobalSeq -ExpectedHistSeeded $cHistSeeded -ExpectedSessionCount $cSessionCount -ExpectedCeMatch $eParity
if (-not $selfAudit.ok) {
    Write-Output "[SH-XI-TURN-RECEIPT-WRITE-FAIL] Self-audit failed: $($selfAudit.reason)"
    exit 1
}

Write-Output "[SH-XI-TURN-RECEIPT-UPDATED] version=$resolvedVersion global_turn_seq=$cGlobalSeq session_count=$cSessionCount historical_seeded_total=$cHistSeeded ce_match=$eParity sha256=$cSha"
exit 0
