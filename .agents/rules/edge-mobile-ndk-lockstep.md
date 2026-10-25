---
trigger: glob
globs: "04_edge_silicon/**/*"
description: "Dual-Phone Android NDK/Compose APK (MainActivity.kt) rules for Pixel 10 (58170DLCR0004V) and Pixel 8 (3A121FDJH00BW5)."
---
# Dual-Pixel Edge Silicon & NDK APK Rules (ACT-Omega v49.0.0+ | CHAIN 100)

1. **100% Mobile Cockpit & Widget Preservation**:
   - Preserve all 15 Mobile Telemetry Cards, the 60 FPS Stiefel Scope & Oscilloscope, the `16x130` (`2,080`-Cacheline) Heatmap, the Top Lens Bar (`ALL`, `CARDS`, `SCOPES`, `TOOLS`, `BUS+E:`), and all `ToolButton603010` rows (`T01..T100` / `CHAIN 100`) in `MainActivity.kt`.

2. **Strict Source Mirror Lockstep (`app/src` == `src`)**:
   - Always keep `04_edge_silicon/pixel10_ndk_app/app/src/main/java/com/actomega/manifold/MainActivity.kt` and `04_edge_silicon/pixel10_ndk_app/src/main/java/com/actomega/manifold/MainActivity.kt` in 1:1 byte-identical lockstep (same SHA-256).
   - Keep `app/src/main/res/layout/sovereign_heatmap_widget.xml` and `src/main/res/layout/sovereign_heatmap_widget.xml` in 1:1 lockstep.

3. **Dual-Pixel Build, Install & Homescreen Widget Refresh Recipe**:
   - Build in `04_edge_silicon/pixel10_ndk_app` via `.\gradlew.bat assembleDebug --console=plain`.
   - For both **Pixel 10 (`58170DLCR0004V`, `S48..S63`)** and **Pixel 8 (`3A121FDJH00BW5`, `S64..S79`, `4.00 MB` L2 SHM)**:
     - Ensure `adb -s <dev> reverse tcp:8097 tcp:8097` and `adb -s <dev> reverse tcp:5173 tcp:5173`.
     - Install via `adb -s <dev> install -r app\build\outputs\apk\debug\app-debug.apk`.
     - Broadcast widget refresh: `adb -s <dev> shell am broadcast -a com.actomega.manifold.ACTION_REFRESH_HEATMAP -n com.actomega.manifold/.SovereignHeatmapWidgetProvider`.

4. **HARD CONSTRAINT (MUSE MANDATE)**:
   - **"If it is not measured, calculated or computed, it DOES NOT ship, full stop."** All mobile heatmap cells must derive from `loadMeasuredE8zAsset(context)` (`sovereign_harmonic_iv_v4000.e8z`) + live `sector_norms_csv` telemetry; when offline, explicitly indicate fallback state without fabricating sensor metrics.
