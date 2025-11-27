FROM debian:stable

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    openvpn \
    easy-rsa \
    iptables \
    iproute2 \
    nfs-kernel-server \
    procps \
    && apt-get clean

# Dossiers
RUN mkdir -p /etc/openvpn/server \
    /pki \
    /exports/workspaces \
    /exports/runner

# Scripts
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 1194/udp
EXPOSE 2049/tcp
EXPOSE 2049/udp

ENTRYPOINT ["/entrypoint.sh"]