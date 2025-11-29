FROM debian:stable

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    wireguard \
    nfs-kernel-server \
    iproute2 \
    iptables \
    procps \
    qrencode \
    sudo \
    && apt-get clean

ARG non_root_user=devuser

RUN useradd -m ${non_root_user} -u 1000 && echo "${non_root_user}:${non_root_user}" | chpasswd && adduser ${non_root_user} sudo \
    && echo "${non_root_user} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${non_root_user} \
    && chmod 0440 /etc/sudoers.d/${non_root_user} \
    \
    && chown -R ${non_root_user}:${non_root_user} ${HOME}

ENV HOME=/home/${non_root_user}

RUN mkdir -p /etc/wireguard /workspaces /runner /state


COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY nfs-start.sh /usr/local/bin/nfs-start.sh
COPY wg-start.sh /usr/local/bin/wg-start.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 51820/udp

ENTRYPOINT ["entrypoint.sh"]   