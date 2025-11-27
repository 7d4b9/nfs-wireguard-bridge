# SSH Bridge

SSH Bridge£ project provides a bridge over SSH using Docker containers. It includes two components: the SSH client and the SSH server.

![IMG_1506](https://github.com/user-attachments/assets/955cdc8e-9631-46a0-b26b-2dacf269337d)

## Prerequisites

- Docker
- Docker Compose
- Make Utility

## Usage

We use `make` commands for various operations in this project. Below is a brief description of each command.

1. **Building the Docker image:**

```bash
make build
```
This command is used to build the Docker image.

2. **Pushing the Docker image:**

```bash
make push
```
This command pushes the built Docker image to the specified repository.

3. **Pulling the Docker image:**

```bash
make pull
```
This command pulls the image from the specified repository.

4. **Generating SSH Keys:**

```bash
make generate-ssh-keys
```
This command generates new SSH keys.

5. **Launching the SSH Server:**

```bash
make server
```
This command starts the SSH server.

6. **Launching the SSH Client with a local docker container:**

```bash
make proxy
```
This command starts the SSH tunnel from a local docker container.
It can be used if SSH is not installed locally.

7. **Launching the SSH Client from your machine directly**

Add this to your *.bashrc*. You have to adjust some values like `workspace/docker-ssh-bridge/id_rsa` to where you did clone the current project

```bash
# Distant docker socket over ssh
export SSH_DOCKER_SERVER_HOST=bbrodriguez.example.org
export SSH_DOCKER_SERVER_PORT=21312
export SSH_DOCKER_SERVER_USER=devuser

# Expose distand dockerd socket locally with DOCKER_HOST
client_ssh_docker_tunnel_host=localhost
client_ssh_docker_tunnel_port=23750
# ssh docker tunnel creation if not exist
nc -z ${client_ssh_docker_tunnel_host} ${client_ssh_docker_tunnel_port}
if [ $? -ne 0 ] ; then
    # if private key exists use it directly
    if [ -f workspace/docker-ssh-bridge/id_rsa ] ; then
        ssh -i workspace/docker-ssh-bridge/id_rsa -NL ${client_ssh_docker_tunnel_host}:${client_ssh_docker_tunnel_port}:/var/run/docker.sock ${SSH_DOCKER_SERVER_USER}@${SSH_DOCKER_SERVER_HOST} -p ${SSH_DOCKER_SERVER_PORT} &
    fi
fi

export DOCKER_HOST=tcp://${client_ssh_docker_tunnel_host}:${client_ssh_docker_tunnel_port}
```

8. **Cleaning up:**

```bash
make clean
```
This command deletes the generated SSH keys.

Use these commands as per your requirements.

**Note:**
The `REPOSITORY` variable can be set to your Docker Hub username or any other registry where you wish to push your images. If not specified, it defaults to `dbndev`.

```bash
make push REPOSITORY=your_dockerhub_username
```

Please ensure that you have proper permissions set for your SSH files/directory.

Enjoy using SSH Bridge!