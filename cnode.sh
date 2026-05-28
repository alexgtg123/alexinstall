#!/bin/bash

cd /var/www/pterodactyl || {
  echo "Panel tidak ditemukan"
  exit 1
}

LOCATION_NAME="NODE BY ALICIA"
LOCATION_DESC="Jangan Lupa Dukung Alicia Ku🗿"

NODE_NAME="NODE BY ALICIA"
DOMAIN="node.domain.com"

RAM="4096"
DISK="4096"
LOCATION_ID="1"

php artisan p:location:make <<EOF
$LOCATION_NAME
$LOCATION_DESC
EOF

php artisan p:node:make <<EOF
$NODE_NAME
$LOCATION_DESC
$LOCATION_ID
https
$DOMAIN
yes
no
no
$RAM
$RAM
$DISK
$DISK
100
8080
2022
/var/lib/pterodactyl/volumes
EOF

NODE_ID=$(php artisan tinker --execute="echo optional(\Pterodactyl\Models\Node::latest()->first())->id;" | grep -E '^[0-9]+$' | tail -n 1)

if [ -z "$NODE_ID" ]; then
  echo "Gagal mendapatkan Node ID"
  exit 1
fi

php artisan p:allocation:make <<EOF
$NODE_ID
0.0.0.0
25565-25600
EOF

echo "=================================="
echo "CREATE NODE BERHASIL"
echo "=================================="
echo "Location : $LOCATION_NAME"
echo "Node ID  : $NODE_ID"
echo "Domain   : $DOMAIN"
echo "RAM      : $RAM"
echo "Disk     : $DISK"
echo "=================================="
