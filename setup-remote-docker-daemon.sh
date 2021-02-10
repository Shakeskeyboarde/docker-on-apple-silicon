#!/usr/bin/env bash
set -e

__IP__=$1

if [ -z "$__IP__" ]; then
  echo $(tput bold)$(tput setaf 4)
  echo "Enter the IP address of an Ubuntu instance where the"
  echo "remote Docker daemon should be provisioned."
  echo $(tput sgr0)
  read -p "$(tput setaf 3)IP Address? $(tput sgr0)" __IP__
fi


echo $(tput bold)$(tput setaf 4)
echo "The Docker daemon will be provisioned over SSH as the"
echo "root user."
echo
echo "$(tput smul)Other changes that will be made:$(tput rmul)"
echo
echo "- Your public key will be added to the remote host's"
echo "  authorized_keys file."
echo
echo "- The self-signed client certificates required for TLS"
echo "  connections to the daemon, will be copied to your"
echo "  local ~/.docker directory."
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
ssh-copy-id -i "root@$__IP__"

echo "Configuring remote Docker daemon"
__VARS__=$(cat <<__VARS__
  __IP__=$__IP__
__VARS__
)
__SCRIPT__=$(cat <<'__SCRIPT__'
  set -e
  HOST=$(hostname)
  __PASSPHRASE__=$(openssl rand -base64 32)

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

  mkdir -p /etc/docker/ssl
  cd /etc/docker/ssl

  # Generating self-signing CA
  openssl genrsa -aes256 -out ca-key.pem -passout pass:"$__PASSPHRASE__" 4096
  openssl req -new -x509 -days 365 -key ca-key.pem -sha256 -out ca.pem \
    -passin pass:"$__PASSPHRASE__" \
    -subj "/C=US/ST=Washington/L=Seattle/O=None/OU=None/CN=$HOST"

  # Generating server key and CSR
  openssl genrsa -out server-key.pem 4096
  openssl req -subj "/CN=$HOST" -sha256 -new -key server-key.pem -out server.csr

  # Signing server cert
  echo subjectAltName = DNS:$HOST,IP:$__IP__,IP:127.0.0.1 >> extfile.cnf
  echo extendedKeyUsage = serverAuth >> extfile.cnf
  openssl x509 -req -days 365 -sha256 -in server.csr -CA ca.pem -CAkey ca-key.pem \
    -passin pass:"$__PASSPHRASE__" \
    -CAcreateserial -out server-cert.pem -extfile extfile.cnf

  # Generating client key and CSR
  openssl genrsa -out key.pem 4096
  openssl req -subj '/CN=client' -new -key key.pem -out client.csr

  # Signing client cert
  echo extendedKeyUsage = clientAuth > extfile-client.cnf
  openssl x509 -req -days 365 -sha256 -in client.csr -CA ca.pem -CAkey ca-key.pem \
    -passin pass:"$__PASSPHRASE__" \
    -CAcreateserial -out cert.pem -extfile extfile-client.cnf

  # Reducing cert file permissions
  rm -f client.csr server.csr extfile.cnf extfile-client.cnf
  chmod -v 0400 ca-key.pem key.pem server-key.pem
  chmod -v 0444 ca.pem server-cert.pem cert.pem
  
  # Enabling Docker daemon TLS
  echo '{
    "tls": true,
    "tlscacert": "/etc/docker/ssl/ca.pem",
    "tlscert": "/etc/docker/ssl/server-cert.pem",
    "tlskey": "/etc/docker/ssl/server-key.pem",
    "tlsverify": true
  }' > /etc/docker/daemon.json

  # Enabling Docker daemon TCP listener
  mkdir -p /etc/systemd/system/docker.service.d
  echo '[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock -H tcp://0.0.0.0:2376' \
  > /etc/systemd/system/docker.service.d/tcp_secure.conf

  # Restarting the Docker daemon
  systemctl daemon-reload
  systemctl restart docker.service

  logout
__SCRIPT__
)
ssh -qtt "root@$__IP__" <<__REMOTE__
  $__VARS__
  $__SCRIPT__
__REMOTE__

echo "Getting client certs"
mkdir -p ~/.docker
rm -f ~/.docker/{ca,cert,key}.pem
scp -q "root@$__IP__:/etc/docker/ssl/{ca,cert,key}.pem" ~/.docker

echo "$(tput bold)$(tput setaf 2)Done.$(tput sgr0)"

echo
echo "$(tput setaf 3)Put the following line in your .bashrc or .zshrc file.$(tput sgr0)"
echo "$(tput bold)  export DOCKER_TLS_VERIFY=1 DOCKER_HOST=tcp://$__IP__:2376$(tput sgr0)"
echo
