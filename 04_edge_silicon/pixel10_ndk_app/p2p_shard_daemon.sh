#!/bin/sh
# ACT-Omega v30.0: Autonomous P2P Shard & Model Replication Daemon
# Target: Google Pixel 10 (Tensor G5 / AVF Debian / Termux)
# Geodesic Anchor: Missoula, MT (15.0 Hz Carrier Clock)

TARGET_HOST="127.0.0.1"
TARGET_PORT=8097
STORAGE_DIR="/sdcard/act_omega"
SHARDS_DIR="${STORAGE_DIR}/shards"
LOG_FILE="${STORAGE_DIR}/daemon.log"
PID_FILE="${STORAGE_DIR}/daemon.pid"

mkdir -p "${SHARDS_DIR}"

case "$1" in
    --stop)
        if [ -f "${PID_FILE}" ]; then
            PID=$(cat "${PID_FILE}")
            kill "${PID}" 2>/dev/null
            rm -f "${PID_FILE}"
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] P2P Daemon Stopped (PID: ${PID})" >> "${LOG_FILE}"
            echo "P2P Daemon Stopped."
        else
            echo "No running daemon PID file found."
        fi
        exit 0
        ;;
    --status)
        if [ -f "${PID_FILE}" ]; then
            PID=$(cat "${PID_FILE}")
            if ps -p "${PID}" >/dev/null 2>&1 || ps | grep -q "${PID}"; then
                echo "P2P Daemon is RUNNING (PID: ${PID})"
            else
                echo "P2P Daemon is DEAD (Stale PID: ${PID})"
            fi
        else
            echo "P2P Daemon is NOT RUNNING"
        fi
        LOCAL_SHARDS=$(ls -1 "${SHARDS_DIR}"/*.bin 2>/dev/null | wc -l)
        echo "Local Shard Inventory: ${LOCAL_SHARDS} active on device."
        echo "Recent Log Entries:"
        tail -n 10 "${LOG_FILE}" 2>/dev/null
        exit 0
        ;;
esac

# Check for existing instance
if [ -f "${PID_FILE}" ]; then
    OLD_PID=$(cat "${PID_FILE}")
    kill "${OLD_PID}" 2>/dev/null
    rm -f "${PID_FILE}"
fi

echo $$ > "${PID_FILE}"
echo "============================================================" >> "${LOG_FILE}"
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Autonomous P2P Daemon Activated (PID: $$)" >> "${LOG_FILE}"
echo "Target Swarm Host: ${TARGET_HOST}:${TARGET_PORT}" >> "${LOG_FILE}"
echo "Storage Path: ${SHARDS_DIR}" >> "${LOG_FILE}"
echo "============================================================" >> "${LOG_FILE}"

CYCLE=0

while true; do
    CYCLE=$((CYCLE + 1))
    
    # 1. Test Host Connectivity via verified subshell netcat
    PONG=$( (echo "PING"; sleep 1) | nc "${TARGET_HOST}" "${TARGET_PORT}" 2>/dev/null )
    
    if [ "${PONG}" = "PONG" ]; then
        # 2. Query Shard Catalog
        CATALOG=$( (echo "LIST_SHARDS"; sleep 1) | nc "${TARGET_HOST}" "${TARGET_PORT}" 2>/dev/null )
        
        if echo "${CATALOG}" | grep -q "SHARDS:"; then
            SHARD_LIST=$(echo "${CATALOG}" | sed 's/SHARDS://' | tr ',' ' ')
            NEW_COUNT=0
            
            for S_ID in ${SHARD_LIST}; do
                LOCAL_FILE="${SHARDS_DIR}/shard_${S_ID}.bin"
                if [ ! -f "${LOCAL_FILE}" ] || [ ! -s "${LOCAL_FILE}" ]; then
                    (echo "GET_SHARD:${S_ID}"; sleep 1) | nc "${TARGET_HOST}" "${TARGET_PORT}" > "${STORAGE_DIR}/shard_${S_ID}.tmp"
                    if [ -s "${STORAGE_DIR}/shard_${S_ID}.tmp" ]; then
                        tail -n +2 "${STORAGE_DIR}/shard_${S_ID}.tmp" > "${LOCAL_FILE}"
                        rm -f "${STORAGE_DIR}/shard_${S_ID}.tmp"
                        NEW_COUNT=$((NEW_COUNT + 1))
                    fi
                fi
            done
            
            if [ ${NEW_COUNT} -gt 0 ]; then
                TOTAL_LOCAL=$(ls -1 "${SHARDS_DIR}"/*.bin 2>/dev/null | wc -l)
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] Replicated ${NEW_COUNT} new shards (Total Local: ${TOTAL_LOCAL})." >> "${LOG_FILE}"
            fi
        fi

        # 3. Model Integrity Check (7,680 bytes INT8)
        MODEL_FILE="${STORAGE_DIR}/model_harmonic_iii.e8q"
        MODEL_SIZE=$(wc -c < "${MODEL_FILE}" 2>/dev/null || echo 0)
        
        if [ ! -f "${MODEL_FILE}" ] || [ "${MODEL_SIZE}" -ne 7680 ]; then
            (echo "GET_MODEL"; sleep 1) | nc "${TARGET_HOST}" "${TARGET_PORT}" > "${STORAGE_DIR}/model_sync.tmp"
            if [ -s "${STORAGE_DIR}/model_sync.tmp" ]; then
                tail -c 7680 "${STORAGE_DIR}/model_sync.tmp" > "${MODEL_FILE}"
                rm -f "${STORAGE_DIR}/model_sync.tmp"
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] Model Checkpoint Synchronized (7,680 B)." >> "${LOG_FILE}"
            fi
        fi

        # Log heartbeat every 12 cycles (~60 seconds)
        if [ $((CYCLE % 12)) -eq 0 ]; then
            TOTAL_LOCAL=$(ls -1 "${SHARDS_DIR}"/*.bin 2>/dev/null | wc -l)
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] Heartbeat: Swarm Online | ${TOTAL_LOCAL} Shards Active." >> "${LOG_FILE}"
        fi
    fi

    sleep 5
done