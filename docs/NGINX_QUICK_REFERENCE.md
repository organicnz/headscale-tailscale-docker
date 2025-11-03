# nginx Quick Reference

Quick reference for common nginx operations in the Headscale stack.

## File Locations

| File | Purpose | Environment |
|------|---------|-------------|
| `nginx.conf` | Development configuration | Development |
| `nginx.prod.conf` | Production configuration with SSL | Production |
| `nginx.sh` | Helper script for nginx operations | Both |
| `docker-compose.prod.yml` | Production Docker override | Production |
| `docs/NGINX_CONFIGURATION.md` | Comprehensive documentation | Both |

## Quick Commands

### Using Helper Script (Recommended)

```bash
# Show status
./scripts/nginx.sh status

# Test configuration
./scripts/nginx.sh test

# Reload configuration (no downtime)
./scripts/nginx.sh reload

# Show logs
./scripts/nginx.sh logs        # Last 50 lines
./scripts/nginx.sh logs 100    # Last 100 lines
./scripts/nginx.sh logs all    # Follow mode

# Check health
./scripts/nginx.sh health

# Show access/error logs
./scripts/nginx.sh access-log 100
./scripts/nginx.sh error-log 50

# Show statistics
./scripts/nginx.sh stats
./scripts/nginx.sh connections

# SSL operations (production)
./scripts/nginx.sh ssl-info
```

### Direct Docker Commands

```bash
# Test configuration
docker exec nginx nginx -t

# Reload without downtime
docker exec nginx nginx -s reload

# Restart container
docker compose restart nginx

# View logs
docker logs nginx
docker logs -f nginx --tail 100

# Execute command in container
docker exec nginx <command>
```

## Configuration Management

### Development Mode (Default)

```bash
# Start
docker compose up -d

# Access
http://localhost:8000              # Headscale
http://localhost:8000/admin        # Headplane UI
http://localhost:8000/health       # Health check
```

### Production Mode

```bash
# Start
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Access
https://yourdomain.com              # Headscale
https://yourdomain.com/admin        # Headplane UI
https://yourdomain.com/health       # Health check
```

### Switch from Dev to Prod

```bash
# 1. Update .env with your domain
HEADSCALE_DOMAIN=yourdomain.com

# 2. Obtain SSL certificates
docker compose -f docker-compose.yml -f docker-compose.prod.yml run --rm certbot certonly \
  --webroot --webroot-path=/var/www/certbot \
  -d yourdomain.com --email your@email.com --agree-tos

# 3. Update config/config.yaml
server_url: https://yourdomain.com

# 4. Start with production config
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

## Troubleshooting Flowchart

```
[502 Bad Gateway]
    ↓
Is Headscale running?
    ├─ No → docker compose up -d
    └─ Yes → Check logs: docker logs headscale
                ↓
         Network connectivity?
            └─ docker exec nginx ping headscale

[429 Too Many Requests]
    ↓
Adjust rate limits in nginx.prod.conf
    └─ Increase burst value or rate

[SSL Certificate Errors]
    ↓
Check certificate validity
    ├─ ./scripts/nginx.sh ssl-info
    └─ Renew: docker compose run --rm certbot renew

[WebSocket Connection Failures]
    ↓
Verify WebSocket headers
    ├─ Check nginx.conf has map $http_upgrade
    └─ Check proxy_set_header Upgrade/Connection
```

## Common Edits

### Add IP Whitelist to Metrics

Edit `nginx.conf` or `nginx.prod.conf`:
```nginx
location = /metrics {
    allow 192.168.1.0/24;
    allow 10.0.0.5;
    deny all;
    # ... rest of config
}
```

### Change Rate Limits

Edit `nginx.prod.conf`:
```nginx
# More restrictive
limit_req_zone $binary_remote_addr zone=general:10m rate=5r/s;

# More permissive
limit_req_zone $binary_remote_addr zone=general:10m rate=20r/s;
```

### Add Basic Auth to Admin

```bash
# Create password file
docker exec nginx apk add apache2-utils
docker exec nginx htpasswd -c /etc/nginx/.htpasswd admin

# Edit nginx config
location /admin {
    auth_basic "Restricted";
    auth_basic_user_file /etc/nginx/.htpasswd;
    # ... rest of config
}

# Reload
./scripts/nginx.sh reload
```

### Increase Upload Size

Edit `nginx.conf` or `nginx.prod.conf`:
```nginx
http {
    client_max_body_size 500M;  # Change from 100M
    # ...
}
```

## Performance Tuning Quick Wins

```nginx
# More connections (http block)
worker_processes auto;
worker_connections 4096;  # Up from 2048

# Larger buffers (http block)
proxy_buffers 32 8k;      # More buffers
proxy_buffer_size 16k;    # Larger header buffer

# Tune keepalive (upstream block)
keepalive 64;             # More persistent connections
keepalive_timeout 120s;   # Longer timeout
```

## Log Analysis

```bash
# Find slowest requests
docker exec nginx awk '{print $NF, $0}' /var/log/nginx/access.log | sort -rn | head -20

# Count status codes
docker exec nginx awk '{print $9}' /var/log/nginx/access.log | sort | uniq -c | sort -rn

# Find most active IPs
docker exec nginx awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -rn | head -20

# Average response time
docker exec nginx awk -F'rt=' '{print $2}' /var/log/nginx/access.log | awk '{sum+=$1; count++} END {print sum/count}'
```

## Security Checklist

- [ ] SSL/TLS certificates configured and valid
- [ ] HSTS enabled (production)
- [ ] Rate limiting configured
- [ ] Server tokens disabled (`server_tokens off`)
- [ ] Security headers added
- [ ] Metrics endpoint restricted (if needed)
- [ ] Admin interface protected (basic auth or IP whitelist)
- [ ] Firewall configured (allow 80, 443; block others)
- [ ] Regular certificate renewals (automated)
- [ ] Logs monitored for suspicious activity

## Health Check Endpoints

| Endpoint | Purpose | Expected Response |
|----------|---------|-------------------|
| `/health` | Headscale health | HTTP 200 |
| `/metrics` | Prometheus metrics | HTTP 200, text/plain |
| `http://localhost:8080/health` | Direct (inside container) | HTTP 200 |

## SSL Certificate Management

```bash
# Initial certificate (first time)
docker compose -f docker-compose.yml -f docker-compose.prod.yml run --rm certbot certonly \
  --webroot --webroot-path=/var/www/certbot \
  -d yourdomain.com \
  --email your@email.com \
  --agree-tos

# Check expiration
./scripts/nginx.sh ssl-info

# Manual renewal
docker compose -f docker-compose.yml -f docker-compose.prod.yml run --rm certbot renew

# Automatic renewal
# Already configured in docker-compose.prod.yml (runs every 12h)
```

## Migration Checklist

### From Caddy to nginx
- [x] nginx configuration created
- [x] WebSocket support verified
- [x] Health checks working
- [x] Headplane routing configured
- [ ] Test all endpoints
- [ ] Monitor logs for errors
- [ ] Update documentation

### From Dev to Production
- [ ] Update HEADSCALE_DOMAIN in .env
- [ ] Obtain SSL certificates
- [ ] Update config/config.yaml server_url
- [ ] Configure DNS
- [ ] Configure firewall (ports 80, 443)
- [ ] Test HTTPS access
- [ ] Verify certificate auto-renewal
- [ ] Monitor metrics and logs

## Testing Commands

```bash
# Test HTTP access (dev)
curl -v http://localhost:8000/health

# Test HTTPS access (prod)
curl -v https://yourdomain.com/health

# Test WebSocket upgrade
curl -v -H "Upgrade: websocket" -H "Connection: Upgrade" http://localhost:8000/

# Test with custom headers
curl -v -H "X-Custom: value" http://localhost:8000/health

# Load test (requires apache bench)
ab -n 1000 -c 10 http://localhost:8000/health

# SSL test (external service)
# Visit: https://www.ssllabs.com/ssltest/
```

## Important Files to Back Up

```
./nginx.conf                    # Dev config
./nginx.prod.conf               # Prod config
./certbot/conf/                 # SSL certificates
./.env                          # Environment variables
./config/config.yaml            # Headscale config
./docker-compose.yml            # Base compose file
./docker-compose.prod.yml       # Prod overrides
```

## Getting More Help

- Full documentation: `docs/NGINX_CONFIGURATION.md`
- nginx docs: https://nginx.org/en/docs/
- Helper script: `./scripts/nginx.sh help`
- View logs: `./scripts/nginx.sh logs all`
- Test config: `./scripts/nginx.sh test`
