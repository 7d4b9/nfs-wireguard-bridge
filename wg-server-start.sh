#!/bin/bash

set -euo pipefail

# --- Configuration ---
WG_IF="wg0"
WG_PORT=51820
WG_DIR="/etc/wireguard"
STATE_DIR="/state"

mkdir -p "${WG_DIR}" "${STATE_DIR}"

sudo chown -R devuser:devuser "${WG_DIR}" "${STATE_DIR}"

# --- Clé WireGuard serveur ---
if [ ! -f "${STATE_DIR}/server.key" ]; then
    umask 077
    wg genkey | tee "${STATE_DIR}/server.key" | wg pubkey > "${STATE_DIR}/server.pub"
    wg genkey | tee "${STATE_DIR}/client.key" | wg pubkey > "${STATE_DIR}/client.pub"
fi

# --- Clé WireGuard Bridge ---
if [ ! -f "${STATE_DIR}/bridge.key" ]; then
    umask 077
    wg genkey | tee "${STATE_DIR}/bridge.key" | wg pubkey > "${STATE_DIR}/bridge.pub"
fi

BRIDGE_PRIV_KEY=$(cat "${STATE_DIR}/bridge.key")
BRIDGE_PUB_KEY=$(cat "${STATE_DIR}/bridge.pub")
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
# PostUp = iptables -t nat -A POSTROUTING -s ${WG_SUBNET}.0/24 -j MASQUERADE
PostUp = iptables -t nat -A POSTROUTING -s 0.0.0.0/0 -j MASQUERADE
PostUp = echo 1 > /proc/sys/net/ipv4/ip_forward
# PostDown = iptables -t nat -D POSTROUTING -s ${WG_SUBNET}.0/24 -j MASQUERADE
PostDown = iptables -t nat -D POSTROUTING -s 0.0.0.0/0 -j MASQUERADE

[Peer]
# Macbook
PublicKey = ${CLIENT_PUB_KEY}
AllowedIPs = ${WG_CLIENT_IP}/32

[Peer]
# Bridge1
PublicKey = ${BRIDGE_PUB_KEY}
AllowedIPs = 10.88.0.3/32
EOF

# --- Lancement de WireGuard ---
echo "🟢 Lancement WireGuard serveur"
wg-quick up "${WG_IF}"

WIREGUARD_SERVER_ENDPOINT="${NFS_WIREGUARD_SERVER_HOST:-$(curl -s https://ifconfig.me)}:${NFS_WIREGUARD_SERVER_PORT:-${WG_PORT}}"

# --- Affichage config Bridge1 ---
cat > "${STATE_DIR}/bridge-client.conf" <<EOF
[Interface]
PrivateKey = ${BRIDGE_PRIV_KEY}
Address = 10.88.0.3/24
DNS = 1.1.1.1

[Peer]
PublicKey = ${SERVER_PUB_KEY}
ENDPOINT = ${WIREGUARD_SERVER_ENDPOINT}
AllowedIPs = 10.88.0.0/24, 192.168.50.0/24
PersistentKeepalive = 25
EOF

# --- Affichage config client ---
cat > "${STATE_DIR}/macbook.conf" <<EOF
[Interface]
PrivateKey = ${CLIENT_PRIV_KEY}
Address = ${WG_CLIENT_IP}/24
DNS = 1.1.1.1

[Peer]
PublicKey = ${SERVER_PUB_KEY}
ENDPOINT = ${WIREGUARD_SERVER_ENDPOINT}
AllowedIPs = 10.88.0.0/24, 192.168.50.0/24
PersistentKeepalive = 25
EOF

echo "--------------------------------------------"
echo "📋 Configuration WireGuard client prête !"
echo "Copie/colle ce fichier sur ton Mac :"
echo "  docker cp <container_id>:/state/macbook.conf ./macbook.conf"
echo "Ou scan ce QR code avec l'app WireGuard mobile:"
qrencode -t ANSIUTF8 < ${STATE_DIR}/macbook.conf || true
echo "--------------------------------------------"
echo "=== READY === (WireGuard) ==="
