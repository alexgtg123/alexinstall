#!/bin/bash

# ============================================================
#   AUTO INSTALLER - Pterodactyl Panel + Node
#   By: Alex
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════╗"
echo "║     PTERODACTYL AUTO INSTALLER v2.0      ║"
echo "║           Panel + Wings + Node           ║"
echo "╚══════════════════════════════════════════╝"
echo -e "${NC}"

# ─── Cek root ───────────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[ERROR] Jalankan sebagai root: sudo bash install.sh${NC}"
  exit 1
fi

# ─── Ambil argumen (dikirim dari bot via SSH) ────────────────
# Usage: bash install.sh auto "panel.com" "email" "pass" "ip" "Node-1" "node.com" "4096" "20480" "25565" "25665"
MODE="$1"

if [ "$MODE" = "auto" ]; then
  PANEL_DOMAIN="$2"
  ADMIN_EMAIL="$3"
  ADMIN_PASS="$4"
  VPS_IP="$5"
  NODE_NAME="$6"
  NODE_DOMAIN="$7"
  NODE_RAM="$8"
  NODE_DISK="$9"
  ALLOC_PORT_START="${10}"
  ALLOC_PORT_END="${11}"

  echo -e "${CYAN}[AUTO MODE] Menggunakan parameter dari bot...${NC}"
else
  # ─── Mode manual: input interaktif ──────────────────────────
  read -p "$(echo -e ${YELLOW}[?] Domain panel \(contoh: panel.domain.com\): ${NC})" PANEL_DOMAIN
  read -p "$(echo -e ${YELLOW}[?] Email admin panel: ${NC})" ADMIN_EMAIL
  read -p "$(echo -e ${YELLOW}[?] Password admin panel: ${NC})" ADMIN_PASS
  read -p "$(echo -e ${YELLOW}[?] IP VPS ini: ${NC})" VPS_IP
  read -p "$(echo -e ${YELLOW}[?] Nama node \(contoh: Node-ID-1\): ${NC})" NODE_NAME
  read -p "$(echo -e ${YELLOW}[?] Domain node \(contoh: node1.domain.com\): ${NC})" NODE_DOMAIN
  read -p "$(echo -e ${YELLOW}[?] RAM untuk node \(MB, contoh: 4096\): ${NC})" NODE_RAM
  read -p "$(echo -e ${YELLOW}[?] Disk untuk node \(MB, contoh: 20480\): ${NC})" NODE_DISK
  read -p "$(echo -e ${YELLOW}[?] Port allocation awal \(contoh: 25565\): ${NC})" ALLOC_PORT_START
  read -p "$(echo -e ${YELLOW}[?] Port allocation akhir \(contoh: 25665\): ${NC})" ALLOC_PORT_END
fi

# ─── Validasi parameter ──────────────────────────────────────
if [ -z "$PANEL_DOMAIN" ] || [ -z "$ADMIN_EMAIL" ] || [ -z "$ADMIN_PASS" ] || [ -z "$VPS_IP" ]; then
  echo -e "${RED}[ERROR] Parameter tidak lengkap!${NC}"
  exit 1
fi

echo ""
echo -e "${CYAN}[INFO] Konfigurasi:"
echo -e "  Panel   : ${PANEL_DOMAIN}"
echo -e "  Node    : ${NODE_DOMAIN}"
echo -e "  IP VPS  : ${VPS_IP}"
echo -e "  RAM     : ${NODE_RAM} MB"
echo -e "  Disk    : ${NODE_DISK} MB${NC}"
echo ""
echo -e "${CYAN}[INFO] Memulai instalasi...${NC}"
sleep 2

# ════════════════════════════════════════════════════════════
#  STEP 1 — UPDATE & DEPENDENCY
# ════════════════════════════════════════════════════════════
echo -e "${GREEN}[1/7] Update sistem & install dependency...${NC}"
export DEBIAN_FRONTEND=noninteractive
apt -y update && apt -y upgrade
apt -y install curl wget git tar unzip software-properties-common \
  apt-transport-https ca-certificates gnupg2 lsb-release \
  nginx certbot python3-certbot-nginx mariadb-server redis-server \
  php8.1 php8.1-cli php8.1-fpm php8.1-mysql php8.1-mbstring \
  php8.1-bcmath php8.1-xml php8.1-curl php8.1-zip php8.1-gd \
  php8.1-intl composer jq

# ════════════════════════════════════════════════════════════
#  STEP 2 — INSTALL NODE.JS LTS
# ════════════════════════════════════════════════════════════
echo -e "${GREEN}[2/7] Install Node.js LTS...${NC}"
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt -y install nodejs
echo -e "${CYAN}    Node.js: $(node -v) | NPM: $(npm -v)${NC}"

# ════════════════════════════════════════════════════════════
#  STEP 3 — SETUP DATABASE
# ════════════════════════════════════════════════════════════
echo -e "${GREEN}[3/7] Setup MariaDB...${NC}"
systemctl enable mariadb && systemctl start mariadb

DB_PASS=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 20)

mysql -u root <<SQLEOF
CREATE DATABASE IF NOT EXISTS panel;
CREATE USER IF NOT EXISTS 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1';
FLUSH PRIVILEGES;
SQLEOF

echo -e "${CYAN}    DB Pass : ${DB_PASS}${NC}"

# ════════════════════════════════════════════════════════════
#  STEP 4 — INSTALL PTERODACTYL PANEL
# ════════════════════════════════════════════════════════════
echo -e "${GREEN}[4/7] Install Pterodactyl Panel...${NC}"
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

# Queue Worker
cat > /etc/systemd/system/pteroq.service <<SVCEOF
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
SVCEOF

systemctl enable --now pteroq.service

# ════════════════════════════════════════════════════════════
#  STEP 5 — NGINX + SSL
# ════════════════════════════════════════════════════════════
echo -e "${GREEN}[5/7] Konfigurasi Nginx & SSL...${NC}"

cat > /etc/nginx/sites-available/pterodactyl.conf <<NGINXEOF
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
NGINXEOF

ln -sf /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

certbot --nginx -d "${PANEL_DOMAIN}" --non-interactive --agree-tos -m "${ADMIN_EMAIL}"
systemctl restart nginx

# ════════════════════════════════════════════════════════════
#  STEP 6 — INSTALL WINGS
# ════════════════════════════════════════════════════════════
echo -e "${GREEN}[6/7] Install Wings...${NC}"
mkdir -p /etc/pterodactyl
curl -L -o /usr/local/bin/wings \
  "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64"
chmod u+x /usr/local/bin/wings

curl -fsSL https://get.docker.com | bash
systemctl enable --now docker

cat > /etc/systemd/system/wings.service <<WINGSEOF
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
WINGSEOF

systemctl enable wings

# ════════════════════════════════════════════════════════════
#  STEP 7 — BUAT NODE + ALLOCATION VIA API
# ════════════════════════════════════════════════════════════
echo -e "${GREEN}[7/7] Membuat Node & Allocation via API...${NC}"

# Tunggu panel benar-benar siap
sleep 10

# ✅ FIX: Ambil API key dengan cara yang benar
# Generate API key via artisan tinker
API_KEY=$(cd /var/www/pterodactyl && php artisan tinker --no-interaction <<TINKER 2>/dev/null | grep -oP 'ptla_[a-zA-Z0-9]+'
\$user = \Pterodactyl\Models\User::where('email', '${ADMIN_EMAIL}')->first();
\$token = \$user->tokens()->create(['name' => 'auto-installer', 'abilities' => ['*']]);
echo \$token->plainTextToken;
TINKER
)

# Fallback: coba cara lain jika tinker gagal
if [ -z "$API_KEY" ]; then
  echo -e "${YELLOW}    Mencoba generate API key cara alternatif...${NC}"
  API_KEY=$(cd /var/www/pterodactyl && php artisan p:user:make \
    --email="apibot@internal.local" \
    --username="apibot" \
    --name-first="API" \
    --name-last="Bot" \
    --password="$(openssl rand -base64 12)" \
    --admin=1 \
    --no-interaction 2>/dev/null | grep -oP 'ptla_[a-zA-Z0-9]+' | head -1)
fi

if [ -z "$API_KEY" ]; then
  echo -e "${YELLOW}    [WARNING] API key tidak berhasil digenerate otomatis.${NC}"
  echo -e "${YELLOW}    Buat manual di panel: Admin > Application API > Create${NC}"
  API_KEY="MANUAL_REQUIRED"
fi

echo -e "${CYAN}    API Key: ${API_KEY}${NC}"

# Buat location
LOC_RESP=$(curl -s -X POST "https://${PANEL_DOMAIN}/api/application/locations" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"short":"ID","long":"Indonesia"}')
LOC_ID=$(echo "$LOC_RESP" | jq -r '.attributes.id // 1')
echo -e "${CYAN}    Location ID: ${LOC_ID}${NC}"

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

# Buat allocation
curl -s -X POST "https://${PANEL_DOMAIN}/api/application/nodes/${NODE_ID}/allocations" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d "{
    \"ip\": \"${VPS_IP}\",
    \"ports\": [$(seq -s, ${ALLOC_PORT_START} ${ALLOC_PORT_END})]
  }" > /dev/null
echo -e "${CYAN}    Allocation ${ALLOC_PORT_START}-${ALLOC_PORT_END} dibuat!${NC}"

# Download wings config dari panel
curl -s "https://${PANEL_DOMAIN}/api/application/nodes/${NODE_ID}/configuration" \
  -H "Authorization: Bearer ${API_KEY}" \
  -H "Accept: application/json" \
  > /etc/pterodactyl/config.yml

systemctl start wings

# ════════════════════════════════════════════════════════════
#  DONE
# ════════════════════════════════════════════════════════════
echo ""
echo -e "${GREEN}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║              INSTALASI SELESAI! 🎉                       ║"
echo "╠══════════════════════════════════════════════════════════╣"
printf "║  Panel URL  : https://%-34s║\n" "${PANEL_DOMAIN}"
printf "║  Username   : %-36s║\n" "admin"
printf "║  Password   : %-36s║\n" "${ADMIN_PASS}"
printf "║  DB Pass    : %-36s║\n" "${DB_PASS}"
printf "║  Node ID    : %-36s║\n" "${NODE_ID}"
printf "║  API Key    : %-36s║\n" "${API_KEY}"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║  Simpan info di atas di tempat aman!                     ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Simpan ke file
cat > /root/pterodactyl-install-info.txt <<INFOEOF
=== PTERODACTYL INSTALL INFO ===
Tanggal    : $(date)
Panel URL  : https://${PANEL_DOMAIN}
Username   : admin
Password   : ${ADMIN_PASS}
Email      : ${ADMIN_EMAIL}
DB Pass    : ${DB_PASS}
Node ID    : ${NODE_ID}
API Key    : ${API_KEY}
INFOEOF

echo -e "${CYAN}Info tersimpan di: /root/pterodactyl-install-info.txt${NC}"
