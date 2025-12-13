FROM debian:stable

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    locales \
    bash-completion \
    ca-certificates \
    curl \
    dnsutils \
    file \
    htop \
    iftop \
    iproute2 \
    iptables \
    iputils-ping \
    less \
    lsof \
    net-tools \
    netcat-openbsd \
    nfs-kernel-server \
    procps \
    qrencode \
    rsync \
    socat \
    sudo \
    tcpdump \
    tree \
    unzip \
    vim \
    wget \
    wireguard \
    xz-utils \
    zip \
    && apt-get clean && rm -rf /var/lib/apt/lists/* \
    && sed -i 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen en_US.UTF-8 \
    && update-locale LANG=en_US.UTF-8
ARG non_root_user=devuser

RUN useradd -m ${non_root_user} -u 1000 && echo "${non_root_user}:${non_root_user}" | chpasswd && adduser ${non_root_user} sudo \
    && echo "${non_root_user} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${non_root_user} \
    && chmod 0440 /etc/sudoers.d/${non_root_user} \
    \
    && chown -R ${non_root_user}:${non_root_user} ${HOME}

USER ${non_root_user}
ENV HOME=/home/${non_root_user}

RUN sudo mkdir -p /etc/wireguard /workspaces /state /runner \
    && sudo chmod 700 /etc/wireguard \
    && sudo chown -R ${non_root_user}:${non_root_user} /workspaces /state /runner

COPY wg-server-start.sh     /usr/local/bin/
COPY wg-client-connect.sh   /usr/local/bin/
COPY wg-show.sh             /usr/local/bin/
COPY nfs-start.sh           /usr/local/bin/
COPY entrypoint.sh          /usr/local/bin/

RUN sudo chmod +x /usr/local/bin/*.sh

EXPOSE 51820/udp

ENTRYPOINT ["entrypoint.sh"]