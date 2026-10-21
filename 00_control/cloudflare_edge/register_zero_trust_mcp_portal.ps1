# ==============================================================================
# ACT-Omega Net v37.1.0 — Cloudflare Zero Trust MCP Portal & Remote 5GB D1 Helper
# Account ID: a37cf8ab07e7c5f886c302be3f098744 | Domain: https://act-omega-net.dev
# ==============================================================================
$ErrorActionPreference = "Continue"
$EdgeDir = "C:\sovereign_manifold_v31\00_control\cloudflare_edge"
Set-Location -Path $EdgeDir
Write-Host "=== [1/2] Provisioning Remote 5GB Cloudflare D1 Database (act_omega_d1_vault) ===" -ForegroundColor Cyan
cmd.exe /c "npx --yes wrangler d1 create act_omega_d1_vault"
cmd.exe /c "npx --yes wrangler d1 execute act_omega_d1_vault --remote --file=schema_d1_v3700.sql"
cmd.exe /c "npx --yes wrangler d1 execute act_omega_d1_vault --remote --file=seed_d1_v3710.sql"
Write-Host "=== [2/2] Cloudflare Zero Trust MCP Portal Endpoint Ready ===" -ForegroundColor Green
Write-Host "  MCP Server URL : https://act-omega-net.dev/mcp" -ForegroundColor Green
Write-Host "  Local MCP URL  : http://127.0.0.1:8097/mcp" -ForegroundColor Green
Write-Host "  OpenAI Base URL: http://127.0.0.1:8097/v1 (or https://act-omega-net.dev/v1)" -ForegroundColor Green
Write-Host "  Model ID       : sovereign-harmonic-v3710" -ForegroundColor Green
