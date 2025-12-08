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
export WG_SUBNET="10.8.0"
export WG_SERVER_IP="${WG_SUBNET}.1"

nfs-start.sh &
bg_pids+=($!)


wg-start.sh &
bg_pids+=($!)

wait -n