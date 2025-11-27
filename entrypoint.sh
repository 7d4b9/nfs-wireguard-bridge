#!/bin/bash
set -euxo pipefail

echo "=== 🟦 Super Gateway Container Start ==="

# --- CHECK PKI ---
if [ ! -d /pki/pki ]; then
  echo "🔧 Initialisation PKI EasyRSA..."
  # make-cadir /pki
  cd /pki
  ./easyrsa init-pki
  echo "build-ca" | ./easyrsa build-ca nopass
  echo "🔧 Build server cert..."
  echo "build-server-full server nopass" | ./easyrsa build-server-full server nopass
  echo "🔧 Build client cert..."
  echo "build-client-full client nopass" | ./easyrsa build-client-full client nopass
  openvpn --genkey --secret /pki/pki/ta.key
fi

# --- OPENVPN CONFIG ---
echo "🔧 Génération configuration OpenVPN serveur..."

cat > /etc/openvpn/server/server.conf <<EOF
port 1194
proto udp
dev tun
ca /pki/pki/ca.crt
cert /pki/pki/issued/server.crt
key /pki/pki/private/server.key
dh none
topology subnet
server 10.8.0.0 255.255.255.0
push "route 10.8.0.0 255.255.255.0"
keepalive 10 120
persist-key
persist-tun
cipher AES-256-GCM
auth SHA256
user nobody
group nogroup
tls-crypt /pki/pki/ta.key
verb 3
EOF

# --- FIREWALL / NAT ---
echo "🔧 Configuration NAT..."
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -j MASQUERADE

echo 1 > /proc/sys/net/ipv4/ip_forward

# --- START OPENVPN ---
echo "🚀 Démarrage OpenVPN..."
openvpn --config /etc/openvpn/server/server.conf --daemon
sleep 3

VPN_IP=$(ip -4 addr show tun0 | grep -Eo '10\.8\.0\.[0-9]+' || true)
echo "✔️  OpenVPN UP : $VPN_IP"

OVPN_REMOTE_DEFAULT_ADDR=$(dig +short myip.opendns.com @resolver1.opendns.com || echo "PUBLIC_IP_NOT_FOUND")
OVPN_REMOTE_ADDR=${OVPN_REMOTE_ADDR:-$OVPN_REMOTE_DEFAULT_ADDR}
echo "🌐 Public IP : $OVPN_REMOTE_ADDR"
OVPN_PUBLIC_PORT=${OVPN_PUBLIC_PORT:-1194}
echo "🔌 OpenVPN Port : $OVPN_PORT"

# --- EXPORT CLIENT OVPN ---
if [ ! -f /pki/client.ovpn ]; then
cat > /pki/client.ovpn <<EOF
client
dev tun
proto udp
remote $OVPN_REMOTE_ADDR $OVPN_PUBLIC_PORT
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-GCM
auth SHA256
verb 3
<ca>
$(cat /pki/pki/ca.crt)
</ca>
<cert>
$(cat /pki/pki/issued/client.crt)
</cert>
<key>
$(cat /pki/pki/private/client.key)
</key>
<tls-crypt>
$(cat /pki/pki/ta.key)
</tls-crypt>
EOF
fi

# --- NFS ---
echo "🔧 Configuration NFSv4..."

cat > /etc/exports <<EOF
/exports/workspaces 10.8.0.0/24(rw,sync,no_subtree_check,no_root_squash)
/exports/runner 10.8.0.0/24(rw,sync,no_subtree_check,no_root_squash)
EOF

rpcbind
sleep 1
exportfs -rav
service nfs-kernel-server start

echo "=== 🟩 Super Gateway READY ==="
tail -f /dev/null