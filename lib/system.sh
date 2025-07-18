#!/bin/bash

# HOPS - System Validation Functions
# Functions for system checks, OS detection, and requirements validation
# Version: 3.1.0

# Source common functions
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$LIB_DIR/common.sh"

# Global variables for system info
OS_NAME=""
OS_VERSION=""
OS_NAME_LOWER=""

# Detect operating system
detect_os() {
    info "🔍 Detecting operating system..."
    
    # Check if we're on macOS
    if [[ "$(uname -s)" == "Darwin" ]]; then
        OS_NAME="macOS"
        OS_VERSION=$(sw_vers -productVersion)
        OS_NAME_LOWER="macos"
        success "Detected supported OS: $OS_NAME $OS_VERSION"
        return 0
    fi
    
    # Linux detection
    if command_exists lsb_release; then
        OS_NAME=$(lsb_release -is)
        OS_VERSION=$(lsb_release -rs)
    elif [[ -f /etc/os-release ]]; then
        OS_NAME=$(grep '^ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
        OS_VERSION=$(grep '^VERSION_ID=' /etc/os-release | cut -d= -f2 | tr -d '"')
    else
        error_exit "Unable to detect operating system"
    fi
    
    OS_NAME_LOWER=$(echo "$OS_NAME" | tr '[:upper:]' '[:lower:]')
    
    # Validate supported OS
    case "$OS_NAME_LOWER" in
        ubuntu|debian|linuxmint|mint)
            success "Detected supported OS: $OS_NAME $OS_VERSION"
            ;;
        *)
            error_exit "Unsupported OS: $OS_NAME $OS_VERSION. Only Ubuntu/Debian/Linux Mint/macOS are supported."
            ;;
    esac
}

# Check system requirements
check_system_requirements() {
    local min_ram_gb=${1:-2}
    local min_disk_gb=${2:-10}
    local target_dir="${3:-/}"
    
    info "🔍 Checking system requirements..."
    
    # Check architecture
    local arch=$(uname -m)
    if [[ "$OS_NAME_LOWER" == "macos" ]]; then
        # macOS supports both x86_64 and arm64 (Apple Silicon)
        if [[ "$arch" != "x86_64" && "$arch" != "arm64" ]]; then
            error_exit "Unsupported architecture: $arch. Only x86_64 and arm64 are supported on macOS."
        fi
    else
        # Linux only supports x86_64
        if [[ "$arch" != "x86_64" ]]; then
            error_exit "Unsupported architecture: $arch. Only x86_64 is supported."
        fi
    fi
    
    # Check RAM
    local ram_gb
    if [[ "$OS_NAME_LOWER" == "macos" ]]; then
        # macOS memory check
        ram_gb=$(sysctl -n hw.memsize | awk '{print int($1/1024/1024/1024)}')
    elif command_exists free; then
        ram_gb=$(free -g | awk '/^Mem:/{print $2}')
    else
        ram_gb=$(awk '/MemTotal/ {print int($2/1024/1024)}' /proc/meminfo)
    fi
    
    if [[ $ram_gb -lt $min_ram_gb ]]; then
        error_exit "Insufficient RAM: ${ram_gb}GB detected, ${min_ram_gb}GB required"
    fi
    
    # Check disk space
    local disk_avail_gb
    if [[ "$OS_NAME_LOWER" == "macos" ]]; then
        # macOS disk space check
        disk_avail_gb=$(df -g "$target_dir" | tail -n 1 | awk '{print $4}')
    elif command_exists df; then
        disk_avail_gb=$(df -BG --output=avail "$target_dir" | tail -n 1 | tr -d 'G')
    else
        error_exit "Unable to check disk space - 'df' command not available"
    fi
    
    if [[ $disk_avail_gb -lt $min_disk_gb ]]; then
        error_exit "Insufficient disk space: ${disk_avail_gb}GB available in $target_dir, ${min_disk_gb}GB required"
    fi
    
    # Check CPU cores
    local cpu_cores
    if [[ "$OS_NAME_LOWER" == "macos" ]]; then
        cpu_cores=$(sysctl -n hw.ncpu)
    else
        cpu_cores=$(nproc)
    fi
    
    if [[ $cpu_cores -lt 2 ]]; then
        warning "Only ${cpu_cores} CPU core(s) detected. 2+ cores recommended for optimal performance."
    fi
    
    success "System requirements met: ${ram_gb}GB RAM, ${disk_avail_gb}GB disk space, ${cpu_cores} CPU cores"
}

# Check if running in a container
check_container_environment() {
    if [[ -f /.dockerenv ]] || grep -q 'container=docker' /proc/1/environ 2>/dev/null; then
        warning "Running inside a container. Some features may not work correctly."
        return 0
    fi
    return 1
}

# Check internet connectivity
check_internet() {
    local test_urls=(
        "google.com"
        "github.com"
        "docker.com"
    )
    
    info "🌐 Checking internet connectivity..."
    
    for url in "${test_urls[@]}"; do
        if ping -c 1 -W 5 "$url" >/dev/null 2>&1; then
            success "Internet connectivity verified"
            return 0
        fi
    done
    
    error_exit "No internet connectivity detected. Please check your network connection."
}

# Check Docker requirements
check_docker_requirements() {
    info "🐳 Checking Docker requirements..."
    
    # Check if Docker is installed
    if ! command_exists docker; then
        warning "Docker not installed. Will be installed automatically."
        return 1
    fi
    
    # Check if Docker daemon is running
    if ! docker info >/dev/null 2>&1; then
        warning "Docker daemon not running. Will be started automatically."
        return 1
    fi
    
    # Check Docker version
    local docker_version=$(docker --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
    local min_version="20.10.0"
    
    if ! version_compare "$docker_version" "$min_version"; then
        error_exit "Docker version $docker_version is too old. Minimum required: $min_version"
    fi
    
    # Check Docker Compose
    if ! docker compose version >/dev/null 2>&1; then
        error_exit "Docker Compose not available. Please install Docker Compose v2+"
    fi
    
    success "Docker requirements met"
    return 0
}

# Compare version strings (returns 0 if version1 >= version2)
version_compare() {
    local version1="$1"
    local version2="$2"
    
    # Convert versions to arrays
    local IFS='.'
    local -a ver1=($version1)
    local -a ver2=($version2)
    
    # Compare each component
    for i in {0..2}; do
        local v1=${ver1[$i]:-0}
        local v2=${ver2[$i]:-0}
        
        if [[ $v1 -gt $v2 ]]; then
            return 0
        elif [[ $v1 -lt $v2 ]]; then
            return 1
        fi
    done
    
    return 0
}

# Check if user has sudo privileges
check_sudo() {
    if [[ $EUID -eq 0 ]]; then
        return 0
    fi
    
    if ! sudo -n true 2>/dev/null; then
        error_exit "This script requires sudo privileges. Please run with sudo or as root."
    fi
    
    return 0
}

# Get system timezone
get_system_timezone() {
    if [[ "$OS_NAME_LOWER" == "macos" ]]; then
        # macOS timezone detection
        readlink /etc/localtime | sed 's|/var/db/timezone/zoneinfo/||' 2>/dev/null || \
        ls -la /etc/localtime | awk '{print $NF}' | sed 's|/var/db/timezone/zoneinfo/||' 2>/dev/null || \
        echo "UTC"
    elif [[ -f /etc/timezone ]]; then
        cat /etc/timezone
    elif [[ -L /etc/localtime ]]; then
        readlink /etc/localtime | sed 's|/usr/share/zoneinfo/||'
    else
        timedatectl show --property=Timezone --value 2>/dev/null || echo "UTC"
    fi
}

# Validate timezone
validate_timezone() {
    local timezone="$1"
    
    if [[ -z "$timezone" ]]; then
        return 1
    fi
    
    if [[ "$OS_NAME_LOWER" == "macos" ]]; then
        # macOS timezone validation
        if [[ -f "/var/db/timezone/zoneinfo/$timezone" ]]; then
            return 0
        fi
    else
        # Linux timezone validation
        if [[ -f "/usr/share/zoneinfo/$timezone" ]]; then
            return 0
        fi
    fi
    
    return 1
}

# Check available storage space for specific path
check_storage_space() {
    local path="$1"
    local required_gb="$2"
    
    # Create directory if it doesn't exist
    mkdir -p "$path" 2>/dev/null || true
    
    local available_gb
    if [[ "$OS_NAME_LOWER" == "macos" ]]; then
        available_gb=$(df -g "$path" | tail -n 1 | awk '{print $4}')
    else
        available_gb=$(df -BG --output=avail "$path" | tail -n 1 | tr -d 'G')
    fi
    
    if [[ $available_gb -lt $required_gb ]]; then
        error_exit "Insufficient storage space in $path: ${available_gb}GB available, ${required_gb}GB required"
    fi
    
    success "Storage space check passed: ${available_gb}GB available in $path"
}

# Check if directory is writable
check_directory_writable() {
    local dir="$1"
    
    # Try to create directory if it doesn't exist
    if ! mkdir -p "$dir" 2>/dev/null; then
        error_exit "Cannot create directory: $dir"
    fi
    
    # Check if writable
    if ! [[ -w "$dir" ]]; then
        error_exit "Directory not writable: $dir"
    fi
    
    return 0
}

# Get current user info (handles sudo correctly)
get_user_info() {
    local -A user_info
    
    if [[ -n "$SUDO_USER" ]]; then
        user_info["username"]="$SUDO_USER"
        user_info["uid"]=$(id -u "$SUDO_USER")
        user_info["gid"]=$(id -g "$SUDO_USER")
        user_info["home"]=$(eval echo "~$SUDO_USER")
    else
        user_info["username"]="$USER"
        user_info["uid"]=$(id -u)
        user_info["gid"]=$(id -g)
        user_info["home"]="$HOME"
    fi
    
    # Return as key=value pairs
    for key in "${!user_info[@]}"; do
        echo "${key}=${user_info[$key]}"
    done
}

# Check if firewall is available and configured
check_firewall() {
    info "🔥 Checking firewall status..."
    
    if [[ "$OS_NAME_LOWER" == "macos" ]]; then
        # macOS uses pfctl/firewall, but we'll skip automatic configuration
        warning "macOS firewall detected. Automatic firewall configuration skipped."
        info "💡 You may need to manually configure firewall rules if needed."
        return 0
    fi
    
    if command_exists ufw; then
        local ufw_status=$(ufw status | head -n1 | awk '{print $2}')
        
        case "$ufw_status" in
            "active")
                success "UFW firewall is active"
                return 0
                ;;
            "inactive")
                warning "UFW firewall is inactive. Will be configured automatically."
                return 1
                ;;
            *)
                warning "UFW firewall status unknown: $ufw_status"
                return 1
                ;;
        esac
    else
        warning "UFW not installed. Will be installed automatically."
        return 1
    fi
}

# Comprehensive system check
run_system_checks() {
    local min_ram_gb=${1:-2}
    local min_disk_gb=${2:-10}
    local target_dir="${3:-/}"
    
    info "🔍 Running comprehensive system checks..."
    
    check_root
    detect_os
    check_system_requirements "$min_ram_gb" "$min_disk_gb" "$target_dir"
    check_internet
    check_docker_requirements
    
    # Skip firewall check for macOS (handled differently)
    if [[ "$OS_NAME_LOWER" != "macos" ]]; then
        check_firewall
    fi
    
    # Check for container environment (warning only)
    check_container_environment
    
    success "All system checks passed"
}

# Get platform-specific default paths
get_default_media_path() {
    if [[ "$OS_NAME_LOWER" == "macos" ]]; then
        echo "/Users/$USER/homelab/media"
    else
        echo "/mnt/media"
    fi
}

get_default_config_path() {
    if [[ "$OS_NAME_LOWER" == "macos" ]]; then
        echo "/Users/$USER/homelab/config"
    else
        echo "/opt/appdata"
    fi
}

get_default_homelab_path() {
    if [[ "$OS_NAME_LOWER" == "macos" ]]; then
        echo "/Users/$USER/homelab"
    else
        echo "/home/$USER/homelab"
    fi
}

# Get Docker socket path for current platform
get_docker_socket_path() {
    if [[ "$OS_NAME_LOWER" == "macos" ]]; then
        echo "/var/run/docker.sock"
    else
        echo "/var/run/docker.sock"
    fi
}

# Package management abstraction
install_package() {
    local package="$1"
    
    if [[ -z "$package" ]]; then
        error_exit "install_package requires a package name"
    fi
    
    info "📦 Installing package: $package"
    
    case "$OS_NAME_LOWER" in
        "macos")
            if ! command_exists brew; then
                error_exit "Homebrew not found. Please install Homebrew first: https://brew.sh/"
            fi
            
            # Get the actual user (not root) to run brew commands
            local actual_user
            if [[ -n "$SUDO_USER" ]]; then
                actual_user="$SUDO_USER"
            else
                actual_user="$(whoami)"
            fi
            
            sudo -u "$actual_user" brew install "$package"
            ;;
        "ubuntu"|"debian"|"linuxmint"|"mint")
            apt-get update && apt-get install -y "$package"
            ;;
        *)
            error_exit "Unsupported OS for package installation: $OS_NAME"
            ;;
    esac
    
    success "Package installed: $package"
}

# Service management abstraction
start_service() {
    local service="$1"
    
    if [[ -z "$service" ]]; then
        error_exit "start_service requires a service name"
    fi
    
    info "🚀 Starting service: $service"
    
    case "$OS_NAME_LOWER" in
        "macos")
            if [[ "$service" == "docker" ]]; then
                # On macOS, Docker Desktop handles this
                info "Docker Desktop should be started manually or via Docker Desktop app"
            else
                # Use launchctl for other services
                launchctl start "$service" 2>/dev/null || true
            fi
            ;;
        "ubuntu"|"debian"|"linuxmint"|"mint")
            systemctl start "$service"
            ;;
        *)
            error_exit "Unsupported OS for service management: $OS_NAME"
            ;;
    esac
    
    success "Service started: $service"
}

# Check if service is running
is_service_running() {
    local service="$1"
    
    if [[ -z "$service" ]]; then
        return 1
    fi
    
    case "$OS_NAME_LOWER" in
        "macos")
            if [[ "$service" == "docker" ]]; then
                # Check if Docker daemon is responding
                docker info >/dev/null 2>&1
            else
                # Check with launchctl
                launchctl list | grep -q "$service"
            fi
            ;;
        "ubuntu"|"debian"|"linuxmint"|"mint")
            systemctl is-active --quiet "$service"
            ;;
        *)
            return 1
            ;;
    esac
}

# Enable service to start on boot
enable_service() {
    local service="$1"
    
    if [[ -z "$service" ]]; then
        error_exit "enable_service requires a service name"
    fi
    
    info "⚙️ Enabling service: $service"
    
    case "$OS_NAME_LOWER" in
        "macos")
            if [[ "$service" == "docker" ]]; then
                info "Docker Desktop auto-start should be configured in Docker Desktop settings"
            else
                # Use launchctl for other services
                launchctl enable "$service" 2>/dev/null || true
            fi
            ;;
        "ubuntu"|"debian"|"linuxmint"|"mint")
            systemctl enable "$service"
            ;;
        *)
            error_exit "Unsupported OS for service management: $OS_NAME"
            ;;
    esac
    
    success "Service enabled: $service"
}

# Get network interface IP address
get_primary_ip() {
    local ip=""
    
    case "$OS_NAME_LOWER" in
        "macos")
            # macOS network interface detection
            ip=$(route get default | grep interface | awk '{print $2}' | head -1)
            if [[ -n "$ip" ]]; then
                ip=$(ifconfig "$ip" | grep 'inet ' | awk '{print $2}' | head -1)
            fi
            ;;
        "ubuntu"|"debian"|"linuxmint"|"mint")
            # Linux network interface detection
            ip=$(hostname -I | awk '{print $1}')
            ;;
        *)
            # Fallback method
            ip=$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K\S+' | head -1)
            ;;
    esac
    
    # Validate IP address
    if is_valid_ip "$ip"; then
        echo "$ip"
    else
        echo "localhost"
    fi
}

# Remove existing Docker installation on Linux
remove_docker_linux() {
    info "🗑️ Removing existing Docker installation..."
    
    # Stop Docker service if running
    if systemctl is-active --quiet docker; then
        info "🛑 Stopping Docker service..."
        systemctl stop docker
    fi
    
    # Stop Docker socket if running
    if systemctl is-active --quiet docker.socket; then
        info "🛑 Stopping Docker socket..."
        systemctl stop docker.socket
    fi
    
    # Disable Docker service
    if systemctl is-enabled --quiet docker; then
        info "🔧 Disabling Docker service..."
        systemctl disable docker
    fi
    
    # Remove Docker packages
    info "🗑️ Removing Docker packages..."
    apt-get remove -y docker docker-engine docker.io containerd runc docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null || true
    apt-get purge -y docker docker-engine docker.io containerd runc docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null || true
    
    # Remove Docker Compose standalone if installed
    if [[ -f "/usr/local/bin/docker-compose" ]]; then
        info "🗑️ Removing Docker Compose standalone..."
        rm -f "/usr/local/bin/docker-compose"
    fi
    
    # Remove Docker data directories
    info "🗑️ Removing Docker data directories..."
    local docker_dirs=(
        "/var/lib/docker"
        "/var/lib/containerd"
        "/etc/docker"
        "/etc/containerd"
        "/run/docker"
        "/run/containerd"
        "/opt/containerd"
    )
    
    for dir in "${docker_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            rm -rf "$dir"
        fi
    done
    
    # Remove Docker group
    if getent group docker >/dev/null 2>&1; then
        info "🗑️ Removing Docker group..."
        groupdel docker 2>/dev/null || true
    fi
    
    # Remove Docker repository
    if [[ -f "/etc/apt/sources.list.d/docker.list" ]]; then
        info "🗑️ Removing Docker repository..."
        rm -f "/etc/apt/sources.list.d/docker.list"
    fi
    
    # Remove Docker GPG key
    if [[ -f "/etc/apt/keyrings/docker.gpg" ]]; then
        rm -f "/etc/apt/keyrings/docker.gpg"
    fi
    
    # Remove any remaining Docker processes
    pkill -f docker 2>/dev/null || true
    pkill -f containerd 2>/dev/null || true
    
    # Clean up package manager cache
    apt-get autoremove -y 2>/dev/null || true
    apt-get autoclean 2>/dev/null || true
    
    success "Docker removal completed"
}

# Remove existing Docker installation on macOS
remove_docker_macos() {
    info "🗑️ Removing existing Docker installation..."
    
    # Get the actual user (not root) for operations
    local actual_user
    if [[ -n "$SUDO_USER" ]]; then
        actual_user="$SUDO_USER"
    else
        actual_user="$(whoami)"
    fi
    
    # Stop Docker Desktop if running
    if pgrep -f "Docker Desktop" >/dev/null 2>&1; then
        info "🛑 Stopping Docker Desktop..."
        sudo -u "$actual_user" osascript -e 'quit app "Docker Desktop"' 2>/dev/null || true
        sleep 3
    fi
    
    # Remove Docker Desktop application
    if [[ -d "/Applications/Docker.app" ]]; then
        info "🗑️ Removing Docker Desktop application..."
        rm -rf "/Applications/Docker.app"
    fi
    
    # Remove Docker CLI tools installed via Homebrew
    if command_exists brew; then
        info "🗑️ Removing Docker via Homebrew..."
        sudo -u "$actual_user" brew uninstall --cask docker 2>/dev/null || true
        sudo -u "$actual_user" brew uninstall docker 2>/dev/null || true
        sudo -u "$actual_user" brew uninstall docker-compose 2>/dev/null || true
        sudo -u "$actual_user" brew uninstall docker-machine 2>/dev/null || true
        sudo -u "$actual_user" brew uninstall docker-buildx 2>/dev/null || true
        sudo -u "$actual_user" brew uninstall containerd 2>/dev/null || true
    fi
    
    # Remove Docker data directories
    local docker_dirs=(
        "/Users/$actual_user/.docker"
        "/Users/$actual_user/Library/Preferences/com.docker.docker.plist"
        "/Users/$actual_user/Library/Saved Application State/com.electron.docker-frontend.savedState"
        "/Users/$actual_user/Library/Group Containers/group.com.docker"
        "/Users/$actual_user/Library/Containers/com.docker.docker"
        "/Users/$actual_user/Library/Application Support/Docker Desktop"
        "/Users/$actual_user/Library/Logs/Docker Desktop"
        "/Users/$actual_user/Library/Preferences/com.electron.docker-frontend.plist"
        "/Users/$actual_user/Library/Caches/com.docker.docker"
    )
    
    for dir in "${docker_dirs[@]}"; do
        if [[ -e "$dir" ]]; then
            info "🗑️ Removing: $dir"
            rm -rf "$dir"
        fi
    done
    
    # Remove Docker symlinks and binaries
    local docker_links=(
        "/usr/local/bin/docker"
        "/usr/local/bin/docker-compose"
        "/usr/local/bin/docker-machine"
        "/usr/local/bin/docker-buildx"
        "/usr/local/bin/containerd"
        "/usr/local/bin/containerd-shim"
        "/usr/local/bin/containerd-shim-runc-v2"
        "/usr/local/bin/ctr"
        "/usr/local/bin/runc"
        "/usr/local/bin/docker-credential-desktop"
        "/usr/local/bin/docker-credential-ecr-login"
        "/usr/local/bin/docker-credential-osxkeychain"
        "/usr/local/bin/kubectl"
        "/usr/local/bin/kubectl.docker"
        "/usr/local/bin/vpnkit"
        "/usr/local/bin/com.docker.cli"
    )
    
    for link in "${docker_links[@]}"; do
        if [[ -L "$link" ]] || [[ -f "$link" ]]; then
            info "🗑️ Removing: $link"
            rm -f "$link"
        fi
    done
    
    # Kill any remaining Docker processes
    pkill -f docker 2>/dev/null || true
    pkill -f com.docker 2>/dev/null || true
    pkill -f containerd 2>/dev/null || true
    
    success "Docker removal completed"
}

# Check existing Docker installation on macOS
check_existing_docker_macos() {
    local docker_version=""
    local docker_desktop_version=""
    local installation_method=""
    
    # Check for Docker command
    if command_exists docker; then
        docker_version=$(docker --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
    fi
    
    # Check for Docker Desktop
    if [[ -d "/Applications/Docker.app" ]]; then
        docker_desktop_version=$(defaults read /Applications/Docker.app/Contents/Info.plist CFBundleShortVersionString 2>/dev/null || echo "unknown")
        installation_method="Docker Desktop"
    fi
    
    # Check if installed via Homebrew
    if command_exists brew; then
        local actual_user
        if [[ -n "$SUDO_USER" ]]; then
            actual_user="$SUDO_USER"
        else
            actual_user="$(whoami)"
        fi
        
        if sudo -u "$actual_user" brew list --cask docker >/dev/null 2>&1; then
            installation_method="Homebrew Cask"
        elif sudo -u "$actual_user" brew list docker >/dev/null 2>&1; then
            installation_method="Homebrew"
        fi
    fi
    
    # Return results
    echo "docker_version=$docker_version"
    echo "docker_desktop_version=$docker_desktop_version"
    echo "installation_method=$installation_method"
}

# Install Docker for the current platform
install_docker() {
    info "🐳 Installing Docker..."
    
    case "$OS_NAME_LOWER" in
        "macos")
            # Check for existing Docker installation
            local docker_info
            docker_info=$(check_existing_docker_macos)
            
            local docker_version=$(echo "$docker_info" | grep "docker_version=" | cut -d'=' -f2)
            local docker_desktop_version=$(echo "$docker_info" | grep "docker_desktop_version=" | cut -d'=' -f2)
            local installation_method=$(echo "$docker_info" | grep "installation_method=" | cut -d'=' -f2)
            
            # If Docker is already installed, ask for confirmation to reinstall
            if [[ -n "$docker_version" ]] || [[ -n "$docker_desktop_version" ]] || [[ -n "$installation_method" ]]; then
                warning "Existing Docker installation detected:"
                if [[ -n "$docker_version" ]]; then
                    info "  Docker CLI version: $docker_version"
                fi
                if [[ -n "$docker_desktop_version" ]]; then
                    info "  Docker Desktop version: $docker_desktop_version"
                fi
                if [[ -n "$installation_method" ]]; then
                    info "  Installation method: $installation_method"
                fi
                
                echo
                warning "⚠️  To ensure a clean HOPS installation, we recommend removing the existing Docker installation."
                warning "    This will remove all Docker data, containers, images, and volumes."
                echo
                
                read -p "❓ Do you want to remove the existing Docker installation and reinstall? (y/N): " -n 1 -r
                echo
                
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    remove_docker_macos
                    
                    # Double-check removal was successful
                    sleep 2
                    if command_exists docker && docker info >/dev/null 2>&1; then
                        error_exit "Docker removal failed. Please manually remove Docker and try again."
                    fi
                else
                    info "Keeping existing Docker installation. Checking if it's compatible..."
                    
                    # Check if existing Docker is compatible
                    if ! docker info >/dev/null 2>&1; then
                        error_exit "Existing Docker installation is not running. Please start Docker Desktop manually or choose to reinstall."
                    fi
                    
                    # Check Docker Compose
                    if ! docker compose version >/dev/null 2>&1; then
                        error_exit "Docker Compose not available in existing installation. Please reinstall Docker Desktop."
                    fi
                    
                    success "Existing Docker installation is compatible"
                    return 0
                fi
            fi
            
            # Install fresh Docker Desktop
            info "📦 Installing Docker Desktop for Mac..."
            
            # Check if Homebrew is available
            if ! command_exists brew; then
                warning "Homebrew not found. Installing Homebrew first..."
                
                # Get the actual user (not root) to install Homebrew
                local actual_user
                if [[ -n "$SUDO_USER" ]]; then
                    actual_user="$SUDO_USER"
                else
                    actual_user="$(whoami)"
                fi
                
                # Install Homebrew as the actual user, not root
                sudo -u "$actual_user" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                
                # Add Homebrew to PATH for current session
                if [[ -f "/opt/homebrew/bin/brew" ]]; then
                    eval "$(/opt/homebrew/bin/brew shellenv)"
                elif [[ -f "/usr/local/bin/brew" ]]; then
                    eval "$(/usr/local/bin/brew shellenv)"
                fi
            fi
            
            # Install Docker Desktop via Homebrew Cask
            info "📦 Installing Docker Desktop via Homebrew..."
            
            # Get the actual user (not root) to run brew commands
            local actual_user
            if [[ -n "$SUDO_USER" ]]; then
                actual_user="$SUDO_USER"
            else
                actual_user="$(whoami)"
            fi
            
            # Remove conflicting compose-bridge binary if it exists
            if [[ -f "/usr/local/bin/compose-bridge" ]]; then
                info "🗑️ Removing conflicting compose-bridge binary..."
                rm -f "/usr/local/bin/compose-bridge" 2>/dev/null || true
            fi
            
            sudo -u "$actual_user" brew install --cask docker
            
            # Start Docker Desktop
            info "🚀 Starting Docker Desktop..."
            open -a Docker
            
            # Wait for Docker to start
            info "⏳ Waiting for Docker Desktop to start (this may take a few minutes)..."
            local max_wait=120
            local wait_time=0
            
            while ! docker info >/dev/null 2>&1; do
                if [[ $wait_time -ge $max_wait ]]; then
                    error_exit "Docker Desktop failed to start within $max_wait seconds. Please start it manually and try again."
                fi
                
                sleep 5
                ((wait_time += 5))
                echo -n "."
            done
            
            echo
            success "Docker Desktop installed and started successfully"
            ;;
        "ubuntu"|"debian"|"linuxmint"|"mint")
            # Check for existing Docker installation
            if command_exists docker; then
                local docker_version=$(docker --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
                
                warning "Existing Docker installation detected:"
                if [[ -n "$docker_version" ]]; then
                    info "  Docker version: $docker_version"
                fi
                
                echo
                warning "⚠️  To ensure a clean HOPS installation, we recommend removing the existing Docker installation."
                warning "    This will remove all Docker data, containers, images, and volumes."
                echo
                
                read -p "❓ Do you want to remove the existing Docker installation and reinstall? (y/N): " -n 1 -r
                echo
                
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    remove_docker_linux
                    
                    # Double-check removal was successful
                    sleep 2
                    if command_exists docker && docker info >/dev/null 2>&1; then
                        error_exit "Docker removal failed. Please manually remove Docker and try again."
                    fi
                else
                    info "Keeping existing Docker installation. Checking if it's compatible..."
                    
                    # Check if existing Docker is compatible
                    if ! docker info >/dev/null 2>&1; then
                        error_exit "Existing Docker installation is not running. Please start Docker service manually or choose to reinstall."
                    fi
                    
                    # Check Docker Compose
                    if ! docker compose version >/dev/null 2>&1; then
                        error_exit "Docker Compose not available in existing installation. Please reinstall Docker."
                    fi
                    
                    success "Existing Docker installation is compatible"
                    return 0
                fi
            fi
            
            # Install fresh Docker using the official script
            info "📦 Installing Docker Engine..."
            curl -fsSL https://get.docker.com | sh
            
            # Add user to docker group if we're running with sudo
            if [[ -n "$SUDO_USER" ]]; then
                usermod -aG docker "$SUDO_USER"
            fi
            
            # Start and enable Docker service
            start_service docker
            enable_service docker
            
            success "Docker installed and configured"
            ;;
        *)
            error_exit "Unsupported OS for Docker installation: $OS_NAME"
            ;;
    esac
}

# Check if Docker is properly installed and running
check_docker_installation() {
    info "🐳 Checking Docker installation..."
    
    # Check if Docker command exists
    if ! command_exists docker; then
        return 1
    fi
    
    # Check if Docker daemon is running
    if ! docker info >/dev/null 2>&1; then
        return 1
    fi
    
    # Check Docker Compose
    if ! docker compose version >/dev/null 2>&1; then
        return 1
    fi
    
    success "Docker is properly installed and running"
    return 0
}