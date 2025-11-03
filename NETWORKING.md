# Advanced Networking Guide

## Subnet Routing

Subnet routing allows you to access devices on a network that aren't running Tailscale, through a node that is running Tailscale.

### Setting Up a Subnet Router

On the node that will act as a subnet router:

```bash
# Enable IP forwarding (Linux)
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Advertise routes to your local networks
sudo tailscale up \
  --login-server http://localhost:8000 \
  --advertise-routes=192.168.1.0/24,192.168.3.0/24 \
  --authkey YOUR_PREAUTH_KEY
```

### Approving Subnet Routes

Routes must be explicitly approved before they become active:

```bash
# List all advertised routes
docker exec headscale headscale routes list

# Approve a specific route
docker exec headscale headscale routes enable --route-id <route-id>
```

### Auto-Approval with ACLs

In your `policy.json`, you can auto-approve routes for specific tags:

```json
{
  "autoApprovers": {
    "routes": {
      "192.168.0.0/16": ["tag:servers"],
      "10.0.0.0/8": ["tag:servers"]
    }
  }
}
```

## Exit Nodes

Exit nodes route all your internet traffic through a specific node, useful for:
- Accessing region-specific content
- Securing traffic on untrusted networks
- Routing through your home network while traveling

### Setting Up an Exit Node

```bash
# Enable IP forwarding
sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -w net.ipv6.conf.all.forwarding=1

# Advertise as exit node
sudo tailscale up \
  --login-server http://localhost:8000 \
  --advertise-exit-node \
  --authkey YOUR_PREAUTH_KEY

# Optional: Also advertise local subnets
sudo tailscale up \
  --login-server http://localhost:8000 \
  --advertise-exit-node \
  --advertise-routes=192.168.1.0/24 \
  --authkey YOUR_PREAUTH_KEY
```

### Using an Exit Node

On a client that wants to use the exit node:

```bash
# List available exit nodes
tailscale exit-node list

# Use a specific exit node
tailscale set --exit-node=<node-name>

# Stop using exit node
tailscale set --exit-node=
```

### Auto-Approval for Exit Nodes

In `policy.json`:

```json
{
  "autoApprovers": {
    "exitNode": ["tag:servers", "tag:personal"]
  }
}
```

## MagicDNS

MagicDNS provides DNS names for your Tailscale devices automatically.

### Using MagicDNS

Once enabled in the config, you can access devices by name:

```bash
# Instead of 100.64.0.1
ssh user@myserver

# Or with the full domain
ssh user@myserver.headscale.net
```

### Custom DNS Records

Add custom DNS records in `config.yaml`:

```yaml
dns:
  magic_dns: true
  base_domain: headscale.net

  nameservers:
    global:
      - 1.1.1.1
      - 1.0.0.1

  extra_records:
    - name: nas
      type: A
      value: 192.168.1.100

    - name: router
      type: A
      value: 192.168.1.1
```

## Split DNS

Route specific domains through your Tailscale network:

```yaml
dns:
  magic_dns: true
  base_domain: headscale.net

  nameservers:
    global:
      - 1.1.1.1
      - 1.0.0.1

    restricted_nameservers:
      "internal.company.com":
        - 192.168.1.53

      "home.local":
        - 192.168.1.1
```

## Access Control Lists (ACLs)

### Tag-Based Organization

Organize your nodes with tags for better access control:

```json
{
  "tagOwners": {
    "tag:personal": ["group:admins"],
    "tag:servers": ["group:admins"],
    "tag:services": ["group:admins"],
    "tag:guests": ["group:admins"]
  }
}
```

### Tagging Nodes

When creating pre-auth keys, assign tags:

```bash
docker exec headscale headscale preauthkeys create \
  --user 1 \
  --reusable \
  --expiration 24h \
  --tags tag:personal
```

Or tag existing nodes via Headplane GUI.

### Example ACL Rules

```json
{
  "acls": [
    {
      "action": "accept",
      "src": ["tag:personal"],
      "dst": [
        "tag:services:80,443",
        "tag:servers:22"
      ],
      "comment": "Personal devices can access web services and SSH to servers"
    },
    {
      "action": "accept",
      "src": ["tag:guests"],
      "dst": [
        "tag:services:80,443"
      ],
      "comment": "Guests can only access public web services"
    }
  ]
}
```

### SSH Access Rules

Control SSH access with specific rules:

```json
{
  "ssh": [
    {
      "action": "accept",
      "src": ["tag:personal", "group:admins"],
      "dst": ["tag:servers"],
      "users": ["root", "autogroup:nonroot"]
    }
  ]
}
```

## Network Isolation Best Practices

### 1. Separate Networks by Function

- **tag:personal** - Your personal devices
- **tag:servers** - Infrastructure servers
- **tag:services** - Public-facing services
- **tag:private** - Admin-only services
- **tag:guests** - Guest user devices

### 2. Principle of Least Privilege

Only grant access to what's needed:

```json
{
  "acls": [
    {
      "action": "accept",
      "src": ["tag:guests"],
      "dst": ["tag:services:80,443"],
      "comment": "Guests ONLY get web access to shared services"
    }
  ]
}
```

### 3. Prevent DNS Privacy Issues

Users accessing shared services should NOT have access to your DNS server, as this reveals all your internal hostnames. Use IP-based rules or create a separate DNS view for guests.

### 4. Use Exit Nodes Strategically

Deploy multiple exit nodes across your infrastructure:
- Home network exit node
- Cloud VPS exit node (for different regions)
- Office network exit node

## Monitoring and Management

### View Network Status

```bash
# List all nodes
docker exec headscale headscale nodes list

# List all routes
docker exec headscale headscale routes list

# Check node connectivity
tailscale status
tailscale netcheck
```

### Headplane Web Interface

Access Headplane at http://localhost:3000 to:
- View all nodes and their status
- Manage ACL policies
- Approve routes graphically
- Monitor connection quality
- View logs and metrics

### Generate API Key for Headplane

```bash
docker exec headscale headscale apikeys create --expiration 999d
```

Copy the generated key and update `headplane/config.yaml`.

## Troubleshooting

### Routes Not Working

1. Check IP forwarding is enabled:
   ```bash
   cat /proc/sys/net/ipv4/ip_forward  # Should be 1
   ```

2. Check firewall rules:
   ```bash
   # Allow forwarding on the subnet router
   sudo iptables -A FORWARD -i tailscale0 -j ACCEPT
   sudo iptables -A FORWARD -o tailscale0 -j ACCEPT
   ```

3. Verify routes are approved:
   ```bash
   docker exec headscale headscale routes list
   ```

### Exit Node Not Working

1. Verify the node is advertising:
   ```bash
   tailscale status
   # Look for "offers exit node" in the output
   ```

2. Check the exit node has internet access:
   ```bash
   ping 8.8.8.8
   ```

3. Verify NAT is configured on the exit node:
   ```bash
   sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
   ```

### DNS Issues

1. Check MagicDNS is enabled in config
2. Verify Tailscale is using the correct nameservers:
   ```bash
   tailscale status --json | jq .MagicDNSSuffix
   ```

3. Test DNS resolution:
   ```bash
   nslookup mynode.headscale.net
   ```

## Production Deployment Checklist

- [ ] Use specific version tags (not `latest`)
- [ ] Enable database-backed policy mode
- [ ] Configure comprehensive ACL policies
- [ ] Set up multiple exit nodes for redundancy
- [ ] Configure subnet routing for local networks
- [ ] Enable MagicDNS
- [ ] Block admin paths with IP restrictions
- [ ] Add robots.txt to prevent indexing
- [ ] Configure local DNS for your domain
- [ ] Set up regular backups
- [ ] Enable monitoring and metrics
- [ ] Document your network topology
- [ ] Test failover scenarios
