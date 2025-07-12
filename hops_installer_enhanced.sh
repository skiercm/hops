#!/bin/bash

install_hops() {
    # Clear terminal at startup
    clear

    # Exit on any error
    set -e

    # Script version for update tracking
    local SCRIPT_VERSION="3.1.0"
    local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # --------------------------------------------
    # LOGGING SETUP
    # --------------------------------------------
    local LOG_DIR="/var/log/hops"
    local LOG_FILE="$LOG_DIR/homelab-setup-$(date +%Y%m%d-%H%M%S).log"
    mkdir -p "$LOG_DIR"
    touch "$LOG_FILE"

    log() {
        echo -e "$(date '+%Y-%m-%d %T') - $1" | tee -a "$LOG_FILE"
    }

    error_exit() {
        log "❌ ERROR: $1"
        log "❌ Installation failed. Check logs at: $LOG_FILE"
        exit 1
    }

    # Enhanced error handling with rollback
    DEPLOYMENT_STEPS_COMPLETED=()

    track_step() {
        DEPLOYMENT_STEPS_COMPLETED+=("$1")
        log "✅ Step completed: $1"
    }

    rollback_deployment() {
        log "🔄 Rolling back deployment..."
        
        for step in "${DEPLOYMENT_STEPS_COMPLETED[@]}"; do
            case "$step" in
                "containers_started")
                    log "🛑 Stopping containers..."
                    docker compose down --timeout 30 2>/dev/null || true
                    ;;
                "images_pulled")
                    log "🗑️ Removing pulled images..."
                    docker compose down --rmi all 2>/dev/null || true
                    ;;
                "directories_created")
                    log "📁 Cleaning up directories..."
                    [[ -n "$APPDATA_DIR" ]] && rm -rf "$APPDATA_DIR" 2>/dev/null || true
                    ;;
                "compose_generated")
                    log "📝 Removing compose file..."
                    [[ -f "docker-compose.yml" ]] && rm -f docker-compose.yml
                    ;;
            esac
        done
        
        log "🔄 Rollback completed"
    }

    error_exit_with_rollback() {
        log "❌ ERROR: $1"
        rollback_deployment
        log "❌ Installation failed and rolled back. Check logs at: $LOG_FILE"
        exit 1
    }

    # --------------------------------------------
    # HEADER
    # --------------------------------------------
    cat << "EOF"

  _    _  ____  ____  ____  
 | |  | ||  _ \|  _ \/ ___| 
 | |__| || |_) | |_) \___ \ 
 |  __  ||  __/|  __/ ___) |
 |_|  |_||_|   |_|   |____/ 

EOF
    echo -e "🚀 Homelab Orchestration Provisioning Script v${SCRIPT_VERSION}\n"
    log "🚀 Starting HOPS Deployment v${SCRIPT_VERSION}"

    # --------------------------------------------
    # SYSTEM REQUIREMENTS CHECK
    # --------------------------------------------
    check_system_requirements() {
        local MIN_RAM_GB=2
        local MIN_DISK_GB=10
        local MIN_CORES=2
        
        log "🔍 Checking system requirements..."
        
        # Check RAM
        local RAM_GB=$(free -g | awk '/^Mem:/{print $2}')
        if [[ $RAM_GB -lt $MIN_RAM_GB ]]; then
            error_exit "Insufficient RAM: ${RAM_GB}GB detected, ${MIN_RAM_GB}GB required"
        fi
        
        # Check disk space
        local DISK_AVAIL=$(df -BG --output=avail / | tail -n 1 | tr -d 'G')
        if [[ $DISK_AVAIL -lt $MIN_DISK_GB ]]; then
            error_exit "Insufficient disk space: ${DISK_AVAIL}GB available, ${MIN_DISK_GB}GB required"
        fi
        
        # Check CPU cores
        local CPU_CORES=$(nproc)
        if [[ $CPU_CORES -lt $MIN_CORES ]]; then
            log "⚠️ Low CPU cores: ${CPU_CORES} detected, ${MIN_CORES} recommended"
        fi
        
        log "✅ System meets minimum requirements (${RAM_GB}GB RAM, ${CPU_CORES} cores, ${DISK_AVAIL}GB disk)"
    }

    # --------------------------------------------
    # REQUIRED PACKAGES CHECK
    # --------------------------------------------
    check_required_packages() {
        local missing_packages=()
        local required_packages=("curl" "wget" "openssl" "lsof" "apache2-utils")
        
        log "📦 Checking required packages..."
        
        for package in "${required_packages[@]}"; do
            if ! command -v "${package%%-*}" &>/dev/null; then
                missing_packages+=("$package")
            fi
        done
        
        if [[ ${#missing_packages[@]} -gt 0 ]]; then
            log "📦 Installing missing packages: ${missing_packages[*]}"
            apt-get update && apt-get install -y "${missing_packages[@]}"
        fi
        
        log "✅ All required packages are installed"
    }

    # --------------------------------------------
    # ROOT CHECK
    # --------------------------------------------
    if [[ $EUID -ne 0 ]]; then
        error_exit "This script must be run as root or with sudo."
    fi

    # --------------------------------------------
    # OS DETECTION
    # --------------------------------------------
    detect_os() {
        if command -v lsb_release &>/dev/null; then
            OS_NAME=$(lsb_release -is)
            OS_VERSION=$(lsb_release -rs)
        else
            OS_NAME=$(grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
            OS_VERSION=$(grep '^VERSION_ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
        fi
        OS_NAME_LOWER=$(echo "$OS_NAME" | tr '[:upper:]' '[:lower:]')

        if [[ ! "$OS_NAME_LOWER" =~ ^(ubuntu|debian|linuxmint|mint)$ ]]; then
            error_exit "Unsupported OS: $OS_NAME Only Debian/Ubuntu/Mint supported"
        fi
        log "✅ Detected OS: $OS_NAME $OS_VERSION"
    }

    # --------------------------------------------
    # USER CONFIGURATION COLLECTION
    # --------------------------------------------
    collect_user_configuration() {
        log "🔧 Collecting user configuration..."
        
        # Get running user info
        if [[ -n "$SUDO_USER" ]]; then
            RUNNING_USER="$SUDO_USER"
            PUID=$(id -u "$SUDO_USER")
            PGID=$(id -g "$SUDO_USER")
        else
            RUNNING_USER="root"
            PUID=1000
            PGID=1000
            log "⚠️ Running as root, defaulting to PUID=1000, PGID=1000"
        fi
        
        # Timezone configuration
        echo -e "\n🌍 Timezone Configuration"
        echo "Current timezone: $(timedatectl show --property=Timezone --value 2>/dev/null || echo "Unknown")"
        echo -e "Keep current timezone? [Y/n]: "
        read -r keep_tz
        
        if [[ "$keep_tz" =~ ^[Nn]$ ]]; then
            echo -e "Enter timezone (e.g., America/New_York, Europe/London): "
            read -r user_timezone
            validate_timezone "$user_timezone"
            TIMEZONE="$user_timezone"
        else
            TIMEZONE=$(timedatectl show --property=Timezone --value 2>/dev/null || echo "America/New_York")
        fi
        
        # Directory configuration
        echo -e "\n📁 Directory Configuration"
        echo -e "Media directory [/mnt/media]: "
        read -r media_dir
        MEDIA_DIR="${media_dir:-/mnt/media}"
        
        echo -e "Application data directory [/opt/appdata]: "
        read -r appdata_dir
        APPDATA_DIR="${appdata_dir:-/opt/appdata}"
        
        # Create directories
        mkdir -p "$MEDIA_DIR"/{movies,tv,music,books,downloads}
        mkdir -p "$APPDATA_DIR"
        
        # Set ownership if not root
        if [[ "$RUNNING_USER" != "root" ]]; then
            chown -R "$PUID:$PGID" "$MEDIA_DIR" "$APPDATA_DIR" 2>/dev/null || true
        fi
        
        log "✅ User configuration collected"
        log "   User: $RUNNING_USER ($PUID:$PGID)"
        log "   Timezone: $TIMEZONE"
        log "   Media: $MEDIA_DIR"
        log "   AppData: $APPDATA_DIR"
    }

    # --------------------------------------------
    # VALIDATION FUNCTIONS
    # --------------------------------------------
    validate_timezone() {
        if ! timedatectl list-timezones | grep -qx "$1" 2>/dev/null; then
            log "⚠️ Timezone '$1' invalid, defaulting to 'America/New_York'"
            TIMEZONE="America/New_York"
        fi
    }

    validate_password() {
        local password="$1"
        local min_length="${2:-12}"
        
        if [[ -z "$password" ]]; then
            echo -e "\n🔐 Password must meet these requirements:"
            echo "   • Minimum $min_length characters"
            echo "   • At least one uppercase letter"
            echo "   • At least one lowercase letter"
            echo "   • At least one number"
            echo "   • At least one special character"
            return 3
        fi
        
        if [[ ${#password} -lt $min_length ]]; then
            return 1
        fi
        
        if [[ ! "$password" =~ [A-Z] ]] || [[ ! "$password" =~ [a-z] ]] || \
           [[ ! "$password" =~ [0-9] ]] || [[ ! "$password" =~ [^A-Za-z0-9] ]]; then
            return 2
        fi
        
        return 0
    }

    check_port() {
        local PORT=$1
        local SERVICE=$2
        if lsof -i :"$PORT" >/dev/null 2>&1; then
            local PROCESS=$(lsof -ti :"$PORT" | head -1)
            local PROCESS_NAME=$(ps -p "$PROCESS" -o comm= 2>/dev/null || echo "unknown")
            log "⚠️ Port $PORT is already in use by $PROCESS_NAME. $SERVICE may fail to start."
            return 1
        fi
        return 0
    }

    check_all_ports() {
        local SERVICES=("$@")
        local CONFLICTS=()
        
        # Source service definitions to get port mappings
        if [[ -f "$SCRIPT_DIR/hops_service_definitions.sh" ]]; then
            source "$SCRIPT_DIR/hops_service_definitions.sh"
        fi
        
        for svc in "${SERVICES[@]}"; do
            local ports=$(get_service_ports "$svc")
            for port in $ports; do
                if ! check_port "$port" "$svc"; then
                    CONFLICTS+=("Port $port ($svc)")
                fi
            done
        done
        
        if [[ ${#CONFLICTS[@]} -gt 0 ]]; then
            log "⚠️ Found ${#CONFLICTS[@]} port conflicts:"
            for conflict in "${CONFLICTS[@]}"; do
                log "   • $conflict"
            done
            
            echo -e "\n⚠️ Port conflicts detected! Continue anyway? (y/N): "
            read -r continue_choice
            if [[ ! "$continue_choice" =~ ^[Yy]$ ]]; then
                error_exit "Installation cancelled due to port conflicts."
            fi
            return 1
        fi
        return 0
    }

    # --------------------------------------------
    # DOCKER COMPOSE VERSION CHECK
    # --------------------------------------------
    check_docker_compose_version() {
        # Check for Docker Compose plugin (v2)
        if docker compose version &>/dev/null; then
            log "✅ Docker Compose plugin detected ($(docker compose version --short))"
            return 0
        fi
        
        # Check for standalone docker-compose (v1)
        if command -v docker-compose &>/dev/null; then
            log "⚠️ Found legacy docker-compose (v1). Installing Docker Compose plugin..."
            if ! apt-get install -y docker-compose-plugin 2>&1 | tee -a "$LOG_FILE"; then
                error_exit "Failed to install Docker Compose plugin."
            fi
            return 0
        fi
        
        # Neither found
        error_exit "No Docker Compose detected. Please install Docker first."
    }

    # --------------------------------------------
    # IMPROVED PASSWORD GENERATION
    # --------------------------------------------
    generate_secure_password() {
        local length="${1:-16}"
        local max_attempts=5
        local attempt=1
        
        while [[ $attempt -le $max_attempts ]]; do
            # Generate password with mixed case, numbers, and symbols
            local password=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-${length})
            
            # Ensure it meets complexity requirements
            if validate_password "$password" "$length"; then
                echo "$password"
                return 0
            fi
            
            ((attempt++))
        done
        
        # Fallback: construct a guaranteed compliant password
        local upper=$(tr -dc 'A-Z' < /dev/urandom | head -c2)
        local lower=$(tr -dc 'a-z' < /dev/urandom | head -c4)
        local digits=$(tr -dc '0-9' < /dev/urandom | head -c2)
        local symbols=$(tr -dc '!@#$%^&*' < /dev/urandom | head -c2)
        local remaining_length=$((length - 10))
        
        if [[ $remaining_length -gt 0 ]]; then
            local remaining=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c$remaining_length)
            echo "${upper}${lower}${digits}${symbols}${remaining}" | fold -w1 | shuf | tr -d '\n'
        else
            echo "${upper}${lower}${digits}${symbols}"
        fi
    }

    # --------------------------------------------
    # ENVIRONMENT FILE GENERATION
    # --------------------------------------------
    create_env_file() {
        local homelab_dir="$1"
        
        log "📝 Creating environment file..."
        
        cat > "$homelab_dir/.env" <<EOF
# HOPS Environment Configuration
# Generated on $(date)

# ==============================================
# CORE CONFIGURATION
# ==============================================

# User Configuration
PUID=$PUID
PGID=$PGID
TZ=$TIMEZONE

# Directory Configuration
DATA_ROOT=$MEDIA_DIR
CONFIG_ROOT=$APPDATA_DIR
HOMELAB_DIR=$homelab_dir

# Network Configuration
DOCKER_SUBNET=172.20.0.0/16

# ==============================================
# SECURITY & AUTHENTICATION
# ==============================================

# Default Passwords (CHANGE THESE IMMEDIATELY!)
DEFAULT_ADMIN_PASSWORD=$(generate_secure_password 16)
DEFAULT_DB_PASSWORD=$(generate_secure_password 20)

# Optional: Custom domain for reverse proxy
# DOMAIN=yourdomain.com

# Optional: Email for Let's Encrypt
# ACME_EMAIL=admin@yourdomain.com

# ==============================================
# SERVICE-SPECIFIC CONFIGURATION
# ==============================================

# Plex Configuration (Get token from: https://www.plex.tv/claim/)
PLEX_CLAIM_TOKEN=

# Watchtower Email Notifications (Optional)
WATCHTOWER_EMAIL_FROM=
WATCHTOWER_EMAIL_TO=
WATCHTOWER_EMAIL_SERVER=
WATCHTOWER_EMAIL_PORT=587
WATCHTOWER_EMAIL_USER=
WATCHTOWER_EMAIL_PASSWORD=

# Traefik Let's Encrypt Email
ACME_EMAIL=admin@localhost
EOF
        
        chmod 600 "$homelab_dir/.env"
        log "✅ Environment file created with secure permissions"
    }

    # --------------------------------------------
    # SERVICE SELECTION
    # --------------------------------------------
    select_services() {
        echo -e "\n📺 CORE MEDIA TOOLS"
        echo "1) Sonarr      2) Radarr      3) Lidarr      4) Readarr"
        echo "5) Bazarr      6) Prowlarr    7) Tdarr"

        echo -e "\n⬇️  DOWNLOAD CLIENTS"
        echo "8) NZBGet      9) SABnzbd     10) Transmission  11) qBittorrent"

        echo -e "\n🎞️  MEDIA SERVERS"
        echo "12) Plex       13) Jellyfin   14) Jellystat     15) Emby"

        echo -e "\n🎛️  REQUEST MANAGEMENT"
        echo "16) Overseerr  17) Jellyseerr 18) Ombi"

        echo -e "\n🔒 NETWORK & SECURITY"
        echo "19) Traefik    20) Nginx Proxy Manager  21) Authelia"

        echo -e "\n📈 MONITORING"
        echo "22) Portainer  23) Watchtower  24) Uptime Kuma"

        echo -e "\n📝 Select services (space-separated numbers, or 'all' for everything): "
        read -a service_choices

        declare -A SERVICE_MAP=(
            [1]="sonarr" [2]="radarr" [3]="lidarr" [4]="readarr"
            [5]="bazarr" [6]="prowlarr" [7]="tdarr" [8]="nzbget" 
            [9]="sabnzbd" [10]="transmission" [11]="qbittorrent"
            [12]="plex" [13]="jellyfin" [14]="jellystat" [15]="emby"
            [16]="overseerr" [17]="jellyseerr" [18]="ombi"
            [19]="traefik" [20]="nginx-proxy-manager" [21]="authelia"
            [22]="portainer" [23]="watchtower" [24]="uptime-kuma"
        )

        SERVICES=()
        if [[ "${service_choices[0]}" == "all" ]]; then
            SERVICES=($(printf '%s\n' "${SERVICE_MAP[@]}" | sort))
            log "🎯 Selected all services"
        else
            for choice in "${service_choices[@]}"; do
                [[ -n "${SERVICE_MAP[$choice]}" ]] && SERVICES+=("${SERVICE_MAP[$choice]}")
            done
        fi

        if [[ ${#SERVICES[@]} -eq 0 ]]; then
            error_exit "No valid services selected."
        fi

        log "✅ Selected services: ${SERVICES[*]}"

        # Check for service dependencies and conflicts
        check_service_dependencies
        check_service_conflicts
    }

    # --------------------------------------------
    # DEPENDENCY AND CONFLICT CHECKING
    # --------------------------------------------
    check_service_dependencies() {
        # Source service definitions for dependency resolution
        if [[ -f "$SCRIPT_DIR/hops_service_definitions.sh" ]]; then
            source "$SCRIPT_DIR/hops_service_definitions.sh"
            
            # Resolve dependencies
            local all_services=($(resolve_dependencies "${SERVICES[@]}"))
            local deps_added=()
            
            for service in "${all_services[@]}"; do
                if [[ ! " ${SERVICES[*]} " =~ " ${service} " ]]; then
                    deps_added+=("$service")
                fi
            done
            
            if [[ ${#deps_added[@]} -gt 0 ]]; then
                log "📦 Adding dependencies: ${deps_added[*]}"
                SERVICES=("${all_services[@]}")
            fi
        fi
        
        # Check if any *arr services are selected without Prowlarr
        local arr_services=(sonarr radarr lidarr readarr)
        local has_arr=false
        for arr in "${arr_services[@]}"; do
            if [[ "${SERVICES[*]}" =~ $arr ]]; then
                has_arr=true
                break
            fi
        done
        
        if [[ $has_arr == true ]] && [[ ! "${SERVICES[*]}" =~ prowlarr ]]; then
            echo -e "\n💡 Recommendation: You selected *arr services but not Prowlarr."
            echo "Prowlarr manages indexers for all *arr applications."
            echo -e "Add Prowlarr? [Y/n]: "
            read -r add_prowlarr
            if [[ ! "$add_prowlarr" =~ ^[Nn]$ ]]; then
                SERVICES+=("prowlarr")
                log "✅ Added Prowlarr"
            fi
        fi
    }

    check_service_conflicts() {
        local warnings=()
        
        # Check for multiple media servers
        local media_servers=(plex jellyfin emby)
        local selected_media_servers=()
        for server in "${media_servers[@]}"; do
            if [[ "${SERVICES[*]}" =~ $server ]]; then
                selected_media_servers+=("$server")
            fi
        done
        
        if [[ ${#selected_media_servers[@]} -gt 1 ]]; then
            warnings+=("Multiple media servers selected: ${selected_media_servers[*]}")
        fi
        
        # Check for multiple reverse proxies
        local reverse_proxies=(traefik nginx-proxy-manager)
        local selected_proxies=()
        for proxy in "${reverse_proxies[@]}"; do
            if [[ "${SERVICES[*]}" =~ $proxy ]]; then
                selected_proxies+=("$proxy")
            fi
        done
        
        if [[ ${#selected_proxies[@]} -gt 1 ]]; then
            warnings+=("Multiple reverse proxies selected: ${selected_proxies[*]} (may conflict on ports 80/443)")
        fi
        
        # Display warnings if any
        if [[ ${#warnings[@]} -gt 0 ]]; then
            log "⚠️ Configuration warnings:"
            for warning in "${warnings[@]}"; do
                log "   • $warning"
            done
            
            echo -e "\n⚠️ Continue with this configuration? [y/N]: "
            read -r continue_choice
            if [[ ! "$continue_choice" =~ ^[Yy]$ ]]; then
                log "🚫 Installation cancelled by user"
                exit 0
            fi
        fi
    }

    # --------------------------------------------
    # DOCKER COMPOSE FILE GENERATION
    # --------------------------------------------
    generate_docker_compose() {
        local HOMELAB_DIR="$HOME/homelab"
        mkdir -p "$HOMELAB_DIR"
        cd "$HOMELAB_DIR"

        if [[ -f docker-compose.yml ]]; then
            local BACKUP_FILE="docker-compose.yml.bak.$(date +%Y%m%d%H%M%S)"
            log "📝 Backing up existing compose file to $BACKUP_FILE"
            mv docker-compose.yml "$BACKUP_FILE"
        fi

        log "📝 Generating Docker Compose configuration..."
        create_env_file "$HOMELAB_DIR"

        # Source the service definitions
        if [[ -f "$SCRIPT_DIR/hops_service_definitions.sh" ]]; then
            source "$SCRIPT_DIR/hops_service_definitions.sh"
            
            # Export variables for service definitions
            export PUID PGID TIMEZONE MEDIA_DIR APPDATA_DIR
            
            # Generate complete compose file with all services
            generate_complete_compose "${SERVICES[@]}"
            track_step "compose_generated"
            
            # Create service-specific configurations
            create_service_configs "${SERVICES[@]}"
            
            log "✅ Generated Docker Compose with ${#SERVICES[@]} services"
        else
            error_exit "Service definitions file not found: $SCRIPT_DIR/hops_service_definitions.sh"
        fi

        # Create networks if they don't exist
        create_docker_networks
    }

    # --------------------------------------------
    # NETWORK CREATION
    # --------------------------------------------
    create_docker_networks() {
        log "🌐 Creating Docker networks..."
        
        # Create traefik network if it doesn't exist
        if ! docker network ls --format "{{.Name}}" | grep -q "^traefik$"; then
            if docker network create traefik 2>/dev/null; then
                log "✅ Created traefik network"
            else
                log "⚠️ Could not create traefik network (may already exist)"
            fi
        fi
    }

    # --------------------------------------------
    # ENHANCED DEPLOYMENT WITH ROLLBACK
    # --------------------------------------------
    deploy_services() {
        log "🚀 Starting deployment..."

        # Set up error trap
        trap 'error_exit_with_rollback "Deployment failed at step: ${BASH_COMMAND}"' ERR

        # Pre-deployment checks
        log "🔍 Running pre-deployment validation..."
        if ! docker info >/dev/null 2>&1; then
            error_exit_with_rollback "Docker daemon is not running or accessible"
        fi

        if ! docker compose config >/dev/null 2>&1; then
            error_exit_with_rollback "Generated docker-compose.yml is invalid"
        fi

        # Create required directories
        log "📁 Creating required directories..."
        for svc in "${SERVICES[@]}"; do
            mkdir -p "${APPDATA_DIR}/${svc}"
            chown -R "$PUID:$PGID" "${APPDATA_DIR}/${svc}" 2>/dev/null || true
        done
        track_step "directories_created"

        # Pull images with retry logic
        log "📥 Pulling container images..."
        local PULL_RETRIES=3
        for attempt in $(seq 1 $PULL_RETRIES); do
            if docker compose pull 2>&1 | tee -a "$LOG_FILE"; then
                track_step "images_pulled"
                break
            elif [[ $attempt -eq $PULL_RETRIES ]]; then
                error_exit_with_rollback "Failed to pull images after $PULL_RETRIES attempts"
            else
                log "⚠️ Pull attempt $attempt failed, retrying in 10 seconds..."
                sleep 10
            fi
        done

        # Start containers
        log "🔄 Starting containers..."
        if docker compose up -d 2>&1 | tee -a "$LOG_FILE"; then
            track_step "containers_started"
        else
            log "❌ Some containers failed to start. Checking status..."
            docker compose ps
            error_exit_with_rollback "Container startup failed"
        fi

        # Clear trap on success
        trap - ERR
    }

    # --------------------------------------------
    # ENHANCED SERVICE VERIFICATION
    # --------------------------------------------
    verify_service_health() {
        local service_name="$1"
        local max_wait=300  # 5 minutes
        local interval=10
        
        log "🔍 Waiting for $service_name to be healthy..."
        
        for ((i=0; i<max_wait; i+=interval)); do
            local health=$(docker inspect --format='{{.State.Health.Status}}' "$service_name" 2>/dev/null || echo "none")
            
            case "$health" in
                "healthy")
                    log "✅ $service_name is healthy"
                    return 0
                    ;;
                "starting")
                    log "⏳ $service_name is starting... (${i}s elapsed)"
                    ;;
                "unhealthy")
                    log "❌ $service_name is unhealthy"
                    return 1
                    ;;
                "none")
                    # No health check defined, check if container is running
                    local state=$(docker inspect --format='{{.State.Status}}' "$service_name" 2>/dev/null || echo "unknown")
                    if [[ "$state" == "running" ]]; then
                        log "✅ $service_name is running (no health check)"
                        return 0
                    fi
                    ;;
            esac
            
            sleep "$interval"
        done
        
        log "⚠️ $service_name health check timed out"
        return 1
    }

    verify_services() {
        log "🩺 Verifying service health..."

        local FAILED_SERVICES=()
        for svc in "${SERVICES[@]}"; do
            if docker ps --format "{{.Names}}" | grep -qi "^${svc}$"; then
                if ! verify_service_health "$svc"; then
                    FAILED_SERVICES+=("$svc")
                fi
            else
                log "❌ $svc container not found"
                FAILED_SERVICES+=("$svc")
            fi
        done

        if [[ ${#FAILED_SERVICES[@]} -gt 0 ]]; then
            log "⚠️ Services requiring attention:"
            for svc in "${FAILED_SERVICES[@]}"; do
                log "   • $svc - Check logs: docker logs $svc"
            done
        else
            log "✅ All services are healthy"
        fi
    }

    # --------------------------------------------
    # SECURITY SETUP
    # --------------------------------------------
    setup_security() {
        log "🔒 Applying security hardening..."
        
        # Secure sensitive files
        find "$APPDATA_DIR" -name "*.env" -exec chmod 600 {} \; 2>/dev/null || true
        find "$APPDATA_DIR" -name "*.key" -exec chmod 600 {} \; 2>/dev/null || true
        find "$APPDATA_DIR" -name "*.pem" -exec chmod 600 {} \; 2>/dev/null || true
        
        # Set secure permissions on homelab directory
        chmod 750 "$HOME/homelab"
        
        log "✅ Security hardening applied"
    }

    setup_firewall() {
        if command -v ufw &>/dev/null; then
            log "🔥 Configuring UFW firewall..."
            
            # Don't reset if already configured
            if ! ufw status | grep -q "Status: active"; then
                ufw --force reset >/dev/null 2>&1
                ufw default deny incoming >/dev/null 2>&1
                ufw default allow outgoing >/dev/null 2>&1
                
                # Allow SSH
                ufw allow ssh >/dev/null 2>&1
            fi
            
            # Allow service ports based on selection
            if [[ -f "$SCRIPT_DIR/hops_service_definitions.sh" ]]; then
                source "$SCRIPT_DIR/hops_service_definitions.sh"
                
                for svc in "${SERVICES[@]}"; do
                    local ports=$(get_service_ports "$svc")
                    for port in $ports; do
                        # Skip UDP ports and handle TCP/UDP notation
                        if [[ "$port" =~ /udp$ ]]; then
                            local port_num="${port%/udp}"
                            ufw allow "$port_num/udp" comment "$svc" >/dev/null 2>&1
                        else
                            local port_num="${port%/tcp}"
                            ufw allow "$port_num/tcp" comment "$svc" >/dev/null 2>&1
                        fi
                    done
                done
            fi
            
            ufw --force enable >/dev/null 2>&1
            log "✅ Firewall configured"
        else
            log "ℹ️ UFW not available, skipping firewall configuration"
        fi
    }

    # --------------------------------------------
    # MAIN INSTALLATION FLOW
    # --------------------------------------------
    check_system_requirements
    detect_os
    check_required_packages
    collect_user_configuration
    select_services
    check_all_ports "${SERVICES[@]}"

    # Install dependencies
    log "📦 Installing prerequisites..."
    if ! apt-get update &>/dev/null; then
        error_exit "Failed to update package lists. Check your internet connection."
    fi

    local REQUIRED_PACKAGES="ca-certificates curl gnupg lsb-release lsof ufw fail2ban openssl apache2-utils"
    if ! apt-get install -y $REQUIRED_PACKAGES 2>&1 | tee -a "$LOG_FILE"; then
        error_exit "Failed to install required packages."
    fi

    # Install Docker if not present
    if ! command -v docker &>/dev/null; then
        log "🐳 Installing Docker..."
        if ! curl -fsSL https://get.docker.com | sh 2>&1 | tee -a "$LOG_FILE"; then
            error_exit "Failed to install Docker."
        fi
        
        # Add user to docker group
        if [[ -n "$SUDO_USER" ]]; then
            usermod -aG docker "$SUDO_USER"
            log "✅ Added $SUDO_USER to docker group (restart session to take effect)"
        fi
    else
        log "✅ Docker already installed ($(docker --version))"
    fi

    check_docker_compose_version

    # Ensure Docker daemon is running
    if ! systemctl is-active --quiet docker; then
        log "🔄 Starting Docker daemon..."
        systemctl start docker || error_exit "Failed to start Docker daemon"
        systemctl enable docker || log "⚠️ Could not enable Docker service"
    fi

    setup_firewall
    generate_docker_compose
    deploy_services
    setup_security
    verify_services

    # --------------------------------------------
    # FINAL SUMMARY
    # --------------------------------------------
    echo -e "\n🎉 HOPS Enhanced Deployment Complete!"
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    log "📋 Deployment Summary:"
    echo -e "\n📂 Configuration:"
    echo "   • Homelab Directory: $HOME/homelab"
    echo "   • Application Data: $APPDATA_DIR"
    echo "   • Media Directory: $MEDIA_DIR"
    echo "   • User/Group: $RUNNING_USER ($PUID:$PGID)"
    echo "   • Timezone: $TIMEZONE"
    echo "   • Log File: $LOG_FILE"

    echo -e "\n🔐 Security:"
    echo "   • Generated secure passwords (see .env file)"
    echo "   • Firewall configured with service-specific rules"
    echo "   • File permissions hardened"

    echo -e "\n📱 Deployed Services:"
    local service_count=0
    for svc in "${SERVICES[@]}"; do
        if [[ -f "$SCRIPT_DIR/hops_service_definitions.sh" ]]; then
            source "$SCRIPT_DIR/hops_service_definitions.sh"
            local ports=$(get_service_ports "$svc")
            local main_port=$(echo $ports | cut -d' ' -f1)
            if [[ -n "$main_port" ]]; then
                echo "   • $svc: http://$(hostname -I | awk '{print $1}'):$main_port"
                ((service_count++))
            fi
        fi
    done

    echo -e "\n🔧 Management Commands:"
    echo "   • View all logs: docker compose logs -f"
    echo "   • View service logs: docker compose logs -f [service]"
    echo "   • Restart service: docker compose restart [service]"
    echo "   • Stop services: docker compose down"
    echo "   • Start services: docker compose up -d"
    echo "   • Update services: docker compose pull && docker compose up -d"

    echo -e "\n📚 Next Steps:"
    echo "   1. Access services using the URLs above"
    echo "   2. Change default passwords from .env file"
    echo "   3. Configure services according to your needs"
    echo "   4. Set up your media library paths"

    echo -e "\n📋 Logs and troubleshooting: $LOG_FILE"
    echo -e "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    log "🎉 HOPS Enhanced deployment completed successfully!"
    return 0
}