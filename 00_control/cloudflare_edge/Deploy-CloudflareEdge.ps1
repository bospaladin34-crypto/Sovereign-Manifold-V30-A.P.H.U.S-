# ==============================================================================
# ACT-Omega Net v73.2.1 — Externalized Cloudflare Workers & Workflow Deployer (S6)
# Reads non-committed cloud resource identifiers exclusively from:
#   C:\Users\Nbell\.act_omega_cloudflare_ids.json (or environment variables)
# Renders ephemeral wrangler configs in $env:TEMP, deploys, and deletes temp files.
# ==============================================================================
param(
    [switch]$DryRun,
    [switch]$SyncSecrets,
    [string]$ExternalConfigPath = "C:\Users\Nbell\.act_omega_cloudflare_ids.json"
)

$ErrorActionPreference = "Stop"
$edgeDir = Split-Path -Parent $MyInvocation.MyCommand.Path

$cfg = $null
if (Test-Path $ExternalConfigPath) {
    $cfg = Get-Content -Raw -Path $ExternalConfigPath | ConvertFrom-Json
}

$accountId   = if ($env:CLOUDFLARE_ACCOUNT_ID) { $env:CLOUDFLARE_ACCOUNT_ID } elseif ($cfg) { $cfg.account_id } else { "" }
$d1DbId      = if ($env:ACT_OMEGA_D1_DATABASE_ID) { $env:ACT_OMEGA_D1_DATABASE_ID } elseif ($cfg) { $cfg.d1_database_id } else { "" }
$hdId        = if ($env:ACT_OMEGA_HYPERDRIVE_ID) { $env:ACT_OMEGA_HYPERDRIVE_ID } elseif ($cfg) { $cfg.hyperdrive_id } else { "" }
$kvId        = if ($env:ACT_OMEGA_KV_ID) { $env:ACT_OMEGA_KV_ID } elseif ($cfg) { $cfg.kv_id } else { "" }
$vpcAnchorId = if ($cfg -and $cfg.vpc_anchor_id) { $cfg.vpc_anchor_id } else { "" }
$vpcDenoId   = if ($cfg -and $cfg.vpc_deno_id)   { $cfg.vpc_deno_id }   else { "" }
$vpcP10Id    = if ($cfg -and $cfg.vpc_p10_id)    { $cfg.vpc_p10_id }    else { "" }
$vpcP8Id     = if ($cfg -and $cfg.vpc_p8_id)     { $cfg.vpc_p8_id }     else { "" }

if (-not $accountId -or -not $d1DbId -or -not $hdId -or -not $kvId) {
    Write-Error "FAIL_CLOSED_MISSING_EXTERNAL_CLOUDFLARE_IDS: Required external IDs (account_id, d1_database_id, hyperdrive_id, kv_id) missing from $ExternalConfigPath and environment."
    exit 1
}

function Render-WranglerTemplate([string]$srcPath, [string]$dstPath) {
    $raw = Get-Content -Raw -Path $srcPath
    $rendered = $raw.Replace("<EXTERNAL_CF_ACCOUNT_ID>", $accountId).
                     Replace("<EXTERNAL_D1_DATABASE_ID>", $d1DbId).
                     Replace("<EXTERNAL_HYPERDRIVE_ID>", $hdId).
                     Replace("<EXTERNAL_KV_ID>", $kvId).
                     Replace("<EXTERNAL_VPC_ANCHOR_ID>", $vpcAnchorId).
                     Replace("<EXTERNAL_VPC_DENO_ID>", $vpcDenoId).
                     Replace("<EXTERNAL_VPC_P10_ID>", $vpcP10Id).
                     Replace("<EXTERNAL_VPC_P8_ID>", $vpcP8Id)
    # Rewrite relative main path to absolute path so temp config outside repo resolves cleanly
    $rendered = [regex]::Replace($rendered, 'main\s*=\s*"([^"]+)"', {
        param($m)
        $absMain = (Join-Path $edgeDir $m.Groups[1].Value).Replace('\', '/')
        "main = `"$absMain`""
    })
    Set-Content -Path $dstPath -Value $rendered -Encoding UTF8
}

$tmpMain = Join-Path $env:TEMP "act_omega_wrangler_main_$([guid]::NewGuid().ToString('N')).toml"
$tmpWf   = Join-Path $env:TEMP "act_omega_wrangler_wf_$([guid]::NewGuid().ToString('N')).toml"

try {
    Render-WranglerTemplate (Join-Path $edgeDir "wrangler.toml") $tmpMain
    Render-WranglerTemplate (Join-Path $edgeDir "wrangler.workflow.toml") $tmpWf

    if ($DryRun) {
        Write-Host "DRY_RUN_OK: Rendered ephemeral wrangler configs without repo plaintext IDs." -ForegroundColor Green
        npx --prefix $edgeDir wrangler deploy --dry-run --config $tmpWf
        if ($LASTEXITCODE -ne 0) { throw "wrangler workflow dry-run failed ($LASTEXITCODE)" }
        npx --prefix $edgeDir wrangler deploy --dry-run --config $tmpMain
        if ($LASTEXITCODE -ne 0) { throw "wrangler main dry-run failed ($LASTEXITCODE)" }
        exit 0
    }

    if ($SyncSecrets) {
        $opKeyFile = "C:\Users\Nbell\.act_omega_operator_vault_key"
        if (-not (Test-Path $opKeyFile)) {
            throw "FAIL_CLOSED_MISSING_OPERATOR_KEY: $opKeyFile not found."
        }
        $opKeyVal = (Get-Content -Raw -Path $opKeyFile).Trim()
        if ($opKeyVal.Length -lt 24) {
            throw "FAIL_CLOSED_INVALID_OPERATOR_KEY_LENGTH"
        }
        $opKeyVal | npx --prefix $edgeDir wrangler secret put SOVEREIGN_OPERATOR_KEY --config $tmpWf
        if ($LASTEXITCODE -ne 0) { throw "Failed provisioning SOVEREIGN_OPERATOR_KEY on workflow worker" }
    }

    Write-Host "Deploying sovereign-paid-workflow..." -ForegroundColor Cyan
    npx --prefix $edgeDir wrangler deploy --config $tmpWf
    if ($LASTEXITCODE -ne 0) { throw "wrangler workflow deploy failed ($LASTEXITCODE)" }

    Write-Host "Deploying sovereign-loq15-vpc-shadow..." -ForegroundColor Cyan
    npx --prefix $edgeDir wrangler deploy --config $tmpMain
    if ($LASTEXITCODE -ne 0) { throw "wrangler main deploy failed ($LASTEXITCODE)" }

    Write-Host "CLOUDFLARE_EDGE_DEPLOY_OK" -ForegroundColor Green
} finally {
    Remove-Item -Path $tmpMain, $tmpWf -Force -ErrorAction SilentlyContinue
}
