#!/usr/bin/env bash

set -euo pipefail

STACK_DIR="/opt/observability"
DATA_DIR="/var/lib/observability"
IMAGE_BUNDLE="images/observability-images.tar"

CONTAINERS=(
observability-grafana
observability-prometheus
observability-loki
observability-tempo
observability-node-exporter
observability-caddy
)

IMAGES=(
grafana/grafana
prom/prometheus
grafana/loki
grafana/tempo
prom/node-exporter
caddy
)

########################################
# Root Check
########################################

require_root() {
if [[ $EUID -ne 0 ]]; then
    echo "Please run with sudo"
    exit 1
fi
}

########################################
# INSTALL
########################################

install_stack() {

require_root

echo ""
echo "Installing Observability Stack"
echo ""

if ! command -v docker >/dev/null; then
    echo "Docker is required but not installed"
    exit 1
fi

mkdir -p "$STACK_DIR"
mkdir -p "$DATA_DIR"/{grafana,prometheus,loki,tempo}

echo "Creating observability data directories..."

mkdir -p /var/lib/observability/grafana
mkdir -p /var/lib/observability/prometheus
mkdir -p /var/lib/observability/loki
mkdir -p /var/lib/observability/tempo

echo "Setting container ownership..."

chown -R 472:472 /var/lib/observability/grafana
chown -R 65534:65534 /var/lib/observability/prometheus
chown -R 10001:10001 /var/lib/observability/loki
chown -R 10001:10001 /var/lib/observability/tempo

chmod -R 755 /var/lib/observability



########################################
# Configure monitor.local hostname
########################################

echo "Configuring monitor.local hostname..."

SERVER_IP=$(hostname -I | awk '{print $1}')

if ! grep -q "monitor.local" /etc/hosts; then
    echo "$SERVER_IP monitor.local" >> /etc/hosts
    echo "Added monitor.local -> $SERVER_IP to /etc/hosts"
else
    echo "monitor.local already configured"
fi



########################################
# Tempo Configuration
########################################
echo "Checking Tempo config..."

if [ ! -f "$STACK_DIR/tempo.yaml" ]; then
cat <<EOF > "$STACK_DIR/tempo.yaml"
server:
  http_listen_port: 3200

distributor:
  receivers:
    otlp:
      protocols:
        http:
        grpc:

ingester:
  trace_idle_period: 10s
  max_block_bytes: 1_000_000
  max_block_duration: 5m

storage:
  trace:
    backend: local
    local:
      path: /var/tempo
EOF
fi

echo "Copying configuration..."

cp docker-compose.yml "$STACK_DIR/"
cp prometheus.yml "$STACK_DIR/"
cp Caddyfile "$STACK_DIR/"

if command -v getenforce >/dev/null; then
if [ "$(getenforce)" = "Enforcing" ]; then
    echo "Applying SELinux container labels..."
    chcon -Rt svirt_sandbox_file_t "$DATA_DIR"
fi
fi

echo "Loading container images if needed..."

if [ -f "$IMAGE_BUNDLE" ]; then
docker load -i "$IMAGE_BUNDLE" || true
fi

echo "Starting stack..."

cd "$STACK_DIR"
docker compose up -d

echo ""
echo "Install complete"
}

########################################
# STATUS
########################################

status_stack() {

echo ""
echo "Observability Stack Status"
echo ""

docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep observability || true

echo ""
echo "Grafana Health Check:"
curl -s http://localhost:3000/api/health || echo "Grafana not responding"
}

########################################
# UNINSTALL
########################################

uninstall_stack() {

require_root

echo "Stopping stack..."

if [ -f "$STACK_DIR/docker-compose.yml" ]; then
docker compose -f "$STACK_DIR/docker-compose.yml" down
fi

echo "Removing stack directories..."

rm -rf "$STACK_DIR"
rm -rf "$DATA_DIR"

echo "Uninstall complete"
}

########################################
# RESET
########################################

reset_stack() {

require_root

echo "Performing full reset..."

if [ -f "$STACK_DIR/docker-compose.yml" ]; then
docker compose -f "$STACK_DIR/docker-compose.yml" down || true
fi

for c in "${CONTAINERS[@]}"
do
docker rm -f "$c" >/dev/null 2>&1 || true
done

rm -rf "$STACK_DIR"
rm -rf "$DATA_DIR"

echo "Removing images..."

for img in "${IMAGES[@]}"
do
docker image rm "$img" >/dev/null 2>&1 || true
done

docker network prune -f >/dev/null 2>&1 || true
docker volume prune -f >/dev/null 2>&1 || true

echo ""
echo "System reset complete"
}

########################################
# CLI
########################################

case "${1:-}" in
install)
install_stack
;;

status)
status_stack
;;

uninstall)
uninstall_stack
;;

reset)
reset_stack
;;

*)
echo ""
echo "Usage:"
echo ""
echo "./observability install"
echo "./observability status"
echo "./observability uninstall"
echo "./observability reset"
echo ""
;;

esac