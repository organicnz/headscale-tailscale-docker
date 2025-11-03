# Quick Start Guide

## 1️⃣ Generate Pre-Auth Key

First, generate a pre-auth key from your Headscale server:

```bash
docker exec headscale headscale preauthkeys create --user 1 --reusable --expiration 24h
```

Copy the key that is generated (it will be a long string of characters)

## 2️⃣ Choose Your Platform

### 🐧 Linux
```bash
cd linux-systemd
sudo bash setup.sh
```

### 🍎 macOS
```bash
sudo /Applications/Tailscale.app/Contents/MacOS/Tailscale up \
  --login-server=http://localhost:8000 \
  --authkey=YOUR_KEY \
  --accept-routes
```

### 🪟 Windows (PowerShell as Admin)
```powershell
tailscale up --login-server=http://localhost:8000 --authkey=YOUR_KEY --accept-routes
```

### 🐳 Docker
```bash
cd docker-compose
# Edit docker-compose.tailscale.yml with your key
docker compose -f docker-compose.tailscale.yml up -d
```

## 3️⃣ Verify Connection

```bash
tailscale status
tailscale ip
```

## 📖 Full Documentation

See [README.md](README.md) for complete documentation, configuration options, and troubleshooting.
