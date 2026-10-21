---
trigger: glob
globs: "04_edge_silicon/**/*"
description: "Dual-Phone Android NDK/Compose APK (MainActivity.kt) rules for Pixel 10 (58170DLCR0004V) and Pixel 8 (3A121FDJH00BW5)."
---
# Dual-Pixel Edge Silicon & NDK APK Rules (ACT-Omega v43.0.0)
1. Preserve all 15 Telemetry Cards, the 60 FPS Stiefel Scope & Oscilloscope, and the 16x130 Heatmap in `MainActivity.kt`.
2. Always use `ToolButton603010` and `invokeHostEndpoint` when adding new tool buttons in Drawer 4 of `MainActivity.kt`.
3. Synchronize both `04_edge_silicon/pixel10_ndk_app/app/src/main/java/com/actomega/manifold/MainActivity.kt` and `04_edge_silicon/pixel10_ndk_app/src/main/java/com/actomega/manifold/MainActivity.kt`, build via `gradlew.bat assembleDebug --no-daemon`, and install to both `58170DLCR0004V` (Pixel 10) and `3A121FDJH00BW5` (Pixel 8) with `adb reverse tcp:8097 tcp:8097` and `tcp:5173 tcp:5173`.
