---
trigger: glob
globs: "05_hud_cockpit/**/*, 02_l2_orchestration/**/*, docs/**/*, index.html, wiki.html, hud.html"
description: "Host WebGPU HUD (05_hud_cockpit & 02_l2_orchestration/hud) preservation of 15 Cards (Card #8 840/840 QED), Gemini+Win11 Mica+M3 Redesign, Gemma 4 Chat Studio, 60 FPS Scopes, 16x130 Heatmap, 5-View Lens Switcher, honest UNMEASURED/OFFLINE fallbacks, External Operator Auth Gate, and 53B GSC Certificate Lock."
---
# WebGPU HUD, Gemini+Win11+M3 Studio, 8-Domain Command Deck, GSC Lock & Portal Rules (ACT-Omega Net v70.0.0 | CHAIN 316 | 840/840 QED)

1. **100% Preservation + Gemini + Windows 11 Mica + Material 3 Redesign**:
   - Preserve 100% of the **15 Interactive Telemetry Cards** in Drawer A (Card #8 `840 / 840` Lean 4 QED, with Compact/Full Density Toggle), the **60 FPS 3D Stiefel/Theodorus Vector Scope & 15.965 Hz Oscilloscope** in Drawer B, the **16x130 (`2,080`-Cacheline) Heatmap**, the **5-View Cockpit Lens Switcher** (`ALL`, `CARDS`, `SCOPES`, `OPS`, `TOOLS`), the **`Ctrl+K` Command Palette**, Drawer 3 (`840/840` Lean 4 QED), Drawer 4 (**8-Domain Functional Command Deck** consolidating all `316` Native Tools (`CHAIN 316`)), the **Before/After Theme Mode Toggle (`✨ Gemini + Win11 Mica + M3` $\leftrightarrow$ `Legacy Neon`)**, the **Dual Gemma 4 Conversational Studio (`/api/v1/gemma4/chat`)**, the **Floating Gemini Omnibar**, and the **5 Official Braid/Orthoplex Artworks** across `App.tsx`, `MainActivity.kt`, and `SovereignTrayAndHud.cs` (`Ω70`).

2. **Honest `"UNMEASURED/OFFLINE"` Fallback Law (Zero Synthetic Constants)**:
   - In `runBrowserWebGpuMicroBatch` and `toggleBrowserWebGpuLease` (and all HUD telemetry renderers), if `e8zCachelineNorms` is absent (`length < 12`) or any sampled component is `<= 0`, the HUD MUST immediately return `[0, "UNMEASURED/OFFLINE", ...]` and display `UNMEASURED/OFFLINE`.
   - Never fall back to hardcoded per-component constants (`0.8520 + ...`, `0.7140 + ...`) or synthetic `Math.sin`/`Math.cos` values.

3. **Zero-Secret Client Bundle & Header-Only Operator Gate**:
   - Never place any operator passkey literal in `App.tsx`, `index.html`, `wiki.html`, or any client bundle.
   - The Operator IDE & Vault gate must send the user-supplied key exclusively via the `X-Sovereign-Operator-Key` HTTP header to `/api/v1/auth/operator_vault_gate` (never via `?key=` query string).

4. **Mandatory Source Mirror & 6-Target Bundle Sync Recipe**:
   - After any edit to `05_hud_cockpit/src/App.tsx`:
     1. Copy `05_hud_cockpit/src/App.tsx` -> `02_l2_orchestration/hud/src/App.tsx` (1:1 byte parity).
     2. Run `npm run build` in `05_hud_cockpit` (`EXIT: 0`).
     3. Clean old `assets/index-*.js` and copy `05_hud_cockpit/dist/*` to `02_l2_orchestration/hud/dist/`, `docs/`, and root (`index.html`, `hud.html`, `assets/`).
     4. Sync `manifest.webmanifest`, `llms.txt`, `wiki.html`, and `telemetry_snapshot.json` across all 6 targets (`05_hud_cockpit/{public,dist}`, `02_l2_orchestration/hud/{public,dist}`, `docs/`, and repo root).

5. **GitHub Pages Relative Asset (`./`) & Pre-Rendered `#root` SSR Snapshot Law**:
   - All asset references in `index.html`, `hud.html`, `docs/index.html`, `docs/hud.html`, and `05_hud_cockpit/dist/index.html` MUST use relative paths starting with `./` (e.g., `./assets/index-<hash>.js`).
   - `<div id="root">` in all static HTML entrypoints MUST be pre-populated with `<main data-sovereign-ssr="v70.0.0">` (or active release version) containing structured semantic telemetry, authorship (**Donevin Frownfelter** `@bospaladin34-crypto`), Zenodo DOI `10.5281/zenodo.23651696`, OSF DOI `10.17605/OSF.IO/2XQ5Z`, and Maryna S. Viazovska's citations.

6. **Permanent Google Search Console Ownership Certificate Lock (`google6edc0affb12d0455.html`) — STRICT `DO NOT REMOVE`**:
   - `google6edc0affb12d0455.html` MUST remain strictly `53` bytes (`google-site-verification: google6edc0affb12d0455.html`, SHA-256 `0241DC5EDED053A96317C9C8FF34F4DCF12C069F88B8D92636D5D795EC176B3D`) across all 7 targets (`05_hud_cockpit/{public,dist}`, `02_l2_orchestration/hud/{public,dist}`, `docs/`, root, and `E:\`) and its HTTP handlers on `:8097`, `:5173`, and `worker_vpc_shadow_v3700.js`.
