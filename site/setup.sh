#!/bin/sh
# Adds the RSRB APT repository:  curl -fsSL https://syntax-xxx.github.io/rsrb/setup.sh | sudo sh
set -e
URL=https://syntax-xxx.github.io/rsrb
[ "$(id -u)" = 0 ] || { echo "Please run as root (sudo)." >&2; exit 1; }
command -v apt-get >/dev/null || { echo "Debian/Ubuntu only." >&2; exit 1; }
command -v curl >/dev/null || { apt-get update -q && apt-get install -y -q curl ca-certificates; }
curl -fsSL "$URL/rsrb.gpg" -o /usr/share/keyrings/rsrb.gpg
echo "deb [signed-by=/usr/share/keyrings/rsrb.gpg] $URL stable main" > /etc/apt/sources.list.d/rsrb.list
apt-get update -q
echo
echo "RSRB repository added. Next, for example:"
echo "  apt install rackpanel        # NAS web UI (asks for user and password)"
echo "  apt install rsrb-neofetch    # neofetch with the RSRB logo"
echo "  apt install rsrb-release     # brand the system as RSRB"
