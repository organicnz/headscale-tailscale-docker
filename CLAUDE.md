# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Docker Compose-based Headscale deployment stack. Headscale is an open-source, self-hosted implementation of the Tailscale control server. The stack includes:

- **Headscale**: Control server for the VPN mesh network
- **PostgreSQL**: Database backend for Headscale
- **Caddy**: Reverse proxy (configured for local development on port 8080)

## Architecture

```
Client Devices (Tailscale)
    ↓
Caddy (:8080) → Headscale (:8080 internally) → PostgreSQL
```

The stack uses a bridge network (`headscale-network`) for internal communication. Headscale stores its state in PostgreSQL and serves both the control plane API and health/metrics endpoints.

## Key Configuration Files

- **docker-compose.yml**: Main service definitions. Currently configured for local development (Caddy listens on port 8080)
- **Caddyfile**: Reverse proxy configuration with health checks and proper header forwarding
- **config/config.yaml**: Headscale server configuration including database connection, DERP settings, DNS (MagicDNS), and IP prefixes
- **config/acl.example.json**: Example ACL policy showing groups, tag owners, and access rules
- **.env**: Environment variables (domain, PostgreSQL credentials, timezone)

## Critical Configuration Notes

1. **Database Password Sync**: The PostgreSQL password must match in both `.env` (POSTGRES_PASSWORD) and `config/config.yaml` (database.postgres.password)

2. **Server URL**: In `config/config.yaml`, the `server_url` must match your deployment:
   - Local dev: `http://localhost:8080`
   - Production: `https://your-domain.com:443`

3. **Caddy Configuration**: The current Caddyfile is set for local development (auto_https off, port 8080). For production, you'd need to enable HTTPS and use ports 80/443.

## Common Commands

### Stack Management
```bash
# Start all services
docker compose up -d

# View logs
docker compose logs -f
docker compose logs -f headscale  # specific service

# Stop services
docker compose down

# Update services
docker compose pull
docker compose up -d

# Check service status
docker compose ps
```

### Headscale Management (via helper script)

The `headscale.sh` script provides a wrapper for common operations:

```bash
# User management
./headscale.sh users list
./headscale.sh users create <username>
./headscale.sh users destroy <username>

# Node management
./headscale.sh nodes list
./headscale.sh nodes delete <node-id>
./headscale.sh nodes expire  # expire all offline nodes

# Pre-auth key management
./headscale.sh keys list <username>
./headscale.sh keys create <username> --reusable --expiration 24h

# Routes
./headscale.sh routes list
./headscale.sh routes enable <route-id>

# Status and health
./headscale.sh status
./headscale.sh health
./headscale.sh logs [lines]
```

### Direct Docker Commands

For operations not covered by the helper script:

```bash
# Execute any headscale command directly
docker exec headscale headscale <command>

# Database backup
docker exec headscale-db pg_dump -U headscale headscale > backup.sql

# Database restore
cat backup.sql | docker exec -i headscale-db psql -U headscale

# Check database connection
docker exec -it headscale-db psql -U headscale -d headscale -c "SELECT 1;"

# Access health endpoint
curl http://localhost:8080/health

# View metrics (Prometheus format)
curl http://localhost:8080/metrics
```

### Setup and Initialization

```bash
# Initial setup (interactive configuration)
./setup.sh

# Manual backup
./backup.sh

# Connect a device to the network
sudo tailscale up --login-server https://your-domain.com --authkey <preauth-key>
```

## Development Workflow

1. **Local Development Mode**: The stack is currently configured for local development:
   - Caddy serves HTTP on port 8080 (no TLS)
   - Headscale server_url is set to `http://localhost:8080`
   - No automatic HTTPS via Let's Encrypt

2. **Production Deployment**: To deploy to production:
   - Update Caddyfile to enable auto_https and listen on ports 80/443
   - Update `config/config.yaml` server_url to `https://your-domain.com:443`
   - Ensure `.env` has correct HEADSCALE_DOMAIN
   - Ensure PostgreSQL password is synced between `.env` and `config/config.yaml`
   - Ensure DNS points to the server

3. **ACL Policies**: To enable access control:
   - Copy `config/acl.example.json` to create your policy file
   - Set `acl_policy_path: /etc/headscale/acl.json` in config.yaml
   - Restart headscale: `docker compose restart headscale`

## Important Implementation Details

### PostgreSQL Health Check
The headscale service depends on postgres being healthy (healthcheck condition). The postgres service has a health check that runs `pg_isready` every 10 seconds.

### Volume Mounts
- `./config:/etc/headscale` - Configuration files
- `./data:/var/lib/headscale` - Headscale data (keys, state)
- `postgres-data:/var/lib/postgresql/data` - Database persistence

### Network Architecture
All services communicate via the `headscale-network` bridge network. Headscale's metrics endpoint (8080) is exposed only to localhost on the host machine.

### DERP Configuration
By default, the stack uses Tailscale's public DERP servers (`controlplane.tailscale.com/derpmap/default`). To use a custom DERP server, enable the embedded DERP in `config/config.yaml` or specify custom DERP map URLs.

### DNS (MagicDNS)
MagicDNS is enabled by default with `base_domain: headscale.net`. Nodes will be accessible at `<nodename>.headscale.net` within the network. Global nameservers are set to Cloudflare (1.1.1.1, 1.0.0.1).
