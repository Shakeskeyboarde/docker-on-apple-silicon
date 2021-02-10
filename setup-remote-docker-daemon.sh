#!/usr/bin/env bash
set -e

__SSH_ENDPOINT__=$1

if [ -z "$__SSH_ENDPOINT__" ]; then
  echo $(tput bold)$(tput setaf 4)
  echo "Enter the SSH endpoint (eg. root@1.2.3.4) of an Ubuntu"
  echo "instance where the remote Docker daemon should be"
  echo "provisioned."
  echo $(tput sgr0)
  read -p "$(tput setaf 3)SSH Endpoint? $(tput sgr0)" __SSH_ENDPOINT__
fi

echo $(tput bold)$(tput setaf 4)
echo "The Docker daemon will be provisioned over SSH."
echo $(tput smul)
echo "Other changes that will be made:"
echo $(tput rmul)
echo "- Your public key will be added to the remote host's"
echo "  authorized_keys file."
echo $(tput sgr0)

read -p "$(tput setaf 3)Continue [yN]? $(tput sgr0)" -n 1 -r
echo
echo

if ! [[ $REPLY =~ ^[Yy]$ ]]; then
  exit
fi

function die() {
  local ERR=$?
  echo "$@"
  exit $ERR
}

echo "Setting up public key authentication"
cat /dev/zero | ssh-keygen -t rsa -q -N "" &>/dev/null || true
ssh-copy-id -i "$__SSH_ENDPOINT__"

echo "Provisioning remote Docker daemon"
ssh -qtt "$__SSH_ENDPOINT__" <<'REMOTE'
  set -e

  # Installing Docker daemon
  DEBIAN_FRONTEND=noninteractive
  apt-get remove docker docker-engine docker.io containerd runc
  apt-get update
  apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"
  apt-get update
  apt-get install docker-ce docker-ce-cli containerd.io
  systemctl restart docker.service

  logout
REMOTE

echo "Creating remote Docker context"
docker context rm remote || true
docker context create remote --docker "host=ssh://$__SSH_ENDPOINT__"

echo "$(tput bold)$(tput setaf 2)Done.$(tput sgr0)"

echo $(tput setaf 3)

echo "Running the following export command will set the Docker"
echo "context to the remote daemon. You can also add the export"
echo "to your .bashrc and/or .zshrc file to make it the default"
echo "context."
echo $(tput sgr0)$(tput bold)

echo "  export DOCKER_CONTEXT=remote"

echo $(tput sgr0)$(tput setaf 3)
echo "Run the 'docker info' command to test."
echo $(tput sgr0)
