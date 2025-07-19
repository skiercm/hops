# HOPS - Homelab Orchestration Provisioning Script

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/Version-3.3.0-blue.svg)]()
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20Windows-orange.svg)]()

**HOPS** is a comprehensive automation tool for deploying homelab infrastructure using Docker Compose. Deploy and manage popular homelab services including media servers, download clients, monitoring tools, and more through an intuitive menu-driven interface.

## ⚠️ Important: Beta Software
**HOPS is beta software**. Always backup your data before installation and test in non-production environments first.

**Platform Status:**
- **Linux**: ✅ Stable and extensively tested
- **macOS**: ✅ Recently improved with v3.2.0 fixes  
- **Windows (WSL2)**: ⚠️ Limited testing

## 🆕 What's New in v3.3.0
- **🔄 Automatic Updates**: Git-based update system with backup functionality
- **📱 Command Line Interface**: `--update`, `--check-updates`, `--version`, `--help` flags
- **🛡️ Safe Updates**: Automatic backup of local changes before updating
- **📋 Change Tracking**: View recent changes and version comparison

### Previous Updates (v3.2.0)
- **Enhanced macOS Support**: Docker Desktop integration, keychain authentication, user directory fixes
- **Caddy Support**: Added reverse proxy option (user provides configuration)
- **Bug Fixes**: Password generation, container creation, healthchecks, file permissions
- **Security**: Encrypted secret management, input validation, privilege separation

## ✨ Key Features

- **🚀 Easy Installation**: One-command setup with automatic Docker installation
- **🔒 Security First**: Encrypted secrets, firewall configuration, input validation
- **📊 Management**: Real-time monitoring, centralized logs, service control
- **🔄 Auto-Updates**: Built-in update system with backup protection
- **🔧 Reliability**: Error handling, rollback capabilities, dependency management
- **🌐 Cross-Platform**: Linux, macOS, and Windows (WSL2) support

## 📱 Supported Services

**Media Management**: Sonarr, Radarr, Lidarr, Readarr, Bazarr, Prowlarr, Tdarr, Huntarr  
**Download Clients**: qBittorrent, Transmission, NZBGet, SABnzbd  
**Media Servers**: Jellyfin, Plex, Emby, Jellystat  
**Request Management**: Overseerr, Jellyseerr, Ombi  
**Reverse Proxy**: Traefik, Nginx Proxy Manager, Caddy, Authelia  
**Monitoring**: Portainer, Uptime Kuma, Watchtower  

[View complete service list with support links →](SERVICES.md)

## 🔧 System Requirements

**Minimum**: 2GB RAM, 10GB storage, 2 CPU cores, internet connection

**Supported Platforms:**
- **Linux**: Ubuntu 20.04+, Debian 11+, Linux Mint 20+ (x86_64, sudo access)
- **macOS**: 11.0+ Big Sur, Intel/Apple Silicon (admin access, auto-installs Docker Desktop)
- **Windows**: 10/11 with WSL2 + Ubuntu 20.04+ (limited testing, requires Docker Desktop)

[View detailed installation guides →](INSTALLATION.md)

## 🚀 Quick Start

```bash
# 1. Download HOPS
git clone https://github.com/skiercm/hops.git
cd hops
chmod +x hops install uninstall setup

# 2. Run installation
sudo ./setup

# 3. Follow interactive setup to select services

# 4. Access your services
# URLs will be provided after installation
```

**Directory Structure:**
- `~/hops/` - Main deployment (docker-compose.yml, .env, logs)  
- `/opt/appdata/` (Linux) or `~/hops/config/` (macOS) - App configs
- `/mnt/media/` (Linux) or `~/hops/media/` (macOS) - Media storage

## 🎛️ Management

```bash
# Access management interface
sudo ./hops

# Update HOPS
sudo ./hops --update                  # Update to latest version
sudo ./hops --check-updates           # Check for updates
./hops --version                      # Show version
./hops --help                         # Show help

# Service operations (no sudo required)
./user-operations status              # View service status
./user-operations logs <service>      # View logs
./user-operations deploy              # Deploy services
./user-operations stop               # Stop all services
```

[View advanced configuration and troubleshooting →](ADVANCED.md)

## 📞 Support

**HOPS Issues**: [GitHub Issues](https://github.com/skiercm/hops/issues) | [Discussions](https://github.com/skiercm/hops/discussions)

**Service Issues**: Contact individual service developers (links in [SERVICES.md](SERVICES.md))

**Contact HOPS for**: Installation/deployment issues, Docker Compose problems, cross-platform issues  
**Contact Service Developers for**: Service configuration, features, service-specific bugs

## 📄 Documentation

- [INSTALLATION.md](INSTALLATION.md) - Detailed installation guides for all platforms
- [SERVICES.md](SERVICES.md) - Complete service list with support links  
- [ADVANCED.md](ADVANCED.md) - Configuration, troubleshooting, security
- [CHANGELOG.md](CHANGELOG.md) - Version history and changes

## 📄 License

MIT License - see [LICENSE](LICENSE) file for details.

---

**Made with ❤️ for the homelab community**
