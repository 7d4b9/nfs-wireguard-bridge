wg show
ip a
ip route

sudo sysctl -w net.ipv4.conf.all.rp_filter=0
sudo sysctl -w net.ipv4.conf.default.rp_filter=0
sudo sysctl -w net.ipv4.conf.wg0.rp_filter=0
# etc. (pour toutes les interfaces utilisées)

sudo tcpdump -ni wg0
sudo tcpdump -ni wg-pdc-client
sudo tcpdump -ni eth0
sudo tcpdump -ni lo

sysctl net.ipv4.ip_forward

iptables -t nat -L -n -v
iptables -L INPUT -n -v
iptables -L FORWARD -n -v

# Routes de wg0
ip route show dev wg0

# Routes de wg-pdc-client
ip route show dev wg-pdc-client

ip route

ip -4 route show