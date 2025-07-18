# Installation Guide

This guide provides detailed installation instructions for all supported platforms.

## 🔧 System Requirements

### Minimum Requirements
- **RAM**: 2GB (4GB+ recommended)
- **Storage**: 10GB free space (more for media storage)
- **CPU**: 2 cores recommended
- **Network**: Internet connection required

### Platform-Specific Requirements

#### Linux (Ubuntu/Debian/Mint)
- **OS**: Ubuntu 20.04+, Debian 11+, or Linux Mint 20+
- **Architecture**: x86_64
- **Access**: Root/sudo privileges
- **Dependencies**: Automatically installed

#### macOS
- **OS**: macOS 11.0+ (Big Sur)
- **Architecture**: Intel (x86_64) or Apple Silicon (ARM64)
- **Access**: Admin privileges (sudo)
- **Dependencies**: Homebrew and Docker Desktop installed automatically

#### Windows (WSL2)
- **OS**: Windows 10 (build 19041+) or Windows 11
- **WSL**: WSL2 enabled with Ubuntu 20.04+ distribution
- **Docker**: Docker Desktop with WSL2 backend
- **Access**: Admin access for initial setup
- **Architecture**: x86_64 with virtualization support
- **BIOS**: Hyper-V and virtualization enabled

⚠️ **Note**: Windows support has limited testing. Proceed with caution and ensure backups.

## 🐧 Linux Installation

### Quick Install
```bash
# Download HOPS
git clone https://github.com/skiercm/hops.git
cd hops
chmod +x hops install uninstall setup

# Run installation
sudo ./setup
```

### Manual Installation (Advanced)
```bash
# Two-phase installation for enhanced security
sudo ./privileged-setup              # Root operations
./user-operations generate <services> # User operations
./user-operations deploy             # Deploy services

# Legacy method (still supported)
sudo ./hops.sh
```

### What Gets Installed
- Docker Engine (via official Docker script)
- Docker Compose
- Required system packages
- UFW firewall rules (automatic)
- Service directories and permissions

### Directory Structure
```
~/hops/                       # Main deployment directory
├── docker-compose.yml        # Service definitions
├── .env                      # Environment variables
└── logs/                     # Application logs

/opt/appdata/                 # Application configurations
├── jellyfin/
├── sonarr/
└── [other services]/

/mnt/media/                   # Media storage
├── movies/
├── tv/
├── music/
└── downloads/
```

## 🍎 macOS Installation

### Prerequisites Setup
HOPS automatically handles dependency installation on macOS, but you can pre-install if desired:

```bash
# Optional: Install Homebrew (will be done automatically)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Optional: Install Docker Desktop (will be done automatically)
brew install --cask docker
```

### HOPS Installation
```bash
# Download HOPS
git clone https://github.com/skiercm/hops.git
cd hops
chmod +x hops install uninstall setup

# Run installation with admin privileges
sudo ./setup
```

### macOS-Specific Features
- **Docker Desktop Integration**: Automatic installation and startup
- **Keychain Authentication**: Secure Docker authentication
- **User Directory Structure**: All files in user home directory
- **Automatic Dependency Resolution**: Homebrew packages installed as needed

### Directory Structure (macOS)
```
~/hops/                       # Main deployment directory
├── docker-compose.yml        # Service definitions
├── .env                      # Environment variables
├── logs/                     # Application logs
├── config/                   # Application configurations
│   ├── jellyfin/
│   ├── sonarr/
│   └── [other services]/
└── media/                    # Media storage
    ├── movies/
    ├── tv/
    ├── music/
    └── downloads/
```

### Important Notes for macOS
- **GPU Acceleration**: Not available (Docker containers cannot access macOS GPU)
- **Firewall**: Manual configuration required (automatic UFW setup skipped)
- **File Permissions**: Uses user's home directory for better compatibility
- **Performance**: Excellent performance on both Intel and Apple Silicon

## 🪟 Windows Installation (WSL2)

Windows support uses WSL2 (Windows Subsystem for Linux) for excellent Linux compatibility.

### Step 1: Enable WSL2
```powershell
# Run in PowerShell as Administrator
wsl --install
# Restart computer when prompted
```

### Step 2: Install Ubuntu Distribution
```powershell
# Install Ubuntu 22.04 LTS (recommended)
wsl --install Ubuntu-22.04
# Follow prompts to create username and password
```

### Step 3: Install Docker Desktop
1. Download [Docker Desktop for Windows](https://docs.docker.com/desktop/install/windows-install/)
2. Enable WSL2 integration during installation
3. Ensure "Use WSL 2 based engine" is enabled in Docker settings
4. Enable integration with your Ubuntu distribution

### Step 4: Install HOPS
```bash
# Launch Ubuntu from Start Menu or run: wsl -d Ubuntu-22.04
cd ~
git clone https://github.com/skiercm/hops.git
cd hops
chmod +x hops install uninstall setup

# Run installation (same as Linux)
sudo ./setup
```

### Windows-Specific Considerations

#### File System Performance
- **Always run HOPS from WSL2 filesystem** (`~/hops/`) for optimal performance
- **Avoid Windows drives** (`/mnt/c/`) as they have significant performance penalties
- WSL2 provides 95% of native Linux performance when using WSL2 filesystem

#### Media Access
Your Windows media can be accessed from WSL2:
- `C:\Users\YourName\` → `/mnt/c/Users/YourName/`
- External drives → `/mnt/d/`, `/mnt/e/`, etc.

#### Service Access
- **Web interfaces**: Accessible from Windows browsers using WSL2 IP or localhost
- **File shares**: Available in Windows Explorer via `\\wsl.localhost\Ubuntu-22.04\home\username\hops\`
- **Network**: Services are accessible from both Windows and WSL2

#### Directory Structure (Windows/WSL2)
```
# WSL2 filesystem (recommended location)
~/hops/                       # Main deployment directory
├── docker-compose.yml        # Service definitions
├── .env                      # Environment variables
└── logs/                     # Application logs

/opt/appdata/                 # Application configurations
├── jellyfin/
├── sonarr/
└── [other services]/

/mnt/media/                   # Media storage (can link to Windows drives)
├── movies/ -> /mnt/d/Movies/
├── tv/ -> /mnt/d/TV/
├── music/ -> /mnt/d/Music/
└── downloads/
```

## 🔧 Installation Options

### Option 1: Secure Installation (Recommended)
```bash
sudo ./setup
```
- **Best Practice**: Separates privileged and user operations
- **Enhanced Security**: Minimizes root access time
- **User-Friendly**: Guided interactive setup

### Option 2: Manual Two-Phase Installation
```bash
sudo ./privileged-setup               # Root-only operations
./user-operations generate [services] # Select and generate services
./user-operations deploy              # Deploy services
```
- **Advanced Users**: Full control over each phase
- **Automation**: Can be scripted for multiple deployments
- **Security**: Clear separation of privileged operations

### Option 3: Legacy Installation
```bash
sudo ./hops.sh
```
- **Compatibility**: Original installation method
- **Full-Featured**: Complete management interface
- **Reliability**: Extensively tested method

## 🔍 Post-Installation Verification

### Check Service Status
```bash
# Via HOPS management interface
sudo ./hops.sh
# Select option 4: Service Status

# Via user operations
./user-operations status

# Direct Docker commands
cd ~/hops
docker compose ps
```

### Access Service URLs
After installation, HOPS provides URLs for all services:
```
📱 Access your services at:
   ● Jellyfin     http://192.168.1.100:8096
   ● Sonarr       http://192.168.1.100:8989
   ● Radarr       http://192.168.1.100:7878
   ● Portainer    http://192.168.1.100:9000
```

### Verify File Permissions
```bash
# Check directory ownership
ls -la ~/hops/
ls -la /opt/appdata/ (Linux) or ~/hops/config/ (macOS)
ls -la /mnt/media/ (Linux) or ~/hops/media/ (macOS)
```

## 🆘 Troubleshooting Installation

### Common Issues

#### Docker Installation Failed
```bash
# Check Docker status
systemctl status docker

# Restart Docker
sudo systemctl restart docker

# Reinstall Docker (Linux)
curl -fsSL https://get.docker.com | sh
```

#### Permission Denied Errors
```bash
# Fix directory ownership
sudo chown -R $USER:$USER ~/hops/
sudo chown -R $USER:$USER /opt/appdata/ (Linux)
sudo chown -R $USER:$USER ~/hops/config/ (macOS)
```

#### Port Conflicts
```bash
# Check what's using a port
sudo lsof -i :PORT_NUMBER

# Kill conflicting process
sudo kill -9 PID
```

#### WSL2 Issues (Windows)
```bash
# Restart WSL2
wsl --shutdown
wsl -d Ubuntu-22.04

# Check Docker Desktop WSL2 integration
# Go to Docker Desktop Settings → Resources → WSL Integration
```

### Log Locations
- **Installation Logs**: 
  - Linux: `/var/log/hops/`
  - macOS: `/usr/local/var/log/hops/`
  - Windows: `~/hops/logs/`
- **Service Logs**: `docker compose logs [service-name]`
- **System Logs**: `journalctl -u docker`

### Getting Help
1. **Built-in Help**: `sudo ./hops.sh` → Option 7
2. **Check Logs**: Review installation logs for errors
3. **Verify Prerequisites**: Ensure all system requirements are met
4. **Docker Status**: Confirm Docker is running and accessible
5. **GitHub Issues**: Report persistent issues with logs

## 🔄 Backup Strategy

### Before Installation
```bash
# Backup existing media and configs
sudo tar -czf homelab-backup-$(date +%Y%m%d).tar.gz \
  /path/to/your/media \
  /path/to/your/configs
```

### After Installation
```bash
# Backup HOPS configuration
sudo tar -czf hops-config-backup-$(date +%Y%m%d).tar.gz \
  ~/hops \
  /opt/appdata (Linux) or ~/hops/config (macOS)
```

## 📊 Performance Optimization

### During Installation
- **SSD Storage**: Install on SSD for better performance
- **Sufficient RAM**: Ensure adequate memory for selected services
- **Network Speed**: Faster internet improves Docker image downloads

### After Installation
- **Monitor Resources**: Use Portainer to monitor CPU, RAM, and disk usage
- **Optimize Services**: Start with fewer services, add more gradually
- **Storage Configuration**: Use dedicated drives for media storage

---

For additional help, see [ADVANCED.md](ADVANCED.md) for configuration and troubleshooting details.