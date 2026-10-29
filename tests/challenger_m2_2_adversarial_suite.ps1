# Challenger M2-2-2: Adversarial Verification & Burst Test Suite
# Target: Milestone 2 Iteration 2 (ACT-Omega Net v50.2.0 Production Release Audit Remediation)
# File: C:\sovereign_manifold_v31\tests\challenger_m2_2_adversarial_suite.ps1
# Constraints: Zero Python | Zero Mock Data | Empirical Verification Mandate

param(
    [string]$RepoRoot = "C:\sovereign_manifold_v31",
    [switch]$Detailed = $true
)

$ErrorActionPreference = "Continue"

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "  CHALLENGER M2-2-2: ADVERSARIAL PARITY, ROUTE & BURST SUITE              " -ForegroundColor Cyan
Write-Host "  Target Root: $RepoRoot                                                  " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan

$TotalTests = 0
$PassedTests = 0
$FailedTests = 0
$Violations = [System.Collections.Generic.List[string]]::new()

function Record-Result {
    param(
        [string]$TestCategory,
        [string]$Description,
        [bool]$Success,
        [string]$Detail = ""
    )
    $script:TotalTests++
    if ($Success) {
        $script:PassedTests++
        Write-Host "  [PASS] [$TestCategory] $Description" -ForegroundColor Green
        if ($Detail -and $script:Detailed) {
            Write-Host "         $Detail" -ForegroundColor DarkGreen
        }
    } else {
        $script:FailedTests++
        $err = "[$TestCategory] $Description : $Detail"
        $script:Violations.Add($err)
        Write-Host "  [FAIL] $err" -ForegroundColor Red
    }
}

# -----------------------------------------------------------------------------
# SUITE 1: BINARY PARITY & PROCESS HEALTH
# -----------------------------------------------------------------------------
Write-Host "`n--- [SUITE 1: Binary Parity & Process Binding] ---" -ForegroundColor Yellow

$stageExe = Join-Path $RepoRoot "01_l0_rust\target_stage\release\v31_swarm.exe"
$targetExe = Join-Path $RepoRoot "01_l0_rust\target\release\v31_swarm.exe"

$stageExists = Test-Path $stageExe
$targetExists = Test-Path $targetExe

Record-Result "Binary" "Stage binary exists at $stageExe" $stageExists
Record-Result "Binary" "Target binary exists at $targetExe" $targetExists

if ($stageExists -and $targetExists) {
    $hStage = (Get-FileHash $stageExe -Algorithm SHA256).Hash
    $hTarget = (Get-FileHash $targetExe -Algorithm SHA256).Hash
    $lenStage = (Get-Item $stageExe).Length
    $lenTarget = (Get-Item $targetExe).Length

    Record-Result "Binary" "Stage and Target SHA-256 hashes match bit-for-bit" ($hStage -eq $hTarget) "Stage=$hStage Target=$hTarget"
    Record-Result "Binary" "Stage and Target file lengths match" ($lenStage -eq $lenTarget) "Length=$lenStage bytes"
    Record-Result "Binary" "Binary size is non-trivial (>1MB)" ($lenStage -gt 1048576) "Size=$lenStage"
}

# Process binding check
$proc = Get-Process -Name v31_swarm -ErrorAction SilentlyContinue
$procRunning = ($null -ne $proc -and $proc.Count -gt 0)
Record-Result "Process" "v31_swarm process is actively running" $procRunning
if ($procRunning) {
    $firstProc = $proc[0]
    $procResponding = $firstProc.Responding
    Record-Result "Process" "v31_swarm process is responding" $procResponding "PID=$($firstProc.Id)"
    $procPath = $firstProc.Path
    Record-Result "Process" "v31_swarm runs from target release path" ($procPath -eq (Resolve-Path $targetExe).Path) "Path=$procPath"
}

# -----------------------------------------------------------------------------
# SUITE 2: ZERO-BRACKET STATICS & MIRROR PARITY
# -----------------------------------------------------------------------------
Write-Host "`n--- [SUITE 2: Zero-Bracket Statics & Mirror Parity] ---" -ForegroundColor Yellow

# Tier 1: Constitutional v33..v52+ modules (34 files)
$vFiles = Get-ChildItem -Path (Join-Path $RepoRoot "01_l0_rust\src\v*.rs") -File | Where-Object { $_.Name -match '^v(3[3-9]|[4-9][0-9])_' }
$vCount = $vFiles.Count
Record-Result "Brackets" "Found 34 constitutional v33..v52+ modules" ($vCount -eq 34) "Count=$vCount"

$tier1BracketCount = 0
foreach ($vf in $vFiles) {
    $raw = [System.IO.File]::ReadAllBytes($vf.FullName)
    $bCount = ($raw | Where-Object { $_ -eq 0x5B -or $_ -eq 0x5D }).Count
    if ($bCount -gt 0) {
        $tier1BracketCount += $bCount
    }
}
Record-Result "Brackets" "Tier 1: 34 Constitutional modules strictly contain 0 square brackets" ($tier1BracketCount -eq 0) "Measured brackets=$tier1BracketCount"

# Tier 2: Delta check on git diff against baseline f5c671be
$diffCmd = git diff f5c671be 01_l0_rust/src/bin/v31_swarm.rs
$diffAddedBracketLines = @($diffCmd | Select-String '^\+.*[\[\]]')
Record-Result "Brackets" "Tier 2: Added square bracket lines in git diff against f5c671be is 0" ($diffAddedBracketLines.Count -eq 0) "Added bracket lines=$($diffAddedBracketLines.Count)"

# Mirror check: bin/v31_swarm.rs == src/v31_swarm.rs
$fBin = Join-Path $RepoRoot "01_l0_rust\src\bin\v31_swarm.rs"
$fSrc = Join-Path $RepoRoot "01_l0_rust\src\v31_swarm.rs"
$hBin = (Get-FileHash $fBin -Algorithm SHA256).Hash
$hSrc = (Get-FileHash $fSrc -Algorithm SHA256).Hash
Record-Result "Mirrors" "v31_swarm.rs bin and src mirrors match 1:1" ($hBin -eq $hSrc) "SHA256=$hBin"

# -----------------------------------------------------------------------------
# SUITE 3: CLOUDFLARE WORKER MIRROR PARITY & WRANGLER DEPLOYMENT
# -----------------------------------------------------------------------------
Write-Host "`n--- [SUITE 3: Cloudflare Edge Worker Parity & Deployment ID] ---" -ForegroundColor Yellow

$w1 = Join-Path $RepoRoot "00_control\cloudflare_edge\worker_vpc_shadow_v3700.js"
$w2 = Join-Path $RepoRoot "worker_vpc_shadow_v3700.js"
$w3 = Join-Path $RepoRoot "00_control\cloudflare_edge\worker_continuum_do.js"

$hw1 = (Get-FileHash $w1 -Algorithm SHA256).Hash
$hw2 = (Get-FileHash $w2 -Algorithm SHA256).Hash
$hw3 = (Get-FileHash $w3 -Algorithm SHA256).Hash

Record-Result "WorkerParity" "worker_vpc_shadow_v3700.js mirrors match 1:1" ($hw1 -eq $hw2 -and $hw2 -eq $hw3) "Hash=$hw1"

# Check active deployment version via wrangler
$expectedDeploymentId = "90f6e875-e7c8-4707-8d2c-824ffc504472"
$wranglerDeployments = npx wrangler deployments list 2>&1 | Out-String
$hasDeploymentId = $wranglerDeployments -match [regex]::Escape($expectedDeploymentId)
$isActive100 = $wranglerDeployments -match "\(100%\)\s+$expectedDeploymentId"

Record-Result "Wrangler" "Active Cloudflare Worker deployment version is $expectedDeploymentId" ($hasDeploymentId -and $isActive100) "Deployment found with 100% allocation"

# -----------------------------------------------------------------------------
# SUITE 4: ADVERSARIAL ROUTE ISOLATION & ACCEPT HEADER BEHAVIOR
# -----------------------------------------------------------------------------
Write-Host "`n--- [SUITE 4: Adversarial Route Isolation & Accept Header Behavior] ---" -ForegroundColor Yellow

$edgeBase = "https://sovereign-loq15-vpc-shadow.bospaladin34.workers.dev"

# Adversarial Test 4.1: /api/* with Accept: text/html MUST NOT return SSR HTML
$apiEndpoints = @(
    "/api/v1/test_isolation",
    "/api/v1/unknown_random_challenge_route",
    "/api/v1/auth/operator_vault_gate",
    "/api/v1/pagefile/cauchy_sparse_npage?neuron_id=100"
)

foreach ($ep in $apiEndpoints) {
    $url = "$edgeBase$ep"
    try {
        $resp = Invoke-WebRequest -Uri $url -Headers @{ "Accept" = "text/html,application/xhtml+xml" } -TimeoutSec 15 -UseBasicParsing -ErrorAction SilentlyContinue
        $statusCode = $resp.StatusCode
        $cType = $resp.Headers["Content-Type"]
        $rawBody = $resp.Content
        $hasSsrTag = $rawBody -match 'data-sovereign-ssr'
        $hasDocType = $rawBody -match '<!DOCTYPE html>'
        $isNotHtml = (-not $hasSsrTag) -and (-not $hasDocType)
        Record-Result "RouteIsolation" "API path $ep with Accept: text/html does NOT render SSR HTML" $isNotHtml "Status=$statusCode, Type=$cType, HasSSR=$hasSsrTag"
    } catch {
        $errResp = $_.Exception.Response
        if ($errResp) {
            $stream = $errResp.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($stream)
            $errBody = $reader.ReadToEnd()
            $hasSsrTag = $errBody -match 'data-sovereign-ssr'
            Record-Result "RouteIsolation" "API path $ep returned HTTP $($errResp.StatusCode) without SSR HTML" (-not $hasSsrTag) "StatusCode=$($errResp.StatusCode)"
        } else {
            Record-Result "RouteIsolation" "API path $ep handled request" $false $_.Exception.Message
        }
    }
}

# Adversarial Test 4.2: Normal HTML routes MUST return SSR HTML with v50.2.0 badge and anti-stale headers
$htmlEndpoints = @(
    "/",
    "/index.html",
    "/hud",
    "/hud.html"
)

foreach ($ep in $htmlEndpoints) {
    $url = "$edgeBase$ep"
    try {
        $resp = Invoke-WebRequest -Uri $url -Headers @{ "Accept" = "text/html" } -TimeoutSec 15 -UseBasicParsing
        $cControl = $resp.Headers["Cache-Control"]
        $body = $resp.Content
        $hasBadge = $body -match 'data-sovereign-ssr="v50\.2\.0"'
        $hasCacheHeader = $cControl -match 'public,\s*max-age=0,\s*must-revalidate'
        Record-Result "HtmlSSR" "$ep returns 200 OK, v50.2.0 badge, and anti-stale cache-control" ($resp.StatusCode -eq 200 -and $hasBadge -and $hasCacheHeader) "Status=$($resp.StatusCode) Cache-Control=$cControl Badge=$hasBadge"
    } catch {
        Record-Result "HtmlSSR" "$ep returns 200 OK" $false $_.Exception.Message
    }
}

# Adversarial Test 4.3: Edge Traversal / Malformed Path Handling
$malformedPaths = @(
    "/api/../index.html",
    "//api//v1//test",
    "/api/v1/%2e%2e/index.html"
)
foreach ($mp in $malformedPaths) {
    $url = "$edgeBase$mp"
    try {
        $resp = Invoke-WebRequest -Uri $url -TimeoutSec 15 -UseBasicParsing -ErrorAction SilentlyContinue
        Record-Result "PathSanity" "Malformed path $mp handled gracefully" ($resp.StatusCode -lt 500) "Status=$($resp.StatusCode)"
    } catch {
        $errResp = $_.Exception.Response
        if ($errResp) {
            Record-Result "PathSanity" "Malformed path $mp rejected gracefully with HTTP $($errResp.StatusCode)" ($errResp.StatusCode.value__ -lt 500) "Status=$($errResp.StatusCode)"
        } else {
            Record-Result "PathSanity" "Malformed path $mp encountered network error" $false $_.Exception.Message
        }
    }
}

# -----------------------------------------------------------------------------
# SUITE 5: EDGE CONCURRENT BURST STRESS TEST
# -----------------------------------------------------------------------------
Write-Host "`n--- [SUITE 5: Edge Burst & Concurrency Stress Test] ---" -ForegroundColor Yellow

Add-Type -AssemblyName System.Net.Http
$burstCount = 30
$burstUrl = "$edgeBase/"
Write-Host "  Launching $burstCount concurrent HTTP requests to $burstUrl..." -ForegroundColor DarkCyan

$client = [System.Net.Http.HttpClient]::new()
$client.DefaultRequestHeaders.Add("Accept", "text/html")
$client.Timeout = [System.TimeSpan]::FromSeconds(15)

$swTotal = [System.Diagnostics.Stopwatch]::StartNew()
$tasks = @()
for ($i = 0; $i -lt $burstCount; $i++) {
    $tasks += $client.GetAsync($burstUrl)
}
[System.Threading.Tasks.Task]::WaitAll($tasks)
$swTotal.Stop()

$successCount = 0
$badgeCount = 0
$cacheControlCount = 0
foreach ($t in $tasks) {
    $r = $t.Result
    if ($r.StatusCode -eq 200) { $successCount++ }
    $b = $r.Content.ReadAsStringAsync().Result
    if ($b -match 'data-sovereign-ssr="v50\.2\.0"') { $badgeCount++ }
    if ($r.Headers.CacheControl.ToString() -match 'max-age=0') { $cacheControlCount++ }
}
$client.Dispose()

Record-Result "BurstStress" "All $burstCount burst requests completed with HTTP 200 OK" ($successCount -eq $burstCount) "Success=$successCount/$burstCount"
Record-Result "BurstStress" "All burst responses contain v50.2.0 SSR badge" ($badgeCount -eq $burstCount) "BadgeCount=$badgeCount/$burstCount"
Record-Result "BurstStress" "All burst responses carry anti-stale cache-control" ($cacheControlCount -eq $burstCount) "CacheControlCount=$cacheControlCount/$burstCount"
Record-Result "BurstStress" "Burst total wall-clock time under 3000ms" ($swTotal.ElapsedMilliseconds -lt 3000) "TotalWallMs=$($swTotal.ElapsedMilliseconds)ms"

# -----------------------------------------------------------------------------
# SUITE 6: ORIGIN DAEMON & OPERATOR GATE VERIFICATION
# -----------------------------------------------------------------------------
Write-Host "`n--- [SUITE 6: Origin Daemon (:8097) & Operator Key Invariants] ---" -ForegroundColor Yellow

$originBase = "http://127.0.0.1:8097"

# Check root probe
try {
    $originResp = Invoke-WebRequest -Uri "$originBase/" -UseBasicParsing -TimeoutSec 5
    $oCc = $originResp.Headers["Cache-Control"]
    $oRobots = $originResp.Headers["X-Robots-Tag"]
    Record-Result "Origin" "Origin / returns 200 OK with correct Cache-Control and X-Robots-Tag" ($originResp.StatusCode -eq 200 -and $oCc -match 'max-age=0' -and $oRobots -match 'index, follow') "CC=$oCc, Robots=$oRobots"
} catch {
    Record-Result "Origin" "Origin / reachable" $false $_.Exception.Message
}

# Check dynamic neuron pagefile bank tag format
try {
    $pageResp = Invoke-WebRequest -Uri "$originBase/api/v1/pagefile/cauchy_sparse_npage?neuron_id=100" -UseBasicParsing -TimeoutSec 5
    $pBody = $pageResp.Content
    $hasLegacyBracket = $pBody -match '\[0\.\.21119\]'
    $hasCleanParens = $pBody -match '\(Neurons 0\.\.21119\)'
    Record-Result "OriginNeuron" "Origin dynamic pagefile bank tag uses parentheses without square brackets" ((-not $hasLegacyBracket) -and $hasCleanParens) "LegacyBracket=$hasLegacyBracket, CleanParens=$hasCleanParens"
} catch {
    Record-Result "OriginNeuron" "Origin dynamic pagefile reachable" $false $_.Exception.Message
}

# Operator Auth Gate test:
$keyPath = "C:\Users\Nbell\.act_omega_operator_vault_key"
if (Test-Path $keyPath) {
    $opKey = (Get-Content $keyPath -Raw).Trim()
    
    # 1. URL Query Param ?key= must return authorized: false on gate endpoint
    $qResp = Invoke-RestMethod -Uri "$originBase/api/v1/auth/operator_vault_gate?key=$opKey" -TimeoutSec 5
    # 2. Request header X-Sovereign-Operator-Key must return authorized: true on gate endpoint
    $hResp = Invoke-RestMethod -Uri "$originBase/api/v1/auth/operator_vault_gate" -Headers @{ "X-Sovereign-Operator-Key" = $opKey } -TimeoutSec 5
    
    $gateOk = ($qResp.authorized -eq $false -and $hResp.authorized -eq $true)
    Record-Result "OperatorGate" "Gate endpoint: ?key= is rejected (authorized:false) & header is authorized:true" $gateOk "QueryAuth=$($qResp.authorized) HeaderAuth=$($hResp.authorized)"

    # 3. Privileged /api/v1/admin/* strictly rejects ?key= with HTTP 403 Forbidden
    $adminStatus = (curl.exe -s -o NUL -w "%{http_code}" "$originBase/api/v1/admin/status?key=$opKey")
    Record-Result "OperatorGate" "Privileged /api/v1/admin/status with ?key= returns HTTP 403 Forbidden" ($adminStatus -eq "403") "HTTPCode=$adminStatus"
} else {
    Record-Result "OperatorGate" "Operator key file exists at $keyPath" $false "File not found"
}

# -----------------------------------------------------------------------------
# SUITE 7: SOVEREIGN LIFECYCLE 6/6 LAYER VERIFY
# -----------------------------------------------------------------------------
Write-Host "`n--- [SUITE 7: Sovereign Lifecycle 6/6 Layer Verification] ---" -ForegroundColor Yellow

$lifecycleScript = Join-Path $RepoRoot "00_control\Sovereign-Lifecycle.ps1"
$lifecycleOutput = powershell -ExecutionPolicy Bypass -File $lifecycleScript -Action verify 2>&1 | Out-String
$lifecyclePass = ($LASTEXITCODE -eq 0 -and $lifecycleOutput -match 'AUDIT RESULT: PASSED \(6/6 LAYERS MET ALL MEASURED THRESHOLDS\)')
Record-Result "Lifecycle" "Sovereign-Lifecycle.ps1 -Action verify passes all 6/6 layers" $lifecyclePass "ExitCode=$LASTEXITCODE"

# -----------------------------------------------------------------------------
# SUMMARY & VERDICT
# -----------------------------------------------------------------------------
Write-Host "`n==========================================================================" -ForegroundColor Cyan
Write-Host "  TEST SUMMARY: Total=$TotalTests | Passed=$PassedTests | Failed=$FailedTests" -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan

if ($FailedTests -gt 0) {
    Write-Host "`n[ADVERSARIAL VERDICT: REQUEST_CHANGES ($FailedTests failures)]" -ForegroundColor Red
    foreach ($v in $Violations) {
        Write-Host "  - $v" -ForegroundColor Red
    }
    exit 1
} else {
    Write-Host "`n[ADVERSARIAL VERDICT: APPROVED (All $PassedTests tests passed!)]" -ForegroundColor Green
    exit 0
}
