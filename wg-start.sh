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

# # --- Clé WireGuard Archer AX55 ---
# if [ ! -f "${STATE_DIR}/ax55.key" ]; then
#     umask 077
#     wg genkey | tee "${STATE_DIR}/ax55.key" | wg pubkey > "${STATE_DIR}/ax55.pub"
# fi

SERVER_PRIV_KEY=$(cat "${STATE_DIR}/server.key")
SERVER_PUB_KEY=$(cat "${STATE_DIR}/server.pub")
CLIENT_PRIV_KEY=$(cat "${STATE_DIR}/client.key")
CLIENT_PUB_KEY=$(cat "${STATE_DIR}/client.pub")

export WG_CLIENT_IP="${WG_SUBNET}.2"

# --- Création du fichier de conf serveur ---
cat > "${WG_DIR}/${WG_IF}.conf" <<EOF
[Interface]
Address = ${WG_SERVER_IP}/24
ListenPort = ${WG_PORT}
PrivateKey = ${SERVER_PRIV_KEY}

# On mappe le réseau distant du VPN 192.168.1.0/24
# vers un réseau virtuel 10.200.1.0/24
PostUp = iptables -t nat -A PREROUTING -d 10.200.1.0/24 -j NETMAP --to 192.168.1.0/24
PostUp = iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -j NETMAP --to 10.200.1.0/24
PostDown = iptables -t nat -D PREROUTING -d 10.200.1.0/24 -j NETMAP --to 192.168.1.0/24
PostDown = iptables -t nat -D POSTROUTING -s 192.168.1.0/24 -j NETMAP --to 10.200.1.0/24

PostUp = iptables -t nat -A POSTROUTING -s ${WG_SUBNET}.0/24 -j MASQUERADE
PostUp = echo 1 > /proc/sys/net/ipv4/ip_forward
PostDown = iptables -t nat -D POSTROUTING -s ${WG_SUBNET}.0/24 -j MASQUERADE

[Peer]
# Labtop
PublicKey = ${CLIENT_PUB_KEY}
AllowedIPs = ${WG_CLIENT_IP}/32

EOF

# --- Lancement de WireGuard ---
echo "🟢 Lancement WireGuard serveur"
wg-quick up "${WG_IF}"

WIREGUARD_SERVER_ENDPOINT="${NFS_WIREGUARD_SERVER_HOST:-$(curl -s https://ifconfig.me)}:${NFS_WIREGUARD_SERVER_PORT:-${WG_PORT}}"

# # --- Affichage config Archer AX55 ---
# cat > "${STATE_DIR}/ax55-client.conf" <<EOF
# [Interface]
# PrivateKey = ${AX55_PRIV_KEY}
# Address = 10.8.0.3/24
# DNS = 1.1.1.1

# [Peer]
# PublicKey = ${SERVER_PUB_KEY}
# ENDPOINT = ${WIREGUARD_SERVER_ENDPOINT}
# AllowedIPs = 10.8.0.0/24, 192.168.1.0/24
# PersistentKeepalive = 25
# EOF

# --- Affichage config client ---
cat > "${STATE_DIR}/laptop.conf" <<EOF
[Interface]
PrivateKey = ${CLIENT_PRIV_KEY}
Address = ${WG_CLIENT_IP}/24
DNS = 1.1.1.1

[Peer]
PublicKey = ${SERVER_PUB_KEY}
ENDPOINT = ${WIREGUARD_SERVER_ENDPOINT}
AllowedIPs = 10.8.0.0/24, 192.168.1.0/24
PersistentKeepalive = 25
EOF

echo "--------------------------------------------"
echo "📋 Configuration WireGuard client prête !"
echo "Copie/colle ce fichier sur ton Mac :"
echo "  docker cp <container_id>:/state/labtop.conf ./labtop.conf"
echo "Ou scan ce QR code avec l'app WireGuard mobile:"
qrencode -t ANSIUTF8 < ${STATE_DIR}/labtop.conf || true
echo "--------------------------------------------"
echo "=== READY === (WireGuard) ==="

sudo iptables -L -t nat

sleep infinity