# =============================================================================
# ACT-Omega Net v73.2.2 — M3 Gatekeeper Negative-Injection E2E Verification
# Tests Item #5 (repo-wide git ls-files CF ID leak scan) and
#       Item #6 (1,009-theorem Lean 4 negative threshold rejection)
# via live subprocess invocations of 00_control\Invoke-BrutalAgentGatekeeper.ps1.
# ZERO raw Cloudflare IDs or secrets appear in this test.
# =============================================================================
$ErrorActionPreference = "Stop"
$RepoRoot = "C:\sovereign_manifold_v31"
$Gatekeeper = Join-Path $RepoRoot "00_control\Invoke-BrutalAgentGatekeeper.ps1"
$CfIdsPath = "C:\Users\Nbell\.act_omega_cloudflare_ids.json"

Write-Host "=== M3 GATEKEEPER NEGATIVE-INJECTION E2E TEST (ITEMS #5 & #6) ===" -ForegroundColor Cyan

# 1. Built-in 5-point negative-injection suite inside Invoke-BrutalAgentGatekeeper.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File $Gatekeeper -TestNegativeCloudflareInjection
if ($LASTEXITCODE -ne 0) {
    throw "FATAL: Invoke-BrutalAgentGatekeeper.ps1 -TestNegativeCloudflareInjection failed with exit $LASTEXITCODE"
}

# 2. Subprocess -StaticOnly negative tests (exit code 1 required on injected CF ID & 1,009-theorem Lean file)
$tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) "act_omega_m3_e2e_neg_$([System.Diagnostics.Process]::GetCurrentProcess().Id)"
New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null
try {
    # Clean -StaticOnly MUST pass (exit 0)
    $cleanOut = powershell -NoProfile -ExecutionPolicy Bypass -File $Gatekeeper -StaticOnly 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "FATAL: Clean -StaticOnly failed unexpectedly: $($cleanOut -join "`n")"
    }
    Write-Host "  [E2E 1/15 CLEAN STATIC]   [PASS] Invoke-BrutalAgentGatekeeper.ps1 -StaticOnly exited 0" -ForegroundColor Green

    # Injected active CF ID fixture -> -StaticOnly MUST exit 1
    $cfCfg = Get-Content -Raw $CfIdsPath | ConvertFrom-Json
    $injFile = Join-Path $tmpDir "leaked_fixture.txt"
    [System.IO.File]::WriteAllText($injFile, "kv_id = `"$($cfCfg.kv_id)`"`n")
    $injOut = powershell -NoProfile -ExecutionPolicy Bypass -File $Gatekeeper -StaticOnly -ExtraFilesToScan @($injFile) 2>&1
    $injExit = $LASTEXITCODE
    if ($injExit -eq 0 -or (($injOut -join "`n") -notmatch "CF_ACTIVE_ID_LEAK")) {
        throw "FATAL: -StaticOnly did NOT fail with CF_ACTIVE_ID_LEAK on injected active CF ID (exit=$injExit)"
    }
    Write-Host "  [E2E 2/15 CF INJECTION]   [PASS] -StaticOnly exited $injExit and flagged CF_ACTIVE_ID_LEAK" -ForegroundColor Green

    # 1,009-theorem Lean override fixture -> -StaticOnly MUST exit 1 with LEAN4_COUNT_LOW
    $lean1009File = Join-Path $tmpDir "SovereignManifoldTheorems_1009.lean"
    $sb = New-Object System.Text.StringBuilder
    for ($i = 1; $i -le 1009; $i++) {
        [void]$sb.AppendLine("theorem e2e_neg_$i : True := by trivial")
    }
    [System.IO.File]::WriteAllText($lean1009File, $sb.ToString())
    $leanOut = powershell -NoProfile -ExecutionPolicy Bypass -File $Gatekeeper -StaticOnly -LeanOverridePath $lean1009File 2>&1
    $leanExit = $LASTEXITCODE
    if ($leanExit -eq 0 -or (($leanOut -join "`n") -notmatch "LEAN4_COUNT_LOW")) {
        throw "FATAL: -StaticOnly did NOT fail with LEAN4_COUNT_LOW on 1,009-theorem fixture (exit=$leanExit)"
    }
    Write-Host "  [E2E 3/15 LEAN 1009]      [PASS] -StaticOnly exited $leanExit and flagged LEAN4_COUNT_LOW" -ForegroundColor Green

    # Active .rs stale D1 count injection -> -StaticOnly MUST exit 1 with STALE_D1_TABLE_COUNT
    $rsStaleD1File = Join-Path $tmpDir "injected_stale_d1.rs"
    [System.IO.File]::WriteAllText($rsStaleD1File, "pub fn fake_d1() -> &'static str { `"{\`"tables_count\`":10,\`"label\`":\`"10-Table D1\`"}`" }`n")
    $rsD1Out = powershell -NoProfile -ExecutionPolicy Bypass -File $Gatekeeper -StaticOnly -ExtraFilesToScan @($rsStaleD1File) 2>&1
    $rsD1Exit = $LASTEXITCODE
    if ($rsD1Exit -eq 0 -or (($rsD1Out -join "`n") -notmatch "STALE_D1_TABLE_COUNT")) {
        throw "FATAL: -StaticOnly did NOT fail with STALE_D1_TABLE_COUNT on injected .rs 10-Table fixture (exit=$rsD1Exit)"
    }
    Write-Host "  [E2E 4/15 RS STALE D1]    [PASS] -StaticOnly exited $rsD1Exit and flagged STALE_D1_TABLE_COUNT" -ForegroundColor Green

    # Active .rs stale retired D1 table names injection -> -StaticOnly MUST exit 1 with STALE_D1_TABLE_COUNT
    $rsStaleNamesFile = Join-Path $tmpDir "injected_stale_d1_names.rs"
    [System.IO.File]::WriteAllText($rsStaleNamesFile, "pub const OLD_D1_TABLES: &str = `"v44_operationalized_research_shards, v44_multiturn_discourse_memory`";`n")
    $rsNamesOut = powershell -NoProfile -ExecutionPolicy Bypass -File $Gatekeeper -StaticOnly -ExtraFilesToScan @($rsStaleNamesFile) 2>&1
    $rsNamesExit = $LASTEXITCODE
    if ($rsNamesExit -eq 0 -or (($rsNamesOut -join "`n") -notmatch "STALE_D1_TABLE_COUNT")) {
        throw "FATAL: -StaticOnly did NOT fail with STALE_D1_TABLE_COUNT on injected retired table names (exit=$rsNamesExit)"
    }
    Write-Host "  [E2E 5/15 RS RETIRED D1]  [PASS] -StaticOnly exited $rsNamesExit and flagged STALE_D1_TABLE_COUNT" -ForegroundColor Green

    # Comment-only .rs negative control -> -StaticOnly MUST exit 0 (proving // comment stripping avoids false positives)
    $rsCommentFile = Join-Path $tmpDir "comment_only_d1.rs"
    [System.IO.File]::WriteAllText($rsCommentFile, "// Historical note: 10-Table v44_operationalized_research_shards act_omega_d1_vault`n")
    $rsCommentOut = powershell -NoProfile -ExecutionPolicy Bypass -File $Gatekeeper -StaticOnly -ExtraFilesToScan @($rsCommentFile) 2>&1
    $rsCommentExit = $LASTEXITCODE
    if ($rsCommentExit -ne 0) {
        throw "FATAL: -StaticOnly failed unexpectedly on comment-only .rs control (exit=$rsCommentExit): $($rsCommentOut -join "`n")"
    }
    Write-Host "  [E2E 6/15 RS COMMENT]     [PASS] -StaticOnly exited 0 on // comment-only .rs control" -ForegroundColor Green

    # Active .rs retired un-suffixed act_omega_d1_vault injection -> -StaticOnly MUST exit 1 with STALE_D1_TABLE_COUNT
    $rsStaleDbFile = Join-Path $tmpDir "injected_stale_d1_db.rs"
    [System.IO.File]::WriteAllText($rsStaleDbFile, "pub const DB: &str = `"act_omega_d1_vault`";`n")
    $rsDbOut = powershell -NoProfile -ExecutionPolicy Bypass -File $Gatekeeper -StaticOnly -ExtraFilesToScan @($rsStaleDbFile) 2>&1
    $rsDbExit = $LASTEXITCODE
    if ($rsDbExit -eq 0 -or (($rsDbOut -join "`n") -notmatch "STALE_D1_TABLE_COUNT")) {
        throw "FATAL: -StaticOnly did NOT fail with STALE_D1_TABLE_COUNT on injected un-suffixed act_omega_d1_vault (exit=$rsDbExit)"
    }
    Write-Host "  [E2E 7/15 RS UNSUFFIXED]  [PASS] -StaticOnly exited $rsDbExit and flagged STALE_D1_TABLE_COUNT" -ForegroundColor Green

    # Trailing inline comment // 10 Tables -> -StaticOnly MUST exit 1 with STALE_D1_TABLE_COUNT
    $rsInlineSimpleFile = Join-Path $tmpDir "inline_comment_d1_simple.rs"
    [System.IO.File]::WriteAllText($rsInlineSimpleFile, "let x = 1; // 10 Tables`n")
    $rsInlineSimpleOut = powershell -NoProfile -ExecutionPolicy Bypass -File $Gatekeeper -StaticOnly -ExtraFilesToScan @($rsInlineSimpleFile) 2>&1
    $rsInlineSimpleExit = $LASTEXITCODE
    if ($rsInlineSimpleExit -eq 0 -or (($rsInlineSimpleOut -join "`n") -notmatch "STALE_D1_TABLE_COUNT")) {
        throw "FATAL: -StaticOnly did NOT fail with STALE_D1_TABLE_COUNT on inline comment '// 10 Tables' (exit=$rsInlineSimpleExit)"
    }
    Write-Host "  [E2E 8/15 RS INLINE //]   [PASS] -StaticOnly exited $rsInlineSimpleExit and flagged STALE_D1_TABLE_COUNT on 'let x = 1; // 10 Tables'" -ForegroundColor Green

    # URL string + trailing inline comment // 10 Tables -> -StaticOnly MUST exit 1 with STALE_D1_TABLE_COUNT
    $rsInlineUrlFile = Join-Path $tmpDir "inline_comment_d1_url.rs"
    [System.IO.File]::WriteAllText($rsInlineUrlFile, "let u = `"https://act-omega-net.dev`"; // 10 Tables`n")
    $rsInlineUrlOut = powershell -NoProfile -ExecutionPolicy Bypass -File $Gatekeeper -StaticOnly -ExtraFilesToScan @($rsInlineUrlFile) 2>&1
    $rsInlineUrlExit = $LASTEXITCODE
    if ($rsInlineUrlExit -eq 0 -or (($rsInlineUrlOut -join "`n") -notmatch "STALE_D1_TABLE_COUNT")) {
        throw "FATAL: -StaticOnly did NOT fail with STALE_D1_TABLE_COUNT on URL string + '// 10 Tables' (exit=$rsInlineUrlExit)"
    }
    Write-Host "  [E2E 9/15 RS URL + //]   [PASS] -StaticOnly exited $rsInlineUrlExit and flagged STALE_D1_TABLE_COUNT on URL + '// 10 Tables'" -ForegroundColor Green

    # Clean URL string + escaped \" + HISTORICAL_PRE_V7322 inline comment -> -StaticOnly MUST exit 0
    $rsCleanPosFile = Join-Path $tmpDir "clean_url_escaped_historical.rs"
    $rsCleanPosBody = @(
        'pub const API_URL: &str = "https://act-omega-net.dev/api/v1/health"; // CHAIN 368 historical'
        'pub const ESC_STR: &str = "escaped \" quote // https://example.com"; // HISTORICAL_PRE_V7322 10-Table schema'
    ) -join "`n"
    [System.IO.File]::WriteAllText($rsCleanPosFile, "$rsCleanPosBody`n")
    $rsCleanPosOut = powershell -NoProfile -ExecutionPolicy Bypass -File $Gatekeeper -StaticOnly -ExtraFilesToScan @($rsCleanPosFile) 2>&1
    $rsCleanPosExit = $LASTEXITCODE
    if ($rsCleanPosExit -ne 0) {
        throw "FATAL: -StaticOnly failed unexpectedly on clean URL/escaped/HISTORICAL_PRE_V7322 control (exit=$rsCleanPosExit): $($rsCleanPosOut -join "`n")"
    }
    Write-Host "  [E2E 10/15 RS URL+HIST]   [PASS] -StaticOnly exited 0 on clean URL + escaped quotes + HISTORICAL_PRE_V7322" -ForegroundColor Green

    # Char literal '\"', lifetime 'a, and raw string r#\"...\"# -> -StaticOnly MUST exit 0
    $rsRawCharFile = Join-Path $tmpDir "clean_raw_char_lifetime.rs"
    $rsRawCharBody = @(
        "pub fn parse<'a>(s: &'a str) -> &'a str {"
        '    let _q = ''"'';'
        '    let _r = r#"https://act-omega-net.dev // raw_ok"#; // CHAIN 368'
        "    s"
        "}"
    ) -join "`n"
    [System.IO.File]::WriteAllText($rsRawCharFile, "$rsRawCharBody`n")
    $rsRawCharOut = powershell -NoProfile -ExecutionPolicy Bypass -File $Gatekeeper -StaticOnly -ExtraFilesToScan @($rsRawCharFile) 2>&1
    $rsRawCharExit = $LASTEXITCODE
    if ($rsRawCharExit -ne 0) {
        throw "FATAL: -StaticOnly failed unexpectedly on char/lifetime/raw-string control (exit=$rsRawCharExit): $($rsRawCharOut -join "`n")"
    }
    Write-Host "  [E2E 11/15 RS RAW+CHAR]   [PASS] -StaticOnly exited 0 on char literal, lifetime, and raw string control" -ForegroundColor Green

    # Regression: escaped single-quote char literal ('\'','"') must NOT desync string state across lines
    $rsEscSqFile = Join-Path $tmpDir "adv_escaped_sq_bypass.rs"
    $rsEscSqBody = @(
        'let p = (''\'''',''"'');'
        'let h = "https://HISTORICAL_PRE_V7322"; // 10 Tables'
    ) -join "`n"
    [System.IO.File]::WriteAllText($rsEscSqFile, "$rsEscSqBody`n")
    $rsEscSqOut = powershell -NoProfile -ExecutionPolicy Bypass -File $Gatekeeper -StaticOnly -ExtraFilesToScan @($rsEscSqFile) 2>&1
    $rsEscSqExit = $LASTEXITCODE
    if ($rsEscSqExit -eq 0 -or (($rsEscSqOut -join "`n") -notmatch "STALE_D1_TABLE_COUNT")) {
        throw "FATAL: -StaticOnly did NOT fail with STALE_D1_TABLE_COUNT after escaped single-quote char literal (exit=$rsEscSqExit)"
    }
    Write-Host "  [E2E 12/15 ESCAPED SQ]    [PASS] -StaticOnly exited $rsEscSqExit and flagged STALE_D1_TABLE_COUNT after ('\'','`"')" -ForegroundColor Green

    # Regression: block comment containing quote /* " */ must NOT flip inString across lines
    $rsBlockQuoteFile = Join-Path $tmpDir "adv_block_quote_bypass.rs"
    $rsBlockQuoteBody = @(
        'let x = /* " */ 1;'
        'let h = "https://HISTORICAL_PRE_V7322"; // 10 Tables'
    ) -join "`n"
    [System.IO.File]::WriteAllText($rsBlockQuoteFile, "$rsBlockQuoteBody`n")
    $rsBlockQuoteOut = powershell -NoProfile -ExecutionPolicy Bypass -File $Gatekeeper -StaticOnly -ExtraFilesToScan @($rsBlockQuoteFile) 2>&1
    $rsBlockQuoteExit = $LASTEXITCODE
    if ($rsBlockQuoteExit -eq 0 -or (($rsBlockQuoteOut -join "`n") -notmatch "STALE_D1_TABLE_COUNT")) {
        throw "FATAL: -StaticOnly did NOT fail with STALE_D1_TABLE_COUNT after block comment /* `" */ (exit=$rsBlockQuoteExit)"
    }
    Write-Host "  [E2E 13/15 BLOCK QUOTE]   [PASS] -StaticOnly exited $rsBlockQuoteExit and flagged STALE_D1_TABLE_COUNT after /* `" */" -ForegroundColor Green

    # Regression: un-annotated inline block comment /* 10 Tables */ on code line MUST trigger STALE_D1_TABLE_COUNT
    $rsInlineBlockFile = Join-Path $tmpDir "adv_inline_block_d1.rs"
    [System.IO.File]::WriteAllText($rsInlineBlockFile, "let x = /* 10 Tables */ 1;`n")
    $rsInlineBlockOut = powershell -NoProfile -ExecutionPolicy Bypass -File $Gatekeeper -StaticOnly -ExtraFilesToScan @($rsInlineBlockFile) 2>&1
    $rsInlineBlockExit = $LASTEXITCODE
    if ($rsInlineBlockExit -eq 0 -or (($rsInlineBlockOut -join "`n") -notmatch "STALE_D1_TABLE_COUNT")) {
        throw "FATAL: -StaticOnly did NOT fail with STALE_D1_TABLE_COUNT on inline block comment /* 10 Tables */ (exit=$rsInlineBlockExit)"
    }
    Write-Host "  [E2E 14/15 INLINE /*]     [PASS] -StaticOnly exited $rsInlineBlockExit and flagged STALE_D1_TABLE_COUNT on /* 10 Tables */" -ForegroundColor Green

    # Regression clean control: ('\'','"'), /* " */, /* CHAIN 368 */, nested /* /* "nested" */ */, and HISTORICAL_PRE_V7322 -> exit 0
    $rsBlockCleanFile = Join-Path $tmpDir "clean_escaped_sq_nested_block.rs"
    $rsBlockCleanBody = @(
        'let p = (''\'''',''"''); // CHAIN 368'
        'let x = /* " */ 1; /* CHAIN 368 */'
        'let ok = /* /* "nested" */ */ "https://act-omega-net.dev"; // HISTORICAL_PRE_V7322 10-Table'
    ) -join "`n"
    [System.IO.File]::WriteAllText($rsBlockCleanFile, "$rsBlockCleanBody`n")
    $rsBlockCleanOut = powershell -NoProfile -ExecutionPolicy Bypass -File $Gatekeeper -StaticOnly -ExtraFilesToScan @($rsBlockCleanFile) 2>&1
    $rsBlockCleanExit = $LASTEXITCODE
    if ($rsBlockCleanExit -ne 0) {
        throw "FATAL: -StaticOnly failed unexpectedly on clean escaped-sq + nested block-comment control (exit=$rsBlockCleanExit): $($rsBlockCleanOut -join "`n")"
    }
    Write-Host "  [E2E 15/15 BLOCK CLEAN]   [PASS] -StaticOnly exited 0 on clean ('\'','`"') + /* `" */ + nested /* /* `"nested`" */ */ control" -ForegroundColor Green
} finally {
    Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "=== M3 GATEKEEPER NEGATIVE-INJECTION E2E TEST: ALL PASSED ===" -ForegroundColor Green
exit 0
