#!/usr/bin/env bash
set -e

PACKAGE_NAME="observability-airgap-package"
WORKDIR=$(pwd)/build

mkdir -p $WORKDIR/images
mkdir -p $WORKDIR/package

echo "Pulling required images..."

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
    echo "Pulling $img"
    docker pull $img
done

echo "Saving images..."

docker save \
grafana/grafana \
prom/prometheus \
grafana/loki \
grafana/tempo \
prom/node-exporter \
caddy \
-o $WORKDIR/images/observability-images.tar

echo "Copying stack configs..."

cp docker-compose.yml $WORKDIR/package/
cp prometheus.yml $WORKDIR/package/
cp Caddyfile $WORKDIR/package/
cp install-airgap.sh $WORKDIR/package/
cp README.md $WORKDIR/package/

mkdir -p $WORKDIR/package/images

mv $WORKDIR/images/observability-images.tar $WORKDIR/package/images/

echo "Creating airgap bundle..."

tar -cvf ${PACKAGE_NAME}.tar -C $WORKDIR/package .

echo ""
echo "Airgap package created:"
echo ""
echo "${PACKAGE_NAME}.tar"
