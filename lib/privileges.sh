#!/bin/bash

# HOPS - Privilege Management System
# Split operations into privileged and non-privileged components
# Version: 3.1.0-beta

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Operations that require root privileges
PRIVILEGED_OPERATIONS=(
    "install_docker"
    "configure_firewall"
    "create_system_directories"
    "install_packages"
    "configure_systemd"
    "setup_secrets_directory"
    "modify_system_files"
)

# Operations that can run as regular user
NON_PRIVILEGED_OPERATIONS=(
    "generate_docker_compose"
    "pull_docker_images"
    "start_containers"
    "stop_containers"
    "view_logs"
    "check_service_status"
    "validate_configuration"
    "backup_user_data"
)

# Check if operation requires privileges
requires_privileges() {
    local operation="$1"
    
    for priv_op in "${PRIVILEGED_OPERATIONS[@]}"; do
        if [[ "$operation" == "$priv_op" ]]; then
            return 0
        fi
    done
    
    return 1
}

# Check if operation can run as regular user
can_run_as_user() {
    local operation="$1"
    
    for user_op in "${NON_PRIVILEGED_OPERATIONS[@]}"; do
        if [[ "$operation" == "$user_op" ]]; then
            return 0
        fi
    done
    
    return 1
}

# Get current user information
get_current_user_info() {
    local -A user_info
    
    if [[ -n "$SUDO_USER" ]]; then
        user_info["username"]="$SUDO_USER"
        user_info["uid"]=$(id -u "$SUDO_USER")
        user_info["gid"]=$(id -g "$SUDO_USER")
        user_info["home"]=$(eval echo "~$SUDO_USER")
        user_info["is_sudo"]="true"
    else
        user_info["username"]="$USER"
        user_info["uid"]=$(id -u)
        user_info["gid"]=$(id -g)
        user_info["home"]="$HOME"
        user_info["is_sudo"]="false"
    fi
    
    # Return as key=value pairs
    for key in "${!user_info[@]}"; do
        echo "${key}=${user_info[$key]}"
    done
}

# Drop privileges to regular user
drop_privileges() {
    local command="$1"
    shift
    local args=("$@")
    
    if [[ $EUID -ne 0 ]]; then
        debug "Already running as non-root user"
        exec "$command" "${args[@]}"
        return $?
    fi
    
    if [[ -z "$SUDO_USER" ]]; then
        error_exit "Cannot drop privileges: SUDO_USER not set"
    fi
    
    local user_info
    user_info=$(get_current_user_info)
    
    local uid=$(echo "$user_info" | grep "uid=" | cut -d= -f2)
    local gid=$(echo "$user_info" | grep "gid=" | cut -d= -f2)
    local home=$(echo "$user_info" | grep "home=" | cut -d= -f2)
    
    debug "Dropping privileges to user: $SUDO_USER (uid=$uid, gid=$gid)"
    
    # Set environment variables for the user
    local env_vars=(
        "HOME=$home"
        "USER=$SUDO_USER"
        "LOGNAME=$SUDO_USER"
        "PATH=/usr/local/bin:/usr/bin:/bin"
    )
    
    # Execute command as user
    sudo -u "$SUDO_USER" env "${env_vars[@]}" "$command" "${args[@]}"
}

# Run operation with appropriate privileges
run_with_privileges() {
    local operation="$1"
    local command="$2"
    shift 2
    local args=("$@")
    
    if requires_privileges "$operation"; then
        debug "Operation '$operation' requires root privileges"
        
        if [[ $EUID -ne 0 ]]; then
            error_exit "Operation '$operation' requires root privileges. Please run with sudo."
        fi
        
        # Run as root
        exec "$command" "${args[@]}"
    elif can_run_as_user "$operation"; then
        debug "Operation '$operation' can run as regular user"
        
        if [[ $EUID -eq 0 ]]; then
            # Drop privileges
            drop_privileges "$command" "${args[@]}"
        else
            # Run as current user
            exec "$command" "${args[@]}"
        fi
    else
        error_exit "Unknown operation: $operation"
    fi
}

# Create privileged setup script
create_privileged_setup() {
    local setup_script="$1"
    
    cat > "$setup_script" << 'EOF'
#!/bin/bash

# HOPS Privileged Setup Script
# This script handles operations that require root privileges
# Version: 3.1.0-beta

set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/system.sh"
source "$SCRIPT_DIR/lib/security.sh"

# Initialize logging
setup_logging "privileged-setup"

# Check root privileges
check_root

# Install Docker if not present
install_docker() {
    info "🐳 Installing Docker..."
    
    if command_exists docker; then
        success "Docker already installed"
        return 0
    fi
    
    # Update package index
    apt-get update
    
    # Install prerequisites
    apt-get install -y \
        ca-certificates \
        curl \
        gnupg \
        lsb-release
    
    # Add Docker GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Add Docker repository with proper Ubuntu codename detection for Linux Mint
    local ubuntu_codename
    if [[ "$(lsb_release -is)" == "Linuxmint" ]]; then
        # Linux Mint provides UBUNTU_CODENAME in /etc/os-release
        if [[ -f /etc/os-release ]]; then
            ubuntu_codename=$(grep '^UBUNTU_CODENAME=' /etc/os-release | cut -d= -f2)
        fi
        
        # Fallback to version mapping if UBUNTU_CODENAME not found
        if [[ -z "$ubuntu_codename" ]]; then
            case "$(lsb_release -rs)" in
                "22"|"22.1"|"22.2"|"22.3")
                    ubuntu_codename="noble"  # Ubuntu 24.04
                    ;;
                "21"|"21.1"|"21.2"|"21.3")
                    ubuntu_codename="jammy"  # Ubuntu 22.04
                    ;;
                "20"|"20.1"|"20.2"|"20.3")
                    ubuntu_codename="focal"  # Ubuntu 20.04
                    ;;
                *)
                    ubuntu_codename="noble"  # Default to latest LTS
                    ;;
            esac
        fi
    else
        ubuntu_codename=$(lsb_release -cs)
    fi
    
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $ubuntu_codename stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Update package index with Docker packages
    apt-get update
    
    # Install Docker
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Start and enable Docker service
    systemctl start docker
    systemctl enable docker
    
    success "Docker installed successfully"
}

# Configure firewall
configure_firewall() {
    info "🔥 Configuring firewall..."
    
    # Install UFW if not present
    if ! command_exists ufw; then
        apt-get update
        apt-get install -y ufw
    fi
    
    # Reset firewall to defaults
    ufw --force reset
    
    # Set default policies
    ufw default deny incoming
    ufw default allow outgoing
    
    # Allow SSH (prevent lockout)
    ufw allow ssh
    
    # Allow HTTP and HTTPS
    ufw allow 80/tcp
    ufw allow 443/tcp
    
    # Enable firewall
    ufw --force enable
    
    success "Firewall configured successfully"
}

# Create system directories
create_system_directories() {
    info "📁 Creating system directories..."
    
    local directories=(
        "/opt/appdata"
        "/mnt/media"
        "/mnt/media/movies"
        "/mnt/media/tv"
        "/mnt/media/music"
        "/mnt/media/downloads"
        "/var/log/hops"
    )
    
    for dir in "${directories[@]}"; do
        if mkdir -p "$dir"; then
            success "Created directory: $dir"
        else
            error_exit "Failed to create directory: $dir"
        fi
    done
    
    # Set ownership to the user who ran sudo
    if [[ -n "$SUDO_USER" ]]; then
        local user_info
        user_info=$(get_user_info)
        
        local uid=$(echo "$user_info" | grep "uid=" | cut -d= -f2)
        local gid=$(echo "$user_info" | grep "gid=" | cut -d= -f2)
        
        chown -R "$uid:$gid" /opt/appdata /mnt/media
        success "Set ownership of directories to $SUDO_USER"
    fi
}

# Add user to docker group
add_user_to_docker_group() {
    if [[ -z "$SUDO_USER" ]]; then
        warning "No SUDO_USER set, skipping docker group addition"
        return 0
    fi
    
    info "👥 Adding user to docker group..."
    
    if usermod -aG docker "$SUDO_USER"; then
        success "User $SUDO_USER added to docker group"
        warning "User must log out and back in for group changes to take effect"
    else
        error_exit "Failed to add user to docker group"
    fi
}

# Install required packages
install_packages() {
    info "📦 Installing required packages..."
    
    apt-get update
    
    local packages=(
        "curl"
        "wget"
        "git"
        "jq"
        "htop"
        "tree"
        "unzip"
        "gnupg"
        "software-properties-common"
        "apt-transport-https"
        "ca-certificates"
        "lsb-release"
    )
    
    for package in "${packages[@]}"; do
        if apt-get install -y "$package"; then
            success "Installed package: $package"
        else
            warning "Failed to install package: $package"
        fi
    done
}

# Setup secrets directory
setup_secrets_directory() {
    info "🔐 Setting up secrets directory..."
    
    local secrets_dir="/etc/hops/secrets"
    
    if mkdir -p "$secrets_dir"; then
        chmod 700 "$secrets_dir"
        success "Secrets directory created: $secrets_dir"
    else
        error_exit "Failed to create secrets directory"
    fi
}

# Configure system settings
configure_system() {
    info "⚙️ Configuring system settings..."
    
    # Set timezone if not already set
    if [[ -n "$TZ" ]]; then
        timedatectl set-timezone "$TZ" 2>/dev/null || true
    fi
    
    # Enable IP forwarding for Docker
    echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf
    sysctl -p /etc/sysctl.conf
    
    success "System configuration completed"
}

# Main privileged setup
main() {
    info "🚀 Starting privileged setup..."
    
    # System checks
    detect_os
    check_system_requirements
    
    # Install packages
    install_packages
    
    # Install Docker
    install_docker
    
    # Configure firewall
    configure_firewall
    
    # Create directories
    create_system_directories
    
    # Add user to docker group
    add_user_to_docker_group
    
    # Setup secrets
    setup_secrets_directory
    
    # Configure system
    configure_system
    
    success "Privileged setup completed successfully"
    success "Please log out and back in for group changes to take effect"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
EOF
    
    chmod +x "$setup_script"
    success "Privileged setup script created: $setup_script"
}

# Create non-privileged user script
create_user_script() {
    local user_script="$1"
    
    cat > "$user_script" << 'EOF'
#!/bin/bash

# HOPS User Script
# This script handles operations that can run as regular user
# Version: 3.1.0-beta

set -e

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
source "$SCRIPT_DIR/lib/docker.sh"
source "$SCRIPT_DIR/lib/validation.sh"

# Initialize logging
setup_logging "user-operations"

# Check if user is in docker group
check_docker_access() {
    if ! groups "\$USER" | grep -q docker; then
        error_exit "User not in docker group. Please run the privileged setup first and log out/in."
    fi
    
    if ! docker info >/dev/null 2>&1; then
        error_exit "Cannot access Docker daemon. Please ensure Docker is running."
    fi
}

# Generate Docker Compose configuration
generate_docker_compose() {
    local services=("$@")
    local compose_file="$HOME/hops/docker-compose.yml"
    
    info "📝 Generating Docker Compose configuration..."
    
    # Create homelab directory
    mkdir -p "$HOME/hops"
    
    # Generate compose file header
    cat > "$compose_file" << EOF
services:
EOF
    
    # Generate service definitions
    for service in "${services[@]}"; do
        if "$SCRIPT_DIR/services-improved" generate "$service" >> "$compose_file"; then
            success "Added service: $service"
        else
            error_exit "Failed to generate service definition for: $service"
        fi
    done
    
    # Add networks section
    cat >> "$compose_file" << EOF

networks:
  homelab:
    driver: bridge
  traefik:
    driver: bridge
  database:
    driver: bridge
EOF
    
    success "Docker Compose configuration generated: $compose_file"
}

# Deploy services
deploy_services() {
    local compose_file="$HOME/hops/docker-compose.yml"
    
    if [[ ! -f "$compose_file" ]]; then
        error_exit "Docker Compose file not found: $compose_file"
    fi
    
    info "🚀 Deploying services..."
    
    cd "$HOME/hops"
    
    # Pull images
    if docker compose pull; then
        success "Docker images pulled successfully"
    else
        error_exit "Failed to pull Docker images"
    fi
    
    # Start services
    if docker compose up -d; then
        success "Services deployed successfully"
    else
        error_exit "Failed to deploy services"
    fi
}

# Stop services
stop_services() {
    local compose_file="$HOME/hops/docker-compose.yml"
    
    if [[ ! -f "$compose_file" ]]; then
        error_exit "Docker Compose file not found: $compose_file"
    fi
    
    info "🛑 Stopping services..."
    
    cd "$HOME/hops"
    
    if docker compose down; then
        success "Services stopped successfully"
    else
        error_exit "Failed to stop services"
    fi
}

# Show service status
show_service_status() {
    local compose_file="$HOME/hops/docker-compose.yml"
    
    if [[ ! -f "$compose_file" ]]; then
        error_exit "Docker Compose file not found: $compose_file"
    fi
    
    info "📊 Service status:"
    
    cd "$HOME/hops"
    docker compose ps
}

# Main user operations
main() {
    local action="$1"
    shift
    
    # Check Docker access
    check_docker_access
    
    case "$action" in
        "generate")
            if [[ $# -eq 0 ]]; then
                error_exit "Usage: $0 generate <service1> [service2] ..."
            fi
            generate_docker_compose "$@"
            ;;
        
        "deploy")
            deploy_services
            ;;
        
        "stop")
            stop_services
            ;;
        
        "status")
            show_service_status
            ;;
        
        "logs")
            if [[ $# -eq 0 ]]; then
                error_exit "Usage: $0 logs <service_name>"
            fi
            cd "$HOME/hops"
            docker compose logs -f "$1"
            ;;
        
        *)
            error_exit "Unknown action: $action"
            ;;
    esac
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
EOF
    
    chmod +x "$user_script"
    success "User script created: $user_script"

# Create installation wrapper
create_installation_wrapper() {
    local wrapper_script="$1"
    
    cat > "$wrapper_script" << 'EOF'
#!/bin/bash

# HOPS Installation Wrapper
# Orchestrates privileged and non-privileged installation steps
# Version: 3.1.0-beta

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"

# Initialize logging
setup_logging "installation-wrapper"

# Show header
show_hops_header "3.1.0" "Installation Wrapper"

# Check if we're running as root
if [[ $EUID -eq 0 ]]; then
    if [[ -z "$SUDO_USER" ]]; then
        error_exit "Please run with sudo, not as root directly"
    fi
else
    error_exit "This script must be run with sudo"
fi

# Phase 1: Privileged setup
info "📋 Phase 1: Privileged setup (requires root)"
if "$SCRIPT_DIR/privileged-setup"; then
    success "Privileged setup completed"
else
    error_exit "Privileged setup failed"
fi

# Phase 2: User setup
info "📋 Phase 2: User setup (running as $SUDO_USER)"

# Drop privileges and run user setup
sudo -u "$SUDO_USER" bash << 'USERSCRIPT'
cd "$HOME"
echo "Running as user: $(whoami)"

# Interactive service selection
echo "Select services to install:"
echo "1) Media Server Stack (Jellyfin, Sonarr, Radarr, Prowlarr)"
echo "2) Download Client Stack (qBittorrent, Transmission)"
echo "3) Monitoring Stack (Portainer, Uptime Kuma)"
echo "4) Custom selection"

read -p "Enter your choice (1-4): " choice

case "$choice" in
    1)
        services=("jellyfin" "sonarr" "radarr" "prowlarr")
        ;;
    2)
        services=("qbittorrent" "transmission")
        ;;
    3)
        services=("portainer" "uptime-kuma")
        ;;
    4)
        echo "Available services:"
        "$SCRIPT_DIR/services-improved" list
        read -p "Enter service names (space-separated): " -a services
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

# Generate and deploy
if "$SCRIPT_DIR/user-operations" generate "${services[@]}"; then
    echo "Configuration generated successfully"
    
    if "$SCRIPT_DIR/user-operations" deploy; then
        echo "Services deployed successfully"
    else
        echo "Deployment failed"
        exit 1
    fi
else
    echo "Configuration generation failed"
    exit 1
fi
USERSCRIPT

success "Installation completed successfully"
success "Services are now running. Check status with: ./user-operations status"
EOF
    
    chmod +x "$wrapper_script"
    success "Installation wrapper created: $wrapper_script"
}

# Main function
main() {
    local action="$1"
    shift
    
    case "$action" in
        "create-setup")
            create_privileged_setup "$1"
            ;;
        
        "create-user")
            create_user_script "$1"
            ;;
        
        "create-wrapper")
            create_installation_wrapper "$1"
            ;;
        
        "create-all")
            create_privileged_setup "privileged-setup"
            create_user_script "user-operations"
            create_installation_wrapper "setup"
            ;;
        
        "run")
            local operation="$1"
            local command="$2"
            shift 2
            run_with_privileges "$operation" "$command" "$@"
            ;;
        
        "help"|"--help"|"-h")
            cat <<EOF
HOPS Privilege Management System

Usage: $0 <action> [options]

Actions:
  create-setup <file>     Create privileged setup script
  create-user <file>      Create non-privileged user script
  create-wrapper <file>   Create installation wrapper
  create-all              Create all scripts
  run <op> <cmd> [args]   Run operation with appropriate privileges
  help                    Show this help message

Examples:
  $0 create-all
  $0 run install_docker /usr/bin/apt-get install docker-ce
  $0 run generate_docker_compose ./compose-gen.sh

EOF
            ;;
        
        *)
            error_exit "Unknown action: $action. Use 'help' for usage information."
            ;;
    esac
}

# If script is run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_logging "privileges"
    main "$@"
fi