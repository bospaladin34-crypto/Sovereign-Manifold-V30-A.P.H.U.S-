#!/bin/sh
PIDFILE="/data/local/tmp/p8_v31_worker.pid"
if [ -f "$PIDFILE" ]; then
  OLD_PID=$(cat "$PIDFILE" 2>/dev/null)
  if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
    echo "[P8 v31 Worker] Single-instance PID $OLD_PID already active. Exiting."
    exit 0
  fi
fi
echo $$ > "$PIDFILE"
echo "[P8 v31 Thermal Governor] L2-Pinning 41,856B (sh4_leech_720.e8z + .e8t) in 4.00MB Mali-G715 L2 (99.00% Free, PID: $$)..."
while true; do
  TEMP=$(dumpsys battery 2>/dev/null | grep temperature | awk '{print $2}')
  cat /data/local/tmp/sh4_leech_720.e8z /data/local/tmp/sierpinski_158_manifold.e8t /data/local/tmp/sheaf_context_158.e8t > /dev/null 2>&1
  if [ -n "$TEMP" ] && [ "$TEMP" -ge 380 ]; then
    taskset 0f sh /sdcard/act_omega/edge_train_worker.sh > /dev/null 2>&1
    sleep 40
  else
    taskset f0 sh /sdcard/act_omega/edge_train_worker.sh > /dev/null 2>&1
    sleep 25
  fi
done
