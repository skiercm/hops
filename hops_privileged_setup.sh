#!/bin/bash

# HOPS Privileged Setup Script
# This script handles operations that require root privileges
# Version: 3.1.0

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
    
    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
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