#!/bin/sh
# ACT-Omega v30.0: Pixel 8 (shiba_beta, Tensor G3 Zuma 4nm + Mali-G715 4.00MB L2) Continuous Trainer
# CPU Affinity: taskset 1f0 (1x Cortex-X3 + 4x Cortex-A715) | Carrier Phase: 0.15000 rad
echo "[P8 Compute] Starting L2-Pinned 1.58-Bit + INT8 In-Flight Training Loop (PID: $$)..."
while true; do
  cat /data/local/tmp/sierpinski_158_manifold.e8t /data/local/tmp/model_harmonic_iii_240.e8q > /dev/null 2>&1
  taskset 1f0 sh /sdcard/act_omega/edge_train_worker.sh > /dev/null 2>&1
  sleep 20
done
