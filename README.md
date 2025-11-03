# Headscale + Tailscale Docker Compose Stack

A production-ready Docker Compose setup for running your own Headscale server - an open-source, self-hosted implementation of the Tailscale control server.

## Features

- **Headscale** - Latest version with PostgreSQL backend
- **Caddy** - Automatic HTTPS with Let's Encrypt
- **PostgreSQL** - Persistent database storage
- **Health Checks** - Automatic service monitoring
- **Security** - TLS encryption and security headers

## Prerequisites

- Docker and Docker Compose installed
- A domain name pointing to your server
- Ports 80, 443 (TCP/UDP) open in firewall

## Quick Start

### 1. Configuration

Copy the environment template and configure your domain:

```bash
cp .env.example .env
```

Edit `.env` and set:
- `HEADSCALE_DOMAIN` - Your domain (e.g., `headscale.yourdomain.com`)
- `POSTGRES_PASSWORD` - A strong password for PostgreSQL

Edit `config/config.yaml` and update:
- `server_url` - Must match your domain (e.g., `https://headscale.yourdomain.com:443`)
- `database.postgres.password` - Must match your `.env` password

### 2. DNS Configuration

Point your domain to your server's IP address:

```
A record: headscale.yourdomain.com -> YOUR_SERVER_IP
```

### 3. Start the Stack

```bash
docker compose up -d
```

Check logs:
```bash
docker compose logs -f
```

### 4. Create Your First User

```bash
docker exec headscale headscale users create default
```

### 5. Generate a Pre-Auth Key

Create a reusable pre-auth key for connecting devices:

```bash
docker exec headscale headscale preauthkeys create --user default --reusable --expiration 24h
```

Save this key - you'll need it to connect devices.

## Connecting Devices

### Linux/MacOS

Install Tailscale:
```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

Connect using your Headscale server:
```bash
sudo tailscale up --login-server https://headscale.yourdomain.com --authkey YOUR_PREAUTH_KEY
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

## Backup and Restore

### Backup

```bash
# Backup PostgreSQL database
docker exec headscale-db pg_dump -U headscale headscale > backup-$(date +%Y%m%d).sql

# Backup configuration
tar -czf config-backup-$(date +%Y%m%d).tar.gz config/ data/
```

### Restore

```bash
# Restore database
cat backup-YYYYMMDD.sql | docker exec -i headscale-db psql -U headscale

# Restore configuration
tar -xzf config-backup-YYYYMMDD.tar.gz
```

## Troubleshooting

### Check Service Status

```bash
docker compose ps
docker compose logs -f headscale
```

### Certificate Issues

If Let's Encrypt fails, check:
1. Domain DNS is pointing correctly
2. Ports 80 and 443 are open
3. Check Caddy logs: `docker compose logs caddy`

### Connection Issues

Test Headscale health:
```bash
curl https://headscale.yourdomain.com/health
```

Check if nodes can reach server:
```bash
sudo tailscale status
sudo tailscale netcheck
```

### Database Connection Issues

Check PostgreSQL logs:
```bash
docker compose logs postgres
```

Verify connection:
```bash
docker exec -it headscale-db psql -U headscale -d headscale -c "SELECT 1;"
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

## Architecture

```
Internet
   |
   v
Caddy (HTTPS/TLS)
   |
   v
Headscale Server
   |
   v
PostgreSQL Database
```

## Files Structure

```
.
├── docker-compose.yml      # Main compose file
├── .env                    # Environment variables
├── Caddyfile              # Caddy configuration
├── config/
│   └── config.yaml        # Headscale configuration
├── data/                  # Headscale data directory
├── caddy-data/           # Caddy data (certificates)
└── caddy-config/         # Caddy config cache
```

## Resources

- [Headscale Documentation](https://headscale.net/)
- [Tailscale Documentation](https://tailscale.com/kb/)
- [Caddy Documentation](https://caddyserver.com/docs/)

## License

This stack configuration is provided as-is under MIT license.
