# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a Docker Compose-based Headscale deployment stack. Headscale is an open-source, self-hosted implementation of the Tailscale control server. The stack includes:

- **Headscale**: Control server for the VPN mesh network
- **PostgreSQL**: Database backend for Headscale
- **nginx**: Reverse proxy (configured for local development on port 8080)

## Architecture

```
Client Devices (Tailscale)
    ↓
nginx (:8080) → Headscale (:8080 internally) → PostgreSQL
```

The stack uses a bridge network (`headscale-network`) for internal communication. Headscale stores its state in PostgreSQL and serves both the control plane API and health/metrics endpoints.

## Key Configuration Files

- **docker-compose.yml**: Production-ready service definitions with SSL/TLS support
- **nginx.conf**: Production nginx configuration with HTTPS, rate limiting, and security headers
- **nginx.dev.conf**: Development nginx configuration (HTTP only, no SSL) - used via docker-compose.override.yml
- **config/config.yaml**: Headscale server configuration including database connection, DERP settings, DNS (MagicDNS), and IP prefixes
- **config/acl.example.json**: Example ACL policy showing groups, tag owners, and access rules
- **.env**: Environment variables (domain, PostgreSQL credentials, timezone)

## Critical Configuration Notes

1. **Database Password Sync**: The PostgreSQL password must match in both `.env` (POSTGRES_PASSWORD) and `config/config.yaml` (database.postgres.password)

2. **Server URL**: In `config/config.yaml`, the `server_url` must match your deployment:
   - Local dev: `http://localhost:8080`
   - Production: `https://your-domain.com:443`

3. **nginx Configuration**: nginx.conf is production-ready with SSL/TLS, rate limiting, and security headers. For local development, use nginx.dev.conf (simple HTTP, no SSL) via docker-compose.override.yml.

## Common Commands

### Stack Management

**Production Mode** (default):
```bash
# Start all services with SSL/TLS
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

**Development Mode** (local testing without SSL):
```bash
# Create override file for development
cp docker-compose.override.example.yml docker-compose.override.yml

# Start with development overrides
docker compose up -d

# Services will use nginx.conf (no SSL) on port 8000
# Access: http://localhost:8000
```

### Headscale Management (via helper script)

The `scripts/headscale.sh` script provides a wrapper for common operations:

```bash
# User management
./scripts/headscale.sh users list
./scripts/headscale.sh users create <username>
./scripts/headscale.sh users destroy <username>

# Node management
./scripts/headscale.sh nodes list
./scripts/headscale.sh nodes delete <node-id>
./scripts/headscale.sh nodes expire  # expire all offline nodes

# Pre-auth key management
./scripts/headscale.sh keys list <username>
./scripts/headscale.sh keys create <username> --reusable --expiration 24h

# Routes
./scripts/headscale.sh routes list
./scripts/headscale.sh routes enable <route-id>

# Status and health
./scripts/headscale.sh status
./scripts/headscale.sh health
./scripts/headscale.sh logs [lines]
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
./scripts/setup.sh

# Manual backup
./scripts/backup.sh

# Connect a device to the network
sudo tailscale up --login-server https://your-domain.com --authkey <preauth-key>
```

## Development Workflow

**docker-compose.yml** is production-ready by default with SSL/TLS support.

1. **Local Development Mode**:
   - Create development override: `cp docker-compose.override.example.yml docker-compose.override.yml`
   - Start stack: `docker compose up -d`
   - nginx serves HTTP on port 8000 (no TLS)
   - Uses nginx.dev.conf (simple HTTP config, mounted via override)
   - Headscale server_url: `http://localhost:8000`
   - Access: http://localhost:8000

2. **Production Deployment**:
   - Update `.env` with your HEADSCALE_DOMAIN
   - Update `config/config.yaml` server_url to `https://your-domain.com`
   - Ensure PostgreSQL password is synced between `.env` and `config/config.yaml`
   - Configure DNS to point to your server
   - Obtain SSL certificates: `./scripts/nginx.sh ssl-init` (see docs/NGINX_CONFIGURATION.md)
   - Start stack: `docker compose up -d` (no override file)
   - Access: https://your-domain.com

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
