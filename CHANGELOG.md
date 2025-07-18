# Changelog

All notable changes to HOPS will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.2.0] - 2024-07-18

### Added
- **Caddy Support**: Added Caddy reverse proxy as a service option
- **Enhanced macOS Compatibility**: Comprehensive improvements for macOS installation and operation
- **Docker Desktop Integration**: Improved Docker Desktop startup and management on macOS
- **Keychain Integration**: Proper Docker authentication with macOS keychain on macOS

### Fixed
- **User Directory Fixes**: All directories now use actual user home instead of root on macOS
- **Password Generation**: Resolved `shuf` command and encoding issues on macOS
- **Container Creation**: Fixed Docker Compose working directory and execution context issues
- **Healthcheck Improvements**: Enhanced service health monitoring, particularly for Jellyseerr
- **File Permissions**: Proper ownership of all directories and files across platforms
- **Docker Compose Warnings**: Resolved version warnings and compatibility issues

### Changed
- **macOS File Structure**: Improved directory layout using user home instead of system directories
- **Error Handling**: Enhanced error messages and troubleshooting information for macOS
- **Documentation**: Updated platform-specific installation and configuration guides

### Security
- **Secure Authentication**: Enhanced Docker authentication methods on macOS
- **File Ownership**: Improved file permission management across all platforms

## [3.1.0-beta] - 2024-06-15

### Added
- **Encrypted Secret Management**: All passwords and sensitive data now encrypted with AES-256
- **Input Validation**: Comprehensive validation preventing injection attacks
- **Privilege Separation**: Root operations separated from user operations for enhanced security
- **Pinned Container Versions**: All container images use specific versions, not `latest`
- **Modular Architecture**: Shared code organized in `lib/` directory for better maintainability
- **Cross-Platform Support**: Native support for Linux, macOS, and Windows (WSL2)
- **Enhanced Error Handling**: Better error messages and recovery mechanisms
- **Improved Service Definitions**: Standardized service generation with validation
- **Complete Documentation**: Added `CLAUDE.md` for development guidance

### Changed
- **Installation Methods**: New secure installer `setup` script as recommended method
- **Service Management**: New `user-operations` script for non-privileged service management
- **Architecture**: Modular library system replacing monolithic scripts
- **Security Model**: Clear separation between privileged and user operations

### Security
- **AES-256 Encryption**: All secrets stored encrypted with master key management
- **Input Sanitization**: Comprehensive validation preventing code injection
- **Container Security**: Pinned versions preventing supply chain attacks
- **Privilege Minimization**: Reduced root access requirements

## [3.0.0] - 2024-05-01

### Added
- **Cross-Platform Support**: Full support for Linux, macOS, and Windows (WSL2)
- **Automatic Dependency Installation**: Docker and system requirements installed automatically
- **Platform Detection**: Intelligent OS detection and platform-specific optimizations
- **Enhanced Service Catalog**: Expanded service definitions with health checks
- **Comprehensive Logging**: Detailed logging system for troubleshooting
- **Service Health Monitoring**: Built-in health checks for all services
- **Rollback Capabilities**: Automatic rollback on deployment failure

### Changed
- **Installation Process**: Streamlined installation with better user experience
- **Directory Structure**: Platform-appropriate directory layouts
- **Service Definitions**: Standardized Docker Compose patterns
- **Error Handling**: Improved error messages and recovery procedures

### Fixed
- **Port Conflict Detection**: Better handling of port conflicts
- **Permission Issues**: Improved file permission management
- **Service Dependencies**: Enhanced dependency resolution

## [2.1.0] - 2024-03-15

### Added
- **Huntarr Support**: Missing media discovery and automation
- **Jellystat Support**: Jellyfin statistics and monitoring
- **Watchtower Integration**: Automatic container updates
- **Enhanced Monitoring**: Improved service status monitoring
- **Backup Utilities**: Built-in backup and recovery tools

### Changed
- **Service Management**: Improved start/stop/restart functionality
- **Log Viewing**: Enhanced centralized log viewing
- **Configuration Management**: Better environment variable handling

### Fixed
- **Memory Usage**: Optimized resource usage for low-resource systems
- **Startup Issues**: Resolved service startup race conditions
- **Network Configuration**: Fixed Docker network isolation issues

## [2.0.0] - 2024-02-01

### Added
- **Management Interface**: Comprehensive web-based management
- **Security Hardening**: Automatic firewall configuration and secure passwords
- **Service Templates**: Standardized service definitions
- **Real-time Monitoring**: Live service status and resource monitoring
- **User Interface**: Menu-driven installation and management

### Changed
- **Architecture**: Complete rewrite with modular design
- **Installation**: Simplified one-command installation
- **Configuration**: Centralized configuration management

### Breaking Changes
- **Directory Structure**: New standardized directory layout
- **Configuration Format**: Updated environment variable structure
- **Service Names**: Standardized container and service naming

## [1.2.0] - 2024-01-15

### Added
- **Authelia Support**: Multi-factor authentication and SSO
- **Nginx Proxy Manager**: Alternative reverse proxy option
- **Enhanced SSL**: Automatic SSL certificate management
- **Service Discovery**: Automatic service registration

### Fixed
- **Traefik Configuration**: Improved reverse proxy setup
- **SSL Issues**: Resolved certificate generation problems
- **Network Routing**: Fixed internal service communication

## [1.1.0] - 2023-12-01

### Added
- **Traefik Integration**: Automatic reverse proxy with SSL
- **Service Categories**: Organized services by function
- **Dependency Management**: Automatic service dependency resolution
- **Health Checks**: Service health monitoring and restart

### Changed
- **Service Definitions**: Improved Docker Compose templates
- **Network Configuration**: Enhanced Docker networking

## [1.0.0] - 2023-11-01

### Added
- **Initial Release**: Core HOPS functionality
- **Service Support**: Basic *arr stack, download clients, and media servers
- **Docker Integration**: Docker Compose based deployment
- **Linux Support**: Ubuntu/Debian/Mint support
- **Basic Management**: Simple service management interface

### Features
- **Automated Installation**: One-command deployment
- **Service Selection**: Interactive service selection
- **Basic Security**: Firewall rules and secure passwords
- **Directory Management**: Automatic directory creation and permissions

---

## Version Support

- **v3.2.x**: Current stable release with full platform support
- **v3.1.x**: Beta features, limited support
- **v3.0.x**: Legacy support for critical bugs only
- **v2.x and earlier**: No longer supported

## Upgrade Path

### From v3.1.x to v3.2.0
```bash
# Backup current installation
sudo tar -czf hops-backup-$(date +%Y%m%d).tar.gz ~/hops /opt/appdata

# Pull latest version
cd ~/hops
git pull origin main

# Run upgrade
sudo ./setup --upgrade
```

### From v3.0.x to v3.2.0
```bash
# Major version upgrade requires fresh installation
# Backup data first
sudo ./uninstall --keep-data
sudo ./setup
```

### From v2.x to v3.2.0
```bash
# Migration script available
sudo ./migrate-from-v2.sh
```

## Migration Notes

### v3.2.0 Changes
- **macOS Users**: Directory structure has changed, migration handled automatically
- **Caddy Users**: Manual Caddyfile configuration required
- **Configuration**: Encrypted secrets now default for new installations

### v3.1.0 Changes
- **Security**: All passwords moved to encrypted storage
- **Architecture**: New modular library system
- **Privileges**: Installation process now uses privilege separation

### v3.0.0 Changes
- **Cross-Platform**: New platform detection and configuration
- **Directories**: Platform-specific directory structures
- **Services**: Updated service definitions and health checks

---

For detailed upgrade instructions, see [INSTALLATION.md](INSTALLATION.md).  
For breaking changes and migration help, see [ADVANCED.md](ADVANCED.md).