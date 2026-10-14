#!/bin/sh
# ACT-Omega v30.0: Pixel 8 (Tensor G3 Zuma) Thermal-Aware L2-Pinned Trainer
# Rests Cortex-X3 prime core; uses 4x Cortex-A715 (f0) < 38.0C and 4x Cortex-A510 (0f) >= 38.0C
echo "[P8 Thermal Governor] Starting L2-Pinned 13,056B Dual-Order Ternary Loop (PID: $$)..."
while true; do
  TEMP=$(dumpsys battery 2>/dev/null | grep temperature | awk "{print \$2}")
  cat /data/local/tmp/sierpinski_158_manifold.e8t /data/local/tmp/sheaf_context_158.e8t > /dev/null 2>&1
  if [ -n "${TEMP}" ] && [ "${TEMP}" -ge 380 ]; then
    taskset 0f sh /sdcard/act_omega/edge_train_worker.sh > /dev/null 2>&1
    sleep 40
  else
    taskset f0 sh /sdcard/act_omega/edge_train_worker.sh > /dev/null 2>&1
    sleep 25
  fi
done
