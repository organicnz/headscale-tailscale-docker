# Tailscale Client Configuration Files

This directory contains configuration files and setup scripts for connecting Tailscale clients to your Headscale server across different platforms.

## 📁 Directory Structure

```
tailscale-configs/
├── linux-systemd/          # Linux with systemd
│   ├── setup.sh           # Automated setup script
│   └── tailscaled.env     # Environment configuration
├── macos/                 # macOS LaunchDaemon
│   └── com.tailscale.headscale.plist
├── windows/               # Windows PowerShell
│   └── tailscale-headscale.ps1
└── docker-compose/        # Docker containers
    └── docker-compose.tailscale.yml
```

## 🚀 Quick Start

### Prerequisites

Before connecting any client, you need:

1. **A pre-auth key** from your Headscale server:
   ```bash
   docker exec headscale headscale preauthkeys create --user 1 --reusable --expiration 24h
   ```

2. **Your Headscale server URL**:
   - Local: `http://localhost:8000`
   - Production: `http://YOUR_SERVER_IP:8000` or `https://headscale.yourdomain.com`

## 🐧 Linux (systemd)

### Option 1: Automated Setup (Recommended)

```bash
cd linux-systemd
sudo bash setup.sh
```

The script will:
- Install Tailscale if not present
- Ask for your server URL and pre-auth key
- Configure environment variables
- Connect to your Headscale server

### Option 2: Manual Configuration

1. **Copy the environment file:**
   ```bash
   sudo cp tailscaled.env /etc/default/tailscaled
   ```

2. **Edit the configuration:**
   ```bash
   sudo nano /etc/default/tailscaled
   ```

   Update:
   - `TS_LOGIN_SERVER` - Your Headscale URL
   - `TS_AUTHKEY` - Your pre-auth key

3. **Restart Tailscale:**
   ```bash
   sudo systemctl restart tailscaled
   ```

4. **Connect:**
   ```bash
   sudo tailscale up --login-server=http://localhost:8000 --authkey=YOUR_KEY
   ```

## 🍎 macOS

### Option 1: LaunchDaemon (Auto-start on boot)

1. **Edit the plist file:**
   ```bash
   nano macos/com.tailscale.headscale.plist
   ```

   Update:
   - Replace `YOUR_PREAUTH_KEY` with your actual key
   - Update login server URL if not using localhost

2. **Install the LaunchDaemon:**
   ```bash
   sudo cp macos/com.tailscale.headscale.plist /Library/LaunchDaemons/
   sudo chown root:wheel /Library/LaunchDaemons/com.tailscale.headscale.plist
   sudo chmod 644 /Library/LaunchDaemons/com.tailscale.headscale.plist
   ```

3. **Load and start:**
   ```bash
   sudo launchctl load /Library/LaunchDaemons/com.tailscale.headscale.plist
   sudo launchctl start com.tailscale.headscale
   ```

4. **Check logs:**
   ```bash
   tail -f /usr/local/var/log/tailscale-headscale.log
   ```

### Option 2: Manual Connection

```bash
sudo /Applications/Tailscale.app/Contents/MacOS/Tailscale up \
  --login-server=http://localhost:8000 \
  --authkey=YOUR_PREAUTH_KEY \
  --accept-routes
```

## 🪟 Windows

### Using PowerShell Script

1. **Open the script:**
   ```powershell
   notepad windows\tailscale-headscale.ps1
   ```

2. **Edit configuration at the top:**
   - `$LoginServer` - Your Headscale URL
   - `$AuthKey` - Your pre-auth key
   - Set optional parameters as needed

3. **Run as Administrator:**
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
   .\windows\tailscale-headscale.ps1
   ```

### Manual Command (CMD as Admin)

```cmd
tailscale up --login-server=http://YOUR_SERVER:8000 --authkey=YOUR_PREAUTH_KEY --accept-routes
```

## 🐳 Docker Containers

### Connect a Docker Service to Tailscale

1. **Copy the example:**
   ```bash
   cp docker-compose/docker-compose.tailscale.yml .
   ```

2. **Create `.env` file:**
   ```bash
   echo "TS_AUTHKEY=your-preauth-key-here" > .env
   ```

3. **Edit the compose file:**
   - Update `TS_LOGIN_SERVER` with your Headscale URL
   - Replace `myapp` service with your actual service
   - Adjust optional parameters

4. **Start the stack:**
   ```bash
   docker compose -f docker-compose.tailscale.yml up -d
   ```

5. **Verify connection:**
   ```bash
   docker exec myapp-tailscale tailscale status
   ```

### Example: Add Tailscale to Existing Container

```yaml
services:
  yourapp:
    image: yourapp:latest
    network_mode: "service:tailscale"
    depends_on:
      - tailscale

  tailscale:
    image: tailscale/tailscale:latest
    hostname: yourapp
    environment:
      - TS_LOGIN_SERVER=http://YOUR_HEADSCALE_HOST:8000
      - TS_AUTHKEY=${TS_AUTHKEY}
      - TS_STATE_DIR=/var/lib/tailscale
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

## 📝 Configuration Options

### Common Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `--login-server` | Your Headscale server URL | `http://localhost:8000` |
| `--authkey` | Pre-auth key from Headscale | `YOUR_PREAUTH_KEY` |
| `--accept-routes` | Accept subnet routes from other nodes | (flag, no value) |
| `--advertise-routes` | Share local networks | `192.168.1.0/24,10.0.0.0/24` |
| `--advertise-exit-node` | Become an exit node | (flag, no value) |
| `--hostname` | Custom hostname | `my-device` |
| `--advertise-tags` | Apply ACL tags | `tag:personal,tag:servers` |
| `--ssh` | Enable Tailscale SSH | (flag, no value) |

### Environment Variables (Linux/Docker)

| Variable | Description | Example |
|----------|-------------|---------|
| `TS_LOGIN_SERVER` | Headscale server URL | `http://localhost:8000` |
| `TS_AUTHKEY` | Pre-auth key | Your key |
| `TS_ACCEPT_ROUTES` | Accept routes | `true` |
| `TS_ROUTES` | Advertise routes | `192.168.1.0/24` |
| `TS_EXIT_NODE` | Advertise exit node | `true` |
| `TS_HOSTNAME` | Custom hostname | `my-device` |
| `TS_SSH` | Enable SSH | `true` |
| `TS_EXTRA_ARGS` | Additional arguments | `--advertise-tags=tag:servers` |

## 🔍 Verification

After connecting, verify your setup:

```bash
# Check connection status
tailscale status

# View your IP addresses
tailscale ip

# Test connectivity
tailscale netcheck

# View routes
tailscale status --peers

# Ping another node (replace with actual hostname or IP)
ping 100.64.0.2
```

## 🛠️ Troubleshooting

### Connection Issues

1. **Check Headscale is running:**
   ```bash
   curl http://localhost:8000/health
   ```

2. **Verify pre-auth key is valid:**
   ```bash
   docker exec headscale headscale preauthkeys list --user 1
   ```

3. **Check Tailscale logs:**
   - Linux: `journalctl -u tailscaled -f`
   - macOS: `/usr/local/var/log/tailscale-headscale.log`
   - Windows: Check Event Viewer
   - Docker: `docker logs myapp-tailscale`

### Reset Connection

If you need to reset and reconnect:

```bash
# Disconnect
sudo tailscale down

# Clear state (optional)
sudo rm -rf /var/lib/tailscale/*

# Reconnect
sudo tailscale up --login-server=http://localhost:8000 --authkey=NEW_KEY
```

## 🔐 Security Best Practices

1. **Use short-lived pre-auth keys** (24h max for testing)
2. **Use single-use keys** when possible (remove `--reusable`)
3. **Apply ACL tags** to organize and restrict access
4. **Limit subnet routes** to only necessary networks
5. **Don't commit `.env` files** with auth keys to git
6. **Rotate API keys** regularly
7. **Use ephemeral nodes** for temporary connections

## 📚 Additional Resources

- [Headscale Documentation](https://headscale.net/)
- [Tailscale Documentation](https://tailscale.com/kb/)
- [ACL Policy Examples](../config/policy.json)
- [Best Practices Guide](../BEST_PRACTICES.md)
- [Networking Guide](../NETWORKING.md)

## 💡 Examples

### Personal Laptop (Accept all routes)

```bash
sudo tailscale up \
  --login-server=http://localhost:8000 \
  --authkey=YOUR_KEY \
  --accept-routes \
  --hostname=my-laptop
```

### Server (Advertise local network)

```bash
sudo tailscale up \
  --login-server=http://localhost:8000 \
  --authkey=YOUR_KEY \
  --advertise-routes=192.168.1.0/24 \
  --advertise-tags=tag:servers
```

### Exit Node (Route internet traffic)

```bash
sudo tailscale up \
  --login-server=http://localhost:8000 \
  --authkey=YOUR_KEY \
  --advertise-exit-node \
  --advertise-tags=tag:servers
```

### Docker Service with Subnet Access

```yaml
services:
  myservice:
    image: myapp:latest
    network_mode: "service:tailscale"
    depends_on:
      - tailscale

  tailscale:
    image: tailscale/tailscale:latest
    hostname: myservice
    environment:
      - TS_LOGIN_SERVER=http://host.docker.internal:8000
      - TS_AUTHKEY=${TS_AUTHKEY}
      - TS_ACCEPT_ROUTES=true
      - TS_EXTRA_ARGS=--advertise-tags=tag:services
    volumes:
      - tailscale-data:/var/lib/tailscale
      - /dev/net/tun:/dev/net/tun
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    restart: unless-stopped
```

---

**Need help?** Check the main [README](../README.md) or consult the [troubleshooting guide](../README.md#-troubleshooting).
