# Advanced Configuration & Troubleshooting

This guide covers advanced HOPS configuration, troubleshooting, security features, and system administration.

## 🔧 Advanced Configuration

### Environment Variables

HOPS uses both encrypted secret management and traditional environment files for configuration.

#### Encrypted Secret Management (v3.1.0+)
```bash
# Initialize secret management
./lib/secrets.sh init

# Create encrypted environment
./lib/secrets.sh create

# Update values
./lib/secrets.sh update DOMAIN example.com
./lib/secrets.sh update ACME_EMAIL admin@example.com

# Retrieve values
./lib/secrets.sh get PUID
./lib/secrets.sh get DEFAULT_ADMIN_PASSWORD

# List all keys
./lib/secrets.sh list

# Backup encrypted secrets
./lib/secrets.sh backup /backup/location/
```

#### Traditional Environment File (~/hops/.env)
```bash
# User and Group Configuration
PUID=1000                     # User ID
PGID=1000                     # Group ID
TZ=America/New_York          # Timezone

# Directory Configuration
DATA_ROOT=/mnt/media         # Media storage (Linux)
CONFIG_ROOT=/opt/appdata     # App configurations (Linux)

# macOS paths (automatically set)
DATA_ROOT=/Users/username/hops/media
CONFIG_ROOT=/Users/username/hops/config

# Security (auto-generated and encrypted)
DEFAULT_ADMIN_PASSWORD=...   # Generated secure password
DEFAULT_DB_PASSWORD=...      # Database password
JELLYFIN_PASSWORD=...        # Service-specific passwords

# Optional: Custom Domain Configuration
DOMAIN=yourdomain.com
ACME_EMAIL=admin@yourdomain.com

# Optional: Service Overrides
JELLYFIN_PORT=8096
SONARR_PORT=8989
RADARR_PORT=7878
```

### Service-Specific Configuration

#### Reverse Proxy Setup

**Traefik Configuration:**
```bash
# Traefik automatically configured with labels
# Custom configuration in ~/hops/config/traefik/

# Example dynamic configuration
mkdir -p ~/hops/config/traefik/dynamic
cat > ~/hops/config/traefik/dynamic/middleware.yml << 'EOF'
http:
  middlewares:
    default-headers:
      headers:
        frameDeny: true
        sslRedirect: true
        browserXssFilter: true
        contentTypeNosniff: true
        forceSTSHeader: true
        stsIncludeSubdomains: true
        stsPreload: true
        stsSeconds: 31536000
EOF
```

**Nginx Proxy Manager:**
- Access admin interface on port 81
- Default credentials: `admin@example.com` / `changeme`
- Configure SSL certificates through web interface

**Caddy Configuration:**
```bash
# Create Caddy configuration directory
mkdir -p ~/hops/config/caddy

# Create custom Caddyfile
cat > ~/hops/config/caddy/Caddyfile << 'EOF'
# Global options
{
    email your-email@domain.com
    # Optional: Use custom CA
    # acme_ca https://acme-staging-v02.api.letsencrypt.org/directory
}

# Main domain
yourdomain.com {
    reverse_proxy jellyfin:8096
    
    # Custom headers
    header {
        # Security headers
        Strict-Transport-Security "max-age=31536000; includeSubDomains; preload"
        X-Content-Type-Options "nosniff"
        X-Frame-Options "DENY"
        Referrer-Policy "strict-origin-when-cross-origin"
    }
}

# Subdomain routing
sonarr.yourdomain.com {
    reverse_proxy sonarr:8989
}

radarr.yourdomain.com {
    reverse_proxy radarr:7878
}

# Internal services (authentication required)
portainer.yourdomain.com {
    reverse_proxy portainer:9000
    
    # Optional: IP allowlist
    @internal {
        remote_ip 192.168.1.0/24 10.0.0.0/8
    }
    handle @internal {
        reverse_proxy portainer:9000
    }
    handle {
        respond "Access denied" 403
    }
}
EOF
```

#### Authelia Integration
```bash
# Authelia configuration
mkdir -p ~/hops/config/authelia

# Example configuration (simplified)
cat > ~/hops/config/authelia/configuration.yml << 'EOF'
theme: dark
default_redirection_url: https://yourdomain.com

server:
  host: 0.0.0.0
  port: 9091

log:
  level: warn

authentication_backend:
  file:
    path: /config/users_database.yml
    password:
      algorithm: argon2id

access_control:
  default_policy: deny
  rules:
    - domain: jellyfin.yourdomain.com
      policy: bypass
    - domain: "*.yourdomain.com"
      policy: one_factor

session:
  name: authelia_session
  domain: yourdomain.com
  
regulation:
  max_retries: 3
  ban_time: 10m

storage:
  local:
    path: /config/db.sqlite3

notifier:
  filesystem:
    filename: /config/notification.txt
EOF
```

### Service Management Commands

#### User Operations Script (No Sudo Required)
```bash
# Service status and control
./user-operations status              # View all service status
./user-operations status jellyfin     # View specific service
./user-operations logs jellyfin       # View service logs
./user-operations logs jellyfin -f    # Follow logs

# Deployment operations
./user-operations deploy              # Deploy all services
./user-operations stop               # Stop all services
./user-operations restart            # Restart all services
./user-operations restart jellyfin   # Restart specific service

# Update operations
./user-operations update             # Update all containers
./user-operations update jellyfin    # Update specific container
```

#### Direct Docker Compose Commands
```bash
cd ~/hops

# Service management
docker compose ps                           # List services
docker compose up -d                        # Start all services
docker compose down                         # Stop all services
docker compose restart                      # Restart all services
docker compose restart jellyfin             # Restart specific service

# Logs and monitoring
docker compose logs                          # View all logs
docker compose logs -f jellyfin             # Follow specific service logs
docker compose logs --tail=100 sonarr       # Last 100 lines

# Updates and maintenance
docker compose pull                          # Pull new images
docker compose up -d --force-recreate       # Recreate containers
docker compose down && docker compose up -d # Full restart

# Resource monitoring
docker stats                                 # Real-time resource usage
docker system df                            # Disk usage
docker system prune                         # Clean unused data
```

### New Modular Architecture

HOPS v3.1.0+ introduces a modular library system:

```
hops/
├── lib/                    # Shared libraries
│   ├── common.sh          # Logging, UI, utilities
│   ├── system.sh          # OS detection, requirements
│   ├── docker.sh          # Docker operations
│   ├── security.sh        # Security functions
│   ├── validation.sh      # Input validation
│   ├── secrets.sh         # Secret management
│   └── privileges.sh      # Privilege separation
├── setup                  # Main installation wrapper
├── privileged-setup       # Root-only operations
├── user-operations        # User operations
├── services-improved      # Enhanced service definitions
└── hops.sh               # Legacy main script
```

#### Using Library Functions
```bash
# Source libraries in custom scripts
source lib/common.sh
source lib/system.sh

# Use logging functions
log "INFO" "Starting custom operation"
warning "This is a warning message"
error_exit "Fatal error occurred"

# Use system functions
detect_os
check_system_requirements 2 10  # 2GB RAM, 10GB disk

# Use validation functions
validate_port "8080"
validate_domain "example.com"
```

## 🔒 Security Features & Hardening

### Automatic Security Hardening

HOPS automatically implements several security measures:

#### Firewall Configuration (Linux)
```bash
# UFW rules automatically created
sudo ufw status

# Manual firewall management
sudo ufw allow 8096/tcp comment "Jellyfin"
sudo ufw allow 9000/tcp comment "Portainer"
sudo ufw delete allow 8096/tcp  # Remove rule
```

#### File Permissions
```bash
# Automatic permission hardening
# Secrets: 600 (owner read/write only)
# Configs: 644 (owner write, group/other read)
# Scripts: 755 (executable)

# Manual permission fixes
chmod 600 ~/hops/.env
chmod 644 ~/hops/docker-compose.yml
chmod 755 ~/hops/user-operations
```

#### Network Isolation
```bash
# Docker network isolation
docker network ls | grep homelab
docker network inspect homelab

# View network configuration
docker compose config | grep network
```

### Security Auditing
```bash
# Run security audit
./lib/security.sh audit

# Check for security issues
./lib/security.sh check-passwords
./lib/security.sh check-permissions
./lib/security.sh check-firewall

# Security recommendations
./lib/security.sh recommendations
```

### SSL/TLS Configuration

#### Traefik SSL
Traefik automatically handles SSL certificates with Let's Encrypt:
```bash
# Check certificate status
docker compose logs traefik | grep -i certificate

# Manual certificate renewal (if needed)
docker compose restart traefik
```

#### Custom SSL Certificates
```bash
# For custom certificates, place in:
# ~/hops/config/traefik/certs/
# - yourdomain.com.crt
# - yourdomain.com.key

# Update Traefik configuration to use custom certs
```

## 🆘 Troubleshooting

### Common Issues & Solutions

#### Docker Issues

**Docker Not Starting:**
```bash
# Check Docker status
systemctl status docker

# Restart Docker
sudo systemctl restart docker

# Check Docker logs
journalctl -u docker --since "1 hour ago"

# Reinstall Docker (Linux)
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker
```

**Docker Compose Errors:**
```bash
# Validate compose file
docker compose config

# Check for syntax errors
docker compose config --quiet

# Force recreate containers
docker compose up -d --force-recreate
```

#### Service-Specific Issues

**Service Won't Start:**
```bash
# Check service logs
docker compose logs [service-name]

# Check container status
docker compose ps

# Restart service
docker compose restart [service-name]

# Check port conflicts
sudo lsof -i :[port-number]
```

**Permission Issues:**
```bash
# Fix ownership (Linux)
sudo chown -R $USER:$USER /opt/appdata
sudo chown -R $USER:$USER /mnt/media
sudo chown -R $USER:$USER ~/hops

# Fix ownership (macOS)
sudo chown -R $USER:$USER ~/hops/config
sudo chown -R $USER:$USER ~/hops/media

# Check PUID/PGID values
id $USER  # Should match PUID/PGID in .env
```

**Database Issues:**
```bash
# Reset service database (example: Sonarr)
docker compose down sonarr
rm -rf ~/hops/config/sonarr/sonarr.db*  # macOS
rm -rf /opt/appdata/sonarr/sonarr.db*   # Linux
docker compose up -d sonarr
```

#### Network Issues

**Can't Access Services:**
```bash
# Check if services are running
docker compose ps

# Check port mapping
docker compose port jellyfin 8096

# Check firewall (Linux)
sudo ufw status

# Check local firewall (macOS)
# System Preferences → Security & Privacy → Firewall

# Find container IP
docker inspect jellyfin | grep IPAddress
```

**Reverse Proxy Issues:**
```bash
# Check proxy logs
docker compose logs traefik
docker compose logs nginx-proxy-manager

# Verify DNS resolution
nslookup yourdomain.com

# Check certificate status
openssl s_client -connect yourdomain.com:443 -servername yourdomain.com
```

#### Platform-Specific Issues

**macOS Issues:**
```bash
# Docker Desktop not starting
open /Applications/Docker.app

# Homebrew issues
brew doctor
brew update && brew upgrade

# Fix keychain authentication
security unlock-keychain ~/Library/Keychains/login.keychain
```

**Windows/WSL2 Issues:**
```bash
# WSL2 not starting
wsl --shutdown
wsl -d Ubuntu-22.04

# Docker Desktop WSL2 integration
# Check Docker Desktop → Settings → Resources → WSL Integration

# File permission issues
# Ensure files are in WSL2 filesystem, not /mnt/c/
```

### Log Analysis

#### Log Locations
- **Installation Logs**:
  - Linux: `/var/log/hops/`
  - macOS: `/usr/local/var/log/hops/`
  - Windows: `~/hops/logs/`
- **Service Logs**: `docker compose logs [service-name]`
- **System Logs**: `journalctl -u docker`

#### Log Analysis Commands
```bash
# HOPS installation logs
sudo tail -f /var/log/hops/hops-main-*.log

# Service logs with filtering
docker compose logs jellyfin | grep -i error
docker compose logs --since="1h" sonarr
docker compose logs --tail=100 radarr

# System resource logs
dmesg | grep -i memory
journalctl --since="1 hour ago" | grep docker
```

### Recovery Procedures

#### Service Recovery
```bash
# Stop problematic service
docker compose stop [service-name]

# Remove container (keeps data)
docker compose rm [service-name]

# Recreate service
docker compose up -d [service-name]

# Full service reset (destroys data)
docker compose down [service-name]
rm -rf /path/to/service/config
docker compose up -d [service-name]
```

#### Complete System Recovery
```bash
# Stop all services
docker compose down

# Backup current state
sudo tar -czf hops-backup-$(date +%Y%m%d).tar.gz ~/hops /opt/appdata

# Clean Docker system
docker system prune -a
docker volume prune

# Restart from backup
cd ~/hops
docker compose up -d

# Or reinstall HOPS
sudo ./uninstall
sudo ./setup
```

## 📊 Performance Tuning

### Resource Monitoring
```bash
# Container resource usage
docker stats

# System resource usage
htop
iotop
free -h
df -h

# Service-specific monitoring
docker compose exec portainer sh
# Access Portainer for detailed monitoring
```

### Optimization Strategies

#### For Low-Resource Systems (2-4GB RAM)
```bash
# Recommended minimal stack
# - Jellyfin (media server)
# - qBittorrent (download)
# - Sonarr (TV management)
# - Portainer (monitoring)

# Resource limits in docker-compose.yml
services:
  jellyfin:
    mem_limit: 1g
    cpus: '2'
    
  sonarr:
    mem_limit: 512m
    cpus: '1'
```

#### For High-Performance Systems (8GB+ RAM)
```bash
# Full stack deployment
# Enable GPU transcoding
# Use multiple download clients
# Add monitoring stack

# GPU support (Linux only)
# Intel GPU passthrough automatically configured
devices:
  - /dev/dri:/dev/dri
```

#### Storage Optimization
```bash
# Use SSD for application data
# HDD for media storage
# Separate Docker volumes

# Example optimized storage layout
/opt/appdata -> SSD
/mnt/media   -> HDD array
~/hops       -> SSD
```

### Update Management
```bash
# Automated updates with Watchtower
# Configure update schedule
WATCHTOWER_SCHEDULE=0 0 2 * * *  # 2 AM daily

# Manual update process
docker compose pull
docker compose up -d

# Rollback to previous version
docker compose down
docker tag service:latest service:backup
docker pull service:previous
docker compose up -d
```

## 🔧 Advanced Features

### Custom Service Definitions
```bash
# Add custom services to docker-compose.yml
services:
  custom-service:
    image: custom/image:latest
    container_name: custom-service
    environment:
      - PUID=${PUID}
      - PGID=${PGID}
      - TZ=${TZ}
    volumes:
      - ${CONFIG_ROOT}/custom:/config
      - ${DATA_ROOT}:/data
    ports:
      - "8999:8999"
    restart: unless-stopped
    networks:
      - homelab
```

### Backup Automation
```bash
# Automated backup script
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backup/hops"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Backup configurations
tar -czf "$BACKUP_DIR/config-$DATE.tar.gz" /opt/appdata

# Backup compose files
cp ~/hops/.env ~/hops/docker-compose.yml "$BACKUP_DIR/"

# Backup encrypted secrets
./lib/secrets.sh backup "$BACKUP_DIR/secrets-$DATE.enc"

# Clean old backups (keep 7 days)
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete
```

### Development & Testing
```bash
# Development setup
git clone https://github.com/skiercm/hops.git
cd hops

# Syntax validation
bash -n lib/*.sh
bash -n *.sh

# Test service definitions
./services-improved list
./services-improved generate jellyfin

# Test installation in VM/container
# Use test environment before production deployment
```

---

For installation guides, see [INSTALLATION.md](INSTALLATION.md).  
For service information, see [SERVICES.md](SERVICES.md).