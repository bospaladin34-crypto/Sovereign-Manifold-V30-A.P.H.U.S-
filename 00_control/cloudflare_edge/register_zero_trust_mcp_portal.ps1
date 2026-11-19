# ==============================================================================
# ACT-Omega Net — Cloudflare Zero Trust MCP Portal & Remote 5GB D1 Helper
# Account ID: <EXTERNAL_CF_ACCOUNT_ID> | Domain: https://act-omega-net.dev
# ==============================================================================
$ErrorActionPreference = "Continue"
$EdgeDir = "C:\sovereign_manifold_v31\00_control\cloudflare_edge"
$ExternalConfigPath = "C:\Users\Nbell\.act_omega_cloudflare_ids.json"
$cfg = if (Test-Path $ExternalConfigPath) { Get-Content -Raw -Path $ExternalConfigPath | ConvertFrom-Json } else { $null }
$D1DatabaseName = if ($env:ACT_OMEGA_D1_DATABASE_NAME) { $env:ACT_OMEGA_D1_DATABASE_NAME } elseif ($cfg -and $cfg.d1_database_name) { $cfg.d1_database_name } else { "act_omega_d1_vault_v7322" }
Set-Location -Path $EdgeDir
Write-Host "=== [1/2] Provisioning Remote 5GB Cloudflare D1 Database ($D1DatabaseName) ===" -ForegroundColor Cyan
if ($cfg) {
    $env:CLOUDFLARE_ACCOUNT_ID = $cfg.account_id
    $tmpCfg = Join-Path $env:TEMP "act_omega_mcp_d1_$([guid]::NewGuid().ToString('N')).toml"
    try {
        $rawToml = Get-Content -Raw -Path (Join-Path $EdgeDir "wrangler.toml")
        $rendered = $rawToml.Replace("<EXTERNAL_CF_ACCOUNT_ID>", $cfg.account_id).
                             Replace("<EXTERNAL_D1_DATABASE_NAME>", $D1DatabaseName).
                             Replace("<EXTERNAL_D1_DATABASE_ID>", $cfg.d1_database_id).
                             Replace("<EXTERNAL_HYPERDRIVE_ID>", $cfg.hyperdrive_id).
                             Replace("<EXTERNAL_KV_ID>", $cfg.kv_id).
                             Replace("<EXTERNAL_VPC_ANCHOR_ID>", $cfg.vpc_anchor_id).
                             Replace("<EXTERNAL_VPC_DENO_ID>", $cfg.vpc_deno_id).
                             Replace("<EXTERNAL_VPC_P10_ID>", $cfg.vpc_p10_id).
                             Replace("<EXTERNAL_VPC_P8_ID>", $cfg.vpc_p8_id)
        Set-Content -Path $tmpCfg -Value $rendered -Encoding UTF8
        npx --yes wrangler d1 execute $D1DatabaseName --remote --config $tmpCfg --file=schema_d1_v3700.sql
        npx --yes wrangler d1 execute $D1DatabaseName --remote --config $tmpCfg --file=seed_d1_v3710.sql
    } finally {
        Remove-Item -Path $tmpCfg -Force -ErrorAction SilentlyContinue
    }
}
Write-Host "=== [2/2] Cloudflare Zero Trust MCP Portal Endpoint Ready ===" -ForegroundColor Green
Write-Host "  MCP Server URL : https://act-omega-net.dev/mcp" -ForegroundColor Green
Write-Host "  Local MCP URL  : http://127.0.0.1:8097/mcp" -ForegroundColor Green
Write-Host "  OpenAI Base URL: http://127.0.0.1:8097/v1 (or https://act-omega-net.dev/v1)" -ForegroundColor Green
Write-Host "  Model ID       : sovereign-harmonic-v3710" -ForegroundColor Green
