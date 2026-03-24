nfs-wireguard-bridge-server-image-build:
	@echo Building image:
	@docker build -t $(NFS_WIREGUARD_BRIDGE_SERVER_IMAGE) .
.PHONY: nfs-wireguard-bridge-server-image-build

nfs-wireguard-bridge-server-image-push:
	@echo pushing image:
	@docker push $(NFS_WIREGUARD_BRIDGE_SERVER_IMAGE)
.PHONY: nfs-wireguard-bridge-server-image-push

nfs-wireguard-bridge-server-image-pull:
	@echo pulling image:
	@docker pull $(NFS_WIREGUARD_BRIDGE_SERVER_IMAGE)
.PHONY: nfs-wireguard-bridge-server-image-pull

NFS_WIREGUARD_BRIDGE_SERVER_DOCKER_COMPOSE ?= \
  COMPOSE_PROJECT_NAME=nfs-wireguard-bridge docker compose

nfs-wireguard-bridge-server-container-up: nfs-wireguard-bridge-server-container-rm 
	@echo Launching wireguard NFS bridge server
	@$(NFS_WIREGUARD_BRIDGE_SERVER_DOCKER_COMPOSE) up -d server
	@echo server is running.
	@echo use "make nfs-wireguard-bridge-server-logs" or "make nfs-wireguard-bridge-server-logs-follow" to view server logs
.PHONY: nfs-wireguard-bridge-server-container-up

nfs-wireguard-bridge-server-container-down:
	@echo Removing NFS server container
	@$(NFS_WIREGUARD_BRIDGE_SERVER_DOCKER_COMPOSE) down server || $(MAKE) nfs-wireguard-bridge-server-container-rm
.PHONY: nfs-wireguard-bridge-server-container-down

nfs-wireguard-bridge-server-container-rm:
	@echo Removing NFS server container
	@-$(NFS_WIREGUARD_BRIDGE_SERVER_DOCKER_COMPOSE) rm -f -s server
.PHONY: nfs-wireguard-bridge-server-container-rm

nfs-wireguard-bridge-server-container-logs:
	@$(NFS_WIREGUARD_BRIDGE_SERVER_DOCKER_COMPOSE) logs server
.PHONY: nfs-wireguard-bridge-server-container-logs

nfs-wireguard-bridge-server-container-logs-follow:
	@$(NFS_WIREGUARD_BRIDGE_SERVER_DOCKER_COMPOSE) logs --follow server
.PHONY: nfs-wireguard-bridge-server-container-logs-follow

nfs-wireguard-bridge-server-container-sh:
	@echo Launching NFS server shell
	@$(NFS_WIREGUARD_BRIDGE_SERVER_DOCKER_COMPOSE) exec -it server bash
.PHONY: nfs-wireguard-bridge-server-container-sh