# Air-Gap Observability Stack

This project provides a **portable observability platform designed for air-gapped environments**.

The stack deploys a full monitoring environment using Docker containers and includes:

- Grafana – dashboards and visualization
- Prometheus – metrics monitoring
- Loki – log aggregation
- Tempo – distributed tracing
- Node Exporter – host metrics
- Caddy – reverse proxy with internal TLS

All services run locally and do **not require internet connectivity after the package is created**.

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

# Quick Reference

## 1️⃣ Build the Air-Gap Package (Online System)

Run the package builder:

```bash
chmod +x build-airgap-package.sh
sudo ./build-airgap-package.sh
```

This will:

- install Docker if missing
- pull required container images
- export images into a bundle
- assemble the deployment package

Output file:

```
observability-airgap-package.tar
```

---

## 2️⃣ Transfer Package to Air-Gap Environment

Copy the package to the offline system using secure media or file transfer.

---

## 3️⃣ Extract the Package

```bash
tar -xvf observability-airgap-package.tar
cd observability-airgap-package
```

---

## 4️⃣ Install the Stack

Run the installer:

```bash
chmod +x Airgap-Observability-Installer.sh
sudo ./Airgap-Observability-Installer.sh
```

The installer automatically:

- verifies Docker
- verifies Docker Compose
- loads container images if needed
- creates required directories
- installs stack configuration
- launches the observability stack

---

## 5️⃣ Access Grafana

After installation completes:

```
https://monitor.local
```

or

```
http://SERVER_IP:3000
```

Default login:

```
username: admin
password: admin
```

Change the password after first login.

---

# Package Contents

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

# System Requirements

Recommended host system:

| Resource | Minimum |
|--------|--------|
| CPU | 2 cores |
| RAM | 4 GB |
| Disk | 20 GB |

Supported OS:

- Rocky Linux
- AlmaLinux
- RHEL
- Ubuntu
- Debian
- Any Linux distribution capable of running Docker

---

# Directory Layout

Stack configuration:

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

```bash
docker compose -f /opt/observability/docker-compose.yml up -d
```

Stop services:

```bash
docker compose -f /opt/observability/docker-compose.yml down
```

Restart services:

```bash
docker compose -f /opt/observability/docker-compose.yml restart
```

View logs:

```bash
docker compose -f /opt/observability/docker-compose.yml logs
```

---

# Updating the Stack

Because the environment is air-gapped:

1. Pull new container images on a connected system
2. Build a new package using the builder script
3. Transfer the new package to the offline system
4. Reinstall or update the deployment

---

# Security Recommendations

For secure environments:

- change default Grafana credentials
- restrict network access to monitoring services
- use internal DNS for `monitor.local`
- integrate with internal PKI if available
- segment monitoring traffic from production networks

---

# Example Monitoring Use Cases

This observability stack works well for monitoring:

- network infrastructure
- telemetry pipelines
- SDR systems
- container workloads
- distributed services
- edge compute nodes
- RF communication networks

---

# License