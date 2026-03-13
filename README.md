# Air-Gap Observability Stack

This project provides a **portable observability stack designed for air-gapped environments**.

The deployment bundle contains everything required to install and run the monitoring platform without internet connectivity.

The stack includes:

- Grafana – dashboards and visualization
- Prometheus – metrics collection and monitoring
- Loki – log aggregation
- Tempo – distributed tracing
- Node Exporter – host metrics
- Caddy – reverse proxy with internal TLS

All services run as **Docker containers with persistent storage**.

---

# Architecture

```
Users
   │
   ▼
Caddy Reverse Proxy (TLS)
   │
   ├── Grafana
   ├── Prometheus
   ├── Loki
   └── Tempo

Prometheus
   └── Node Exporter
```

All services communicate over an **internal Docker network**.

---

# Key Features

- Single-script installation
- Designed for air-gapped networks
- Docker-based deployment
- Automatic dependency validation
- Automatic container image loading
- Internal TLS support
- Persistent storage
- Minimal resource usage

---

# System Requirements

Recommended host specifications:

| Resource | Minimum |
|--------|--------|
| CPU | 2 cores |
| RAM | 4 GB |
| Disk | 20 GB |

Supported operating systems:

- Ubuntu
- Debian
- Rocky Linux
- AlmaLinux
- RHEL
- Any modern Linux distribution capable of running Docker

---

# Air-Gap Package Contents

After building the deployment package, the structure will look like:

```
observability-airgap-package
│
├── Airgap-Observability-Installer.sh
├── docker-compose.yml
├── prometheus.yml
├── Caddyfile
│
├── images
│   └── observability-images.tar
│
└── README.md
```

---

# Building the Air-Gap Package

On a machine **with internet access**, build the package using the package builder:

```
./build-airgap-package.sh
```

This script will:

1. Pull required container images
2. Export the images into a bundle
3. Assemble the deployment package
4. Create a portable archive

Output file:

```
observability-airgap-package.tar
```

---

# Deploying in an Air-Gapped Environment

Transfer the package into the isolated environment.

Extract the package:

```
tar -xvf observability-airgap-package.tar
cd observability-airgap-package
```

Run the installer:

```
chmod +x Airgap-Observability-Installer.sh
sudo ./Airgap-Observability-Installer.sh
```

The installer automatically:

- verifies Docker is installed
- verifies Docker Compose is installed
- checks required container images
- loads images from the bundle if needed
- validates configuration files
- creates persistent storage directories
- deploys the observability stack

---

# Accessing Grafana

After installation completes:

```
https://monitor.local
```

or

```
http://SERVER_IP:3000
```

Default credentials:

```
username: admin
password: admin
```

It is recommended to **change the password after first login**.

---

# Directory Layout

Deployment configuration:

```
/opt/observability
│
├── docker-compose.yml
├── prometheus.yml
└── Caddyfile
```

Persistent data:

```
/var/lib/observability
│
├── grafana
├── prometheus
├── loki
└── tempo
```

---

# Managing the Stack

Start services:

```
docker compose -f /opt/observability/docker-compose.yml up -d
```

Stop services:

```
docker compose -f /opt/observability/docker-compose.yml down
```

Restart services:

```
docker compose -f /opt/observability/docker-compose.yml restart
```

View logs:

```
docker compose -f /opt/observability/docker-compose.yml logs
```

---

# Updating the Stack

Because the deployment environment is air-gapped, updates must be performed manually:

1. Pull updated container images on a connected system
2. Build a new air-gap package
3. Transfer the new package
4. Run the installer again

---

# Security Recommendations

For secure deployments:

- change default Grafana credentials
- restrict network access to monitoring services
- use internal DNS for `monitor.local`
- integrate with internal PKI if available
- segment monitoring traffic from production networks

---

# Example Monitoring Use Cases

This observability stack is well suited for monitoring:

- network infrastructure
- SDR platforms
- telemetry fan-out systems
- distributed services
- container platforms
- edge compute nodes
- RF and tactical communication systems

---

# Future Enhancements

Possible extensions include:

- SNMP exporter for routers and radios
- NetFlow or sFlow collectors
- OpenTelemetry collector
- Prometheus federation
- distributed Grafana deployments

---

# License

MIT License
