#!/bin/bash

set -euo pipefail

sudo wg show

ip a
ip route

sudo iptables -t nat -L -n -v
sudo iptables -L INPUT -n -v
sudo iptables -L FORWARD -n -v

# Routes de wg0
ip route show dev wg0

# Routes de wg-pdc-client
ip route show dev wg-pdc-client

ip route

ip -4 route show