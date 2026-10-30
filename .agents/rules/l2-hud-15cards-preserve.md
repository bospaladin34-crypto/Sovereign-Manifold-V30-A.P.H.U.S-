---
trigger: glob
globs: "05_hud_cockpit/**/*, 02_l2_orchestration/**/*, docs/**/*, index.html, wiki.html, hud.html"
description: "Host WebGPU HUD (05_hud_cockpit & 02_l2_orchestration/hud) preservation of 15 Cards, 60 FPS Scopes, 16x130 Heatmap, 5-View Lens Switcher, honest UNMEASURED/OFFLINE fallbacks, External Operator Auth Gate, Anti-Stale Headers, and Relative Asset / SSR Snapshot Law."
---
# WebGPU HUD, 8-Domain Functional Command Deck, GSC Lock & Portal Rules (ACT-Omega Net v56.1.0 | CHAIN 210 | 624 QED)

1. **100% Preservation + Zero-Data-Loss UI/UX Streamlining**:
   - Preserve 100% of the **15 Interactive Telemetry Cards** in Drawer A (with Compact/Full Density Toggle), the **60 FPS 3D Stiefel/Theodorus Vector Scope & 15.965 Hz Oscilloscope** in Drawer B, the **16x130 (`2,080`-Cacheline) Heatmap**, the **5-View Cockpit Lens Switcher** (`ALL`, `CARDS`, `SCOPES`, `OPS`, `TOOLS`), the **`Ctrl+K` Command Palette**, Drawer 3 (`624/624` Lean 4 QED), and Drawer 4 (**8-Domain Functional Command Deck** consolidating all `210` Native Tools (`43+29+19+26+16+13+34+30 = 210`) with 1-click `/api/v1/unified/*` domain dispatchers, domain filter tabs, instant search, and collapsible individual tool grids across `App.tsx`, `MainActivity.kt`, and `SovereignTrayAndHud.cs`).

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

5. **Edge & Origin Anti-Stale-Cache Headers for Crawlers & LLMs**:
   - Cloudflare Edge Shadow Worker (`00_control/cloudflare_edge/worker_vpc_shadow_v3700.js` and root mirror `worker_vpc_shadow_v3700.js`) and L0 Origin Daemon (`01_l0_rust/src/bin/v31_swarm.rs` and mirror `src/v31_swarm.rs`) MUST serve root HTML responses (`/`, `/index.html`, `/hud.html`, `/docs/index.html`) with strict anti-stale headers:
     - `Cache-Control: public, max-age=0, must-revalidate`
     - `X-Robots-Tag: index, follow, max-snippet:-1`
   - Cloudflare Edge DO in-memory fallback must never cache stale HTML responses across releases, ensuring crawlers and external LLM retrieval agents receive instant live updates.

6. **GitHub Pages Relative Asset (`./`) & Pre-Rendered `#root` SSR Snapshot Law**:
   - **Relative Subpath Bundling (`./`)**:
     - All asset references in `index.html`, `hud.html`, `docs/index.html`, `docs/hud.html`, and `05_hud_cockpit/dist/index.html` MUST use relative paths starting with `./` (e.g., `./assets/index-<hash>.js`, `./assets/index-<hash>.css`, `./manifest.json`, `./sw.js`).
     - Absolute root paths (`/assets/...`) are strictly forbidden, guaranteeing zero 404 blank screens when hosted on GitHub Pages subpaths (e.g. `https://<user>.github.io/<repo>/`).
     - All referenced `assets/index-*.js` and `assets/index-*.css` files MUST exist concurrently in `assets/`, `docs/assets/`, and `05_hud_cockpit/dist/assets/`.
   - **Pre-Rendered `#root` SSR Snapshot Law**:
     - `<div id="root">` in all static HTML entrypoints (`index.html`, `hud.html`, `docs/index.html`, `docs/hud.html`, `05_hud_cockpit/dist/index.html`) MUST be pre-populated with a crawlable, semantic SSR snapshot: `<main data-sovereign-ssr="v56.0.0">` (or active release version).
     - The snapshot MUST contain structured semantic content:
       - Complete Tri-Silicon Cluster topology (Anchor-1 LOQ 15, Edge-1 Pixel 10 NDK, Edge-2 Rooted Pixel 8 APEX).
       - Exact connectome metrics: 63,360 dendritic pyramidal neurons, 1,440 Chair-44 columns, 1,013,760 synapses, 80 sectors, 132,960 cachelines.
       - Formal verification status: 624/624 Lean 4 QED theorems (zero sorry, zero axiom) and Layer 1.5 Haskell exact algebra.
       - Verified hardware IDs, ADB serials, Zenodo DOI `10.5281/zenodo.23651696`, OSF DOI `10.17605/OSF.IO/2XQ5Z`.
     - When React mounts on a client browser, it hydrates or replaces `#root`, while search crawlers, headless agents, and `curl` receive 100% crawlable architectural telemetry without executing JavaScript.

7. **Permanent Google Search Console Ownership Certificate Lock (`google6edc0affb12d0455.html`) — STRICT `DO NOT REMOVE`**:
   - **7-Target Exact Byte & SHA-256 Lock**: `google6edc0affb12d0455.html` MUST remain strictly `53` bytes (`google-site-verification: google6edc0affb12d0455.html`, SHA-256 `0241DC5EDED053A96317C9C8FF34F4DCF12C069F88B8D92636D5D795EC176B3D`) across:
     1. `05_hud_cockpit/public/google6edc0affb12d0455.html`
     2. `02_l2_orchestration/hud/public/google6edc0affb12d0455.html`
     3. `05_hud_cockpit/dist/google6edc0affb12d0455.html`
     4. `02_l2_orchestration/hud/dist/google6edc0affb12d0455.html`
     5. `docs/google6edc0affb12d0455.html`
     6. `google6edc0affb12d0455.html` (repo root)
     7. `E:\Sovereign_Manifold_SSD_Vault\google6edc0affb12d0455.html`
   - **`.gitignore` Un-Ignore Law**: Never add `05_hud_cockpit/dist/` to `.gitignore`; `05_hud_cockpit/dist/google6edc0affb12d0455.html`, `05_hud_cockpit/dist/index.html`, and `05_hud_cockpit/dist/assets/*` MUST remain tracked in Git so GitHub Actions CI (`Invoke-BrutalAgentGatekeeper.ps1 -StaticOnly`) passes on every push.
   - **HTTP & Edge Fast-Path Lock**: Never remove the `// STRICT DO NOT REMOVE: Google Search Console Ownership Verification Certificate (google6edc0affb12d0455.html)` handlers in `01_l0_rust/src/v31_swarm.rs` (`:8097` and `:5173`) or `00_control/cloudflare_edge/worker_vpc_shadow_v3700.js`.
