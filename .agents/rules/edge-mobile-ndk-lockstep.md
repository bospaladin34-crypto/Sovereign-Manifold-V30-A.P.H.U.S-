---
trigger: glob
globs: "04_edge_silicon/**/*"
description: "Dual-Phone Android NDK/Compose APK (MainActivity.kt, v70.0.0 versionCode=70) rules for Pixel 10 (58170DLCR0004V) and Pixel 8 (3A121FDJH00BW5 / Wi-Fi Direct ADB)."
---
# Dual-Pixel Edge Silicon & NDK APK Rules (ACT-Omega v70.0.0 | CHAIN 316 | 840/840 QED)

1. **100% Mobile Cockpit & Widget Preservation (`v70.0.0`, `versionCode=70`)**:
   - Preserve all 15 Mobile Telemetry Cards (Card #8 `840 / 840` Lean 4 QED), the 60 FPS Stiefel Scope & Oscilloscope, the `16x130` (`2,080`-Cacheline) Heatmap, the Top Lens Bar (`ALL`, `CARDS`, `SCOPES`, `TOOLS`, `BUS+E:`), the Gemini + Win11 Mica + M3 mobile header & artwork cards, and all `ToolButton603010` rows (`T01..T316` / `CHAIN 316`) in `MainActivity.kt`.

2. **Strict 3-Mirror Source & 4-Target APK Lockstep**:
   - Always keep all **3** copies of `MainActivity.kt` in 1:1 byte-identical lockstep (same SHA-256):
     1. `04_edge_silicon/pixel10_ndk_app/MainActivity.kt`
     2. `04_edge_silicon/pixel10_ndk_app/app/src/main/java/com/actomega/manifold/MainActivity.kt`
     3. `04_edge_silicon/pixel10_ndk_app/src/main/java/com/actomega/manifold/MainActivity.kt`
   - Keep `app/src/main/res/layout/sovereign_heatmap_widget.xml` and `src/main/res/layout/sovereign_heatmap_widget.xml` in 1:1 lockstep, as well as `app/src/main/AndroidManifest.xml` and `src/main/AndroidManifest.xml`.
   - Mirror the built `app-debug.apk` to all **4** canonical APK targets:
     1. `releases/ACT-Omega-v70.0.0-Pixel10-Sovereign.apk`
     2. `04_edge_silicon/ACT-Omega-Pixel10-Sovereign.apk`
     3. `docs/ACT-Omega-Pixel10-Sovereign.apk`
     4. `03_vault/ota/act_omega_manifold_latest.apk`

3. **Dual-Pixel Build, USB + Wi-Fi Direct ADB Discovery & Install Recipe**:
   - Build in `04_edge_silicon/pixel10_ndk_app` via `.\gradlew.bat assembleDebug --console=plain`.
   - Discover **Pixel 10** via USB serial `58170DLCR0004V` (`S48..S63`, `49,152` CLs) and **Pixel 8** via either USB serial `3A121FDJH00BW5` or Wi-Fi Direct ADB (`192.168.*` / `adb-3A121FDJH00BW5*`, `S64..S79`, `32,768` CLs, `4.00 MB` L2 SHM).
   - Install via `adb -s <dev> install -r -d app\build\outputs\apk\debug\app-debug.apk` and broadcast widget refresh: `adb -s <dev> shell am broadcast -a com.actomega.manifold.ACTION_REFRESH_HEATMAP -n com.actomega.manifold/.SovereignHeatmapWidgetProvider`.

4. **HARD CONSTRAINT (MUSE MANDATE)**:
   - **"If it is not measured, calculated or computed, it DOES NOT ship, full stop."** All mobile heatmap cells must derive from `loadMeasuredE8zAsset(context)` + live `sector_norms_csv` telemetry; when offline, explicitly indicate fallback state without fabricating sensor metrics.
