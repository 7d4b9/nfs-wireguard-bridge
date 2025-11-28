#!/bin/bash
set -euo pipefail

# --- Configuration ---
WG_IF="wg0"
WG_PORT=51820
WG_SUBNET="10.8.0"
WG_SERVER_IP="${WG_SUBNET}.1"
WG_CLIENT_IP="${WG_SUBNET}.2"
WG_DIR="/etc/wireguard"
STATE_DIR="/state"

mkdir -p "${WG_DIR}" "${STATE_DIR}"

# --- Clé WireGuard serveur ---
if [ ! -f "${STATE_DIR}/server.key" ]; then
    umask 077
    wg genkey | tee "${STATE_DIR}/server.key" | wg pubkey > "${STATE_DIR}/server.pub"
    wg genkey | tee "${STATE_DIR}/client.key" | wg pubkey > "${STATE_DIR}/client.pub"
fi

SERVER_PRIV_KEY=$(cat "${STATE_DIR}/server.key")
SERVER_PUB_KEY=$(cat "${STATE_DIR}/server.pub")
CLIENT_PRIV_KEY=$(cat "${STATE_DIR}/client.key")
CLIENT_PUB_KEY=$(cat "${STATE_DIR}/client.pub")

# --- Création du fichier de conf serveur ---
cat > "${WG_DIR}/${WG_IF}.conf" <<EOF
[Interface]
Address = ${WG_SERVER_IP}/24
ListenPort = ${WG_PORT}
PrivateKey = ${SERVER_PRIV_KEY}
PostUp = iptables -t nat -A POSTROUTING -s ${WG_SUBNET}.0/24 -j MASQUERADE
PostUp = echo 1 > /proc/sys/net/ipv4/ip_forward
PostDown = iptables -t nat -D POSTROUTING -s ${WG_SUBNET}.0/24 -j MASQUERADE

[Peer]
# Macbook
PublicKey = ${CLIENT_PUB_KEY}
AllowedIPs = ${WG_CLIENT_IP}/32
EOF

# --- Lancement de WireGuard ---
echo "🟢 Lancement WireGuard serveur"
wg-quick up "${WG_IF}"

NFS_WIREGUARD_SERVER_ENDPOINT="${NFS_WIREGUARD_SERVER_HOST:-$(curl -s https://ifconfig.me)}:${NFS_WIREGUARD_SERVER_PORT:-${WG_PORT}}"

# --- Affichage config client ---
cat > "${STATE_DIR}/macbook.conf" <<EOF
[Interface]
PrivateKey = ${CLIENT_PRIV_KEY}
Address = ${WG_CLIENT_IP}/24
DNS = 1.1.1.1

[Peer]
PublicKey = ${SERVER_PUB_KEY}
ENDPOINT = ${NFS_WIREGUARD_SERVER_ENDPOINT}
AllowedIPs = 10.8.0.0/24, 192.168.50.0/24
PersistentKeepalive = 25
EOF

echo "--------------------------------------------"
echo "📋 Configuration WireGuard client prête !"
echo "Copie/colle ce fichier sur ton Mac :"
echo "  docker cp <container_id>:/state/macbook.conf ./macbook.conf"
echo "Ou scan ce QR code avec l'app WireGuard mobile:"
qrencode -t ANSIUTF8 < ${STATE_DIR}/macbook.conf || true
echo "--------------------------------------------"

# --- NFS exports ---
echo "/workspaces  ${WG_CLIENT_IP}/32(rw,sync,no_subtree_check,all_squash,anonuid=1000,anongid=1000)" >> /etc/exports
echo "/runner      ${WG_CLIENT_IP}/32(rw,sync,no_subtree_check,no_root_squash)" >> /etc/exports 
# --- 
echo 'RPCMOUNTDOPTS="--port 32767"' > /etc/default/nfs-kernel-server
echo 'STATDOPTS="--port 32765 --outgoing-port 32766"' > /etc/default/nfs-common
echo 'options lockd nlm_udpport=32768 nlm_tcpport=32768' > /etc/modprobe.d/lockd.conf

rpc.statd --no-notify --port 32765 --outgoing-port 32766 &

echo "🟢 Démarrage NFS server"
rpcbind
sleep 1
exportfs -rav
service nfs-kernel-server restart

echo "=== READY === (WireGuard + NFS) ==="
tail -f /dev/null