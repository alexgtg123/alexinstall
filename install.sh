#!/bin/bash

# Pastikan dijalankan sebagai root
if [[ $EUID -ne 0 ]]; then
   echo "Skrip ini harus dijalankan sebagai root"
   exit 1
fi

IPVPS=$1
PWVPS=$2
DOMAIN=$3
NODEDOMAIN=$4
RAM=$5
ADMINPW=$6

# 1. Jalankan Installer Resmi
bash <(curl -s https://pterodactyl-installer.se) <<EOF
0
y
y
y
$DOMAIN
Asia/Jakarta
admin@admin.com
admin
admin
Lipzz
Store
$ADMINPW
y
y
y
y
EOF

# 2. Impor Nest & Egg secara otomatis
# Pastikan link ini mengarah ke file egg.json di repo kamu
curl -o /root/egg.json https://raw.githubusercontent.com/alexgtg123/alexinstall/main/egg.json

# Buat Nest baru dulu (Contoh ID Nest: 1)
php /var/www/pterodactyl/artisan p:nest:create --name="Alicia Nests" --description="Nest dari Alicia Yaitu Istri Alip🤭, Gw gak pedo ya, gw seumuran🗿"

# Impor Egg ke dalam Nest tersebut
php /var/www/pterodactyl/artisan p:egg:import /root/egg.json --nest=1

# 3. Konfigurasi Node
php /var/www/pterodactyl/artisan p:node:make --name="Node-Alicia" --fqdn=$NODEDOMAIN --memory=$RAM --disk=100000 --daemon-token=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32) --ip=$IPVPS

# 4. Tambahkan Allocation
php /var/www/pterodactyl/artisan p:allocation:add --node=1 --ip=$IPVPS --port=25565-25570

# 5. Reset Password Admin
php /var/www/pterodactyl/artisan p:user:password --email="admin@admin.com" --password="$ADMINPW"

echo "Instalasi selesai!"
