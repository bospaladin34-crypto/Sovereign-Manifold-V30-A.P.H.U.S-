---
name: cloudflare-edge-continuum-ops
description: >-
  Audit, deploy, and synchronize the ACT-Omega Cloudflare Named Tunnel
  (act-omega-net.dev), SovereignEdgeShadowDO SQLite Durable Object
  (worker_vpc_shadow_v3700.js), 10-Table Cloudflare D1 Vault
  (act_omega_d1_vault), and 2026 Cloudflare Free-Tier developer services
  (Vectorize, R2, Workers AI, Workers KV, Turnstile, Zero Trust Access). Use
  whenever inspecting or upgrading the Cloudflare edge layer.
---

# ACT-Omega Cloudflare Edge Continuum & 2026 Free-Tier Runbook (`v70.0.0+`)

## 1. Live Named Tunnel & Edge Worker Health Check
1. Verify local `cloudflared.exe` daemon and Seattle PoP connections:
   `"C:\sovereign_manifold_v31\00_control\cloudflared.exe" tunnel info 9cdea4c4-831d-4ccc-983d-5f7587a98206`
2. Probe public tunnel and Edge Worker endpoints:
   - `https://act-omega-net.dev/` (`200 OK`, `data-sovereign-ssr="v70.0.0"`)
   - `https://act-omega-net.dev/google6edc0affb12d0455.html` (`200 OK`, exact `53 B` GSC token)
   - `https://api.act-omega-net.dev/api/v1/chain316/master_certification` (`200 OK`, `total_tools: 316`, `lean4_theorems_qed: 840`)
   - `https://sovereign-loq15-vpc-shadow.bospaladin34.workers.dev/api/v1/edge_continuum/status` (`200 OK`, `tlv_version: 7000`, `lean4_theorems_qed: "840/840"`)

## 2. 3-Mirror Edge Worker Deployment & D1 Telemetry Sync
1. Edit `00_control/cloudflare_edge/worker_vpc_shadow_v3700.js` and mirror 1:1 to:
   - `00_control/cloudflare_edge/worker_continuum_do.js`
   - `worker_vpc_shadow_v3700.js` (repo root)
2. Ensure `$env:CLOUDFLARE_API_TOKEN` is unset if expired (`Remove-Item Env:\CLOUDFLARE_API_TOKEN -ErrorAction SilentlyContinue`) so Wrangler 4.158.0 uses the active OAuth token in `C:\Users\Nbell\AppData\Roaming\xdg.config\.wrangler\config\default.toml`.
3. Deploy via `npx wrangler deploy` and trigger `/api/v1/cloudflare/cron_sync` with live measured SHA-256 digests (`SovereignManifoldTheorems.lean`, `neurons_v6900_84480.npage`, `sovereign_harmonic_iv_v5000.e8z`).
