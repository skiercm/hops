#!/bin/bash

# HOPS - System Validation Functions
# Functions for system checks, OS detection, and requirements validation
# Version: 3.1.0

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Global variables for system info
OS_NAME=""
OS_VERSION=""
OS_NAME_LOWER=""

# Detect operating system
detect_os() {
    info "🔍 Detecting operating system..."
    
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
            error_exit "Unsupported OS: $OS_NAME $OS_VERSION. Only Ubuntu/Debian/Linux Mint are supported."
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
    if [[ "$arch" != "x86_64" ]]; then
        error_exit "Unsupported architecture: $arch. Only x86_64 is supported."
    fi
    
    # Check RAM
    local ram_gb
    if command_exists free; then
        ram_gb=$(free -g | awk '/^Mem:/{print $2}')
    else
        ram_gb=$(awk '/MemTotal/ {print int($2/1024/1024)}' /proc/meminfo)
    fi
    
    if [[ $ram_gb -lt $min_ram_gb ]]; then
        error_exit "Insufficient RAM: ${ram_gb}GB detected, ${min_ram_gb}GB required"
    fi
    
    # Check disk space
    local disk_avail_gb
    if command_exists df; then
        disk_avail_gb=$(df -BG --output=avail "$target_dir" | tail -n 1 | tr -d 'G')
    else
        error_exit "Unable to check disk space - 'df' command not available"
    fi
    
    if [[ $disk_avail_gb -lt $min_disk_gb ]]; then
        error_exit "Insufficient disk space: ${disk_avail_gb}GB available in $target_dir, ${min_disk_gb}GB required"
    fi
    
    # Check CPU cores
    local cpu_cores=$(nproc)
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
    if [[ -f /etc/timezone ]]; then
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
    
    if [[ -f "/usr/share/zoneinfo/$timezone" ]]; then
        return 0
    fi
    
    return 1
}

# Check available storage space for specific path
check_storage_space() {
    local path="$1"
    local required_gb="$2"
    
    # Create directory if it doesn't exist
    mkdir -p "$path" 2>/dev/null || true
    
    local available_gb=$(df -BG --output=avail "$path" | tail -n 1 | tr -d 'G')
    
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
    check_firewall
    
    # Check for container environment (warning only)
    check_container_environment
    
    success "All system checks passed"
}