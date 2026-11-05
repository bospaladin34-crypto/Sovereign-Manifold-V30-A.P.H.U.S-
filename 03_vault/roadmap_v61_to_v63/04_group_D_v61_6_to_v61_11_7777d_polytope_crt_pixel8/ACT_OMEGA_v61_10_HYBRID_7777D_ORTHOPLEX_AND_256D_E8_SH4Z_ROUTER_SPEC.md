# ACT-Omega v61.10: Two-Level Hybrid `7777D Orthoplex (.o7777)` + `256D E8 (.sh4z)` Router & Sparse MatVec Architecture

* **One-Command PowerShell 5.1 Runner:** `Invoke_v61_10_Hybrid_7777D_Orthoplex_And_256D_E8_SH4Z_Router_Test.ps1` (`0` backticks)
* **Lab Output Directory:** `C:\ACT_OMEGA_7777D_ORTHOPLEX_LAB\hybrid_sh4z_index\`
* **Cold Vault Receipt Path:** `E:\ACT_OMEGA_COLD_VAULT\7777d_orthoplex_receipts\v61_10_hybrid_7777d_e8_sh4z_router_receipt.json`

## 1. Why Combining `7777D Orthoplex (.o7777)` + `256D E8 (.sh4z)` Solves the Sparsity-vs-SNR Tradeoff

In our `v61.9` hardware run (`PXL_20261102_184503403.jpg`), we discovered a fundamental duality:
1. **Macro-Horizon `7777D` Orthoplex (`β_7777`):** Classifies an entire `7,777`-coordinate horizon (`30.38 KB`) to its nearest signed Cross-Polytope pole $v^* \in [0..15,553]$ and CRT fiber $(r_1, r_2, r_3) \in \mathbb{Z}_7 \times \mathbb{Z}_{11} \times \mathbb{Z}_{101}$ at **`1,393.35 Million coords/s` (`5.58 µs`/frame)**, boosting zero-sparsity to **`37.46%` (`E4B-it`)** and **`44.14%` (`12B-it`)**, but using a single scalar scale $\gamma_{7777}$ across all `7,777` weights caps reconstruction SNR at `6.40 dB` (`E4B-it`) and `3.46 dB` (`12B-it`).
2. **Micro-Horizon `256D E8` (`.sh4z` `68-Byte` Blocks):** Dedicates an independent `float32` scale $\gamma_{256}$ to every `256` weights (`31` local scales per `7,777D` horizon), preserving high local SNR across heavy-tailed attention/MLP channels.

### The Two-Level Hybrid `.o7777 + .sh4z` Hierarchy

$$\underbrace{\text{Level 1: } 7777\text{D Orthoplex Routing Header (16 Bytes)}}_{\text{Pole } v^* \in [0..15,553], \text{ CRT } (r_1, r_2, r_3), \text{ Top-16 Active Sub-Block Bitmask}} \;\longrightarrow\; \underbrace{\text{Level 2: } 31 \times 256\text{D E8 } (\text{.sh4z}) \text{ Micro-Blocks (68 Bytes each)}}_{\text{Per-block scale } \gamma_b + 64\text{B packed 2-bit trits (skips cold blocks!)}}$$

- **Exact Address Decomposition (`15,554 / 15,554` Bijective):**
  Given any Orthoplex pole $v^* \in [0..15,553]$:
  $$d^* = \lfloor v^* / 2 \rfloor = (3333 r_1 + 2828 r_2 + 1617 r_3) \bmod 7777$$
  $$\text{E8 Sub-Block Index } b^* = \lfloor d^* / 256 \rfloor \in [0..30], \qquad \text{In-Block Lane } k^* = d^* \bmod 256 \in [0..255]$$

## 2. The Six Practical Batteries in `Invoke_v61_10_Hybrid_7777D_Orthoplex_And_256D_E8_SH4Z_Router_Test.ps1`

| Battery | Practical Test Suite | What It Verifies on Your `LENOVO LOQ 15` |
| :--- | :--- | :--- |
| **Battery 1** | **Real `gemma-4-E4B-it` Hybrid `.o7777 + .sh4z` Compiler** | Compiles `surgical_layer0_bf16_slice_64kb.bin` into a `8,768-byte` Hybrid Vault (`4 × 16 B` `7777D` Orthoplex headers + `128 × 68 B` `256D E8` `.sh4z` blocks), measuring the **SNR gain (`+dB`)** over flat `7777D` and the `$L_2$ Energy Retained (%)` in the Top-50% routed E8 sub-blocks. |
| **Battery 2** | **Real `gemma-4-12B-it` Hybrid `.o7777 + .sh4z` Compiler** | Compiles `gemma-4-12B-it`'s `64 KB` Layer-0 `BF16` slice into `gemma-4-12B-it_layer0_hybrid_o7777_sh4z.bin` (`8,768 B`) and measures local-scale `256D E8` SNR recovery vs. flat `7777D`. |
| **Battery 3** | **Exhaustive `15,554 / 15,554` Orthoplex Pole $\to$ `256D E8` Sub-Block Bijection** | Verifies that every Orthoplex pole $v \in [0..15,553]$ reconstructs via CRT `(3333, 2828, 1617)` and maps bijectively to `(subBlockIdx * 256 + inBlockOffset) == flatAxis` across all **`77,952,685` `256D E8` blocks** (`2,514,603` macro-`7777D` pages) of the combined `19.96B` Gemma 4 vault. |
| **Battery 4** | **`100,000`-Query Two-Level Hybrid Router Throughput Benchmark** | Uses the `7777D` CRT + Orthoplex header to route queries directly to the dominant `256D E8` sub-block and its 3 CRT fiber neighbors (skipping **`87.1%`** of cold `256D E8` blocks) and measures **effective Billion weights/sec**. |
| **Battery 5** | **Dense `7777D` vs. Hybrid Orthoplex-Routed `256D E8` MatVec Speedup** | Benchmarks `10,000` full `7,777D` dot products against `10,000` Orthoplex-routed `256D E8` micro-block dot products and reports the exact wall-clock speedup factor (`x`). |
| **Battery 6** | **Cryptographic JSON Receipt & Cold Vault (`E:`) Mirror** | Writes `v61_10_hybrid_7777d_e8_sh4z_router_receipt.json` to `C:\ACT_OMEGA_7777D_ORTHOPLEX_LAB\receipts\` and mirrors it to `E:\ACT_OMEGA_COLD_VAULT\7777d_orthoplex_receipts\`. |

## 3. One-Line Command to Run in PowerShell

```powershell
powershell -ExecutionPolicy Bypass -File "$HOME\Downloads\Invoke_v61_10_Hybrid_7777D_Orthoplex_And_256D_E8_SH4Z_Router_Test.ps1"
```
