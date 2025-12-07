#!/bin/bash
set -euo pipefail

echo "=== INTERFACES ==="
ip a

echo -e "\n=== ROUTES ==="
ip route

echo -e "\n=== TABLES DE ROUTAGE ==="
ip rule

echo -e "\n=== INTERFACES WireGuard ==="
sudo wg show

echo -e "\n=== TABLES DE NAT ==="
sudo iptables -t nat -L -n -v

echo -e "\n=== TABLES DE FILTRAGE ==="
sudo iptables -L -n -v

echo -e "\n=== EXPORTS NFS ==="
exportfs -v || echo "nfs-utils non installé"

echo -e "\n=== DNS ACTUEL ==="
cat /etc/resolv.conf || echo "Pas d'accès à resolv.conf"

echo -e "\n=== TEST CONNEXION INTERNET ==="
curl -s https://ifconfig.me || echo "curl échoué"

echo -e "\n=== TEST ICMP (10.8.0.2 et 10.5.5.2) ==="
ping -c2 10.8.0.2 || echo "Pas de réponse de 10.8.0.2"
ping -c2 10.5.5.2 || echo "Pas de réponse de 10.5.5.2"

echo -e "\n=== TCPDUMP 10 paquets sur wg0 et wg-pdc-client (10s chaque) ==="
timeout 10 tcpdump -n -i wg0 &
timeout 10 tcpdump -n -i wg-pdc-client &
wait

echo -e "\n=== FIN DEBUG BRIDGE ==="