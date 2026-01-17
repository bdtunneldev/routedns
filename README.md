# RouteDNS: Secure DNS over TLS (DoT) with HAProxy, RouteDNS, and Valkey

This project provides a production-ready setup for a DNS over TLS (DoT) service with tenant validation, rate limiting, and monitoring. It uses HAProxy, RouteDNS, Valkey (Redis-compatible), Prometheus, and Grafana.

## Features

- **DNS over TLS (DoT)**: Secure DNS resolution using HAProxy and RouteDNS.
- **Tenant Validation**: Validate tenants via routedns.io API with Valkey caching.
- **Rate Limiting**: Protect against DDoS attacks with connection and rate limits.
- **Monitoring**: Prometheus and Grafana for metrics and dashboards.
- **Backup and Restore**: Automated backup scripts for Valkey, Grafana, and configuration files.

---

## Prerequisites

1. **Docker**: Install Docker and Docker Compose on your system.
   - [Install Docker](https://docs.docker.com/get-docker/)
   - [Install Docker Compose](https://docs.docker.com/compose/install/)

2. **Domain Name**: Ensure you have a domain name (e.g., `dns.routedns.io`) and can configure DNS records.

3. **SSL/TLS Certificates**: Obtain SSL/TLS certificates for your domain using [Let's Encrypt](https://letsencrypt.org/) or another certificate authority.

---

## Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/bdtunneldev/routeDNS.git
cd routeDNS
```

### 2. Configure Environment Variables

1. Copy the `.env.example` file to `.env`:

   ```bash
   cp .env.example .env
   ```

2. Edit the `.env` file and set the following variables:

   ```env
   HAPROXY_STATS_USER=admin
   HAPROXY_STATS_PASSWORD=your_secure_stats_password_here
   VALKEY_PASSWORD=your_secure_valkey_password_here
   GRAFANA_ADMIN_USER=admin
   GRAFANA_ADMIN_PASSWORD=your_secure_grafana_password_here
   ```

---

### 3. Deploy SSL/TLS Certificates

1. Obtain SSL/TLS certificates using Let's Encrypt or another provider.
2. Place the certificates in `/etc/letsencrypt/live/dns.routedns.io/` (or update the path in `deploy-certs.sh`).
3. Run the deployment script to copy and configure the certificates for HAProxy:

   ```bash
   sudo ./deploy-certs.sh
   ```

---

### 4. Start the Services

1. Build and start the Docker containers:

   ```bash
   docker compose up -d
   ```

2. Verify that all services are running:

   ```bash
   docker compose ps
   ```

---

### 5. Access the Services

- **DNS over TLS (DoT)**: Configure your DNS client to use `dns.routedns.io` on port `853`.
- **HAProxy Stats**: Access the HAProxy stats page at `http://localhost:8404/stats` (use the credentials from `.env`).
- **Prometheus**: Access Prometheus at `http://localhost:9090`.
- **Grafana**: Access Grafana at `http://localhost:3000` (use the credentials from `.env`).

---

## Monitoring and Alerts

1. Prometheus is pre-configured to scrape metrics from HAProxy and itself.
2. Grafana dashboards are pre-provisioned for HAProxy monitoring.
3. Alerts for HAProxy and infrastructure are defined in `monitoring/prometheus/alerts.yml`.

---

## Backup and Restore

1. Run the backup script to back up Valkey, Grafana, and configuration files:

   ```bash
   ./backup.sh [daily|weekly|manual]
   ```

2. Backups are stored in the `backups/` directory.

---

## Health Checks

Run health checks for all services:

```bash
./manage.sh test
```

---

## Management Commands

Use the `manage.sh` script to manage the stack:

```bash
./manage.sh [command]
```

Available commands:
- `status`: Show service status.
- `logs [service]`: Show logs for a specific service (e.g., `haproxy`, `routedns`, `valkey`).
- `restart [service]`: Restart a specific service or all services.
- `test`: Run health checks on all services.
- `shell [service]`: Open a shell in a service container.
- `help`: Show help message.

---

## Security Notes

1. **Environment Variables**: Never commit the `.env` file with sensitive information to version control.
2. **SSL/TLS Certificates**: Use strong certificates and keep them secure.
3. **Passwords**: Use strong passwords for all services and rotate them regularly.

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
