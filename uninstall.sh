#!/usr/bin/env bash

set -euo pipefail

STACK_DIR="/opt/observability"
DATA_DIR="/var/lib/observability"

echo ""
echo "----------------------------------------"
echo " Observability Stack Reset Tool"
echo "----------------------------------------"
echo ""

########################################
# Root Check
########################################

if [[ $EUID -ne 0 ]]; then
  echo "Run this script with sudo or as root"
  exit 1
fi

########################################
# Stop stack if compose exists
########################################

if [ -f "$STACK_DIR/docker-compose.yml" ]; then
  echo "Stopping observability stack..."
  docker compose -f "$STACK_DIR/docker-compose.yml" down || true
fi

########################################
# Remove containers manually (safety)
########################################

echo "Removing observability containers..."

CONTAINERS=(
observability-grafana
observability-prometheus
observability-loki
observability-tempo
observability-node-exporter
observability-caddy
)

for c in "${CONTAINERS[@]}"
do
  if docker ps -a --format '{{.Names}}' | grep -q "$c"; then
    docker rm -f "$c" >/dev/null 2>&1 || true
    echo "Removed container: $c"
  fi
done

########################################
# Remove stack configuration
########################################

if [ -d "$STACK_DIR" ]; then
  echo "Removing stack configuration..."
  rm -rf "$STACK_DIR"
fi

########################################
# Remove persistent data
########################################

if [ -d "$DATA_DIR" ]; then
  echo "Removing observability data..."
  rm -rf "$DATA_DIR"
fi

########################################
# Remove images used by stack
########################################

echo "Removing observability images..."

IMAGES=(
grafana/grafana
prom/prometheus
grafana/loki
grafana/tempo
prom/node-exporter
caddy
)

for img in "${IMAGES[@]}"
do
  docker image rm "$img" >/dev/null 2>&1 || true
done

########################################
# Cleanup dangling resources
########################################

echo "Cleaning unused docker resources..."

docker network prune -f >/dev/null 2>&1 || true
docker volume prune -f >/dev/null 2>&1 || true

########################################
# Done
########################################

echo ""
echo "----------------------------------------"
echo " System Reset Complete"
echo "----------------------------------------"
echo ""
echo "The observability stack has been removed."
echo ""