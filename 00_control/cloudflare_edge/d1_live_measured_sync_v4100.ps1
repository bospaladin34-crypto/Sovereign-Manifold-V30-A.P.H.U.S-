# =============================================================================
# 00_control/cloudflare_edge/d1_live_measured_sync_v4100.ps1
# Computes real SHA-256 digests and executes wrangler d1 execute --remote
# across all 8 tables in act_omega_d1_vault (9f46d56a-ef3e-4232-a9ac-c4bd12e20a87)
# =============================================================================
$ErrorActionPreference = 'Continue'
$Root = 'C:\sovereign_manifold_v31'
Set-Location $Root

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
Write-Output "Measured SHA-256 (Lean 4 364 QED): $LeanSha256"

$SqlPath = Join-Path $Root '00_control\cloudflare_edge\sync_d1_v4300_all8tables.sql'
$NpxCmd = Get-Command npx.cmd -ErrorAction SilentlyContinue
if ($NpxCmd) {
    & npx.cmd wrangler d1 execute act_omega_d1_vault --remote --config='wrangler.toml' --file=$SqlPath --yes
}
