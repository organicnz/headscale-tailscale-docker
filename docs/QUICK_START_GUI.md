# Quick Start - GUI Only (No Command Line!)

## 🎯 Goal
Connect your devices to your Headscale network using only graphical interfaces.

---

## Step 1: Open Headplane Web Interface

**URL**: http://localhost:3001/admin/

**Login**: Generate an API key first:
```bash
docker exec headscale headscale apikeys create
```
Then paste the generated key when prompted in Headplane

You'll see a dashboard with tabs: **Dashboard**, **Nodes**, **Users**, **Pre-Auth Keys**, **Routes**, **Settings**

---

## Step 2: Generate a Pre-Auth Key

In Headplane:

1. Click **Pre-Auth Keys** tab
2. Click **Create New Key** button
3. Configure:
   - User: Select `default`
   - Reusable: ✅ Check this
   - Expiration: `24h`
   - Tags: Leave empty (or add `tag:personal`)
4. Click **Create**
5. **IMPORTANT**: Copy the key immediately! (example: `abc123def.456ghi789jkl`)

---

## Step 3: Download Tailscale App

Choose your device:

### 💻 Windows
- Download: https://tailscale.com/download/windows
- Install the `.msi` file
- Find Tailscale in Start menu

### 🍎 Mac
- Download: https://tailscale.com/download/mac
- Install the `.dmg` file
- Find Tailscale in Applications

### 📱 iPhone
- App Store → Search "Tailscale" → Install

### 🤖 Android
- Google Play → Search "Tailscale" → Install

---

## Step 4: Connect Device (GUI Only!)

### Windows:
1. Open **Tailscale** from Start menu
2. Click **Settings** (gear icon)
3. Click **Use a Custom Login Server**
4. Type: `http://YOUR_COMPUTER_IP:8000`
   - Find your IP: Open Command Prompt → type `ipconfig` → look for IPv4 Address
   - Example: `http://192.168.1.100:8000`
5. Click **Connect**
6. Browser opens → **Paste your pre-auth key** from Step 2
7. Click **Authenticate**
8. Done! ✅ Tailscale icon in system tray turns blue

### Mac:
1. Open **Tailscale** from Applications
2. Click the icon in menu bar
3. Click **Preferences**
4. Go to **Advanced** tab
5. Under "Login Server", type: `http://YOUR_MAC_IP:8000`
6. Click **Save**
7. Click **Connect**
8. Browser opens → **Paste your pre-auth key**
9. Done! ✅ Icon turns blue

### iPhone/iPad:
1. Open **Tailscale** app
2. Tap **Settings** (gear icon bottom right)
3. Scroll down → Toggle ON **Use Alternative Coordination Server**
4. Type: `http://YOUR_COMPUTER_IP:8000`
   - ⚠️ Must be your computer's actual IP address, not `localhost`
   - Example: `http://192.168.1.100:8000`
5. Tap **Save**
6. Go back → Tap **Connect**
7. Browser opens → **Paste your pre-auth key**
8. Done! ✅

### Android:
1. Open **Tailscale** app
2. Tap **⋮** (three dots menu)
3. Tap **Settings**
4. Tap **Server URL**
5. Type: `http://YOUR_COMPUTER_IP:8000`
6. Tap **OK**
7. Go back → Tap **Connect**
8. Browser opens → **Paste your pre-auth key**
9. Done! ✅

---

## Step 5: Verify Connection

### On Your Device:
- **Windows/Mac**: Tailscale icon should be blue/green (connected)
- **Mobile**: Should show "Connected" status

### In Headplane:
1. Go back to http://localhost:3001/admin/
2. Click **Nodes** tab
3. Click **Refresh** or wait a few seconds
4. Your device should appear in the list! 🎉

You'll see:
- Device name (e.g., "iPhone", "Windows-PC")
- IP address (e.g., `100.64.0.2`)
- Status: **Online** (green dot)
- Last seen: Just now

---

## 🎉 You're Done!

Your device is now connected to your private Tailscale network!

### What Can You Do Now?

- **Ping other devices**: From your device, ping any IP shown in Headplane
- **Access services**: Any service running on your network is now accessible
- **Add more devices**: Repeat Steps 2-5 for each device

---

## 🔧 Managing Your Network (All in GUI)

### Add Another Device
1. Headplane → Pre-Auth Keys → Create New Key
2. On new device: Install Tailscale → Settings → Custom Server → Connect
3. Paste the new key

### Remove a Device
1. Headplane → Nodes tab
2. Find the device
3. Click **Delete** button
4. Confirm

### See Who's Connected
1. Headplane → Nodes tab
2. All devices listed with:
   - Name
   - IP address
   - Online/offline status
   - Last seen time

### Change Device Name
1. Headplane → Nodes tab
2. Click device name
3. Edit and save

### View Network Map
- Headplane → Dashboard
- See visual representation of your network

---

## 📱 Using Tailscale App Features

### Share Files (Taildrop)
- Windows/Mac: Tailscale menu → Taildrop
- Mobile: Tailscale app → Share files to other devices

### Use Exit Node
- Makes your internet traffic go through another device
- Windows/Mac: Tailscale menu → Exit Node → Select device
- Mobile: Tailscale app → Settings → Use Exit Node

### Accept Routes
- Access networks behind other devices
- Windows/Mac: Tailscale menu → Accept Routes
- Mobile: Enable in Settings

---

## ❓ Troubleshooting

### "Can't connect" Error

**Problem**: Device can't reach Headscale server

**Solution**:
1. Make sure you used your computer's **actual IP address**, not `localhost`
2. Find your IP:
   - Windows: `ipconfig`
   - Mac: System Preferences → Network
   - Show IP address (e.g., `192.168.1.100`)
3. Use that IP in the server URL: `http://192.168.1.100:8000`

### "Invalid key" Error

**Solution**:
1. Go to Headplane
2. Create a NEW pre-auth key
3. Make sure to check "Reusable"
4. Copy the whole key (no spaces)
5. Try again

### Device Not Showing in Headplane

**Solution**:
1. Wait 30 seconds
2. Click **Refresh** button in Headplane
3. Check device shows "Connected" in Tailscale app
4. If still not showing, disconnect and reconnect

---

## 📚 Full Documentation

- **Complete GUI Guide**: [GUI_SETUP.md](GUI_SETUP.md)
- **Main README**: [README.md](README.md)
- **Tailscale Configs**: [tailscale-configs/](tailscale-configs/)

---

## ✅ Checklist

- [ ] Opened Headplane at http://localhost:3001/admin/
- [ ] Logged in with API key
- [ ] Created pre-auth key
- [ ] Downloaded Tailscale app on device
- [ ] Configured custom login server
- [ ] Connected with pre-auth key
- [ ] Verified device appears in Headplane
- [ ] Tested connection (ping another device)

**Congratulations! You're using your own private VPN network!** 🎉
