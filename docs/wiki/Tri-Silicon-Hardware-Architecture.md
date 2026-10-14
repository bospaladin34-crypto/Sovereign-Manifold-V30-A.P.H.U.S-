# Tri-Silicon Hardware & Affinity Architecture (`APhus-1.0-A`)

The `APhus-1.0-A` cluster unites three physical compute nodes over low-latency USB-C ADB and LAN TCP bridges into a 25-core (29-thread), 3-GPU, 38 GB heterogeneous compute manifold.

## 1. Node 1: Lenovo LOQ 15IAX9 (`garlock00` / `APhus-1.0-A`)
- **CPU:** Intel Core i5-12450HX (`4x` Golden Cove P-cores @ up to `4.4 GHz` + `4x` Gracemont E-cores, `12 MB` L3 cache, AVX2/VNNI).
- **GPU:** NVIDIA GeForce RTX 3050 6GB Laptop GPU (`2,048` CUDA cores, `64` Tensor cores, **PCIe Resizable BAR [ReBAR] enabled**).
- **Memory:** `12 GB DDR5` + `64 MB` C-ABI zero-copy ring (`Global\ACT_OMEGA_E8_HYPER_MANIFOLD`).

## 2. Node 2: Google Pixel 10 (`frankel_beta`, Serial `58170DLCR0004V`)
- **SoC:** Google Tensor G5 (`Laguna`, 3nm TSMC, 8 cores: `1x Cortex-X4 @ 3.78 GHz`, `3x Cortex-A725 @ 3.05 GHz`, `2x Cortex-A725 @ 3.05 GHz`, `2x Cortex-A520 @ 2.25 GHz`).
- **GPU:** Imagination PowerVR D-Series DXT-48-1536 @ `1094 MHz` (`6` Compute Units, **Vulkan `1.4.344`**, `11.27 GB` Vulkan Heap 0).
- **Memory:** `12 GB LPDDR5` (`12.11 GB` total) + `128 GB UFS`.

## 3. Node 3: Google Pixel 8 (`shiba_beta`, Serial `3A121FDJH00BW5`)
- **SoC:** Google Tensor G3 (`Zuma`, 4nm, 9 cores `ARMv9-A`: `1x Cortex-X3 @ 2.91 GHz`, `4x Cortex-A715 @ 2.37 GHz`, `4x Cortex-A510 @ 1.70 GHz`, Governor `sched_pixel`).
- **GPU:** ARM Mali-G715 @ `890 MHz • 7 cores` (`Valhall`, **`4.00 MB` Total L2 Cache**, `256-bit` bus, `896 FP32 ALUs`) + Google TPU.
- **Memory:** `8 GB Micron LPDDR5` + **`3.97 GB ZRAM`** + `128 GB Micron UFS`.