# nginx Configuration Consolidation

## Summary

Successfully consolidated nginx configuration into a single production-ready file with development override.

## Changes Made

### Before
- `nginx.conf` - Development configuration (HTTP, no SSL)
- `nginx.prod.conf` - Production configuration (HTTPS, SSL, rate limiting)

### After
- `nginx.conf` - **Production-ready** (HTTPS, SSL/TLS, rate limiting, security headers)
- `nginx.dev.conf` - Development configuration (simple HTTP, no SSL)

## Philosophy

**Production-first design**: nginx.conf is optimized for production deployment with:
- ✅ SSL/TLS with modern ciphers (TLS 1.2/1.3)
- ✅ HTTP to HTTPS redirect
- ✅ Rate limiting (3-tier: general 10r/s, API 30r/s, health 100r/s)
- ✅ Security headers (HSTS, CSP, X-Frame-Options, etc.)
- ✅ OCSP stapling
- ✅ HTTP/2 support
- ✅ DDoS protection
- ✅ Optimized for production workloads

**Development is opt-in**: nginx.dev.conf provides simplified configuration for local testing:
- Simple HTTP on port 8080
- No SSL certificate requirements
- No rate limiting
- Reduced security headers (still safe for dev)
- Lower resource settings

## File Structure

```
nginx.conf          → Production (SSL/TLS, HTTPS on 80/443)
nginx.dev.conf      → Development (HTTP on 8080)
docker-compose.yml  → Uses nginx.conf by default
docker-compose.override.yml → Mounts nginx.dev.conf
```

## Usage

### Production Deployment

```bash
# Uses nginx.conf automatically
docker compose up -d

# Access via HTTPS
https://your-domain.com
```

**nginx.conf provides:**
- SSL/TLS termination
- HTTP→HTTPS redirect
- Rate limiting per endpoint
- Enhanced security headers
- Connection limits per IP
- OCSP stapling
- HTTP/2 support

### Local Development

```bash
# Create override to use nginx.dev.conf
cp docker-compose.override.example.yml docker-compose.override.yml

# Start with development config
docker compose up -d

# Access via HTTP
http://localhost:8000
```

**nginx.dev.conf provides:**
- Simple HTTP (no certificates needed)
- Lower resource limits
- Simplified logging
- No rate limiting
- Minimal security headers

## Configuration Comparison

| Feature | nginx.conf (Prod) | nginx.dev.conf (Dev) |
|---------|-------------------|----------------------|
| **Protocol** | HTTPS (443) + HTTP redirect (80) | HTTP (8080) |
| **SSL/TLS** | Yes (TLS 1.2/1.3) | No |
| **HTTP/2** | Yes | No |
| **Rate Limiting** | 3 zones (10/30/100 r/s) | No |
| **Connection Limits** | 10 per IP | No |
| **HSTS** | Yes (1 year + preload) | No |
| **CSP Header** | Yes (restrictive) | No |
| **Security Headers** | 7 headers | 4 basic headers |
| **OCSP Stapling** | Yes | No |
| **Worker Connections** | 4096 | 2048 |
| **Timeouts** | 90s | 90s |
| **Keepalive** | 65s | 65s |
| **Gzip** | Yes (level 6) | Yes (level 6) |
| **Proxy Buffers** | 16 × 8k | 16 × 8k |
| **WebSocket** | Yes | Yes |
| **Headplane /admin** | Yes | Yes |

## Benefits

### Production
1. **Secure by default** - SSL/TLS enabled, HSTS enforced
2. **DDoS protection** - Rate limiting and connection limits
3. **Performance** - HTTP/2, OCSP stapling, optimized buffers
4. **Monitoring** - Enhanced logging with SSL info
5. **Best practices** - Modern TLS config, security headers

### Development
1. **Simple setup** - No certificates needed
2. **Fast iteration** - Hot reload with ./scripts/nginx.sh reload
3. **Easy debugging** - Simplified logging
4. **No complexity** - Plain HTTP, no SSL overhead
5. **Resource friendly** - Lower connection limits

## Migration

### From Previous Setup

The consolidation is automatic:

```bash
# Old files renamed/moved:
nginx.conf → nginx.dev.conf (development)
nginx.prod.conf → nginx.conf (production)

# No action needed if using docker-compose.override.yml
# It now mounts nginx.dev.conf automatically
```

### Switching Between Modes

**Development → Production:**
```bash
docker compose down
rm docker-compose.override.yml
docker compose up -d
# Now uses nginx.conf (production)
```

**Production → Development:**
```bash
docker compose down
cp docker-compose.override.example.yml docker-compose.override.yml
docker compose up -d
# Now uses nginx.dev.conf (development)
```

## SSL/TLS Configuration

### Production (nginx.conf)

```nginx
# SSL protocols - modern only
ssl_protocols TLSv1.2 TLSv1.3;

# Strong cipher suites
ssl_ciphers 'ECDHE-ECDSA-AES128-GCM-SHA256:...';

# Certificate paths (Let's Encrypt)
ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;

# OCSP stapling
ssl_stapling on;
ssl_stapling_verify on;

# Session cache
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 10m;
```

### Development (nginx.dev.conf)

No SSL configuration needed - simple HTTP only.

## Rate Limiting

### Production (nginx.conf)

Three rate limiting zones:

```nginx
# General requests - 10 per second
limit_req_zone $binary_remote_addr zone=general:10m rate=10r/s;

# API endpoints - 30 per second
limit_req_zone $binary_remote_addr zone=api:10m rate=30r/s;

# Health checks - 100 per second
limit_req_zone $binary_remote_addr zone=health:10m rate=100r/s;
```

Applied per location:
- `/` → general (10 r/s)
- `/api/*` → api (30 r/s)
- `/health` → health (100 r/s)
- `/admin` → general (20 burst)

### Development (nginx.dev.conf)

No rate limiting for easy testing.

## Security Headers

### Production (nginx.conf)

7 security headers applied:
- `Strict-Transport-Security` (HSTS with preload)
- `X-Frame-Options` (SAMEORIGIN)
- `X-Content-Type-Options` (nosniff)
- `X-XSS-Protection` (enabled)
- `Referrer-Policy` (strict-origin-when-cross-origin)
- `Content-Security-Policy` (restrictive)
- `Permissions-Policy` (restrictive)

### Development (nginx.dev.conf)

4 basic headers:
- `X-Frame-Options`
- `X-Content-Type-Options`
- `X-XSS-Protection`
- `Referrer-Policy`

## Testing

### Verify Production Config

```bash
# Test configuration syntax
./scripts/nginx.sh test

# Check SSL certificates
./scripts/nginx.sh ssl-info

# Test HTTPS endpoint
curl -I https://your-domain.com/health

# Verify rate limiting
ab -n 100 -c 10 https://your-domain.com/

# Check security headers
curl -I https://your-domain.com | grep -E "(Strict|X-Frame|X-Content)"
```

### Verify Development Config

```bash
# Test configuration
./scripts/nginx.sh test

# Test HTTP endpoint
curl http://localhost:8000/health

# Check headers (should have basic set)
curl -I http://localhost:8000 | grep X-Frame
```

## Troubleshooting

### Production Issues

**SSL certificate errors:**
```bash
# Check certificate status
./scripts/nginx.sh ssl-info

# Verify cert files exist
ls -l certbot/conf/live/*/

# Renew certificate
docker compose run --rm certbot renew
```

**Rate limiting too aggressive:**
```nginx
# Edit nginx.conf, increase rates:
limit_req_zone $binary_remote_addr zone=general:10m rate=20r/s;
# Then reload
./scripts/nginx.sh reload
```

### Development Issues

**Port 8000 in use:**
```bash
# Check what's using port
sudo lsof -i :8000

# Change port in docker-compose.override.yml
ports:
  - 8001:8080  # Use different port
```

**Config syntax errors:**
```bash
# Test nginx config
./scripts/nginx.sh test

# Check nginx logs
./scripts/nginx.sh error-logs 50
```

## Documentation Updates

Updated files to reflect consolidation:
- ✅ CLAUDE.md - Updated configuration section
- ✅ README.md - Updated file structure
- ✅ QUICKSTART.md - Added configuration philosophy
- ✅ docs/NGINX_CONFIGURATION.md - Updated paths
- ✅ docker-compose.yml - Uses nginx.conf
- ✅ docker-compose.override.example.yml - Uses nginx.dev.conf

## Benefits Summary

### For Users
1. **Clearer intent** - Production config is obvious default
2. **Less confusion** - One main config file
3. **Better security** - Production-ready by default
4. **Simpler deployment** - No need to choose config files
5. **Easy development** - Override file handles dev setup

### For Maintenance
1. **Single source of truth** - nginx.conf is canonical
2. **Version control** - Production config is tracked
3. **Less duplication** - No need to maintain two full configs
4. **Clear separation** - Dev config is explicitly different
5. **Better documentation** - Clear prod vs dev distinction

---

## Conclusion

The nginx consolidation follows the same philosophy as the docker-compose.yml consolidation:

- **Production-first**: Main config (nginx.conf) is production-ready
- **Development override**: Simple config (nginx.dev.conf) for local testing
- **Clean separation**: No mixing of production and development concerns
- **Version control**: Production config is tracked, dev config is minimal
- **Easy deployment**: `docker compose up -d` just works

**nginx.conf is now production-ready by default!** 🚀
