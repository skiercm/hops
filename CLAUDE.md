# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

HOPS (Homelab Orchestration Provisioning Script) is a comprehensive automation tool for deploying homelab infrastructure using Docker Compose. It provides menu-driven installation, management, and monitoring of popular homelab services including media servers, download clients, monitoring tools, and more.

**Cross-Platform Support**: HOPS now supports both Linux (Ubuntu/Debian/Mint) and macOS systems with intelligent platform detection and abstraction.

## Architecture

### Core Components

- **Main Script (`hops.sh`)**: Primary entry point providing menu-driven interface for all operations
- **Installer (`install`)**: Handles service installation and Docker Compose deployment
- **Uninstaller (`uninstall`)**: Manages complete removal of services and configurations
- **Service Definitions (`services`)**: Contains Docker Compose service templates and configurations
- **Library System (`lib/`)**: Modular abstraction layer for cross-platform compatibility
  - `lib/common.sh`: Shared logging, UI, and utility functions
  - `lib/system.sh`: OS detection, system requirements, and platform abstraction

### Key Design Patterns

- **Modular Architecture**: Each major function is separated into dedicated scripts
- **Cross-Platform Abstraction**: OS-specific operations are abstracted through lib/system.sh
- **Service-Driven**: All services are defined as Docker Compose configurations with standardized patterns
- **Error Handling**: Comprehensive error handling with logging and rollback capabilities
- **Security First**: Built-in security hardening, platform-appropriate firewall configuration, and secure password generation

## Development Commands

### Running HOPS
```bash
# Main script (requires root on Linux, admin on macOS)
sudo ./hops.sh

# Direct installation (Linux)
sudo ./install

# Direct installation (macOS)
sudo ./install

# Uninstallation
sudo ./uninstall
```

### Platform-Specific Requirements

**Linux (Ubuntu/Debian/Mint):**
- Root/sudo access
- Internet connection
- 2GB+ RAM, 10GB+ disk space

**macOS:**
- Admin access
- Internet connection
- 2GB+ RAM, 10GB+ disk space
- Homebrew will be installed automatically if not present
- Docker Desktop will be installed automatically via Homebrew

### Testing and Validation
```bash
# Check script syntax
bash -n hops.sh
bash -n install
bash -n services
bash -n uninstall
bash -n lib/system.sh
bash -n lib/common.sh

# Test OS detection and system requirements
source lib/common.sh && source lib/system.sh && detect_os && check_system_requirements 2 10

# Test service definitions
source services
generate_service_definition jellyfin
```

### Log Management
```bash
# View installation logs (Linux)
sudo tail -f /var/log/hops/hops-main-*.log

# View installation logs (macOS)
sudo tail -f /usr/local/var/log/hops/hops-main-*.log

# View Docker Compose logs
cd ~/homelab && docker compose logs -f [service-name]
```

## Service Architecture

### Service Definition Pattern
All services follow a standardized Docker Compose pattern:
- LinuxServer.io containers with PUID/PGID/TZ environment variables
- Platform-aware volume mounting:
  - **Linux**: `/opt/appdata` for configs, `/mnt/media` for data
  - **macOS**: `/Users/[user]/homelab/config` for configs, `/Users/[user]/homelab/media` for data
- Health checks for web services
- Unified network configuration (`homelab` network)
- Restart policy: `unless-stopped`
- Platform-specific features (timezone mounts, GPU access) handled automatically

### Supported Service Categories
1. **Media Management**: Sonarr, Radarr, Lidarr, Readarr, Bazarr, Prowlarr, Tdarr, Huntarr
2. **Download Clients**: qBittorrent, Transmission, NZBGet, SABnzbd
3. **Media Servers**: Jellyfin, Plex, Emby, Jellystat
4. **Request Management**: Overseerr, Jellyseerr, Ombi
5. **Reverse Proxy**: Traefik, Nginx Proxy Manager, Authelia
6. **Monitoring**: Portainer, Uptime Kuma, Watchtower

## File Structure

### Linux File Structure
```
~/homelab/                    # Main deployment directory
├── docker-compose.yml        # Generated service definitions
├── .env                      # Environment variables
└── logs/                     # Application logs

/opt/appdata/                 # Application configurations
└── [service-name]/           # Individual service configs

/mnt/media/                   # Media storage
├── movies/
├── tv/
├── music/
└── downloads/
```

### macOS File Structure
```
~/homelab/                    # Main deployment directory
├── docker-compose.yml        # Generated service definitions
├── .env                      # Environment variables
├── logs/                     # Application logs
├── config/                   # Application configurations
│   └── [service-name]/       # Individual service configs
└── media/                    # Media storage
    ├── movies/
    ├── tv/
    ├── music/
    └── downloads/
```

## Environment Configuration

Key environment variables in `~/homelab/.env`:
- `PUID`/`PGID`: User/group IDs for file permissions
- `TZ`: Timezone configuration
- `DATA_ROOT`: Media storage location
- `CONFIG_ROOT`: Application configuration location
- Security passwords (auto-generated)

## Security Features

- **Firewall Integration**: 
  - **Linux**: Automatic UFW rule management
  - **macOS**: Manual firewall configuration (automatic setup skipped)
- **Secure Password Generation**: Cryptographically secure passwords
- **File Permission Hardening**: Restrictive permissions on sensitive files
- **Network Isolation**: Docker network segregation
- **SSL/TLS Support**: Automatic certificate management with reverse proxies

## Error Handling

- **Comprehensive Logging**: All operations logged to platform-specific directories
  - **Linux**: `/var/log/hops/`
  - **macOS**: `/usr/local/var/log/hops/`
- **Rollback Capability**: Automatic rollback on deployment failure
- **Dependency Validation**: Pre-deployment system requirement checks
- **Service Health Monitoring**: Built-in health checks for all services

## Key Functions

### In `hops.sh`
- `show_main_menu()`: Primary interface
- `manage_services()`: Service start/stop/restart
- `show_service_status()`: Real-time monitoring
- `show_access_info()`: Service URL and credential display

### In `services`
- `generate_service_definition()`: Creates Docker Compose service blocks
- `get_linuxserver_env()`: Standard environment variables
- `get_web_healthcheck()`: Health check configurations
- `get_timezone_mount()`: Platform-specific timezone handling
- `get_gpu_devices()`: Platform-specific GPU access

### In `install`
- Service selection and dependency resolution
- Docker Compose file generation
- Cross-platform dependency installation
- Security hardening implementation
- Post-deployment verification

### In `lib/system.sh`
- `detect_os()`: Cross-platform OS detection
- `check_system_requirements()`: Platform-aware system validation
- `install_package()`: Package manager abstraction
- `install_docker()`: Platform-specific Docker installation
- `get_primary_ip()`: Network interface detection
- `get_default_*_path()`: Platform-specific path resolution

## Development Guidelines

- **Bash Best Practices**: Use `set -e` for error handling, quote variables, use readonly for constants
- **Cross-Platform Compatibility**: Always use lib/system.sh abstraction functions instead of direct OS commands
- **Logging**: Use the logging functions (`log`, `error_exit`, `warning`, `success`, `info`)
- **Color Output**: Use predefined color constants for consistent formatting
- **Service Patterns**: Follow the established Docker Compose patterns when adding new services
- **Security**: Never commit secrets, use secure password generation, implement proper file permissions
- **Path Handling**: Use `get_default_*_path()` functions for platform-specific paths

## Common Operations

### Adding New Services
1. Add service definition function in `services`
2. Add service to installer menu in `install`
3. Configure any required dependencies or special handling
4. Test deployment and health checks

### Debugging Issues
1. Check logs in platform-specific directories:
   - **Linux**: `/var/log/hops/`
   - **macOS**: `/usr/local/var/log/hops/`
2. Verify Docker Compose syntax with `docker compose config`
3. Check service health with `docker compose ps`
4. Review firewall rules:
   - **Linux**: `sudo ufw status`
   - **macOS**: Check System Preferences > Security & Privacy > Firewall

## Platform-Specific Notes

### macOS Considerations
- **Architecture Support**: Both Intel (x86_64) and Apple Silicon (ARM64) are supported
- **Docker Desktop**: Automatically installed via Homebrew if not present
- **Homebrew**: Automatically installed if not present
- **GPU Acceleration**: Not available (Docker containers cannot access macOS GPU)
- **Firewall**: Manual configuration required (automatic UFW setup skipped)
- **File Permissions**: Uses user's home directory structure for better compatibility
- **Service Management**: Uses launchctl instead of systemctl where applicable

### Linux Considerations
- **Architecture Support**: x86_64 only
- **Docker Engine**: Installed via official Docker script
- **Package Management**: Uses apt-get for Ubuntu/Debian/Mint
- **GPU Acceleration**: Available for Intel GPUs via /dev/dri passthrough
- **Firewall**: Automatic UFW configuration
- **File Permissions**: Uses system-wide directories (/opt, /mnt)
- **Service Management**: Uses systemctl for service management