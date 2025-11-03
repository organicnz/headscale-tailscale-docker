# nginx Architecture Overview

## System Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Client Devices                              │
│                      (Tailscale Clients)                            │
└───────────────────────────┬─────────────────────────────────────────┘
                            │
                            │ HTTP/HTTPS
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         nginx Reverse Proxy                         │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────────┐  │
│  │  Development Mode (port 8000)                                │  │
│  │  - HTTP only                                                  │  │
│  │  - nginx.conf                                                 │  │
│  │                                                               │  │
│  │  Production Mode (ports 80, 443)                             │  │
│  │  - HTTPS with Let's Encrypt                                  │  │
│  │  - nginx.prod.conf                                           │  │
│  │  - Rate limiting                                             │  │
│  │  - Security headers                                          │  │
│  └──────────────────────────────────────────────────────────────┘  │
│                                                                     │
│  Features:                                                          │
│  • WebSocket upgrade handling                                       │
│  • Request buffering & optimization                                 │
│  • Health checks                                                    │
│  • Access logging with timing                                       │
│  • Error handling & retry logic                                     │
└───────────────┬─────────────────────────┬───────────────────────────┘
                │                         │
                │                         │
    ┌───────────▼────────┐    ┌──────────▼────────┐
    │   Headscale        │    │   Headplane       │
    │   (Control Server) │    │   (Web UI)        │
    │   Port: 8080       │    │   Port: 3000      │
    │                    │    │                   │
    │   Routes:          │    │   Route:          │
    │   • /              │    │   • /admin        │
    │   • /api/*         │    │                   │
    │   • /health        │    └───────────────────┘
    │   • /metrics       │
    └─────────┬──────────┘
              │
              │
    ┌─────────▼──────────┐
    │   PostgreSQL       │
    │   (Database)       │
    │   Port: 5432       │
    └────────────────────┘
```

## Request Flow

### 1. Client Request Flow

```
Client Request
     │
     ├─ Development Mode
     │    └─> http://localhost:8000
     │         └─> nginx:8080
     │              └─> Route to backend
     │
     └─ Production Mode
          └─> https://yourdomain.com
               └─> nginx:443 (SSL termination)
                    └─> Route to backend
```

### 2. Routing Logic

```
nginx Routing Decision Tree

Request arrives at nginx
     │
     ├─ Path = /robots.txt
     │    └─> Return static response (200)
     │
     ├─ Path = /favicon.ico
     │    └─> Return 204 (no content)
     │
     ├─ Path = /health
     │    └─> Proxy to headscale:8080/health
     │         • No logging
     │         • Fast timeout (5s)
     │         • Rate limited (prod)
     │
     ├─ Path = /metrics
     │    └─> Proxy to headscale:8080/metrics
     │         • Optional IP restriction
     │         • Rate limited (prod)
     │
     ├─ Path = /admin
     │    └─> Proxy to headplane:3000
     │         • WebSocket support
     │         • Buffering disabled
     │         • Optional auth (prod)
     │
     ├─ Path = /api/*
     │    └─> Proxy to headscale:8080
     │         • Higher rate limit (prod)
     │         • WebSocket support
     │
     └─ Path = /* (default)
          └─> Proxy to headscale:8080
               • General rate limit (prod)
               • WebSocket support
               • Request buffering enabled
```

### 3. WebSocket Upgrade Flow

```
Client sends WebSocket upgrade request
     │
     ├─ Header: Upgrade: websocket
     ├─ Header: Connection: upgrade
     │
     ▼
nginx processes request
     │
     ├─ Map directive evaluates $http_upgrade
     │    └─> Sets $connection_upgrade
     │         • "upgrade" if Upgrade header present
     │         • "close" if absent
     │
     ▼
Proxy headers set
     │
     ├─ Upgrade: $http_upgrade
     ├─ Connection: $connection_upgrade
     │
     ▼
WebSocket connection established to backend
     │
     ▼
Persistent bi-directional communication
```

## Configuration Layers

### Layer 1: Global Configuration

```
nginx.conf (or nginx.prod.conf)
├─ Worker processes
├─ Event model (epoll)
├─ HTTP block
│   ├─ MIME types
│   ├─ Logging format
│   ├─ Performance settings
│   │   ├─ sendfile, tcp_nopush, tcp_nodelay
│   │   ├─ keepalive settings
│   │   └─ gzip compression
│   │
│   ├─ Security settings (prod)
│   │   ├─ SSL/TLS protocols & ciphers
│   │   ├─ OCSP stapling
│   │   └─ Rate limiting zones
│   │
│   └─ Proxy defaults
│       ├─ Buffer sizes
│       ├─ Timeouts
│       └─ Headers
```

### Layer 2: Upstream Configuration

```
Upstream Blocks
├─ headscale_backend
│   ├─ Server: headscale:8080
│   ├─ Health: max_fails=3, fail_timeout=30s
│   └─ Keepalive: 32 connections
│
└─ headplane_backend
    ├─ Server: headplane:3000
    ├─ Health: max_fails=3, fail_timeout=30s
    └─ Keepalive: 16 connections
```

### Layer 3: Server Block

```
Server Configuration
├─ Development
│   ├─ Listen: 8080 (HTTP)
│   └─ Server name: _
│
└─ Production
    ├─ Listen: 80 (HTTP redirect)
    ├─ Listen: 443 (HTTPS)
    ├─ SSL certificates
    ├─ Security headers
    └─ Server name: yourdomain.com
```

### Layer 4: Location Blocks

```
Location Routing
├─ Exact matches (=)
│   ├─ /robots.txt
│   ├─ /favicon.ico
│   ├─ /health
│   └─ /metrics
│
├─ Prefix matches
│   ├─ /admin
│   └─ /api/
│
└─ Default (/)
    └─ Catch-all for Headscale
```

## Data Flow: Typical Request

### Example: Client Node Connecting

```
1. Client initiates connection
   └─> https://yourdomain.com/machine/register

2. nginx receives request (port 443)
   ├─ SSL termination
   ├─ Security headers added
   └─ Rate limit check

3. Request matches location / (default)
   ├─ Proxy headers set
   │   ├─ Host: yourdomain.com
   │   ├─ X-Real-IP: <client-ip>
   │   ├─ X-Forwarded-For: <client-ip>
   │   └─ X-Forwarded-Proto: https
   │
   └─ Forward to headscale_backend

4. Headscale processes registration
   ├─ Database query to PostgreSQL
   ├─ Generate response
   └─ Return to nginx

5. nginx processes response
   ├─ Add security headers
   ├─ Log request (with timing)
   └─ Return to client

6. Client receives response
   └─> Connection established
```

## Security Architecture

### Production Security Layers

```
┌─────────────────────────────────────────┐
│  Layer 7: Application Security         │
│  • Security headers                     │
│  • CSRF protection (Headscale)          │
│  • Input validation                     │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│  Layer 6: Access Control                │
│  • Rate limiting (per IP)               │
│  • Connection limits                    │
│  • IP whitelisting (optional)           │
│  • Basic auth (optional)                │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│  Layer 5: nginx Security                │
│  • Request size limits                  │
│  • Timeout protection                   │
│  • Error handling                       │
│  • Server tokens hidden                 │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│  Layer 4: SSL/TLS Security              │
│  • TLS 1.2 / 1.3 only                   │
│  • Strong cipher suites                 │
│  • OCSP stapling                        │
│  • HSTS with preload                    │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│  Layer 3: Network Security              │
│  • Firewall (ports 80, 443 only)        │
│  • Docker network isolation             │
│  • Internal-only database               │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│  Layer 2: Container Security            │
│  • Read-only config volumes             │
│  • Non-root processes                   │
│  • Resource limits                      │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│  Layer 1: Host Security                 │
│  • OS hardening                         │
│  • Regular updates                      │
│  • Minimal services                     │
└─────────────────────────────────────────┘
```

## Performance Architecture

### Connection Handling

```
Client Connections
     │
     ├─ Worker Process 1 (handles up to 2048/4096 connections)
     ├─ Worker Process 2 (handles up to 2048/4096 connections)
     ├─ Worker Process 3 (handles up to 2048/4096 connections)
     └─ Worker Process N (handles up to 2048/4096 connections)
          │
          └─> Upstream Keepalive Pool
               ├─ 32 persistent connections to headscale
               └─ 16 persistent connections to headplane
```

### Buffer Management

```
Request Processing
     │
     ├─ Client Request
     │    └─> client_body_buffer: 128k
     │
     ├─ Proxy Buffering
     │    ├─> proxy_buffer_size: 8k (headers)
     │    └─> proxy_buffers: 16 x 8k (body)
     │         └─> Total: 128k buffering capacity
     │
     └─ Response
          └─> Sent to client with tcp_nopush optimization
```

### Caching Strategy (Future)

```
Request Path
     │
     ├─ Static assets
     │    └─> Browser cache (Cache-Control headers)
     │
     ├─ API responses
     │    └─> No caching (dynamic content)
     │
     └─ Health/Metrics
          └─> No caching (real-time data)
```

## Monitoring Architecture

### Logging Flow

```
Request Lifecycle
     │
     ├─> Access Log
     │    ├─ Client IP
     │    ├─ Request details
     │    ├─ Status code
     │    ├─ Response size
     │    └─ Timing metrics
     │         ├─ request_time
     │         ├─ upstream_connect_time
     │         ├─ upstream_header_time
     │         └─ upstream_response_time
     │
     └─> Error Log (if errors)
          ├─ Error level
          ├─ Error message
          └─ Context
```

### Metrics Exposure

```
Prometheus Monitoring
     │
     ├─> nginx metrics
     │    └─ /metrics endpoint
     │
     ├─> Headscale metrics
     │    └─ Proxied through nginx
     │
     └─> Container metrics
          └─ Docker stats API
```

## Deployment Architecture

### Development Environment

```
Developer Machine
     │
     ├─ docker-compose.yml
     │    └─> nginx.conf
     │         └─> HTTP on port 8000
     │
     └─ Access
          ├─> http://localhost:8000 (Headscale)
          ├─> http://localhost:8000/admin (Headplane)
          └─> http://localhost:8000/health
```

### Production Environment

```
Production Server
     │
     ├─ docker-compose.yml + docker-compose.prod.yml
     │    └─> nginx.prod.conf
     │         ├─> HTTP on port 80 (redirect)
     │         └─> HTTPS on port 443
     │
     ├─ Certbot (automated certificate renewal)
     │    └─> Let's Encrypt certificates
     │
     └─ Access
          ├─> https://yourdomain.com (Headscale)
          ├─> https://yourdomain.com/admin (Headplane)
          └─> https://yourdomain.com/health
```

## Network Topology

### Docker Network

```
headscale-network (bridge)
     │
     ├─ nginx (8080 internal)
     │    ├─> 8000:8080 (dev)
     │    └─> 80:80, 443:443 (prod)
     │
     ├─ headscale (8080 internal)
     │    └─> 127.0.0.1:8080:8080 (metrics only)
     │
     ├─ headplane (3000 internal)
     │    └─> 3001:3000
     │
     └─ postgres (5432 internal)
          └─> No external exposure
```

### Port Mapping

```
External Access
     │
Development
     ├─ 8000 → nginx:8080 → backends
     ├─ 3001 → headplane:3000 (direct)
     └─ 127.0.0.1:8080 → headscale:8080 (metrics)

Production
     ├─ 80 → nginx:80 → redirect to 443
     ├─ 443 → nginx:443 → backends
     ├─ 3001 → headplane:3000 (direct, could be removed)
     └─ 127.0.0.1:9090 → headscale:9090 (metrics)
```

## Configuration Files Relationship

```
Project Root
├── nginx.conf (dev config)
│    ├─ Used by: docker-compose.yml
│    └─ Features: HTTP only, simplified
│
├── nginx.prod.conf (prod config)
│    ├─ Used by: docker-compose.prod.yml
│    └─ Features: HTTPS, rate limiting, security
│
├── docker-compose.yml (base)
│    └─ nginx service definition
│
├── docker-compose.prod.yml (production override)
│    ├─ Extends: docker-compose.yml
│    ├─ Overrides: nginx volumes (prod config)
│    ├─ Adds: certbot service
│    └─ Changes: port mappings (80, 443)
│
└── nginx.sh (helper script)
     └─ Operations: test, reload, logs, health, etc.
```

## Integration Points

### Headscale Integration

```
nginx ←→ Headscale
     │
     ├─ Protocol: HTTP/1.1
     ├─ WebSocket: Supported (Upgrade headers)
     ├─ Buffering: Enabled
     ├─ Timeouts: 90s
     ├─ Keepalive: 32 connections
     └─ Health: /health endpoint (5s timeout)
```

### Headplane Integration

```
nginx ←→ Headplane
     │
     ├─ Protocol: HTTP/1.1
     ├─ WebSocket: Supported (UI updates)
     ├─ Buffering: Disabled (interactive)
     ├─ Path: /admin
     ├─ Keepalive: 16 connections
     └─ Optional: Basic auth
```

### PostgreSQL (Indirect)

```
nginx → headscale → PostgreSQL
                │
                ├─ Protocol: PostgreSQL wire protocol
                ├─ Port: 5432 (internal only)
                ├─ Connection pooling: In headscale
                └─ No direct nginx involvement
```

## Scalability Considerations

### Horizontal Scaling (Future)

```
Load Balancer (HAProxy/nginx)
     │
     ├─> nginx instance 1
     ├─> nginx instance 2
     └─> nginx instance 3
          │
          └─> Headscale instances
               └─> Shared PostgreSQL (with replication)
```

### Vertical Scaling

```
Increase Resources
     │
     ├─ CPU: More worker processes
     │    └─> worker_processes auto
     │
     ├─ RAM: Larger buffers
     │    ├─> More proxy_buffers
     │    └─> Larger cache (if enabled)
     │
     └─ Network: Higher connections
          └─> worker_connections 8192+
```

## Summary

The nginx architecture provides:

1. **Flexibility**: Dev/prod configurations
2. **Security**: Multi-layer defense
3. **Performance**: Optimized buffering and connections
4. **Reliability**: Health checks and error handling
5. **Observability**: Comprehensive logging
6. **Scalability**: Ready for growth

All components work together to provide a robust, production-ready reverse proxy for the Headscale VPN control plane.
