#!/bin/sh
# ACT-Omega v30.0: Pixel 10 (frankel_beta, Tensor G5 Laguna 3nm) Edge Worker
# CPU Affinity: taskset fc (1x Cortex-X4 + 5x Cortex-A725) | Carrier Phase: 0.17259 rad
TARGET_HOST="127.0.0.1"
TARGET_PORT="8097"
DELTA_FILE="/sdcard/act_omega/gradient_delta.bin"
E8T_FILE="/data/local/tmp/sierpinski_158_manifold.e8t"
cp /data/local/tmp/model_harmonic_iii_240.e8q "${DELTA_FILE}" 2>/dev/null || true
echo "[Pixel 10 Tensor G5] Armed 1,536B .e8t & 7,680B .e8q (Phase: 0.17259 rad)"
(
  echo "PUSH_GRADIENTS:Pixel 10 (frankel, Tensor G5 | Window 3030 | Phase 0.17259)"
  sleep 1
  cat "${DELTA_FILE}"
) | taskset fc nc "${TARGET_HOST}" "${TARGET_PORT}" 2>/dev/null || true
