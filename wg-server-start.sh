#!/bin/bash

set -euxo pipefail

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
    wg genkey | tee "${STATE_DIR}/client-macbook.key" | wg pubkey > "${STATE_DIR}/client-macbook.pub"
    wg genkey | tee "${STATE_DIR}/client-iphone6s.key" | wg pubkey > "${STATE_DIR}/client-iphone6s.pub"
fi

SERVER_PRIV_KEY=$(cat "${STATE_DIR}/server.key")
SERVER_PUB_KEY=$(cat "${STATE_DIR}/server.pub")

CLIENT_MACBOOK_PRIV_KEY=$(cat "${STATE_DIR}/client-macbook.key")
CLIENT_MACBOOK_PUB_KEY=$(cat "${STATE_DIR}/client-macbook.pub")

# CLIENT_IPHONE6S_PRIV_KEY=$(cat "${STATE_DIR}/client-iphone6s.key")
# CLIENT_IPHONE6S_PUB_KEY=$(cat "${STATE_DIR}/client-iphone6s.pub")

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
PublicKey = ${CLIENT_MACBOOK_PUB_KEY}
AllowedIPs = ${WG_CLIENT_MACBOOK_IP}/32
PersistentKeepalive = 25

# [Peer]
# # iPhone 6s
# PublicKey = ${CLIENT_IPHONE6S_PUB_KEY}
# AllowedIPs = ${WG_CLIENT_IPHONE6S_IP}/32
# PersistentKeepalive = 25
EOF

# --- Lancement de WireGuard ---
echo "🟢 Lancement WireGuard serveur"
wg-quick up "${WG_IF}"

WIREGUARD_SERVER_ENDPOINT="${NFS_WIREGUARD_SERVER_HOST:-$(curl -s https://ifconfig.me)}:${NFS_WIREGUARD_SERVER_PORT:-${WG_PORT}}"
CODESPACES_DOCKER_SUBNET="172.17.0.0/16"
echo "🌐 WireGuard endpoint: ${WIREGUARD_SERVER_ENDPOINT}"

# --- Affichage config client macbook ---
cat > "${STATE_DIR}/macbook.conf" <<EOF
[Interface]
PrivateKey = ${CLIENT_MACBOOK_PRIV_KEY}
Address = ${WG_CLIENT_MACBOOK_IP}/24

[Peer]
PublicKey = ${SERVER_PUB_KEY}
ENDPOINT = ${WIREGUARD_SERVER_ENDPOINT}
AllowedIPs = ${WG_SUBNET}.0/24, ${CODESPACES_DOCKER_SUBNET}
PersistentKeepalive = 25
EOF

echo "--------------------------------------------"
echo "📋 Configuration WireGuard client prête !"
echo "Copie/colle ce fichier sur ton Mac :"
echo "  docker cp <container_id>:/state/macbook.conf ./macbook.conf"
echo "Ou scan ce QR code avec l'app WireGuard mobile:"
qrencode -t ANSIUTF8 < ${STATE_DIR}/macbook.conf || true
echo "--------------------------------------------"

# # --- Affichage config client iPhone 6s ---
# cat > "${STATE_DIR}/iphone6s.conf" <<EOF
# [Interface]
# PrivateKey = ${CLIENT_IPHONE6S_PRIV_KEY}
# Address = ${WG_CLIENT_IPHONE6S_IP}/24

# [Peer]
# PublicKey = ${SERVER_PUB_KEY}
# ENDPOINT = ${WIREGUARD_SERVER_ENDPOINT}
# AllowedIPs = 0.0.0.0/0
# PersistentKeepalive = 25
# EOF

echo "--------------------------------------------"
echo "📋 Configuration WireGuard client prête !"
echo "=== READY === (WireGuard) ==="

sudo iptables -L -t nat

# --- Affichage des infos WireGuard ---
wg-show.sh

sleep infinity
