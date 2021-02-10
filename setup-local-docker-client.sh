#!/usr/bin/env bash
set -e

__TEMP__=$(mktemp -d)
function finish() {
  rm -rf "$__TEMP__"
}
trap finish EXIT

__VERSION__=$(curl -s https://download.docker.com/mac/static/stable/x86_64/ | grep -oE "docker-[0-9.]+\.tgz" | tail -n 1 | grep -oE "[0-9.]+[0-9]")
echo "Downloading Docker CLI v$__VERSION__"
curl -so "$__TEMP__/docker-client.tar.gz" "https://download.docker.com/mac/static/stable/x86_64/docker-$__VERSION__.tgz"
tar xzf "$__TEMP__/docker-client.tar.gz" -C "$__TEMP__"

echo "Copying to '/usr/local/bin/docker'"
sudo cp -f "$__TEMP__/docker/docker" /usr/local/bin/

echo "$(tput bold)$(tput setaf 2)Done.$(tput sgr0)"

echo $(tput setaf 3)
echo "Run the'docker --version' command to test."
echo $(tput sgr0)
