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
    [string]$ExternalConfigPath = "C:\Users\Nbell\.act_omega_cloudflare_ids.json"
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
$vpcAnchorId = if ($cfg -and $cfg.vpc_anchor_id) { $cfg.vpc_anchor_id } else { "" }
$vpcDenoId   = if ($cfg -and $cfg.vpc_deno_id)   { $cfg.vpc_deno_id }   else { "" }
$vpcP10Id    = if ($cfg -and $cfg.vpc_p10_id)    { $cfg.vpc_p10_id }    else { "" }
$vpcP8Id     = if ($cfg -and $cfg.vpc_p8_id)     { $cfg.vpc_p8_id }     else { "" }

if (-not $accountId -or -not $d1DbId -or -not $hdId -or -not $kvId) {
    Write-Error "FAIL_CLOSED_MISSING_EXTERNAL_CLOUDFLARE_IDS: Required external IDs (account_id, d1_database_id, hyperdrive_id, kv_id) missing from $ExternalConfigPath and environment."
    exit 1
}

# Use OAuth token unless caller explicitly provided a valid non-expired token
Remove-Item Env:\CLOUDFLARE_API_TOKEN -ErrorAction SilentlyContinue

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
                     Replace("<EXTERNAL_VPC_P8_ID>", $vpcP8Id)
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
            npx --prefix $edgeDir wrangler deploy --dry-run --config $tmpWf
            if ($LASTEXITCODE -ne 0) { throw "wrangler workflow dry-run failed ($LASTEXITCODE)" }
        }
        if ($deployEdge) {
            npx --prefix $edgeDir wrangler deploy --dry-run --config $tmpMain
            if ($LASTEXITCODE -ne 0) { throw "wrangler main dry-run failed ($LASTEXITCODE)" }
        }
        if ($validateRoot) {
            npx --prefix $edgeDir wrangler deploy --dry-run --config $tmpRoot
            if ($LASTEXITCODE -ne 0) { throw "wrangler root dry-run failed ($LASTEXITCODE)" }
        }
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
        if ($deployWorkflow) {
            $opKeyVal | npx --prefix $edgeDir wrangler secret put SOVEREIGN_OPERATOR_KEY --config $tmpWf
            if ($LASTEXITCODE -ne 0) { throw "Failed provisioning SOVEREIGN_OPERATOR_KEY on workflow worker" }
        }
        if ($deployEdge) {
            $opKeyVal | npx --prefix $edgeDir wrangler secret put SOVEREIGN_OPERATOR_KEY --config $tmpMain
            if ($LASTEXITCODE -ne 0) { throw "Failed provisioning SOVEREIGN_OPERATOR_KEY on edge worker" }
        }
    }

    if ($deployWorkflow) {
        Write-Host "Deploying sovereign-paid-workflow..." -ForegroundColor Cyan
        npx --prefix $edgeDir wrangler deploy --config $tmpWf
        if ($LASTEXITCODE -ne 0) { throw "wrangler workflow deploy failed ($LASTEXITCODE)" }
    }

    if ($deployEdge) {
        Write-Host "Deploying sovereign-loq15-vpc-shadow (edge)..." -ForegroundColor Cyan
        npx --prefix $edgeDir wrangler deploy --config $tmpMain
        if ($LASTEXITCODE -ne 0) { throw "wrangler edge deploy failed ($LASTEXITCODE)" }
    }

    if ($deployRoot) {
        Write-Host "Deploying sovereign-loq15-vpc-shadow (root wrangler.toml)..." -ForegroundColor Cyan
        npx --prefix $edgeDir wrangler deploy --config $tmpRoot
        if ($LASTEXITCODE -ne 0) { throw "wrangler root deploy failed ($LASTEXITCODE)" }
    } elseif ($ConfigScope -eq "all") {
        Write-Host "Validating root wrangler.toml dry-run (preserving edge Hyperdrive/VPC bindings)..." -ForegroundColor Cyan
        npx --prefix $edgeDir wrangler deploy --dry-run --config $tmpRoot
        if ($LASTEXITCODE -ne 0) { throw "wrangler root dry-run failed ($LASTEXITCODE)" }
    }

    Write-Host "CLOUDFLARE_EDGE_DEPLOY_OK" -ForegroundColor Green
} finally {
    Remove-Item -Path $tmpMain, $tmpWf, $tmpRoot -Force -ErrorAction SilentlyContinue
}
