#!/bin/bash

apt update && apt upgrade -y

curl -sSL https://get.docker.com/ | CHANNEL=stable bash

systemctl enable docker
systemctl start docker

mkdir -p /etc/pterodactyl

curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64"

chmod u+x /usr/local/bin/wings

curl -o /etc/systemd/system/wings.service https://raw.githubusercontent.com/pterodactyl/wings/master/wings.service

cd /var/www/pterodactyl || {
  echo "Panel tidak ditemukan"
  exit 1
}

NODE_ID=$(php artisan tinker --execute="echo optional(\Pterodactyl\Models\Node::latest()->first())->id;" | grep -E '^[0-9]+$' | tail -n 1)

if [ -z "$NODE_ID" ]; then
  echo "Gagal mendapatkan Node ID"
  exit 1
fi

php artisan p:node:configuration $NODE_ID > /etc/pterodactyl/config.yml

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable wings
systemctl restart wings

sleep 5

echo ""
echo "=============================="
echo "STATUS WINGS"
echo "=============================="

if systemctl is-active --quiet wings; then
    echo "[SUKSES] Wings berhasil ONLINE!"
else
    echo "[ERROR] Wings gagal start"
    systemctl status wings
fi
