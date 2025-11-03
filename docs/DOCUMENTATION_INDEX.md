# Documentation Index

Quick reference to all documentation files in this repository.

## 🚀 Getting Started

| Document | Description | Best For |
|----------|-------------|----------|
| **[README.md](README.md)** | Main documentation and setup guide | Everyone - start here! |
| **[QUICK_START_GUI.md](QUICK_START_GUI.md)** ⭐ | Step-by-step GUI-only guide (no command line) | Windows/Mac/Mobile users who prefer GUIs |

## 🎨 GUI Guides

| Document | Description | Best For |
|----------|-------------|----------|
| **[GUI_SETUP.md](GUI_SETUP.md)** | Complete guide for using graphical interfaces | All platforms - detailed GUI instructions |
| **[QUICK_START_GUI.md](QUICK_START_GUI.md)** | Quick GUI walkthrough | Fast setup with screenshots |

## 🔧 Configuration Files

| Document | Description | Best For |
|----------|-------------|----------|
| **[tailscale-configs/README.md](tailscale-configs/README.md)** | Tailscale client config files for all platforms | Automated setup and system service configuration |
| **[tailscale-configs/QUICK_START.md](tailscale-configs/QUICK_START.md)** | Quick reference for config files | Fast command-line setup |

## 📚 Advanced Topics

| Document | Description | Best For |
|----------|-------------|----------|
| **[BEST_PRACTICES.md](BEST_PRACTICES.md)** | Production deployment best practices | Production environments |
| **[NETWORKING.md](NETWORKING.md)** | Advanced networking (routes, exit nodes, ACLs) | Network configuration and troubleshooting |

## 📖 By Use Case

### I want to use GUIs only (no command line)
1. [QUICK_START_GUI.md](QUICK_START_GUI.md) - Fast GUI walkthrough
2. [GUI_SETUP.md](GUI_SETUP.md) - Complete GUI documentation

### I want automated setup with config files
1. [tailscale-configs/README.md](tailscale-configs/README.md) - All config files
2. [tailscale-configs/QUICK_START.md](tailscale-configs/QUICK_START.md) - Quick commands

### I want to understand best practices
1. [BEST_PRACTICES.md](BEST_PRACTICES.md) - Production guidelines
2. [NETWORKING.md](NETWORKING.md) - Network architecture

### I want complete reference
1. [README.md](README.md) - Main documentation
2. [GUI_SETUP.md](GUI_SETUP.md) - GUI reference
3. [tailscale-configs/README.md](tailscale-configs/README.md) - Config reference

## 🎯 Quick Links

### Access Your Services
- **Headplane Web GUI**: http://localhost:3001/admin/
- **Headscale API**: http://localhost:8000
- **Health Check**: http://localhost:8000/health

### Important Info
- **API Key**: Generate with `docker exec headscale headscale apikeys create`
- **Database**: SQLite (file-based, no PostgreSQL needed)
- **Version**: Headscale v0.27.0

## 📱 By Platform

### Windows
- GUI: [QUICK_START_GUI.md](QUICK_START_GUI.md#windows) (recommended)
- Config: [tailscale-configs/windows/](tailscale-configs/windows/)
- Full Guide: [GUI_SETUP.md](GUI_SETUP.md#windows---tailscale-gui)

### macOS
- GUI: [QUICK_START_GUI.md](QUICK_START_GUI.md#mac) (recommended)
- Config: [tailscale-configs/macos/](tailscale-configs/macos/)
- Full Guide: [GUI_SETUP.md](GUI_SETUP.md#macos---tailscale-menu-bar-app)

### Linux
- Config: [tailscale-configs/linux-systemd/](tailscale-configs/linux-systemd/)
- Setup Script: [tailscale-configs/linux-systemd/setup.sh](tailscale-configs/linux-systemd/setup.sh)
- Full Guide: [GUI_SETUP.md](GUI_SETUP.md#linux---tailscale-gui-gnomekde)

### iOS/Android
- GUI: [QUICK_START_GUI.md](QUICK_START_GUI.md#iphoneipad) (recommended)
- Full Guide: [GUI_SETUP.md](GUI_SETUP.md#3%EF%B8%8F%E2%83%A3-mobile-apps-ios--android)

### Docker Containers
- Config: [tailscale-configs/docker-compose/](tailscale-configs/docker-compose/)
- Example: [docker-compose.tailscale.yml](tailscale-configs/docker-compose/docker-compose.tailscale.yml)

## 🔍 Finding Information

### "How do I connect a device without command line?"
→ [QUICK_START_GUI.md](QUICK_START_GUI.md)

### "How do I set up automatic connection on boot?"
→ [tailscale-configs/README.md](tailscale-configs/README.md)

### "How do I configure ACL policies?"
→ [NETWORKING.md](NETWORKING.md#access-control-lists-acls)

### "How do I set up exit nodes?"
→ [NETWORKING.md](NETWORKING.md#exit-nodes)

### "How do I manage everything in the web interface?"
→ [GUI_SETUP.md](GUI_SETUP.md#1%EF%B8%8F%E2%83%A3-headplane-web-gui-server-management)

### "What are the best practices for production?"
→ [BEST_PRACTICES.md](BEST_PRACTICES.md)

### "How do I troubleshoot connection issues?"
→ [README.md](README.md#-troubleshooting)

## 📄 File List

```
.
├── README.md                      ← Start here
├── DOCUMENTATION_INDEX.md         ← You are here
├── QUICK_START_GUI.md            ← GUI-only quick start ⭐
├── GUI_SETUP.md                  ← Complete GUI guide
├── BEST_PRACTICES.md             ← Production best practices
├── NETWORKING.md                 ← Advanced networking
├── docker-compose.yml
├── Caddyfile
├── .env
├── headscale.sh
├── config/
│   ├── config.yaml
│   └── policy.json
├── headplane/
│   └── config.yaml
└── tailscale-configs/
    ├── README.md                 ← Config files documentation
    ├── QUICK_START.md           ← Quick config reference
    ├── linux-systemd/
    │   ├── setup.sh             ← Linux auto-setup
    │   └── tailscaled.env
    ├── macos/
    │   └── com.tailscale.headscale.plist
    ├── windows/
    │   └── tailscale-headscale.ps1
    └── docker-compose/
        └── docker-compose.tailscale.yml
```

## 🆘 Getting Help

1. Check [README.md](README.md#-troubleshooting) troubleshooting section
2. Review [NETWORKING.md](NETWORKING.md#troubleshooting) for network issues
3. See [GUI_SETUP.md](GUI_SETUP.md#-troubleshooting-gui-apps) for GUI problems
4. Check Headscale logs: `docker compose logs headscale`
5. Verify health: `curl http://localhost:8000/health`

## 🌟 Recommended Reading Order

### For Beginners
1. [README.md](README.md) - Overview
2. [QUICK_START_GUI.md](QUICK_START_GUI.md) - Connect first device
3. [GUI_SETUP.md](GUI_SETUP.md) - Learn all GUI features

### For Advanced Users
1. [NETWORKING.md](NETWORKING.md) - Advanced config
2. [BEST_PRACTICES.md](BEST_PRACTICES.md) - Production setup
3. [tailscale-configs/README.md](tailscale-configs/README.md) - Automation

---

**Need something specific?** Use your browser's find function (Ctrl+F / Cmd+F) to search this index!
