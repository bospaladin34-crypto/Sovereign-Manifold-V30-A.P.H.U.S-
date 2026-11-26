# ==============================================================================
# ACT-Omega Net v74.0.0 — Cloudflare Zero Trust MCP Portal, AI Gateway & D1 Helper
# Account ID: <EXTERNAL_CF_ACCOUNT_ID> | Domain: https://act-omega-net.dev
# ==============================================================================
$ErrorActionPreference = "Continue"
$EdgeDir = "C:\sovereign_manifold_v31\00_control\cloudflare_edge"
$ExternalConfigPath = "C:\Users\Nbell\.act_omega_cloudflare_ids.json"
$cfg = if (Test-Path $ExternalConfigPath) { Get-Content -Raw -Path $ExternalConfigPath | ConvertFrom-Json } else { $null }
$D1DatabaseName = if ($env:ACT_OMEGA_D1_DATABASE_NAME) { $env:ACT_OMEGA_D1_DATABASE_NAME } elseif ($cfg -and $cfg.d1_database_name) { $cfg.d1_database_name } else { "act_omega_d1_vault_v7322" }
$FlagshipAppId  = if ($env:ACT_OMEGA_FLAGSHIP_APP_ID)  { $env:ACT_OMEGA_FLAGSHIP_APP_ID }  elseif ($cfg -and $cfg.flagship_app_id)  { $cfg.flagship_app_id }  else { "" }
Set-Location -Path $EdgeDir
Write-Host "=== [1/3] Provisioning Remote 5GB Cloudflare D1 Database ($D1DatabaseName) ===" -ForegroundColor Cyan
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
                             Replace("<EXTERNAL_VPC_P8_ID>", $cfg.vpc_p8_id).
                             Replace("<EXTERNAL_FLAGSHIP_APP_ID>", $FlagshipAppId)
        Set-Content -Path $tmpCfg -Value $rendered -Encoding UTF8
        npx --yes wrangler d1 execute $D1DatabaseName --remote --config $tmpCfg --file=schema_d1_v3700.sql
        npx --yes wrangler d1 execute $D1DatabaseName --remote --config $tmpCfg --file=seed_d1_v3710.sql
    } finally {
        Remove-Item -Path $tmpCfg -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "=== [2/3] Optional API Provisioning for AI Gateway & Zero Trust MCP Portal ===" -ForegroundColor Cyan
if ($cfg -and -not [string]::IsNullOrWhiteSpace($env:CLOUDFLARE_API_TOKEN)) {
    $apiHeaders = @{
        "Authorization" = "Bearer $($env:CLOUDFLARE_API_TOKEN.Trim())"
        "Content-Type"  = "application/json"
    }
    try {
        $gwPayload = @{
            id                      = "act-omega-ai-gateway"
            collect_logs            = $true
            cache_invalidate_on_update = $true
            cache_ttl               = 3600
            rate_limiting_interval  = 60
            rate_limiting_limit     = 60
            rate_limiting_technique = "sliding"
        } | ConvertTo-Json -Compress
        $null = Invoke-RestMethod -Method Post -Uri "https://api.cloudflare.com/client/v4/accounts/$($cfg.account_id)/ai-gateway/gateways" -Headers $apiHeaders -Body $gwPayload
        Write-Host "  [AI Gateway] Provisioned 'act-omega-ai-gateway' (3600s cache TTL, 60 req/min sliding limit)." -ForegroundColor Green
    } catch {
        Write-Host "  [AI Gateway] Notice: $($_.Exception.Message) (already exists or requires AI Gateway:Edit API token)." -ForegroundColor Yellow
    }
    try {
        $mcpSrvPayload = @{
            id          = "act-omega-sovereign-mcp"
            name        = "ACT-Omega Sovereign Manifold MCP (70 Tools)"
            hostname    = "https://mcp.act-omega-net.dev/mcp"
            auth_type   = "unauthenticated"
            description = "ACT-Omega Net v74.0.0 SH4Z v7400 | CHAIN 418 | 70 Strict-Schema Gemini JSON-RPC 2.0 MCP Tools (Operator-Key Gated tools/call)"
        } | ConvertTo-Json -Compress
        $null = Invoke-RestMethod -Method Post -Uri "https://api.cloudflare.com/client/v4/accounts/$($cfg.account_id)/access/ai-controls/mcp/servers" -Headers $apiHeaders -Body $mcpSrvPayload
        $mcpPortalPayload = @{
            id          = "act-omega-mcp-portal"
            name        = "ACT-Omega Sovereign MCP Portal"
            hostname    = "mcp-portal.act-omega-net.dev"
            description = "Unified Zero Trust AI Controls MCP Portal for ACT-Omega Net v74.0.0"
            servers     = @(@{ server_id = "act-omega-sovereign-mcp"; default_disabled = $false })
        } | ConvertTo-Json -Compress
        $null = Invoke-RestMethod -Method Post -Uri "https://api.cloudflare.com/client/v4/accounts/$($cfg.account_id)/access/ai-controls/mcp/portals" -Headers $apiHeaders -Body $mcpPortalPayload
        Write-Host "  [Zero Trust MCP Portal] Registered 'act-omega-sovereign-mcp' & 'act-omega-mcp-portal'." -ForegroundColor Green
    } catch {
        Write-Host "  [Zero Trust MCP Portal] Notice: $($_.Exception.Message) (already registered or requires Zero Trust:Edit API token)." -ForegroundColor Yellow
    }
} else {
    Write-Host "  [Info] Set CLOUDFLARE_API_TOKEN (with AI Gateway:Edit + Zero Trust:Edit) to auto-create dashboard objects via REST, or create 'act-omega-ai-gateway' & link https://mcp.act-omega-net.dev/mcp in Dashboard." -ForegroundColor Gray
}

Write-Host "=== [3/3] Cloudflare Zero Trust MCP Portal & AI Gateway Endpoints Ready ===" -ForegroundColor Green
Write-Host "  Dedicated MCP URL : https://mcp.act-omega-net.dev/mcp (70 Gemini MCP Tools)" -ForegroundColor Green
Write-Host "  Shadow MCP URL    : https://act-omega-net.dev/mcp" -ForegroundColor Green
Write-Host "  Local MCP URL     : http://127.0.0.1:8097/mcp" -ForegroundColor Green
Write-Host "  AI Gateway ID     : act-omega-ai-gateway (auto-routed by /api/v1/ai/embed)" -ForegroundColor Green
Write-Host "  Flagship App      : act-omega-sovereign-flags (4 runtime boolean flags)" -ForegroundColor Green
Write-Host "  OpenAI Base URL   : http://127.0.0.1:8097/v1 (or https://act-omega-net.dev/v1)" -ForegroundColor Green
Write-Host "  Model ID          : sovereign-harmonic-v7400" -ForegroundColor Green
