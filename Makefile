export 

REPOSITORY ?= dbndev
IMAGE := $(REPOSITORY)/nfs-wireguard-bridge
PWD = $(CURDIR)

build:
	@echo Building image:
	@docker build -t $(IMAGE) .
.PHONY: build

push:
	@echo pushing image:
	@docker push $(IMAGE)
.PHONY: push

pull:
	@echo pulling image:
	@docker pull $(IMAGE)
.PHONY: pull

server-upgrade: build server-down server-up
.PHONY: server-upgrade

NFS_WIREGUARD_SERVER_HOST := 10.5.5.5
NFS_WIREGUARD_SERVER_PORT := 51820

NFS_WIREGUARD_SERVER_DOCKER_COMPOSE = \
COMPOSE_PROJECT_NAME=nfs-wireguard-bridge \
docker compose

server-up: server-rm 
	@echo Launching wireguard NFS bridge server
	@$(NFS_WIREGUARD_SERVER_DOCKER_COMPOSE) up -d server
	@echo server is running.
	@echo use "make server-logs" or "make server-logs-follow" to view server logs
.PHONY: server-up

server-down:
	@echo Removing NFS server container
	@$(NFS_WIREGUARD_SERVER_DOCKER_COMPOSE) down server || $(MAKE) server-rm
.PHONY: server-down

server-rm:
	@echo Removing NFS server container
	-$(NFS_WIREGUARD_SERVER_DOCKER_COMPOSE) rm -f -s server
.PHONY: server-rm

server-up-github-codespaces:
	@echo Launching wireguard NFS bridge server in GitHub Codespaces
	@NFS_WIREGUARD_BRIDGE_GITHUB_ACTIONS_RUNNER_WORK_DIR=/mnt/data/gha-runner \
	  $(MAKE) server-up
.PHONY: server-up-github-codespaces

server-logs:
	@$(NFS_WIREGUARD_SERVER_DOCKER_COMPOSE) logs server
.PHONY: server-logs

server-logs-follow:
	@$(NFS_WIREGUARD_SERVER_DOCKER_COMPOSE) logs --follow server
.PHONY: server-logs-follow

server-sh:
	@echo Launching NFS server shell
	@$(NFS_WIREGUARD_SERVER_DOCKER_COMPOSE) exec -it server bash
.PHONY: server-sh