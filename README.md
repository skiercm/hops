# HOPS - Homelab Orchestration Provisioning Script

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/Version-3.1.0-blue.svg)]()
[![Platform](https://img.shields.io/badge/Platform-Ubuntu%2FDebian%2FMint-orange.svg)]()

**HOPS** is a comprehensive, automated deployment solution for popular homelab applications. It simplifies the process of setting up and managing Docker-based services including media servers, download clients, monitoring tools, and more.

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

### 🔒 **Security First**
- Automatic firewall configuration
- Secure password generation
- File permission hardening
- Network isolation

### 📊 **Management & Monitoring**
- Real-time service status monitoring
- Centralized log viewing
- Easy service management (start/stop/restart)
- Health checks and service verification

### 🔄 **Reliability**
- Error handling with automatic rollback
- Service dependency management
- Port conflict detection
- System requirements validation

## 📱 Supported Services

### 📺 Media Management (*arr Stack)
- **Sonarr** - TV show management
- **Radarr** - Movie management  
- **Lidarr** - Music management
- **Readarr** - eBook/audiobook management
- **Bazarr** - Subtitle management
- **Prowlarr** - Indexer management
- **Tdarr** - Media transcoding

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
- **OS**: Ubuntu 20.04+, Debian 11+, or Linux Mint 20+
- **RAM**: 2GB (4GB+ recommended)
- **Storage**: 10GB free space (more for media)
- **CPU**: 2 cores recommended
- **Network**: Internet connection required

### Prerequisites
- Root/sudo access
- x86_64 architecture

## 🚀 Quick Start

### 1. Download HOPS
```bash
git clone https://github.com/yourusername/hops.git
cd hops
chmod +x hops.sh
```

### 2. Run Installation
```bash
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
~/homelab/                    # Main homelab directory
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
All configuration is stored in `~/homelab/.env`:

```bash
# Core Configuration
PUID=1000                     # User ID
PGID=1000                     # Group ID
TZ=America/New_York          # Timezone

# Directory Configuration
DATA_ROOT=/mnt/media         # Media storage
CONFIG_ROOT=/opt/appdata     # App configurations

# Security
DEFAULT_ADMIN_PASSWORD=...   # Generated secure password
DEFAULT_DB_PASSWORD=...      # Database password

# Optional: Custom domain
DOMAIN=yourdomain.com
ACME_EMAIL=admin@yourdomain.com
```

### Service Management Commands
```bash
# Navigate to homelab directory
cd ~/homelab

# View running services
docker compose ps

# View logs
docker compose logs -f [service-name]

# Restart specific service
docker compose restart [service-name]

# Update all services
docker compose pull && docker compose up -d

# Stop all services
docker compose down
```

## 🔒 Security Features

### Automatic Security Hardening
- **Firewall Configuration**: Automatic UFW rules for service ports
- **Secure Passwords**: Cryptographically secure password generation
- **File Permissions**: Restrictive permissions on sensitive files
- **Network Isolation**: Docker network segregation
- **SSL/TLS**: Automatic certificate management with Traefik

### Post-Installation Security
1. **Change Default Passwords**: Update passwords in `.env` file
2. **Configure Reverse Proxy**: Set up Traefik or Nginx Proxy Manager
3. **Enable Authentication**: Configure Authelia for additional security
4. **Regular Updates**: Use Watchtower for automatic updates

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
cd ~/homelab
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
cp ~/homelab/.env ~/homelab/docker-compose.yml /backup/location/
```

### Recovery
```bash
# Restore configurations
sudo tar -xzf hops-config-backup.tar.gz -C /

# Redeploy services
cd ~/homelab
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
git clone https://github.com/yourusername/hops.git
cd hops
# Make changes to scripts
# Test with: sudo ./hops.sh
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

- **Documentation**: Check this README and built-in help
- **Issues**: Report bugs via GitHub Issues
- **Community**: Join discussions in GitHub Discussions

---

**Made with ❤️ for the homelab community**

*HOPS - Making homelab deployment simple, secure, and reliable.*