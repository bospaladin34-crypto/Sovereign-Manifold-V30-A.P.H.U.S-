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
    Write-Host "  [E2E 1/7 CLEAN STATIC]   [PASS] Invoke-BrutalAgentGatekeeper.ps1 -StaticOnly exited 0" -ForegroundColor Green

    # Injected active CF ID fixture -> -StaticOnly MUST exit 1
    $cfCfg = Get-Content -Raw $CfIdsPath | ConvertFrom-Json
    $injFile = Join-Path $tmpDir "leaked_fixture.txt"
    [System.IO.File]::WriteAllText($injFile, "kv_id = `"$($cfCfg.kv_id)`"`n")
    $injOut = powershell -NoProfile -ExecutionPolicy Bypass -File $Gatekeeper -StaticOnly -ExtraFilesToScan @($injFile) 2>&1
    $injExit = $LASTEXITCODE
    if ($injExit -eq 0 -or (($injOut -join "`n") -notmatch "CF_ACTIVE_ID_LEAK")) {
        throw "FATAL: -StaticOnly did NOT fail with CF_ACTIVE_ID_LEAK on injected active CF ID (exit=$injExit)"
    }
    Write-Host "  [E2E 2/7 CF INJECTION]   [PASS] -StaticOnly exited $injExit and flagged CF_ACTIVE_ID_LEAK" -ForegroundColor Green

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
    Write-Host "  [E2E 3/7 LEAN 1009]      [PASS] -StaticOnly exited $leanExit and flagged LEAN4_COUNT_LOW" -ForegroundColor Green

    # Active .rs stale D1 count injection -> -StaticOnly MUST exit 1 with STALE_D1_TABLE_COUNT
    $rsStaleD1File = Join-Path $tmpDir "injected_stale_d1.rs"
    [System.IO.File]::WriteAllText($rsStaleD1File, "pub fn fake_d1() -> &'static str { `"{\`"tables_count\`":10,\`"label\`":\`"10-Table D1\`"}`" }`n")
    $rsD1Out = powershell -NoProfile -ExecutionPolicy Bypass -File $Gatekeeper -StaticOnly -ExtraFilesToScan @($rsStaleD1File) 2>&1
    $rsD1Exit = $LASTEXITCODE
    if ($rsD1Exit -eq 0 -or (($rsD1Out -join "`n") -notmatch "STALE_D1_TABLE_COUNT")) {
        throw "FATAL: -StaticOnly did NOT fail with STALE_D1_TABLE_COUNT on injected .rs 10-Table fixture (exit=$rsD1Exit)"
    }
    Write-Host "  [E2E 4/7 RS STALE D1]    [PASS] -StaticOnly exited $rsD1Exit and flagged STALE_D1_TABLE_COUNT" -ForegroundColor Green

    # Active .rs stale retired D1 table names injection -> -StaticOnly MUST exit 1 with STALE_D1_TABLE_COUNT
    $rsStaleNamesFile = Join-Path $tmpDir "injected_stale_d1_names.rs"
    [System.IO.File]::WriteAllText($rsStaleNamesFile, "pub const OLD_D1_TABLES: &str = `"v44_operationalized_research_shards, v44_multiturn_discourse_memory`";`n")
    $rsNamesOut = powershell -NoProfile -ExecutionPolicy Bypass -File $Gatekeeper -StaticOnly -ExtraFilesToScan @($rsStaleNamesFile) 2>&1
    $rsNamesExit = $LASTEXITCODE
    if ($rsNamesExit -eq 0 -or (($rsNamesOut -join "`n") -notmatch "STALE_D1_TABLE_COUNT")) {
        throw "FATAL: -StaticOnly did NOT fail with STALE_D1_TABLE_COUNT on injected retired table names (exit=$rsNamesExit)"
    }
    Write-Host "  [E2E 5/7 RS RETIRED D1]  [PASS] -StaticOnly exited $rsNamesExit and flagged STALE_D1_TABLE_COUNT" -ForegroundColor Green

    # Comment-only .rs negative control -> -StaticOnly MUST exit 0 (proving // comment stripping avoids false positives)
    $rsCommentFile = Join-Path $tmpDir "comment_only_d1.rs"
    [System.IO.File]::WriteAllText($rsCommentFile, "// Historical note: 10-Table v44_operationalized_research_shards act_omega_d1_vault`n")
    $rsCommentOut = powershell -NoProfile -ExecutionPolicy Bypass -File $Gatekeeper -StaticOnly -ExtraFilesToScan @($rsCommentFile) 2>&1
    $rsCommentExit = $LASTEXITCODE
    if ($rsCommentExit -ne 0) {
        throw "FATAL: -StaticOnly failed unexpectedly on comment-only .rs control (exit=$rsCommentExit): $($rsCommentOut -join "`n")"
    }
    Write-Host "  [E2E 6/7 RS COMMENT]     [PASS] -StaticOnly exited 0 on // comment-only .rs control" -ForegroundColor Green

    # Active .rs retired un-suffixed act_omega_d1_vault injection -> -StaticOnly MUST exit 1 with STALE_D1_TABLE_COUNT
    $rsStaleDbFile = Join-Path $tmpDir "injected_stale_d1_db.rs"
    [System.IO.File]::WriteAllText($rsStaleDbFile, "pub const DB: &str = `"act_omega_d1_vault`";`n")
    $rsDbOut = powershell -NoProfile -ExecutionPolicy Bypass -File $Gatekeeper -StaticOnly -ExtraFilesToScan @($rsStaleDbFile) 2>&1
    $rsDbExit = $LASTEXITCODE
    if ($rsDbExit -eq 0 -or (($rsDbOut -join "`n") -notmatch "STALE_D1_TABLE_COUNT")) {
        throw "FATAL: -StaticOnly did NOT fail with STALE_D1_TABLE_COUNT on injected un-suffixed act_omega_d1_vault (exit=$rsDbExit)"
    }
    Write-Host "  [E2E 7/7 RS UNSUFFIXED]  [PASS] -StaticOnly exited $rsDbExit and flagged STALE_D1_TABLE_COUNT" -ForegroundColor Green
} finally {
    Remove-Item $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "=== M3 GATEKEEPER NEGATIVE-INJECTION E2E TEST: ALL PASSED ===" -ForegroundColor Green
exit 0
