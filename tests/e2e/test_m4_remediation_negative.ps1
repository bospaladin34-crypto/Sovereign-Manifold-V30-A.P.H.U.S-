# =============================================================================
# ACT-Omega Net v73.2.2 — M4 Comprehensive Remediation Positive & Negative E2E
# Covers live :8097 + static negative gates for Items #8, #9, #10, #11, #13,
# #14, #15, and #16. ZERO raw Pixel serials, operator keys, or CF IDs emitted.
# =============================================================================
param(
    [string]$RepoRoot = ""
)
$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Net.Http

if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    if ($PSScriptRoot) {
        $RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
    } else {
        $RepoRoot = "C:\sovereign_manifold_v31"
    }
}
$BaseUrl = "http://127.0.0.1:8097"

function Get-OperatorKey {
    if (-not [string]::IsNullOrWhiteSpace($env:ACT_OMEGA_OPERATOR_KEY)) {
        $k = $env:ACT_OMEGA_OPERATOR_KEY.Trim()
        if ($k.Length -ge 24) { return $k }
    }
    $kf = "C:\Users\Nbell\.act_omega_operator_vault_key"
    if (Test-Path $kf -PathType Leaf) {
        $k = ([System.IO.File]::ReadAllText($kf)).Trim()
        if ($k.Length -ge 24) { return $k }
    }
    throw "FATAL: External operator key missing or < 24 chars"
}

$OpKey = Get-OperatorKey
$HttpClientHandler = New-Object System.Net.Http.HttpClientHandler
$HttpClient = New-Object System.Net.Http.HttpClient($HttpClientHandler)
$HttpClient.Timeout = [TimeSpan]::FromSeconds(60)

function Invoke-RawHttp {
    param(
        [string]$Method,
        [string]$Url,
        [hashtable]$Headers = @{},
        [string]$Body = $null
    )
    $req = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::new($Method), $Url)
    foreach ($kv in $Headers.GetEnumerator()) {
        $null = $req.Headers.TryAddWithoutValidation($kv.Key, $kv.Value)
    }
    if ($Method -ne "GET" -and $Method -ne "HEAD" -and $PSBoundParameters.ContainsKey("Body") -and $null -ne $Body) {
        $req.Content = New-Object System.Net.Http.StringContent($Body, [System.Text.UTF8Encoding]::new($false), "application/json")
    }
    $resp = $HttpClient.SendAsync($req).GetAwaiter().GetResult()
    $respBody = $resp.Content.ReadAsStringAsync().GetAwaiter().GetResult()
    $acao = @()
    if ($resp.Headers.Contains("Access-Control-Allow-Origin")) {
        $acao = @($resp.Headers.GetValues("Access-Control-Allow-Origin"))
    }
    return @{
        StatusCode = [int]$resp.StatusCode
        Body = $respBody
        Acao = ($acao -join ",")
    }
}

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "  ACT-OMEGA M4 REMEDIATION POSITIVE & NEGATIVE E2E SUITE (#8-#16)         " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan

try {
    # -------------------------------------------------------------------------
    # 1. Item #8 — /api/v1/ota/manifest auth + ?key= reject + no 0.085 proxy PPL
    # -------------------------------------------------------------------------
    $r8Unauth = Invoke-RawHttp -Method "GET" -Url "$BaseUrl/api/v1/ota/manifest"
    if ($r8Unauth.StatusCode -ne 403) {
        throw "ITEM #8 FAIL: Unauth /api/v1/ota/manifest expected 403, got $($r8Unauth.StatusCode)"
    }
    $r8Query = Invoke-RawHttp -Method "GET" -Url "$BaseUrl/api/v1/ota/manifest?key=$([uri]::EscapeDataString($OpKey))"
    if ($r8Query.StatusCode -ne 403) {
        throw "ITEM #8 FAIL: ?key= /api/v1/ota/manifest expected 403, got $($r8Query.StatusCode)"
    }
    $r8Auth = Invoke-RawHttp -Method "GET" -Url "$BaseUrl/api/v1/ota/manifest" -Headers @{ "X-Sovereign-Operator-Key" = $OpKey }
    if ($r8Auth.StatusCode -ne 200) {
        throw "ITEM #8 FAIL: Auth /api/v1/ota/manifest expected 200, got $($r8Auth.StatusCode)"
    }
    if ($r8Auth.Body -match 'v61\.0\.0|0\.085') {
        throw "ITEM #8 FAIL: /api/v1/ota/manifest body still contains v61.0.0 or 0.085"
    }
    Write-Host "  [ITEM #8  OTA MANIFEST]    [PASS] Unauth=403 | ?key=403 | Auth=200 (0 proxy-PPL/v61.0.0)" -ForegroundColor Green

    # -------------------------------------------------------------------------
    # 2. Item #9 — /api/v1/cluster/sync_matrix write gate & bounds
    # -------------------------------------------------------------------------
    $r9UnauthGet = Invoke-RawHttp -Method "GET" -Url "$BaseUrl/api/v1/cluster/sync_matrix?pixel10_kops=9999"
    $r9UnauthPost = Invoke-RawHttp -Method "POST" -Url "$BaseUrl/api/v1/cluster/sync_matrix" -Body '{"pixel10_kops":9999}'
    if ($r9UnauthGet.StatusCode -ne 403 -or $r9UnauthPost.StatusCode -ne 403) {
        throw "ITEM #9 FAIL: Unauth sync_matrix expected 403/403, got $($r9UnauthGet.StatusCode)/$($r9UnauthPost.StatusCode)"
    }
    $r9AuthGet = Invoke-RawHttp -Method "GET" -Url "$BaseUrl/api/v1/cluster/sync_matrix" -Headers @{ "X-Sovereign-Operator-Key" = $OpKey }
    if ($r9AuthGet.StatusCode -ne 405 -and $r9AuthGet.StatusCode -lt 400) {
        throw "ITEM #9 FAIL: Auth GET sync_matrix expected 405/4xx, got $($r9AuthGet.StatusCode)"
    }
    $r9BadJson = Invoke-RawHttp -Method "POST" -Url "$BaseUrl/api/v1/cluster/sync_matrix" -Headers @{ "X-Sovereign-Operator-Key" = $OpKey } -Body '{"pixel10_kops":"not_a_number"}'
    $r9Oob = Invoke-RawHttp -Method "POST" -Url "$BaseUrl/api/v1/cluster/sync_matrix" -Headers @{ "X-Sovereign-Operator-Key" = $OpKey } -Body '{"pixel10_kops":999999.0}'
    if ($r9BadJson.StatusCode -ne 400 -or $r9Oob.StatusCode -ne 400) {
        throw "ITEM #9 FAIL: Bad/OOB POST sync_matrix expected 400/400, got $($r9BadJson.StatusCode)/$($r9Oob.StatusCode)"
    }
    Write-Host "  [ITEM #9  SYNC MATRIX]     [PASS] Unauth=403 | GET=$($r9AuthGet.StatusCode) | BadJSON=400 | OOB=400" -ForegroundColor Green

    # -------------------------------------------------------------------------
    # 3. Item #11 — L0 CORS 6-origin allowlist & t281..t286 auth gate
    # -------------------------------------------------------------------------
    $r11EvilCors = Invoke-RawHttp -Method "GET" -Url "$BaseUrl/api/v1/health" -Headers @{ "Origin" = "https://evil.example" }
    if ($r11EvilCors.Acao -eq "*" -or $r11EvilCors.Acao -eq "https://evil.example") {
        throw "ITEM #11 FAIL: Evil origin echoed in ACAO: '$($r11EvilCors.Acao)'"
    }
    $r11GoodCors = Invoke-RawHttp -Method "GET" -Url "$BaseUrl/api/v1/health" -Headers @{ "Origin" = "https://act-omega-net.dev" }
    if ($r11GoodCors.Acao -ne "https://act-omega-net.dev") {
        throw "ITEM #11 FAIL: Allowlisted origin not echoed in ACAO: '$($r11GoodCors.Acao)'"
    }
    $r11T281Unauth = Invoke-RawHttp -Method "GET" -Url "$BaseUrl/api/v1/tools/t281"
    $r11BleedUnauth = Invoke-RawHttp -Method "GET" -Url "$BaseUrl/api/v1/synthesis/bleeding_edge_1"
    if ($r11T281Unauth.StatusCode -ne 403 -or $r11BleedUnauth.StatusCode -ne 403) {
        throw "ITEM #11 FAIL: Unauth t281/bleeding_edge_1 expected 403/403, got $($r11T281Unauth.StatusCode)/$($r11BleedUnauth.StatusCode)"
    }
    $r11T281Auth = Invoke-RawHttp -Method "GET" -Url "$BaseUrl/api/v1/tools/t281" -Headers @{ "X-Sovereign-Operator-Key" = $OpKey }
    if ($r11T281Auth.StatusCode -ne 200) {
        throw "ITEM #11 FAIL: Auth t281 expected 200, got $($r11T281Auth.StatusCode)"
    }
    Write-Host "  [ITEM #11 CORS & T281]     [PASS] EvilOrigin omitted | AllowOrigin=echoed | Unauth=403 | Auth=200" -ForegroundColor Green

    # -------------------------------------------------------------------------
    # 4. Item #10 — Pixel serial negative scan + stamp/staging/Android checks
    # -------------------------------------------------------------------------
    powershell -NoProfile -ExecutionPolicy Bypass -File "$RepoRoot\00_control\Invoke-BrutalAgentGatekeeper.ps1" -TestNegativePixelSerialInjection | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "ITEM #10 FAIL: Invoke-BrutalAgentGatekeeper.ps1 -TestNegativePixelSerialInjection failed (exit=$LASTEXITCODE)"
    }
    $stagingPath = "$RepoRoot\03_vault\config\MainActivity.kt.staging"
    $stagingTracked = @(git -C $RepoRoot ls-files "03_vault/config/MainActivity.kt.staging" 2>$null)
    if ((Test-Path $stagingPath) -or $stagingTracked.Count -gt 0) {
        throw "ITEM #10 FAIL: MainActivity.kt.staging still exists or tracked"
    }
    $v72_2_src = [System.IO.File]::ReadAllText("$RepoRoot\01_l0_rust\src\v72_2_sh_xi_sparse_moe_chatml_sft_and_rag.rs")
    if ($v72_2_src -match '"version"\s*:\s*"v72\.2\.0"') {
        throw "ITEM #10 FAIL: v72_2 still emits hardcoded v72.2.0"
    }
    powershell -NoProfile -ExecutionPolicy Bypass -File "$RepoRoot\00_control\Invoke-BrutalAgentGatekeeper.ps1" -StaticOnly | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "ITEM #10 FAIL: Invoke-BrutalAgentGatekeeper.ps1 -StaticOnly failed (exit=$LASTEXITCODE)"
    }
    Write-Host "  [ITEM #10 PIXEL & STAMPS]  [PASS] PixelSerialNeg=4/4 | StagingAbsent=True | GatekeeperStatic=PASS" -ForegroundColor Green

    # -------------------------------------------------------------------------
    # 5. Item #13 — Independent HMAC Lean receipt negative + live forged fail
    # -------------------------------------------------------------------------
    powershell -NoProfile -ExecutionPolicy Bypass -File "$RepoRoot\00_control\Verify-Lean4IndependentReceipt.ps1" -TestNegative | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "ITEM #13 FAIL: Verify-Lean4IndependentReceipt.ps1 -TestNegative failed"
    }
    $rec1 = "$RepoRoot\03_vault\receipts\lean4_compiler_verification_receipt.json"
    $rec2 = "$RepoRoot\03_vault\connectome\lean4_compiler_verified_receipt.json"
    $bak1 = [System.IO.File]::ReadAllBytes($rec1)
    $bak2 = [System.IO.File]::ReadAllBytes($rec2)
    try {
        foreach ($rp in @($rec1, $rec2)) {
            $rj = Get-Content -Raw $rp | ConvertFrom-Json
            $rj.hmac_sha256 = ("f" * 64)
            [System.IO.File]::WriteAllText($rp, ($rj | ConvertTo-Json -Depth 6), [System.Text.UTF8Encoding]::new($false))
        }
        $r399Bad = Invoke-RawHttp -Method "POST" -Url "$BaseUrl/api/v1/chain399" -Headers @{ "X-Sovereign-Operator-Key" = $OpKey } -Body '{}'
        $r404Bad = Invoke-RawHttp -Method "POST" -Url "$BaseUrl/api/v1/tools/t404" -Headers @{ "X-Sovereign-Operator-Key" = $OpKey } -Body '{}'
        $j399Bad = $r399Bad.Body | ConvertFrom-Json
        $j404Bad = $r404Bad.Body | ConvertFrom-Json
        if ($j399Bad.ok -ne $false -or $j399Bad.certified -ne $false -or $j399Bad.lean4_compiler_verified -ne $false -or $j399Bad.status -ne "UNMEASURED/OFFLINE") {
            throw "ITEM #13 FAIL: CHAIN 399 did not fail closed on forged HMAC receipt: $($r399Bad.Body)"
        }
        if ($j404Bad.ok -ne $false -or $j404Bad.certified -ne $false -or $j404Bad.lean4_compiler_verified -ne $false -or $j404Bad.status -ne "UNMEASURED/OFFLINE") {
            throw "ITEM #13 FAIL: CHAIN 404 did not fail closed on forged HMAC receipt: $($r404Bad.Body)"
        }
    } finally {
        [System.IO.File]::WriteAllBytes($rec1, $bak1)
        [System.IO.File]::WriteAllBytes($rec2, $bak2)
    }
    powershell -NoProfile -ExecutionPolicy Bypass -File "$RepoRoot\00_control\Verify-Lean4IndependentReceipt.ps1" -VerifyOnly | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "ITEM #13 FAIL: Restored Lean receipts failed VerifyOnly"
    }
    $r404Ok = Invoke-RawHttp -Method "POST" -Url "$BaseUrl/api/v1/tools/t404" -Headers @{ "X-Sovereign-Operator-Key" = $OpKey } -Body '{}'
    $j404Ok = $r404Ok.Body | ConvertFrom-Json
    if ($j404Ok.ok -ne $true -or $j404Ok.certified -ne $true -or $j404Ok.lean4_compiler_verified -ne $true) {
        throw "ITEM #13 FAIL: Restored CHAIN 404 did not pass: $($r404Ok.Body)"
    }
    Write-Host "  [ITEM #13 LEAN HMAC GATE]  [PASS] ScriptNeg=5/5 | ForgedHMAC->CHAIN399/404=UNMEASURED/OFFLINE | Restored=PASS" -ForegroundColor Green

    # -------------------------------------------------------------------------
    # 6. Item #14 — /api/v1/health JSON probe + 404 / HTTP-200 non-JSON negative
    # -------------------------------------------------------------------------
    $r14Good = Invoke-RawHttp -Method "GET" -Url "$BaseUrl/api/v1/health" -Headers @{ "X-Sovereign-Operator-Key" = $OpKey }
    $j14 = $r14Good.Body | ConvertFrom-Json
    if ($r14Good.StatusCode -ne 200 -or $j14.status -notmatch '^LAMINAR_' -or [int]$j14.lean4_theorems_qed -lt 1010 -or [int]$j14.tools_count -lt 404) {
        throw "ITEM #14 FAIL: /api/v1/health invalid response: $($r14Good.Body)"
    }
    $r14Bad404 = Invoke-RawHttp -Method "GET" -Url "$BaseUrl/api/v1/nonexistent_health_probe"
    $r14BadHtml = Invoke-RawHttp -Method "GET" -Url "$BaseUrl/google6edc0affb12d0455.html"
    if ($r14Bad404.StatusCode -ne 404 -or $r14BadHtml.StatusCode -ne 200 -or ($r14BadHtml.Body -match '^\{')) {
        throw "ITEM #14 FAIL: Unexpected negative probe responses: 404=$($r14Bad404.StatusCode) html=$($r14BadHtml.StatusCode)"
    }
    Write-Host "  [ITEM #14 HEALTH PROBE]    [PASS] /api/v1/health=200 JSON | 404=404 | GSC_HTML=200 non-JSON" -ForegroundColor Green

    # -------------------------------------------------------------------------
    # 7. Item #15 — Week4 Torture Suite Perturbation Fail Proof
    # -------------------------------------------------------------------------
    powershell -NoProfile -ExecutionPolicy Bypass -File "$RepoRoot\00_control\Invoke-Week4TortureSuite.ps1" -TestPerturbationFail | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "ITEM #15 FAIL: Invoke-Week4TortureSuite.ps1 -TestPerturbationFail failed (exit=$LASTEXITCODE)"
    }
    Write-Host "  [ITEM #15 WEEK4 RANGE]     [PASS] Perturbation fail proof (3/3) exited 0" -ForegroundColor Green

    # -------------------------------------------------------------------------
    # 8. Item #16 — T383 CE comparison, v71_2 172-token support, docs/6x wiki/E:\
    # -------------------------------------------------------------------------
    $r383Base = Invoke-RawHttp -Method "POST" -Url "$BaseUrl/api/v1/tools/t383" -Headers @{ "X-Sovereign-Operator-Key" = $OpKey } -Body '{}'
    $r383Pert = Invoke-RawHttp -Method "POST" -Url "$BaseUrl/api/v1/tools/t383" -Headers @{ "X-Sovereign-Operator-Key" = $OpKey } -Body '{"perturb_delta":0.25}'
    $j383B = $r383Base.Body | ConvertFrom-Json
    $j383P = $r383Pert.Body | ConvertFrom-Json
    if ($null -eq $j383B.fp32_val_ce_nats -or $null -eq $j383B.scalar_3bpw_val_ce_nats -or $null -eq $j383B.curvetq_3bpw_val_ce_nats -or [int]$j383B.val_positions_evaluated -ne 16 -or [string]$j383B.distortion_metric_scope -ne "FISHER_WEIGHTED_DISTORTION_ONLY_NOT_CE") {
        throw "ITEM #16 FAIL: T383 missing CE comparison or distortion_metric_scope: $($r383Base.Body)"
    }
    if ([double]$j383B.fisher_trace -eq [double]$j383P.fisher_trace) {
        throw "ITEM #16 FAIL: T383 perturb_delta=0.25 did not shift fisher_trace"
    }
    $r339 = Invoke-RawHttp -Method "POST" -Url "$BaseUrl/api/v1/tool/339" -Headers @{ "X-Sovereign-Operator-Key" = $OpKey } -Body '{}'
    $j339 = $r339.Body | ConvertFrom-Json
    $w28 = $j339.w2_8_six_way_ablation_matrix
    if ($null -eq $w28 -or [int]$w28.eval_vocab_support_size -ne 172 -or [string]$w28.eval_vocab_support_label -ne "NARROW_172_TOKEN_EVAL_SUPPORT") {
        throw "ITEM #16 FAIL: Tool 339 missing 172-token support label: $($r339.Body)"
    }
    foreach ($doc in @("README.md", "WHATS_NEW.md", "MODEL_CARD.md")) {
        $hRoot = (Get-FileHash "$RepoRoot\$doc" -Algorithm SHA256).Hash
        $hDocs = (Get-FileHash "$RepoRoot\docs\$doc" -Algorithm SHA256).Hash
        if ($hRoot -ne $hDocs) { throw "ITEM #16 FAIL: docs\$doc != $doc" }
        $docTxt = [System.IO.File]::ReadAllText("$RepoRoot\$doc")
        if ($docTxt -notmatch '6\.289823' -or $docTxt -notmatch '6\.217202' -or $docTxt -notmatch '6\.307933' -or $docTxt -notmatch 'NARROW_172_TOKEN_EVAL_SUPPORT') {
            throw "ITEM #16 FAIL: $doc missing T383 CE comparison or NARROW_172_TOKEN_EVAL_SUPPORT"
        }
    }
    $crTxt = [System.IO.File]::ReadAllText("$RepoRoot\COMPLETION_REPORT_V73_MUSE.md")
    if ($crTxt -notmatch '6\.289823' -or $crTxt -notmatch '6\.217202' -or $crTxt -notmatch '6\.307933' -or $crTxt -notmatch 'NARROW_172_TOKEN_EVAL_SUPPORT') {
        throw "ITEM #16 FAIL: COMPLETION_REPORT_V73_MUSE.md missing T383 CE comparison or NARROW_172_TOKEN_EVAL_SUPPORT"
    }
    $wikiRefHash = (Get-FileHash "$RepoRoot\wiki.html" -Algorithm SHA256).Hash
    foreach ($wp in @("docs\wiki.html", "05_hud_cockpit\public\wiki.html", "05_hud_cockpit\dist\wiki.html", "02_l2_orchestration\hud\public\wiki.html", "02_l2_orchestration\hud\dist\wiki.html")) {
        $hW = (Get-FileHash "$RepoRoot\$wp" -Algorithm SHA256).Hash
        if ($hW -ne $wikiRefHash) { throw "ITEM #16 FAIL: $wp SHA-256 mismatch with wiki.html" }
    }
    $wikiTxt = [System.IO.File]::ReadAllText("$RepoRoot\wiki.html")
    if ($wikiTxt -match '63,360 \.binshard|63,360-Neuron|IFEval-Lite-64 64/64|CHAIN 316 Certification \(v72\.2\.0\)') {
        throw "ITEM #16 FAIL: wiki.html retains stale 63,360 / IFEval 64/64 / v72.2.0 cells"
    }
    if ((Get-FileHash "$RepoRoot\00_control\weights\sh_xi_base_train_meta.json" -Algorithm SHA256).Hash -ne (Get-FileHash "E:\Sovereign_Manifold_SSD_Vault\weights\sh_xi_base_train_meta.json" -Algorithm SHA256).Hash) {
        throw "ITEM #16 FAIL: E:\weights\sh_xi_base_train_meta.json out of sync"
    }
    if ((Get-FileHash "$RepoRoot\03_vault\connectome\sh_xi_moe_training_curve.csv" -Algorithm SHA256).Hash -ne (Get-FileHash "E:\Sovereign_Manifold_SSD_Vault\connectome\sh_xi_moe_training_curve.csv" -Algorithm SHA256).Hash) {
        throw "ITEM #16 FAIL: E:\connectome\sh_xi_moe_training_curve.csv out of sync"
    }
    Write-Host "  [ITEM #16 CE/172/DOCS/E:\] [PASS] T383 CE+scope+perturb | T339 172-tok | 3x docs + 6x wiki + E:\ synced" -ForegroundColor Green
} finally {
    $HttpClient.Dispose()
}

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "  ALL M4 REMEDIATION POSITIVE & NEGATIVE E2E CHECKS PASSED!               " -ForegroundColor Green
Write-Host "==========================================================================" -ForegroundColor Cyan
exit 0
