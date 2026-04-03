DOCKER_REPOSITORY ?= dbndev
NFS_WIREGUARD_BRIDGE_SERVER_IMAGE ?= $(DOCKER_REPOSITORY)/nfs-wireguard-bridge
NFS_WIREGUARD_BRIDGE_SERVER_PORT ?= 51820

include server.mk

export 

DOCKER_IMAGE_MAKE ?= \
  build push pull

$(DOCKER_IMAGE_MAKE):
	@$(MAKE) $(@:%=nfs-wireguard-bridge-server-image-%)
.PHONY: $(DOCKER_IMAGE_MAKE)

DOCKER_CONTAINER_MAKE ?= \
  up down rm logs logs-f sh

$(DOCKER_CONTAINER_MAKE):
	@$(MAKE) $(@:%=nfs-wireguard-bridge-server-container-%)
.PHONY: $(DOCKER_CONTAINER_MAKE)

VPN_BACKBONE ?= 10.5.5

# Addresses below are used by devices without nfs-wireguard-bridge container
RESERVED_VPN_BACKBONE_ROUTER_ADDR     ?= $(VPN_BACKBONE).1
RESERVED_VPN_BACKBONE_PC_LABTOP_ADDR  ?= $(VPN_BACKBONE).4
RESERVED_VPN_BACKBONE_PC_DESKTOP_ADDR ?= $(VPN_BACKBONE).7

DOCKER_COMPOSE = docker compose -f docker-compose.yml
# ----------------------------------------------
# #############################################
# ----------------------------------------------
# Github Codespaces
# ----------------------------------------------
GITHUB_CODESPACES_SERVER_HOST ?= $(VPN_BACKBONE).5
GITHUB_CODESPACES_SERVER_WG_SUBNET ?= 10.9.0

GITHUB_CODESPACES_DOCKER_COMPOSE ?= \
  $(DOCKER_COMPOSE) -f github-codespaces-docker-compose-override.yml

github-codespaces-up:
	@echo Launching wireguard NFS bridge server in GitHub Codespaces
	@$(MAKE) up \
	  NFS_WIREGUARD_BRIDGE_SERVER_DOCKER_COMPOSE=$(GITHUB_CODESPACES_DOCKER_COMPOSE)
	  NFS_WIREGUARD_BRIDGE_GITHUB_ACTIONS_RUNNER_WORK_DIR=/mnt/data/gha-runner \
	  NFS_WIREGUARD_BRIDGE_SERVER_HOST=$(GITHUB_CODESPACES_SERVER_HOST) \
	  NFS_BACKEND=ganesha \
	  WG_SUBNET=$(GITHUB_CODESPACES_SERVER_WG_SUBNET)
.PHONY: github-codespaces-up

github-codespaces-upgrade: build down github-codespaces-up
.PHONY: github-codespaces-upgrade
# ----------------------------------------------
# #############################################
# ----------------------------------------------
# GCP Developer VM
# ----------------------------------------------
GCP_DEV_SERVER_HOST ?= $(VPN_BACKBONE).6
GCP_DEV_SERVER_WG_SUBNET ?= 10.7.0

gcp-dev-up:
	@echo Launching wireguard NFS bridge server in GCP developer VM
	@$(MAKE) up \
	  NFS_WIREGUARD_BRIDGE_SERVER_HOST=$(GCP_DEV_SERVER_HOST) \
	  NFS_BACKEND=ganesha \
	  WG_SUBNET=$(GCP_DEV_SERVER_WG_SUBNET)
.PHONY: gcp-dev-up

gcp-dev-upgrade: build down gcp-dev-up
.PHONY: gcp-dev-upgrade
# ----------------------------------------------
# #############################################
# ----------------------------------------------
# PC Desktop
# ----------------------------------------------
PC_DESKTOP_SERVER_HOST ?= $(VPN_BACKBONE).3
PC_DESKTOP_SERVER_WG_SUBNET ?= 10.8.0

pc-desktop-up:
	@echo Launching wireguard NFS bridge server in PC Desktop
	@$(MAKE) up \
	  NFS_WIREGUARD_BRIDGE_SERVER_HOST=$(PC_DESKTOP_SERVER_HOST) \
	  WG_SUBNET=$(PC_DESKTOP_SERVER_WG_SUBNET)
.PHONY: pc-desktop-up

pc-desktop-upgrade: build down pc-desktop-up
.PHONY: pc-desktop-upgrade
# ----------------------------------------------
# #############################################
# ----------------------------------------------
# ----------------------------------------------
# PC Labtop
# ----------------------------------------------
PC_LABTOP_SERVER_HOST ?= $(VPN_BACKBONE).4
PC_LABTOP_SERVER_WG_SUBNET ?= 10.11.0

pc-labtop-up:
	@echo Launching wireguard NFS bridge server in PC labtop
	@$(MAKE) up \
	  NFS_WIREGUARD_BRIDGE_SERVER_HOST=$(PC_LABTOP_SERVER_HOST) \
	  WG_SUBNET=$(PC_LABTOP_SERVER_WG_SUBNET) \
	  NFS_BACKEND=ganesha
.PHONY: pc-labtop-up

pc-labtop-upgrade: build down pc-labtop-up
.PHONY: pc-labtop-upgrade
# ----------------------------------------------
# #############################################
# ----------------------------------------------
