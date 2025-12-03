#!/bin/bash
set -euo pipefail

cleanup() {
    echo "🛑 Arrêt NFS server"
    service nfs-kernel-server stop || true
}

trap cleanup EXIT

echo "📝 Mise à jour des exports NFS"

# Ensure exports.d directory exists
mkdir -p /etc/exports.d
chmod 755 /etc/exports.d

cat > /etc/exports.d/wireguard.exports <<EOF
/workspaces  ${WG_CLIENT_IP}/32(rw,sync,no_subtree_check,all_squash,anonuid=1000,anongid=1000)
/runner      ${WG_CLIENT_IP}/32(rw,sync,no_subtree_check,no_root_squash)
EOF

echo 'RPCMOUNTDOPTS="--port 32767"' > /etc/default/nfs-kernel-server
echo 'STATDOPTS="--port 32765 --outgoing-port 32766"' > /etc/default/nfs-common
echo 'options lockd nlm_udpport=32768 nlm_tcpport=32768' > /etc/modprobe.d/lockd.conf

echo "🟢 Démarrage NFS"

rpc.statd --no-notify --port 32765 --outgoing-port 32766 || true
rpcbind

exportfs -rav
service nfs-kernel-server start

echo "=== READY === (NFS) ==="
tail -f /dev/null