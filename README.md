# Air-Gap Observability Stack

A **single-command installer** that deploys a complete monitoring and observability stack designed specifically for **air-gapped environments**.

This stack deploys a full local monitoring platform using Docker containers with persistent storage and internal networking.

## Stack Components

- Grafana — dashboards and visualization
- Prometheus — metrics collection and monitoring
- Loki — log aggregation
- Tempo — distributed tracing
- Node Exporter — host system metrics
- Caddy — reverse proxy with internal TLS

All services are deployed locally and do **not require internet access once container images are loaded**.

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

All services communicate using the **internal Docker network**.

---

# Features

- Single command installation
- Designed for air-gapped environments
- Local TLS support via Caddy
- Persistent storage
- Docker containerized services
- Minimal resource usage
- Production-ready configuration
- No external dependencies after image load

---

# System Requirements

Recommended host system:

| Resource | Minimum |
|--------|--------|
| CPU | 2 cores |
| RAM | 4 GB |
| Disk | 20 GB |

Supported OS:

- Ubuntu
- Debian
- Rocky Linux
- AlmaLinux
- RHEL
- Other modern Linux distributions with Docker

---

# Required Docker Images

The following images must be present locally before running the installer:

```
grafana/grafana
prom/prometheus
grafana/loki
grafana/tempo
prom/node-exporter
caddy
```

---

# Preparing Images for Air-Gap Deployment

On a machine with internet access:

```bash
docker pull grafana/grafana
docker pull prom/prometheus
docker pull grafana/loki
docker pull grafana/tempo
docker pull prom/node-exporter
docker pull caddy
```

Export the images:

```bash
docker save -o observability-images.tar \
grafana/grafana \
prom/prometheus \
grafana/loki \
grafana/tempo \
prom/node-exporter \
caddy
```

Transfer the archive to the air-gapped system.

Load the images:

```bash
docker load -i observability-images.tar
```

---

# Installation

Run the installer:

```bash
curl -fsSL https://install.observability.sh | sudo bash
```

Optional parameters:

```
--domain <domain>          default: monitor.local
--grafana-port <port>      default: 3000
--random-password          generate random admin password
```

Example installation:

```bash
curl -fsSL https://install.observability.sh | sudo bash -s -- \
  --domain monitoring.local \
  --grafana-port 3000 \
  --random-password
```

---

# Accessing Grafana

After installation, Grafana can be accessed at:

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

If the `--random-password` option is used, the generated password will be printed after installation.

---

# Directory Layout

```
/opt/observability
│
├── docker-compose.yml
├── Caddyfile
├── prometheus.yml
│
└── configs

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

Because the environment is air-gapped, updates must be performed manually.

1. Pull updated container images on a connected machine
2. Export the images
3. Transfer them to the air-gapped system
4. Load them with:

```bash
docker load -i observability-images.tar
```

Restart the services afterwards.

---

# Removing the Stack

Stop the containers:

```bash
docker compose -f /opt/observability/docker-compose.yml down
```

Remove configuration and data:

```bash
rm -rf /opt/observability
rm -rf /var/lib/observability
```

---

# Security Recommendations

This stack is intended for **secure or isolated networks**.

Recommended best practices:

- Change the default Grafana password
- Restrict network access to Grafana
- Use internal DNS for the monitoring domain
- Integrate with internal PKI if available
- Segment monitoring traffic from production networks

---

# Example Use Cases

This observability stack is well suited for monitoring:

- network infrastructure
- SDR platforms
- telemetry fan-out systems
- distributed Go services
- container platforms
- edge compute nodes
- RF and tactical communication networks

---

# Future Enhancements

Possible future improvements include:

- SNMP exporter for network devices
- NetFlow or sFlow collectors
- OpenTelemetry collector
- Kafka telemetry monitoring
- Prometheus federation
- distributed Grafana deployments

---

# License

MIT License
