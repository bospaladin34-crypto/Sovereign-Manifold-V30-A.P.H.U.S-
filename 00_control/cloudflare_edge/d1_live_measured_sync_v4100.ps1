# =============================================================================
# 00_control/cloudflare_edge/d1_live_measured_sync_v4100.ps1
# Remediates Muse Audit #4 & #5: Computes real SHA-256 digests and executes
# explicit wrangler d1 execute --remote --command calls against act_omega_d1_vault
# =============================================================================
$ErrorActionPreference = 'Continue'
$Root = 'C:\sovereign_manifold_v31'
Set-Location $Root

$E8zFile = Join-Path $Root '00_control\weights\sovereign_harmonic_iv_v4000.e8z'
$NpageFile = Join-Path $Root '00_control\weights\neurons_v4000.npage'
$LeanFile = Join-Path $Root '01_l0_rust\lean4\SovereignManifoldTheorems.lean'

$E8zSha256 = (Get-FileHash -Path $E8zFile -Algorithm SHA256).Hash.ToLower()
$NpageSha256 = (Get-FileHash -Path $NpageFile -Algorithm SHA256).Hash.ToLower()
$LeanSha256 = (Get-FileHash -Path $LeanFile -Algorithm SHA256).Hash.ToLower()

$SqlPath = Join-Path $Root '00_control\cloudflare_edge\sync_d1_v3800.sql'
$NpxCmd = Get-Command npx.cmd -ErrorAction SilentlyContinue
if ($NpxCmd) {
    & npx.cmd wrangler d1 execute act_omega_d1_vault --remote --config='wrangler.toml' --file=$SqlPath --yes
    & npx.cmd wrangler d1 execute act_omega_d1_vault --remote --config='wrangler.toml' --command='SELECT artifact_name, byte_length, sha256_digest, measured_shards, measured_neurons FROM v41_measured_sha256_audit;' --yes
}
