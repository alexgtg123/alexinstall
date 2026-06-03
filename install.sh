#!/bin/bash

# ============================================================
#   AUTO INSTALLER - Pterodactyl Panel + Node + Bot SC
#   By: Owner Setup Script
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════╗"
echo "║     PTERODACTYL AUTO INSTALLER v1.0      ║"
echo "║         Panel + Wings + Bot SC           ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"

# ─── Cek root ───────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[ERROR] Jalankan sebagai root: sudo bash install.sh${NC}"
  exit 1
fi

# ─── Input dari user ────────────────────────────────────────
read -p "$(echo -e ${YELLOW}[?] Masukkan domain panel \(contoh: panel.domain.com\): ${NC})" PANEL_DOMAIN
read -p "$(echo -e ${YELLOW}[?] Masukkan email admin panel: ${NC})" ADMIN_EMAIL
read -s -p "$(echo -e ${YELLOW}[?] Masukkan password admin panel: ${NC})" ADMIN_PASS
echo ""
read -p "$(echo -e ${YELLOW}[?] Masukkan IP VPS ini: ${NC})" VPS_IP
read -p "$(echo -e ${YELLOW}[?] Masukkan nama node \(contoh: Node-ID-1\): ${NC})" NODE_NAME
read -p "$(echo -e ${YELLOW}[?] Masukkan domain/subdomain node \(contoh: node1.domain.com\): ${NC})" NODE_DOMAIN
read -p "$(echo -e ${YELLOW}[?] RAM VPS tersedia untuk node \(MB, contoh: 4096\): ${NC})" NODE_RAM
read -p "$(echo -e ${YELLOW}[?] Disk VPS tersedia untuk node \(MB, contoh: 20480\): ${NC})" NODE_DISK
read -p "$(echo -e ${YELLOW}[?] Port allocation awal \(contoh: 25565\): ${NC})" ALLOC_PORT_START
read -p "$(echo -e ${YELLOW}[?] Port allocation akhir \(contoh: 25665\): ${NC})" ALLOC_PORT_END

echo ""
echo -e "${CYAN}[INFO] Memulai instalasi...${NC}"
sleep 2

# ════════════════════════════════════════════════════════════
#  STEP 1 — UPDATE & DEPENDENCY
# ════════════════════════════════════════════════════════════
echo -e "${GREEN}[1/8] Update sistem & install dependency...${NC}"
apt -y update && apt -y upgrade
apt -y install curl wget git tar unzip software-properties-common \
  apt-transport-https ca-certificates gnupg2 lsb-release \
  nginx certbot python3-certbot-nginx mariadb-server redis-server \
  php8.1 php8.1-cli php8.1-fpm php8.1-mysql php8.1-mbstring \
  php8.1-bcmath php8.1-xml php8.1-curl php8.1-zip php8.1-gd \
  php8.1-intl composer nodejs npm jq

# ════════════════════════════════════════════════════════════
#  STEP 2 — INSTALL NODE.JS (LTS via NodeSource)
# ════════════════════════════════════════════════════════════
echo -e "${GREEN}[2/8] Install Node.js LTS (hijau/stable)...${NC}"
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt -y install nodejs
echo -e "${CYAN}    Node.js version: $(node -v)${NC}"
echo -e "${CYAN}    NPM version    : $(npm -v)${NC}"

# ════════════════════════════════════════════════════════════
#  STEP 3 — SETUP DATABASE
# ════════════════════════════════════════════════════════════
echo -e "${GREEN}[3/8] Setup MariaDB untuk Pterodactyl...${NC}"
systemctl enable mariadb && systemctl start mariadb

DB_PASS=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 20)

mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS panel;
CREATE USER IF NOT EXISTS 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1';
FLUSH PRIVILEGES;
EOF

echo -e "${CYAN}    DB User : pterodactyl${NC}"
echo -e "${CYAN}    DB Pass : ${DB_PASS}${NC}"
echo -e "${CYAN}    DB Name : panel${NC}"

# ════════════════════════════════════════════════════════════
#  STEP 4 — INSTALL PTERODACTYL PANEL
# ════════════════════════════════════════════════════════════
echo -e "${GREEN}[4/8] Download & install Pterodactyl Panel...${NC}"
mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl
curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
tar -xzvf panel.tar.gz
chmod -R 755 storage/* bootstrap/cache/

cp .env.example .env
composer install --no-dev --optimize-autoloader --no-interaction

php artisan key:generate --force

php artisan p:environment:setup \
  --author="${ADMIN_EMAIL}" \
  --url="https://${PANEL_DOMAIN}" \
  --timezone="Asia/Jakarta" \
  --cache=redis \
  --session=database \
  --queue=redis \
  --redis-host=127.0.0.1 \
  --redis-pass="" \
  --redis-port=6379 \
  --no-interaction

php artisan p:environment:database \
  --host=127.0.0.1 \
  --port=3306 \
  --database=panel \
  --username=pterodactyl \
  --password="${DB_PASS}" \
  --no-interaction

php artisan migrate --seed --force

php artisan p:user:make \
  --email="${ADMIN_EMAIL}" \
  --username="admin" \
  --name-first="Admin" \
  --name-last="Owner" \
  --password="${ADMIN_PASS}" \
  --admin=1 \
  --no-interaction

chown -R www-data:www-data /var/www/pterodactyl/
chmod -R 755 /var/www/pterodactyl/storage /var/www/pterodactyl/bootstrap/cache

# ─── Queue Worker ────────────────────────────────────────────
cat > /etc/systemd/system/pteroq.service <<EOF
[Unit]
Description=Pterodactyl Queue Worker
After=redis-server.service

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/php /var/www/pterodactyl/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

systemctl enable --now pteroq.service

# ════════════════════════════════════════════════════════════
#  STEP 5 — NGINX + SSL
# ════════════════════════════════════════════════════════════
echo -e "${GREEN}[5/8] Konfigurasi Nginx & SSL...${NC}"

cat > /etc/nginx/sites-available/pterodactyl.conf <<EOF
server {
    listen 80;
    server_name ${PANEL_DOMAIN};
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl http2;
    server_name ${PANEL_DOMAIN};

    root /var/www/pterodactyl/public;
    index index.php;

    ssl_certificate /etc/letsencrypt/live/${PANEL_DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${PANEL_DOMAIN}/privkey.pem;

    access_log /var/log/nginx/pterodactyl.app-access.log;
    error_log  /var/log/nginx/pterodactyl.app-error.log error;

    client_max_body_size 100m;
    client_body_timeout 120s;

    sendfile off;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

ln -sf /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

certbot --nginx -d "${PANEL_DOMAIN}" --non-interactive --agree-tos -m "${ADMIN_EMAIL}"
systemctl restart nginx

# ════════════════════════════════════════════════════════════
#  STEP 6 — INSTALL WINGS (NODE DAEMON)
# ════════════════════════════════════════════════════════════
echo -e "${GREEN}[6/8] Install Pterodactyl Wings...${NC}"
mkdir -p /etc/pterodactyl
curl -L -o /usr/local/bin/wings \
  "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64"
chmod u+x /usr/local/bin/wings

# Install Docker
curl -fsSL https://get.docker.com | bash
systemctl enable --now docker

cat > /etc/systemd/system/wings.service <<EOF
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

systemctl enable wings

# ════════════════════════════════════════════════════════════
#  STEP 7 — BUAT NODE + ALLOCATION VIA API
# ════════════════════════════════════════════════════════════
echo -e "${GREEN}[7/8] Membuat Node & Allocation otomatis via API...${NC}"

sleep 5  # tunggu panel siap

# Ambil API key admin
API_KEY=$(cd /var/www/pterodactyl && php artisan p:api:key:create \
  --email="${ADMIN_EMAIL}" \
  --memo="auto-installer" \
  --no-interaction 2>/dev/null | grep -oP 'ptla_[a-zA-Z0-9]+' | head -1)

# Ambil location ID (buat default location dulu jika belum ada)
LOC_RESP=$(curl -s -X POST "https://${PANEL_DOMAIN}/api/application/locations" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"short":"ID","long":"Indonesia"}')
LOC_ID=$(echo "$LOC_RESP" | jq -r '.attributes.id // 1')

# Buat node
NODE_RESP=$(curl -s -X POST "https://${PANEL_DOMAIN}/api/application/nodes" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "{
    \"name\": \"${NODE_NAME}\",
    \"location_id\": ${LOC_ID},
    \"fqdn\": \"${NODE_DOMAIN}\",
    \"scheme\": \"https\",
    \"memory\": ${NODE_RAM},
    \"memory_overallocate\": 0,
    \"disk\": ${NODE_DISK},
    \"disk_overallocate\": 0,
    \"upload_size\": 100,
    \"daemon_sftp\": 2022,
    \"daemon_listen\": 8080
  }")
NODE_ID=$(echo "$NODE_RESP" | jq -r '.attributes.id')

echo -e "${CYAN}    Node ID: ${NODE_ID}${NC}"

# Buat allocation range
curl -s -X POST "https://${PANEL_DOMAIN}/api/application/nodes/${NODE_ID}/allocations" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "{
    \"ip\": \"${VPS_IP}\",
    \"ports\": [$(seq -s, ${ALLOC_PORT_START} ${ALLOC_PORT_END})]
  }" > /dev/null

echo -e "${CYAN}    Allocation ${ALLOC_PORT_START}-${ALLOC_PORT_END} berhasil dibuat!${NC}"

# Download wings config dari panel
curl -s "https://${PANEL_DOMAIN}/api/application/nodes/${NODE_ID}/configuration" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Accept: application/json" \
  > /etc/pterodactyl/config.yml

systemctl start wings

# ════════════════════════════════════════════════════════════
#  STEP 8 — INSTALL EGG PYTHON & NODE.JS
# ════════════════════════════════════════════════════════════
echo -e "${GREEN}[8/8] Install Egg Python & Node.js...${NC}"

# Download official eggs dari Pterodactyl
mkdir -p /tmp/eggs
cd /tmp/eggs

# Python Generic Egg
curl -sLO "https://raw.githubusercontent.com/pterodactyl/yolks/master/nodejs/18/Dockerfile"
curl -sLO "https://github.com/parkervcp/eggs/raw/master/generic/python/egg-generic-python.json"
curl -sLO "https://github.com/parkervcp/eggs/raw/master/generic/nodejs/egg-generic-node-js.json"

# Import eggs via API
for EGG_FILE in egg-generic-python.json egg-generic-node-js.json; do
  if [ -f "$EGG_FILE" ]; then
    NEST_ID=$(curl -s "https://${PANEL_DOMAIN}/api/application/nests" \
      -H "Authorization: Bearer ${API_KEY}" \
      -H "Accept: application/json" | jq -r '.data[0].attributes.id // 1')

    curl -s -X POST "https://${PANEL_DOMAIN}/api/application/nests/${NEST_ID}/eggs" \
      -H "Authorization: Bearer ${API_KEY}" \
      -H "Content-Type: application/json" \
      -H "Accept: application/json" \
      -d @"$EGG_FILE" > /dev/null

    echo -e "${CYAN}    Egg ${EGG_FILE} berhasil diimport!${NC}"
  fi
done

# ════════════════════════════════════════════════════════════
#  STEP 9 — INSTALL BOT SC
# ════════════════════════════════════════════════════════════
echo -e "${GREEN}[+] Setup Bot SC Telegram...${NC}"

mkdir -p /opt/pterodactyl-bot
cd /opt/pterodactyl-bot

# Copy bot files (diasumsikan ada di direktori yang sama dengan install.sh)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

for FILE in config.js alicia.js installer.js main.js package.json; do
  if [ -f "${SCRIPT_DIR}/${FILE}" ]; then
    cp "${SCRIPT_DIR}/${FILE}" /opt/pterodactyl-bot/
    echo -e "${CYAN}    Copied: ${FILE}${NC}"
  else
    echo -e "${YELLOW}    [WARNING] ${FILE} tidak ditemukan di ${SCRIPT_DIR}${NC}"
  fi
done

npm install

# Buat systemd service untuk bot
cat > /etc/systemd/system/pterodactyl-bot.service <<EOF
[Unit]
Description=Pterodactyl SC Bot
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/pterodactyl-bot
ExecStart=/usr/bin/node alicia.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

systemctl enable --now pterodactyl-bot

# ════════════════════════════════════════════════════════════
#  DONE — TAMPILKAN SUMMARY
# ════════════════════════════════════════════════════════════
echo ""
echo -e "${GREEN}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║              INSTALASI SELESAI! 🎉                       ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo -e "║  Panel URL  : https://${PANEL_DOMAIN}"
echo -e "║  Admin Email: ${ADMIN_EMAIL}"
echo -e "║  DB Pass    : ${DB_PASS}"
echo -e "║  Node ID    : ${NODE_ID}"
echo -e "║  API Key    : ${API_KEY}"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║  PENTING: Simpan info di atas di tempat aman!            ║"
echo "║  Bot SC berjalan di /opt/pterodactyl-bot                 ║"
echo "║  Edit /opt/pterodactyl-bot/config.js untuk konfigurasi   ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Simpan info ke file
cat > /root/pterodactyl-install-info.txt <<EOF
=== PTERODACTYL INSTALL INFO ===
Tanggal    : $(date)
Panel URL  : https://${PANEL_DOMAIN}
Admin Email: ${ADMIN_EMAIL}
DB Pass    : ${DB_PASS}
Node ID    : ${NODE_ID}
API Key    : ${API_KEY}
Bot Dir    : /opt/pterodactyl-bot
EOF

echo -e "${CYAN}Info tersimpan di: /root/pterodactyl-install-info.txt${NC}"
