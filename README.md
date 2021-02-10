# Docker on Apple silicon

This repository contains instructions and setup scripts for installing the Docker client (`docker` CLI) locally, the Docker daemon remotely (on Ubuntu), and configuring them to work together.

**Q:** Why would you want to do this?

**A:** Because support for Docker on Apple silicon is still progressing. And, even when Docker becomes Apple native, it will still only run Apple containers. Running the daemon remotely not only allows Docker to work now, but also means we can continue to use Linux containers. This is important, partly because there are a lot of them and not all will be ported to Apple, but mostly because we aren't deploying containers to Apple servers just yet (maybe someday).

&nbsp;

# Let's begin.

Follow these three (easy-ish) steps follow to get Docker working on your Apple silicon.

## Step 1: Acquire an Ubuntu (20.04 LTS) instance

You will need to be able to SSH into it as the root user.

I highly recommend creating a [Kamatera](https://kamatera.com) Type A (availability) VPS instance with at least 1GB of RAM and 20GB of storage. It's cheap (but not free), easy, and works great for running a Docker daemon.

## Step 2: Install the Docker client

Run the [setup-local-docker-client.sh](setup-local-docker-client.sh) script by pasting the following command in a terminal.

```bash
bash <(curl -sL https://raw.githubusercontent.com/Shakeskeyboarde/docker-remote/main/setup-local-docker-client.sh)
```

This script will download a tarball of the latest stable Docker client, and extract the `docker` binary to your `/usr/local/bin` directory. This will _NOT_ install the Docker daemon locally.

When it's done, you should be able to run the following command:

```bash
docker --version
```

## Step 3: Provision the Docker daemon

Run the [setup-remote-docker-daemon.ts](setup-remote-docker-daemon.sh) script by pasting the following command in a terminal (I'm sensing a pattern).

```bash
bash <(curl -s https://raw.githubusercontent.com/Shakeskeyboarde/docker-remote/main/setup-remote-docker-daemon.sh)
```

This script will...

1. Ask you for the IP address of your Ubuntu host, and you might have to enter the root user's password once.
2. Install your public key on the remote, so that you don't need to enter a password repeatedly.
3. Install the Docker daemon on the remote.
4. Generate self-signed TLS certs and configure the daemon for TLS secured TCP connections.
5. Download the client TLS certs to your local `~/.docker` directory.
6. Print out an export string which configures the Docker client to connect to the remote Docker daemon.
   - Example: `export DOCKER_TLS_VERIFY=1 DOCKER_HOST=tcp://1.2.3.4:2376`

## Step 4: Profit.

That's it. You can now use `docker` commands the same way you always have.
