#!/bin/bash

# Argumen yang diterima dari bot (via install.js)
IP_VPS=$1
PW_VPS=$2
DOMAIN=$3
NODE_DOMAIN=$4
RAM_VPS=$5
ADMIN_PASS=$6
ADMIN_EMAIL="admin@admin.com"

echo "Memulai instalasi panel untuk $DOMAIN..."

# 1. Update sistem (Opsional)
apt update && apt upgrade -y

# 2. Download Script Pterodactyl (Contoh pakai script instalasi populer)
# Ganti link ini dengan link script instalasi milikmu sendiri
wget https://raw.githubusercontent.com/pterodactyl/installer/master/install.sh
bash install.sh <<EOF
y
y
y
y
$ADMIN_EMAIL
admin
Admin
User
$ADMIN_PASS
$DOMAIN
EOF

# 3. Auto Create Node (Menggunakan perintah internal artisan)
cd /var/www/pterodactyl
php artisan p:node:make <<EOF
Node-Auto
http
$NODE_DOMAIN
8080
$RAM_VPS
20000
100
1
EOF

# 4. Auto Create Location
php artisan p:location:make <<EOF
ID
Indonesia
EOF

# 5. Import Egg (Jika file JSON sudah ada di server)
# Kamu bisa menaruh file .json di folder bot/eggs dan copy ke sini
# php artisan p:egg:import /path/to/egg.json

echo "Instalasi selesai!"
