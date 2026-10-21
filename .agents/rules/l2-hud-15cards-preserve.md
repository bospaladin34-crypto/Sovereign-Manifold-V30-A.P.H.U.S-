---
trigger: glob
globs: "05_hud_cockpit/**/*, 02_l2_orchestration/**/*, index.html, wiki.html, hud.html"
description: "Host WebGPU HUD (05_hud_cockpit) preservation of all 15 Telemetry Cards, 3D Stiefel Scope, 16x130 Heatmap, and Auth-Gated Operator Vault."
---
# WebGPU HUD & Portal Rules (ACT-Omega v43.0.0)
1. Always preserve all 15 Interactive Telemetry Cards in Drawer A, the 60 FPS 3D Stiefel Scope & 15.965 Hz Oscilloscope in Drawer B, the 16x130 (2,080-Cacheline) Heatmap, and Drawers 1-4 in `05_hud_cockpit/src/App.tsx` and `02_l2_orchestration/hud/src/App.tsx`.
2. Keep the Embedded IDE & Antigravity Operator Vault gated behind passkey `SOVEREIGN-LOQ15-4200` (or localhost origin) to prevent accidental public overuse on `act-omega-net.dev`.
3. Always run `npm run build` inside `05_hud_cockpit` after editing `05_hud_cockpit/src/App.tsx` so `05_hud_cockpit/dist` updates on `:5173`.
