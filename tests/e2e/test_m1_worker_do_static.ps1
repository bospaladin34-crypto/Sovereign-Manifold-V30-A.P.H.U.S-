# C:\sovereign_manifold_v31\tests\e2e\test_m1_worker_do_static.ps1
# Static Invariant and Regression Audit for Cloudflare Edge Durable Object
$ErrorActionPreference = "Stop"
$targetFiles = @(
    "C:\sovereign_manifold_v31\00_control\cloudflare_edge\worker_continuum_do.js",
    "C:\sovereign_manifold_v31\00_control\cloudflare_edge\worker_vpc_shadow_v3700.js"
)

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "   MILESTONE 1: CLOUDFLARE EDGE DO STATIC INVARIANT AUDIT                  " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan

$allPass = $true

foreach ($file in $targetFiles) {
    if (-not (Test-Path $file)) {
        Write-Host "  [-] Target file missing: $($file)" -ForegroundColor Red
        $allPass = $false
        continue
    }
    $raw = Get-Content -Path $file -Raw

    # Test 1: Zero runtime SELECT COUNT(*) scans
    # Note: Only a single point query or initialization query is allowed; during updates/sync, zero SELECT COUNT(*) must be present.
    $activeCountMatches = [regex]::Matches($raw, '(?i)SELECT\s+COUNT\s*\(\s*\*\s*\)\s+AS\s+cnt\s+FROM\s+edge_heartbeat')
    if ($activeCountMatches.Count -gt 0) {
        Write-Host "  [FAIL] $($file) - Detected $($activeCountMatches.Count) unbounded SELECT COUNT(*) queries! (Req: 0)" -ForegroundColor Red
        $allPass = $false
    } else {
        Write-Host "  [PASS] $($file) - Zero active SELECT COUNT(*) queries detected." -ForegroundColor Green
    }

    # Test 2: Bounded 8-Row Ring Buffer Pruning Statement
    $pruneMatches = [regex]::Matches($raw, '(?i)DELETE\s+FROM\s+edge_heartbeat\s+WHERE\s+id\s+NOT\s+IN\s*\(\s*SELECT\s+id\s+FROM\s+edge_heartbeat\s+ORDER\s+BY\s+id\s+DESC\s+LIMIT\s+8\s*\)')
    if ($pruneMatches.Count -lt 1) {
        Write-Host "  [FAIL] $($file) - Missing 8-row ring buffer pruning query! (Req: >= 1)" -ForegroundColor Red
        $allPass = $false
    } else {
        Write-Host "  [PASS] $($file) - 8-row ring buffer pruning query verified ($($pruneMatches.Count) call sites)." -ForegroundColor Green
    }

    # Test 3: In-Memory Heartbeat Counter Pattern
    if ($raw -match 'this\.cachedHeartbeatCounter') {
        Write-Host "  [PASS] $($file) - In-memory heartbeat counter 'this.cachedHeartbeatCounter' verified." -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] $($file) - Missing 'this.cachedHeartbeatCounter' pattern!" -ForegroundColor Red
        $allPass = $false
    }

    # Test 4: SQLite 60-Second Write Debouncing on shm_continuum_state
    if (($raw -match 'nodeLastWriteMs') -and ($raw -match '60000')) {
        Write-Host "  [PASS] $($file) - 60-second write debouncing logic ('nodeLastWriteMs' + 60000ms threshold) verified." -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] $($file) - Missing 60-second write debouncing for shm_continuum_state!" -ForegroundColor Red
        $allPass = $false
    }

    # Test 5: In-Memory 30-Second TTL D1 Cache in Global Worker Scope
    if (($raw -match 'gD1TelemetryCache') -and ($raw -match '30000')) {
        Write-Host "  [PASS] $($file) - In-memory 30-second TTL D1 cache ('gD1TelemetryCache' + 30000ms TTL) verified." -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] $($file) - Missing 30-second D1 cache structure!" -ForegroundColor Red
        $allPass = $false
    }

    # Test 6: In-Memory Status Serving on /shadow/status
    if ($raw -match 'this\.cachedLatestHeartbeat') {
        Write-Host "  [PASS] $($file) - In-memory status cache 'this.cachedLatestHeartbeat' verified." -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] $($file) - /shadow/status is not served from in-memory cache!" -ForegroundColor Red
        $allPass = $false
    }
}

Write-Host "==========================================================================" -ForegroundColor Cyan
if (-not $allPass) {
    throw "Static Invariant Audit failed for Cloudflare Edge DO."
}
Write-Host "  STATIC INVARIANT AUDIT PASSED: ALL 6 CHECKS MET" -ForegroundColor Green
Write-Host ""
