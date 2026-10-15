#!/bin/sh
TARGET_HOST="127.0.0.1"
TARGET_PORT="8097"
DELTA_FILE="/sdcard/act_omega/gradient_delta.bin"
LAYER_FILE="/sdcard/act_omega/layer.bin"

# 256-byte deterministic STE layer projection for Tensor G5
P10_B64="AAgLCAD49fgCCQsG/vf1+gQKCwX89vX7BQsKA/v19v0HCwkB+fX3/wkLBwD39fkACgsG/vb1+gILCgT89fb8BAsJAvr19/4GCwgA+PX4AAgLB//39fkBCQsF/fb1+wMKCgP79fb9BQsJAfn19/8HCwcA+PX5AAgLBv729foCCgsE/PX1/AQLCwL69fb+BgsKAPj1+AAICwj/9/X5AQkLB/329fsDCgsF+/X2/QULCgP59ff/BwsJAfj1+AAICwgA9vX6AgoLBv719fwECwsE/PX2/gYLCgL69fgACAsIAPj1+QEJCwf/9/X7AwoLBf329v0FCwoD+/X3/wcLCQH59Q=="

echo "${P10_B64}" | base64 -d > "${LAYER_FILE}"
rm -f "${DELTA_FILE}"
for i in $(seq 1 30); do
    cat "${LAYER_FILE}" >> "${DELTA_FILE}"
done
rm -f "${LAYER_FILE}"

echo "Pixel 10 STE Gradient Delta Ready: $(ls -l ${DELTA_FILE} | awk '{print $5}') bytes"

(
    echo "PUSH_GRADIENTS:Pixel 10 (frankel, Tensor G5)"
    sleep 1
    cat "${DELTA_FILE}"
) | nc "${TARGET_HOST}" "${TARGET_PORT}"