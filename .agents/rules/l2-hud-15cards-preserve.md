---
trigger: glob
globs: "05_hud_cockpit/**/*, 02_l2_orchestration/**/*, docs/**/*, index.html, wiki.html, hud.html"
description: "Host WebGPU HUD (05_hud_cockpit & 02_l2_orchestration/hud) preservation of 15 Cards, 60 FPS Scopes, 16x130 Heatmap, 5-View Lens Switcher, honest UNMEASURED/OFFLINE fallbacks, and External Operator Auth Gate."
---
# WebGPU HUD, UI/UX Streamlining & Portal Rules (ACT-Omega v49.0.0+ | CHAIN 100)

1. **100% Preservation + Zero-Data-Loss UI/UX Streamlining**:
   - Preserve 100% of the **15 Interactive Telemetry Cards** in Drawer A (with Compact/Full Density Toggle), the **60 FPS 3D Stiefel/Theodorus Vector Scope & 15.965 Hz Oscilloscope** in Drawer B, the **16x130 (`2,080`-Cacheline) Heatmap**, the **5-View Cockpit Lens Switcher** (`ALL`, `CARDS`, `SCOPES`, `OPS`, `TOOLS`), the **`Ctrl+K` Command Palette**, Drawer 3 (`460/460` Lean 4 QED), and Drawer 4 (`100` Native Tools / `CHAIN 100` with Taxonomic Category Tabs & Instant Search).

2. **Honest `"UNMEASURED/OFFLINE"` Fallback Law (Zero Synthetic Constants)**:
   - In `runBrowserWebGpuMicroBatch` and `toggleBrowserWebGpuLease` (and all HUD telemetry renderers), if `e8zCachelineNorms` is absent (`length < 12`) or any sampled component is `<= 0`, the HUD MUST immediately return `[0, "UNMEASURED/OFFLINE", ...]` and display `UNMEASURED/OFFLINE`.
   - Never fall back to hardcoded per-component constants (`0.8520 + ...`, `0.7140 + ...`) or synthetic `Math.sin`/`Math.cos` values.

3. **Zero-Secret Client Bundle & Header-Only Operator Gate**:
   - Never place any operator passkey literal in `App.tsx`, `index.html`, `wiki.html`, or any client bundle.
   - The Operator IDE & Vault gate must send the user-supplied key exclusively via the `X-Sovereign-Operator-Key` HTTP header to `/api/v1/auth/operator_vault_gate` (never via `?key=` query string).

4. **Mandatory Source Mirror & Multi-Target Bundle Sync Recipe**:
   - After any edit to `05_hud_cockpit/src/App.tsx`:
     1. Copy `05_hud_cockpit/src/App.tsx` -> `02_l2_orchestration/hud/src/App.tsx` (1:1 byte parity).
     2. Run `npm run build` in `05_hud_cockpit` (`EXIT: 0`).
     3. Clean old `assets/index-*.js` and copy `05_hud_cockpit/dist/*` to `02_l2_orchestration/hud/dist/` and `docs/`, and sync `05_hud_cockpit/dist/index.html` to root `index.html`.
     4. Increment `CACHE_NAME` in `05_hud_cockpit/public/sw.js` when version or asset structure changes.
