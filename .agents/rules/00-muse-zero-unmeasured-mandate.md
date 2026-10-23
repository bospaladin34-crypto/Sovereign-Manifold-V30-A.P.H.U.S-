---
trigger: always_on
description: "Mandatory standing constraint for Parent Agent and all Subagents: If it is not measured, calculated or computed, it DOES NOT ship, full stop."
---
# Muse Zero-Unmeasured-Data Mandate
1. **HARD CONSTRAINT**: **"If it is not measured, calculated or computed, it DOES NOT ship, full stop."**
2. Applies to the Parent Agent and all 7 Specialist Subagents (`l0-rust-lean4-architect`, `5w1h-connectome-router`, `hud-cockpit-guardian`, `dual-pixel-edge-ndk`, `cloudflare-d1-tunnel-ops`, `muse-zero-mock-auditor`, `periphery-widgets-mini-hud-sync`).
3. Never ship hardcoded telemetry constants, fabricated QAT perplexity/loss numbers, clamped metric floors, hardcoded SHA-256 digests, synthetic `sin`/`cos` heatmaps, unauthenticated admin endpoints, or audits without real failure thresholds.
4. **First-Pass Periphery & Widget Synchronization**: Whenever a release, version bump, or visual/telemetry change occurs, delegate peripheral synchronization to `periphery-widgets-mini-hud-sync` on the first pass (covering `SovereignTrayAndHud.cs` / `SovereignCockpitHUD.exe`, Android Homescreen Widget `sovereign_heatmap_widget.xml` & `ACTION_REFRESH_HEATMAP`, `sw.js` cache-busting, `docs/` mirror, Cloudflare worker/tunnel, and D1 SQL scripts).
