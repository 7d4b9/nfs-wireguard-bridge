#!/bin/bash
set -euo pipefail

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
export WG_SUBNET="10.8.0"
export WG_SERVER_IP="${WG_SUBNET}.1"
export WG_CLIENT_IP="${WG_SUBNET}.2"

wg-start.sh
# bg_pids+=($!)

nfs-start.sh &
bg_pids+=($!)

# --- Wait and return status of the first finished background job ---
wait -n