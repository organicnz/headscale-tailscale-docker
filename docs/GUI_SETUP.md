# GUI Setup Guide for Headscale + Tailscale

This guide shows you how to use **graphical interfaces** instead of command-line tools to manage your Headscale network.

## 🎨 Available GUIs

1. **Headplane** - Web-based Headscale management (Already running!)
2. **Tailscale Desktop Apps** - Native GUI for each platform
3. **Tailscale Mobile Apps** - iOS and Android apps

---

## 1️⃣ Headplane Web GUI (Server Management)

**Already running at: http://localhost:3001/admin/**

### What You Can Do

✅ View and manage all connected nodes
✅ Create and manage users
✅ Generate pre-auth keys
✅ Configure ACL policies
✅ Approve routes and exit nodes
✅ Monitor connection status
✅ View node details and IP addresses

### How to Access

1. Open browser: **http://localhost:3001/admin/**
2. Generate an API key: `docker exec headscale headscale apikeys create`
3. Login with the API key
4. Done! You now have full GUI access to manage your Headscale server

### Screenshots of What You'll See

The Headplane interface provides:
- **Dashboard** - Overview of all nodes and network status
- **Nodes Page** - List all connected devices, rename, delete, view details
- **Users Page** - Manage users and their devices
- **Routes Page** - Approve subnet routes and exit nodes
- **Settings** - Configure policies and server settings
- **Pre-auth Keys** - Generate keys for connecting new devices

---

## 2️⃣ Tailscale GUI Apps (Client Devices)

Instead of using command-line, you can use Tailscale's native GUI applications.

### Windows - Tailscale GUI

#### Installation

1. **Download**: https://tailscale.com/download/windows
2. **Install** the MSI package
3. **Launch** Tailscale from Start menu

#### Connecting to Headscale

**Option A: Using GUI (Easier)**

1. Open Tailscale app
2. Click **Settings** (gear icon)
3. Go to **Admin Console**
4. Click **Use a Custom Login Server**
5. Enter: `http://YOUR_SERVER_IP:8000` (or `localhost:8000` for local)
6. Click **Connect**
7. A browser window will open asking for a pre-auth key
8. Paste your pre-auth key and click **Authenticate**
9. Done!

**Option B: Using Registry (One-time setup)**

Create a file `headscale-setup.reg` with:

```reg
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Tailscale IPN]
"LoginURL"="http://localhost:8000"
"UnattendedMode"="always"
```

Double-click to import, then open Tailscale GUI and click "Connect"

#### Features

- System tray icon shows connection status
- Click icon to see menu:
  - View connected nodes
  - Copy your IP address
  - Enable/disable connection
  - Accept exit node
  - Preferences

### macOS - Tailscale Menu Bar App

#### Installation

1. **Download**: https://tailscale.com/download/mac
2. **Install** the DMG package
3. **Launch** from Applications

#### Connecting to Headscale

**Option A: Preferences (Easier)**

1. Open Tailscale from menu bar
2. Click **Preferences**
3. Go to **Advanced** tab
4. Under "Login Server", enter: `http://localhost:8000`
5. Click **Save**
6. Click **Connect** in the main menu
7. Browser opens - paste your pre-auth key
8. Done!

**Option B: Using defaults command (Terminal, one-time)**

```bash
defaults write com.tailscale.ipn.macos LoginURL http://localhost:8000
```

Then open Tailscale app and click "Connect"

#### Features

- Menu bar icon shows status (blue = connected)
- Click icon for menu:
  - View all nodes on network
  - Copy your Tailscale IP
  - Share files (Taildrop)
  - Exit node selection
  - Preferences

### Linux - Tailscale GUI (GNOME/KDE)

#### Installation

```bash
# Install Tailscale
curl -fsSL https://tailscale.com/install.sh | sh

# Install GUI (varies by distro)
# Ubuntu/Debian:
sudo apt install tailscale-gnome   # for GNOME
# or
sudo apt install plasma-widget-tailscale   # for KDE
```

#### Connecting to Headscale

**GUI Method:**

1. Open Tailscale from system tray or app menu
2. Click **Settings**
3. Under "Control Server", change to: `http://localhost:8000`
4. Click **Connect**
5. Paste pre-auth key when prompted
6. Done!

**Alternative: Set via system settings**

Many Linux GUI's integrate with GNOME Settings or KDE System Settings where you can configure the VPN settings directly.

---

## 3️⃣ Mobile Apps (iOS & Android)

### iOS - Tailscale App

#### Installation

1. Download from **App Store**
2. Open the app

#### Connecting to Headscale

1. Tap **Settings** (gear icon)
2. Scroll down to **Use Alternative Coordination Server**
3. Toggle **ON**
4. Enter: `http://YOUR_SERVER_IP:8000`
   - ⚠️ **Important**: Must be reachable from your phone (not localhost)
   - Use your computer's IP address or public domain
5. Tap **Save**
6. Go back and tap **Connect**
7. When browser opens, paste your pre-auth key
8. Done!

#### Features

- View all connected nodes
- See your IP address
- Accept exit nodes
- Share files via Taildrop
- Connection status notifications

### Android - Tailscale App

#### Installation

1. Download from **Google Play Store**
2. Open the app

#### Connecting to Headscale

1. Tap **⋮** (three dots menu)
2. Select **Settings**
3. Tap **Server URL**
4. Enter: `http://YOUR_SERVER_IP:8000`
5. Tap **OK**
6. Go back and tap **Connect**
7. Paste pre-auth key in browser
8. Done!

#### Features

- View network nodes
- Share files
- Enable exit nodes
- Persistent notification shows status
- Quick tile for on/off

---

## 🔧 Pre-Auth Key Management (Using Headplane)

Instead of command-line, generate keys in Headplane:

1. Open **http://localhost:3001/admin/**
2. Go to **Pre-Auth Keys** section
3. Click **Create New Key**
4. Configure:
   - User: Select user
   - Reusable: ✅ (for multiple devices)
   - Expiration: 24 hours (recommended)
   - Tags: Optional (e.g., `tag:personal`)
5. Click **Create**
6. Copy the key immediately (shown only once!)
7. Use this key in any Tailscale GUI app

---

## 📱 Step-by-Step: Connect Your Phone

### Example: iPhone Setup

1. **On your computer** (Headplane):
   - Go to http://localhost:3001/admin/
   - Create a new pre-auth key
   - Copy the key

2. **On your iPhone**:
   - Install Tailscale from App Store
   - Open app → Settings
   - Enable "Use Alternative Coordination Server"
   - Enter your server address (e.g., `http://192.168.1.100:8000`)
   - Save
   - Tap "Connect"
   - Browser opens
   - Paste the pre-auth key
   - Tap "Authenticate"
   - Done! ✅

3. **Verify** (on computer in Headplane):
   - Refresh the Nodes page
   - You should see your iPhone listed

---

## 💻 Step-by-Step: Connect Windows PC

1. **Generate key in Headplane**:
   - Go to http://localhost:3001/admin/
   - Create new pre-auth key
   - Copy it

2. **On Windows PC**:
   - Download Tailscale from https://tailscale.com/download/windows
   - Install it
   - Open Tailscale from Start menu
   - Click Settings → Use Custom Login Server
   - Enter: `http://YOUR_HEADSCALE_IP:8000`
   - Click Connect
   - Browser opens
   - Paste pre-auth key
   - Click Authenticate
   - Done! ✅

3. **Verify**:
   - Look for Tailscale icon in system tray (should be blue/connected)
   - In Headplane, refresh Nodes page
   - Your Windows PC appears in the list

---

## 🎛️ Managing Everything via GUI

### Add/Remove Devices
**Use Headplane:**
- Go to Nodes page
- Click **Delete** to remove a device
- Click node name to view details

### Approve Routes
**Use Headplane:**
- Go to Routes page
- See all advertised routes
- Click **Approve** to enable

### Manage Users
**Use Headplane:**
- Go to Users page
- Click **Create User** to add new users
- View all devices per user

### Configure ACLs
**Use Headplane:**
- Go to Policies/Settings
- Edit ACL rules in the web editor
- Save changes

### View Network Status
**Use Headplane:**
- Dashboard shows overview
- Click any node to see:
  - IP addresses
  - Online/offline status
  - Last seen time
  - Operating system
  - Tailscale version

---

## 🔍 Troubleshooting GUI Apps

### "Unable to connect" Error

**Cause**: App can't reach your Headscale server

**Solutions**:
1. Make sure Headscale is running: `curl http://localhost:8000/health`
2. For mobile: Use your computer's IP, not `localhost`
3. Check firewall allows port 8000
4. For production: Use your public domain with HTTPS

### "Invalid pre-auth key" Error

**Solutions**:
1. Generate a new key in Headplane
2. Make sure key hasn't expired
3. Copy the entire key (no extra spaces)
4. Use a reusable key if connecting multiple devices

### GUI App Won't Start

**Windows**:
- Restart Tailscale service: Services → Tailscale → Restart
- Reinstall from https://tailscale.com/download/windows

**macOS**:
- Quit Tailscale completely (right-click icon → Quit)
- Relaunch from Applications

**Mobile**:
- Force close app
- Clear app cache in system settings
- Reinstall if needed

---

## 📊 Feature Comparison

| Feature | Headplane (Web) | Tailscale Desktop GUI | Tailscale Mobile |
|---------|----------------|----------------------|------------------|
| Manage all nodes | ✅ | ❌ | ❌ |
| Create users | ✅ | ❌ | ❌ |
| Generate keys | ✅ | ❌ | ❌ |
| Configure ACLs | ✅ | ❌ | ❌ |
| Connect device | ❌ | ✅ | ✅ |
| View own IP | ✅ | ✅ | ✅ |
| Enable exit node | ✅ | ✅ | ✅ |
| File sharing | ❌ | ✅ | ✅ |
| View network map | ✅ | ✅ | ✅ |

**Recommendation**: Use **Headplane for server management** and **Tailscale GUI apps for client devices**.

---

## 🎯 Quick Reference

### Generate Pre-Auth Key (GUI)
1. Open http://localhost:3001/admin/
2. Pre-Auth Keys → Create New
3. Copy key

### Connect Device (GUI)
**Desktop**: Settings → Custom Login Server → Enter URL → Connect → Paste key
**Mobile**: Settings → Alternative Server → Enter URL → Connect → Paste key

### View All Devices (GUI)
1. Open http://localhost:3001/admin/
2. Go to Nodes page
3. See all connected devices

### Remove Device (GUI)
1. Open http://localhost:3001/admin/
2. Nodes page → Find device
3. Click Delete

---

## 🚀 Next Steps

1. **Access Headplane**: http://localhost:3001/admin/
2. **Generate a key**: Create pre-auth key in Headplane
3. **Download Tailscale app**: For your device from https://tailscale.com/download
4. **Connect**: Use the GUI to connect with your key
5. **Verify**: Check Headplane Nodes page to see your device

**No command-line required!** 🎉

---

## 📚 Additional Resources

- **Headplane**: Already running at http://localhost:3001/admin/
- **Tailscale Downloads**: https://tailscale.com/download
- **Your Headscale Server**: http://localhost:8000
- **API Key**: Generate with `docker exec headscale headscale apikeys create`
- **Main README**: [README.md](README.md)
