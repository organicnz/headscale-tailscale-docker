# Best Practices for Headscale + Tailscale

This guide consolidates best practices from production deployments and the community.

## Version Management

### ❌ Don't Use `latest` Tag
```yaml
image: headscale/headscale:latest  # BAD
```

### ✅ Use Specific Versions
```yaml
image: headscale/headscale:v0.27.0  # GOOD
```

**Why:** Headscale has breaking changes between major versions. Pin to specific versions to avoid unexpected issues during automatic updates.

## Policy Management

### ❌ File-Based Policies (Limited)
```yaml
policy:
  mode: file
  path: /etc/headscale/acl.json
```

### ✅ Database-Backed Policies (Headplane Compatible)
```yaml
policy:
  mode: database
  path: /etc/headscale/policy.json
```

**Why:** Database mode enables GUI management through Headplane and provides better auditing.

## Access Control Organization

### Tag-Based Architecture

Organize nodes by function, not by individual device:

```json
{
  "tagOwners": {
    "tag:personal": ["group:admins"],
    "tag:servers": ["group:admins"],
    "tag:services": ["group:admins"],
    "tag:private": ["group:admins"],
    "tag:guests": ["group:admins"]
  }
}
```

### Create Visual Network Diagrams

Before implementing ACLs, draw your desired connectivity:

```
[Personal Devices] → [Private Services] ✓
[Personal Devices] → [Servers:SSH] ✓
[Guests] → [Private Services] ✗
[Guests] → [Public Services] ✓
```

Then translate to ACL rules.

## Network Isolation

### DNS Privacy

**Problem:** Users with DNS access can see all your internal hostnames.

**Solution:** Guests accessing shared services should use IP-based access, not full DNS:

```json
{
  "acls": [
    {
      "action": "accept",
      "src": ["tag:guests"],
      "dst": ["10.0.0.50:80", "10.0.0.50:443"],
      "comment": "Direct IP access, not DNS"
    }
  ]
}
```

### Principle of Least Privilege

Grant minimum required access:

```json
{
  "acls": [
    {
      "action": "accept",
      "src": ["tag:guests"],
      "dst": ["tag:services:80,443"],
      "comment": "Only HTTP/HTTPS to public services"
    }
  ]
}
```

## Reverse Proxy Security

### Restrict Admin Paths

```nginx
# Restrict admin paths to local IPs only
location ~ ^/(admin|api/v1/admin) {
    allow 192.168.1.0/24;
    allow 100.64.0.0/24;
    deny all;

    proxy_pass http://headscale_backend;

    handle @local {
        reverse_proxy headscale:8080
    }

    handle {
        respond "Access Denied" 403
    }
}
```

### Block Search Engine Indexing

```nginx
location = /robots.txt {
    add_header Content-Type text/plain;
    return 200 "User-agent: *\nDisallow: /\n";
}
```

## DNS Configuration

### Local DNS Resolution

Create DNS records in your local DNS server (Pi-Hole, AdGuard, etc.) pointing your domain to the reverse proxy's **internal IP**:

```
# In Pi-Hole/AdGuard
hs.yourdomain.com → 192.168.1.100
```

**Why:** Prevents routing through external IP when accessing from internal network.

### Verify DNS Propagation

```bash
dig hs.yourdomain.com
# Should return internal IP when queried internally
```

## Exit Nodes & Subnet Routing

### Multiple Exit Nodes

Deploy exit nodes in different locations:

- **Home Network:** For accessing home resources while traveling
- **Cloud VPS:** For region-specific content
- **Office Network:** For accessing work resources remotely

### Auto-Approve Routes

```json
{
  "autoApprovers": {
    "routes": {
      "192.168.0.0/16": ["tag:servers"],
      "10.0.0.0/8": ["tag:servers"]
    },
    "exitNode": ["tag:servers"]
  }
}
```

### Enable IP Forwarding

On subnet routers and exit nodes:

```bash
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

## Headplane GUI Setup

### Generate Long-Lived API Key

```bash
docker exec headscale headscale apikeys create --expiration 999d
```

### Configuration Best Practices

```yaml
headscale:
  url: http://headscale:8080  # Use internal hostname, not external domain
  api_key: "your-api-key-here"

server:
  cookie_secure: true  # Only if behind HTTPS reverse proxy
```

## Operational Security

### Backup Strategy

```bash
# Daily backup script
docker exec headscale-db pg_dump -U headscale headscale > backup-$(date +%Y%m%d).sql
tar -czf backup-$(date +%Y%m%d).tar.gz config/ data/
```

### Isolate Headscale

Consider running Headscale in a dedicated VM for:
- Easier backups
- Better security isolation
- Simplified disaster recovery

### Monitor Update Announcements

Join Headscale channels to stay informed about:
- Security patches
- Breaking changes
- New features

## Pre-Auth Keys

### Short-Lived Keys for Security

```bash
# Reusable but short-lived for onboarding
docker exec headscale headscale preauthkeys create \
  --user 1 \
  --reusable \
  --expiration 1h
```

### Tag Assignment

```bash
# Assign tags during key creation
docker exec headscale headscale preauthkeys create \
  --user 1 \
  --tags tag:personal \
  --expiration 24h
```

## Common Pitfalls

### ❌ Exposing Admin Interfaces Publicly

Never expose admin paths without IP restrictions.

### ❌ Using Same DNS for All Users

Separate DNS views prevent hostname enumeration by guests.

### ❌ Auto-Updating Production

Pin versions and test updates in staging first.

### ❌ Single Exit Node

Deploy multiple exit nodes for redundancy.

### ❌ Overly Permissive ACLs

Start restrictive, add access as needed.

## Future Enhancements

### OIDC Authentication

Integrate with Authentik or Pocket-ID:

```yaml
oidc:
  issuer: https://auth.yourdomain.com
  client_id: headscale
  client_secret: secret
```

### Custom DERP Servers

Reduce dependency on Tailscale's infrastructure:

```yaml
derp:
  server:
    enabled: true
    region_id: 999
    region_code: "home"
    region_name: "Home DERP"
    stun_listen_addr: "0.0.0.0:3478"
```

## Monitoring & Observability

### Prometheus Metrics

Headscale exposes metrics on port 9090:

```bash
curl http://localhost:9090/metrics
```

### Health Checks

```bash
curl http://localhost:8000/health
# Returns: {"status":"pass"}
```

### Log Analysis

```bash
docker compose logs -f headscale | grep -i error
```

## Performance Optimization

### Database Tuning

For PostgreSQL:

```yaml
postgres:
  max_open_conns: 10
  max_idle_conns: 5
  conn_max_idle_time_secs: 3600
```

### Connection Optimization

```yaml
randomize_client_port: false  # Improves NAT traversal
```

## Documentation Maintenance

Keep these updated:
- Network topology diagrams
- ACL policy documentation
- Disaster recovery procedures
- Contact information for node owners

## Security Audit Checklist

- [ ] ACLs follow least privilege principle
- [ ] Admin paths restricted by IP
- [ ] robots.txt blocks indexing
- [ ] Pre-auth keys are short-lived
- [ ] Exit nodes have IP forwarding enabled
- [ ] Routes are explicitly approved
- [ ] DNS doesn't leak internal hostnames to guests
- [ ] Regular backups are automated
- [ ] Monitoring is configured
- [ ] Version pinning is enforced
- [ ] API keys have reasonable expiration
- [ ] Logs are reviewed regularly

## Resources

- [Headscale Documentation](https://headscale.net/)
- [Tailscale Documentation](https://tailscale.com/kb/)
- [Headplane GitHub](https://github.com/tale/headplane)
- [ACL Policy Examples](https://headscale.net/ref/acls/)

---

**Remember:** Security is a process, not a destination. Regularly review and update your configuration as your needs evolve.
