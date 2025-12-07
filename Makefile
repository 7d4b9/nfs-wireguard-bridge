export 

REPOSITORY ?= dbndev
IMAGE := $(REPOSITORY)/nfs-wireguard-bridge
PWD = $(CURDIR)

server-upgrade: build server-down server-up
.PHONY: server-upgrade

NFS_WIREGUARD_SERVER_HOST := davidberichon.pro.dns-orange.fr
NFS_WIREGUARD_SERVER_PORT := 41414

server-up: 
	@echo Launching ssh server
	@-docker compose rm -f -s server
	@docker compose up -d server
	@echo server is running.
	@echo use "make server-logs" or "make server-logs-follow" to view server logs
.PHONY: server-up

server-logs:
	@docker compose logs server
.PHONY: server-logs

server-logs-follow:
	@docker compose logs --follow server
.PHONY: server-logs-follow

server-sh:
	@echo Launching ssh server shell
	@docker compose exec -it server bash
.PHONY: server-sh

server-down:
	@echo Removing ssh server container
	@docker compose down server || docker compose rm -f -s server
.PHONY: server-down

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