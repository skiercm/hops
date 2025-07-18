#!/bin/bash

# HOPS - Input Validation and Sanitization Functions
# Comprehensive input validation and sanitization utilities
# Version: 3.1.0-beta

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Validate and sanitize directory path
validate_directory_path() {
    local path="$1"
    local allow_relative="${2:-false}"
    local create_if_missing="${3:-false}"
    
    if [[ -z "$path" ]]; then
        error_exit "Directory path cannot be empty"
    fi
    
    # Remove any trailing slashes (except for root)
    path="${path%/}"
    if [[ "$path" == "" ]]; then
        path="/"
    fi
    
    # Check for path traversal attempts
    if [[ "$path" =~ \.\./|\.\.\\ ]]; then
        error_exit "Path traversal detected in: $path"
    fi
    
    # Check for null bytes
    if [[ "$path" =~ $'\0' ]]; then
        error_exit "Null byte detected in path: $path"
    fi
    
    # Check for dangerous characters
    if [[ "$path" =~ [\;\&\|\`\$\(\)] ]]; then
        error_exit "Dangerous characters detected in path: $path"
    fi
    
    # Check if relative paths are allowed
    if [[ "$allow_relative" != "true" && "$path" != /* ]]; then
        error_exit "Relative paths not allowed: $path"
    fi
    
    # Validate length (most filesystems have a 4096 limit)
    if [[ ${#path} -gt 4000 ]]; then
        error_exit "Path too long: ${#path} characters (max 4000)"
    fi
    
    # Create directory if requested and doesn't exist
    if [[ "$create_if_missing" == "true" && ! -d "$path" ]]; then
        if ! mkdir -p "$path" 2>/dev/null; then
            error_exit "Failed to create directory: $path"
        fi
    fi
    
    # Return sanitized path
    echo "$path"
}

# Validate timezone
validate_timezone() {
    local timezone="$1"
    
    if [[ -z "$timezone" ]]; then
        error_exit "Timezone cannot be empty"
    fi
    
    # Basic format validation
    if [[ ! "$timezone" =~ ^[A-Za-z_]+(/[A-Za-z_]+)*$ ]]; then
        error_exit "Invalid timezone format: $timezone"
    fi
    
    # Check if timezone file exists
    if [[ ! -f "/usr/share/zoneinfo/$timezone" ]]; then
        error_exit "Unknown timezone: $timezone"
    fi
    
    echo "$timezone"
}

# Validate domain name
validate_domain() {
    local domain="$1"
    
    if [[ -z "$domain" ]]; then
        error_exit "Domain cannot be empty"
    fi
    
    # Basic domain validation
    if [[ ! "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        error_exit "Invalid domain format: $domain"
    fi
    
    # Check length
    if [[ ${#domain} -gt 253 ]]; then
        error_exit "Domain too long: ${#domain} characters (max 253)"
    fi
    
    # Check for localhost variants
    if [[ "$domain" =~ ^(localhost|127\.0\.0\.1|::1)$ ]]; then
        warning "Using localhost domain: $domain"
    fi
    
    echo "$domain"
}

# Validate email address
validate_email() {
    local email="$1"
    
    if [[ -z "$email" ]]; then
        error_exit "Email cannot be empty"
    fi
    
    # Basic email validation
    if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        error_exit "Invalid email format: $email"
    fi
    
    # Check length
    if [[ ${#email} -gt 254 ]]; then
        error_exit "Email too long: ${#email} characters (max 254)"
    fi
    
    echo "$email"
}

# Validate port number
validate_port() {
    local port="$1"
    local allow_privileged="${2:-false}"
    
    if [[ -z "$port" ]]; then
        error_exit "Port cannot be empty"
    fi
    
    # Check if it's a number
    if [[ ! "$port" =~ ^[0-9]+$ ]]; then
        error_exit "Port must be a number: $port"
    fi
    
    # Check range
    if [[ "$port" -lt 1 || "$port" -gt 65535 ]]; then
        error_exit "Port out of range: $port (1-65535)"
    fi
    
    # Check for privileged ports
    if [[ "$allow_privileged" != "true" && "$port" -lt 1024 ]]; then
        error_exit "Privileged port not allowed: $port (use ports >= 1024)"
    fi
    
    echo "$port"
}

# Validate IP address
validate_ip() {
    local ip="$1"
    
    if [[ -z "$ip" ]]; then
        error_exit "IP address cannot be empty"
    fi
    
    # IPv4 validation
    if [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        local IFS='.'
        local -a octets=($ip)
        
        for octet in "${octets[@]}"; do
            if [[ "$octet" -gt 255 ]]; then
                error_exit "Invalid IPv4 address: $ip"
            fi
        done
        
        echo "$ip"
        return 0
    fi
    
    # IPv6 validation (basic)
    if [[ "$ip" =~ ^([0-9a-fA-F]{0,4}:){2,7}[0-9a-fA-F]{0,4}$ ]]; then
        echo "$ip"
        return 0
    fi
    
    error_exit "Invalid IP address format: $ip"
}

# Validate container name
validate_container_name() {
    local name="$1"
    
    if [[ -z "$name" ]]; then
        error_exit "Container name cannot be empty"
    fi
    
    # Docker container name validation
    if [[ ! "$name" =~ ^[a-zA-Z0-9][a-zA-Z0-9_.-]*$ ]]; then
        error_exit "Invalid container name: $name (use alphanumeric, underscore, period, hyphen)"
    fi
    
    # Check length
    if [[ ${#name} -gt 63 ]]; then
        error_exit "Container name too long: ${#name} characters (max 63)"
    fi
    
    echo "$name"
}

# Validate environment variable name
validate_env_var_name() {
    local name="$1"
    
    if [[ -z "$name" ]]; then
        error_exit "Environment variable name cannot be empty"
    fi
    
    # Environment variable name validation
    if [[ ! "$name" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        error_exit "Invalid environment variable name: $name"
    fi
    
    echo "$name"
}

# Validate and sanitize environment variable value
validate_env_var_value() {
    local value="$1"
    local allow_empty="${2:-false}"
    
    if [[ -z "$value" && "$allow_empty" != "true" ]]; then
        error_exit "Environment variable value cannot be empty"
    fi
    
    # Check for null bytes
    if [[ "$value" =~ $'\0' ]]; then
        error_exit "Null byte detected in environment variable value"
    fi
    
    # Check for dangerous command substitution
    if [[ "$value" =~ \$\(|\`|\\x ]]; then
        error_exit "Dangerous command substitution detected in value: $value"
    fi
    
    echo "$value"
}

# Validate user ID
validate_uid() {
    local uid="$1"
    
    if [[ -z "$uid" ]]; then
        error_exit "UID cannot be empty"
    fi
    
    # Check if it's a number
    if [[ ! "$uid" =~ ^[0-9]+$ ]]; then
        error_exit "UID must be a number: $uid"
    fi
    
    # Check range (0-65534)
    if [[ "$uid" -lt 0 || "$uid" -gt 65534 ]]; then
        error_exit "UID out of range: $uid (0-65534)"
    fi
    
    # Warn about using root
    if [[ "$uid" -eq 0 ]]; then
        warning "Using root UID (0) is not recommended"
    fi
    
    echo "$uid"
}

# Validate group ID
validate_gid() {
    local gid="$1"
    
    if [[ -z "$gid" ]]; then
        error_exit "GID cannot be empty"
    fi
    
    # Check if it's a number
    if [[ ! "$gid" =~ ^[0-9]+$ ]]; then
        error_exit "GID must be a number: $gid"
    fi
    
    # Check range (0-65534)
    if [[ "$gid" -lt 0 || "$gid" -gt 65534 ]]; then
        error_exit "GID out of range: $gid (0-65534)"
    fi
    
    # Warn about using root
    if [[ "$gid" -eq 0 ]]; then
        warning "Using root GID (0) is not recommended"
    fi
    
    echo "$gid"
}

# Validate memory size (e.g., "512m", "2g")
validate_memory_size() {
    local size="$1"
    
    if [[ -z "$size" ]]; then
        error_exit "Memory size cannot be empty"
    fi
    
    # Check format (number followed by unit)
    if [[ ! "$size" =~ ^[0-9]+[kmgtKMGT]?$ ]]; then
        error_exit "Invalid memory size format: $size (use format like 512m, 2g)"
    fi
    
    echo "$size"
}

# Validate disk size (e.g., "10G", "500M")
validate_disk_size() {
    local size="$1"
    
    if [[ -z "$size" ]]; then
        error_exit "Disk size cannot be empty"
    fi
    
    # Check format (number followed by unit)
    if [[ ! "$size" =~ ^[0-9]+[KMGTPEZY]?$ ]]; then
        error_exit "Invalid disk size format: $size (use format like 10G, 500M)"
    fi
    
    echo "$size"
}

# Validate URL
validate_url() {
    local url="$1"
    local allowed_schemes="${2:-http,https}"
    
    if [[ -z "$url" ]]; then
        error_exit "URL cannot be empty"
    fi
    
    # Basic URL validation
    if [[ ! "$url" =~ ^[a-zA-Z][a-zA-Z0-9+.-]*:// ]]; then
        error_exit "Invalid URL format: $url"
    fi
    
    # Extract scheme
    local scheme="${url%%://*}"
    
    # Check allowed schemes
    if [[ ",$allowed_schemes," != *",$scheme,"* ]]; then
        error_exit "URL scheme not allowed: $scheme (allowed: $allowed_schemes)"
    fi
    
    echo "$url"
}

# Sanitize filename for safe use
sanitize_filename() {
    local filename="$1"
    local max_length="${2:-255}"
    
    if [[ -z "$filename" ]]; then
        error_exit "Filename cannot be empty"
    fi
    
    # Remove path separators and dangerous characters
    filename=$(echo "$filename" | tr -d '/' | tr -d '\\' | tr -d '\0')
    
    # Remove control characters
    filename=$(echo "$filename" | tr -d '[:cntrl:]')
    
    # Remove leading/trailing whitespace
    filename=$(echo "$filename" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    # Replace multiple spaces with single space
    filename=$(echo "$filename" | sed 's/[[:space:]]\+/ /g')
    
    # Remove reserved names (Windows compatibility)
    case "$filename" in
        CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])
            filename="${filename}_safe"
            ;;
    esac
    
    # Limit length
    if [[ ${#filename} -gt $max_length ]]; then
        filename="${filename:0:$max_length}"
    fi
    
    # Ensure it's not empty after sanitization
    if [[ -z "$filename" ]]; then
        filename="unnamed"
    fi
    
    echo "$filename"
}

# Validate Docker image name
validate_docker_image() {
    local image="$1"
    
    if [[ -z "$image" ]]; then
        error_exit "Docker image name cannot be empty"
    fi
    
    # Basic Docker image validation
    if [[ ! "$image" =~ ^[a-z0-9]+([._-][a-z0-9]+)*(/[a-z0-9]+([._-][a-z0-9]+)*)*(:([a-zA-Z0-9._-]+))?$ ]]; then
        error_exit "Invalid Docker image format: $image"
    fi
    
    # Check for latest tag warning
    if [[ "$image" =~ :latest$ || ! "$image" =~ : ]]; then
        warning "Using 'latest' tag is not recommended: $image"
    fi
    
    echo "$image"
}

# Validate network name
validate_network_name() {
    local name="$1"
    
    if [[ -z "$name" ]]; then
        error_exit "Network name cannot be empty"
    fi
    
    # Docker network name validation
    if [[ ! "$name" =~ ^[a-zA-Z0-9][a-zA-Z0-9_.-]*$ ]]; then
        error_exit "Invalid network name: $name"
    fi
    
    # Check length
    if [[ ${#name} -gt 63 ]]; then
        error_exit "Network name too long: ${#name} characters (max 63)"
    fi
    
    echo "$name"
}

# Validate volume name
validate_volume_name() {
    local name="$1"
    
    if [[ -z "$name" ]]; then
        error_exit "Volume name cannot be empty"
    fi
    
    # Docker volume name validation
    if [[ ! "$name" =~ ^[a-zA-Z0-9][a-zA-Z0-9_.-]*$ ]]; then
        error_exit "Invalid volume name: $name"
    fi
    
    # Check length
    if [[ ${#name} -gt 63 ]]; then
        error_exit "Volume name too long: ${#name} characters (max 63)"
    fi
    
    echo "$name"
}

# Comprehensive input validation for user inputs
validate_user_input() {
    local input="$1"
    local input_type="$2"
    local options="$3"
    
    case "$input_type" in
        "path")
            validate_directory_path "$input" "$options"
            ;;
        "timezone")
            validate_timezone "$input"
            ;;
        "domain")
            validate_domain "$input"
            ;;
        "email")
            validate_email "$input"
            ;;
        "port")
            validate_port "$input" "$options"
            ;;
        "ip")
            validate_ip "$input"
            ;;
        "container_name")
            validate_container_name "$input"
            ;;
        "uid")
            validate_uid "$input"
            ;;
        "gid")
            validate_gid "$input"
            ;;
        "memory")
            validate_memory_size "$input"
            ;;
        "disk")
            validate_disk_size "$input"
            ;;
        "url")
            validate_url "$input" "$options"
            ;;
        "filename")
            sanitize_filename "$input" "$options"
            ;;
        "docker_image")
            validate_docker_image "$input"
            ;;
        "network_name")
            validate_network_name "$input"
            ;;
        "volume_name")
            validate_volume_name "$input"
            ;;
        *)
            error_exit "Unknown input type: $input_type"
            ;;
    esac
}

# Batch validation for multiple inputs
validate_inputs() {
    local -A inputs
    local -A types
    local -A options
    
    # Parse arguments (input_name:input_value:type:options)
    while [[ $# -gt 0 ]]; do
        local arg="$1"
        local input_name="${arg%%:*}"
        local remaining="${arg#*:}"
        local input_value="${remaining%%:*}"
        remaining="${remaining#*:}"
        local input_type="${remaining%%:*}"
        local input_options="${remaining#*:}"
        
        inputs["$input_name"]="$input_value"
        types["$input_name"]="$input_type"
        options["$input_name"]="$input_options"
        
        shift
    done
    
    # Validate all inputs
    for input_name in "${!inputs[@]}"; do
        local validated_value
        validated_value=$(validate_user_input "${inputs[$input_name]}" "${types[$input_name]}" "${options[$input_name]}")
        echo "${input_name}=${validated_value}"
    done
}

# Interactive input validation
read_and_validate() {
    local prompt="$1"
    local input_type="$2"
    local options="$3"
    local default="$4"
    local allow_empty="${5:-false}"
    
    while true; do
        local input
        if [[ -n "$default" ]]; then
            read -r -p "$prompt [$default]: " input
            input="${input:-$default}"
        else
            read -r -p "$prompt: " input
        fi
        
        if [[ -z "$input" && "$allow_empty" == "true" ]]; then
            echo ""
            return 0
        fi
        
        if [[ -z "$input" ]]; then
            warning "Input cannot be empty"
            continue
        fi
        
        if validate_user_input "$input" "$input_type" "$options" >/dev/null 2>&1; then
            echo "$input"
            return 0
        else
            warning "Invalid input. Please try again."
        fi
    done
}