# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

HOPS (Homelab Orchestration Provisioning Script) is a comprehensive automation tool for deploying homelab infrastructure using Docker Compose. It provides menu-driven installation, management, and monitoring of popular homelab services including media servers, download clients, monitoring tools, and more.

## Architecture

### Core Components

- **Main Script (`hops.sh`)**: Primary entry point providing menu-driven interface for all operations
- **Installer (`hops_installer_enhanced.sh`)**: Handles service installation and Docker Compose deployment
- **Uninstaller (`hops_uninstaller_fixed.sh`)**: Manages complete removal of services and configurations
- **Service Definitions (`hops_service_definitions.sh`)**: Contains Docker Compose service templates and configurations

### Key Design Patterns

- **Modular Architecture**: Each major function is separated into dedicated scripts
- **Service-Driven**: All services are defined as Docker Compose configurations with standardized patterns
- **Error Handling**: Comprehensive error handling with logging and rollback capabilities
- **Security First**: Built-in security hardening, firewall configuration, and secure password generation

## Development Commands

### Running HOPS
```bash
# Main script (requires root)
sudo ./hops.sh

# Direct installation
sudo ./hops_installer_enhanced.sh

# Uninstallation
sudo ./hops_uninstaller_fixed.sh
```

### Testing and Validation
```bash
# Check script syntax
bash -n hops.sh
bash -n hops_installer_enhanced.sh
bash -n hops_service_definitions.sh
bash -n hops_uninstaller_fixed.sh

# Test service definitions
source hops_service_definitions.sh
generate_service_definition jellyfin
```

### Log Management
```bash
# View installation logs
sudo tail -f /var/log/hops/hops-main-*.log

# View Docker Compose logs
cd ~/homelab && docker compose logs -f [service-name]
```

## Service Architecture

### Service Definition Pattern
All services follow a standardized Docker Compose pattern:
- LinuxServer.io containers with PUID/PGID/TZ environment variables
- Consistent volume mounting (`/opt/appdata` for configs, `/mnt/media` for data)
- Health checks for web services
- Unified network configuration (`homelab` network)
- Restart policy: `unless-stopped`

### Supported Service Categories
1. **Media Management**: Sonarr, Radarr, Lidarr, Readarr, Bazarr, Prowlarr, Tdarr
2. **Download Clients**: qBittorrent, Transmission, NZBGet, SABnzbd
3. **Media Servers**: Jellyfin, Plex, Emby, Jellystat
4. **Request Management**: Overseerr, Jellyseerr, Ombi
5. **Reverse Proxy**: Traefik, Nginx Proxy Manager, Authelia
6. **Monitoring**: Portainer, Uptime Kuma, Watchtower

## File Structure

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

## Environment Configuration

Key environment variables in `~/homelab/.env`:
- `PUID`/`PGID`: User/group IDs for file permissions
- `TZ`: Timezone configuration
- `DATA_ROOT`: Media storage location
- `CONFIG_ROOT`: Application configuration location
- Security passwords (auto-generated)

## Security Features

- **Firewall Integration**: Automatic UFW rule management
- **Secure Password Generation**: Cryptographically secure passwords
- **File Permission Hardening**: Restrictive permissions on sensitive files
- **Network Isolation**: Docker network segregation
- **SSL/TLS Support**: Automatic certificate management with reverse proxies

## Error Handling

- **Comprehensive Logging**: All operations logged to `/var/log/hops/`
- **Rollback Capability**: Automatic rollback on deployment failure
- **Dependency Validation**: Pre-deployment system requirement checks
- **Service Health Monitoring**: Built-in health checks for all services

## Key Functions

### In `hops.sh`
- `show_main_menu()`: Primary interface
- `manage_services()`: Service start/stop/restart
- `show_service_status()`: Real-time monitoring
- `show_access_info()`: Service URL and credential display

### In `hops_service_definitions.sh`
- `generate_service_definition()`: Creates Docker Compose service blocks
- `get_linuxserver_env()`: Standard environment variables
- `get_web_healthcheck()`: Health check configurations

### In `hops_installer_enhanced.sh`
- Service selection and dependency resolution
- Docker Compose file generation
- Security hardening implementation
- Post-deployment verification

## Development Guidelines

- **Bash Best Practices**: Use `set -e` for error handling, quote variables, use readonly for constants
- **Logging**: Use the logging functions (`log`, `error_exit`, `warning`, `success`, `info`)
- **Color Output**: Use predefined color constants for consistent formatting
- **Service Patterns**: Follow the established Docker Compose patterns when adding new services
- **Security**: Never commit secrets, use secure password generation, implement proper file permissions

## Common Operations

### Adding New Services
1. Add service definition function in `hops_service_definitions.sh`
2. Add service to installer menu in `hops_installer_enhanced.sh`
3. Configure any required dependencies or special handling
4. Test deployment and health checks

### Debugging Issues
1. Check logs in `/var/log/hops/`
2. Verify Docker Compose syntax with `docker compose config`
3. Check service health with `docker compose ps`
4. Review firewall rules with `sudo ufw status`