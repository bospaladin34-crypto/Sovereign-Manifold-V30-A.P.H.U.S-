# ==============================================================================
# ACT-Omega Net v73.2.2 — Externalized Cloudflare Workers & Workflow Deployer (S6)
# Reads non-committed cloud resource identifiers exclusively from:
#   C:\Users\Nbell\.act_omega_cloudflare_ids.json (or environment variables)
# Renders ephemeral wrangler configs in $env:TEMP, deploys, and deletes temp files.
#
# ROOT WRANGLER.TOML RESTRICTION:
#   Tracked wrangler.toml files (including repo-root wrangler.toml) store ONLY
#   <EXTERNAL_*> placeholders. Never run bare `npx wrangler deploy` from repo root;
#   always deploy via this script (`-ConfigScope edge_and_workflow|edge|workflow|root|all`).
# ==============================================================================
param(
    [switch]$DryRun,
    [switch]$SyncSecrets,
    [ValidateSet("edge_and_workflow", "edge", "workflow", "root", "all")]
    [string]$ConfigScope = "edge_and_workflow",
    [string]$ExternalConfigPath = "C:\Users\Nbell\.act_omega_cloudflare_ids.json",
    [string]$ReceiptOutPath = "",
    [string]$EdgeBaseUri = "https://act-omega-net.dev",
    [switch]$SkipDeploymentReceipt
)

$ErrorActionPreference = "Stop"
$edgeDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $edgeDir "..\..")).Path

$cfg = $null
if (Test-Path $ExternalConfigPath) {
    $cfg = Get-Content -Raw -Path $ExternalConfigPath | ConvertFrom-Json
}

$accountId   = if ($env:CLOUDFLARE_ACCOUNT_ID) { $env:CLOUDFLARE_ACCOUNT_ID } elseif ($cfg) { $cfg.account_id } else { "" }
$d1DbName    = if ($env:ACT_OMEGA_D1_DATABASE_NAME) { $env:ACT_OMEGA_D1_DATABASE_NAME } elseif ($cfg -and $cfg.d1_database_name) { $cfg.d1_database_name } else { "act_omega_d1_vault_v7322" }
$d1DbId      = if ($env:ACT_OMEGA_D1_DATABASE_ID) { $env:ACT_OMEGA_D1_DATABASE_ID } elseif ($cfg) { $cfg.d1_database_id } else { "" }
$hdId        = if ($env:ACT_OMEGA_HYPERDRIVE_ID) { $env:ACT_OMEGA_HYPERDRIVE_ID } elseif ($cfg) { $cfg.hyperdrive_id } else { "" }
$kvId        = if ($env:ACT_OMEGA_KV_ID) { $env:ACT_OMEGA_KV_ID } elseif ($cfg) { $cfg.kv_id } else { "" }
$vpcAnchorId   = if ($cfg -and $cfg.vpc_anchor_id)   { $cfg.vpc_anchor_id }   else { "" }
$vpcDenoId     = if ($cfg -and $cfg.vpc_deno_id)     { $cfg.vpc_deno_id }     else { "" }
$vpcP10Id      = if ($cfg -and $cfg.vpc_p10_id)      { $cfg.vpc_p10_id }      else { "" }
$vpcP8Id       = if ($cfg -and $cfg.vpc_p8_id)       { $cfg.vpc_p8_id }       else { "" }
$flagshipAppId = if ($env:ACT_OMEGA_FLAGSHIP_APP_ID) { $env:ACT_OMEGA_FLAGSHIP_APP_ID } elseif ($cfg -and $cfg.flagship_app_id) { $cfg.flagship_app_id } else { "" }

if (-not $accountId -or -not $d1DbId -or -not $hdId -or -not $kvId) {
    Write-Error "FAIL_CLOSED_MISSING_EXTERNAL_CLOUDFLARE_IDS: Required external IDs (account_id, d1_database_id, hyperdrive_id, kv_id) missing from $ExternalConfigPath and environment."
    exit 1
}

$prevCfToken = $env:CLOUDFLARE_API_TOKEN
$prevCfAccount = $env:CLOUDFLARE_ACCOUNT_ID

# Use OAuth token unless caller explicitly provided a valid non-expired token
Remove-Item Env:\CLOUDFLARE_API_TOKEN -ErrorAction SilentlyContinue
$env:CLOUDFLARE_ACCOUNT_ID = $accountId

function Invoke-WranglerCapture {
    param([string[]]$WranglerArgs)
    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    Push-Location $env:TEMP
    try {
        $lines = & npx --prefix $edgeDir wrangler @WranglerArgs 2>&1 | ForEach-Object { $_.ToString() }
        $code = $LASTEXITCODE
        return [pscustomobject]@{
            ExitCode = $code
            Output   = ($lines -join "`n")
        }
    } finally {
        Pop-Location
        $ErrorActionPreference = $prevEap
    }
}

function Remove-AnsiSequences {
    param([string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return "" }
    return [regex]::Replace($Text, '\x1b\[[0-9;]*[A-Za-z]', '')
}

function Get-RedactedDiagnosticSummary {
    param([string]$Text)
    $clean = Remove-AnsiSequences -Text $Text
    foreach ($secretId in @($accountId, $d1DbId, $hdId, $kvId, $vpcAnchorId, $vpcDenoId, $vpcP10Id, $vpcP8Id, $flagshipAppId)) {
        if (-not [string]::IsNullOrWhiteSpace($secretId)) {
            $clean = $clean.Replace([string]$secretId, "<REDACTED_CF_ID>")
        }
    }
    return $clean
}

function Get-ExternalOperatorKeyPlaintext {
    $raw = ""
    if (-not [string]::IsNullOrWhiteSpace($env:ACT_OMEGA_OPERATOR_KEY)) {
        $raw = $env:ACT_OMEGA_OPERATOR_KEY.Trim()
    } else {
        $candidates = @("C:\Users\Nbell\.act_omega_operator_vault_key")
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
        throw "FAIL_CLOSED_INVALID_OPERATOR_KEY: External operator key missing or < 24 chars."
    }
    return $raw
}

function Invoke-EdgeDirectJsonGet {
    param(
        [string]$Uri,
        [string]$OperatorKey = ""
    )
    Add-Type -AssemblyName System.Net.Http
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    $client = New-Object System.Net.Http.HttpClient
    $client.Timeout = [TimeSpan]::FromSeconds(20)
    try {
        $req = New-Object System.Net.Http.HttpRequestMessage([System.Net.Http.HttpMethod]::Get, $Uri)
        if (-not [string]::IsNullOrWhiteSpace($OperatorKey)) {
            $req.Headers.TryAddWithoutValidation("X-Sovereign-Operator-Key", $OperatorKey) | Out-Null
        }
        $resp = $client.SendAsync($req).GetAwaiter().GetResult()
        $statusCode = [int]$resp.StatusCode
        $bodyText = $resp.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        $parsed = $null
        try {
            $parsed = $bodyText | ConvertFrom-Json
        } catch {
            $parsed = $null
        }
        return [pscustomobject]@{
            StatusCode = $statusCode
            BodyText   = $bodyText
            Json       = $parsed
        }
    } finally {
        $client.Dispose()
    }
}

function Assert-NoSecretOrCfIdLeaks {
    param(
        [string]$PayloadText,
        [string]$OperatorKey
    )
    if (-not [string]::IsNullOrWhiteSpace($OperatorKey) -and $PayloadText.Contains($OperatorKey)) {
        throw "FAIL_CLOSED_SECRET_LEAK: Operator key detected in receipt payload."
    }
    foreach ($activeId in @($accountId, $d1DbId, $hdId, $kvId, $vpcAnchorId, $vpcDenoId, $vpcP10Id, $vpcP8Id, $flagshipAppId)) {
        if (-not [string]::IsNullOrWhiteSpace($activeId) -and $PayloadText.IndexOf([string]$activeId, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
            throw "FAIL_CLOSED_CF_ACTIVE_ID_LEAK: Active Cloudflare resource ID detected in receipt payload."
        }
    }
    if ($cfg -and $cfg.retired_id_prefixes) {
        foreach ($pfx in @($cfg.retired_id_prefixes)) {
            $pfxStr = [string]$pfx
            if ($pfxStr.Length -ge 8 -and $PayloadText.IndexOf($pfxStr, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
                throw "FAIL_CLOSED_CF_RETIRED_ID_LEAK: Retired Cloudflare ID prefix detected in receipt payload."
            }
        }
    }
}

function Render-WranglerTemplate([string]$srcPath, [string]$dstPath, [string]$baseDir) {
    $raw = Get-Content -Raw -Path $srcPath
    $rendered = $raw.Replace("<EXTERNAL_CF_ACCOUNT_ID>", $accountId).
                     Replace("<EXTERNAL_D1_DATABASE_NAME>", $d1DbName).
                     Replace("<EXTERNAL_D1_DATABASE_ID>", $d1DbId).
                     Replace("<EXTERNAL_HYPERDRIVE_ID>", $hdId).
                     Replace("<EXTERNAL_KV_ID>", $kvId).
                     Replace("<EXTERNAL_VPC_ANCHOR_ID>", $vpcAnchorId).
                     Replace("<EXTERNAL_VPC_DENO_ID>", $vpcDenoId).
                     Replace("<EXTERNAL_VPC_P10_ID>", $vpcP10Id).
                     Replace("<EXTERNAL_VPC_P8_ID>", $vpcP8Id).
                     Replace("<EXTERNAL_FLAGSHIP_APP_ID>", $flagshipAppId)
    # Rewrite relative main path to absolute path so temp config outside repo resolves cleanly
    $rendered = [regex]::Replace($rendered, 'main\s*=\s*"([^"]+)"', {
        param($m)
        $absMain = (Join-Path $baseDir $m.Groups[1].Value).Replace('\', '/')
        "main = `"$absMain`""
    })
    Set-Content -Path $dstPath -Value $rendered -Encoding UTF8
}

$tmpMain = Join-Path $env:TEMP "act_omega_wrangler_main_$([guid]::NewGuid().ToString('N')).toml"
$tmpWf   = Join-Path $env:TEMP "act_omega_wrangler_wf_$([guid]::NewGuid().ToString('N')).toml"
$tmpRoot = Join-Path $env:TEMP "act_omega_wrangler_root_$([guid]::NewGuid().ToString('N')).toml"

$deployWorkflow = ($ConfigScope -eq "workflow" -or $ConfigScope -eq "edge_and_workflow" -or $ConfigScope -eq "all")
$deployEdge     = ($ConfigScope -eq "edge"     -or $ConfigScope -eq "edge_and_workflow" -or $ConfigScope -eq "all")
$deployRoot     = ($ConfigScope -eq "root")
$validateRoot   = ($ConfigScope -eq "root" -or $ConfigScope -eq "all")

try {
    if ($deployEdge)     { Render-WranglerTemplate (Join-Path $edgeDir "wrangler.toml")          $tmpMain $edgeDir }
    if ($deployWorkflow) { Render-WranglerTemplate (Join-Path $edgeDir "wrangler.workflow.toml") $tmpWf   $edgeDir }
    if ($validateRoot)   { Render-WranglerTemplate (Join-Path $repoRoot "wrangler.toml")         $tmpRoot $repoRoot }

    if ($DryRun) {
        Write-Host "DRY_RUN_OK: Rendered ephemeral wrangler configs ($ConfigScope) without repo plaintext IDs." -ForegroundColor Green
        if ($deployWorkflow) {
            $wfDry = Invoke-WranglerCapture -WranglerArgs @("deploy", "--dry-run", "--config", $tmpWf)
            if ($wfDry.ExitCode -ne 0) {
                throw ("wrangler workflow dry-run failed ({0}): {1}" -f $wfDry.ExitCode, (Get-RedactedDiagnosticSummary -Text $wfDry.Output))
            }
            Write-Host "DRY_RUN_WORKFLOW_VALIDATED: sovereign-paid-workflow (exit=0)" -ForegroundColor Green
        }
        if ($deployEdge) {
            $edgeDry = Invoke-WranglerCapture -WranglerArgs @("deploy", "--dry-run", "--config", $tmpMain)
            if ($edgeDry.ExitCode -ne 0) {
                throw ("wrangler main dry-run failed ({0}): {1}" -f $edgeDry.ExitCode, (Get-RedactedDiagnosticSummary -Text $edgeDry.Output))
            }
            Write-Host "DRY_RUN_EDGE_VALIDATED: sovereign-loq15-vpc-shadow (exit=0)" -ForegroundColor Green
        }
        if ($validateRoot) {
            $rootDry = Invoke-WranglerCapture -WranglerArgs @("deploy", "--dry-run", "--config", $tmpRoot)
            if ($rootDry.ExitCode -ne 0) {
                throw ("wrangler root dry-run failed ({0}): {1}" -f $rootDry.ExitCode, (Get-RedactedDiagnosticSummary -Text $rootDry.Output))
            }
            Write-Host "DRY_RUN_ROOT_VALIDATED: root wrangler.toml (exit=0)" -ForegroundColor Green
        }
        exit 0
    }

    if ($SyncSecrets) {
        $opKeyVal = Get-ExternalOperatorKeyPlaintext
        if ($deployWorkflow) {
            $opKeyVal | npx --prefix $edgeDir wrangler secret put SOVEREIGN_OPERATOR_KEY --config $tmpWf | Out-Null
            if ($LASTEXITCODE -ne 0) { throw "Failed provisioning SOVEREIGN_OPERATOR_KEY on workflow worker" }
        }
        if ($deployEdge) {
            $opKeyVal | npx --prefix $edgeDir wrangler secret put SOVEREIGN_OPERATOR_KEY --config $tmpMain | Out-Null
            if ($LASTEXITCODE -ne 0) { throw "Failed provisioning SOVEREIGN_OPERATOR_KEY on edge worker" }
        }
    }

    if ($deployWorkflow) {
        Write-Host "Deploying sovereign-paid-workflow..." -ForegroundColor Cyan
        $wfDeploy = Invoke-WranglerCapture -WranglerArgs @("deploy", "--config", $tmpWf)
        if ($wfDeploy.ExitCode -ne 0) {
            throw ("wrangler workflow deploy failed ({0}): {1}" -f $wfDeploy.ExitCode, (Get-RedactedDiagnosticSummary -Text $wfDeploy.Output))
        }
        Write-Host "DEPLOY_WORKFLOW_OK: sovereign-paid-workflow" -ForegroundColor Green
    }

    if ($deployEdge) {
        Write-Host "Deploying sovereign-loq15-vpc-shadow (edge)..." -ForegroundColor Cyan
        $edgeDeploy = Invoke-WranglerCapture -WranglerArgs @("deploy", "--config", $tmpMain)
        if ($edgeDeploy.ExitCode -ne 0) {
            throw ("wrangler edge deploy failed ({0}): {1}" -f $edgeDeploy.ExitCode, (Get-RedactedDiagnosticSummary -Text $edgeDeploy.Output))
        }

        $cleanDeployOut = Remove-AnsiSequences -Text $edgeDeploy.Output
        $stdoutVersionId = ""
        $verMatch = [regex]::Match($cleanDeployOut, '(?im)Current Version ID:\s*([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})')
        if ($verMatch.Success) {
            $stdoutVersionId = $verMatch.Groups[1].Value.ToLowerInvariant()
        }

        $depListRes = Invoke-WranglerCapture -WranglerArgs @("deployments", "list", "--json", "--config", $tmpMain)
        if ($depListRes.ExitCode -ne 0) {
            throw ("wrangler deployments list failed ({0}): {1}" -f $depListRes.ExitCode, (Get-RedactedDiagnosticSummary -Text $depListRes.Output))
        }
        $cleanDepOut = Remove-AnsiSequences -Text $depListRes.Output
        $arrMatch = [regex]::Match($cleanDepOut, '(?m)^\s*\[')
        $jsonStart = if ($arrMatch.Success) { $arrMatch.Index } else { $cleanDepOut.IndexOf("[") }
        if ($jsonStart -lt 0) {
            throw "FAIL_CLOSED_DEPLOYMENTS_LIST_PARSE: Could not locate JSON array in wrangler deployments list output."
        }
        $parsedDep = $cleanDepOut.Substring($jsonStart) | ConvertFrom-Json
        $depEntries = New-Object System.Collections.Generic.List[object]
        if ($parsedDep -is [System.Array]) {
            foreach ($item in $parsedDep) {
                if ($null -ne $item -and -not [string]::IsNullOrWhiteSpace([string]$item.created_on)) {
                    $depEntries.Add($item)
                }
            }
        } elseif ($null -ne $parsedDep -and -not [string]::IsNullOrWhiteSpace([string]$parsedDep.created_on)) {
            $depEntries.Add($parsedDep)
        }
        if ($depEntries.Count -eq 0) {
            throw "FAIL_CLOSED_NO_DEPLOYMENTS_FOUND: wrangler deployments list returned empty array."
        }
        $latestDeploy = $depEntries | Sort-Object { [DateTimeOffset]::Parse([string]$_.created_on) } | Select-Object -Last 1
        $deploymentId = ([string]$latestDeploy.id).ToLowerInvariant()
        $deployedCreatedOn = [string]$latestDeploy.created_on
        $listVersionId = if ($latestDeploy.versions -and $latestDeploy.versions.Count -gt 0) { ([string]$latestDeploy.versions[0].version_id).ToLowerInvariant() } else { "" }

        if ($listVersionId -notmatch '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$') {
            throw "FAIL_CLOSED_INVALID_VERSION_ID: deployments list returned invalid version_id."
        }
        if (-not [string]::IsNullOrWhiteSpace($stdoutVersionId) -and $stdoutVersionId -ne $listVersionId) {
            throw "WORKER_VERSION_ID_MISMATCH: deploy stdout ($stdoutVersionId) != deployments list ($listVersionId)"
        }
        $workerVersionId = $listVersionId
        Write-Host ("DEPLOY_EDGE_OK: worker_version_id={0} deployment_id={1}" -f $workerVersionId, $deploymentId) -ForegroundColor Green

        if (-not $SkipDeploymentReceipt) {
            $targetReceiptPath = if ([string]::IsNullOrWhiteSpace($ReceiptOutPath)) {
                Join-Path $repoRoot "03_vault\receipts\cloudflare_edge_worker_deployment_receipt.json"
            } else {
                $ReceiptOutPath
            }
            $receiptParent = Split-Path -Parent $targetReceiptPath
            if (-not [string]::IsNullOrWhiteSpace($receiptParent) -and -not (Test-Path $receiptParent)) {
                New-Item -ItemType Directory -Path $receiptParent -Force | Out-Null
            }

            $opKey = Get-ExternalOperatorKeyPlaintext
            $baseUri = $EdgeBaseUri.TrimEnd('/')
            $manifestReqPath = "/api/v1/ota/pixel_manifest?edge_direct=1"
            $t284ReqPath     = "/api/v1/tools/t284?edge_direct=1"
            $healthReqPath   = "/api/v1/health?edge_direct=1"

            $manifestProbe = Invoke-EdgeDirectJsonGet -Uri "$baseUri$manifestReqPath" -OperatorKey $opKey
            if ($manifestProbe.StatusCode -ne 200 -or $null -eq $manifestProbe.Json) {
                throw ("FAIL_CLOSED_EDGE_MANIFEST_PROBE: HTTP {0} on {1}" -f $manifestProbe.StatusCode, $manifestReqPath)
            }
            $m = $manifestProbe.Json
            $mVersionCodeOk = ($null -ne $m.version_code) -and ($m.version_code -is [int] -or $m.version_code -is [long] -or $m.version_code -is [double]) -and ([int64]$m.version_code -gt 0)
            $mApkBytesOk = ($null -ne $m.apk_bytes) -and ($m.apk_bytes -is [int] -or $m.apk_bytes -is [long] -or $m.apk_bytes -is [double]) -and ([int64]$m.apk_bytes -gt 0)
            if ([string]$m.status -ne "MEASURED_PIXEL_OTA_MANIFEST_READY" -or
                [string]::IsNullOrWhiteSpace([string]$m.version_name) -or
                -not $mVersionCodeOk -or
                -not $mApkBytesOk -or
                ([string]$m.apk_sha256) -notmatch '^[0-9a-f]{64}$') {
                throw "FAIL_CLOSED_EDGE_MANIFEST_INVALID: pixel_manifest?edge_direct=1 returned unmeasured or invalid payload."
            }

            $t284Probe = Invoke-EdgeDirectJsonGet -Uri "$baseUri$t284ReqPath" -OperatorKey $opKey
            if ($t284Probe.StatusCode -ne 200 -or $null -eq $t284Probe.Json) {
                throw ("FAIL_CLOSED_EDGE_T284_PROBE: HTTP {0} on {1}" -f $t284Probe.StatusCode, $t284ReqPath)
            }
            $t = $t284Probe.Json
            if ([string]$t.status -ne "MEASURED_PIXEL_OTA_MANIFEST_READY" -or
                [int]$t.version_code -ne [int]$m.version_code -or
                [string]$t.version_name -ne [string]$m.version_name -or
                [int64]$t.apk_bytes -ne [int64]$m.apk_bytes -or
                ([string]$t.apk_sha256).ToLowerInvariant() -ne ([string]$m.apk_sha256).ToLowerInvariant()) {
                throw "FAIL_CLOSED_EDGE_T284_PARITY: t284?edge_direct=1 did not match pixel_manifest?edge_direct=1."
            }

            $healthProbe = Invoke-EdgeDirectJsonGet -Uri "$baseUri$healthReqPath"
            if ($healthProbe.StatusCode -ne 200 -or $null -eq $healthProbe.Json) {
                throw ("FAIL_CLOSED_EDGE_HEALTH_PROBE: HTTP {0} on {1}" -f $healthProbe.StatusCode, $healthReqPath)
            }
            $h = $healthProbe.Json
            if ([string]::IsNullOrWhiteSpace([string]$h.version) -or [string]::IsNullOrWhiteSpace([string]$h.status)) {
                throw "FAIL_CLOSED_EDGE_HEALTH_INVALID: health?edge_direct=1 returned empty version or status."
            }

            $receiptObj = [ordered]@{
                schema                = "act_omega.cloudflare_edge_worker_deployment_receipt.v1"
                worker_name           = "sovereign-loq15-vpc-shadow"
                config_scope          = $ConfigScope
                worker_version_id     = $workerVersionId
                deployment_id         = $deploymentId
                deployment_created_on = $deployedCreatedOn
                edge_base_uri         = $baseUri
                version_code          = [int]$m.version_code
                version_name          = [string]$m.version_name
                apk_bytes             = [int64]$m.apk_bytes
                apk_sha256            = ([string]$m.apk_sha256).ToLowerInvariant()
                timestamp_utc         = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
                request_paths         = @($manifestReqPath, $t284ReqPath, $healthReqPath)
                probes                = [ordered]@{
                    pixel_manifest = [ordered]@{
                        http_status  = $manifestProbe.StatusCode
                        request_path = $manifestReqPath
                        status       = [string]$m.status
                        version_name = [string]$m.version_name
                        version_code = [int]$m.version_code
                        apk_bytes    = [int64]$m.apk_bytes
                        apk_sha256   = ([string]$m.apk_sha256).ToLowerInvariant()
                        timestamp_ms = [int64]$m.timestamp_ms
                    }
                    t284 = [ordered]@{
                        http_status  = $t284Probe.StatusCode
                        request_path = $t284ReqPath
                        status       = [string]$t.status
                        version_name = [string]$t.version_name
                        version_code = [int]$t.version_code
                        apk_bytes    = [int64]$t.apk_bytes
                        apk_sha256   = ([string]$t.apk_sha256).ToLowerInvariant()
                        timestamp_ms = [int64]$t.timestamp_ms
                    }
                    health = [ordered]@{
                        http_status        = $healthProbe.StatusCode
                        request_path       = $healthReqPath
                        status             = [string]$h.status
                        version            = [string]$h.version
                        chain_milestone    = [string]$h.chain_milestone
                        lean4_theorems_qed = [string]$h.lean4_theorems_qed
                        tools_total        = if ($null -ne $h.tools_total) { [int]$h.tools_total } else { $null }
                    }
                }
            }

            $jsonRaw = $receiptObj | ConvertTo-Json -Depth 8
            $jsonLf = ($jsonRaw.Replace("`r`n", "`n").Replace("`r", "`n")).TrimEnd("`n") + "`n"
            Assert-NoSecretOrCfIdLeaks -PayloadText $jsonLf -OperatorKey $opKey
            $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
            [System.IO.File]::WriteAllText($targetReceiptPath, $jsonLf, $utf8NoBom)
            Write-Host ("DEPLOYMENT_RECEIPT_WRITTEN: {0} (version_id={1}, version_code={2})" -f $targetReceiptPath, $workerVersionId, [int]$m.version_code) -ForegroundColor Green
        }
    }

    if ($deployRoot) {
        Write-Host "Deploying sovereign-loq15-vpc-shadow (root wrangler.toml)..." -ForegroundColor Cyan
        $rootDeploy = Invoke-WranglerCapture -WranglerArgs @("deploy", "--config", $tmpRoot)
        if ($rootDeploy.ExitCode -ne 0) {
            throw ("wrangler root deploy failed ({0}): {1}" -f $rootDeploy.ExitCode, (Get-RedactedDiagnosticSummary -Text $rootDeploy.Output))
        }
        Write-Host "DEPLOY_ROOT_OK: sovereign-loq15-vpc-shadow" -ForegroundColor Green
    } elseif ($ConfigScope -eq "all") {
        Write-Host "Validating root wrangler.toml dry-run (preserving edge Hyperdrive/VPC bindings)..." -ForegroundColor Cyan
        $rootDryAll = Invoke-WranglerCapture -WranglerArgs @("deploy", "--dry-run", "--config", $tmpRoot)
        if ($rootDryAll.ExitCode -ne 0) {
            throw ("wrangler root dry-run failed ({0}): {1}" -f $rootDryAll.ExitCode, (Get-RedactedDiagnosticSummary -Text $rootDryAll.Output))
        }
        Write-Host "DRY_RUN_ROOT_VALIDATED: root wrangler.toml (exit=0)" -ForegroundColor Green
    }

    Write-Host "CLOUDFLARE_EDGE_DEPLOY_OK" -ForegroundColor Green
} finally {
    Remove-Item -Path $tmpMain, $tmpWf, $tmpRoot -Force -ErrorAction SilentlyContinue
    if ($null -ne $prevCfToken) { $env:CLOUDFLARE_API_TOKEN = $prevCfToken } else { Remove-Item Env:\CLOUDFLARE_API_TOKEN -ErrorAction SilentlyContinue }
    if ($null -ne $prevCfAccount) { $env:CLOUDFLARE_ACCOUNT_ID = $prevCfAccount } else { Remove-Item Env:\CLOUDFLARE_ACCOUNT_ID -ErrorAction SilentlyContinue }
}
