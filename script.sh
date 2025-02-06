#!/bin/bash

set -e

# غیرفعال کردن UFW
ufw disable

# نصب Marzban
sudo bash -c "$(curl -sL https://github.com/Gozargah/Marzban-scripts/raw/master/marzban.sh)" @ install

# ویرایش فایل .env
cat <<EOF | sudo tee /opt/marzban/.env
UVICORN_HOST = "0.0.0.0"
UVICORN_PORT = 8443
XRAY_EXECUTABLE_PATH = "/var/lib/marzban/xray-core/xray"
XRAY_ASSETS_PATH = "/var/lib/marzban/assets/"
UVICORN_SSL_CERTFILE = "/var/lib/marzban/certs/fullchain.pem"
UVICORN_SSL_KEYFILE = "/var/lib/marzban/certs/key.pem"

XRAY_JSON = "/var/lib/marzban/xray_config.json"
SQLALCHEMY_DATABASE_URL = "sqlite:////var/lib/marzban/db.sqlite3"
EOF

# ایجاد دایرکتوری و دانلود فایل‌های مورد نیاز
mkdir -p /var/lib/marzban/assets/
wget -O /var/lib/marzban/assets/geosite.dat https://github.com/v2fly/domain-list-community/releases/latest/download/dlc.dat
wget -O /var/lib/marzban/assets/geoip.dat https://github.com/v2fly/geoip/releases/latest/download/geoip.dat
wget -O /var/lib/marzban/assets/iran.dat https://github.com/bootmortis/iran-hosted-domains/releases/latest/download/iran.dat

# نصب ابزارهای مورد نیاز
apt update && apt install -y wget unzip socat certbot

# دانلود و استخراج Xray-core
mkdir -p /var/lib/marzban/xray-core && cd /var/lib/marzban/xray-core
wget https://github.com/XTLS/Xray-core/releases/download/v1.8.24/Xray-linux-64.zip
unzip Xray-linux-64.zip
rm Xray-linux-64.zip

# نصب ACME و تنظیم Let’s Encrypt
touch ~/.bashrc
curl https://get.acme.sh | sh
~/.acme.sh/acme.sh --set-default-ca --server letsencrypt

# ایجاد دایرکتوری گواهینامه‌ها
mkdir -p /var/lib/marzban/certs/

# تنظیم کلید و ایمیل Cloudflare
export CF_Key="85a5dab43c55fe0eab26f934f40045f24e50b"
export CF_Email="mohamadsalehsaghafian@gmail.com"

~/.acme.sh/acme.sh --issue -d 'j0binja.ir' -d '*.j0binja.ir' --dns dns_cf --key-file /var/lib/marzban/certs/key.pem --fullchain-file /var/lib/marzban/certs/fullchain.pem
marzban restart
