#!/usr/bin/env bash
set -euo pipefail

DOMAIN="monitor.local"
PORT=3000
STACK_DIR="/opt/observability"
DATA_DIR="/var/lib/observability"

banner() {
echo "--------------------------------"
echo " Airgap Observability Installer"
echo "--------------------------------"
}

parse_args() {
while [[ $# -gt 0 ]]; do
case "$1" in
--domain)
DOMAIN="$2"
shift 2
;;
--grafana-port)
PORT="$2"
shift 2
;;
--random-password)
ADMIN_PASS=$(openssl rand -base64 12)
shift
;;
*)
echo "Unknown option $1"
exit 1
;;
esac
done
}

install_docker() {

if ! command -v docker >/dev/null; then
echo "Installing Docker"
curl -fsSL https://get.docker.com | sh
systemctl enable docker
systemctl start docker
fi
}

create_dirs() {

mkdir -p $STACK_DIR
mkdir -p $DATA_DIR/{grafana,prometheus,loki,tempo}
}

write_prometheus() {

cat <<EOF > $STACK_DIR/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:

  - job_name: node
    static_configs:
      - targets: ['node-exporter:9100']
EOF
}

write_caddy() {

cat <<EOF > $STACK_DIR/Caddyfile
$DOMAIN {

reverse_proxy grafana:3000

tls internal
}
EOF
}

write_compose() {

cat <<EOF > $STACK_DIR/docker-compose.yml
version: "3"

services:

  caddy:
    image: caddy
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
    restart: unless-stopped

  grafana:
    image: grafana/grafana
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=$ADMIN_PASS
    volumes:
      - $DATA_DIR/grafana:/var/lib/grafana
    restart: unless-stopped

  prometheus:
    image: prom/prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - $DATA_DIR/prometheus:/prometheus
    restart: unless-stopped

  node-exporter:
    image: prom/node-exporter
    restart: unless-stopped

  loki:
    image: grafana/loki
    volumes:
      - $DATA_DIR/loki:/loki
    restart: unless-stopped

  tempo:
    image: grafana/tempo
    volumes:
      - $DATA_DIR/tempo:/var/tempo
    restart: unless-stopped
EOF
}

start_stack() {

cd $STACK_DIR
docker compose up -d
}

success() {

IP=$(hostname -I | awk '{print $1}')

echo ""
echo "--------------------------------"
echo "Observability Stack Installed"
echo ""
echo "Grafana URL:"
echo "https://$DOMAIN"
echo "or"
echo "http://$IP:$PORT"
echo ""
echo "user: admin"
echo "pass: $ADMIN_PASS"
echo "--------------------------------"
}

main() {

ADMIN_PASS="admin"

banner
parse_args "$@"

install_docker
create_dirs
write_prometheus
write_caddy
write_compose
start_stack
success

}

main "$@"
