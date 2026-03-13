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
# Check Docker
########################################

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: Docker is not installed."
  echo "Install Docker before running this installer."
  exit 1
fi

########################################
# Check Docker Compose
########################################

if ! docker compose version >/dev/null 2>&1; then
  echo "ERROR: Docker Compose v2 not found."
  echo "Install Docker Compose plugin."
  exit 1
fi

########################################
# Load Images if Needed
########################################

echo "Checking required images..."

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
    echo ""
    echo "Loading container images from bundle..."

    if [ ! -f "$IMAGE_BUNDLE" ]; then
        echo "ERROR: Image bundle not found:"
        echo "$IMAGE_BUNDLE"
        exit 1
    fi

    docker load -i "$IMAGE_BUNDLE"
fi

echo "All images present."

########################################
# Validate Configuration Files
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
# Create Directories
########################################

echo ""
echo "Creating directories..."

mkdir -p "$STACK_DIR"
mkdir -p "$DATA_DIR/grafana"
mkdir -p "$DATA_DIR/prometheus"
mkdir -p "$DATA_DIR/loki"
mkdir -p "$DATA_DIR/tempo"

########################################
# Copy Stack Files
########################################

echo "Installing stack configuration..."

cp docker-compose.yml "$STACK_DIR/"
cp prometheus.yml "$STACK_DIR/"
cp Caddyfile "$STACK_DIR/"

########################################
# Start Stack
########################################

echo ""
echo "Starting observability stack..."

cd "$STACK_DIR"

docker compose up -d

########################################
# Success Output
########################################

IP=$(hostname -I | awk '{print $1}')

echo ""
echo "----------------------------------------"
echo " Observability Stack Installed"
echo "----------------------------------------"
echo ""
echo "Grafana:"
echo ""
echo "https://monitor.local"
echo "or"
echo "http://$IP:3000"
echo ""
echo "username: admin"
echo "password: admin"
echo ""
echo "----------------------------------------"