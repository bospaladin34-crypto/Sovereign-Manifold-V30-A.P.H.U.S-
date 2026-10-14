#!/bin/sh
# ACT-Omega v30.0: Continuous Background In-Flight STE Trainer (Pixel 8)
echo "[P8 Compute] Starting Continuous In-Flight Training Loop (PID: $$)..."
while true; do
    sh /sdcard/act_omega/edge_train_worker.sh > /dev/null 2>&1
    sleep 20
done