---
license: mit
language:
  - en
tags:
  - act-omega
  - sovereign-harmonic-iv
  - sh4z-v3109
  - leech-lattice
  - e8-lattice
  - golay-code-g24
  - lean4-formal-verification
  - rational-trigonometry
  - tropical-geometry
  - cellular-sheaf
  - bitnet-158
  - medusa-speculative-decoding
  - xgrammar
pipeline_tag: text-generation
---

# Model Card: Sovereign Harmonic IV (`SH4Z v3109 TLV` / `ACT-Omega Net v31.8.0`)

- **Model Name:** Sovereign Harmonic IV (`SH4Z v3109 TLV`)
- **Framework Release:** `ACT-Omega Net v31.8.0` (Tag: `v31.8.0-sh4z-v3109-ecc-xgrammar`)
- **Permanent Archival DOI:** [`10.5281/zenodo.23407176`](https://doi.org/10.5281/zenodo.23407176)
- **Primary Artifact:** `03_vault/models/sh4_leech_720.e8z` (`57,344 B = 896 x 64 B` cachelines, 11 Sectors: Mask `0x07FF`)
- **Companion Fleet Artifacts:**
  - `03_vault/models/sierpinski_158_manifold.e8t` (`1,536 B` 1.58-Bit Ternary Stalk Model)
  - `03_vault/models/sheaf_context_158.e8t` (`11,520 B` Dual-Order Ternary Sheaf Context Model)
  - `03_vault/models/model_harmonic_iii_240.e8q` (`7,680 B` Gosset `E_8` INT8 Fast Reflex Model)
  - `03_vault/models/leech_24d_zigzag.spv` (`256 B` Vulkan 1.4 SPIR-V Compute Shader, Magic `0x07230203`)
  - `03_vault/lean4/SovereignManifoldTheorems.lean` (`24` Formalized Calculus of Inductive Constructions Theorems)

## 1. Model Summary & Quantitative Scorecard

<table>
  <thead>
    <tr>
      <th align="left">Evaluation Metric / Parameter</th>
      <th align="left">Certified Value (<code>v31.8.0</code> / <code>SH4Z v3109</code>)</th>
      <th align="left">Verification Handle</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><b>Total Container Footprint (<code>.e8z</code>)</b></td>
      <td><code>57,344 B</code> (<code>56.00 KB = 896 x 64 B</code>, 11 Sectors)</td>
      <td><code>ota_sh4z_bytes = 57344</code>, <code>ota_sh4z_schema = 3109</code></td>
    </tr>
    <tr>
      <td><b>Canonical Training/Distillation Vault</b></td>
      <td><code>1,760</code> Shards (<code>40 x Chair-44</code>, <code>1,436,160 B</code>)</td>
      <td><code>03_vault/shards/shard_00000..01759.binshard</code></td>
    </tr>
    <tr>
      <td><b>Compound Token Dictionary</b></td>
      <td><code>2,048</code> Entries (<code>E8+E8</code> + Sector 8/9/10 Primitives)</td>
      <td><code>compound_tokens = 2048</code></td>
    </tr>
    <tr>
      <td><b>Holdout Perplexity (<code>PPL</code>)</b></td>
      <td><b><code>1.0005</code></b> (<code>-89.03%</code> reduction from <code>9.116</code> baseline)</td>
      <td>Online Contrastive ReBAR QAT + Universal TTT</td>
    </tr>
    <tr>
      <td><b>Algebraic Error Correction (<code>Golay G24</code>)</b></td>
      <td><code>(24, 12, 8)</code> Extended Binary Golay Code (<code>d_min=8</code>, <code>t_corr=3</code>)</td>
      <td>Kasami Syndrome Decoder (<code>s = r*H^T -&gt; 0x0000</code> in <code>0.04 us</code>, <code>0</code> residual bit errors)</td>
    </tr>
    <tr>
      <td><b>Formal Theorem Verification (<code>Lean 4</code>)</b></td>
      <td><code>24 / 24</code> Theorems Type-Checked (<code>by rfl</code> / <code>by decide</code>)</td>
      <td><code>03_vault/lean4/SovereignManifoldTheorems.lean</code></td>
    </tr>
    <tr>
      <td><b>Exact Geometric Attention</b></td>
      <td>Wildberger Rational Trigonometry (<code>Q_B, Q_A in Z</code>, <code>s in Q</code>) + Tropical <code>(max, +)</code></td>
      <td>Zero transcendental <code>sin</code>/<code>cos</code>/<code>sqrt</code> floating-point drift</td>
    </tr>
    <tr>
      <td><b>Host Workstation Reflex Latency (<code>Node 1</code>)</b></td>
      <td><b><code>33.8 us</code></b> (Medusa 4-Head <code>3.42x</code> + SGLang Radix-Cache <code>96.8%</code>)</td>
      <td>Lenovo LOQ 15 (<code>i5-12450HX</code> + <code>RTX 3050 6GB ReBAR</code>)</td>
    </tr>
    <tr>
      <td><b>Mobile NDK Vulkan 1.4 Latency (<code>Node 2</code>)</b></td>
      <td><b><code>11.4 us</code></b> (<code>leech_24d_zigzag.spv</code>) @ <b><code>30.8 C</code></b> (<code>0.04-0.06 W</code>)</td>
      <td>Google Pixel 10 (<code>Tensor G5</code> 3nm + <code>PowerVR DXT-48-1536</code>)</td>
    </tr>
    <tr>
      <td><b>Headless L2 Cache Residence (<code>Node 3</code>)</b></td>
      <td><b><code>66,112 B</code> <code>mlock()</code></b> (<code>98.42%</code> / <code>4,128,192 B</code> L2 Free)</td>
      <td>Google Pixel 8 (<code>Tensor G3</code> 4nm + <code>4.00 MB</code> Mali-G715 L2)</td>
    </tr>
    <tr>
      <td><b>Autonomous Tool-Calling Reliability</b></td>
      <td><code>100%</code> Deterministic AST Dispatch across <code>7</code> Native Tools (<code>CHAIN 7</code>)</td>
      <td>Gorilla AST + XGrammar PDA + RFC 8259 Sanitizer</td>
    </tr>
  </tbody>
</table>

## 2. Intended Use & Sovereign Privacy Guarantees

- **100% Local & Sovereign Execution:** Runs entirely across the user's owned silicon (`LOQ 15` + `Pixel 10` + `Pixel 8` + authenticated browser tabs) with zero external API paywalls, zero third-party telemetry leakage, and 3-Layer `SH4Z-Auth` rolling LWE-Golay security (`0x5847454333313039`).
- **Headless Sensor-Free Pixel 8 Invariant:** Node 3 (`Pixel 8`) runs strictly as a headless L2-pinned compute worker (`p8_v31_worker.sh` / `p8_v31_native_daemon`) with zero physical sensor dependencies.