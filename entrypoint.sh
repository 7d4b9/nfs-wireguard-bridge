#!/bin/bash
set -euo pipefail

echo "=== OpenVPN + NFS Container ==="

# 1. Démarrer le VPN
echo "🔵 Starting OpenVPN..."
openvpn --config /vpn/client.ovpn --daemon

sleep 5

echo "🔵 Checking VPN IP..."
VPN_IP=$(ip -4 addr show | grep -Eo '10\.8\.20\.[0-9]+' || true)
if [ -z "$VPN_IP" ]; then
    echo "❌ No VPN IP. Exiting."
    exit 1
fi
echo "✔️ VPN UP: $VPN_IP"

# 2. Préparer les exports NFS
echo "🔵 Configuring NFS exports..."
cat > /etc/exports <<EOF
/exports/workspaces  $VPN_IP/32(rw,fsid=0,no_subtree_check,no_root_squash,insecure)
/exports/runner      $VPN_IP/32(rw,no_subtree_check,no_root_squash,insecure)
EOF

# 3. Démarrer NFS
echo "🔵 Starting NFS server..."
rpcbind
sleep 1
exportfs -rav
service nfs-kernel-server start

echo "=== READY ==="
echo "NFS exports:"
exportfs -v

tail -f /dev/null