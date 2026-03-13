# Observability Air-Gap Stack

A fully self-contained observability platform designed for air-gapped environments.

This project packages a complete monitoring stack with all container images so the system can be deployed without internet access.

The stack includes:

Component | Purpose
--------- | -------
Grafana | Visualization dashboards
Prometheus | Metrics collection
Loki | Log aggregation
Tempo | Distributed tracing
Node Exporter | Host metrics
Caddy | Reverse proxy

Everything runs using Docker Compose and is packaged for offline deployment.

---

# Architecture

The observability platform provides unified monitoring for metrics, logs, and traces.

Node Exporter  
↓  
Prometheus → Grafana  
↓  
Loki (logs)  
↓  
Tempo (traces)

Grafana provides dashboards for all telemetry sources.

---

# Deployment Model

Two systems are required.

Build System (Internet Connected)

Used to download container images and build the air-gap package.

Target System (Air-Gapped)

Used to install and run the observability stack.

---

# Step 1 — Build the Air-Gap Package

Run on the internet-connected system:

sudo ./build-airgap-package.sh

The builder will:

- Pull required container images
- Export them into a portable bundle
- Package configuration files
- Generate the deployment archive

Output file:

observability-airgap-package.tar

---

# Step 2 — Transfer the Package

Move the package to the air-gapped system.

Example:

scp observability-airgap-package.tar user@server:/root

Or transfer via removable media.

---

# Step 3 — Extract the Package [No Need]

On the air-gapped machine:

tar -xvf observability-airgap-package.tar  
cd observability-airgap-package

Directory structure:

observability-airgap-package  
├── observability.sh  
├── docker-compose.yml  
├── prometheus.yml  
├── Caddyfile  
├── images  
│   └── observability-images.tar  

---

# Step 4 — Install the Stack

Run the installer:

sudo bash observability.sh install

The installer automatically:

- Creates required directories
- Fixes container permissions
- Handles SELinux labeling
- Generates Tempo configuration
- Loads container images
- Starts Docker Compose

---

# Verify Installation

Check stack status:

bash observability.sh status

Expected containers:

observability-grafana  
observability-prometheus  
observability-loki  
observability-tempo  
observability-node-exporter  
observability-caddy  

---

# Access the Services

Grafana  
http://SERVER_IP:3000

Prometheus  
http://SERVER_IP:9090

Loki API  
http://SERVER_IP:3100

Node Exporter metrics  
http://SERVER_IP:9100/metrics

---

# Default Grafana Credentials

Username: admin  
Password: admin

You will be prompted to change the password on first login.

---

# Lifecycle Commands

The observability script manages the entire stack.

Install the stack:

sudo ./observability install

Check stack status:

./observability status

Uninstall stack:

sudo ./observability uninstall

This stops containers and removes configuration directories.

Full reset:

sudo ./observability reset

This removes containers, images, networks, and persistent data.

---

# Troubleshooting

Grafana Restarting

Check logs:

docker logs observability-grafana

Verify directory permissions:

/var/lib/observability/grafana

---

Tempo Restarting

Ensure configuration file exists:

/opt/observability/tempo.yaml

Restart stack:

docker compose -f /opt/observability/docker-compose.yml restart

---

SELinux Issues (Rocky Linux / RHEL)

Check status:

getenforce

If enforcing:

sudo chcon -Rt svirt_sandbox_file_t /var/lib/observability

---

# Quick Reference

Build package

sudo ./build-airgap-package.sh

Install stack

sudo ./observability install

Check status

./observability status

Uninstall stack

sudo ./observability uninstall

Full reset

sudo ./observability reset

---

# System Requirements

Docker  
Docker Compose v2  
Linux host (Rocky, RHEL, Ubuntu, Debian)

Recommended minimum resources:

CPU: 2 cores  
RAM: 4 GB  
Disk: 20 GB

---

# Directory Layout

/opt/observability  
    docker-compose.yml  
    prometheus.yml  
    Caddyfile  
    tempo.yaml  

/var/lib/observability  
    grafana  
    prometheus  
    loki  
    tempo  

---

# Security Considerations

This deployment is designed for isolated networks.

For production environments consider:

- TLS certificates
- Grafana authentication providers
- role-based access control
- hardened reverse proxy configuration

---

# License

Internal deployment tool.