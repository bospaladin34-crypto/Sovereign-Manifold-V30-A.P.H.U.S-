# =============================================================================
# ACT-Omega Net — Security Negative & Positive Probe Suite (R3, R4, R8)
# Covers:
#   Section 1 (R3): Bare read-only GET, POST /api/v1/health 405, 29-param write
#                   query-param 403 + zero mutation, POST /api/v1/telemetry/ingest
#                   auth/edge/bounds/?key=/?%6bey=/restore
#   Section 2 (R4): All 11 handler groups + tool-ID aliases + POST /api/v1/tool/execute
#                   GET/POST/?key=/?%6bey= (+ header smuggling) 403 on origin & edge
#                   + cron-paused .spage/ledger SHA-256 invariance
#   Section 3 (R8): Timing-Allow-Origin 6-origin allowlist on write_http_str
#                   & write_http_vec across origin & edge
#
# Windows PowerShell 5.1 compatible. Zero embedded secrets; zero Python.
# =============================================================================
param(
    [string]$RepoRoot = "",
    [string]$HostUri = "http://127.0.0.1:8097",
    [string]$EdgeWorkerUri = "https://act-omega-net.dev",
    [string]$ReceiptOutPath = "",
    [string]$OperatorKeyPath = "C:\Users\Nbell\.act_omega_operator_vault_key",
    [string]$TelemetryKeyPath = "C:\Users\Nbell\.act_omega_telemetry_ingest_key",
    [string]$VecProbePath = "/sovereign_harmonic_iv_v5000.e8z",
    [int]$TimeoutSec = 15,
    [switch]$SkipEdge,
    [switch]$SkipCronPause
)

$ErrorActionPreference = "Stop"

# Force TLS 1.2 for Cloudflare Edge HTTPS probes on Windows PowerShell 5.1
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
Add-Type -AssemblyName System.Net.Http

# Resolve RepoRoot dynamically
if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    if ($PSScriptRoot) {
        $parentDir = Split-Path -Parent $PSScriptRoot
        if ($parentDir -and (Test-Path $parentDir)) {
            $RepoRoot = (Resolve-Path $parentDir).Path
        } else {
            $RepoRoot = "C:\sovereign_manifold_v31"
        }
    } else {
        $RepoRoot = "C:\sovereign_manifold_v31"
    }
} elseif (Test-Path $RepoRoot) {
    $RepoRoot = (Resolve-Path $RepoRoot).Path
}

$HostUri = $HostUri.TrimEnd("/")
$EdgeWorkerUri = $EdgeWorkerUri.TrimEnd("/")
if ([string]::IsNullOrWhiteSpace($VecProbePath)) {
    $VecProbePath = "/sovereign_harmonic_iv_v5000.e8z"
} elseif (-not $VecProbePath.StartsWith("/")) {
    $VecProbePath = "/" + $VecProbePath
}

if ([string]::IsNullOrWhiteSpace($ReceiptOutPath)) {
    $ReceiptOutPath = Join-Path $RepoRoot "03_vault\receipts\v73_2_4_security_negative_tests_receipt.json"
}

# Read live version dynamically from CITATION.cff
$liveVersion = "UNMEASURED/OFFLINE"
$citationPath = Join-Path $RepoRoot "CITATION.cff"
if (Test-Path $citationPath -PathType Leaf) {
    try {
        $cffText = [System.IO.File]::ReadAllText($citationPath)
        if ($cffText -match '(?m)^version:\s*"?([^"\r\n]+)"?\s*$') {
            $verToken = $Matches[1].Trim()
            if (-not [string]::IsNullOrWhiteSpace($verToken)) {
                $liveVersion = if ($verToken.StartsWith("v")) { $verToken } else { "v$verToken" }
            }
        }
    } catch {
        $liveVersion = "UNMEASURED/OFFLINE"
    }
}

$runStartedUtc = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$checks = New-Object System.Collections.Generic.List[object]
$sectionCounts = [ordered]@{
    keys                 = [ordered]@{ passed = 0; failed = 0 }
    r3_ingest            = [ordered]@{ passed = 0; failed = 0 }
    r4_gates             = [ordered]@{ passed = 0; failed = 0 }
    r8_tao               = [ordered]@{ passed = 0; failed = 0 }
    item2_l0_t275_280    = [ordered]@{ passed = 0; failed = 0 }
    item3_chain135_edge  = [ordered]@{ passed = 0; failed = 0 }
    item4_webgpu_poc     = [ordered]@{ passed = 0; failed = 0 }
    item5_query_key_9gates = [ordered]@{ passed = 0; failed = 0 }
    runtime              = [ordered]@{ passed = 0; failed = 0 }
}

$opKey = ""
$telKey = ""

function Protect-RedactedText {
    param(
        [string]$InputText,
        [string]$OpSecret = "",
        [string]$TelSecret = ""
    )
    if ($null -eq $InputText) { return "" }
    $out = $InputText
    if (-not [string]::IsNullOrWhiteSpace($OpSecret) -and $OpSecret.Length -ge 8) {
        $escapedOp = [regex]::Escape($OpSecret)
        $out = [regex]::Replace($out, $escapedOp, "<REDACTED>")
        $escapedUrlOp = [regex]::Escape([uri]::EscapeDataString($OpSecret))
        $out = [regex]::Replace($out, $escapedUrlOp, "<REDACTED>")
    }
    if (-not [string]::IsNullOrWhiteSpace($TelSecret) -and $TelSecret.Length -ge 8) {
        $escapedTel = [regex]::Escape($TelSecret)
        $out = [regex]::Replace($out, $escapedTel, "<REDACTED>")
        $escapedUrlTel = [regex]::Escape([uri]::EscapeDataString($TelSecret))
        $out = [regex]::Replace($out, $escapedUrlTel, "<REDACTED>")
    }
    $out = [regex]::Replace($out, '(?i)([?&](?:k|%6b)(?:e|%65)(?:y|%79)=)[^&\s"'']+', '${1}<REDACTED>')
    return $out
}

function Add-CheckResult {
    param(
        [Parameter(Mandatory = $true)][string]$Section,
        [Parameter(Mandatory = $true)][string]$Id,
        [Parameter(Mandatory = $true)][bool]$Passed,
        [Parameter(Mandatory = $true)][string]$Detail,
        [string]$Target = "",
        [string]$Method = "",
        [int]$ExpectedStatus = -1,
        [int]$ActualStatus = -1
    )
    $safeDetail = Protect-RedactedText -InputText $Detail -OpSecret $opKey -TelSecret $telKey
    $safeTarget = Protect-RedactedText -InputText $Target -OpSecret $opKey -TelSecret $telKey

    if ($sectionCounts.Contains($Section)) {
        if ($Passed) {
            $sectionCounts[$Section]["passed"] = [int]$sectionCounts[$Section]["passed"] + 1
        } else {
            $sectionCounts[$Section]["failed"] = [int]$sectionCounts[$Section]["failed"] + 1
        }
    }

    $entry = [ordered]@{
        section = $Section
        id      = $Id
        passed  = $Passed
        detail  = $safeDetail
    }
    if (-not [string]::IsNullOrWhiteSpace($Method)) { $entry["method"] = $Method }
    if (-not [string]::IsNullOrWhiteSpace($safeTarget)) { $entry["target"] = $safeTarget }
    if ($ExpectedStatus -ge 0) { $entry["expected_status"] = $ExpectedStatus }
    if ($ActualStatus -ge 0) { $entry["actual_status"] = $ActualStatus }
    $checks.Add([pscustomobject]$entry)

    if (-not $Passed) {
        Write-Host "  [FAIL] [$Section] $Id :: $safeDetail" -ForegroundColor Red
    }
}

function Get-ExternalSecretKey {
    param(
        [Parameter(Mandatory = $true)][string]$EnvVarName,
        [Parameter(Mandatory = $true)][string]$FilePath
    )
    $envVal = [Environment]::GetEnvironmentVariable($EnvVarName)
    if (-not [string]::IsNullOrWhiteSpace($envVal)) {
        $trimmed = $envVal.Trim()
        if ($trimmed.Length -ge 24) {
            return [pscustomobject]@{
                Found  = $true
                Value  = $trimmed
                Source = "ENV:$EnvVarName"
                Length = $trimmed.Length
            }
        }
    }
    if (-not [string]::IsNullOrWhiteSpace($FilePath) -and (Test-Path $FilePath -PathType Leaf)) {
        $fileVal = ([System.IO.File]::ReadAllText($FilePath)).Trim()
        if ($fileVal.Length -ge 24) {
            return [pscustomobject]@{
                Found  = $true
                Value  = $fileVal
                Source = "FILE:$FilePath"
                Length = $fileVal.Length
            }
        }
    }
    return [pscustomobject]@{
        Found  = $false
        Value  = ""
        Source = "MISSING"
        Length = 0
    }
}

function Invoke-HttpProbe {
    param(
        [Parameter(Mandatory = $true)][System.Net.Http.HttpClient]$Client,
        [Parameter(Mandatory = $true)][string]$Method,
        [Parameter(Mandatory = $true)][string]$Url,
        [hashtable]$Headers = @{},
        [string]$Body = $null
    )
    $req = $null
    $resp = $null
    try {
        $httpMethod = New-Object System.Net.Http.HttpMethod($Method)
        $req = New-Object System.Net.Http.HttpRequestMessage($httpMethod, $Url)
        $req.Headers.ConnectionClose = $true
        foreach ($kv in $Headers.GetEnumerator()) {
            $null = $req.Headers.TryAddWithoutValidation([string]$kv.Key, [string]$kv.Value)
        }
        if ($Method -ne "GET" -and $Method -ne "HEAD" -and $null -ne $Body) {
            $utf8 = New-Object System.Text.UTF8Encoding($false)
            $req.Content = New-Object System.Net.Http.StringContent($Body, $utf8, "application/json")
        }
        $resp = $Client.SendAsync($req).GetAwaiter().GetResult()
        $respBytes = $null
        $respBody = ""
        if ($null -ne $resp.Content) {
            $respBytes = $resp.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult()
            if ($null -ne $respBytes -and $respBytes.Length -gt 0) {
                $respBody = [System.Text.Encoding]::UTF8.GetString($respBytes)
            }
        }
        $hdrs = New-Object 'System.Collections.Generic.Dictionary[string,string]' ([System.StringComparer]::OrdinalIgnoreCase)
        foreach ($h in $resp.Headers) {
            $hdrs[$h.Key] = ($h.Value -join ", ")
        }
        if ($null -ne $resp.Content -and $null -ne $resp.Content.Headers) {
            foreach ($ch in $resp.Content.Headers) {
                $hdrs[$ch.Key] = ($ch.Value -join ", ")
            }
        }
        return [pscustomobject]@{
            StatusCode     = [int]$resp.StatusCode
            Body           = $respBody
            ByteLength     = if ($null -ne $respBytes) { $respBytes.Length } else { 0 }
            Headers        = $hdrs
            TransportError = $null
        }
    } catch {
        return [pscustomobject]@{
            StatusCode     = 0
            Body           = ""
            ByteLength     = 0
            Headers        = (New-Object 'System.Collections.Generic.Dictionary[string,string]' ([System.StringComparer]::OrdinalIgnoreCase))
            TransportError = $_.Exception.Message
        }
    } finally {
        if ($null -ne $resp) { $resp.Dispose() }
        if ($null -ne $req) { $req.Dispose() }
    }
}

function ConvertFrom-JsonSafe {
    param([string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return $null }
    try {
        return ($Text | ConvertFrom-Json)
    } catch {
        return $null
    }
}

function Test-HasNonNullProperty {
    param(
        [object]$Obj,
        [string]$PropName
    )
    if ($null -eq $Obj) { return $false }
    $prop = $Obj.PSObject.Properties[$PropName]
    if ($null -eq $prop) { return $false }
    return ($null -ne $prop.Value)
}

function ConvertTo-Int64Safe {
    param([object]$Value)
    if ($null -eq $Value) { return $null }
    $s = if ($Value -is [System.IFormattable]) {
        $Value.ToString($null, [System.Globalization.CultureInfo]::InvariantCulture)
    } else {
        [string]$Value
    }
    if ([string]::IsNullOrWhiteSpace($s)) { return $null }
    [int64]$parsed = 0
    if ([int64]::TryParse($s.Trim(), [System.Globalization.NumberStyles]::Integer, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$parsed)) {
        return $parsed
    }
    return $null
}

function ConvertTo-DoubleSafe {
    param([object]$Value)
    if ($null -eq $Value) { return $null }
    $s = if ($Value -is [System.IFormattable]) {
        $Value.ToString($null, [System.Globalization.CultureInfo]::InvariantCulture)
    } else {
        [string]$Value
    }
    if ([string]::IsNullOrWhiteSpace($s)) { return $null }
    [double]$parsed = 0.0
    if ([double]::TryParse($s.Trim(), [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$parsed)) {
        if (-not [double]::IsNaN($parsed) -and -not [double]::IsInfinity($parsed)) {
            return $parsed
        }
    }
    return $null
}

function Get-FileSnapshot {
    param([string]$FullPath)
    if (-not (Test-Path $FullPath -PathType Leaf)) {
        return [pscustomobject]@{
            Exists = $false
            Path   = $FullPath
            Length = -1
            Sha256 = ""
        }
    }
    $fi = Get-Item -LiteralPath $FullPath
    $hash = (Get-FileHash -LiteralPath $FullPath -Algorithm SHA256).Hash
    return [pscustomobject]@{
        Exists = $true
        Path   = $FullPath
        Length = [int64]$fi.Length
        Sha256 = $hash
    }
}

function Assert-HealthPayload {
    param(
        [string]$Section,
        [string]$Id,
        [string]$TargetUrl,
        [pscustomobject]$Resp
    )
    if ($null -ne $Resp.TransportError) {
        Add-CheckResult -Section $Section -Id $Id -Passed $false -Method "GET" -Target $TargetUrl -ExpectedStatus 200 -ActualStatus $Resp.StatusCode -Detail "Transport error: $($Resp.TransportError)"
        return $null
    }
    if ($Resp.StatusCode -ne 200) {
        Add-CheckResult -Section $Section -Id $Id -Passed $false -Method "GET" -Target $TargetUrl -ExpectedStatus 200 -ActualStatus $Resp.StatusCode -Detail "Expected HTTP 200, got $($Resp.StatusCode)"
        return $null
    }
    $j = ConvertFrom-JsonSafe -Text $Resp.Body
    if ($null -eq $j) {
        Add-CheckResult -Section $Section -Id $Id -Passed $false -Method "GET" -Target $TargetUrl -ExpectedStatus 200 -ActualStatus $Resp.StatusCode -Detail "Invalid JSON body"
        return $null
    }
    $statusOk = (Test-HasNonNullProperty $j "status") -and ([string]$j.status -match '^LAMINAR_')
    $verOk = (Test-HasNonNullProperty $j "version") -and ([string]$j.version -match '^ACT-Omega Net v\d+\.\d+\.\d+')
    $toolsVal = if (Test-HasNonNullProperty $j "tools_count") { ConvertTo-Int64Safe $j.tools_count } else { $null }
    $leanVal = if (Test-HasNonNullProperty $j "lean4_theorems_qed") { ConvertTo-Int64Safe $j.lean4_theorems_qed } else { $null }
    $genVal = if (Test-HasNonNullProperty $j "generation") { ConvertTo-Int64Safe $j.generation } else { $null }
    $toolsOk = ($null -ne $toolsVal) -and ($toolsVal -ge 404)
    $leanOk = ($null -ne $leanVal) -and ($leanVal -ge 1010)
    $genOk = ($null -ne $genVal) -and ($genVal -ge 1)
    $allOk = $statusOk -and $verOk -and $toolsOk -and $leanOk -and $genOk
    $detail = "status=$($j.status) version=$($j.version) tools=$($j.tools_count) qed=$($j.lean4_theorems_qed) gen=$($j.generation)"
    Add-CheckResult -Section $Section -Id $Id -Passed $allOk -Method "GET" -Target $TargetUrl -ExpectedStatus 200 -ActualStatus $Resp.StatusCode -Detail $detail
    return $j
}

function Assert-TelemetryPayload {
    param(
        [string]$Section,
        [string]$Id,
        [string]$TargetUrl,
        [pscustomobject]$Resp
    )
    if ($null -ne $Resp.TransportError) {
        Add-CheckResult -Section $Section -Id $Id -Passed $false -Method "GET" -Target $TargetUrl -ExpectedStatus 200 -ActualStatus $Resp.StatusCode -Detail "Transport error: $($Resp.TransportError)"
        return $null
    }
    if ($Resp.StatusCode -ne 200) {
        Add-CheckResult -Section $Section -Id $Id -Passed $false -Method "GET" -Target $TargetUrl -ExpectedStatus 200 -ActualStatus $Resp.StatusCode -Detail "Expected HTTP 200, got $($Resp.StatusCode)"
        return $null
    }
    $j = ConvertFrom-JsonSafe -Text $Resp.Body
    if ($null -eq $j) {
        Add-CheckResult -Section $Section -Id $Id -Passed $false -Method "GET" -Target $TargetUrl -ExpectedStatus 200 -ActualStatus $Resp.StatusCode -Detail "Invalid JSON body"
        return $null
    }
    $reqKeys = @("cluster_total_kops", "pixel10_g5_kops", "pixel8_l2_kops", "loq15_rtx3050_kops", "mag_x", "p10_bearer", "p8_bearer")
    $missing = New-Object System.Collections.Generic.List[string]
    foreach ($rk in $reqKeys) {
        if (-not (Test-HasNonNullProperty $j $rk)) {
            $missing.Add($rk)
        }
    }
    $allOk = ($missing.Count -eq 0)
    $detail = if ($allOk) { "All 7 telemetry schema fields present" } else { "Missing telemetry fields: $($missing -join ', ')" }
    Add-CheckResult -Section $Section -Id $Id -Passed $allOk -Method "GET" -Target $TargetUrl -ExpectedStatus 200 -ActualStatus $Resp.StatusCode -Detail $detail
    return $j
}

function Assert-HttpStatus {
    param(
        [string]$Section,
        [string]$Id,
        [string]$Method,
        [string]$TargetUrl,
        [int]$ExpectedStatus,
        [pscustomobject]$Resp,
        [string]$ExtraDetail = ""
    )
    if ($null -ne $Resp.TransportError) {
        Add-CheckResult -Section $Section -Id $Id -Passed $false -Method $Method -Target $TargetUrl -ExpectedStatus $ExpectedStatus -ActualStatus $Resp.StatusCode -Detail "Transport error: $($Resp.TransportError)"
        return $false
    }
    $ok = ($Resp.StatusCode -eq $ExpectedStatus)
    $msg = "HTTP $($Resp.StatusCode) (expected $ExpectedStatus)"
    if (-not [string]::IsNullOrWhiteSpace($ExtraDetail)) {
        $msg = "$msg | $ExtraDetail"
    }
    Add-CheckResult -Section $Section -Id $Id -Passed $ok -Method $Method -Target $TargetUrl -ExpectedStatus $ExpectedStatus -ActualStatus $Resp.StatusCode -Detail $msg
    return $ok
}

Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "  ACT-Omega Net $liveVersion — Security Negative & Positive Probe Suite   " -ForegroundColor Cyan
Write-Host "==========================================================================" -ForegroundColor Cyan
Write-Host "  HostUri       : $HostUri"
Write-Host "  EdgeWorkerUri : $(if ($SkipEdge) { '<SKIPPED>' } else { $EdgeWorkerUri })"
Write-Host "  ReceiptOut    : $ReceiptOutPath"

$handler = New-Object System.Net.Http.HttpClientHandler
$handler.AllowAutoRedirect = $false
$client = New-Object System.Net.Http.HttpClient($handler)
$client.Timeout = [TimeSpan]::FromSeconds($TimeoutSec)

$cronPaused = $false
$opKeyInfo = $null
$telKeyInfo = $null
$watchedFilesSummary = New-Object System.Collections.Generic.List[object]

try {
    # -------------------------------------------------------------------------
    # External Key Loading (Fail-Closed, Zero Secret Leaks)
    # -------------------------------------------------------------------------
    $opKeyInfo = Get-ExternalSecretKey -EnvVarName "ACT_OMEGA_OPERATOR_KEY" -FilePath $OperatorKeyPath
    if ($opKeyInfo.Found) {
        $opKey = $opKeyInfo.Value
        Add-CheckResult -Section "keys" -Id "Key_Operator_Loaded" -Passed $true -Detail "Loaded operator key from $($opKeyInfo.Source) (len=$($opKeyInfo.Length))"
    } else {
        Add-CheckResult -Section "keys" -Id "Key_Operator_Loaded" -Passed $false -Detail "FAIL-CLOSED: Operator key missing or < 24 chars (env ACT_OMEGA_OPERATOR_KEY / $OperatorKeyPath)"
    }

    $telKeyInfo = Get-ExternalSecretKey -EnvVarName "ACT_OMEGA_TELEMETRY_KEY" -FilePath $TelemetryKeyPath
    if ($telKeyInfo.Found) {
        $telKey = $telKeyInfo.Value
        Add-CheckResult -Section "keys" -Id "Key_Telemetry_Loaded" -Passed $true -Detail "Loaded telemetry key from $($telKeyInfo.Source) (len=$($telKeyInfo.Length))"
    } else {
        Add-CheckResult -Section "keys" -Id "Key_Telemetry_Loaded" -Passed $false -Detail "FAIL-CLOSED: Telemetry key missing or < 24 chars (env ACT_OMEGA_TELEMETRY_KEY / $TelemetryKeyPath)"
    }

    # =========================================================================
    # SECTION 1 — R3 Telemetry Ingest & Pure Read-Only GET
    # =========================================================================
    Write-Host "`n[Section 1] R3 Telemetry Ingest & Pure Read-Only GET..." -ForegroundColor Yellow

    # 1a. Bare GET /api/v1/health (twice consecutively on host, once on edge)
    $h1Url = "$HostUri/api/v1/health"
    $h1Resp = Invoke-HttpProbe -Client $client -Method "GET" -Url $h1Url
    $h1Json = Assert-HealthPayload -Section "r3_ingest" -Id "R3_Host_Health_1" -TargetUrl $h1Url -Resp $h1Resp

    $h2Resp = Invoke-HttpProbe -Client $client -Method "GET" -Url $h1Url
    $h2Json = Assert-HealthPayload -Section "r3_ingest" -Id "R3_Host_Health_2" -TargetUrl $h1Url -Resp $h2Resp

    $g1Val = if ($null -ne $h1Json -and (Test-HasNonNullProperty $h1Json "generation")) { ConvertTo-Int64Safe $h1Json.generation } else { $null }
    $g2Val = if ($null -ne $h2Json -and (Test-HasNonNullProperty $h2Json "generation")) { ConvertTo-Int64Safe $h2Json.generation } else { $null }
    if ($null -ne $g1Val -and $null -ne $g2Val) {
        $genInc = ($g2Val -gt $g1Val)
        Add-CheckResult -Section "r3_ingest" -Id "R3_Host_Health_Generation_Monotonic" -Passed $genInc -Method "GET" -Target $h1Url -Detail "gen1=$g1Val -> gen2=$g2Val"
    } else {
        Add-CheckResult -Section "r3_ingest" -Id "R3_Host_Health_Generation_Monotonic" -Passed $false -Method "GET" -Target $h1Url -Detail "Cannot verify generation monotonicity because health JSON failed or generation was non-numeric"
    }

    $rHostPostHealth = Invoke-HttpProbe -Client $client -Method "POST" -Url $h1Url -Body '{}'
    $null = Assert-HttpStatus -Section "r3_ingest" -Id "R3_Host_PostHealth_MethodNotAllowed_405" -Method "POST" -TargetUrl $h1Url -ExpectedStatus 405 -Resp $rHostPostHealth

    if (-not $SkipEdge) {
        $edgeHealthUrl = "$EdgeWorkerUri/api/v1/health"
        $edgeHealthResp = Invoke-HttpProbe -Client $client -Method "GET" -Url $edgeHealthUrl
        $null = Assert-HealthPayload -Section "r3_ingest" -Id "R3_Edge_Health" -TargetUrl $edgeHealthUrl -Resp $edgeHealthResp

        $rEdgePostHealth = Invoke-HttpProbe -Client $client -Method "POST" -Url $edgeHealthUrl -Body '{}'
        $edgePostHealthOk = ($null -eq $rEdgePostHealth.TransportError) -and (($rEdgePostHealth.StatusCode -eq 405) -or ($rEdgePostHealth.StatusCode -eq 403))
        Add-CheckResult -Section "r3_ingest" -Id "R3_Edge_PostHealth_NotAllowed_405_or_403" -Passed $edgePostHealthOk -Method "POST" -Target $edgeHealthUrl -ExpectedStatus 405 -ActualStatus $rEdgePostHealth.StatusCode -Detail "HTTP $($rEdgePostHealth.StatusCode) (expected 405 or 403, never 200) err=$($rEdgePostHealth.TransportError)"
    }

    # 1b. Bare GET telemetry endpoints
    $hostTeleBaseline = $null
    foreach ($ep in @("/api/v1/telemetry", "/api/v1/telemetry/snapshot", "/api/v1/StateGraph")) {
        $u = "$HostUri$ep"
        $r = Invoke-HttpProbe -Client $client -Method "GET" -Url $u
        $j = Assert-TelemetryPayload -Section "r3_ingest" -Id ("R3_Host_BareGet_" + ($ep.TrimStart('/').Replace('/', '_'))) -TargetUrl $u -Resp $r
        if ($ep -eq "/api/v1/telemetry" -and $null -ne $j) {
            $hostTeleBaseline = $j
        }
    }

    if (-not $SkipEdge) {
        foreach ($ep in @("/api/v1/telemetry/snapshot", "/api/v1/StateGraph")) {
            $u = "$EdgeWorkerUri$ep"
            $r = Invoke-HttpProbe -Client $client -Method "GET" -Url $u
            $null = Assert-TelemetryPayload -Section "r3_ingest" -Id ("R3_Edge_BareGet_" + ($ep.TrimStart('/').Replace('/', '_'))) -TargetUrl $u -Resp $r
        }
    }

    # 1c. Write-Query-Param 403 & Zero-Mutation Matrix (all 29 params + combined)
    $writeParamSentinels = @(
        @{ name = "node";         qs = "node=pixel10" },
        @{ name = "kops";         qs = "kops=987654.3" },
        @{ name = "p8_kops";      qs = "p8_kops=943210.9" },
        @{ name = "pixel10_kops"; qs = "pixel10_kops=987654.3" },
        @{ name = "pixel10";      qs = "pixel10=987654.3" },
        @{ name = "pixel8_kops";  qs = "pixel8_kops=943210.9" },
        @{ name = "pixel8";       qs = "pixel8=943210.9" },
        @{ name = "loq15_kops";   qs = "loq15_kops=919876.5" },
        @{ name = "loq15";        qs = "loq15=919876.5" },
        @{ name = "anchor1_kops"; qs = "anchor1_kops=919876.5" },
        @{ name = "p8_free";      qs = "p8_free=1" },
        @{ name = "col";          qs = "col=1" },
        @{ name = "mx";           qs = "mx=9876.5" },
        @{ name = "my";           qs = "my=9876.5" },
        @{ name = "mz";           qs = "mz=9876.5" },
        @{ name = "bn";           qs = "bn=9876.5" },
        @{ name = "baro";         qs = "baro=777.7" },
        @{ name = "lux";          qs = "lux=98765.0" },
        @{ name = "acc";          qs = "acc=987.6" },
        @{ name = "gyro";         qs = "gyro=987.6" },
        @{ name = "temp";         qs = "temp=99.9" },
        @{ name = "mv";           qs = "mv=9876.0" },
        @{ name = "bat";          qs = "bat=99.0" },
        @{ name = "ram_u";        qs = "ram_u=98765.0" },
        @{ name = "ram_t";        qs = "ram_t=98765.0" },
        @{ name = "shz";          qs = "shz=987.6" },
        @{ name = "thz";          qs = "thz=987.6" },
        @{ name = "rtt";          qs = "rtt=987.6" },
        @{ name = "bearer";       qs = "bearer=CANARY_PROBE_V7323" },
        @{ name = "combined";     qs = "node=pixel10&pixel10_kops=987654.3&p8_kops=943210.9&loq15_kops=919876.5&p8_free=1&col=1&mx=9876.5&baro=777.7&bearer=CANARY_PROBE_V7323" }
    )

    $readOnlyPaths = @("/api/v1/telemetry", "/api/v1/telemetry/snapshot", "/api/v1/StateGraph", "/api/v1/health")
    $targetsList = New-Object System.Collections.Generic.List[object]
    $targetsList.Add([pscustomobject]@{ Label = "Host"; BaseUri = $HostUri })
    if (-not $SkipEdge) {
        $targetsList.Add([pscustomobject]@{ Label = "Edge"; BaseUri = $EdgeWorkerUri })
    }

    $writeParamTotal = 0
    $writeParamPassed = 0
    foreach ($tgt in $targetsList) {
        foreach ($ep in $readOnlyPaths) {
            foreach ($wp in $writeParamSentinels) {
                $writeParamTotal++
                $probeUrl = "$($tgt.BaseUri)$ep`?$($wp.qs)"
                $r = Invoke-HttpProbe -Client $client -Method "GET" -Url $probeUrl
                $cid = "R3_$($tgt.Label)_WriteParam403_$($ep.TrimStart('/').Replace('/', '_'))_$($wp.name)"
                if (Assert-HttpStatus -Section "r3_ingest" -Id $cid -Method "GET" -TargetUrl $probeUrl -ExpectedStatus 403 -Resp $r) {
                    $writeParamPassed++
                }
            }
        }
    }
    Write-Host "  [R3 Write-Param 403 Matrix] $writeParamPassed / $writeParamTotal returned HTTP 403"

    # Re-fetch GET $HostUri/api/v1/telemetry and assert ZERO sentinel values persisted
    $postTeleUrl = "$HostUri/api/v1/telemetry"
    $postTeleResp = Invoke-HttpProbe -Client $client -Method "GET" -Url $postTeleUrl
    $postTele = Assert-TelemetryPayload -Section "r3_ingest" -Id "R3_Host_PostWriteProbe_TelemetryRead" -TargetUrl $postTeleUrl -Resp $postTeleResp
    if ($null -ne $postTele -and (Test-HasNonNullProperty $postTele "baro_hpa")) {
        $p10KopsVal = ConvertTo-DoubleSafe $postTele.pixel10_g5_kops
        $p8KopsVal = ConvertTo-DoubleSafe $postTele.pixel8_l2_kops
        $loqKopsVal = ConvertTo-DoubleSafe $postTele.loq15_rtx3050_kops
        $clustKopsVal = ConvertTo-DoubleSafe $postTele.cluster_total_kops
        $magXVal = ConvertTo-DoubleSafe $postTele.mag_x
        $baroVal = ConvertTo-DoubleSafe $postTele.baro_hpa
        $baseClustVal = if ($null -ne $hostTeleBaseline -and (Test-HasNonNullProperty $hostTeleBaseline "cluster_total_kops")) {
            ConvertTo-DoubleSafe $hostTeleBaseline.cluster_total_kops
        } else {
            $null
        }
        $baseLoqVal = if ($null -ne $hostTeleBaseline -and (Test-HasNonNullProperty $hostTeleBaseline "loq15_rtx3050_kops")) {
            ConvertTo-DoubleSafe $hostTeleBaseline.loq15_rtx3050_kops
        } else {
            $null
        }
        $clusterMaxAllowed = if ($null -ne $baseClustVal) { [math]::Max(2500000.0, $baseClustVal + 1000000.0) } else { 2500000.0 }
        $loqMaxAllowed = if ($null -ne $baseLoqVal) { [math]::Max(2500000.0, $baseLoqVal + 1000000.0) } else { 2500000.0 }

        if ($null -ne $p10KopsVal -and $null -ne $p8KopsVal -and $null -ne $loqKopsVal -and $null -ne $clustKopsVal -and $null -ne $magXVal -and $null -ne $baroVal) {
            $noSentinelP10 = ($p10KopsVal -lt 900000.0) -and ([math]::Abs($p10KopsVal - 987654.3) -gt 0.01)
            $noSentinelP8 = ($p8KopsVal -lt 900000.0) -and ([math]::Abs($p8KopsVal - 943210.9) -gt 0.01)
            $noSentinelLoq = ($loqKopsVal -lt $loqMaxAllowed) -and ([math]::Abs($loqKopsVal - 919876.5) -gt 0.01)
            $noSentinelClust = ($clustKopsVal -lt $clusterMaxAllowed) -and ([math]::Abs($clustKopsVal - 987654.3) -gt 0.01) -and ([math]::Abs($clustKopsVal - 943210.9) -gt 0.01) -and ([math]::Abs($clustKopsVal - 919876.5) -gt 0.01)
            $noSentinelMx = ([math]::Abs($magXVal - 9876.5) -gt 0.01)
            $noSentinelBaro = ([math]::Abs($baroVal - 777.7) -gt 0.01)
            $noSentinelP10B = ([string]$postTele.p10_bearer -ne "CANARY_PROBE_V7323")
            $noSentinelP8B = ([string]$postTele.p8_bearer -ne "CANARY_PROBE_V7323")
            $zeroMutation = $noSentinelP10 -and $noSentinelP8 -and $noSentinelLoq -and $noSentinelClust -and $noSentinelMx -and $noSentinelBaro -and $noSentinelP10B -and $noSentinelP8B
            $mutDetail = "p10_kops=$p10KopsVal p8_kops=$p8KopsVal loq_kops=$loqKopsVal total=$clustKopsVal(limit=$clusterMaxAllowed) mag_x=$magXVal baro=$baroVal p10_bearer=$($postTele.p10_bearer) p8_bearer=$($postTele.p8_bearer)"
            Add-CheckResult -Section "r3_ingest" -Id "R3_ZeroMutation_SentinelCheck" -Passed $zeroMutation -Method "GET" -Target $postTeleUrl -Detail $mutDetail
        } else {
            Add-CheckResult -Section "r3_ingest" -Id "R3_ZeroMutation_SentinelCheck" -Passed $false -Method "GET" -Target $postTeleUrl -Detail "Non-numeric or missing telemetry numeric fields after write-param probes"
        }
    } else {
        Add-CheckResult -Section "r3_ingest" -Id "R3_ZeroMutation_SentinelCheck" -Passed $false -Method "GET" -Target $postTeleUrl -Detail "Missing/invalid telemetry response after write-param probes"
    }

    # 1d. POST /api/v1/telemetry/ingest Auth, Edge Block, Bounds & Positive
    $ingestPath = "/api/v1/telemetry/ingest"
    $validProbeBody = '{"node":"pixel10","mx":42.5,"baro":1013.25,"temp":30.0,"bat":80.0,"col":0,"p10_kops":12.5,"bearer":"PROBE_V7323_TEL"}'

    if (-not $SkipEdge) {
        $edgeIngestUrl = "$EdgeWorkerUri$ingestPath"
        $rEdgeUnauth = Invoke-HttpProbe -Client $client -Method "POST" -Url $edgeIngestUrl -Body $validProbeBody
        $null = Assert-HttpStatus -Section "r3_ingest" -Id "R3_Edge_PostIngest_Unauth_403" -Method "POST" -TargetUrl $edgeIngestUrl -ExpectedStatus 403 -Resp $rEdgeUnauth

        $edgeHdrTel = if ($telKeyInfo.Found) { $telKey } else { "unprovisioned_dummy_telemetry_key_probe_00" }
        $rEdgeWithTel = Invoke-HttpProbe -Client $client -Method "POST" -Url $edgeIngestUrl -Headers @{ "X-Sovereign-Telemetry-Key" = $edgeHdrTel } -Body $validProbeBody
        $null = Assert-HttpStatus -Section "r3_ingest" -Id "R3_Edge_PostIngest_WithTelKey_403" -Method "POST" -TargetUrl $edgeIngestUrl -ExpectedStatus 403 -Resp $rEdgeWithTel -ExtraDetail "Edge must block telemetry ingest even with header"
    }

    $hostIngestUrl = "$HostUri$ingestPath"
    $rHostNoKey = Invoke-HttpProbe -Client $client -Method "POST" -Url $hostIngestUrl -Body $validProbeBody
    $null = Assert-HttpStatus -Section "r3_ingest" -Id "R3_Host_PostIngest_NoKey_403" -Method "POST" -TargetUrl $hostIngestUrl -ExpectedStatus 403 -Resp $rHostNoKey

    $smuggleKey = if ($telKeyInfo.Found) { $telKey } elseif ($opKeyInfo.Found) { $opKey } else { "dummy_query_smuggle_probe_key_00000" }
    $smuggleHeaders = @{}
    if ($telKeyInfo.Found) {
        $smuggleHeaders["X-Sovereign-Telemetry-Key"] = $telKey
    }
    $rHostQueryKey = Invoke-HttpProbe -Client $client -Method "POST" -Url "$hostIngestUrl`?key=$([uri]::EscapeDataString($smuggleKey))" -Headers $smuggleHeaders -Body $validProbeBody
    $null = Assert-HttpStatus -Section "r3_ingest" -Id "R3_Host_PostIngest_QueryKeySmuggle_403" -Method "POST" -TargetUrl "$hostIngestUrl`?key=<REDACTED>" -ExpectedStatus 403 -Resp $rHostQueryKey

    if (-not $telKeyInfo.Found) {
        Add-CheckResult -Section "r3_ingest" -Id "R3_Host_PostIngest_PctEncodedQueryKey_TelHeader_403" -Passed $false -Method "POST" -Target "$hostIngestUrl`?%6bey=<REDACTED>" -ExpectedStatus 403 -Detail "FAIL-CLOSED: Telemetry key unavailable ($TelemetryKeyPath / ACT_OMEGA_TELEMETRY_KEY)"
    } else {
        $rHostPctTel = Invoke-HttpProbe -Client $client -Method "POST" -Url "$hostIngestUrl`?%6bey=$([uri]::EscapeDataString($telKey))" -Headers @{ "X-Sovereign-Telemetry-Key" = $telKey } -Body $validProbeBody
        $null = Assert-HttpStatus -Section "r3_ingest" -Id "R3_Host_PostIngest_PctEncodedQueryKey_TelHeader_403" -Method "POST" -TargetUrl "$hostIngestUrl`?%6bey=<REDACTED>" -ExpectedStatus 403 -Resp $rHostPctTel
    }

    if (-not $opKeyInfo.Found) {
        Add-CheckResult -Section "r3_ingest" -Id "R3_Host_PostIngest_OperatorHeaderPlusQueryKeySmuggle_403" -Passed $false -Method "POST" -Target "$hostIngestUrl`?key=<REDACTED>" -ExpectedStatus 403 -Detail "FAIL-CLOSED: Operator key unavailable ($OperatorKeyPath / ACT_OMEGA_OPERATOR_KEY)"
        Add-CheckResult -Section "r3_ingest" -Id "R3_Host_PostIngest_PctEncodedQueryKey_OpHeader_403" -Passed $false -Method "POST" -Target "$hostIngestUrl`?%6bey=<REDACTED>" -ExpectedStatus 403 -Detail "FAIL-CLOSED: Operator key unavailable ($OperatorKeyPath / ACT_OMEGA_OPERATOR_KEY)"
    } else {
        $opHdr = @{ "X-Sovereign-Operator-Key" = $opKey }
        $escOp = [uri]::EscapeDataString($opKey)
        $rHostOpQueryKey = Invoke-HttpProbe -Client $client -Method "POST" -Url "$hostIngestUrl`?key=$escOp" -Headers $opHdr -Body $validProbeBody
        $null = Assert-HttpStatus -Section "r3_ingest" -Id "R3_Host_PostIngest_OperatorHeaderPlusQueryKeySmuggle_403" -Method "POST" -TargetUrl "$hostIngestUrl`?key=<REDACTED>" -ExpectedStatus 403 -Resp $rHostOpQueryKey

        $rHostOpPctQueryKey = Invoke-HttpProbe -Client $client -Method "POST" -Url "$hostIngestUrl`?%6bey=$escOp" -Headers $opHdr -Body $validProbeBody
        $null = Assert-HttpStatus -Section "r3_ingest" -Id "R3_Host_PostIngest_PctEncodedQueryKey_OpHeader_403" -Method "POST" -TargetUrl "$hostIngestUrl`?%6bey=<REDACTED>" -ExpectedStatus 403 -Resp $rHostOpPctQueryKey
    }

    $rHostWrongKey = Invoke-HttpProbe -Client $client -Method "POST" -Url $hostIngestUrl -Headers @{ "X-Sovereign-Telemetry-Key" = "wrong_telemetry_key_v7323_must_reject_000" } -Body $validProbeBody
    $null = Assert-HttpStatus -Section "r3_ingest" -Id "R3_Host_PostIngest_WrongTelKey_403" -Method "POST" -TargetUrl $hostIngestUrl -ExpectedStatus 403 -Resp $rHostWrongKey

    # Snapshot pre-ingest values for clean restoration
    $preIngestTele = $postTele
    if ($null -eq $preIngestTele) {
        $preIngestTele = $hostTeleBaseline
    }

    # Bounds & positive with X-Sovereign-Telemetry-Key (fail closed if key missing!)
    $boundsCases = @(
        @{ id = "temp_9999";   body = '{"node":"pixel10","temp":9999}' },
        @{ id = "kops_neg5";   body = '{"node":"pixel10","kops":-5}' },
        @{ id = "bat_500";     body = '{"node":"pixel10","bat":500}' },
        @{ id = "kops_strNaN"; body = '{"node":"pixel10","kops":"NaN"}' },
        @{ id = "kops_rawNaN"; body = '{"node":"pixel10","kops":NaN}' },
        @{ id = "malformed";   body = '{bad' },
        @{ id = "col_9999";    body = '{"node":"pixel10","col":9999}' },
        @{ id = "baro_50";     body = '{"node":"pixel10","baro":50}' }
    )

    if (-not $telKeyInfo.Found) {
        foreach ($bc in $boundsCases) {
            Add-CheckResult -Section "r3_ingest" -Id "R3_Host_PostIngest_Bounds400_$($bc.id)" -Passed $false -Method "POST" -Target $hostIngestUrl -ExpectedStatus 400 -Detail "FAIL-CLOSED: Telemetry key unavailable ($TelemetryKeyPath / ACT_OMEGA_TELEMETRY_KEY)"
        }
        Add-CheckResult -Section "r3_ingest" -Id "R3_Host_PostIngest_TelemetryKey_Positive_200" -Passed $false -Method "POST" -Target $hostIngestUrl -ExpectedStatus 200 -Detail "FAIL-CLOSED: Telemetry key unavailable ($TelemetryKeyPath / ACT_OMEGA_TELEMETRY_KEY)"
    } else {
        $telHeaders = @{ "X-Sovereign-Telemetry-Key" = $telKey }
        foreach ($bc in $boundsCases) {
            $rb = Invoke-HttpProbe -Client $client -Method "POST" -Url $hostIngestUrl -Headers $telHeaders -Body $bc.body
            $null = Assert-HttpStatus -Section "r3_ingest" -Id "R3_Host_PostIngest_Bounds400_$($bc.id)" -Method "POST" -TargetUrl $hostIngestUrl -ExpectedStatus 400 -Resp $rb -ExtraDetail "payload=$($bc.body)"
        }

        $rTelPos = Invoke-HttpProbe -Client $client -Method "POST" -Url $hostIngestUrl -Headers $telHeaders -Body $validProbeBody
        $null = Assert-HttpStatus -Section "r3_ingest" -Id "R3_Host_PostIngest_TelemetryKey_Positive_200" -Method "POST" -TargetUrl $hostIngestUrl -ExpectedStatus 200 -Resp $rTelPos
    }

    # Check X-Sovereign-Operator-Key works on POST /api/v1/telemetry/ingest (200)
    if (-not $opKeyInfo.Found) {
        Add-CheckResult -Section "r3_ingest" -Id "R3_Host_PostIngest_OperatorKey_Positive_200" -Passed $false -Method "POST" -Target $hostIngestUrl -ExpectedStatus 200 -Detail "FAIL-CLOSED: Operator key unavailable"
    } else {
        $opIngestBody = '{"node":"pixel10","mx":43.5,"baro":1013.25,"temp":30.0,"bat":80.0,"col":0,"p10_kops":12.5,"bearer":"PROBE_V7323_OP"}'
        $rOpPos = Invoke-HttpProbe -Client $client -Method "POST" -Url $hostIngestUrl -Headers @{ "X-Sovereign-Operator-Key" = $opKey } -Body $opIngestBody
        $null = Assert-HttpStatus -Section "r3_ingest" -Id "R3_Host_PostIngest_OperatorKey_Positive_200" -Method "POST" -TargetUrl $hostIngestUrl -ExpectedStatus 200 -Resp $rOpPos
    }

    # Restore pre-test mag_x / baro_hpa / p10_temp_c / p10_batt_pct / p10_bearer if pre-test values were read and at least one valid key exists
    if ($null -ne $preIngestTele -and ($telKeyInfo.Found -or $opKeyInfo.Found)) {
        $restoreMap = [ordered]@{ node = "pixel10" }
        if (Test-HasNonNullProperty $preIngestTele "mag_x") {
            $mxOrig = ConvertTo-DoubleSafe $preIngestTele.mag_x
            if ($null -ne $mxOrig -and $mxOrig -ge -100000.0 -and $mxOrig -le 100000.0) {
                $restoreMap["mx"] = $mxOrig
            }
        }
        if (Test-HasNonNullProperty $preIngestTele "baro_hpa") {
            $baroOrig = ConvertTo-DoubleSafe $preIngestTele.baro_hpa
            if ($null -ne $baroOrig -and $baroOrig -ge 300.0 -and $baroOrig -le 1200.0) {
                $restoreMap["baro"] = $baroOrig
            }
        }
        if (Test-HasNonNullProperty $preIngestTele "p10_temp_c") {
            $tempOrig = ConvertTo-DoubleSafe $preIngestTele.p10_temp_c
            if ($null -ne $tempOrig -and $tempOrig -ge -40.0 -and $tempOrig -le 150.0) {
                $restoreMap["temp"] = $tempOrig
            }
        }
        if (Test-HasNonNullProperty $preIngestTele "p10_batt_pct") {
            $batOrig = ConvertTo-DoubleSafe $preIngestTele.p10_batt_pct
            if ($null -ne $batOrig -and $batOrig -ge 0.0 -and $batOrig -le 100.0) {
                $restoreMap["bat"] = $batOrig
            }
        }
        if (Test-HasNonNullProperty $preIngestTele "p10_bearer") {
            $bearerOrig = [string]$preIngestTele.p10_bearer
            if (-not [string]::IsNullOrWhiteSpace($bearerOrig) -and $bearerOrig.Length -le 128) {
                $restoreMap["bearer"] = $bearerOrig
            }
        }
        if ($restoreMap.Count -gt 1) {
            $restoreJson = ($restoreMap | ConvertTo-Json -Compress)
            $restoreHdr = if ($telKeyInfo.Found) { @{ "X-Sovereign-Telemetry-Key" = $telKey } } else { @{ "X-Sovereign-Operator-Key" = $opKey } }
            $rRestore = Invoke-HttpProbe -Client $client -Method "POST" -Url $hostIngestUrl -Headers $restoreHdr -Body $restoreJson
            $null = Assert-HttpStatus -Section "r3_ingest" -Id "R3_Host_PostIngest_StateRestore_200" -Method "POST" -TargetUrl $hostIngestUrl -ExpectedStatus 200 -Resp $rRestore -ExtraDetail "Restored pre-probe mag_x/baro/temp/bat/p10_bearer"
        }
    }

    # =========================================================================
    # SECTION 2 — R4 11 Handler Groups (16 Routes) & .spage SHA-256 Invariance
    # =========================================================================
    Write-Host "`n[Section 2] R4 11 Handler Groups (16 Routes) & .spage Invariance..." -ForegroundColor Yellow

    if (-not $SkipCronPause) {
        if (-not $opKeyInfo.Found) {
            Add-CheckResult -Section "r4_gates" -Id "R4_Cron_Pause" -Passed $false -Method "POST" -Target "$HostUri/api/v1/aegis/cron_status" -ExpectedStatus 200 -Detail "FAIL-CLOSED: Cannot pause cron without operator key"
        } else {
            $cronUrl = "$HostUri/api/v1/aegis/cron_status"
            $rCronPause = Invoke-HttpProbe -Client $client -Method "POST" -Url $cronUrl -Headers @{ "X-Sovereign-Operator-Key" = $opKey } -Body '{"enabled":false}'
            if (Assert-HttpStatus -Section "r4_gates" -Id "R4_Cron_Pause" -Method "POST" -TargetUrl $cronUrl -ExpectedStatus 200 -Resp $rCronPause -ExtraDetail "Paused aegis_autonomous_cron before .spage snapshot") {
                $cronPaused = $true
                Start-Sleep -Milliseconds 300
            }
        }
    }

    $watchedRelPaths = @(
        "00_control\weights\synapses_v5700_2027520.spage",
        "00_control\weights\synapses_v6900_2703360.spage",
        "03_vault\connectome\message_bus_ledger_v4800.jsonl",
        "03_vault\connectome\codegen_integration_manifest_v4800.jsonl"
    )
    $preSnapshots = @{}
    foreach ($rel in $watchedRelPaths) {
        $full = Join-Path $RepoRoot $rel
        $snap = Get-FileSnapshot -FullPath $full
        $preSnapshots[$rel] = $snap
        $safeId = "R4_PreHash_" + ($rel.Replace('\', '_').Replace('.', '_'))
        if ($snap.Exists) {
            Add-CheckResult -Section "r4_gates" -Id $safeId -Passed $true -Target $rel -Detail "bytes=$($snap.Length) sha256=$($snap.Sha256)"
        } else {
            Add-CheckResult -Section "r4_gates" -Id $safeId -Passed $false -Target $rel -Detail "Watched file missing: $full"
        }
    }

    $r4Routes = @(
        @{ path = "/api/v1/p8_root/hardware_audit";        postBody = '{}' },
        @{ path = "/api/v1/p8_root/governor";              postBody = '{}' },
        @{ path = "/api/v1/aegis/autonomous_harness";      postBody = '{}' },
        @{ path = "/api/v1/harness/aegis_autonomous_loop"; postBody = '{}' },
        @{ path = "/api/v1/aegis/cron_status";             postBody = '{"action":"trigger_now"}' },
        @{ path = "/api/v1/gemma4/sh4z_layer_mixer";       postBody = '{}' },
        @{ path = "/api/v1/gemma4/http206_slice";          postBody = '{}' },
        @{ path = "/api/v1/connectome/spage_3m_synapses";  postBody = '{}' },
        @{ path = "/api/v1/gemma4/ple_256d_surgical_router"; postBody = '{}' },
        @{ path = "/api/v1/tools/t272";                    postBody = '{}' },
        @{ path = "/api/v1/gemma4/multimodal_tower_probe"; postBody = '{}' },
        @{ path = "/api/v1/tools/t273";                    postBody = '{}' },
        @{ path = "/api/v1/gemma4/speculative_cascade";    postBody = '{"prompt":"probe","k":4}' },
        @{ path = "/api/v1/tools/t274";                    postBody = '{"prompt":"probe","k":4}' },
        @{ path = "/api/v1/gemma4/bpe_resolve";            postBody = '{}' },
        @{ path = "/api/v1/tools/t271";                    postBody = '{}' },
        @{ path = "/api/v1/tools/t195";                    postBody = '{}' },
        @{ path = "/api/v1/tool/195";                      postBody = '{}' },
        @{ path = "/api/v1/tools/t204";                    postBody = '{}' },
        @{ path = "/api/v1/tool/204";                      postBody = '{}' },
        @{ path = "/api/v1/tools/t212";                    postBody = '{}' },
        @{ path = "/api/v1/tool/212";                      postBody = '{}' },
        @{ path = "/api/v1/tools/t258";                    postBody = '{}' },
        @{ path = "/api/v1/tool/258";                      postBody = '{}' },
        @{ path = "/api/v1/tools/t260";                    postBody = '{}' },
        @{ path = "/api/v1/tool/260";                      postBody = '{}' }
    )

    $r4Total = 0
    $r4Passed = 0
    foreach ($tgt in $targetsList) {
        foreach ($rt in $r4Routes) {
            $slug = $rt.path.TrimStart('/').Replace('/', '_')
            $u = "$($tgt.BaseUri)$($rt.path)"

            $r4Total++
            $rGet = Invoke-HttpProbe -Client $client -Method "GET" -Url $u
            if (Assert-HttpStatus -Section "r4_gates" -Id "R4_$($tgt.Label)_Unauth_GET_$slug" -Method "GET" -TargetUrl $u -ExpectedStatus 403 -Resp $rGet) {
                $r4Passed++
            }

            $r4Total++
            $rPost = Invoke-HttpProbe -Client $client -Method "POST" -Url $u -Body $rt.postBody
            if (Assert-HttpStatus -Section "r4_gates" -Id "R4_$($tgt.Label)_Unauth_POST_$slug" -Method "POST" -TargetUrl $u -ExpectedStatus 403 -Resp $rPost) {
                $r4Passed++
            }
        }
    }

    # Unauthenticated POST /api/v1/tool/execute with R4 tool IDs -> 403 on Host & Edge
    $r4ExecuteToolIds = @(195, 212, 258, 260, 271, 272, 273, 274)
    foreach ($tgt in $targetsList) {
        $execUrl = "$($tgt.BaseUri)/api/v1/tool/execute"
        foreach ($tid in $r4ExecuteToolIds) {
            $r4Total++
            $rExec = Invoke-HttpProbe -Client $client -Method "POST" -Url $execUrl -Body "{`"tool_id`":$tid}"
            if (Assert-HttpStatus -Section "r4_gates" -Id "R4_$($tgt.Label)_Unauth_POST_tool_execute_t$tid" -Method "POST" -TargetUrl $execUrl -ExpectedStatus 403 -Resp $rExec -ExtraDetail "tool_id=$tid") {
                $r4Passed++
            }
        }
    }

    # ?key=<opKey> and ?%6bey=<opKey> smuggling probes (unauthenticated AND paired with valid X-Sovereign-Operator-Key)
    $keySmuggleRoutes = @(
        @{ path = "/api/v1/p8_root/hardware_audit";   postBody = '{}' },
        @{ path = "/api/v1/aegis/autonomous_harness"; postBody = '{}' },
        @{ path = "/api/v1/gemma4/speculative_cascade"; postBody = '{"prompt":"probe","k":4}' },
        @{ path = "/api/v1/tools/t274";               postBody = '{"prompt":"probe","k":4}' }
    )
    $pctSmuggleRoutes = @(
        @{ path = "/api/v1/p8_root/hardware_audit";   postBody = '{}' },
        @{ path = "/api/v1/gemma4/speculative_cascade"; postBody = '{"prompt":"probe","k":4}' },
        @{ path = "/api/v1/tools/t274";               postBody = '{"prompt":"probe","k":4}' }
    )
    $opSmuggleToken = if ($opKeyInfo.Found) { $opKey } else { "dummy_operator_smuggle_probe_key_0000" }
    $escapedOpToken = [uri]::EscapeDataString($opSmuggleToken)

    foreach ($tgt in $targetsList) {
        foreach ($kr in $keySmuggleRoutes) {
            $slug = $kr.path.TrimStart('/').Replace('/', '_')
            $uSmuggle = "$($tgt.BaseUri)$($kr.path)?key=$escapedOpToken"
            $uSafe = "$($tgt.BaseUri)$($kr.path)?key=<REDACTED>"

            $r4Total++
            $rg = Invoke-HttpProbe -Client $client -Method "GET" -Url $uSmuggle
            if (Assert-HttpStatus -Section "r4_gates" -Id "R4_$($tgt.Label)_QueryKey_GET_$slug" -Method "GET" -TargetUrl $uSafe -ExpectedStatus 403 -Resp $rg) {
                $r4Passed++
            }

            $r4Total++
            $rp = Invoke-HttpProbe -Client $client -Method "POST" -Url $uSmuggle -Body $kr.postBody
            if (Assert-HttpStatus -Section "r4_gates" -Id "R4_$($tgt.Label)_QueryKey_POST_$slug" -Method "POST" -TargetUrl $uSafe -ExpectedStatus 403 -Resp $rp) {
                $r4Passed++
            }

            if (-not $opKeyInfo.Found) {
                $r4Total += 2
                Add-CheckResult -Section "r4_gates" -Id "R4_$($tgt.Label)_HeaderPlusQueryKey_GET_$slug" -Passed $false -Method "GET" -Target $uSafe -ExpectedStatus 403 -Detail "FAIL-CLOSED: Operator key unavailable ($OperatorKeyPath / ACT_OMEGA_OPERATOR_KEY)"
                Add-CheckResult -Section "r4_gates" -Id "R4_$($tgt.Label)_HeaderPlusQueryKey_POST_$slug" -Passed $false -Method "POST" -Target $uSafe -ExpectedStatus 403 -Detail "FAIL-CLOSED: Operator key unavailable ($OperatorKeyPath / ACT_OMEGA_OPERATOR_KEY)"
            } else {
                $opHdr = @{ "X-Sovereign-Operator-Key" = $opKey }
                $r4Total++
                $rgh = Invoke-HttpProbe -Client $client -Method "GET" -Url $uSmuggle -Headers $opHdr
                if (Assert-HttpStatus -Section "r4_gates" -Id "R4_$($tgt.Label)_HeaderPlusQueryKey_GET_$slug" -Method "GET" -TargetUrl $uSafe -ExpectedStatus 403 -Resp $rgh) {
                    $r4Passed++
                }

                $r4Total++
                $rph = Invoke-HttpProbe -Client $client -Method "POST" -Url $uSmuggle -Headers $opHdr -Body $kr.postBody
                if (Assert-HttpStatus -Section "r4_gates" -Id "R4_$($tgt.Label)_HeaderPlusQueryKey_POST_$slug" -Method "POST" -TargetUrl $uSafe -ExpectedStatus 403 -Resp $rph) {
                    $r4Passed++
                }
            }
        }

        foreach ($pr in $pctSmuggleRoutes) {
            $slug = $pr.path.TrimStart('/').Replace('/', '_')
            $uPctSmuggle = "$($tgt.BaseUri)$($pr.path)?%6bey=$escapedOpToken"
            $uPctSafe = "$($tgt.BaseUri)$($pr.path)?%6bey=<REDACTED>"

            $r4Total++
            $rpg = Invoke-HttpProbe -Client $client -Method "GET" -Url $uPctSmuggle
            if (Assert-HttpStatus -Section "r4_gates" -Id "R4_$($tgt.Label)_PctEncodedQueryKey_GET_$slug" -Method "GET" -TargetUrl $uPctSafe -ExpectedStatus 403 -Resp $rpg) {
                $r4Passed++
            }

            $r4Total++
            $rpp = Invoke-HttpProbe -Client $client -Method "POST" -Url $uPctSmuggle -Body $pr.postBody
            if (Assert-HttpStatus -Section "r4_gates" -Id "R4_$($tgt.Label)_PctEncodedQueryKey_POST_$slug" -Method "POST" -TargetUrl $uPctSafe -ExpectedStatus 403 -Resp $rpp) {
                $r4Passed++
            }

            if (-not $opKeyInfo.Found) {
                $r4Total += 2
                Add-CheckResult -Section "r4_gates" -Id "R4_$($tgt.Label)_HeaderPlusPctEncodedQueryKey_GET_$slug" -Passed $false -Method "GET" -Target $uPctSafe -ExpectedStatus 403 -Detail "FAIL-CLOSED: Operator key unavailable ($OperatorKeyPath / ACT_OMEGA_OPERATOR_KEY)"
                Add-CheckResult -Section "r4_gates" -Id "R4_$($tgt.Label)_HeaderPlusPctEncodedQueryKey_POST_$slug" -Passed $false -Method "POST" -Target $uPctSafe -ExpectedStatus 403 -Detail "FAIL-CLOSED: Operator key unavailable ($OperatorKeyPath / ACT_OMEGA_OPERATOR_KEY)"
            } else {
                $opHdr = @{ "X-Sovereign-Operator-Key" = $opKey }
                $r4Total++
                $rpgh = Invoke-HttpProbe -Client $client -Method "GET" -Url $uPctSmuggle -Headers $opHdr
                if (Assert-HttpStatus -Section "r4_gates" -Id "R4_$($tgt.Label)_HeaderPlusPctEncodedQueryKey_GET_$slug" -Method "GET" -TargetUrl $uPctSafe -ExpectedStatus 403 -Resp $rpgh) {
                    $r4Passed++
                }

                $r4Total++
                $rpph = Invoke-HttpProbe -Client $client -Method "POST" -Url $uPctSmuggle -Headers $opHdr -Body $pr.postBody
                if (Assert-HttpStatus -Section "r4_gates" -Id "R4_$($tgt.Label)_HeaderPlusPctEncodedQueryKey_POST_$slug" -Method "POST" -TargetUrl $uPctSafe -ExpectedStatus 403 -Resp $rpph) {
                    $r4Passed++
                }
            }
        }
    }
    Write-Host "  [R4 Gate & Smuggle Matrix]  $r4Passed / $r4Total returned HTTP 403"

    # Re-hash watched files and assert 0-byte / exact SHA-256 invariance
    foreach ($rel in $watchedRelPaths) {
        $pre = $preSnapshots[$rel]
        $post = Get-FileSnapshot -FullPath (Join-Path $RepoRoot $rel)
        $safeId = "R4_Invariance_" + ($rel.Replace('\', '_').Replace('.', '_'))
        $matchOk = $pre.Exists -and $post.Exists -and ($pre.Length -eq $post.Length) -and ($pre.Sha256 -eq $post.Sha256)
        $watchedFilesSummary.Add([pscustomobject]@{
            path        = $rel
            pre_bytes   = $pre.Length
            post_bytes  = $post.Length
            pre_sha256  = $pre.Sha256
            post_sha256 = $post.Sha256
            unchanged   = $matchOk
        })
        Add-CheckResult -Section "r4_gates" -Id $safeId -Passed $matchOk -Target $rel -Detail "pre=$($pre.Length)B/$($pre.Sha256) post=$($post.Length)B/$($post.Sha256)"
    }

    # =========================================================================
    # SECTION 3 — R8 Timing-Allow-Origin 6-Origin Allowlist
    # =========================================================================
    Write-Host "`n[Section 3] R8 Timing-Allow-Origin 6-Origin Allowlist..." -ForegroundColor Yellow

    $taoProbeTargets = New-Object System.Collections.Generic.List[object]
    $taoProbeTargets.Add([pscustomobject]@{ Label = "Host_Str"; BaseUri = $HostUri; Path = "/api/v1/health"; Kind = "write_http_str" })
    $taoProbeTargets.Add([pscustomobject]@{ Label = "Host_Vec"; BaseUri = $HostUri; Path = $VecProbePath;    Kind = "write_http_vec" })
    if (-not $SkipEdge) {
        $taoProbeTargets.Add([pscustomobject]@{ Label = "Edge_Str"; BaseUri = $EdgeWorkerUri; Path = "/api/v1/health"; Kind = "write_http_str" })
        $taoProbeTargets.Add([pscustomobject]@{ Label = "Edge_Vec"; BaseUri = $EdgeWorkerUri; Path = $VecProbePath;    Kind = "write_http_vec" })
    }

    foreach ($tp in $taoProbeTargets) {
        $u = "$($tp.BaseUri)$($tp.Path)"

        # 1. Evil origin -> TAO MUST be absent (and ACAO absent)
        $rEvil = Invoke-HttpProbe -Client $client -Method "GET" -Url $u -Headers @{ "Origin" = "https://evil.example" }
        $taoEvil = if ($rEvil.Headers.ContainsKey("Timing-Allow-Origin")) { $rEvil.Headers["Timing-Allow-Origin"] } else { "" }
        $acaoEvil = if ($rEvil.Headers.ContainsKey("Access-Control-Allow-Origin")) { $rEvil.Headers["Access-Control-Allow-Origin"] } else { "" }
        $evilOk = ($null -eq $rEvil.TransportError) -and ($rEvil.StatusCode -eq 200) -and [string]::IsNullOrEmpty($taoEvil) -and [string]::IsNullOrEmpty($acaoEvil)
        Add-CheckResult -Section "r8_tao" -Id "R8_$($tp.Label)_EvilOrigin_Absent" -Passed $evilOk -Method "GET" -Target $u -ExpectedStatus 200 -ActualStatus $rEvil.StatusCode -Detail "kind=$($tp.Kind) TAO='$taoEvil' ACAO='$acaoEvil' err=$($rEvil.TransportError)"

        # 2. No Origin header -> TAO MUST be absent
        $rNoOrig = Invoke-HttpProbe -Client $client -Method "GET" -Url $u
        $taoNoOrig = if ($rNoOrig.Headers.ContainsKey("Timing-Allow-Origin")) { $rNoOrig.Headers["Timing-Allow-Origin"] } else { "" }
        $noOrigOk = ($null -eq $rNoOrig.TransportError) -and ($rNoOrig.StatusCode -eq 200) -and [string]::IsNullOrEmpty($taoNoOrig)
        Add-CheckResult -Section "r8_tao" -Id "R8_$($tp.Label)_NoOrigin_Absent" -Passed $noOrigOk -Method "GET" -Target $u -ExpectedStatus 200 -ActualStatus $rNoOrig.StatusCode -Detail "kind=$($tp.Kind) TAO='$taoNoOrig' err=$($rNoOrig.TransportError)"

        # 3. Allowlisted primary origins: https://act-omega-net.dev & http://127.0.0.1:5173
        foreach ($allowOrig in @("https://act-omega-net.dev", "http://127.0.0.1:5173")) {
            $origSlug = $allowOrig.Replace("://", "_").Replace(".", "_").Replace(":", "_")
            $rAllow = Invoke-HttpProbe -Client $client -Method "GET" -Url $u -Headers @{ "Origin" = $allowOrig }
            $taoAllow = if ($rAllow.Headers.ContainsKey("Timing-Allow-Origin")) { $rAllow.Headers["Timing-Allow-Origin"] } else { "" }
            $allowOk = ($null -eq $rAllow.TransportError) -and ($rAllow.StatusCode -eq 200) -and ($taoAllow -eq $allowOrig)
            Add-CheckResult -Section "r8_tao" -Id "R8_$($tp.Label)_Allow_$origSlug" -Passed $allowOk -Method "GET" -Target $u -ExpectedStatus 200 -ActualStatus $rAllow.StatusCode -Detail "kind=$($tp.Kind) sent='$allowOrig' TAO='$taoAllow' err=$($rAllow.TransportError)"
        }
    }

    # Verify remaining 4 allowlisted origins on $HostUri/api/v1/health
    $remainingOrigins = @(
        "https://api.act-omega-net.dev",
        "https://mcp.act-omega-net.dev",
        "http://localhost:5173",
        "http://127.0.0.1:8097"
    )
    $hostHealthTaoUrl = "$HostUri/api/v1/health"
    foreach ($remOrig in $remainingOrigins) {
        $origSlug = $remOrig.Replace("://", "_").Replace(".", "_").Replace(":", "_")
        $rRem = Invoke-HttpProbe -Client $client -Method "GET" -Url $hostHealthTaoUrl -Headers @{ "Origin" = $remOrig }
        $taoRem = if ($rRem.Headers.ContainsKey("Timing-Allow-Origin")) { $rRem.Headers["Timing-Allow-Origin"] } else { "" }
        $remOk = ($null -eq $rRem.TransportError) -and ($rRem.StatusCode -eq 200) -and ($taoRem -eq $remOrig)
        Add-CheckResult -Section "r8_tao" -Id "R8_Host_Str_Allow_$origSlug" -Passed $remOk -Method "GET" -Target $hostHealthTaoUrl -ExpectedStatus 200 -ActualStatus $rRem.StatusCode -Detail "sent='$remOrig' TAO='$taoRem' err=$($rRem.TransportError)"
    }

    # =========================================================================
    # SECTION 4 — Item #2 (Gate l0_core/* & t275..t280 at L0 & Edge)
    # =========================================================================
    Write-Host "`n[Section 4] Item #2 (l0_core/* & t275..t280 L0 & Edge Gating)..." -ForegroundColor Yellow

    $item2PreLedger = Get-FileSnapshot -FullPath (Join-Path $RepoRoot "03_vault\connectome\message_bus_ledger_v4800.jsonl")
    $item2PreManifest = Get-FileSnapshot -FullPath (Join-Path $RepoRoot "03_vault\connectome\codegen_integration_manifest_v4800.jsonl")

    $item2Routes = @(
        "/api/v1/l0_core/execute_41_modules",
        "/api/v1/l0_core/sheaf_engine",
        "/api/v1/tools/t275",
        "/api/v1/tool/275",
        "/api/v1/tools/t276",
        "/api/v1/tool/276",
        "/api/v1/tools/t277",
        "/api/v1/tool/277",
        "/api/v1/tools/t278",
        "/api/v1/tool/278",
        "/api/v1/tools/t279",
        "/api/v1/tool/279",
        "/api/v1/tools/t280",
        "/api/v1/tool/280"
    )

    foreach ($tgt in $targetsList) {
        foreach ($p in $item2Routes) {
            $slug = $p.TrimStart('/').Replace('/', '_')
            $u = "$($tgt.BaseUri)$p"
            $rg = Invoke-HttpProbe -Client $client -Method "GET" -Url $u
            $null = Assert-HttpStatus -Section "item2_l0_t275_280" -Id "Item2_$($tgt.Label)_Unauth_GET_$slug" -Method "GET" -TargetUrl $u -ExpectedStatus 403 -Resp $rg
            $rp = Invoke-HttpProbe -Client $client -Method "POST" -Url $u -Body '{}'
            $null = Assert-HttpStatus -Section "item2_l0_t275_280" -Id "Item2_$($tgt.Label)_Unauth_POST_$slug" -Method "POST" -TargetUrl $u -ExpectedStatus 403 -Resp $rp
        }
        foreach ($tid in 275..280) {
            $eu = "$($tgt.BaseUri)/api/v1/tool/execute"
            $re = Invoke-HttpProbe -Client $client -Method "POST" -Url $eu -Body "{`"tool_id`":$tid}"
            $null = Assert-HttpStatus -Section "item2_l0_t275_280" -Id "Item2_$($tgt.Label)_Unauth_POST_execute_t$tid" -Method "POST" -TargetUrl $eu -ExpectedStatus 403 -Resp $re -ExtraDetail "tool_id=$tid"
        }
        if ($opKeyInfo.Found) {
            $opHdr = @{ "X-Sovereign-Operator-Key" = $opKey }
            foreach ($qp in @("/api/v1/l0_core/execute_41_modules", "/api/v1/tools/t275", "/api/v1/tools/t280")) {
                $slug = $qp.TrimStart('/').Replace('/', '_')
                $uq = "$($tgt.BaseUri)${qp}?%6bey=test"
                $rq = Invoke-HttpProbe -Client $client -Method "GET" -Url $uq -Headers $opHdr
                $null = Assert-HttpStatus -Section "item2_l0_t275_280" -Id "Item2_$($tgt.Label)_HeaderPlusPctKey_$slug" -Method "GET" -TargetUrl $uq -ExpectedStatus 403 -Resp $rq
            }
        }
    }

    $item2PostLedger = Get-FileSnapshot -FullPath (Join-Path $RepoRoot "03_vault\connectome\message_bus_ledger_v4800.jsonl")
    $item2PostManifest = Get-FileSnapshot -FullPath (Join-Path $RepoRoot "03_vault\connectome\codegen_integration_manifest_v4800.jsonl")
    $item2InvOk = ($item2PreLedger.Sha256 -eq $item2PostLedger.Sha256) -and ($item2PreManifest.Sha256 -eq $item2PostManifest.Sha256)
    Add-CheckResult -Section "item2_l0_t275_280" -Id "Item2_Negative_ZeroMutation_Invariance" -Passed $item2InvOk -Target "message_bus_ledger & codegen_manifest" -Detail "ledger_eq=$($item2PreLedger.Sha256 -eq $item2PostLedger.Sha256) manifest_eq=$($item2PreManifest.Sha256 -eq $item2PostManifest.Sha256)"

    if ($opKeyInfo.Found) {
        $opHdr = @{ "X-Sovereign-Operator-Key" = $opKey }
        foreach ($tgt in $targetsList) {
            $posPaths = if ($tgt.Label -eq "Host") {
                @("/api/v1/l0_core/execute_41_modules", "/api/v1/l0_core/sheaf_engine", "/api/v1/tools/t275", "/api/v1/tool/275", "/api/v1/tools/t276", "/api/v1/tools/t277", "/api/v1/tools/t278", "/api/v1/tools/t279", "/api/v1/tools/t280")
            } else {
                @("/api/v1/tools/t275", "/api/v1/tools/t276", "/api/v1/tools/t277", "/api/v1/tools/t278", "/api/v1/tools/t279", "/api/v1/tools/t280")
            }
            foreach ($pp in $posPaths) {
                $slug = $pp.TrimStart('/').Replace('/', '_')
                $up = "$($tgt.BaseUri)$pp"
                $rpos = Invoke-HttpProbe -Client $client -Method "POST" -Url $up -Headers $opHdr -Body '{}'
                $null = Assert-HttpStatus -Section "item2_l0_t275_280" -Id "Item2_$($tgt.Label)_Auth_POST_$slug" -Method "POST" -TargetUrl $up -ExpectedStatus 200 -Resp $rpos
            }
        }
    }

    # =========================================================================
    # SECTION 5 — Item #3 (t341, SSE converse, chain135_json, unified, legacy)
    # =========================================================================
    Write-Host "`n[Section 5] Item #3 (chain135_json, SSE converse, unified/*, legacy)..." -ForegroundColor Yellow

    $item3PreKl = Get-FileSnapshot -FullPath (Join-Path $RepoRoot "03_vault\connectome\sh_week3_k4_empirical_kl_receipt.json")
    $item3PreLedger = Get-FileSnapshot -FullPath (Join-Path $RepoRoot "03_vault\connectome\message_bus_ledger_v4800.jsonl")
    $item3PreManifest = Get-FileSnapshot -FullPath (Join-Path $RepoRoot "03_vault\connectome\codegen_integration_manifest_v4800.jsonl")
    $item3PreCounters = Get-FileSnapshot -FullPath (Join-Path $RepoRoot "03_vault\connectome\sh_xi_session_turn_counters.json")

    $item3Routes = @(
        @{ path = "/api/v1/sovereign_harmonic/week3/k4_speculative_cascade"; postBody = '{}' },
        @{ path = "/api/v1/tools/t341"; postBody = '{}' },
        @{ path = "/api/v1/tool/341"; postBody = '{}' },
        @{ path = "/api/v1/sovereign_harmonic/converse"; postBody = '{"prompt":"probe","stream":true}' },
        @{ path = "/api/v1/sh_xi/converse"; postBody = '{"prompt":"probe"}' },
        @{ path = "/converse"; postBody = '{"prompt":"probe"}' },
        @{ path = "/v1/chat/completions"; postBody = '{"model":"sovereign-harmonic-xi-3shell-moe","messages":[{"role":"user","content":"probe"}],"max_tokens":4}' },
        @{ path = "/api/v1/openai/compat"; postBody = '{"model":"sovereign-harmonic-xi-3shell-moe","messages":[{"role":"user","content":"probe"}],"max_tokens":4}' },
        @{ path = "/api/v1/sovereign_harmonic/week4/rlvf_grpo_compiler_in_the_loop"; postBody = '{}' },
        @{ path = "/api/v1/tools/t351"; postBody = '{}' },
        @{ path = "/api/v1/chain316/master_certification"; postBody = '{}' },
        @{ path = "/api/v1/chain362/master_certification"; postBody = '{}' },
        @{ path = "/api/v1/chain368/master_certification"; postBody = '{}' },
        @{ path = "/api/v1/cloudflare/free_tier_governor"; postBody = '{}' },
        @{ path = "/api/v1/vesper_os/ssd_boot_telemetry"; postBody = '{}' },
        @{ path = "/api/v1/weights/verify"; postBody = '{}' },
        @{ path = "/api/v1/v70/bijected_262144_cacheline_manifold"; postBody = '{}' },
        @{ path = "/api/v1/v69_5/rtx3050_nvcuda_ptx_driver_probe"; postBody = '{}' },
        @{ path = "/api/v1/v68/omegalang_v15_8target_compiler"; postBody = '{}' },
        @{ path = "/api/v1/v63/capability_parity_bput"; postBody = '{}' },
        @{ path = "/api/v1/polytope7777/crt_pfa"; postBody = '{}' },
        @{ path = "/api/v1/fluency/open_vocab_524k_192subdomains_mit_rag"; postBody = '{}' },
        @{ path = "/api/v1/connectome/tier4_84480_neurons_4055040_synapses"; postBody = '{}' },
        @{ path = "/api/v1/omegalang/v16_primary_tlv_compiler"; postBody = '{}' },
        @{ path = "/api/v1/audit/cern_lhcb_5mapping_auditor"; postBody = '{}' },
        @{ path = "/api/v1/mit_pipeline/hot_index_ingest_and_query"; postBody = '{}' },
        @{ path = "/api/v1/unified/lattice_algebra_proofs"; postBody = '{}' },
        @{ path = "/api/v1/stiefel"; postBody = '{}' },
        @{ path = "/api/v1/acoustic"; postBody = '{}' },
        @{ path = "/api/v1/wgsl"; postBody = '{}' },
        @{ path = "/api/v1/compute"; postBody = '{}' },
        @{ path = "/api/v1/debate"; postBody = '{}' },
        @{ path = "/api/v1/hotpatch"; postBody = '{}' },
        @{ path = "/api/v1/codegen"; postBody = '{}' },
        @{ path = "/api/v1/tool/104"; postBody = '{}' },
        @{ path = "/api/v1/tools/t146"; postBody = '{}' },
        @{ path = "/api/v1/tools/t214"; postBody = '{}' },
        @{ path = "/api/v1/tools/t289"; postBody = '{}' },
        @{ path = "/api/v1/tools/t305"; postBody = '{}' },
        @{ path = "/api/v1/tool/308"; postBody = '{}' },
        @{ path = "/api/v1/tool/309"; postBody = '{}' },
        @{ path = "/api/v1/tool/310"; postBody = '{}' },
        @{ path = "/api/v1/tool/311"; postBody = '{}' },
        @{ path = "/api/v1/tool/312"; postBody = '{}' },
        @{ path = "/api/v1/tool/313"; postBody = '{}' },
        @{ path = "/api/v1/tool/314"; postBody = '{}' },
        @{ path = "/api/v1/tool/315"; postBody = '{}' },
        @{ path = "/api/v1/tools/t317"; postBody = '{}' },
        @{ path = "/api/v1/tools/t361"; postBody = '{}' }
    )

    foreach ($tgt in $targetsList) {
        foreach ($rt in $item3Routes) {
            $slug = $rt.path.TrimStart('/').Replace('/', '_')
            if ([string]::IsNullOrEmpty($slug)) { $slug = "root" }
            $u = "$($tgt.BaseUri)$($rt.path)"
            $rg = Invoke-HttpProbe -Client $client -Method "GET" -Url $u
            $null = Assert-HttpStatus -Section "item3_chain135_edge" -Id "Item3_$($tgt.Label)_Unauth_GET_$slug" -Method "GET" -TargetUrl $u -ExpectedStatus 403 -Resp $rg
            $rp = Invoke-HttpProbe -Client $client -Method "POST" -Url $u -Body $rt.postBody
            $null = Assert-HttpStatus -Section "item3_chain135_edge" -Id "Item3_$($tgt.Label)_Unauth_POST_$slug" -Method "POST" -TargetUrl $u -ExpectedStatus 403 -Resp $rp
        }
        # Confirm read-only /api/v1/unified/catalog remains public 200
        $uCat = "$($tgt.BaseUri)/api/v1/unified/catalog"
        $rCat = Invoke-HttpProbe -Client $client -Method "GET" -Url $uCat
        $null = Assert-HttpStatus -Section "item3_chain135_edge" -Id "Item3_$($tgt.Label)_Public_GET_unified_catalog" -Method "GET" -TargetUrl $uCat -ExpectedStatus 200 -Resp $rCat

        # Valid X-Sovereign-Operator-Key + encoded ?%6bey= / ?%4Bey= MUST return 403 on OpenAI compat routes
        if ($opKeyInfo.Found) {
            $opHdr = @{ "X-Sovereign-Operator-Key" = $opKey }
            foreach ($oaiPath in @("/v1/chat/completions", "/api/v1/openai/compat")) {
                $oaiSlug = $oaiPath.TrimStart('/').Replace('/', '_')
                foreach ($encParam in @("%6bey", "%4Bey")) {
                    $encSlug = $encParam.Replace("%", "pct")
                    $uOaiQ = "$($tgt.BaseUri)${oaiPath}?${encParam}=test"
                    $rOaiQ = Invoke-HttpProbe -Client $client -Method "POST" -Url $uOaiQ -Headers $opHdr -Body '{"model":"sovereign-harmonic-xi-3shell-moe","messages":[{"role":"user","content":"probe"}],"max_tokens":4}'
                    $null = Assert-HttpStatus -Section "item3_chain135_edge" -Id "Item3_$($tgt.Label)_HeaderPlus_${encSlug}_POST_$oaiSlug" -Method "POST" -TargetUrl $uOaiQ -ExpectedStatus 403 -Resp $rOaiQ
                }
            }
        }
    }

    $item3PostKl = Get-FileSnapshot -FullPath (Join-Path $RepoRoot "03_vault\connectome\sh_week3_k4_empirical_kl_receipt.json")
    $item3PostLedger = Get-FileSnapshot -FullPath (Join-Path $RepoRoot "03_vault\connectome\message_bus_ledger_v4800.jsonl")
    $item3PostManifest = Get-FileSnapshot -FullPath (Join-Path $RepoRoot "03_vault\connectome\codegen_integration_manifest_v4800.jsonl")
    $item3PostCounters = Get-FileSnapshot -FullPath (Join-Path $RepoRoot "03_vault\connectome\sh_xi_session_turn_counters.json")
    $item3InvOk = ($item3PreKl.Sha256 -eq $item3PostKl.Sha256) -and ($item3PreLedger.Sha256 -eq $item3PostLedger.Sha256) -and ($item3PreManifest.Sha256 -eq $item3PostManifest.Sha256) -and ($item3PreCounters.Sha256 -eq $item3PostCounters.Sha256)
    Add-CheckResult -Section "item3_chain135_edge" -Id "Item3_Negative_ZeroMutation_Invariance" -Passed $item3InvOk -Target "t341_kl_receipt & bus_ledger & manifest & turn_counters" -Detail "kl_eq=$($item3PreKl.Sha256 -eq $item3PostKl.Sha256) ledger_eq=$($item3PreLedger.Sha256 -eq $item3PostLedger.Sha256) manifest_eq=$($item3PreManifest.Sha256 -eq $item3PostManifest.Sha256) counters_eq=$($item3PreCounters.Sha256 -eq $item3PostCounters.Sha256)"

    if ($opKeyInfo.Found) {
        $opHdr = @{ "X-Sovereign-Operator-Key" = $opKey }
        foreach ($tgt in $targetsList) {
            $r341 = Invoke-HttpProbe -Client $client -Method "POST" -Url "$($tgt.BaseUri)/api/v1/tools/t341" -Headers $opHdr -Body '{}'
            $null = Assert-HttpStatus -Section "item3_chain135_edge" -Id "Item3_$($tgt.Label)_Auth_POST_t341" -Method "POST" -TargetUrl "$($tgt.BaseUri)/api/v1/tools/t341" -ExpectedStatus 200 -Resp $r341

            $rSse = Invoke-HttpProbe -Client $client -Method "POST" -Url "$($tgt.BaseUri)/api/v1/sovereign_harmonic/converse" -Headers $opHdr -Body '{"prompt":"ping","max_tokens":4,"stream":true}'
            $null = Assert-HttpStatus -Section "item3_chain135_edge" -Id "Item3_$($tgt.Label)_Auth_POST_converse_SSE" -Method "POST" -TargetUrl "$($tgt.BaseUri)/api/v1/sovereign_harmonic/converse" -ExpectedStatus 200 -Resp $rSse

            foreach ($oaiPath in @("/v1/chat/completions", "/api/v1/openai/compat")) {
                $oaiSlug = $oaiPath.TrimStart('/').Replace('/', '_')
                $rOaiPos = Invoke-HttpProbe -Client $client -Method "POST" -Url "$($tgt.BaseUri)$oaiPath" -Headers $opHdr -Body '{"model":"sovereign-harmonic-xi-3shell-moe","session_id":"secprobe_m3_openai_compat","reset_session":false,"messages":[{"role":"user","content":"ping"}],"max_tokens":4}'
                $null = Assert-HttpStatus -Section "item3_chain135_edge" -Id "Item3_$($tgt.Label)_Auth_POST_$oaiSlug" -Method "POST" -TargetUrl "$($tgt.BaseUri)$oaiPath" -ExpectedStatus 200 -Resp $rOaiPos
            }

            $r289 = Invoke-HttpProbe -Client $client -Method "GET" -Url "$($tgt.BaseUri)/api/v1/tools/t289" -Headers $opHdr
            $null = Assert-HttpStatus -Section "item3_chain135_edge" -Id "Item3_$($tgt.Label)_Auth_GET_t289" -Method "GET" -TargetUrl "$($tgt.BaseUri)/api/v1/tools/t289" -ExpectedStatus 200 -Resp $r289

            $rUni = Invoke-HttpProbe -Client $client -Method "POST" -Url "$($tgt.BaseUri)/api/v1/unified/lattice_algebra_proofs" -Headers $opHdr -Body '{}'
            $null = Assert-HttpStatus -Section "item3_chain135_edge" -Id "Item3_$($tgt.Label)_Auth_POST_unified_domain" -Method "POST" -TargetUrl "$($tgt.BaseUri)/api/v1/unified/lattice_algebra_proofs" -ExpectedStatus 200 -Resp $rUni

            $rLeg = Invoke-HttpProbe -Client $client -Method "GET" -Url "$($tgt.BaseUri)/api/v1/stiefel" -Headers $opHdr
            $null = Assert-HttpStatus -Section "item3_chain135_edge" -Id "Item3_$($tgt.Label)_Auth_GET_legacy_stiefel" -Method "GET" -TargetUrl "$($tgt.BaseUri)/api/v1/stiefel" -ExpectedStatus 200 -Resp $rLeg
        }
    }

    # =========================================================================
    # SECTION 6 — Item #4 (webgpu_lease / t78 Auth + Real .e8z PoC Verification)
    # =========================================================================
    Write-Host "`n[Section 6] Item #4 (webgpu_lease / t78 Auth & Real .e8z PoC Verification)..." -ForegroundColor Yellow

    $item4PreLease = Get-FileSnapshot -FullPath (Join-Path $RepoRoot "03_vault\connectome\webgpu_active_leases_v4400.jsonl")

    # Compute exact real .e8z 6D Plucker FNV-1a digest matching App.tsx & v44
    $realPocHash = ""
    $e8zDiskPath = Join-Path $RepoRoot "00_control\weights\sovereign_harmonic_iv_v5000.e8z"
    if (Test-Path $e8zDiskPath -PathType Leaf) {
        $rawE8z = [System.IO.File]::ReadAllBytes($e8zDiskPath)
        if ($rawE8z.Length -ge 2080 * 64) {
            $rawEnergies = New-Object double[] 2080
            $minE = [double]::PositiveInfinity
            $maxE = [double]::NegativeInfinity
            for ($idx = 0; $idx -lt 2080; $idx++) {
                $baseOff = $idx * 64
                $sumSq = 0.0
                $sumDiff = 0.0
                for ($b = 0; $b -lt 64; $b++) {
                    $centered = ($rawE8z[$baseOff + $b] - 127.5) / 127.5
                    $sumSq += $centered * $centered
                    if ($b -gt 0) {
                        $sumDiff += [Math]::Abs($rawE8z[$baseOff + $b] - $rawE8z[$baseOff + $b - 1]) / 255.0
                    }
                }
                $rms = [Math]::Sqrt($sumSq / 64.0)
                $tv = $sumDiff / 63.0
                $bm = (($rawE8z[$baseOff + ($idx % 64)] -bxor $rawE8z[$baseOff + (($idx * 7 + 13) % 64)]) -band 0xff) / 255.0
                $energy = 0.45 * $rms + 0.35 * $tv + 0.20 * $bm
                $rawEnergies[$idx] = $energy
                if ($energy -lt $minE) { $minE = $energy }
                if ($energy -gt $maxE) { $maxE = $energy }
            }
            $span = [Math]::Max(1e-6, $maxE - $minE)
            $maxSafe = [Math]::Max(1e-6, $maxE)
            $normE8z = New-Object double[] 2080
            for ($idx = 0; $idx -lt 2080; $idx++) {
                $normE8z[$idx] = [Math]::Max(0.05 * ($rawEnergies[$idx] / $maxSafe), ($rawEnergies[$idx] - $minE) / $span)
            }
            [uint32]$crc = 0x5348345AL
            for ($i = 0; $i -lt 704; $i++) {
                $ia = ($i * 6) % 2080
                $ib = ($ia + 44) % 2080
                $pab = $normE8z[$ia] * $normE8z[($ib + 5) % 2080] - $normE8z[($ia + 1) % 2080] * $normE8z[($ib + 4) % 2080] + $normE8z[($ia + 2) % 2080] * $normE8z[($ib + 3) % 2080] + $normE8z[($ia + 3) % 2080] * $normE8z[($ib + 2) % 2080] - $normE8z[($ia + 4) % 2080] * $normE8z[($ib + 1) % 2080] + $normE8z[($ia + 5) % 2080] * $normE8z[$ib]
                [int32]$trunc = [Math]::Truncate($pab * 10000.0)
                [uint32]$pluckerWord = [BitConverter]::ToUInt32([BitConverter]::GetBytes($trunc), 0)
                [uint64]$prod = ([uint64]($crc -bxor $pluckerWord)) * ([uint64]0x01000193)
                $crc = [uint32]($prod -band ([uint64]4294967295))
            }
            $realPocHash = ("0x{0:X6}_PLUCKER_POS_QED" -f ($crc -band 0xFFFFFF))
        }
    }
    $pocReady = -not [string]::IsNullOrWhiteSpace($realPocHash)
    Add-CheckResult -Section "item4_webgpu_poc" -Id "Item4_Real_E8Z_Plucker_Poc_Computed" -Passed $pocReady -Target $e8zDiskPath -Detail "realPocHash=$realPocHash"

    foreach ($tgt in $targetsList) {
        foreach ($rp in @("/api/v1/worksteal/webgpu_lease?action=acquire&worker_id=evil&kops=850&poc_hash=0x123456_PLUCKER_POS_QED", "/api/v1/tools/t78", "/api/v1/tool/78")) {
            $slug = ($rp.Split('?')[0]).TrimStart('/').Replace('/', '_')
            $probeUrl4 = "$($tgt.BaseUri)$rp"
            $rg = Invoke-HttpProbe -Client $client -Method "GET" -Url $probeUrl4
            $null = Assert-HttpStatus -Section "item4_webgpu_poc" -Id "Item4_$($tgt.Label)_Unauth_GET_$slug" -Method "GET" -TargetUrl $probeUrl4 -ExpectedStatus 403 -Resp $rg
            $rpost = Invoke-HttpProbe -Client $client -Method "POST" -Url $probeUrl4 -Body '{}'
            $null = Assert-HttpStatus -Section "item4_webgpu_poc" -Id "Item4_$($tgt.Label)_Unauth_POST_$slug" -Method "POST" -TargetUrl $probeUrl4 -ExpectedStatus 403 -Resp $rpost
        }
        $rExec78 = Invoke-HttpProbe -Client $client -Method "POST" -Url "$($tgt.BaseUri)/api/v1/tool/execute" -Body '{"tool_id":78}'
        $null = Assert-HttpStatus -Section "item4_webgpu_poc" -Id "Item4_$($tgt.Label)_Unauth_POST_execute_t78" -Method "POST" -TargetUrl "$($tgt.BaseUri)/api/v1/tool/execute" -ExpectedStatus 403 -Resp $rExec78

        if ($opKeyInfo.Found) {
            $opHdr = @{ "X-Sovereign-Operator-Key" = $opKey }
            $rPct = Invoke-HttpProbe -Client $client -Method "GET" -Url "$($tgt.BaseUri)/api/v1/worksteal/webgpu_lease?action=status&%6bey=test" -Headers $opHdr
            $null = Assert-HttpStatus -Section "item4_webgpu_poc" -Id "Item4_$($tgt.Label)_HeaderPlusPctKey_webgpu_lease" -Method "GET" -TargetUrl "$($tgt.BaseUri)/api/v1/worksteal/webgpu_lease?action=status&%6bey=test" -ExpectedStatus 403 -Resp $rPct

            # Negative 400 checks (empty poc_hash, forged poc_hash, missing kops, NaN kops, out-of-range kops, bogus action)
            $badCases = @(
                @{ id = "EmptyPoc";     q = "action=acquire&worker_id=probe_neg1&kops=400.0" },
                @{ id = "ForgedPoc";    q = "action=acquire&worker_id=probe_neg2&kops=400.0&poc_hash=0xDEAD00_PLUCKER_POS_QED" },
                @{ id = "MissingKops";  q = "action=acquire&worker_id=probe_neg3&poc_hash=$realPocHash" },
                @{ id = "NaNKops";      q = "action=acquire&worker_id=probe_neg4&kops=NaN&poc_hash=$realPocHash" },
                @{ id = "LowKops";      q = "action=acquire&worker_id=probe_neg5&kops=49.9&poc_hash=$realPocHash" },
                @{ id = "HighKops";     q = "action=acquire&worker_id=probe_neg6&kops=850.1&poc_hash=$realPocHash" },
                @{ id = "BogusAction";  q = "action=bogus&worker_id=probe_neg7&kops=400.0&poc_hash=$realPocHash" }
            )
            foreach ($bc in $badCases) {
                $bu = "$($tgt.BaseUri)/api/v1/worksteal/webgpu_lease?$($bc.q)"
                $br = Invoke-HttpProbe -Client $client -Method "GET" -Url $bu -Headers $opHdr
                $bObj = $null
                try { $bObj = $br.Body | ConvertFrom-Json } catch {}
                $bOk = ($br.StatusCode -eq 400) -and ($null -ne $bObj) -and ($bObj.poc_verified -eq $false) -and ($bObj.lease_active -eq $false)
                Add-CheckResult -Section "item4_webgpu_poc" -Id "Item4_$($tgt.Label)_Bad400_$($bc.id)" -Passed $bOk -Method "GET" -Target $bu -ExpectedStatus 400 -ActualStatus $br.StatusCode -Detail "poc_verified=$($bObj.poc_verified) lease_active=$($bObj.lease_active)"
            }
        }
    }

    $item4PostLease = Get-FileSnapshot -FullPath (Join-Path $RepoRoot "03_vault\connectome\webgpu_active_leases_v4400.jsonl")
    $item4InvOk = ($item4PreLease.Sha256 -eq $item4PostLease.Sha256)
    Add-CheckResult -Section "item4_webgpu_poc" -Id "Item4_Negative_ZeroLeaseMutation_Invariance" -Passed $item4InvOk -Target "webgpu_active_leases_v4400.jsonl" -Detail "pre=$($item4PreLease.Sha256) post=$($item4PostLease.Sha256)"

    if ($opKeyInfo.Found -and $pocReady) {
        $opHdr = @{ "X-Sovereign-Operator-Key" = $opKey }
        foreach ($tgt in $targetsList) {
            $acqUrl = "$($tgt.BaseUri)/api/v1/worksteal/webgpu_lease?action=acquire&worker_id=secprobe_v7324&kops=420.0&poc_hash=$realPocHash"
            $rAcq = Invoke-HttpProbe -Client $client -Method "GET" -Url $acqUrl -Headers $opHdr
            $aObj = $null
            try { $aObj = $rAcq.Body | ConvertFrom-Json } catch {}
            $acqOk = ($rAcq.StatusCode -eq 200) -and ($null -ne $aObj) -and ($aObj.poc_verified -eq $true) -and ($aObj.lease_active -eq $true)
            Add-CheckResult -Section "item4_webgpu_poc" -Id "Item4_$($tgt.Label)_Positive_Acquire" -Passed $acqOk -Method "GET" -Target $acqUrl -ExpectedStatus 200 -ActualStatus $rAcq.StatusCode -Detail "poc_verified=$($aObj.poc_verified) lease_active=$($aObj.lease_active)"

            $relUrl = "$($tgt.BaseUri)/api/v1/worksteal/webgpu_lease?action=release&worker_id=secprobe_v7324"
            $rRel = Invoke-HttpProbe -Client $client -Method "GET" -Url $relUrl -Headers $opHdr
            $relObj = $null
            try { $relObj = $rRel.Body | ConvertFrom-Json } catch {}
            $relOk = ($rRel.StatusCode -eq 200) -and ($null -ne $relObj) -and ($relObj.lease_active -eq $false)
            Add-CheckResult -Section "item4_webgpu_poc" -Id "Item4_$($tgt.Label)_Positive_Release" -Passed $relOk -Method "GET" -Target $relUrl -ExpectedStatus 200 -ActualStatus $rRel.StatusCode -Detail "lease_active=$($relObj.lease_active)"
        }
    }

    # =========================================================================
    # SECTION 7 — Item #5 (All 9 Converted ?key= Gates Reject Encoded ?%6bey= / ?%4Bey= with 403 Even With Valid Header)
    # =========================================================================
    Write-Host "`n[Section 7] Item #5 (All 9 Converted ?key= Gates -> 403 on ?%6bey= & ?%4Bey= With Valid Header)..." -ForegroundColor Yellow

    $item5Routes = @(
        "/api/v1/router/distributed_5w1h_dispatch",
        "/api/v1/auth/operator_vault_gate",
        "/api/v1/ota/pixel_apk",
        "/api/v1/ota/pixel_manifest",
        "/api/v1/hud/embedded_ide_cockpit",
        "/api/v1/admin/status",
        "/api/v1/gemma4/chat",
        "/api/v1/tools/t404",
        "/api/v1/lab/station/369"
    )
    if ($opKeyInfo.Found) {
        $opHdr = @{ "X-Sovereign-Operator-Key" = $opKey }
        foreach ($r5 in $item5Routes) {
            $slug = $r5.TrimStart('/').Replace('/', '_')
            foreach ($encParam in @("%6bey", "%4Bey")) {
                $encSlug = $encParam.Replace("%", "pct")
                $u5 = "$HostUri${r5}?${encParam}=test"
                $resp5 = Invoke-HttpProbe -Client $client -Method "GET" -Url $u5 -Headers $opHdr
                $null = Assert-HttpStatus -Section "item5_query_key_9gates" -Id "Item5_Host_ValidHeaderPlus_${encSlug}_$slug" -Method "GET" -TargetUrl $u5 -ExpectedStatus 403 -Resp $resp5
            }
        }

        if (-not $SkipEdge) {
            foreach ($edgeOtaPath in @("/api/v1/tools/t284", "/api/v1/tool/284", "/api/v1/ota/pixel_manifest")) {
                $eSlug = $edgeOtaPath.TrimStart('/').Replace('/', '_')
                $uUnauth = "$EdgeWorkerUri${edgeOtaPath}?edge_direct=1"
                $rUnauth = Invoke-HttpProbe -Client $client -Method "GET" -Url $uUnauth
                $null = Assert-HttpStatus -Section "item5_query_key_9gates" -Id "Item5_EdgeDirect_Unauth_403_$eSlug" -Method "GET" -TargetUrl $uUnauth -ExpectedStatus 403 -Resp $rUnauth

                $uPct = "$EdgeWorkerUri${edgeOtaPath}?edge_direct=1&%6bey=test"
                $rPct = Invoke-HttpProbe -Client $client -Method "GET" -Url $uPct -Headers $opHdr
                $null = Assert-HttpStatus -Section "item5_query_key_9gates" -Id "Item5_EdgeDirect_HeaderPlusPctKey_403_$eSlug" -Method "GET" -TargetUrl $uPct -ExpectedStatus 403 -Resp $rPct

                $uPos = "$EdgeWorkerUri${edgeOtaPath}?edge_direct=1"
                $rPos = Invoke-HttpProbe -Client $client -Method "GET" -Url $uPos -Headers $opHdr
                $posJson = ConvertFrom-JsonSafe -Text $rPos.Body
                $posOk = ($null -eq $rPos.TransportError) -and ($rPos.StatusCode -eq 200) -and ($null -ne $posJson) -and ([string]$posJson.version_name -eq $liveVersion) -and ((ConvertTo-Int64Safe $posJson.version_code) -eq 77) -and ((ConvertTo-Int64Safe $posJson.apk_bytes) -eq 30546770) -and ([string]$posJson.status -eq "MEASURED_PIXEL_OTA_MANIFEST_READY")
                Add-CheckResult -Section "item5_query_key_9gates" -Id "Item5_EdgeDirect_OtaParity_$eSlug" -Passed $posOk -Method "GET" -Target $uPos -ExpectedStatus 200 -ActualStatus $rPos.StatusCode -Detail "version_name=$($posJson.version_name) version_code=$($posJson.version_code) apk_bytes=$($posJson.apk_bytes) status=$($posJson.status)"
            }

            $uEdgeHealth = "$EdgeWorkerUri/api/v1/health?edge_direct=1"
            $rEdgeHealth = Invoke-HttpProbe -Client $client -Method "GET" -Url $uEdgeHealth
            $ehJson = ConvertFrom-JsonSafe -Text $rEdgeHealth.Body
            $ehOk = ($null -eq $rEdgeHealth.TransportError) -and ($rEdgeHealth.StatusCode -eq 200) -and ($null -ne $ehJson) -and ([string]$ehJson.version -eq $liveVersion) -and ((ConvertTo-Int64Safe $ehJson.tlv_version) -eq 7321) -and ([string]$ehJson.status -eq "ONLINE")
            Add-CheckResult -Section "item5_query_key_9gates" -Id "Item5_EdgeDirect_Health_Parity" -Passed $ehOk -Method "GET" -Target $uEdgeHealth -ExpectedStatus 200 -ActualStatus $rEdgeHealth.StatusCode -Detail "version=$($ehJson.version) tlv_version=$($ehJson.tlv_version) status=$($ehJson.status)"
        }
    } else {
        Add-CheckResult -Section "item5_query_key_9gates" -Id "Item5_OperatorKey_Available" -Passed $false -Detail "Operator key missing"
    }
} catch {
    Add-CheckResult -Section "runtime" -Id "Unhandled_Suite_Exception" -Passed $false -Detail "Unhandled exception: $($_.Exception.Message)"
} finally {
    if ($cronPaused -and $opKeyInfo -and $opKeyInfo.Found) {
        try {
            $cronRestoreUrl = "$HostUri/api/v1/aegis/cron_status"
            $rCronRestore = Invoke-HttpProbe -Client $client -Method "POST" -Url $cronRestoreUrl -Headers @{ "X-Sovereign-Operator-Key" = $opKey } -Body '{"enabled":true}'
            $null = Assert-HttpStatus -Section "r4_gates" -Id "R4_Cron_Restore" -Method "POST" -TargetUrl $cronRestoreUrl -ExpectedStatus 200 -Resp $rCronRestore -ExtraDetail "Restored aegis_autonomous_cron"
        } catch {
            Add-CheckResult -Section "r4_gates" -Id "R4_Cron_Restore" -Passed $false -Method "POST" -Target "$HostUri/api/v1/aegis/cron_status" -Detail "Exception restoring cron: $($_.Exception.Message)"
        }
    }

    if ($null -ne $client) { $client.Dispose() }
    if ($null -ne $handler) { $handler.Dispose() }

    $passedTotal = 0
    $failedTotal = 0
    foreach ($c in $checks) {
        if ($c.passed) { $passedTotal++ } else { $failedTotal++ }
    }

    $edgeUriForReceipt = if ($SkipEdge) { "SKIPPED" } else { $EdgeWorkerUri }
    $receiptObj = [ordered]@{
        schema                = "act_omega_v73_2_4_security_negative_probes_v1"
        version               = $liveVersion
        generated_utc         = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
        started_utc           = $runStartedUtc
        host_uri              = $HostUri
        edge_worker_uri       = $edgeUriForReceipt
        vec_probe_path        = $VecProbePath
        skip_edge             = [bool]$SkipEdge
        skip_cron_pause       = [bool]$SkipCronPause
        total_checks          = $checks.Count
        passed_checks         = $passedTotal
        failed_checks         = $failedTotal
        overall_passed        = ($failedTotal -eq 0 -and $checks.Count -gt 0)
        sections              = $sectionCounts
        watched_files         = $watchedFilesSummary.ToArray()
        checks                = $checks.ToArray()
    }

    $receiptDir = Split-Path -Parent $ReceiptOutPath
    if (-not [string]::IsNullOrWhiteSpace($receiptDir) -and -not (Test-Path $receiptDir)) {
        $null = New-Item -ItemType Directory -Force -Path $receiptDir
    }
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    $rawJson = ($receiptObj | ConvertTo-Json -Depth 8)
    $lfJson = ($rawJson + "`n").Replace("`r`n", "`n").Replace("`r", "`n")
    $redactedJson = Protect-RedactedText -InputText $lfJson -OpSecret $opKey -TelSecret $telKey
    [System.IO.File]::WriteAllText($ReceiptOutPath, $redactedJson, $utf8NoBom)
}

$finalPass = 0
$finalFail = 0
foreach ($c in $checks) {
    if ($c.passed) { $finalPass++ } else { $finalFail++ }
}

Write-Host "`n==========================================================================" -ForegroundColor Cyan
if ($finalFail -eq 0 -and $checks.Count -gt 0) {
    Write-Host "  SECURITY PROBE SUITE PASSED: $finalPass / $($checks.Count) checks passed (0 failed)" -ForegroundColor Green
    Write-Host "  Receipt written (UTF-8 no-BOM LF): $ReceiptOutPath" -ForegroundColor Green
    Write-Host "==========================================================================" -ForegroundColor Cyan
    exit 0
} else {
    Write-Host "  SECURITY PROBE SUITE FAILED: $finalFail failed / $finalPass passed ($($checks.Count) total)" -ForegroundColor Red
    Write-Host "  Receipt written (UTF-8 no-BOM LF): $ReceiptOutPath" -ForegroundColor Yellow
    Write-Host "==========================================================================" -ForegroundColor Cyan
    exit 1
}
