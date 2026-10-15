#!/bin/sh
TARGET_HOST="127.0.0.1"
TARGET_PORT="8097"
DELTA_FILE="/sdcard/act_omega/gradient_delta.bin"
LAYER_FILE="/sdcard/act_omega/layer.bin"

# 256-byte deterministic STE layer projection for Tensor G3
P8_B64="AAgLCAD49fgBCQsH//f1+QMKCwX99vX7BQsKA/v19v0GCwkC+vX3/ggLCAD49fgACQsH//f1+QEKCwX99vX7AwsKBPz19vwECwoC+vX2/gYLCQD59fcABwsHAPf1+QAJCwb+9vX6AgoLBPz19fwECwoD+vX2/QYLCQH59ff/BwsIAPj1+AAICwb+9/X6AgkLBfz29fsECgsD+/X2/QULCgH59ff/BwsJAPj1+AAICwj/9/X5AQkLB/329fsDCgsF+/X2/QULCgP69ff+BgsJAvj1+AAICwgA9/X5AQkLB//29fsDCgsF/fX2/AQLCgT89fb+BgsKAvr1+AAHCwgA+Q=="

echo "${P8_B64}" | base64 -d > "${LAYER_FILE}"
rm -f "${DELTA_FILE}"
for i in $(seq 1 30); do
    cat "${LAYER_FILE}" >> "${DELTA_FILE}"
done
rm -f "${LAYER_FILE}"

echo "Pixel 8 STE Gradient Delta Ready: $(ls -l ${DELTA_FILE} | awk '{print $5}') bytes"

(
    echo "PUSH_GRADIENTS:Pixel 8 (shiba, Tensor G3)"
    sleep 1
    cat "${DELTA_FILE}"
) | nc "${TARGET_HOST}" "${TARGET_PORT}"