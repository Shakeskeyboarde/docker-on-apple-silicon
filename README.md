# Docker on Apple (ARM64) using a remote daemon on Ubuntu (AMD64)

This repository contains instructions and setup scripts for installing the Docker client locally (Apple), the Docker daemon remotely (Ubuntu), and configuring them to work together.

**Q:** Why?

**A:** Getting a MacBook with an ARM64 processor means that my development machine is no longer the same arch as my deployment environments, which are all AMD64. My dev and deployment environments have frequently been running different operating systems, but still all on AMD64 processors. While the Docker tech preview can actually run and build linux/amd64 images with emulation (awesome!), I'd rather just side-step the whole issue and have my containers run un-emulated, on a daemon running remotely on a linux/amd64 VPS. It's a neat way to develop directly on my target platform. And it has some other side benefits...

### Pros

- Remote containers don't use local resources.
- Remote containers continue running when I close my laptop.
- It can be a very fast way to create a public endpoint which another person can consume, for demo or collaboration purposes.
- Security-wise, the running containers are "sandboxed" on the remote host, preventing potential malicious behavior on my local machine.

### Cons

- If running containers have listeners, they will be listening _on the remote host's public IP._ This can be a good thing as long as you're aware of it. It's a great way to quickly demo things for other people. But, if you're not okay with public listeners, then I suggest you try setting up a VPN or an SSH tunnel, and using iptables to lock down incoming connections to the VPS. But that's beyond the scope of this document.
- Using volumes/mounts will target the filesystem _of the remote host_, not your local file system. If you need to share the remote host's file system with your local machine, I recommend checking out SSHFS. But again, that's beyond the scope of this document.

&nbsp;

# Let's begin.

Follow these three (easy-ish) steps to get Docker working on your Apple silicon.

## Step 1: Acquire an Ubuntu (20.04 LTS) instance

You will need to be able to SSH into it as the root user.

I highly recommend creating a [Kamatera](https://kamatera.com) Type A (availability) VPS instance with at least 1GB of RAM and 20GB of storage. It's cheap (but not free), easy, and works great for running a Docker daemon.

## Step 2: Install the Docker client

Run the [setup-local-docker-client.sh](setup-local-docker-client.sh) script by pasting the following command in a terminal.

```bash
bash <(curl -sL https://raw.githubusercontent.com/Shakeskeyboarde/docker-remote-daemon/main/setup-local-docker-client.sh)
```

This script will download a tarball of the latest stable Docker client, and extract the `docker` binary to your `/usr/local/bin` directory. This will _NOT_ install the Docker daemon locally. You can run this script again at anytime to upgrade or re-install the Docker client.

When it's done, you should be able to run the following command:

```bash
docker --version
```

## Step 3: Provision the Docker daemon

Run the [setup-remote-docker-daemon.ts](setup-remote-docker-daemon.sh) script by pasting the following command in a terminal (I'm sensing a pattern).

```bash
bash <(curl -sL https://raw.githubusercontent.com/Shakeskeyboarde/docker-remote-daemon/main/setup-remote-docker-daemon.sh)
```

This script will...

1. Ask you for the SSH endpoint (eg. root@1.2.3.4) of your Ubuntu host, and you might have to enter the user's password once.
2. Install your public key on the remote, so that you don't need to enter a password repeatedly.
3. Install the Docker daemon on the remote.
4. Create a local Docker context called `remote`.

You can add `export DOCKER_CONTEXT=remote` to your `.zshrc` and/or `.bashrc` file to make it the default context. Or select it every time using the `--context` option.

You can run this script again at any time to upgrade or re-provision the Docker daemon.

## Step 4: Profit.

That's it. You can now use `docker` commands the same way you always have.
