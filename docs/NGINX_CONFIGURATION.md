# nginx Configuration Guide

This document provides comprehensive guidance for configuring nginx as a reverse proxy for the Headscale deployment stack.

## Table of Contents

- [Overview](#overview)
- [Configuration Files](#configuration-files)
- [Development vs Production](#development-vs-production)
- [Key Features](#key-features)
- [Configuration Details](#configuration-details)
- [Performance Tuning](#performance-tuning)
- [Security Hardening](#security-hardening)
- [Troubleshooting](#troubleshooting)

## Overview

The Headscale stack uses nginx as a reverse proxy to:
- Route traffic to Headscale control server
- Provide access to Headplane web UI
- Handle SSL/TLS termination (production)
- Implement security headers and rate limiting
- Support WebSocket connections (required for Tailscale protocol)

## Configuration Files

### nginx.conf (Development)
**Location**: `/nginx.conf`
**Purpose**: Local development and testing
**Ports**: HTTP on 8000 (mapped from internal 8080)

**Key characteristics**:
- HTTP only (no SSL/TLS)
- Simplified logging
- Optimized for debugging and iteration
- WebSocket support enabled
- Routes to both Headscale and Headplane

### nginx.prod.conf (Production)
**Location**: `/nginx.prod.conf`
**Purpose**: Production deployment
**Ports**: 80 (HTTP redirect) and 443 (HTTPS)

**Key characteristics**:
- Full SSL/TLS configuration with modern ciphers
- Rate limiting and DDoS protection
- Enhanced security headers (HSTS, CSP, etc.)
- OCSP stapling
- HTTP/2 support
- Separate rate limits for different endpoints

### docker-compose.prod.yml
**Location**: `/docker-compose.prod.yml`
**Purpose**: Production override for docker-compose.yml

**Usage**:
```bash
# Development
docker compose up -d

# Production
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

## Development vs Production

### Development Mode (default)

**Start the stack**:
```bash
docker compose up -d
```

**Access points**:
- Headscale: `http://localhost:8000`
- Headplane: `http://localhost:8000/admin`
- Health check: `http://localhost:8000/health`
- Metrics: `http://localhost:8000/metrics`

**Configuration file**: `nginx.conf`

### Production Mode

**Prerequisites**:
1. Valid domain name with DNS pointing to your server
2. Update `HEADSCALE_DOMAIN` in `.env` file
3. Obtain SSL certificates (see [SSL Setup](#ssl-setup))
4. Configure firewall to allow ports 80 and 443

**Start the stack**:
```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

**Access points**:
- Headscale: `https://yourdomain.com`
- Headplane: `https://yourdomain.com/admin`
- Health check: `https://yourdomain.com/health`
- Metrics: `https://yourdomain.com/metrics` (restricted)

**Configuration file**: `nginx.prod.conf`

## Key Features

### 1. WebSocket Support

Both configurations include proper WebSocket upgrade handling, critical for the Tailscale protocol:

```nginx
# Map for WebSocket upgrade handling
map $http_upgrade $connection_upgrade {
    default upgrade;
    ''      close;
}

location / {
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection $connection_upgrade;
    # ... other settings
}
```

### 2. Headplane Web UI Routing

The admin interface is accessible at `/admin`:

```nginx
location /admin {
    proxy_pass http://headplane_backend;
    proxy_buffering off;  # Interactive UI works better without buffering
    # ... WebSocket support
}
```

### 3. Health Checks

Optimized health check endpoint with fast timeouts and no logging:

```nginx
location = /health {
    proxy_pass http://headscale_backend/health;
    proxy_connect_timeout 5s;
    proxy_read_timeout 5s;
    access_log off;
}
```

### 4. Rate Limiting (Production)

Three-tier rate limiting strategy:

```nginx
# General traffic: 10 requests/second
limit_req_zone $binary_remote_addr zone=general:10m rate=10r/s;

# API traffic: 30 requests/second
limit_req_zone $binary_remote_addr zone=api:10m rate=30r/s;

# Health checks: 100 requests/second
limit_req_zone $binary_remote_addr zone=health:10m rate=100r/s;
```

### 5. Security Headers

Production configuration includes comprehensive security headers:

```nginx
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Content-Security-Policy "default-src 'self'; ..." always;
```

## Configuration Details

### Upstream Backends

Both configurations define upstream blocks for load balancing and health checking:

```nginx
upstream headscale_backend {
    server headscale:8080 max_fails=3 fail_timeout=30s;
    keepalive 32;           # Persistent connections for performance
    keepalive_requests 100;
    keepalive_timeout 60s;
}

upstream headplane_backend {
    server headplane:3000 max_fails=3 fail_timeout=30s;
    keepalive 16;
}
```

**Parameters explained**:
- `max_fails=3`: Mark backend as down after 3 failed attempts
- `fail_timeout=30s`: Wait 30s before retrying failed backend
- `keepalive 32`: Keep 32 idle connections open for reuse

### Proxy Buffering

Optimized for VPN traffic with larger buffers:

```nginx
proxy_buffering on;
proxy_buffer_size 8k;           # Headers
proxy_buffers 16 8k;            # Body (16 x 8k = 128k total)
proxy_busy_buffers_size 16k;
proxy_max_temp_file_size 2048m; # Large temp files for big transfers
```

**Trade-offs**:
- Buffering ON: Better performance for most traffic, allows nginx to free up backend connections
- Buffering OFF: Better for interactive/streaming content (used for Headplane UI)

### Worker Configuration

**Development**:
```nginx
worker_processes auto;
worker_connections 2048;
```

**Production**:
```nginx
worker_processes auto;
worker_rlimit_nofile 65535;  # Increase file descriptor limit
worker_connections 4096;       # More concurrent connections
```

## Performance Tuning

### For High-Traffic Deployments

1. **Increase worker connections**:
```nginx
events {
    worker_connections 8192;  # Adjust based on RAM and expected load
    worker_rlimit_nofile 100000;
}
```

2. **Tune buffer sizes for your workload**:
```nginx
# For many small requests
proxy_buffers 32 4k;

# For fewer large requests
proxy_buffers 8 16k;
```

3. **Enable caching (if applicable)**:
```nginx
# Add to http block
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=headscale_cache:10m max_size=1g inactive=60m;

# Use in location blocks
location / {
    proxy_cache headscale_cache;
    proxy_cache_valid 200 5m;
    # ... other settings
}
```

4. **Monitor performance**:
```bash
# Check nginx stub status (requires ngx_http_stub_status_module)
# Add to nginx.conf:
location /nginx_status {
    stub_status;
    allow 127.0.0.1;
    deny all;
}

# Access
curl http://localhost:8000/nginx_status
```

### Tuning Checklist

- [ ] Monitor CPU usage (`top`, `htop`)
- [ ] Monitor memory usage (`free -h`)
- [ ] Check connection states (`ss -s`)
- [ ] Review nginx error logs for timeout issues
- [ ] Monitor upstream response times (check access logs with timing format)
- [ ] Test with realistic load (`ab`, `wrk`, `vegeta`)

## Security Hardening

### SSL/TLS Best Practices

1. **Use strong cipher suites** (already configured in nginx.prod.conf):
```nginx
ssl_protocols TLSv1.2 TLSv1.3;
ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:...';
ssl_prefer_server_ciphers off;  # Let client choose (TLS 1.3 best practice)
```

2. **Generate strong DH parameters**:
```bash
openssl dhparam -out ./nginx/dhparam.pem 2048
```

Then uncomment in nginx.prod.conf:
```nginx
ssl_dhparam /etc/nginx/dhparam.pem;
```

3. **Enable OCSP stapling** (already configured):
```nginx
ssl_stapling on;
ssl_stapling_verify on;
```

### Access Control

**Restrict metrics endpoint** (edit nginx.prod.conf):
```nginx
location = /metrics {
    # Allow only specific IPs
    allow 10.0.0.0/8;       # Internal network
    allow 192.168.0.0/16;   # Private network
    deny all;

    proxy_pass http://headscale_backend/metrics;
}
```

**Protect admin interface with authentication**:
```bash
# Install htpasswd utility
docker exec -it nginx apk add apache2-utils

# Create password file
docker exec -it nginx htpasswd -c /etc/nginx/.htpasswd admin
```

Uncomment in nginx.prod.conf:
```nginx
location /admin {
    auth_basic "Restricted Access";
    auth_basic_user_file /etc/nginx/.htpasswd;
    # ... rest of configuration
}
```

### Rate Limiting Customization

Adjust rates based on your usage patterns:

```nginx
# More restrictive
limit_req_zone $binary_remote_addr zone=general:10m rate=5r/s;

# More permissive
limit_req_zone $binary_remote_addr zone=general:10m rate=20r/s;

# Different burst values
location / {
    limit_req zone=general burst=50 nodelay;  # Allow bursts of 50
}
```

### IP Whitelisting/Blacklisting

```nginx
# Block specific IPs
location / {
    deny 192.168.1.100;
    deny 10.0.0.0/24;
    allow all;
    # ... rest of configuration
}

# Allow only specific IPs
location /admin {
    allow 192.168.1.0/24;
    allow 10.0.0.5;
    deny all;
    # ... rest of configuration
}
```

## SSL Setup

### Using Let's Encrypt with Certbot

1. **Initial certificate generation**:
```bash
# First, start nginx with HTTP only to get certificates
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Generate certificate
docker compose -f docker-compose.yml -f docker-compose.prod.yml run --rm certbot certonly \
  --webroot \
  --webroot-path=/var/www/certbot \
  -d yourdomain.com \
  -d www.yourdomain.com \
  --email your-email@example.com \
  --agree-tos \
  --no-eff-email
```

2. **Update nginx.prod.conf**:
Replace `${DOMAIN}` with your actual domain name in the SSL certificate paths.

3. **Restart nginx**:
```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml restart nginx
```

4. **Certificate renewal**:
Certificates are automatically renewed by the certbot container (runs every 12 hours).

**Manual renewal**:
```bash
docker compose -f docker-compose.yml -f docker-compose.prod.yml run --rm certbot renew
docker compose -f docker-compose.yml -f docker-compose.prod.yml restart nginx
```

### Using Custom Certificates

If you have your own certificates:

1. **Place certificates**:
```
./certs/
  ├── fullchain.pem
  ├── privkey.pem
  └── chain.pem
```

2. **Update docker-compose.prod.yml**:
```yaml
services:
  nginx:
    volumes:
      - ./certs:/etc/nginx/certs:ro
```

3. **Update nginx.prod.conf**:
```nginx
ssl_certificate /etc/nginx/certs/fullchain.pem;
ssl_certificate_key /etc/nginx/certs/privkey.pem;
ssl_trusted_certificate /etc/nginx/certs/chain.pem;
```

## Troubleshooting

### Common Issues

#### 1. "502 Bad Gateway"

**Cause**: nginx can't reach the backend service

**Solutions**:
```bash
# Check if headscale is running
docker compose ps

# Check headscale logs
docker compose logs headscale

# Verify network connectivity
docker exec nginx ping headscale

# Check if headscale is listening on port 8080
docker exec headscale netstat -tulpn | grep 8080
```

#### 2. WebSocket Connection Failures

**Cause**: Incorrect WebSocket headers or timeouts

**Solutions**:
- Verify WebSocket map is configured
- Check proxy timeout settings
- Review browser console for specific errors

**Test WebSocket**:
```bash
# Install wscat
npm install -g wscat

# Test WebSocket connection
wscat -c ws://localhost:8000/path
```

#### 3. SSL Certificate Errors

**Cause**: Invalid or expired certificates

**Solutions**:
```bash
# Check certificate validity
docker compose exec nginx openssl x509 -in /etc/letsencrypt/live/yourdomain.com/fullchain.pem -text -noout

# Check certificate expiration
docker compose exec nginx openssl x509 -in /etc/letsencrypt/live/yourdomain.com/fullchain.pem -noout -dates

# Force certificate renewal
docker compose run --rm certbot renew --force-renewal
```

#### 4. Rate Limiting Issues (429 errors)

**Cause**: Exceeding configured rate limits

**Solutions**:
```bash
# Check nginx error logs
docker compose logs nginx | grep limiting

# Adjust rate limits in nginx.prod.conf
# Increase burst value or rate
```

#### 5. Performance Issues / Slow Response

**Diagnostics**:
```bash
# Check access logs for response times
docker compose logs nginx | grep "rt="

# Monitor upstream connection times
# Look for high "uct", "uht", "urt" values in logs

# Check system resources
docker stats

# Verify no CPU/memory limits are being hit
docker compose exec nginx top
```

**Solutions**:
- Increase buffer sizes
- Increase worker connections
- Enable caching for static content
- Review upstream backend performance

### Debugging Tips

1. **Enable debug logging** (temporarily):
```nginx
error_log /var/log/nginx/error.log debug;
```

2. **Test configuration syntax**:
```bash
docker compose exec nginx nginx -t
```

3. **Reload configuration without downtime**:
```bash
docker compose exec nginx nginx -s reload
```

4. **View real-time logs**:
```bash
# All logs
docker compose logs -f nginx

# Access logs only
docker exec nginx tail -f /var/log/nginx/access.log

# Error logs only
docker exec nginx tail -f /var/log/nginx/error.log
```

5. **Check active connections**:
```bash
docker exec nginx sh -c 'echo "" | nc localhost 8080'
```

### Getting Help

If you encounter issues not covered here:

1. Check nginx error logs first
2. Review Headscale logs for backend issues
3. Test with curl to isolate the problem:
```bash
# Test basic connectivity
curl -v http://localhost:8000/health

# Test with specific headers
curl -v -H "Upgrade: websocket" -H "Connection: Upgrade" http://localhost:8000/
```

4. Consult the nginx documentation: https://nginx.org/en/docs/
5. Check Headscale documentation: https://headscale.net/

## Additional Resources

- [nginx Documentation](https://nginx.org/en/docs/)
- [nginx Security Headers Guide](https://www.nginx.com/blog/security-headers/)
- [SSL Labs Server Test](https://www.ssllabs.com/ssltest/)
- [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)
