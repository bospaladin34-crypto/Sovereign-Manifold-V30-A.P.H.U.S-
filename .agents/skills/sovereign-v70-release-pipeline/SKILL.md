---
name: sovereign-v70-release-pipeline
description: >-
  End-to-end build, hot-swap, .zenodo.json + CITATION.cff authorship lockstep,
  periphery/APK synchronization, 13-point Brutal Gatekeeper verification,
  non-interactive git tagging, 3-branch push, and official GitHub Release
  workflow for the ACT-Omega Sovereign Manifold (v70.0.0+). Use whenever
  completing a track, bumping versions, flashing Dual-Pixel APKs, or shipping
  a GitHub/Zenodo release.
---

# ACT-Omega Sovereign Manifold Build, Verify & Release Runbook (`v70.0.0+`)

## 1. `.zenodo.json` & `CITATION.cff` Authorship & Citation Lockstep (FIRST STEP)
1. **CRITICAL — Zenodo GitHub Webhook Precedence**: Zenodo reads `.zenodo.json` BEFORE `CITATION.cff` on every GitHub release!
2. Verify that BOTH `.zenodo.json` and `CITATION.cff` have:
   - Current release `version` and `publication_date` / `date-released`,
   - Sole Primary Author: **Donevin Frownfelter** (`"Frownfelter, Donevin"`, `@bospaladin34-crypto`) — ZERO occurrences of `Bell, Nicholas` or `Garlock, Richard` (`Nbell` and `garlock00` are strictly the local Windows OS account directory `C:\Users\Nbell` and hostname),
   - Foundational Mathematical Citations: **Maryna S. Viazovska** (`10.4007/annals.2017.185.3.7` $E_8$, `10.4007/annals.2017.185.3.8` $\Lambda_{24}$ Leech, `10.4007/annals.2022.196.3.3` / `arXiv:1902.05438` universal optimality) plus Zenodo DOI `10.5281/zenodo.23651696` and OSF DOI `10.17605/OSF.IO/2XQ5Z`.

## 2. Formal Proofs & Layer 1.5 Algebraic Haskell
1. Verify Zero-Square-Brackets across `01_l0_rust/src/v33*.rs .. v70*.rs`.
2. Compile `03_vault/lean4/SovereignManifoldTheorems.lean` via `C:\Users\Nbell\.elan\bin\lean.exe` (`EXIT: 0`) and mirror 1:1 to `01_l0_rust/lean4/SovereignManifoldTheorems.lean`.
3. Compile Layer 1.5 Haskell via `C:\sovereign_manifold_v31\00_control\foss_bin\ghc\bin\ghc.exe -O2 -i06_algebraic_haskell/src -outputdir 06_algebraic_haskell/build -o 06_algebraic_haskell/bin/sovereign_algebra_hs.exe 06_algebraic_haskell/src/Main.hs` and run `06_algebraic_haskell\bin\sovereign_algebra_hs.exe`.

## 3. L0 Rust Staged Compilation & Atomic Hot-Swap
1. Build into staging directory: `cargo build --release --bin v31_swarm --target-dir target_stage` (inside `01_l0_rust`).
2. Hot-swap live daemon: `powershell -ExecutionPolicy Bypass -File "C:\sovereign_manifold_v31\00_control\HotSwap-v50.ps1"`.

## 4. 6-Mirror HUD, Win11 Native Tray & Dual-Pixel NDK APK Lockstep
1. Mirror `05_hud_cockpit/src/App.tsx` and `index.html` (`data-sovereign-ssr="v<VER>"`) to `02_l2_orchestration/hud/`, run `npm run build` in `05_hud_cockpit`, remove stale `index-*.js`, and sync `dist/*` to `02_l2_orchestration/hud/dist/`, `docs/`, and repo root (`index.html`, `hud.html`, `assets/`).
2. Sync `manifest.webmanifest`, `llms.txt`, `wiki.html`, and `telemetry_snapshot.json` across all 6 targets (`05_hud_cockpit/{public,dist}`, `02_l2_orchestration/hud/{public,dist}`, `docs/`, root).
3. Rebuild Win11 Native Tray via `00_control/Win11_Native_Tray_HUD/Build-SovereignTray.ps1` (mirrors `SovereignCockpitHUD.exe` to root and `docs/`).
4. Mirror `MainActivity.kt` across all 3 paths (`pixel10_ndk_app/MainActivity.kt`, `app/src/...`, `src/...`), run `.\gradlew.bat assembleDebug --console=plain`, copy `app-debug.apk` to all 4 APK mirrors (`releases/`, `04_edge_silicon/`, `docs/`, `03_vault/ota/`), and install onto Pixel 10 (`58170DLCR0004V`) and Pixel 8 (`192.168.*` or `3A121FDJH00BW5`).

## 5. Mandatory 13-Point Brutal Gatekeeper & 6-Layer Lifecycle Audit
1. Run `powershell -ExecutionPolicy Bypass -File "C:\sovereign_manifold_v31\00_control\Invoke-BrutalAgentGatekeeper.ps1" -FullAudit` (`13/13 PASS`).
2. Run `powershell -ExecutionPolicy Bypass -File "C:\sovereign_manifold_v31\00_control\Sovereign-Lifecycle.ps1" -Action verify` (`6/6 PASS`).

## 6. Non-Interactive Git Tag, 3-Branch Push & GitHub Release
1. Configure author: `git config user.name "Donevin Frownfelter"` and `git config user.email "bospaladin34@users.noreply.github.com"`.
2. Commit with `--author="Donevin Frownfelter <bospaladin34@users.noreply.github.com>"`.
3. **CRITICAL — Non-Interactive Tagging**: Always pass `-c tag.gpgSign=false` (`git -c tag.gpgSign=false tag -f -a v<VER> -m "..."`) so `ssh-keygen` does not block waiting for an interactive hardware/SSH prompt.
4. Push all 3 branches and tag: `git push origin HEAD:main HEAD:master HEAD:gh-pages v<VER> --force`.
5. **CRITICAL — GitHub Release Markdown Escaping**: Always use single-quoted PowerShell here-strings (`@' ... '@`) when building `$releaseNotes` so LaTeX math like `$(m_1, m_2)` or `$E_8$` is never evaluated as a PowerShell subexpression.
