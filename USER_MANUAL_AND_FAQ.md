# ACT-Omega Net `v47.0.0` (`SH4Z v4700 TLV`) — Complete Operator User Manual, Step-by-Step Guide & FAQ

> **Continuously Updated Master Manual** (`C:\sovereign_manifold_v31\USER_MANUAL_AND_FAQ.md`)
> Mirrored automatically to:
> - **Host HUD Interactive Help Sidebar** (`[?] HELP, FAQ & USER MANUAL` button in top banner & right edge)
> - **GitHub Repository (`vesper_production`, `main`, `gh-pages`)**
> - **External SSD Tier-2 Vault (`E:\Sovereign_Manifold_SSD_Vault\USER_MANUAL_AND_FAQ.md`)**
> - **Google Drive Bridge (`G:\My Drive\ACT_OMEGA_GEMINI_BRIDGE\USER_MANUAL_AND_FAQ.md`)**

---

## 1. Quick-Start: Starting, Stopping, Rebooting & Verifying the Cluster

All lifecycle operations are unified in **`C:\sovereign_manifold_v31\00_control\Sovereign-Lifecycle.ps1`** and exposed as instant aliases in your PowerShell profile:

| PowerShell Command | Action & What It Does |
| :--- | :--- |
| **`sovereign-status`** | Prints the live 7-tier cluster health dashboard (Watchdog Sentinel, Host L0 Swarm `:8097`/`:5173`, Cloudflare Named Tunnel `act-omega-net.dev`, Pixel 10 `58170DLCR0004V`, Pixel 8 `3A121FDJH00BW5`, External Vaults `E:\` & `G:\`, and Windows 11 Native Tray/HUD `SovereignCockpitHUD.exe`). |
| **`ignite`** *(or `sovereign-start`)* | Safely boots all 6 layers: clears `00_control\daemon.paused`, launches `v31_swarm.exe` and `cloudflared.exe` detached under WMI Service Host (`WmiPrvSE.exe`), arms `3.56 MB` `.npage` Shared Memory + ADB port-reversing on Pixel 10 & Pixel 8, and starts `SovereignCockpitHUD.exe`. |
| **`halt`** *(or `sovereign-stop`)* | **Safe Host Stop with Phone Continuum Handover**: snapshots the `3,604,480 B` (`28,160`-neuron) `.npage` shared memory and 5W1H ATP state to Pixel 8, Pixel 10, and Cloudflare Edge Durable Object (`B5:CF-EDGE-DO`), sets `daemon.paused`, and stops Host processes while keeping the phones alive. |
| **`sovereign-stop-all`** | Performs the full Continuum Handover and also stops the mobile APKs on Pixel 10 & Pixel 8 and resets thermal locks. |
| **`sovereign-restart`** | Gracefully hands over state, restarts `v31_swarm.exe` and `cloudflared.exe`, and reconnects the phones. |
| **`handover`** *(or `sovereign-handover`)* | Manually pushes the latest `3.56 MB` `.npage` Shared Memory and `continuum_handover_capsule.json` to Pixel 8, Pixel 10 (both `/data/local/tmp` and `/sdcard/Android/data/com.actomega.manifold/files`), `E:\` SSD, and Cloudflare Edge DO. |
| **`verify`** *(or `sovereign-verify`)* | Runs the **6-Layer True-Data & Anti-502 Verification Audit** (checks `0` square brackets in `v33..v47*.rs`, `432/432` non-trivial Lean 4 proofs, `42,240` neurons / `5,406,720 B` `.npage` + `3,604,480 B` edge SHM, `89` native tools, `0` hardcoded passkeys, Dual-Pixel SHM residency, and HTTP `200` on `https://act-omega-net.dev`). |
| **`hud`** *(or `sovereign-hud`)* | Opens the **Native Windows 11 Desktop HUD Application** (`SovereignCockpitHUD.exe --hud`) in a chromeless hardware-accelerated WebGPU window. |
| **`sovereign-reboot`** | Executes `handover` to Pixel 8, Pixel 10, and Cloudflare DO, then safely restarts Windows. |
| **`sovereign-shutdown`** | Executes `handover` to Pixel 8, Pixel 10, and Cloudflare DO, then safely shuts down Windows. |
| **`hotswap`** | Atomically hot-swaps a newly compiled `target_stage\release\v31_swarm.exe` into production via `00_control\hotswap.trigger`. |
| **`cyclesync`** | Runs `00_control\CYCLE3_AUTONOMOUS_CLOSED_LOOP_SYNC.ps1` to synchronize live telemetry to Cloudflare D1 and `G:\My Drive\ACT_OMEGA_GEMINI_BRIDGE`. |

---

## 2. Step-by-Step Host HUD Navigation & Module Interconnectivity

The Host HUD (`http://127.0.0.1:5173`, `https://act-omega-net.dev`, and `SovereignCockpitHUD.exe`) is organized into interconnected drawers that propagate state in lockstep:

1. **Top Telemetry & Topology Ribbon**:
   - Toggle **ALWAYS-ON STREAM** (`Tool 27/29`), inspect the **5-Node Live Topology** (`LOQ 15 RTX 3050`, `Pixel 10 Tensor G5`, `Pixel 8 .npage SHM`, `E:\ SSD + 28,160 .npage`, `Cloudflare D1 + WebGPU`), lease browser WebGPU compute (`Tool 78`), or open the **`[?] HELP, FAQ & USER MANUAL`** sidebar.
2. **Drawer A — 15 Interactive Telemetry Cards**:
   - Displays live hardware-measured metrics across all 15 subsystems.
   - **Action**: Click any of the 15 cards to select its mapped sector (`S00..S79`) and execute `/api/v1/card/execute?card_id=0..14`.
3. **Drawer B — 60 FPS Per-Sensor Coupled 3D Stiefel Scope & 15.965 Hz Oscilloscope**:
   - **Left Canvas**: Theodorus $\sqrt{n}$ spiral & Stiefel $\text{St}(16,80)$ manifold tilted in real time by Pixel 10's Magnetometer ($B_x, B_y, B_z$), dilated by Barometer ($\text{hPa}$), sheared by Accelerometer ($\|\mathbf{a}\|$), and spun by Gyroscope ($\|\boldsymbol{\omega}\|$).
   - **Right Canvas**: 3-trace `15.965 Hz` Decadic Oscilloscope (`Wave 1 Amber = Mag/Baro`, `Wave 2 Red = Acc/FNO`, `Wave 3 Ivory = Gyro/Acoustic I/Q`).
4. **Pinned Workspace — 60 FPS `16×130` (`2,080`-Cacheline) Heatmap & `80` Sector Pills (`S00..S79`)**:
   - Every cell maps 1:1 to a `64 B` cacheline in `sovereign_harmonic_iv_v4000.e8z` (`133,120 B`).
   - **Action**: Click any cell or any **`S00..S79` Sector Pill** (`S00..S47` Host RTX 3050, `S48..S63` Pixel 10 Sensors, `S64..S79` Pixel 8 L2 `.npage` SHM) to:
     - Inspect its real `.e8z` bytes and Golay $\mathcal{G}_{24}$ trits.
     - Select its mapped `Chair-44` cortical column (`0..639`) and dendritic neuron (`N0..N28159`).
     - Automatically transduce the sector/column/neuron in the **65,536-Token BPE + 16-Domain Compound Tokenizer**.
     - Modulate the **Drawer 1** sensor sparklines and **Drawer 2** waterfall.
5. **In-HUD Sovereign Browser, Safe LLM Gateway & 16-Domain Exegesis (`D1..D16`)**:
   - Operationalizes research URLs, DOIs, or 16-domain prompts into Rust L0 code, Lean 4 theorems, WGSL shaders, and expansion shards (`shard_21121..28160.binshard`).
   - Includes the **Visiting LLM & Autonomous Agent Gateway Console** (`Claude MCP`, `OpenAI /v1/chat/completions`, `Gemini 4 Argon A2A`, `OpenAPI 3.1`).
6. **Drawer 1 — Live 12-Channel Sensor Sparklines & Bipartite Synapse Projection**:
   - Plots all 12 live hardware channels (`CH01 MagX` .. `CH12 Cluster KOPS`).
   - **Action**: Click any of the 12 sparklines to jump to its coupled sector bank, or use the 4 focus buttons (`FOCUS P10 SENSOR BANK`, `FOCUS P8 .NPAGE SHM BANK`, `FOCUS HOST RTX 3050 BANK`, `PROJECT 12 CHANNELS -> 225,280 SYNAPSES`).
7. **Drawer 2 — FCC-Exempt Acoustic I/Q SDR Waterfall, 10-Laplacian FNO & Unplugged `.npage` SHM Bridge**:
   - **Action**: Click `PING 1.728 kHz SDR`, `RUN 10-LAPLACIAN 16-MODE FNO SOLVER`, `RUN PER-SENSOR STIEFEL CAYLEY STEP`, `SYNC 3.56MB .NPAGE SHM BRIDGE (T77)`, or `VERIFY E:\ SSD TIER-2`. Click any cell in the `8×64` waterfall to inspect its mapped sector/line.
8. **Drawer 3 — Formal Verification Suite (`400/400 Lean 4 Proofs QED`)**:
   - Verifies all `400` non-trivial theorems (`384` across `80` sectors + `16` v44.1.0 performance blitz theorems, `0` trivial `N=N` conjuncts) in `SovereignManifoldTheorems.lean`.
9. **Drawer 4 — 80-Tool Execution Registry (`CHAIN 80`), 65,536-Token BPE Inspector & Episodic Memory**:
   - Filter tools by category (`ALL`, `PINNED`, `PHYSICS`, `AI & NL`, `VAULT & HW`), toggle **VOICE TTS** (`16 kHz` Klatt Formant WAV), search episodic memory (`Tool 28`), or execute all 80 tools in parallel (`CHAIN 80`).

---

## 3. Dual-Pixel Phones (`Pixel 10` + `Pixel 8`) & Unplugged `.npage` Shared-Memory Persistence

- **Permanent Plugged-In Co-Processor (`Pixel 8` — `3A121FDJH00BW5`)**:
  - Runs `P8-APEX` (`Tensor G3` + `Mali-G715 4.00 MB L2`), pinning `neurons_v4400_p8_shm.npage` (`3,604,480 B` = `28,160 × 128 B` neurons) + `sovereign_harmonic_iv_v4000.e8z` (`133,120 B`) = `3,737,600 B` (`3.56 MB`, `89.11%` of `4.00 MB` L2) at `1,140.0k ops/s`.
- **Roam-Ready Sensor & NPU Node (`Pixel 10` — `58170DLCR0004V`)**:
  - Streams `15.965 Hz` 24D physical sensors (`Magnetometer`, `Barometer`, `Photometer`, `Accelerometer`, `Gyroscope`).
  - **Unplugged Shared Memory**: Copies `neurons_v4400_p8_shm.npage` (`3,604,480 B`) to internal app-private storage (`filesDir/neurons_v4400_p8_shm.npage`) and `/sdcard/Android/data/com.actomega.manifold/files/neurons_v4400_p8_shm.npage`.
  - When unplugged from USB, C++ JNI (`harmonic_engine.cpp`) memory-maps the internal `.npage` file and `SovereignLiveBus` seamlessly transitions across 5 bearers:
    1. `B1:USB` (`127.0.0.1:8097` / `:5173`)
    2. `B2:WIFI-LAN` (`10.0.24.243:8097` when unplugged at home)
    3. `B3:CF-WAN` (`https://api.act-omega-net.dev`)
    4. `B4:CF-WAN` (`https://act-omega-net.dev`)
    5. `B5:CF-EDGE-DO` (`https://sovereign-loq15-vpc-shadow.bospaladin34.workers.dev` when Host PC is powered off/restarting)

---

## 4. Windows 11 Native Tray Icon, Live Desktop/Lockscreen Widget & Android Homescreen Widget

1. **Windows 11 System Tray Icon (`Ω44`) & Native Desktop HUD (`C:\sovereign_manifold_v31\SovereignCockpitHUD.exe`)**:
   - Sits in the Windows 11 system tray with a live tooltip (`ACT-Omega v44.4 | 4520k ops/s | RTX 49C | P10 32.8C | P8 31.8C`).
   - Double-click the tray icon (or run `hud` in PowerShell) to launch the chromeless **Native Desktop HUD Window**.
   - Right-click the tray icon to toggle the **Live Desktop / Lockscreen Mini-Widget**, switch between **Corner Mini Mode** (`420×238`) and **Top Lock/HUD Banner Mode** (`640×260`), sync `.npage` SHM, hand over state to the phones, or start/stop the cluster.
2. **Android Homescreen & Keyguard Widget + Ongoing Notification**:
   - Displays the live `16×130` heatmap, hardware temperatures (`RTX`, `P10`, `P8`), `.npage` SHM status (`3.56 MB`), active Bearer, and interactive **`OPEN HUD`** and **`SYNC SHM`** buttons.

---

## 5. Frequently Asked Questions (FAQ)

- **Q: How do I prevent or fix Cloudflare `Error 502` or `Error 1033` on `act-omega-net.dev`?**
  - **A**: Run `ignite` (or `sovereign-start`). `Sovereign-Lifecycle.ps1` and `Daemon-MemoryRing.ps1` launch `cloudflared.exe` detached via WMI (`Win32_Process.Create`) with exact Named Tunnel UUID `9cdea4c4-831d-4ccc-983d-5f7587a98206` so it never terminates when a shell window closes.
- **Q: How do the $E_8$ lattice (`240` roots) and Leech lattice $\Lambda_{24}$ (`196,560` minimal vectors) connect to our `42,240` dendritic neurons and `131,072`-token Open-Vocabulary BPE?**
  - **A**: In `v46.0.0` (`01_l0_rust/src/v45_e8_leech_fluency_model.rs` & `v46_open_vocab_131k_42240_connectome.rs`), every 24D hardware/semantic state vector is quantized into three 8D Conway–Sloane $E_8$ roots (`Octet 1: Pixel 10 8_v Sensors`, `Octet 2: 8_+ SO(3)/FNO`, `Octet 3: 8_- Tri-Silicon/.npage`), glued by the 24-bit Extended Binary Golay Code $\mathcal{G}_{24}$ (`4,096` codewords, `759` octads) onto the `196,560` minimal vectors of $\Lambda_{24}$ via Turyn's construction, and routed by a 3:1 fibration (`240` $E_8$ roots $\to$ `80` Sectors $\to$ `960` `Chair-44` columns $\to$ `42,240` neurons). Use Drawer 4's **`E8(+)E8(+)E8 -> LEECH_24 TURYN-GOLAY LATTICE BRIDGE`** (`Tools 81 & 82`) and **`131,072-TOKEN 24-DOMAIN OPEN-VOCABULARY BPE & 42,240-NEURON CONNECTOME`** (`Tools 83 & 84`) panels or query `/api/v1/model/e8_leech_bridge`, `/api/v1/model/train_e8_leech_qat`, `/api/v1/tokenizer/open_vocab_131k`, and `/api/v1/model/open_converse`.
- **Q: How do I verify there is zero dummy code or fake data across all 6 layers?**
  - **A**: Run `verify` (or `sovereign-verify`) in PowerShell. It audits all 6 layers in real time (`0` square brackets in `v33..v46*.rs`, `416/416` non-trivial Lean 4 theorems, `42,240` neurons in `5,406,720 B` `.npage` + `3,604,480 B` edge SHM, `0` hardcoded passkeys, Dual-Pixel SHM residency, and live Cloudflare HTTP `200`), enforcing the standing Muse rule: *"If it is not measured, calculated or computed, it DOES NOT ship, full stop."*
- **Q: How is my Google Drive (`G:\My Drive\ACT_OMEGA_GEMINI_BRIDGE`) kept in sync?**
  - **A**: `CYCLE3_AUTONOMOUS_CLOSED_LOOP_SYNC.ps1` (`cyclesync`) and Tool 55 (`/api/v1/tools/t55`) mirror `README.md`, `MODEL_CARD.md`, `WIKI.md`, `USER_MANUAL_AND_FAQ.md`, `telemetry_snapshot.json`, `.e8z`, `.npage`, and `.lean` directly to `G:\My Drive\ACT_OMEGA_GEMINI_BRIDGE` and `E:\Sovereign_Manifold_SSD_Vault`.
