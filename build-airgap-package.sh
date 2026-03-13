#!/usr/bin/env bash

set -e

PACKAGE_NAME="observability-airgap-package"
WORKDIR=$(pwd)/build

echo "--------------------------------------"
echo "Observability Airgap Package Builder"
echo "--------------------------------------"

########################################
# Install Docker Function
########################################

install_docker() {

if command -v docker >/dev/null 2>&1; then
    echo "Docker already installed."
    return
fi

echo "Docker not found. Installing Docker..."

if [ -f /etc/debian_version ]; then

    apt-get update
    apt-get install -y ca-certificates curl gnupg

    install -m 0755 -d /etc/apt/keyrings

    curl -fsSL https://download.docker.com/linux/debian/gpg \
    | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/debian \
    $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
    > /etc/apt/sources.list.d/docker.list

    apt-get update

    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

elif [ -f /etc/redhat-release ]; then

    dnf -y install dnf-plugins-core

    dnf config-manager \
        --add-repo \
        https://download.docker.com/linux/centos/docker-ce.repo

    dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

else

    echo "Unsupported OS for automatic Docker install"
    exit 1

fi

systemctl enable docker
systemctl start docker

echo "Docker installed successfully."

}

########################################
# Ensure Docker Exists
########################################

install_docker

########################################
# Create working directories
########################################

mkdir -p $WORKDIR/images
mkdir -p $WORKDIR/package

########################################
# Required images
########################################

IMAGES=(
grafana/grafana
prom/prometheus
grafana/loki
grafana/tempo
prom/node-exporter
caddy
)

echo ""
echo "Pulling required images..."

for img in "${IMAGES[@]}"
do
    echo "Pulling $img"
    docker pull $img
done

########################################
# Export images
########################################

echo ""
echo "Saving container images..."

docker save \
grafana/grafana \
prom/prometheus \
grafana/loki \
grafana/tempo \
prom/node-exporter \
caddy \
-o $WORKDIR/images/observability-images.tar

########################################
# Copy stack files
########################################

echo ""
echo "Copying stack files..."

mkdir -p $WORKDIR/package/images

cp docker-compose.yml $WORKDIR/package/
cp prometheus.yml $WORKDIR/package/
cp Caddyfile $WORKDIR/package/
cp observability.sh $WORKDIR/package/
cp README.md $WORKDIR/package/

mv $WORKDIR/images/observability-images.tar $WORKDIR/package/images/

########################################
# Create final bundle
########################################

echo ""
echo "Creating airgap bundle..."

tar -cvf ${PACKAGE_NAME}.tar -C $WORKDIR/package .

echo ""
echo "--------------------------------------"
echo "Airgap package created:"
echo ""
echo "${PACKAGE_NAME}.tar"
echo "--------------------------------------"