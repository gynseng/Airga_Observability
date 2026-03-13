#!/usr/bin/env bash

set -euo pipefail

STACK_DIR="/opt/observability"
DATA_DIR="/var/lib/observability"
IMAGE_BUNDLE="images/observability-images.tar"

echo ""
echo "----------------------------------------"
echo " Airgap Observability Stack Installer"
echo "----------------------------------------"
echo ""

########################################
# Root Check
########################################

if [[ $EUID -ne 0 ]]; then
  echo "Please run as root or with sudo"
  exit 1
fi

########################################
# Verify Docker
########################################

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: Docker is not installed."
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "ERROR: Docker Compose v2 not installed."
  exit 1
fi

########################################
# Load Images if Needed
########################################

echo "Checking container images..."

REQUIRED_IMAGES=(
grafana/grafana
prom/prometheus
grafana/loki
grafana/tempo
prom/node-exporter
caddy
)

MISSING=false

for img in "${REQUIRED_IMAGES[@]}"
do
    if ! docker image inspect "$img" >/dev/null 2>&1; then
        echo "Missing image: $img"
        MISSING=true
    fi
done

if [ "$MISSING" = true ]; then
    if [ ! -f "$IMAGE_BUNDLE" ]; then
        echo "ERROR: Image bundle not found: $IMAGE_BUNDLE"
        exit 1
    fi

    echo "Loading container images..."
    docker load -i "$IMAGE_BUNDLE"
fi

########################################
# Validate stack files
########################################

FILES=(
docker-compose.yml
prometheus.yml
Caddyfile
)

for f in "${FILES[@]}"
do
    if [ ! -f "$f" ]; then
        echo "ERROR: Missing required file: $f"
        exit 1
    fi
done

########################################
# Create directories
########################################

echo "Creating data directories..."

mkdir -p "$STACK_DIR"
mkdir -p "$DATA_DIR/grafana"
mkdir -p "$DATA_DIR/prometheus"
mkdir -p "$DATA_DIR/loki"
mkdir -p "$DATA_DIR/tempo"

########################################
# Fix container UID ownership
########################################

echo "Fixing container permissions..."

chown -R 472:472 "$DATA_DIR/grafana"
chown -R 65534:65534 "$DATA_DIR/prometheus"
chown -R 10001:10001 "$DATA_DIR/loki"
chown -R 10001:10001 "$DATA_DIR/tempo"

chmod -R 755 "$DATA_DIR"

########################################
# Create Tempo config if missing
########################################

if [ ! -f "$STACK_DIR/tempo.yaml" ]; then
echo "Creating Tempo configuration..."

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

########################################
# Copy stack configuration
########################################

echo "Installing stack configuration..."

cp docker-compose.yml "$STACK_DIR/"
cp prometheus.yml "$STACK_DIR/"
cp Caddyfile "$STACK_DIR/"

########################################
# SELinux compatibility
########################################

if command -v getenforce >/dev/null 2>&1; then
    if [ "$(getenforce)" = "Enforcing" ]; then
        echo "SELinux detected, applying container labels..."
        chcon -Rt svirt_sandbox_file_t "$DATA_DIR"
    fi
fi

########################################
# Launch stack
########################################

echo "Starting observability stack..."

cd "$STACK_DIR"

docker compose up -d

########################################
# Display status
########################################

IP=$(hostname -I | awk '{print $1}')

echo ""
echo "----------------------------------------"
echo " Observability Stack Installed"
echo "----------------------------------------"
echo ""
echo "Grafana:"
echo "http://$IP:3000"
echo ""
echo "Prometheus:"
echo "http://$IP:9090"
echo ""
echo "Loki:"
echo "http://$IP:3100"
echo ""
echo "Node Exporter:"
echo "http://$IP:9100/metrics"
echo ""
echo "----------------------------------------"