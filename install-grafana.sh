#!/usr/bin/env bash
set -e

echo "===================================="
echo " Grafana Automatic Installer"
echo "===================================="

# Detect distro
if [ -f /etc/debian_version ]; then
    DISTRO="debian"
elif [ -f /etc/redhat-release ]; then
    DISTRO="redhat"
else
    echo "Unsupported OS"
    exit 1
fi

install_debian() {
    echo "[+] Installing Grafana for Debian/Ubuntu..."

    apt-get update -y
    apt-get install -y apt-transport-https wget gnupg

    mkdir -p /etc/apt/keyrings

    wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor \
        | tee /etc/apt/keyrings/grafana.gpg > /dev/null

    echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" \
        | tee /etc/apt/sources.list.d/grafana.list

    apt-get update -y
    apt-get install -y grafana
}

install_redhat() {
    echo "[+] Installing Grafana for RHEL/CentOS/Fedora..."

    cat <<EOF > /etc/yum.repos.d/grafana.repo
[grafana]
name=Grafana
baseurl=https://rpm.grafana.com
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=https://rpm.grafana.com/gpg.key
sslverify=1
EOF

    dnf install -y grafana || yum install -y grafana
}

if [ "$DISTRO" = "debian" ]; then
    install_debian
else
    install_redhat
fi

echo "[+] Enabling Grafana service..."
systemctl daemon-reload
systemctl enable grafana-server
systemctl start grafana-server

IP=$(hostname -I | awk '{print $1}')

echo ""
echo "===================================="
echo " Grafana Installed Successfully"
echo "===================================="
echo "URL: http://$IP:3000"
echo "User: admin"
echo "Pass: admin"
echo "===================================="
