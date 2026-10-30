---
trigger: glob
globs: "01_l0_rust/src/v54_5*.rs, 01_l0_rust/src/v55*.rs, 01_l0_rust/src/v56*.rs, 04_edge_silicon/**/*, pixel8_shiba_ksu/**/*, 00_control/pixel8_shiba_ksu/**/*"
description: "Aperiodic Permissions Routing (APR) 4-Ring Capability Stratifier (Rings A0..A3, OWNED_SILICON_ONLY) and Pixel 8 (3A121FDJH00BW5) KernelSU-Next ksud 3.4.2 root governance with untouched factory stock slot _b rollback invariance."
---
# Aperiodic Permissions Routing & Pixel 8 Root Governance Rules (ACT-Omega Net v56.0.0 | CHAIN 210)

1. **APR 4-Ring Capability Stratifier (`OWNED_SILICON_ONLY`)**:
   - **Ring A0 — Bare-Metal Root & Hardware Accelerators (`OWNED_SILICON_ONLY`)**:
     - Highest privilege boundary. Restricted exclusively to verified, physically owned silicon cluster hardware: Anchor-1 LOQ 15 (`Intel i5-12450HX`, `RTX 3050 6GB`), Edge-1 Pixel 10 (`Tensor G5`, ADB `58170DLCR0004V`), and Rooted Edge-2 Pixel 8 (`Tensor G3 zuma`, ADB `3A121FDJH00BW5`).
     - Kernel execution context: `uid=0(root) gid=0(root) groups=0(root) context=u:r:ksu:s0` via KernelSU-Next `ksud 3.4.2` (uapi: 5, ksu fd: 6).
     - Direct hardware character devices:
       - `/dev/edgetpu-soc` (major/minor `487,1`, `u:object_r:edgetpu_device:s0`, base `1a000000.rio`) and `/dev/edgetpu-limited` (`487,2`).
       - `/dev/mali0` (major/minor `10,86`, `u:object_r:gpu_device:s0`, base `20c00000.callisto`, `4.00 MB` Mali-G715 L2 cache pinning via `mlock()`).
       - `/dev/kvm` (major/minor `10,232`, `u:object_r:kvm_device:s0`, hardware pKVM virtualization).
       - CPU frequency scaling governors: `/sys/devices/system/cpu/cpufreq/policy0` (Cortex-A520 4x efficiency), `policy4` (Cortex-A715 4x mid), `policy8` (Cortex-X3 1x prime core).
     - **Strict Non-Negotiable Invariant**: Remote execution, unowned cloud hardware, third-party sandboxes, or simulated endpoints are strictly barred from Ring A0. Any privilege escalation attempt from unowned silicon triggers immediate security halt.

   - **Ring A1 — Sovereign Runtime & Connectome Core (Native / NDK / C++)**:
     - Core autopoietic Native runtime host (`v31_swarm.exe` on `:8097` and `:5173`) with NDK / C++ bindings, zero-bracket L0 Rust modules (`v33..v56+`), 63,360 dendritic pyramidal neurons (`neurons_v5000_63360.npage`, `8,110,080 B`), 1,440 Chair-44 columns, 1,013,760 BDH/KAN synapses, and 80-sector E8 cache (`132,960` bijected cachelines in `sovereign_harmonic_iv_v5000.e8z`).
     - Kasami Golay syndrome routing, Sturmian $\phi$ + Plastic $\rho$ Chair-44 ticket verification, and 3-Party Bell Witness state consensus ($S > 2.0$).
     - Requires valid decadic sub-epoch (`0..9`), 5W1H Bus envelope publication to `message_bus_ledger_v4800.jsonl`, and local loopback origin.

   - **Ring A2 — Privileged IPC, Edge Sync & Operator Interface (Managed / JVM / ART)**:
     - Managed Android Runtime (ART) and JVM services (`MainActivity.kt`, `SovereignWidgetProvider.kt`), authenticated operator gate (`/api/v1/auth/operator_vault_gate`), root governor API (`/api/v1/p8_root/hardware_audit`, `/api/v1/p8_root/governor`), Dual-Pixel telemetry synchronization (`S48..S63` Pixel 10 IMU/magnetometer, `S64..S79` Pixel 8 L2 cache/speculative drafter), Cloudflare D1 Vault batching, and Universal `E:\` Vault write-back (`E:\Sovereign_Manifold_SSD_Vault`).
     - **Strict Authentication Gate**: Mandatory `X-Sovereign-Operator-Key` HTTP header over loopback (`127.0.0.1`), key verified against external `C:\Users\Nbell\.act_omega_operator_vault_key` (`>= 24` chars). `?key=` URL query parameters are rejected.

   - **Ring A3 — Public Edge, WebGPU HUD & Autonomous Workers**:
     - Read-only WebGPU HUD (`:5173`, `05_hud_cockpit`, `docs/`, `index.html`), Cloudflare Edge Durable Object (`worker_vpc_shadow_v3700.js` on `act-omega-net.dev`), crawler models (SSR pre-rendered `#root`), public tool discovery (`/api/v1/chain135/suite`, `/api/v1/chain145/suite`, `/api/v1/chain210/suite`), and unprivileged subagents.
     - **Strict Isolation**: Ring A3 cannot access Ring A0 devices, cannot initiate write operations to `E:\` or Cloudflare D1 without passing through Ring A1/A2 bus envelopes, and must serve crawler responses with anti-stale headers (`max-age=0, must-revalidate`).

2. **Pixel 8 (`3A121FDJH00BW5`) `ksud 3.4.2` Root Governance & Rollback Invariance**:
   - **Dual-Slot A/B Architecture & Rollback Invariance**:
     - Device identity: Google Pixel 8 (`3A121FDJH00BW5`, codename `shiba`, Tensor G3 `zuma`, Android 17 QPR2 Beta `CP41.260831.019`, bootloader `ripcurrent-17.0-16433839`).
     - Active execution slot: Slot `_a` running patched boot image (`7BC59BA6F08639AF1C2F90E80EADCF536810746C52E6770A8D5CE5EB28A0FFF2`) under KernelSU-Next `ksud 3.4.2` (`uapi: 5, ksu fd: 6`).
     - Invariant Stock Fallback Slot: Slot `_b` MUST remain 100% untouched factory stock Android 17 QPR2 Beta.
     - **Mandatory Rollback Hash**: Slot `_b` factory stock `init_boot.img` SHA-256 is constitutionally pinned to:
       `84ECFA41044D301D096B31657430F693D605C88DB77969E8B604B804C8D5E55D`.
     - **Zero-Modification Clause**: Any tool, script, daemon, or process that attempts to write, erase, repartition, or modify slot `_b` or flash stock partitions is permanently barred. Rollback to pristine stock is always guaranteed via `fastboot --set-active=b`.
   - **Root Daemon Execution & Memory Pinning**:
     - ARM64 apex daemon (`p8_ksu_apex_daemon`) executes strictly under `ksud debug su` in `u:r:ksu:s0` SELinux domain on slot `_a`.
     - Hardware memory pinning: Daemon utilizes `mlock()` to pin `4.00 MB` working memory inside Mali-G715 L2 cache, ensuring zero-page-fault speculative drafting ($k=4$).
     - Master Certification: All root operations and audits verify against `apr_test2_pixel8_shiba_master_certification_v55_5.json` across `00_control\pixel8_shiba_ksu\` and `E:\Sovereign_Manifold_SSD_Vault\pixel8_shiba_ksu\`.

3. **Syndrome-Guided MST & Kasami Golay Gate Protocol (`v54_5`)**:
   - Aperiodic routing decisions must compute Kasami Golay syndromes over 24-bit codewords to detect and correct routing perturbations.
   - Minimum Spanning Tree (MST) weights derived from live measured latency across Anchor-1, Edge-1, and Edge-2.
   - 3-Party Bell Witness: Aperiodic state transitions require correlated entanglement witness verification across all three nodes ($S > 2.0$, CHSH inequality).

4. **Muse Zero-Unmeasured Mandate on Root & Accelerator Telemetry**:
   - All root and accelerator telemetry endpoints (`/api/v1/p8_root/hardware_audit`, `/api/v1/p8_root/governor`, and `Tools 185..204`) must query live device sysfs/devfs paths via `ksud debug su`:
     - Frequencies: `/sys/devices/system/cpu/cpufreq/policy*/scaling_cur_freq`
     - GPU load/clock: `/sys/devices/platform/20c00000.callisto/`
     - TPU temperature/power: `/sys/class/edgetpu/`
   - When Edge-2 is unreachable or offline, endpoints MUST return explicit `"status": "UNMEASURED/OFFLINE"`. Never emit synthetic clocks, hardcoded temperatures, or fabricated benchmark numbers.
