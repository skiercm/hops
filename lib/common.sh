#!/bin/bash

# HOPS - Common Utility Functions
# Shared functions for logging, error handling, and UI
# Version: 3.1.0

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly NC='\033[0m' # No Color

# Global variables (set by setup_logging)
LOG_DIR=""
LOG_FILE=""

# Initialize logging system
setup_logging() {
    local log_prefix="$1"
    
    if [[ -z "$log_prefix" ]]; then
        echo "ERROR: setup_logging requires a log prefix" >&2
        return 1
    fi
    
    LOG_DIR="/var/log/hops"
    LOG_FILE="$LOG_DIR/${log_prefix}-$(date +%Y%m%d-%H%M%S).log"
    
    if [[ $EUID -eq 0 ]]; then
        mkdir -p "$LOG_DIR"
        touch "$LOG_FILE"
    else
        echo "WARNING: Not running as root, logging to console only" >&2
    fi
}

# Unified logging function
log() {
    local message="$1"
    local timestamp="$(date '+%Y-%m-%d %T')"
    
    # Write to log file if available
    if [[ -n "$LOG_FILE" && -w "$LOG_FILE" ]]; then
        echo "$timestamp - $message" >> "$LOG_FILE"
    fi
    
    # Always output to console
    echo -e "$message"
}

# Error handling with exit
error_exit() {
    log "${RED}❌ ERROR: $1${NC}"
    if [[ -n "$LOG_FILE" ]]; then
        log "${RED}❌ Operation failed. Check logs at: $LOG_FILE${NC}"
    fi
    exit 1
}

# Warning function
warning() {
    log "${YELLOW}⚠️ WARNING: $1${NC}"
}

# Success function
success() {
    log "${GREEN}✅ $1${NC}"
}

# Info function
info() {
    log "${BLUE}ℹ️ $1${NC}"
}

# Debug function (only shows if DEBUG=1)
debug() {
    if [[ "${DEBUG:-0}" == "1" ]]; then
        log "${PURPLE}🐛 DEBUG: $1${NC}"
    fi
}

# Show HOPS header
show_hops_header() {
    local version="$1"
    local subtitle="$2"
    
    if [[ -z "$version" ]]; then
        version="3.1.0"
    fi
    
    clear
    cat << "EOF"

  _    _  ____  ____  ____  
 | |  | ||  _ \|  _ \/ ___| 
 | |__| || |_) | |_) \___ \ 
 |  __  ||  __/|  __/ ___) |
 |_|  |_||_|   |_|   |____/ 

EOF
    echo -e "${CYAN}🚀 Homelab Orchestration Provisioning Script v${version}${NC}"
    
    if [[ -n "$subtitle" ]]; then
        echo -e "${WHITE}${subtitle}${NC}"
    fi
    
    echo -e "${WHITE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# Progress indicator
show_progress() {
    local current="$1"
    local total="$2"
    local message="$3"
    local width=50
    
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    printf "\r${BLUE}[${NC}"
    printf "%${filled}s" | tr ' ' '='
    printf "%${empty}s" | tr ' ' '-'
    printf "${BLUE}] %3d%% %s${NC}" "$percentage" "$message"
    
    if [[ $current -eq $total ]]; then
        echo
    fi
}

# Confirmation prompt
confirm() {
    local message="$1"
    local default="${2:-n}"
    local prompt
    
    case "$default" in
        [Yy]|[Yy][Ee][Ss]) prompt="[Y/n]" ;;
        [Nn]|[Nn][Oo]) prompt="[y/N]" ;;
        *) prompt="[y/n]" ;;
    esac
    
    while true; do
        read -r -p "${message} ${prompt}: " response
        
        # Use default if empty response
        if [[ -z "$response" ]]; then
            response="$default"
        fi
        
        case "$response" in
            [Yy]|[Yy][Ee][Ss]) return 0 ;;
            [Nn]|[Nn][Oo]) return 1 ;;
            *) echo "Please answer yes or no." ;;
        esac
    done
}

# Spinner for long operations
spinner() {
    local pid=$1
    local message="$2"
    local spin='-\|/'
    local i=0
    
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r${BLUE}%s %s${NC}" "${spin:i++%${#spin}:1}" "$message"
        sleep 0.1
    done
    
    printf "\r"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error_exit "This script must be run as root or with sudo."
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Wait for user input
pause() {
    local message="${1:-Press any key to continue...}"
    read -n 1 -s -r -p "$message"
    echo
}

# Format bytes to human readable
format_bytes() {
    local bytes=$1
    local units=("B" "KB" "MB" "GB" "TB")
    local unit=0
    
    while [[ $bytes -gt 1024 && $unit -lt 4 ]]; do
        bytes=$((bytes / 1024))
        ((unit++))
    done
    
    echo "${bytes}${units[$unit]}"
}

# Check if string is a valid IP address
is_valid_ip() {
    local ip=$1
    local regex="^([0-9]{1,3}\.){3}[0-9]{1,3}$"
    
    if [[ $ip =~ $regex ]]; then
        local IFS='.'
        local -a octets=($ip)
        
        for octet in "${octets[@]}"; do
            if [[ $octet -gt 255 ]]; then
                return 1
            fi
        done
        
        return 0
    fi
    
    return 1
}

# Check if port is available
is_port_available() {
    local port=$1
    ! ss -tuln | grep -q ":$port "
}

# Get available port starting from given port
get_available_port() {
    local start_port=$1
    local port=$start_port
    
    while ! is_port_available "$port"; do
        ((port++))
        if [[ $port -gt 65535 ]]; then
            error_exit "No available ports found starting from $start_port"
        fi
    done
    
    echo "$port"
}