#!/bin/bash

set -euxo pipefail

# List to hold background job PIDs
bg_pids=()

cleanup() {
    for pid in "${bg_pids[@]}"; do
        kill "$pid"
        wait "$pid" 2>/dev/null
    done
}

trap cleanup EXIT

# --- Configuration ---
export WG_IF="wg0"
export WG_SUBNET="10.88.0"
export WG_SERVER_IP="${WG_SUBNET}.1"
export WG_CLIENT_IP="${WG_SUBNET}.2"

wg-server-start.sh

wg-client-connect.sh &
bg_pids+=($!)

# --- Affichage des infos WireGuard ---
sleep 2
wg-show.sh

# nfs-start.sh &
# bg_pids+=($!)

if [ $# -eq 0 ]; then
  echo "[entrypoint] No command passed, entering sleep infinity to keep container alive"
  wait ${bg_pids[@]}
else
  exec "$@"
fi