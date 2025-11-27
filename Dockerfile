FROM debian:stable

RUN apt-get update && apt-get install -y \
    openvpn \
    nfs-kernel-server \
    iproute2 \
    iputils-ping \
    procps \
    && apt-get clean

# Répertoires de configuration
RUN mkdir -p /vpn /exports

# Notre script entrypoint
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# # Ports NFSv4 uniquement (un seul port !)
# EXPOSE 2049/tcp
# EXPOSE 2049/udp

ENTRYPOINT ["/entrypoint.sh"]