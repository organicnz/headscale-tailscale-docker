# Deployment Guide

This guide covers deploying the Headscale stack in both development and production environments.

## Overview

The stack uses a **production-first** approach:
- `docker-compose.yml` - Production-ready configuration with SSL/TLS
- `docker-compose.override.yml` - Local development overrides (not tracked in git)
- `docker-compose.override.example.yml` - Example development configuration

## Local Development Setup

### 1. Create Development Override

```bash
# Copy the example override file
cp docker-compose.override.example.yml docker-compose.override.yml

# This file is gitignored and won't be committed
```

### 2. Configure Environment

```bash
# Copy environment template
cp .env.example .env

# Edit .env - use localhost for development
nano .env
```

Set these values for development:
```env
HEADSCALE_DOMAIN=localhost
POSTGRES_PASSWORD=your_secure_password
HEADPLANE_API_KEY=your_api_key
HEADPLANE_COOKIE_SECRET=your_cookie_secret
```

### 3. Start Development Stack

```bash
# Start all services
docker compose up -d

# Check status
docker compose ps

# View logs
docker compose logs -f
```

### 4. Access Services

- **Headscale API**: http://localhost:8000
- **Headplane UI**: http://localhost:8000/admin (or http://localhost:3001)
- **Health Check**: http://localhost:8000/health

### 5. Development Workflow

```bash
# View nginx logs
./scripts/nginx.sh logs 50

# Test nginx config
./scripts/nginx.sh test

# Reload nginx (after config changes)
./scripts/nginx.sh reload

# Restart services
docker compose restart nginx

# Stop everything
docker compose down
```

## Production Deployment

### Prerequisites

1. **Domain Name**: You need a domain name (e.g., headscale.example.com)
2. **DNS Configuration**: Point your domain to your server's IP address
3. **Firewall**: Open ports 80 and 443
4. **Server**: Recommended 2GB RAM, 20GB disk

### 1. Initial Setup

```bash
# Clone repository
git clone <your-repo>
cd headscale-tailscale-docker

# Copy environment file
cp .env.example .env

# Edit .env with production values
nano .env
```

Production .env configuration:
```env
# Your actual domain
HEADSCALE_DOMAIN=headscale.example.com

# Strong PostgreSQL password
POSTGRES_PASSWORD=<generate-strong-password>

# Headplane credentials
HEADPLANE_API_KEY=<generate-api-key>
HEADPLANE_COOKIE_SECRET=<generate-cookie-secret>

# Timezone
TZ=UTC
```

### 2. Configure Headscale

Edit `config/config.yaml`:

```yaml
server_url: https://headscale.example.com

# Update database password to match .env
database:
  type: postgres
  postgres:
    host: postgres
    port: 5432
    name: headscale
    user: headscale
    password: <same-as-POSTGRES_PASSWORD-in-env>
```

### 3. Obtain SSL Certificates

**First Time Setup:**

```bash
# Create directories
mkdir -p certbot/conf certbot/www

# Temporarily start nginx without SSL
docker compose up -d nginx

# Obtain certificate
docker compose run --rm certbot certonly \
  --webroot \
  --webroot-path=/var/www/certbot \
  --email your-email@example.com \
  --agree-tos \
  --no-eff-email \
  -d headscale.example.com

# Restart nginx with SSL
docker compose restart nginx
```

**Using nginx.sh Helper:**

```bash
# Initialize SSL certificates
./scripts/nginx.sh ssl-init

# Check certificate status
./scripts/nginx.sh ssl-info
```

### 4. Start Production Stack

```bash
# Do NOT create docker-compose.override.yml
# The base docker-compose.yml is production-ready

# Start all services
docker compose up -d

# Check status
docker compose ps

# View logs
./scripts/nginx.sh logs 100

# Check health
./scripts/nginx.sh health
```

### 5. Verify Production Deployment

```bash
# Test HTTPS endpoint
curl https://headscale.example.com/health

# Check SSL certificate
./scripts/nginx.sh ssl-info

# View nginx access logs
./scripts/nginx.sh access-logs 20

# Check all services
docker compose ps
```

### 6. Create First User and Device

```bash
# Create a user
./scripts/headscale.sh users create myuser

# Generate pre-auth key
./scripts/headscale.sh keys create myuser --reusable --expiration 24h

# On your device, connect using:
sudo tailscale up --login-server https://headscale.example.com --authkey <key>
```

## Production Maintenance

### Certificate Renewal

Certbot automatically renews certificates. Monitor with:

```bash
# Check certificate expiry
./scripts/nginx.sh ssl-info

# Manual renewal (if needed)
docker compose run --rm certbot renew

# Reload nginx after renewal
docker compose restart nginx
```

### Updates

```bash
# Pull latest images
docker compose pull

# Restart with new images
docker compose up -d

# Check logs for issues
./scripts/nginx.sh logs 50
```

### Backups

```bash
# Backup database
./scripts/backup.sh

# Backups saved to ./backups/
ls -lh backups/
```

### Monitoring

```bash
# Service health
./scripts/nginx.sh health

# Resource usage
./scripts/nginx.sh stats

# Active connections
./scripts/nginx.sh connections

# Recent errors
./scripts/nginx.sh error-logs 20
```

## Switching Between Dev and Prod

### From Development to Production

```bash
# 1. Stop development stack
docker compose down

# 2. Remove override file
rm docker-compose.override.yml

# 3. Update .env with production domain
nano .env

# 4. Obtain SSL certificates (see above)
./scripts/nginx.sh ssl-init

# 5. Start production stack
docker compose up -d
```

### From Production to Development

```bash
# 1. Stop production stack
docker compose down

# 2. Create development override
cp docker-compose.override.example.yml docker-compose.override.yml

# 3. Update .env for localhost
nano .env  # Set HEADSCALE_DOMAIN=localhost

# 4. Start development stack
docker compose up -d
```

## Troubleshooting

### nginx Won't Start

```bash
# Test configuration
./scripts/nginx.sh test

# Check logs
./scripts/nginx.sh error-logs 50

# Verify ports not in use
sudo lsof -i :80
sudo lsof -i :443
```

### SSL Certificate Issues

```bash
# Check certificate status
./scripts/nginx.sh ssl-info

# View certbot logs
docker compose logs certbot

# Manually renew
docker compose run --rm certbot renew --force-renewal
```

### Headscale Connection Issues

```bash
# Check health endpoint
curl http://localhost:9090/health

# View headscale logs
docker compose logs headscale

# Verify database connection
docker exec -it headscale-db psql -U headscale -c "SELECT 1;"
```

### Database Issues

```bash
# Check postgres health
docker compose exec postgres pg_isready

# View database logs
docker compose logs postgres

# Access database
docker exec -it headscale-db psql -U headscale
```

## Security Hardening

### 1. Update Default Passwords

Change all default passwords in `.env`:
- POSTGRES_PASSWORD
- HEADPLANE_API_KEY
- HEADPLANE_COOKIE_SECRET

### 2. Configure Firewall

```bash
# Allow only necessary ports
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 22/tcp  # SSH
sudo ufw enable
```

### 3. Enable Rate Limiting

Rate limiting is enabled by default in nginx.prod.conf. Adjust if needed:

```nginx
# In nginx.prod.conf
limit_req_zone $binary_remote_addr zone=general:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=api:10m rate=30r/s;
```

### 4. Regular Updates

```bash
# Update OS packages
sudo apt update && sudo apt upgrade -y

# Update Docker images
docker compose pull
docker compose up -d
```

### 5. Monitor Logs

```bash
# Set up log monitoring
./scripts/nginx.sh follow  # Follow logs in real-time

# Check for errors daily
./scripts/nginx.sh error-logs 100 | grep -i error
```

## Architecture

### Production Stack

```
Internet (Port 80/443)
    ↓
nginx (SSL/TLS termination)
    ↓
Headscale (:8080) ← PostgreSQL
    ↑
Headplane UI (:3000)
```

### Development Stack

```
localhost:8000 (HTTP)
    ↓
nginx (No SSL)
    ↓
Headscale (:8080) ← PostgreSQL
    ↑
Headplane UI (:3000 and :3001)
```

## Environment Variables

| Variable | Production | Development |
|----------|-----------|-------------|
| HEADSCALE_DOMAIN | headscale.example.com | localhost |
| POSTGRES_PASSWORD | Strong password | Any password |
| TZ | UTC | UTC |
| LOG_LEVEL | info | debug (optional) |

## Ports

| Port | Service | Production | Development |
|------|---------|-----------|-------------|
| 80 | nginx HTTP | ✅ (→443) | ❌ |
| 443 | nginx HTTPS | ✅ | ❌ |
| 8000 | nginx HTTP | ❌ | ✅ |
| 3001 | Headplane | ✅ | ✅ |
| 9090 | Metrics | localhost only | localhost only |

## Additional Resources

- [nginx Configuration Guide](NGINX_CONFIGURATION.md)
- [nginx Quick Reference](NGINX_QUICK_REFERENCE.md)
- [Security Best Practices](SECURITY.md)
- [Troubleshooting Guide](DEBUG_REPORT.md)
