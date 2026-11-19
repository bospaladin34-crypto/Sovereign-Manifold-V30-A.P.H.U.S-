# =============================================================================
# 00_control/cloudflare_edge/d1_live_measured_sync_v4100.ps1
# Computes real SHA-256 digests and executes wrangler d1 execute --remote
# across all 10 tables in <EXTERNAL_D1_DATABASE_NAME> (<EXTERNAL_D1_DATABASE_ID>)
# =============================================================================
$ErrorActionPreference = 'Continue'
$Root = 'C:\sovereign_manifold_v31'
Set-Location $Root

$ExternalConfigPath = 'C:\Users\Nbell\.act_omega_cloudflare_ids.json'
$cfg = if (Test-Path $ExternalConfigPath) { Get-Content -Raw -Path $ExternalConfigPath | ConvertFrom-Json } else { $null }
$D1DatabaseName = if ($env:ACT_OMEGA_D1_DATABASE_NAME) { $env:ACT_OMEGA_D1_DATABASE_NAME } elseif ($cfg -and $cfg.d1_database_name) { $cfg.d1_database_name } else { 'act_omega_d1_vault_v7322' }

$E8zFile = Join-Path $Root '00_control\weights\sovereign_harmonic_iv_v4000.e8z'
$NpageFile = Join-Path $Root '00_control\weights\neurons_v4000.npage'
$ExpNpageFile = Join-Path $Root '00_control\weights\neurons_v4300_expansion.npage'
$LeanFile = Join-Path $Root '01_l0_rust\lean4\SovereignManifoldTheorems.lean'

$E8zSha256 = (Get-FileHash -Path $E8zFile -Algorithm SHA256).Hash.ToLower()
$NpageSha256 = (Get-FileHash -Path $NpageFile -Algorithm SHA256).Hash.ToLower()
$ExpNpageSha256 = (Get-FileHash -Path $ExpNpageFile -Algorithm SHA256).Hash.ToLower()
$LeanSha256 = (Get-FileHash -Path $LeanFile -Algorithm SHA256).Hash.ToLower()

Write-Output "Measured SHA-256 (.e8z):           $E8zSha256"
Write-Output "Measured SHA-256 (core .npage):    $NpageSha256"
Write-Output "Measured SHA-256 (exp .npage):     $ExpNpageSha256"
Write-Output "Measured SHA-256 (Lean 4 QED):     $LeanSha256"

$SqlPath = Join-Path $Root '00_control\cloudflare_edge\sync_d1_v4300_all8tables.sql'
$NpxCmd = Get-Command npx.cmd -ErrorAction SilentlyContinue
if ($NpxCmd -and $cfg) {
    $tmpCfg = Join-Path $env:TEMP "act_omega_d1_sync_$([guid]::NewGuid().ToString('N')).toml"
    try {
        $rawToml = Get-Content -Raw -Path (Join-Path $Root '00_control\cloudflare_edge\wrangler.toml')
        $rendered = $rawToml.Replace('<EXTERNAL_CF_ACCOUNT_ID>', $cfg.account_id).
                             Replace('<EXTERNAL_D1_DATABASE_NAME>', $D1DatabaseName).
                             Replace('<EXTERNAL_D1_DATABASE_ID>', $cfg.d1_database_id).
                             Replace('<EXTERNAL_HYPERDRIVE_ID>', $cfg.hyperdrive_id).
                             Replace('<EXTERNAL_KV_ID>', $cfg.kv_id).
                             Replace('<EXTERNAL_VPC_ANCHOR_ID>', $cfg.vpc_anchor_id).
                             Replace('<EXTERNAL_VPC_DENO_ID>', $cfg.vpc_deno_id).
                             Replace('<EXTERNAL_VPC_P10_ID>', $cfg.vpc_p10_id).
                             Replace('<EXTERNAL_VPC_P8_ID>', $cfg.vpc_p8_id)
        Set-Content -Path $tmpCfg -Value $rendered -Encoding UTF8
        & npx.cmd --prefix (Join-Path $Root '00_control\cloudflare_edge') wrangler d1 execute $D1DatabaseName --remote --config=$tmpCfg --file=$SqlPath --yes
    } finally {
        Remove-Item -Path $tmpCfg -Force -ErrorAction SilentlyContinue
    }
}
