#!/usr/bin/env bash
# ACT-Omega Net v44.5.0 (SH4Z v4450 TLV) — Cross-Platform POSIX Lifecycle Orchestrator
# Compatible with Linux (Ubuntu/Debian/Arch/Fedora), macOS (Apple Silicon/Intel), WSL2, and Android Termux.
# Usage: ./sovereign-lifecycle.sh [ignite|halt|status|verify|cyclesync|ollama-test|anthropic-test|metrics]

set -u
HOST_URL="${ACT_OMEGA_HOST_URL:-http://127.0.0.1:8097}"
HUD_URL="${ACT_OMEGA_HUD_URL:-http://127.0.0.1:5173}"
WAN_URL="${ACT_OMEGA_WAN_URL:-https://act-omega-net.dev}"

cmd="${1:-status}"

case "$cmd" in
  status|sovereign-status)
    echo "=== ACT-OMEGA v44.5.0 CROSS-OS STATUS PROBE ==="
    curl -sS --max-time 4 "${HOST_URL}/api/v1/diagnostics/v44_self_profiler" || curl -sS --max-time 5 "${WAN_URL}/api/v1/diagnostics/v44_self_profiler"
    echo ""
    ;;
  verify)
    echo "=== ACT-OMEGA v44.5.0 6-LAYER TRUE-DATA & COMPATIBILITY AUDIT ==="
    curl -sS --max-time 4 "${HOST_URL}/api/v1/compat/matrix" || curl -sS --max-time 5 "${WAN_URL}/api/v1/compat/matrix"
    echo ""
    ;;
  cyclesync|handover)
    echo "=== ACT-OMEGA v44.5.0 .NPAGE SHM & CLOUDFLARE D1 SYNC ==="
    curl -sS --max-time 4 "${HOST_URL}/api/v1/shm/p8_npage_bridge"
    echo ""
    curl -sS --max-time 6 "${HOST_URL}/api/v1/cloudflare/d1_sync_10tables"
    echo ""
    ;;
  ollama-test)
    echo "=== OLLAMA API COMPATIBILITY TEST (/api/tags & /api/chat) ==="
    curl -sS --max-time 4 "${HOST_URL}/api/tags"
    echo ""
    ;;
  anthropic-test)
    echo "=== ANTHROPIC MESSAGES API COMPATIBILITY TEST (/v1/messages) ==="
    curl -sS --max-time 4 -X POST "${HOST_URL}/v1/messages" -H "Content-Type: application/json" -d '{"model":"act-omega-sh4z-v4450","messages":[{"role":"user","content":"Verify 28,160 neurons and 15.965Hz Decadic lockstep"}]}'
    echo ""
    ;;
  metrics)
    echo "=== PROMETHEUS / OPENMETRICS SCRAPE (/metrics) ==="
    curl -sS --max-time 4 "${HOST_URL}/metrics"
    ;;
  hud)
    if command -v xdg-open >/dev/null 2>&1; then
      xdg-open "${HUD_URL}"
    elif command -v open >/dev/null 2>&1; then
      open "${HUD_URL}"
    else
      echo "Open ${HUD_URL} or ${WAN_URL} in any browser."
    fi
    ;;
  *)
    echo "Usage: $0 {status|verify|cyclesync|handover|ollama-test|anthropic-test|metrics|hud}"
    ;;
esac
