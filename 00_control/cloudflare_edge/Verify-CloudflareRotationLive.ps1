# ==============================================================================
# ACT-Omega Net v73.2.3 — Live Wrangler Rotation & 11-User-Table D1 Proof (R6)
# Executes read-only wrangler CLI probes from $env:TEMP using externalized
# credentials (C:\Users\Nbell\.act_omega_cloudflare_ids.json), redacts all
# active/retired IDs/UUIDs/32-hex tokens to <REDACTED_<name>_sha256:<16hex>>,
# signs with RFC2104 HMAC-SHA256, and writes UTF-8 (no BOM) LF receipt to:
#   03_vault/receipts/s6_cloudflare_live_wrangler_verification.txt
# ==============================================================================
param(
    [switch]$VerifyOnly,
    [string]$RepoRoot = "",
    [string]$ExternalConfigPath = "C:\Users\Nbell\.act_omega_cloudflare_ids.json"
)

$ErrorActionPreference = "Stop"

$edgeDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $RepoRoot = (Resolve-Path (Join-Path $edgeDir "..\..")).Path
}
if (-not (Test-Path $RepoRoot)) {
    throw "FAIL_CLOSED: RepoRoot not found: $RepoRoot"
}

$receiptPath = Join-Path $RepoRoot "03_vault\receipts\s6_cloudflare_live_wrangler_verification.txt"

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

function Get-StringSha256Hex16 {
    param([string]$Value)
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    $hex = Get-Sha256HexLower -Bytes ($utf8NoBom.GetBytes($Value.ToLowerInvariant()))
    return $hex.Substring(0, 16)
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

function Load-ExternalCloudflareConfig {
    param([string]$CfgPath)
    if (-not (Test-Path $CfgPath -PathType Leaf)) {
        throw "FAIL_CLOSED: External Cloudflare IDs file not found: $CfgPath"
    }
    $cfg = Get-Content -Raw -Path $CfgPath | ConvertFrom-Json
    foreach ($req in @("account_id", "d1_database_id", "hyperdrive_id", "kv_id")) {
        $v = [string]$cfg.$req
        if ([string]::IsNullOrWhiteSpace($v) -or $v.Length -lt 16) {
            throw "FAIL_CLOSED: Missing or invalid required Cloudflare field '$req' in $CfgPath"
        }
    }
    return $cfg
}

function Redact-CloudflareOutput {
    param(
        [string]$Text,
        [object]$Cfg
    )
    if ([string]::IsNullOrEmpty($Text)) { return "" }
    # Strip ANSI escape sequences and normalize line endings
    $clean = [regex]::Replace($Text, '\x1b\[[0-9;?]*[A-Za-z]', '')
    $clean = $clean -replace "\r\n", "`n" -replace "\r", "`n"
    # Strip local log path noise
    $clean = [regex]::Replace($clean, '(?m)^.*Logs were written to ".*".*\n?', '')

    # Replace all known active Cloudflare IDs with labeled redacted sha256:<16hex>
    $idKeys = @("account_id", "d1_database_id", "hyperdrive_id", "kv_id", "vpc_anchor_id", "vpc_deno_id", "vpc_p10_id", "vpc_p8_id")
    foreach ($k in $idKeys) {
        $val = [string]$Cfg.$k
        if (-not [string]::IsNullOrWhiteSpace($val) -and $val.Length -ge 16) {
            $tag = "<REDACTED_${k}_sha256:" + (Get-StringSha256Hex16 -Value $val.Trim()) + ">"
            $clean = [regex]::Replace($clean, [regex]::Escape($val.Trim()), $tag, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        }
    }

    # Sweep any remaining 36-char UUIDs
    $clean = [regex]::Replace($clean, '\b([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})\b', {
        param($m)
        "<REDACTED_UUID_sha256:" + (Get-StringSha256Hex16 -Value $m.Groups[1].Value) + ">"
    })

    # Sweep any remaining 32-hex IDs
    $clean = [regex]::Replace($clean, '\b([0-9a-fA-F]{32})\b', {
        param($m)
        "<REDACTED_HEX32_sha256:" + (Get-StringSha256Hex16 -Value $m.Groups[1].Value) + ">"
    })

    return $clean.Trim()
}

function Assert-NoLeaks {
    param(
        [string]$Text,
        [object]$Cfg,
        [byte[]]$OperatorKeyBytes
    )
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    $opKeyStr = $utf8NoBom.GetString($OperatorKeyBytes)
    if ($Text.IndexOf($opKeyStr, [System.StringComparison]::Ordinal) -ge 0) {
        throw "FAIL_CLOSED_SECRET_LEAK: Operator key detected in verification transcript"
    }
    $idKeys = @("account_id", "d1_database_id", "hyperdrive_id", "kv_id", "vpc_anchor_id", "vpc_deno_id", "vpc_p10_id", "vpc_p8_id")
    foreach ($k in $idKeys) {
        $val = [string]$Cfg.$k
        if (-not [string]::IsNullOrWhiteSpace($val) -and $val.Length -ge 16) {
            if ($Text.IndexOf($val.Trim(), [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                throw "FAIL_CLOSED_CF_ID_LEAK: Active Cloudflare ID '$k' detected unredacted in transcript"
            }
        }
    }
    if ($Text -match '(?i)\b([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}|[0-9a-f]{32})\b') {
        throw "FAIL_CLOSED_RAW_HEX_UUID_LEAK: Unredacted 32-hex or 36-char UUID token detected in transcript"
    }
}

$cfg = Load-ExternalCloudflareConfig -CfgPath $ExternalConfigPath
$keyBytes = Get-ExternalOperatorKeyBytes

if ($VerifyOnly) {
    if (-not (Test-Path $receiptPath -PathType Leaf)) {
        throw "FAIL_CLOSED: Receipt not found at $receiptPath"
    }
    $rawBytes = [System.IO.File]::ReadAllBytes($receiptPath)
    if ($rawBytes.Length -ge 3 -and $rawBytes[0] -eq 0xEF -and $rawBytes[1] -eq 0xBB -and $rawBytes[2] -eq 0xBF) {
        throw "FAIL_CLOSED: Receipt has UTF-8 BOM (must be UTF-8 no BOM)"
    }
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    $fullText = $utf8NoBom.GetString($rawBytes)
    if ($fullText.Contains("`r")) {
        throw "FAIL_CLOSED: Receipt contains CR/CRLF (must be LF only)"
    }
    Assert-NoLeaks -Text $fullText -Cfg $cfg -OperatorKeyBytes $keyBytes

    $marker = "=== SIGNATURE_BLOCK ==="
    $idx = $fullText.IndexOf($marker, [System.StringComparison]::Ordinal)
    if ($idx -lt 1) {
        throw "FAIL_CLOSED: Missing SIGNATURE_BLOCK marker in $receiptPath"
    }
    $bodyText = $fullText.Substring(0, $idx)
    $sigText = $fullText.Substring($idx)

    $actualBodySha = Get-Sha256HexLower -Bytes ($utf8NoBom.GetBytes($bodyText))
    $verifiedAt = if ($sigText -match '(?m)^verified_at_utc:\s*(\S+)\s*$') { $Matches[1] } else { throw "FAIL_CLOSED: Missing verified_at_utc" }
    $recordedSha = if ($sigText -match '(?m)^transcript_sha256:\s*([0-9a-f]{64})\s*$') { $Matches[1] } else { throw "FAIL_CLOSED: Missing transcript_sha256" }
    $recordedPayload = if ($sigText -match '(?m)^canonical_payload:\s*(\S+)\s*$') { $Matches[1] } else { throw "FAIL_CLOSED: Missing canonical_payload" }
    $recordedHmac = if ($sigText -match '(?m)^hmac_sha256:\s*([0-9a-f]{64})\s*$') { $Matches[1] } else { throw "FAIL_CLOSED: Missing hmac_sha256" }

    if (-not (Test-ConstantTimeHex64 -Actual $actualBodySha -Expected $recordedSha)) {
        throw "FAIL_CLOSED: transcript_sha256 mismatch (actual=$actualBodySha recorded=$recordedSha)"
    }
    $expectedPayload = "${actualBodySha}||${verifiedAt}||d1_tables=11+2sys"
    if ($recordedPayload -ne $expectedPayload) {
        throw "FAIL_CLOSED: canonical_payload mismatch"
    }
    $expectedHmac = Get-HmacSha256HexLower -KeyBytes $keyBytes -Payload $expectedPayload
    if (-not (Test-ConstantTimeHex64 -Actual $recordedHmac -Expected $expectedHmac)) {
        throw "FAIL_CLOSED: RFC2104 HMAC-SHA256 verification failed"
    }
    if ($bodyText -notmatch 'user_tables_count:\s*11\b' -or $bodyText -notmatch 'system_tables_count:\s*2\b') {
        throw "FAIL_CLOSED: Verified receipt missing 11 user tables + 2 system tables assertion"
    }
    Write-Output ("[CF-ROTATION-VERIFY-ONLY PASS] d1_tables=11+2sys sha256={0} hmac={1}... utf8_no_bom_lf=true leaks=0" -f $actualBodySha.Substring(0, 16), $recordedHmac.Substring(0, 16))
    exit 0
}

function Invoke-WranglerRaw {
    param(
        [string[]]$WranglerArgs,
        [string]$EdgeDirectory
    )
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        $lines = & npx --prefix $EdgeDirectory wrangler @WranglerArgs 2>&1 | ForEach-Object { $_.ToString() }
        $code = $LASTEXITCODE
        return [pscustomobject]@{
            ExitCode = $code
            Output   = ($lines -join "`n")
        }
    } finally {
        $ErrorActionPreference = $prevEap
    }
}

$d1DbName = if ($cfg.d1_database_name) { [string]$cfg.d1_database_name } else { "act_omega_d1_vault_v7322" }
$accountId = [string]$cfg.account_id
$d1DbId = [string]$cfg.d1_database_id
$hdId = [string]$cfg.hyperdrive_id
$kvId = [string]$cfg.kv_id
$vpcAnchorId = [string]$cfg.vpc_anchor_id
$vpcDenoId = [string]$cfg.vpc_deno_id
$vpcP10Id = [string]$cfg.vpc_p10_id
$vpcP8Id = [string]$cfg.vpc_p8_id

$prevToken = $env:CLOUDFLARE_API_TOKEN
$prevAccount = $env:CLOUDFLARE_ACCOUNT_ID
$tmpCfg = Join-Path $env:TEMP ("act_omega_wrangler_verify_" + [guid]::NewGuid().ToString("N") + ".toml")

$rawToml = Get-Content -Raw -Path (Join-Path $edgeDir "wrangler.toml")
$renderedToml = $rawToml.Replace("<EXTERNAL_CF_ACCOUNT_ID>", $accountId).
                         Replace("<EXTERNAL_D1_DATABASE_NAME>", $d1DbName).
                         Replace("<EXTERNAL_D1_DATABASE_ID>", $d1DbId).
                         Replace("<EXTERNAL_HYPERDRIVE_ID>", $hdId).
                         Replace("<EXTERNAL_KV_ID>", $kvId).
                         Replace("<EXTERNAL_VPC_ANCHOR_ID>", $vpcAnchorId).
                         Replace("<EXTERNAL_VPC_DENO_ID>", $vpcDenoId).
                         Replace("<EXTERNAL_VPC_P10_ID>", $vpcP10Id).
                         Replace("<EXTERNAL_VPC_P8_ID>", $vpcP8Id)
$renderedToml = [regex]::Replace($renderedToml, 'main\s*=\s*"([^"]+)"', {
    param($m)
    $absMain = (Join-Path $edgeDir $m.Groups[1].Value).Replace('\', '/')
    "main = `"$absMain`""
})
Set-Content -Path $tmpCfg -Value $renderedToml -Encoding UTF8

Remove-Item Env:\CLOUDFLARE_API_TOKEN -ErrorAction SilentlyContinue
$env:CLOUDFLARE_ACCOUNT_ID = $accountId

Push-Location $env:TEMP
try {
    $resD1List = Invoke-WranglerRaw -WranglerArgs @("d1", "list", "--config", $tmpCfg) -EdgeDirectory $edgeDir
    if ($resD1List.ExitCode -ne 0) {
        throw "FAIL_CLOSED: wrangler d1 list exited $($resD1List.ExitCode)"
    }
    if ($resD1List.Output -notmatch 'act_omega_d1_vault_v7322') {
        throw "FAIL_CLOSED: Active rotated D1 database act_omega_d1_vault_v7322 not found in wrangler d1 list"
    }
    if ($resD1List.Output -match '\bact_omega_d1_vault\b(?!_v7322)') {
        throw "FAIL_CLOSED: Retired D1 database act_omega_d1_vault still present in wrangler d1 list"
    }

    $resOldD1Info = Invoke-WranglerRaw -WranglerArgs @("d1", "info", "act_omega_d1_vault", "--config", $tmpCfg) -EdgeDirectory $edgeDir
    if ($resOldD1Info.ExitCode -eq 0) {
        throw "FAIL_CLOSED: Retired D1 database act_omega_d1_vault unexpectedly succeeded on wrangler d1 info"
    }

    $sqlCmd = "SELECT name, type FROM sqlite_master WHERE type='table' ORDER BY name;"
    $resD1Tables = Invoke-WranglerRaw -WranglerArgs @("d1", "execute", $d1DbName, "--remote", "--config", $tmpCfg, "--json", "--command", $sqlCmd) -EdgeDirectory $edgeDir
    if ($resD1Tables.ExitCode -ne 0) {
        throw "FAIL_CLOSED: wrangler d1 execute sqlite_master exited $($resD1Tables.ExitCode)"
    }

    # Parse JSON output from wrangler d1 execute --json
    $jsonStart = $resD1Tables.Output.IndexOf("[")
    if ($jsonStart -lt 0) {
        throw "FAIL_CLOSED: Could not parse JSON array from wrangler d1 execute output"
    }
    $parsedD1 = ($resD1Tables.Output.Substring($jsonStart)) | ConvertFrom-Json
    $allRows = @($parsedD1[0].results)
    $allTableNames = @($allRows | ForEach-Object { [string]$_.name } | Sort-Object)
    $systemTables = @($allTableNames | Where-Object { $_ -like "_cf_*" -or $_ -like "sqlite_*" })
    $userTables = @($allTableNames | Where-Object { $_ -notlike "_cf_*" -and $_ -notlike "sqlite_*" })

    if ($userTables.Count -ne 11 -or $systemTables.Count -ne 2 -or $allTableNames.Count -ne 13) {
        throw "FAIL_CLOSED: Expected 11 user tables + 2 system tables (13 total), measured user=$($userTables.Count) sys=$($systemTables.Count) total=$($allTableNames.Count)"
    }

    $resKvList = Invoke-WranglerRaw -WranglerArgs @("kv", "namespace", "list", "--config", $tmpCfg) -EdgeDirectory $edgeDir
    if ($resKvList.ExitCode -ne 0) {
        throw "FAIL_CLOSED: wrangler kv namespace list exited $($resKvList.ExitCode)"
    }
    if ($resKvList.Output -notmatch 'ACT_OMEGA_KV_V7322') {
        throw "FAIL_CLOSED: Active rotated KV namespace ACT_OMEGA_KV_V7322 not found"
    }
    if ($resKvList.Output -match '"title"\s*:\s*"ACT_OMEGA_KV"') {
        throw "FAIL_CLOSED: Retired KV namespace ACT_OMEGA_KV still present"
    }

    $resHdList = Invoke-WranglerRaw -WranglerArgs @("hyperdrive", "list", "--config", $tmpCfg) -EdgeDirectory $edgeDir
    if ($resHdList.ExitCode -ne 0) {
        throw "FAIL_CLOSED: wrangler hyperdrive list exited $($resHdList.ExitCode)"
    }
    if ($resHdList.Output -notmatch 'act-omega-duckdb-hyperdrive-v7322') {
        throw "FAIL_CLOSED: Active rotated Hyperdrive act-omega-duckdb-hyperdrive-v7322 not found"
    }
    if ($resHdList.Output -match '\bact-omega-duckdb-hyperdrive\b(?!-v7322)') {
        throw "FAIL_CLOSED: Retired Hyperdrive act-omega-duckdb-hyperdrive still present"
    }
} finally {
    Pop-Location
    Remove-Item -Path $tmpCfg -Force -ErrorAction SilentlyContinue
    if ($null -ne $prevToken) { $env:CLOUDFLARE_API_TOKEN = $prevToken } else { Remove-Item Env:\CLOUDFLARE_API_TOKEN -ErrorAction SilentlyContinue }
    if ($null -ne $prevAccount) { $env:CLOUDFLARE_ACCOUNT_ID = $prevAccount } else { Remove-Item Env:\CLOUDFLARE_ACCOUNT_ID -ErrorAction SilentlyContinue }
}

$verifiedAtUtc = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$redD1List = Redact-CloudflareOutput -Text $resD1List.Output -Cfg $cfg
$redOldD1Info = Redact-CloudflareOutput -Text $resOldD1Info.Output -Cfg $cfg
$redD1Tables = Redact-CloudflareOutput -Text $resD1Tables.Output -Cfg $cfg
$redKvList = Redact-CloudflareOutput -Text $resKvList.Output -Cfg $cfg
$redHdList = Redact-CloudflareOutput -Text $resHdList.Output -Cfg $cfg

$acctRedacted = "<REDACTED_account_id_sha256:" + (Get-StringSha256Hex16 -Value $accountId) + ">"
$userListStr = ($userTables -join ", ")
$sysListStr = ($systemTables -join ", ")

$bodyLines = @(
    "# ACT-Omega Net v73.2.3 — Independent Redacted Live Wrangler Verification Receipt (R6)",
    "verified_at_utc: $verifiedAtUtc",
    "account_id_redacted: $acctRedacted",
    "account_id_disposition: PARTIAL (immutable in-place; compensating controls documented in s6_cloudflare_rotation_and_gatekeeper_receipt.json)",
    "d1_active_database: $d1DbName",
    "user_tables_count: $($userTables.Count)",
    "system_tables_count: $($systemTables.Count)",
    "total_sqlite_master_tables: $($allTableNames.Count)",
    "user_tables_list: $userListStr",
    "system_tables_list: $sysListStr",
    "old_instances_confirmed_absent: act_omega_d1_vault, act-omega-duckdb-hyperdrive, ACT_OMEGA_KV",
    "",
    "=== [1] wrangler d1 list (exit=$($resD1List.ExitCode)) ===",
    $redD1List,
    "",
    "=== [2] wrangler d1 info act_omega_d1_vault (expected non-zero not-found, exit=$($resOldD1Info.ExitCode)) ===",
    $redOldD1Info,
    "",
    "=== [3] wrangler d1 execute $d1DbName --remote --json --command `"SELECT name, type FROM sqlite_master WHERE type='table' ORDER BY name;`" (exit=$($resD1Tables.ExitCode)) ===",
    $redD1Tables,
    "",
    "=== [4] wrangler kv namespace list (exit=$($resKvList.ExitCode)) ===",
    $redKvList,
    "",
    "=== [5] wrangler hyperdrive list (exit=$($resHdList.ExitCode)) ===",
    $redHdList,
    ""
)

$bodyText = (($bodyLines -join "`n") -replace "\r\n", "`n" -replace "\r", "`n")
Assert-NoLeaks -Text $bodyText -Cfg $cfg -OperatorKeyBytes $keyBytes

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$bodySha256 = Get-Sha256HexLower -Bytes ($utf8NoBom.GetBytes($bodyText))
$canonicalPayload = "${bodySha256}||${verifiedAtUtc}||d1_tables=11+2sys"
$hmacSha256 = Get-HmacSha256HexLower -KeyBytes $keyBytes -Payload $canonicalPayload

$sigLines = @(
    "=== SIGNATURE_BLOCK ===",
    "verified_at_utc: $verifiedAtUtc",
    "transcript_sha256: $bodySha256",
    "canonical_payload: $canonicalPayload",
    "hmac_algorithm: RFC2104_HMAC_SHA256",
    "hmac_sha256: $hmacSha256",
    "trust_boundary: RFC2104_HMAC_SHA256 signed externally by 00_control/cloudflare_edge/Verify-CloudflareRotationLive.ps1 using the local external operator key (ACT_OMEGA_OPERATOR_KEY / ~/.act_omega_operator_vault_key)."
)
$finalText = $bodyText + (($sigLines -join "`n") + "`n")
$finalText = $finalText -replace "\r\n", "`n" -replace "\r", "`n"
Assert-NoLeaks -Text $finalText -Cfg $cfg -OperatorKeyBytes $keyBytes

$receiptParent = Split-Path -Parent $receiptPath
if (-not (Test-Path $receiptParent)) {
    New-Item -ItemType Directory -Force -Path $receiptParent | Out-Null
}
[System.IO.File]::WriteAllText($receiptPath, $finalText, $utf8NoBom)

Write-Output ("[CF-ROTATION-LIVE PASS] d1_tables=$($userTables.Count)+$($systemTables.Count)sys sha256=$($bodySha256.Substring(0,16)) hmac=$($hmacSha256.Substring(0,16))... receipt=03_vault/receipts/s6_cloudflare_live_wrangler_verification.txt")
exit 0
