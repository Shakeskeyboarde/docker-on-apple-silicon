# Docker on Apple (ARM64) using a remote daemon on Ubuntu (AMD64)

This repository contains instructions and setup scripts for installing the Docker client locally (Apple), the Docker daemon remotely (Ubuntu), and configuring them to work together.

**Q:** Why would you want to do this?

**A:** Because support for Docker on Apple silicon is still progressing. Even when Docker becomes Apple native, it will still only _run_ Arm64 containers on Apple silicon, and building will require emulation (buildx). Running the daemon remotely on an Amd64 Linux host allows me to continue running Amd64 images _right now_, and building does not require any additional configuration or emulation. I can run and build on the same platform the images will be deployed to.

### Caveats

- If running containers have listeners, they will be listening _on the daemon host's public IP._ This can be a good thing as long as you're aware of it. It's a great way to quickly demo things for other people. But, if you're not okay with public listeners, then I suggest you try setting up a VPN on your daemon host, and using iptables to lock down incoming connections to the VPS. But that's beyond the scope of this document.
- Using volumes/mounts will target the filesystem _of the daemon host_, not your local file system. If you need to share the daemon host's file system with your local machine, I recommend checking out SSHFS. But again, that's beyond the scope of this document.

&nbsp;

# Let's begin.

Follow these three (easy-ish) steps to get Docker working on your Apple silicon.

## Step 1: Acquire an Ubuntu (20.04 LTS) instance

You will need to be able to SSH into it as the root user.

I highly recommend creating a [Kamatera](https://kamatera.com) Type A (availability) VPS instance with at least 1GB of RAM and 20GB of storage. It's cheap (but not free), easy, and works great for running a Docker daemon.

## Step 2: Install the Docker client

Run the [setup-local-docker-client.sh](setup-local-docker-client.sh) script by pasting the following command in a terminal.

```bash
bash <(curl -sL https://raw.githubusercontent.com/Shakeskeyboarde/docker-remote/main/setup-local-docker-client.sh)
```

This script will download a tarball of the latest stable Docker client, and extract the `docker` binary to your `/usr/local/bin` directory. This will _NOT_ install the Docker daemon locally. You can run this script again at anytime to upgrade or re-install the Docker client.

When it's done, you should be able to run the following command:

```bash
docker --version
```

## Step 3: Provision the Docker daemon

Run the [setup-remote-docker-daemon.ts](setup-remote-docker-daemon.sh) script by pasting the following command in a terminal (I'm sensing a pattern).

```bash
bash <(curl -sL https://raw.githubusercontent.com/Shakeskeyboarde/docker-remote/main/setup-remote-docker-daemon.sh)
```

This script will...

1. Ask you for the IP address of your Ubuntu host, and you might have to enter the root user's password once.
2. Install your public key on the remote, so that you don't need to enter a password repeatedly.
3. Install the Docker daemon on the remote.
4. Generate self-signed TLS certs and configure the daemon for TLS secured TCP connections.
5. Download the client TLS certs to your local `~/.docker` directory.
6. Print out an export string which configures the Docker client to connect to the remote Docker daemon.
   - Example: `export DOCKER_TLS_VERIFY=1 DOCKER_HOST=tcp://1.2.3.4:2376`

You can run this script again at any time to upgrade or re-provision the Docker daemon, or to generate new certs.

## Step 4: Profit.

That's it. You can now use `docker` commands the same way you always have.
