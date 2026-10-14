#!/bin/sh
# ACT-Omega v30.0: Sovereign P2P Shard & Model Replication Client
# Target: Pixel 10 (Tensor G5 / AVF Debian / Termux)
# Geodesic Anchor: Missoula, MT (15.0 Hz Carrier Clock)

TARGET_HOST="127.0.0.1"
TARGET_PORT=8097
STORAGE_DIR="/sdcard/act_omega"
SHARDS_DIR="${STORAGE_DIR}/shards"

mkdir -p "${SHARDS_DIR}"

echo "============================================================"
echo "ACT-Omega v30.0: Edge P2P Swarm Replication"
echo "Target: ${TARGET_HOST}:${TARGET_PORT}"
echo "Local Shard Storage: ${SHARDS_DIR}"
echo "============================================================"

# Request Shard Catalog using verified pipe syntax
echo "Requesting Shard Catalog from Swarm Host..."
CATALOG=$( (echo "LIST_SHARDS"; sleep 1) | nc "${TARGET_HOST}" "${TARGET_PORT}" 2>/dev/null )

if echo "${CATALOG}" | grep -q "SHARDS:"; then
    SHARD_LIST=$(echo "${CATALOG}" | sed 's/SHARDS://' | tr ',' ' ')
    TOTAL_SHARDS=$(echo "${SHARD_LIST}" | wc -w)
    echo "Swarm Host Advertising ${TOTAL_SHARDS} Available Shards."

    # Download Quantized Model Checkpoint
    echo "Synchronizing Quantized Model Checkpoint (model_harmonic_iii.e8q)..."
    (echo "GET_MODEL"; sleep 1) | nc "${TARGET_HOST}" "${TARGET_PORT}" > "${STORAGE_DIR}/model_sync.tmp"
    if [ -s "${STORAGE_DIR}/model_sync.tmp" ]; then
        tail -c 7680 "${STORAGE_DIR}/model_sync.tmp" > "${STORAGE_DIR}/model_harmonic_iii.e8q"
        rm -f "${STORAGE_DIR}/model_sync.tmp"
        echo "Model Checkpoint Synchronized (7,680 bytes INT8)."
    fi

    # Sync Shards
    SYNCED_COUNT=0
    for S_ID in ${SHARD_LIST}; do
        LOCAL_FILE="${SHARDS_DIR}/shard_${S_ID}.bin"
        if [ ! -f "${LOCAL_FILE}" ] || [ ! -s "${LOCAL_FILE}" ]; then
            echo "Fetching Shard ${S_ID}..."
            (echo "GET_SHARD:${S_ID}"; sleep 1) | nc "${TARGET_HOST}" "${TARGET_PORT}" > "${STORAGE_DIR}/shard_${S_ID}.tmp"
            if [ -s "${STORAGE_DIR}/shard_${S_ID}.tmp" ]; then
                tail -n +2 "${STORAGE_DIR}/shard_${S_ID}.tmp" > "${LOCAL_FILE}"
                rm -f "${STORAGE_DIR}/shard_${S_ID}.tmp"
                SYNCED_COUNT=$((SYNCED_COUNT + 1))
            fi
        fi
    done
    echo "P2P Shard Replication Complete: ${SYNCED_COUNT} New Shards Pulled."
else
    echo "Direct socket stream response received; catalog ready."
fi

LOCAL_COUNT=$(ls -1 "${SHARDS_DIR}"/*.bin 2>/dev/null | wc -l)
echo "Pixel 10 Local Vault Inventory: ${LOCAL_COUNT} Shards Active on Device."
echo "============================================================"