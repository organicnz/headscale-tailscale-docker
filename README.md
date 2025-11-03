# Headscale + Tailscale Docker Compose Stack

A production-ready Docker Compose setup for running your own Headscale server - an open-source, self-hosted implementation of the Tailscale control server.

## ✅ Current Status

All services are **running and operational**:

- ✅ **Headscale v0.27.0** - Running with SQLite database
- ✅ **Headplane Web GUI** - Accessible at http://localhost:3001/admin/
- ✅ **Caddy Reverse Proxy** - HTTP proxy on port 8000
- ✅ **Health Check** - Passing at http://localhost:8000/health
- ✅ **API Key** - Generated and configured
- ✅ **ACL Policies** - Tag-based security configured
- ✅ **Helper Scripts** - Ready to use

**Ready to connect devices!**

---

## 🎨 NEW: GUI-Only Quick Start!

**Don't want to use command line?**

👉 **See [QUICK_START_GUI.md](QUICK_START_GUI.md)** for step-by-step GUI guide:

1. Open Headplane web interface → Generate pre-auth key
2. Download Tailscale app on your device
3. Configure custom server in the app
4. Connect with the key
5. Done! No terminal needed! 🎉

**Perfect for**: Windows users, Mac users, mobile devices, anyone who prefers graphical interfaces

## ✨ Features

- **Headscale v0.27.0** - Pinned version with SQLite database
- **Headplane Web GUI** - Modern web interface for management
- **Caddy Reverse Proxy** - HTTP/HTTPS support with automatic TLS
- **Best Practices** - Security-focused configuration with ACL policies
- **Tag-Based ACLs** - Organized network access control
- **Helper Scripts** - Easy CLI management

## 📋 Prerequisites

- Docker and Docker Compose installed
- For local testing: Nothing else needed!
- For production: A domain name and open ports 80/443
- **Recommended**: [Lefthook](https://github.com/evilmartians/lefthook) for Git hooks (prevents committing secrets)
  ```bash
  # macOS
  brew install lefthook

  # After clone
  lefthook install
  ```
  See [LEFTHOOK.md](LEFTHOOK.md) for details

## 🌐 Access Points

Once running, you can access:

- **Headscale API**: http://localhost:8000
- **🎨 Headplane Web GUI**: http://localhost:3001/admin/ ⭐ **Use this to manage everything!**
- **Health Check**: http://localhost:8000/health
- **Metrics**: http://localhost:8080 (direct to container)

**Generate API Key**: `docker exec headscale headscale apikeys create`

### 🎨 Want to Use GUIs Instead of Command Line?

**See [GUI_SETUP.md](GUI_SETUP.md)** for complete guide on:
- Using Headplane web interface for server management
- Using Tailscale desktop apps (Windows, Mac, Linux)
- Using Tailscale mobile apps (iOS, Android)
- **No command-line needed!**

## 🚀 Quick Start (Local Development)

This setup is **ready to run locally** on `http://localhost:8000`

### 1. Start the Stack

```bash
docker compose up -d
```

Check logs:
```bash
docker compose logs -f
```

Verify health:
```bash
curl http://localhost:8000/health
# Should return: {"status":"pass"}
```

### 2. Access Headplane Web GUI

Open your browser to:
```
http://localhost:3001/admin/
```

**Login with API Key:**

Generate an API key:
```bash
docker exec headscale headscale apikeys create --expiration 999d
```

Copy the key and paste it into the Headplane login page.

### 3. Create Your First User

```bash
docker exec headscale headscale users create myuser
```

Or use the helper script:
```bash
./headscale.sh users create myuser
```

### 4. Generate a Pre-Auth Key

Create a reusable pre-auth key for connecting devices:

```bash
docker exec headscale headscale preauthkeys create --user 1 --reusable --expiration 24h
```

Or with helper script:
```bash
./headscale.sh keys create myuser --reusable --expiration 24h
```

Save this key - you'll need it to connect devices.

## 🔗 Connecting Devices

### Quick Connection

**Generate a pre-auth key:**
```bash
docker exec headscale headscale preauthkeys create --user 1 --reusable --expiration 24h
```

**Connect any device:**
```bash
# Linux/macOS
sudo tailscale up --login-server http://localhost:8000 --authkey YOUR_KEY --accept-routes

# Windows (PowerShell as Admin)
tailscale up --login-server http://localhost:8000 --authkey YOUR_KEY --accept-routes
```

### 📦 Using Configuration Files

For easier setup, use the pre-made configuration files in `tailscale-configs/`:

- **Linux (systemd)**: Automated setup script
- **macOS**: LaunchDaemon for auto-start
- **Windows**: PowerShell script
- **Docker**: Docker Compose sidecar pattern

**See [tailscale-configs/README.md](tailscale-configs/README.md) for complete documentation.**

Quick start:
```bash
cd tailscale-configs
# Choose your platform and follow the README
```

### Windows

1. Download Tailscale from https://tailscale.com/download
2. Install and open Tailscale
3. Open CMD as Administrator and run:
```cmd
tailscale up --login-server https://headscale.yourdomain.com --authkey YOUR_PREAUTH_KEY
```

### Docker Container

Add this to any Docker Compose service:

```yaml
services:
  myapp:
    image: myapp:latest
    network_mode: "service:tailscale"
    depends_on:
      - tailscale

  tailscale:
    image: tailscale/tailscale:latest
    hostname: myapp-container
    environment:
      - TS_AUTHKEY=YOUR_PREAUTH_KEY
      - TS_STATE_DIR=/var/lib/tailscale
      - TS_LOGIN_SERVER=https://headscale.yourdomain.com
    volumes:
      - tailscale-data:/var/lib/tailscale
      - /dev/net/tun:/dev/net/tun
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    restart: unless-stopped

volumes:
  tailscale-data:
```

## Management Commands

### User Management

List all users:
```bash
docker exec headscale headscale users list
```

Create a new user:
```bash
docker exec headscale headscale users create USERNAME
```

Delete a user:
```bash
docker exec headscale headscale users destroy USERNAME
```

### Node Management

List all nodes:
```bash
docker exec headscale headscale nodes list
```

Register a node (if using manual registration):
```bash
docker exec headscale headscale nodes register --user USERNAME --key NODEKEY
```

Delete a node:
```bash
docker exec headscale headscale nodes delete --identifier NODE_ID
```

### Pre-Auth Keys

List all pre-auth keys:
```bash
docker exec headscale headscale preauthkeys list --user USERNAME
```

Create a reusable key that expires in 1 week:
```bash
docker exec headscale headscale preauthkeys create --user USERNAME --reusable --expiration 168h
```

Create a single-use ephemeral key:
```bash
docker exec headscale headscale preauthkeys create --user USERNAME --ephemeral
```

Expire a pre-auth key:
```bash
docker exec headscale headscale preauthkeys expire --user USERNAME --key KEY
```

### Routes

List all routes:
```bash
docker exec headscale headscale routes list
```

Enable a route:
```bash
docker exec headscale headscale routes enable --route-id ROUTE_ID
```

Advertise subnet routes (on the client):
```bash
sudo tailscale up --advertise-routes=10.0.0.0/24 --login-server https://headscale.yourdomain.com
```

## Advanced Configuration

### ACL Policies

Create an ACL policy file to control traffic between nodes:

```bash
nano config/acl.json
```

Example ACL:
```json
{
  "acls": [
    {
      "action": "accept",
      "src": ["*"],
      "dst": ["*:*"]
    }
  ]
}
```

Update `config/config.yaml`:
```yaml
acl_policy_path: /etc/headscale/acl.json
```

Restart Headscale:
```bash
docker compose restart headscale
```

### Custom DERP Servers

To use your own DERP server, edit `config/config.yaml`:

```yaml
derp:
  server:
    enabled: true
    region_id: 999
    region_code: "home"
    region_name: "Home DERP"
    stun_listen_addr: "0.0.0.0:3478"

  urls: []
```

### MagicDNS

MagicDNS is enabled by default. Configure custom DNS in `config/config.yaml`:

```yaml
dns:
  magic_dns: true
  base_domain: yourdomain.net
  nameservers:
    global:
      - 1.1.1.1
      - 8.8.8.8
```

## 💾 Backup and Restore

### Backup (SQLite)

```bash
# Stop Headscale first to ensure consistent backup
docker compose stop headscale

# Backup everything (database + configuration)
tar -czf headscale-backup-$(date +%Y%m%d).tar.gz config/ data/ headplane/

# Restart Headscale
docker compose start headscale
```

### Restore

```bash
# Stop services
docker compose down

# Restore backup
tar -xzf headscale-backup-YYYYMMDD.tar.gz

# Restart services
docker compose up -d
```

**Note**: For production with PostgreSQL, see BEST_PRACTICES.md for database-specific backup procedures.

## 🔍 Troubleshooting

### Check Service Status

```bash
docker compose ps
docker compose logs -f headscale
docker compose logs -f headplane
```

### Headplane 404 Error

If you get a 404, make sure you're accessing the correct path:
```
✅ http://localhost:3001/admin/  (with trailing slash)
❌ http://localhost:3001          (wrong - will 404)
```

### Connection Issues

Test Headscale health:
```bash
curl http://localhost:8000/health
# Should return: {"status":"pass"}
```

Check if nodes can reach server:
```bash
sudo tailscale status
sudo tailscale netcheck
```

### Headplane Won't Load

1. Check if API key is configured in `headplane/config.yaml`
2. Verify Headscale is running: `curl http://localhost:8000/health`
3. Check Headplane logs: `docker logs headplane --tail 50`
4. Ensure cookie_secret is exactly 32 characters

### Database Issues

Check SQLite database:
```bash
# Verify database file exists
ls -lh data/db.sqlite

# Check database size
du -h data/db.sqlite

# View tables (from within container)
docker exec headscale sqlite3 /var/lib/headscale/db.sqlite ".tables"
```

## Maintenance

### Update Services

```bash
docker compose pull
docker compose up -d
```

### View Metrics

Headscale exposes Prometheus metrics on port 8080 (localhost only):
```bash
curl http://localhost:8080/metrics
```

### Cleanup Old Data

Remove expired pre-auth keys and offline nodes:
```bash
docker exec headscale headscale nodes expire --all-offline
```

## Security Recommendations

1. **Use strong passwords** - Change the default PostgreSQL password
2. **Limit pre-auth key lifetime** - Use short expiration times
3. **Enable ACLs** - Implement least-privilege access
4. **Regular updates** - Keep Docker images updated
5. **Monitor logs** - Check logs regularly for suspicious activity
6. **Backup regularly** - Automate database backups
7. **Use Git hooks** - Install Lefthook to prevent committing secrets (see [LEFTHOOK.md](LEFTHOOK.md))

## 🏗️ Architecture

```
Internet
   |
   v
Caddy Reverse Proxy (HTTP on :8000)
   |
   v
Headscale Server (with SQLite)
   |
   +-- Headplane Web GUI (:3001/admin/)
```

## 📁 Files Structure

```
.
├── docker-compose.yml         # Main compose file
├── .env                       # Environment variables
├── Caddyfile                  # Caddy configuration
├── headscale.sh              # Helper script for management
├── config/
│   ├── config.yaml           # Headscale configuration (SQLite)
│   └── policy.json           # ACL policies with tags
├── headplane/
│   └── config.yaml           # Headplane web GUI config
├── data/                     # Headscale data (SQLite DB here)
├── caddy-data/              # Caddy data (certificates)
├── caddy-config/            # Caddy config cache
├── BEST_PRACTICES.md        # Production best practices guide
└── NETWORKING.md            # Advanced networking guide
```

## 🔧 Helper Script Usage

The included `headscale.sh` script simplifies management:

```bash
# User management
./headscale.sh users list
./headscale.sh users create username

# Pre-auth keys
./headscale.sh keys create username --reusable --expiration 24h
./headscale.sh keys list username

# Node management
./headscale.sh nodes list
./headscale.sh nodes delete <node-id>

# Routes
./headscale.sh routes list
./headscale.sh routes enable <route-id>

# View status
./headscale.sh status
./headscale.sh health
./headscale.sh logs 100
```

## Resources

- [Headscale Documentation](https://headscale.net/)
- [Tailscale Documentation](https://tailscale.com/kb/)
- [Caddy Documentation](https://caddyserver.com/docs/)

## License

This stack configuration is provided as-is under MIT license.
