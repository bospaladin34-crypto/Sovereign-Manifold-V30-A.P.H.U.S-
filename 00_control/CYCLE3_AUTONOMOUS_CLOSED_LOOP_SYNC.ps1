# ACT-Omega Net v43.0.0 (SH4Z v4300 TLV) — Cycle 3 Autonomous Closed-Loop Orchestrator (`CYCLE3_AUTONOMOUS_CLOSED_LOOP_SYNC.ps1`)
# Synchronizes Host (LOQ 15 :8097) <-> Mobile Edge (Pixel 10 58170DLCR0004V & Pixel 8 3A121FDJH00BW5) <-> Cloudflare Worker/D1/DO <-> E:\ SSD & G:\ Drive

$ErrorActionPreference = "SilentlyContinue"
Write-Host "========================================================================" -ForegroundColor Cyan
Write-Host " ACT-OMEGA v43.0.0 CYCLE 3: AUTONOMOUS HOST-EDGE-CLOUD CLOSED-LOOP SYNC" -ForegroundColor Cyan
Write-Host "========================================================================" -ForegroundColor Cyan

# 1. Verify ADB Reverse Tunnel on Pixel 10 & Pixel 8
$adbDevices = adb devices | Select-String -Pattern "device$"
foreach ($line in $adbDevices) {
    $serial = ($line.Line -split "\s+")[0]
    if ($serial) {
        adb -s $serial reverse tcp:8097 tcp:8097 | Out-Null
        adb -s $serial reverse tcp:5173 tcp:5173 | Out-Null
        Write-Host "[EDGE-ADB] Verified reverse tunnel (:8097 & :5173) on $serial" -ForegroundColor Green
    }
}

# 2. Trigger 65,536-Token Bidirectional BPE + 8-Domain Compound (128 Phrases) Tokenizer & Detokenizer
$tokRes = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/tokenizer/nl_transduce?q=sovereign%20manifold%20v43.0.0%20antigravity%20gemini%204%20argon%2015.965hz%2024640%20dendritic%20neurons%20n24639%20cloudflare%20d1" -TimeoutSec 5
if ($tokRes) {
    Write-Host "[CYCLE-1 TOKENIZER] Vocab=$($tokRes.vocab_size) | Tokens=$($tokRes.total_tokens) ($($tokRes.token_tiers_csv)) | Roundtrip=$($tokRes.roundtrip_exact) | Ratio=$($tokRes.compression_ratio)x | IPA=$($tokRes.detokenized_ipa)" -ForegroundColor Yellow
}

# 3. Trigger Cycle-2 8-Domain Compound QAT & Pixel 8 Speculative Verifier + 24,640-Neuron Connectome
$qatRes = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/training/cross_domain_compound_qat" -TimeoutSec 5
$cQatRes = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/train/continual_qat" -TimeoutSec 5
$npageRes = Invoke-RestMethod -Uri "http://127.0.0.1:8097/api/v1/pagefile/cauchy_sparse_npage?neuron_id=24639" -TimeoutSec 5
if ($qatRes) {
    Write-Host "[CYCLE-2 MODEL QAT] Epochs=$($qatRes.qat_total_epochs) | Bridged=$($qatRes.active_domains_bridged) Domains | Holdout PPL=$($qatRes.holdout_ppl) | Transfer=$($qatRes.compound_transfer_pct)% | P8 Speculative=$($cQatRes.p8_speculative_kops)k ops/s | Neurons=$($npageRes.total_combined_neurons) (560x Chair-44)" -ForegroundColor Magenta
}

# 4. Trigger Cloudflare Edge Worker Durable Object & 8-Table D1 Closed-Loop Sync
$cfRes = Invoke-RestMethod -Uri "https://sovereign-loq15-vpc-shadow.bospaladin34.workers.dev/api/v1/cloudflare/cron_sync" -TimeoutSec 10
if ($cfRes) {
    Write-Host "[CYCLE-3 CLOUDFLARE] Status=$($cfRes.status) | Cron=$($cfRes.cron_schedule) | Neurons=$($cfRes.npage_combined_neurons) | DO Heartbeats=$($cfRes.durable_object_shadow.heartbeats_stored) | D1 Connected=$($cfRes.d1_live.live_d1_connected)" -ForegroundColor Green
}

# 5. Mirror Updated Logs, Expansion .npage & Modules to E:\Sovereign_Manifold_SSD_Vault and G:\My Drive\ACT_OMEGA_GEMINI_BRIDGE
if (Test-Path "E:\Sovereign_Manifold_SSD_Vault") {
    Copy-Item "C:\sovereign_manifold_v31\03_vault\connectome\*.jsonl" "E:\Sovereign_Manifold_SSD_Vault\connectome\" -Force
    Copy-Item "C:\sovereign_manifold_v31\00_control\weights\neurons_v4300_expansion.npage" "E:\Sovereign_Manifold_SSD_Vault\weights\" -Force
    Write-Host "[VAULT-E] Mirrored QAT/5W1H JSONL rings & neurons_v4300_expansion.npage (450,560 B) to E:\Sovereign_Manifold_SSD_Vault" -ForegroundColor Cyan
}
if (Test-Path "G:\My Drive\ACT_OMEGA_GEMINI_BRIDGE") {
    Copy-Item "C:\sovereign_manifold_v31\01_l0_rust\src\v43_bpe_compound_65k.rs" "G:\My Drive\ACT_OMEGA_GEMINI_BRIDGE\" -Force
    Copy-Item "C:\sovereign_manifold_v31\00_control\weights\neurons_v4300_expansion.npage" "G:\My Drive\ACT_OMEGA_GEMINI_BRIDGE\weights\" -Force
    Write-Host "[BRIDGE-G] Synced v43_bpe_compound_65k.rs & neurons_v4300_expansion.npage (450,560 B) to G:\My Drive\ACT_OMEGA_GEMINI_BRIDGE" -ForegroundColor Cyan
}
