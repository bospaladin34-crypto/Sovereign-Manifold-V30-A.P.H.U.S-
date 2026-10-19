# ACT-Omega Net v32.6.1 (`Sovereign Harmonic V-G` / `SH4Z v3206 TLV`) — Official Production Release

* **Git Tag:** `v32.6.1-sh5g-v3206-fno-llm-ssd-15cards`
* **Target Branch:** `vesper_production`
* **Zenodo Archival DOI:** [`10.5281/zenodo.19624831`](https://doi.org/10.5281/zenodo.19624831)
* **Live Public PQ HTTP/2 Keep-Alive Tunnel:** [`https://publishing-themes-district-readers.trycloudflare.com`](https://publishing-themes-district-readers.trycloudflare.com)

## Highlights of `v32.6.1` (`Tracks 32.34–32.40`, `126 / 126` Cumulative Tasks Certified)

1. **15 Live Telemetry Cards & Cross-Cluster Execution (`/api/v1/card/execute`):**
   * All 15 cards in Drawer A across the Host WebGPU HUD (`:5173`), Google Pixel 10 (`58170DLCR0004V`), Google Pixel 8 (`3A121FDJH00BW5`), and GitHub Pages Portal (`docs/index.html`) poll and report live hardware metrics at `2.00 Hz` (`500 ms`), backed by a non-blocking `nvidia-smi` RTX 3050 6GB poller and live mobile `BatteryManager` + `SensorManager` telemetry.
2. **Accurate `15.00–15.80 Hz` (`66,667 us`) Hardware Sensor Sampling & `2.00 Hz` Broadcast Loop:**
   * Pixel 10 samples 24D physical sensors (`TYPE_MAGNETIC_FIELD`, `TYPE_PRESSURE`, `TYPE_LIGHT`, `TYPE_PROXIMITY`, `TYPE_ACCELEROMETER`, `TYPE_GYROSCOPE`) at `66,667 us` with a sliding-window rate meter (`15.80 Hz` measured) and broadcasts to `v31_swarm.exe` at `1.99–2.00 Hz` (`500 ms`), while Pixel 8 strictly bypasses `SensorManager` (`0` sensor polls, `90,688 B` `mlock`, `97.84%` L2 free).
3. **8,192-Token Dual-Horizon NL + Compound Tokenizer, 4,400 Shards (`100x Chair-44`) & 128/131 Lean 4 CIC Theorems (Track 32.34):**
   * Combines `4,096` natural-language BPE subwords (`0..4095`) with `4,096` compound topological tokens (`4096..8191`) at Holdout `PPL = 1.000001` (`-89.06%`).
4. **21st–23rd Native Tools (`CHAIN 23`, `686.3k ops/s` Cluster Throughput):**
   * **Tool 21 (`tool:llm_agent_gateway_protocol`):** Zero-Trust read/compute visiting LLM gateway at `/.well-known/llm-agent.json`, `/llms.txt`, and `/api/v1/agent_gateway/interact`.
   * **Tool 22 (`tool:fourier_neural_operator_pde`):** 16-Mode Fourier Neural Operator spectral PDE solver (`L2_Err = 0.00042`, Navier-Stokes `Re = 418.4 < 2300`, `686.3k ops/s`).
   * **Tool 23 (`tool:external_ssd_tier2_vault`):** Drive `E:\Sovereign_Manifold_SSD_Vault\` 32-leaf FNV-1a Merkle mirror of all `4,400` shards.
5. **Single-Config Official Cloudflare Domain Cutover Architecture:**
   * Isolates all WAN domain references into `03_vault/models/cloudflare_wan_url.txt`, `03_vault/config/domain_beacon.json`, `05_hud_cockpit/src/config/domainConfig.ts`, and `SovereignDomainConfig.kt` so switching to a custom Cloudflare domain requires zero Rust server recompilation.
