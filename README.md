# HOPS - Homelab Orchestration Provisioning Script

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/Version-3.1.0--beta-blue.svg)]()
[![Platform](https://img.shields.io/badge/Platform-Linux%20%7C%20macOS%20%7C%20Windows-orange.svg)]()

**HOPS** is a comprehensive, automated deployment solution for popular homelab applications. It simplifies the process of setting up and managing Docker-based services including media servers, download clients, monitoring tools, and more.

## 🆕 What's New in v3.1.0-beta

### Major Security Enhancements
- **🔐 Encrypted Secret Management**: All passwords and sensitive data now encrypted with AES-256
- **🛡️ Input Validation**: Comprehensive validation preventing injection attacks
- **⚡ Privilege Separation**: Root operations separated from user operations
- **📌 Pinned Versions**: All container images use specific versions, not `latest`

### New Architecture
- **📚 Modular Libraries**: Shared code organized in `lib/` directory
- **🔧 Enhanced Error Handling**: Better error messages and recovery mechanisms
- **🎯 Improved Service Definitions**: Standardized service generation with validation
- **📖 Documentation**: Complete `CLAUDE.md` for development guidance
- **🍎 Cross-Platform Support**: Native support for Linux, macOS, and Windows (WSL2) with automatic dependency installation

### Installation Methods
- **🚀 New Secure Installer**: `sudo ./setup` - Recommended method
- **⚙️ Manual Installation**: Separate privileged and user operations
- **🔄 Legacy Support**: Original `hops.sh` still fully supported

## 🎯 What is HOPS?

HOPS (Homelab Orchestration Provisioning Script) automates the deployment of a complete homelab infrastructure using Docker Compose. It provides an intuitive menu-driven interface for selecting, configuring, and managing services with enterprise-grade features like:

- **Automated dependency resolution**
- **Security hardening and firewall configuration**
- **Service health monitoring**
- **Rollback capabilities on failure**
- **Comprehensive logging**
- **User-friendly management interface**

## ✨ Key Features

### 🚀 **Easy Installation**
- One-command installation process
- Automatic Docker installation and configuration
- Interactive service selection
- Intelligent dependency resolution
- **NEW**: Privilege separation for enhanced security

### 🔒 **Security First**
- Automatic firewall configuration
- Secure password generation with encryption
- File permission hardening
- Network isolation
- **NEW**: AES-256 encrypted secret storage
- **NEW**: Comprehensive input validation
- **NEW**: Pinned container versions

### 📊 **Management & Monitoring**
- Real-time service status monitoring
- Centralized log viewing
- Easy service management (start/stop/restart)
- Health checks and service verification
- **NEW**: Modular architecture with shared libraries

### 🔄 **Reliability**
- Error handling with automatic rollback
- Service dependency management
- Port conflict detection
- System requirements validation
- **NEW**: Enhanced error handling with detailed context

## 📱 Supported Services

### 📺 Media Management (*arr Stack)
- **Sonarr** - TV show management
- **Radarr** - Movie management  
- **Lidarr** - Music management
- **Readarr** - eBook/audiobook management
- **Bazarr** - Subtitle management
- **Prowlarr** - Indexer management
- **Tdarr** - Media transcoding
- **Huntarr** - Missing media discovery and automation

### ⬇️ Download Clients
- **qBittorrent** - Feature-rich BitTorrent client
- **Transmission** - Lightweight BitTorrent client
- **NZBGet** - Efficient Usenet downloader
- **SABnzbd** - Popular Usenet client

### 🎞️ Media Servers
- **Jellyfin** - Open-source media server
- **Plex** - Popular media server platform
- **Emby** - Feature-rich media server
- **Jellystat** - Jellyfin statistics and monitoring

### 🎛️ Request Management
- **Overseerr** - Media request management for Plex
- **Jellyseerr** - Media request management for Jellyfin
- **Ombi** - Media request platform

### 🔒 Reverse Proxy & Security
- **Traefik** - Modern reverse proxy with automatic SSL
- **Nginx Proxy Manager** - Easy-to-use reverse proxy
- **Authelia** - Authentication and authorization server

### 📈 Monitoring & Management
- **Portainer** - Docker container management
- **Uptime Kuma** - Service monitoring
- **Watchtower** - Automatic container updates

## 🔧 System Requirements

### Minimum Requirements
- **OS**: 
  - **Linux**: Ubuntu 20.04+, Debian 11+, or Linux Mint 20+
  - **macOS**: 11.0+ (Big Sur) with Intel or Apple Silicon
  - **Windows**: 10/11 with WSL2 (Ubuntu 20.04+ distribution)
- **RAM**: 2GB (4GB+ recommended)
- **Storage**: 10GB free space (more for media)
- **CPU**: 2 cores recommended
- **Network**: Internet connection required

### Prerequisites

**Linux:**
- Root/sudo access
- x86_64 architecture
- Internet connection

**macOS:**
- Admin access (sudo privileges)
- Intel (x86_64) or Apple Silicon (ARM64)
- Internet connection
- Homebrew will be installed automatically if not present
- Docker Desktop will be installed automatically if not present

**Windows:**
- Windows 10 (build 19041+) or Windows 11
- WSL2 enabled with Ubuntu 20.04+ distribution
- Docker Desktop with WSL2 backend
- Admin access to install prerequisites
- x86_64 processor with virtualization support
- Hyper-V and virtualization enabled in BIOS

## 🪟 Windows Installation (WSL2)

HOPS runs on Windows through WSL2 (Windows Subsystem for Linux) with excellent compatibility and performance. This approach leverages the full Linux environment within Windows.

### Prerequisites Setup

**1. Enable WSL2:**
```powershell
# Run in PowerShell as Administrator
wsl --install
# Restart computer when prompted
```

**2. Install Ubuntu Distribution:**
```powershell
# Install Ubuntu 22.04 LTS (recommended)
wsl --install Ubuntu-22.04
# Set up username and password when prompted
```

**3. Install Docker Desktop:**
- Download from [Docker Desktop for Windows](https://docs.docker.com/desktop/install/windows-install/)
- Enable WSL2 integration during installation
- Ensure "Use WSL 2 based engine" is checked in Docker settings

### HOPS Installation on WSL2

**1. Open WSL2 Terminal:**
```bash
# Launch Ubuntu from Start Menu or run:
wsl -d Ubuntu-22.04
```

**2. Install HOPS (same as Linux):**
```bash
# Clone inside WSL2 filesystem (important for performance)
cd ~
git clone https://github.com/skiercm/hops.git
cd hops
chmod +x hops install uninstall setup

# Run installation
sudo ./setup
```

### ⚠️ Important Notes for Windows Users

**File Location:** Always run HOPS from the WSL2 filesystem (`~/hops/`) for optimal performance. Avoid running from `/mnt/c/` (Windows drives).

**Media Access:** Your Windows media folders can be accessed at:
- `C:\Users\YourName\` → `/mnt/c/Users/YourName/`
- External drives → `/mnt/d/`, `/mnt/e/`, etc.

**Docker Integration:** Services will be accessible from both Windows and WSL2:
- Web interfaces work from Windows browsers
- File shares accessible from Windows Explorer via `\\wsl.localhost\Ubuntu-22.04\home\username\hops\`

**Performance:** WSL2 provides 95% of native Linux performance when files are stored in the WSL2 filesystem.

## 🚀 Quick Start

### 1. Download HOPS
```bash
git clone https://github.com/skiercm/hops.git
cd hops
chmod +x hops install uninstall setup
```

### 2. Run Installation (New Improved Method)
```bash
# Option 1: Use the new secure installation wrapper
sudo ./setup

# Option 2: Manual two-phase installation
sudo ./privileged-setup  # Run as root
./user-operations generate <services>  # Run as user
./user-operations deploy  # Run as user

# Option 3: Legacy installation (still supported)
sudo ./hops.sh
```

### 3. Follow the Interactive Setup
- Select your desired services
- Configure directories and timezone
- Choose security options
- Wait for automated deployment

### 4. Access Your Services
The installer will provide URLs for all deployed services:
```
📱 Access your services at:
   ● Jellyfin     http://192.168.1.100:8096
   ● Sonarr       http://192.168.1.100:8989
   ● Radarr       http://192.168.1.100:7878
   ● Portainer    http://192.168.1.100:9000
```

## 📁 Default Directory Structure

```
~/hops/                       # Main deployment directory
├── docker-compose.yml        # Service definitions
├── .env                      # Environment variables
└── logs/                     # Application logs

/opt/appdata/                 # Application configurations
├── jellyfin/
├── sonarr/
├── radarr/
└── ...

/mnt/media/                   # Media storage
├── movies/
├── tv/
├── music/
└── downloads/
```

## 🎛️ Management Interface

HOPS includes a comprehensive management interface accessible through the main script:

```bash
sudo ./hops.sh
```

### Available Options:
1. **Install HOPS** - Deploy new services
2. **Uninstall HOPS** - Complete removal with options
3. **Manage Services** - Start/stop/restart services
4. **Service Status** - Real-time service monitoring
5. **Access Information** - Get service URLs and credentials
6. **View Logs** - Centralized log viewing
7. **Help & Documentation** - Built-in help system

## 🔧 Advanced Configuration

### Environment Variables
Configuration is now stored encrypted for enhanced security:

```bash
# NEW: Encrypted secret management
./lib/secrets.sh init                    # Initialize secret management
./lib/secrets.sh create                  # Create encrypted environment
./lib/secrets.sh update DOMAIN example.com  # Update values
./lib/secrets.sh get PUID               # Get values
./lib/secrets.sh list                   # List all keys

# Legacy: Plaintext configuration in ~/hops/.env
PUID=1000                     # User ID
PGID=1000                     # Group ID
TZ=America/New_York          # Timezone

# Directory Configuration
DATA_ROOT=/mnt/media         # Media storage
CONFIG_ROOT=/opt/appdata     # App configurations

# Security (now auto-generated and encrypted)
DEFAULT_ADMIN_PASSWORD=...   # Generated secure password
DEFAULT_DB_PASSWORD=...      # Database password

# Optional: Custom domain
DOMAIN=yourdomain.com
ACME_EMAIL=admin@yourdomain.com
```

### Service Management Commands
```bash
# NEW: User operations script (runs without sudo)
./user-operations status        # View service status
./user-operations logs <service> # View service logs
./user-operations deploy        # Deploy services
./user-operations stop          # Stop all services

# Legacy: Direct Docker Compose commands
cd ~/hops
docker compose ps                       # View running services
docker compose logs -f [service-name]  # View logs
docker compose restart [service-name]  # Restart specific service
docker compose pull && docker compose up -d  # Update all services
docker compose down                     # Stop all services
```

### New Architecture
HOPS v3.1.0-beta introduces a modular architecture with shared libraries:

```
hops/
├── lib/                    # NEW: Shared libraries
│   ├── common.sh          # Logging, UI, utilities
│   ├── system.sh          # System validation
│   ├── docker.sh          # Docker operations
│   ├── security.sh        # Security utilities
│   ├── validation.sh      # Input validation
│   ├── secrets.sh         # Secret management
│   └── privileges.sh      # Privilege management
├── setup                  # NEW: Installation wrapper
├── privileged-setup       # NEW: Root-only operations
├── user-operations        # NEW: User operations
├── services-improved      # NEW: Enhanced service definitions
└── hops.sh               # Legacy main script (still supported)
```

## 🔒 Security Features

### Automatic Security Hardening
- **Firewall Configuration**: Automatic UFW rules for service ports
- **Secure Passwords**: Cryptographically secure password generation
- **File Permissions**: Restrictive permissions on sensitive files
- **Network Isolation**: Docker network segregation
- **SSL/TLS**: Automatic certificate management with Traefik
- **NEW**: AES-256 encrypted secret storage with master key management
- **NEW**: Comprehensive input validation preventing injection attacks
- **NEW**: Privilege separation (root vs user operations)
- **NEW**: Pinned container versions preventing supply chain attacks

### Post-Installation Security
1. **Manage Encrypted Secrets**: Use `./lib/secrets.sh` for secure password management
2. **Configure Reverse Proxy**: Set up Traefik or Nginx Proxy Manager
3. **Enable Authentication**: Configure Authelia for additional security
4. **Regular Updates**: Use Watchtower for automatic updates
5. **Security Auditing**: Use `./lib/security.sh` for security checks

## 🆘 Troubleshooting

### Common Issues

#### Port Conflicts
```bash
# Check for port conflicts
sudo lsof -i :PORT_NUMBER

# View HOPS service status
sudo ./hops.sh
# Select option 4: Service Status
```

#### Service Won't Start
```bash
# Check service logs
cd ~/hops
docker compose logs [service-name]

# Restart service
docker compose restart [service-name]
```

#### Permission Issues
```bash
# Fix ownership of data directories
sudo chown -R $USER:$USER /mnt/media /opt/appdata
```

### Log Locations
- **Installation Logs**: `/var/log/hops/`
- **Service Logs**: `docker compose logs [service-name]`
- **System Logs**: `journalctl -u docker`

### Getting Help
1. Check the built-in help: `sudo ./hops.sh` → Option 7
2. Review logs in `/var/log/hops/`
3. Verify Docker status: `systemctl status docker`
4. Check service health: `docker compose ps`

## 🔄 Backup and Recovery

### Backup Important Data
```bash
# Backup configurations
sudo tar -czf hops-config-backup.tar.gz /opt/appdata

# Backup compose files
cp ~/hops/.env ~/hops/docker-compose.yml /backup/location/
```

### Recovery
```bash
# Restore configurations
sudo tar -xzf hops-config-backup.tar.gz -C /

# Redeploy services
cd ~/hops
docker compose up -d
```

## 📊 Performance Tuning

### For Low-Resource Systems
- Start with fewer services initially
- Monitor resource usage with Portainer
- Consider using lightweight alternatives (Transmission vs qBittorrent)

### For High-Performance Systems
- Enable GPU transcoding in Jellyfin/Plex
- Use SSD storage for application data
- Configure multiple download clients for redundancy

## 🤝 Contributing

We welcome contributions! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

### Development Setup
```bash
git clone https://github.com/skiercm/hops.git
cd hops

# Test syntax validation
bash -n lib/*.sh
bash -n *.sh

# Test service definitions
./services-improved list
./services-improved generate jellyfin

# Test new installation method
sudo ./setup

# Test legacy method
sudo ./hops.sh
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **LinuxServer.io** for excellent Docker images
- **Docker** for containerization platform
- **The Servarr Team** for the *arr applications
- **Jellyfin Project** for the open-source media server
- All the amazing open-source projects that make HOPS possible

## 📞 Support

### HOPS Support
- **Documentation**: Check this README and built-in help
- **Issues**: Report HOPS bugs via [GitHub Issues](https://github.com/skiercm/hops/issues)
- **Community**: Join discussions in [GitHub Discussions](https://github.com/skiercm/hops/discussions)

### Service-Specific Support

**⚠️ Important**: If you encounter issues with a specific service (configuration, features, bugs), please reach out to the respective service developers directly using the links below. HOPS only handles deployment automation - the individual services are maintained by their respective teams.

#### 📺 Media Management (*arr Stack)
- **Sonarr**: [github.com/Sonarr/Sonarr](https://github.com/Sonarr/Sonarr) - TV series management
- **Radarr**: [github.com/Radarr/Radarr](https://github.com/Radarr/Radarr) - Movie collection manager
- **Lidarr**: [github.com/Lidarr/Lidarr](https://github.com/Lidarr/Lidarr) - Music collection manager
- **Readarr**: [github.com/Readarr/Readarr](https://github.com/Readarr/Readarr) - E-book manager ⚠️ *Project retired*
- **Bazarr**: [github.com/morpheus65535/bazarr](https://github.com/morpheus65535/bazarr) - Subtitle management
- **Prowlarr**: [github.com/Prowlarr/Prowlarr](https://github.com/Prowlarr/Prowlarr) - Indexer manager
- **Tdarr**: [github.com/HaveAGitGat/Tdarr](https://github.com/HaveAGitGat/Tdarr) - Media transcoding
- **Huntarr**: [github.com/plexguide/Huntarr.io](https://github.com/plexguide/Huntarr.io) - Missing media discovery

#### ⬇️ Download Clients
- **qBittorrent**: [github.com/qbittorrent/qBittorrent](https://github.com/qbittorrent/qBittorrent) - BitTorrent client
- **Transmission**: [github.com/transmission/transmission](https://github.com/transmission/transmission) - BitTorrent client
- **NZBGet**: [github.com/nzbget/nzbget](https://github.com/nzbget/nzbget) - Usenet downloader
- **SABnzbd**: [github.com/sabnzbd/sabnzbd](https://github.com/sabnzbd/sabnzbd) - Usenet downloader

#### 🎞️ Media Servers
- **Jellyfin**: [github.com/jellyfin/jellyfin](https://github.com/jellyfin/jellyfin) - Free media server
- **Plex**: [github.com/plexinc/pms-docker](https://github.com/plexinc/pms-docker) - Docker container repo
- **Emby**: [github.com/MediaBrowser/Emby](https://github.com/MediaBrowser/Emby) - Personal media server

#### 🎛️ Request Management
- **Overseerr**: [github.com/sct/overseerr](https://github.com/sct/overseerr) - Media requests for Plex
- **Jellyseerr**: [github.com/fallenbagel/jellyseerr](https://github.com/fallenbagel/jellyseerr) - Media requests for Jellyfin/Emby/Plex
- **Ombi**: [github.com/Ombi-app/Ombi](https://github.com/Ombi-app/Ombi) - Media request platform
- **Jellystat**: [github.com/CyferShepard/Jellystat](https://github.com/CyferShepard/Jellystat) - Jellyfin statistics

#### 🔒 Network & Security
- **Traefik**: [github.com/traefik/traefik](https://github.com/traefik/traefik) - Modern reverse proxy
- **Nginx Proxy Manager**: [github.com/NginxProxyManager/nginx-proxy-manager](https://github.com/NginxProxyManager/nginx-proxy-manager) - Nginx proxy management
- **Authelia**: [github.com/authelia/authelia](https://github.com/authelia/authelia) - Authentication & SSO

#### 📈 Monitoring & Management
- **Portainer**: [github.com/portainer/portainer](https://github.com/portainer/portainer) - Container management
- **Watchtower**: [github.com/containrrr/watchtower](https://github.com/containrrr/watchtower) - Automatic updates
- **Uptime Kuma**: [github.com/louislam/uptime-kuma](https://github.com/louislam/uptime-kuma) - Uptime monitoring

### When to Contact HOPS vs Service Developers

**Contact HOPS** for:
- Installation/deployment issues
- Docker Compose generation problems  
- Cross-platform compatibility issues
- Script errors or automation failures

**Contact Service Developers** for:
- Service configuration help
- Feature requests for individual services
- Bugs within the service itself
- Service-specific documentation

---

**Made with ❤️ for the homelab community**

*HOPS - Making homelab deployment simple, secure, and reliable.*
