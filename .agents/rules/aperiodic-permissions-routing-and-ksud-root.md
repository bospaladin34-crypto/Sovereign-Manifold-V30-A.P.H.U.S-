---
trigger: glob
globs: "01_l0_rust/src/v54_5*.rs, 01_l0_rust/src/v55*.rs, 01_l0_rust/src/v56*.rs, 04_edge_silicon/**/*, pixel8_shiba_ksu/**/*, 00_control/pixel8_shiba_ksu/**/*"
description: "Aperiodic Permissions Routing (APR) 4-Ring Capability Stratifier (Rings A0..A3, OWNED_SILICON_ONLY) and Pixel 8 (3A121FDJH00BW5) KernelSU-Next ksud 3.4.2 root governance with untouched factory stock slot _b rollback invariance."
---
# Aperiodic Permissions Routing & Pixel 8 Root Governance Rules (ACT-Omega Net v70.0.0 | CHAIN 316 | 840/840 QED)

1. **APR 4-Ring Capability Stratifier (`OWNED_SILICON_ONLY`)**:
   - **Ring A0 — Bare-Metal Root & Hardware Accelerators (`OWNED_SILICON_ONLY`)**:
     - Highest privilege boundary. Restricted exclusively to verified, physically owned silicon cluster hardware: Anchor-1 LOQ 15 (`Intel i5-12450HX`, `RTX 3050 6GB`), Edge-1 Pixel 10 (`Tensor G5`, ADB `58170DLCR0004V`), and Rooted Edge-2 Pixel 8 (`Tensor G3 zuma`, ADB `3A121FDJH00BW5` / `192.168.137.8:5555`).
     - Kernel execution context: `uid=0(root) gid=0(root) groups=0(root) context=u:r:ksu:s0` via KernelSU-Next `ksud 3.4.2` (uapi: 5, ksu fd: 6).
     - Direct hardware character devices: `/dev/edgetpu-soc` (`487,1`), `/dev/mali0` (`10,86`, `4.00 MB` Mali-G715 L2 cache pinning via `mlock()`), `/dev/kvm` (`10,232`), and CPU frequency scaling governors (`policy0`, `policy4`, `policy8`).
     - **Strict Non-Negotiable Invariant**: Remote execution, unowned cloud hardware, third-party sandboxes, or simulated endpoints are strictly barred from Ring A0.
   - **Ring A1 — Sovereign Runtime & Connectome Core (Native / NDK / C++)**:
     - Core autopoietic Native runtime host (`v31_swarm.exe` on `:8097` and `:5173`) with NDK / C++ bindings, zero-bracket L0 Rust modules (`v33..v70+`), `84,480` dendritic pyramidal neurons (`neurons_v6900_84480.npage`, `10,813,440 B`), `1,920` Chair-44 columns, `4,055,040` total synapses, and `262,144` ($2^{18}$) bijected cachelines (`16.00 MiB`).
   - **Ring A2 — Privileged IPC, Edge Sync & Operator Interface (Managed / JVM / ART)**:
     - Managed Android Runtime (ART) and JVM services (`MainActivity.kt`), authenticated operator gate (`/api/v1/auth/operator_vault_gate`), root governor API (`/api/v1/p8_root/hardware_audit`, `/api/v1/p8_root/governor`), Dual-Pixel telemetry synchronization (`S48..S63` Pixel 10, `S64..S79` Pixel 8), Cloudflare D1 Vault batching, and Universal `E:\` / `F:\` Vault persistence.
     - **Strict Authentication Gate**: Mandatory `X-Sovereign-Operator-Key` HTTP header over loopback (`127.0.0.1`), key verified against external `C:\Users\Nbell\.act_omega_operator_vault_key` (`>= 24` chars). `?key=` URL query parameters are rejected.
   - **Ring A3 — Public Edge, WebGPU HUD & Autonomous Workers**:
     - Read-only WebGPU HUD (`:5173`, `05_hud_cockpit`, `docs/`, `index.html`), Cloudflare Edge Durable Object (`worker_vpc_shadow_v3700.js` on `act-omega-net.dev`), crawler models (SSR pre-rendered `#root`), and unprivileged subagents.

2. **Pixel 8 (`3A121FDJH00BW5`) `ksud 3.4.2` Root Governance & Rollback Invariance**:
   - Active execution slot: Slot `_a` running patched boot image (`7BC59BA6F08639AF1C2F90E80EADCF536810746C52E6770A8D5CE5EB28A0FFF2`) under KernelSU-Next `ksud 3.4.2`.
   - Invariant Stock Fallback Slot: Slot `_b` MUST remain 100% untouched factory stock Android 17 QPR2 Beta (`init_boot.img` SHA-256 `84ECFA41044D301D096B31657430F693D605C88DB77969E8B604B804C8D5E55D`).

3. **Muse Zero-Unmeasured Mandate on Root & Accelerator Telemetry**:
   - All root and accelerator telemetry endpoints must query live device sysfs/devfs paths via `ksud debug su`; when Edge-2 is unreachable or offline, endpoints MUST return explicit `"status": "UNMEASURED/OFFLINE"`.
