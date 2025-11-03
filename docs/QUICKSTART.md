# Quick Start Guide

Choose your deployment mode:

## 🚀 Production (with SSL/TLS)

**Prerequisites**: Domain name, DNS configured, ports 80/443 open

```bash
# 1. Configure environment
cp .env.example .env
nano .env  # Set HEADSCALE_DOMAIN to your domain

# 2. Update Headscale config
nano config/config.yaml  # Set server_url to https://your-domain.com

# 3. Obtain SSL certificates
mkdir -p certbot/conf certbot/www
docker compose up -d nginx

docker compose run --rm certbot certonly \
  --webroot --webroot-path=/var/www/certbot \
  --email your@email.com --agree-tos \
  -d your-domain.com

# 4. Start all services
docker compose restart nginx
docker compose up -d

# 5. Verify
curl https://your-domain.com/health
```

**Access**: https://your-domain.com

---

## 💻 Development (local, no SSL)

**Prerequisites**: Docker and Docker Compose installed

```bash
# 1. Create development override
cp docker-compose.override.example.yml docker-compose.override.yml

# 2. Configure environment
cp .env.example .env
nano .env  # Set HEADSCALE_DOMAIN=localhost

# 3. Start all services
docker compose up -d

# 4. Verify
curl http://localhost:8000/health
```

**Access**: http://localhost:8000

---

## 🔧 Common Commands

```bash
# Service management
docker compose ps              # Check status
docker compose logs -f         # View logs
docker compose restart nginx   # Restart service
docker compose down            # Stop all services

# nginx helper script
./scripts/nginx.sh status             # Service status
./scripts/nginx.sh logs 50            # View logs
./scripts/nginx.sh test               # Test config
./scripts/nginx.sh reload             # Hot reload
./scripts/nginx.sh health             # Health check

# Headscale management
./scripts/headscale.sh users create myuser           # Create user
./scripts/headscale.sh keys create myuser --reusable # Create auth key
./scripts/headscale.sh nodes list                    # List nodes
./scripts/headscale.sh status                        # Check status
```

---

## 📱 Connect a Device

```bash
# 1. Create user and key
./scripts/headscale.sh users create myuser
./scripts/headscale.sh keys create myuser --reusable --expiration 24h

# 2. On your device (production)
sudo tailscale up --login-server https://your-domain.com --authkey <key>

# 2. On your device (development)
sudo tailscale up --login-server http://localhost:8000 --authkey <key>
```

---

## 🔄 Switch Between Modes

### Development → Production

```bash
docker compose down
rm docker-compose.override.yml
# Update .env with production domain
./scripts/nginx.sh ssl-init
docker compose up -d
```

### Production → Development

```bash
docker compose down
cp docker-compose.override.example.yml docker-compose.override.yml
# Update .env with localhost
docker compose up -d
```

---

## 📚 Full Documentation

- **[DEPLOYMENT.md](docs/DEPLOYMENT.md)** - Complete deployment guide
- **[NGINX_CONFIGURATION.md](docs/NGINX_CONFIGURATION.md)** - nginx setup and tuning
- **[NGINX_QUICK_REFERENCE.md](docs/NGINX_QUICK_REFERENCE.md)** - Quick command reference
- **[CLAUDE.md](CLAUDE.md)** - Development guidelines
- **[SECURITY.md](docs/SECURITY.md)** - Security best practices

---

## ❓ Troubleshooting

**nginx won't start:**
```bash
./scripts/nginx.sh test          # Test configuration
./scripts/nginx.sh error-logs    # Check errors
sudo lsof -i :80         # Check port usage
```

**Can't connect to Headscale:**
```bash
curl http://localhost:9090/health  # Check health
docker compose logs headscale      # View logs
```

**SSL certificate issues:**
```bash
./scripts/nginx.sh ssl-info                          # Check certificate
docker compose logs certbot                  # View certbot logs
docker compose run --rm certbot renew        # Renew manually
```

For more help, see [DEPLOYMENT.md](docs/DEPLOYMENT.md) or [DEBUG_REPORT.md](docs/DEBUG_REPORT.md).
