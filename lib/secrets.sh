#!/bin/bash

# HOPS - Secret Management System
# Secure encryption and management of sensitive configuration data
# Version: 3.1.0-beta

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"
source "$SCRIPT_DIR/security.sh"

# Default configuration
readonly SECRETS_DIR="/etc/hops/secrets"
readonly MASTER_KEY_FILE="$SECRETS_DIR/master.key"
readonly ENCRYPTED_ENV_FILE="$SECRETS_DIR/environment.gpg"
readonly DECRYPTED_ENV_FILE="/tmp/hops_env_$$"

# Initialize secrets management
init_secrets() {
    info "🔐 Initializing secrets management..."
    
    # Create secrets directory
    if ! mkdir -p "$SECRETS_DIR"; then
        error_exit "Failed to create secrets directory: $SECRETS_DIR"
    fi
    
    # Set secure permissions
    chmod 700 "$SECRETS_DIR"
    
    # Generate master key if it doesn't exist
    if [[ ! -f "$MASTER_KEY_FILE" ]]; then
        generate_master_key
    fi
    
    success "Secrets management initialized"
}

# Generate master encryption key
generate_master_key() {
    info "🔑 Generating master encryption key..."
    
    # Generate 256-bit key
    local master_key
    master_key=$(openssl rand -hex 32)
    
    if [[ -z "$master_key" ]]; then
        error_exit "Failed to generate master key"
    fi
    
    # Store master key securely
    echo "$master_key" > "$MASTER_KEY_FILE"
    chmod 600 "$MASTER_KEY_FILE"
    
    success "Master key generated and stored securely"
}

# Get master key
get_master_key() {
    if [[ ! -f "$MASTER_KEY_FILE" ]]; then
        error_exit "Master key file not found: $MASTER_KEY_FILE"
    fi
    
    if [[ ! -r "$MASTER_KEY_FILE" ]]; then
        error_exit "Cannot read master key file: $MASTER_KEY_FILE"
    fi
    
    cat "$MASTER_KEY_FILE"
}

# Encrypt environment file
encrypt_environment() {
    local env_file="$1"
    local output_file="${2:-$ENCRYPTED_ENV_FILE}"
    
    if [[ ! -f "$env_file" ]]; then
        error_exit "Environment file not found: $env_file"
    fi
    
    info "🔒 Encrypting environment file..."
    
    local master_key
    master_key=$(get_master_key)
    
    # Encrypt using AES-256-GCM
    if openssl enc -aes-256-gcm -salt -in "$env_file" -out "$output_file" -pass pass:"$master_key"; then
        success "Environment file encrypted: $output_file"
        
        # Set secure permissions
        chmod 600 "$output_file"
        
        # Optionally remove original
        if confirm "Remove original plaintext file?" "y"; then
            secure_delete "$env_file"
        fi
    else
        error_exit "Failed to encrypt environment file"
    fi
}

# Decrypt environment file
decrypt_environment() {
    local encrypted_file="${1:-$ENCRYPTED_ENV_FILE}"
    local output_file="${2:-$DECRYPTED_ENV_FILE}"
    
    if [[ ! -f "$encrypted_file" ]]; then
        error_exit "Encrypted file not found: $encrypted_file"
    fi
    
    debug "Decrypting environment file..."
    
    local master_key
    master_key=$(get_master_key)
    
    # Decrypt using AES-256-GCM
    if openssl enc -aes-256-gcm -d -salt -in "$encrypted_file" -out "$output_file" -pass pass:"$master_key"; then
        debug "Environment file decrypted: $output_file"
        
        # Set secure permissions
        chmod 600 "$output_file"
        
        # Register for cleanup on exit
        trap "secure_delete '$output_file'" EXIT
        
        echo "$output_file"
    else
        error_exit "Failed to decrypt environment file"
    fi
}

# Secure delete file
secure_delete() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        return 0
    fi
    
    debug "Securely deleting: $file"
    
    # Use shred if available, otherwise multiple overwrites
    if command_exists shred; then
        shred -vfz -n 3 "$file" 2>/dev/null
    else
        # Manual secure deletion
        local file_size
        file_size=$(stat -c%s "$file" 2>/dev/null || echo "0")
        
        if [[ "$file_size" -gt 0 ]]; then
            # Overwrite with random data
            dd if=/dev/urandom of="$file" bs="$file_size" count=1 2>/dev/null
            # Overwrite with zeros
            dd if=/dev/zero of="$file" bs="$file_size" count=1 2>/dev/null
        fi
        
        rm -f "$file"
    fi
}

# Create encrypted environment file with secrets
create_encrypted_environment() {
    local output_file="${1:-$ENCRYPTED_ENV_FILE}"
    
    info "🔐 Creating encrypted environment configuration..."
    
    # Generate secure passwords
    local admin_password
    local mysql_password
    local postgres_password
    local api_key
    
    admin_password=$(generate_secure_password 16)
    mysql_password=$(generate_secure_password 20)
    postgres_password=$(generate_secure_password 20)
    api_key=$(generate_secure_password 32)
    
    # Get user input for configuration
    local puid pgid timezone domain email data_root config_root
    
    puid=$(read_and_validate "Enter PUID (user ID)" "uid" "" "1000")
    pgid=$(read_and_validate "Enter PGID (group ID)" "gid" "" "1000")
    timezone=$(read_and_validate "Enter timezone" "timezone" "" "UTC")
    domain=$(read_and_validate "Enter domain (optional)" "domain" "" "localhost" "true")
    email=$(read_and_validate "Enter email for SSL certificates" "email" "" "" "false")
    data_root=$(read_and_validate "Enter data root directory" "path" "true" "/mnt/media")
    config_root=$(read_and_validate "Enter config root directory" "path" "true" "/opt/appdata")
    
    # Create temporary environment file
    local temp_env_file="/tmp/hops_env_new_$$"
    
    cat > "$temp_env_file" << EOF
# HOPS Environment Configuration
# Generated on: $(date)
# Version: 3.1.0-beta

# Core Configuration
PUID=$puid
PGID=$pgid
TZ=$timezone

# Directory Configuration
DATA_ROOT=$data_root
CONFIG_ROOT=$config_root

# Network Configuration
DOMAIN=$domain
ACME_EMAIL=$email

# Security Configuration
DEFAULT_ADMIN_PASSWORD=$admin_password
MYSQL_ROOT_PASSWORD=$mysql_password
POSTGRES_PASSWORD=$postgres_password
API_KEY=$api_key

# Service-specific passwords
JELLYFIN_PASSWORD=$(generate_secure_password 16)
PLEX_PASSWORD=$(generate_secure_password 16)
TRAEFIK_PASSWORD=$(generate_secure_password 16)
AUTHELIA_PASSWORD=$(generate_secure_password 16)

# Database Configuration
MYSQL_DATABASE=homelab
MYSQL_USER=homelab
MYSQL_PASSWORD=$mysql_password

POSTGRES_DB=homelab
POSTGRES_USER=homelab
POSTGRES_PASSWORD=$postgres_password

# Optional: Cloudflare API (for DNS challenge)
CF_API_EMAIL=
CF_API_KEY=

# Optional: Plex Claim Token
PLEX_CLAIM=

# Optional: Advertise IP for Plex
ADVERTISE_IP=
EOF
    
    # Encrypt the environment file
    encrypt_environment "$temp_env_file" "$output_file"
    
    # Clean up temporary file
    secure_delete "$temp_env_file"
    
    success "Encrypted environment configuration created: $output_file"
}

# Load encrypted environment into current shell
load_encrypted_environment() {
    local encrypted_file="${1:-$ENCRYPTED_ENV_FILE}"
    
    if [[ ! -f "$encrypted_file" ]]; then
        error_exit "Encrypted environment file not found: $encrypted_file"
    fi
    
    debug "Loading encrypted environment..."
    
    # Decrypt to temporary file
    local temp_env
    temp_env=$(decrypt_environment "$encrypted_file")
    
    # Source the decrypted environment
    set -a  # Automatically export all variables
    source "$temp_env"
    set +a  # Stop auto-export
    
    success "Environment loaded successfully"
}

# Update encrypted environment
update_encrypted_environment() {
    local encrypted_file="${1:-$ENCRYPTED_ENV_FILE}"
    local key="$2"
    local value="$3"
    
    if [[ -z "$key" || -z "$value" ]]; then
        error_exit "Key and value are required for update"
    fi
    
    info "🔄 Updating encrypted environment..."
    
    # Decrypt current environment
    local temp_env
    temp_env=$(decrypt_environment "$encrypted_file")
    
    # Create updated environment file
    local updated_env="/tmp/hops_env_updated_$$"
    
    # Copy existing environment, updating the specified key
    local key_found=false
    while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*${key}[[:space:]]*= ]]; then
            echo "$key=$value"
            key_found=true
        else
            echo "$line"
        fi
    done < "$temp_env" > "$updated_env"
    
    # If key wasn't found, add it
    if [[ "$key_found" != "true" ]]; then
        echo "$key=$value" >> "$updated_env"
    fi
    
    # Encrypt updated environment
    encrypt_environment "$updated_env" "$encrypted_file"
    
    # Clean up temporary files
    secure_delete "$temp_env"
    secure_delete "$updated_env"
    
    success "Environment updated successfully"
}

# Get value from encrypted environment
get_encrypted_value() {
    local encrypted_file="${1:-$ENCRYPTED_ENV_FILE}"
    local key="$2"
    
    if [[ -z "$key" ]]; then
        error_exit "Key is required"
    fi
    
    # Decrypt environment
    local temp_env
    temp_env=$(decrypt_environment "$encrypted_file")
    
    # Get value
    local value
    value=$(grep "^${key}=" "$temp_env" | cut -d= -f2- | tr -d '"')
    
    # Clean up
    secure_delete "$temp_env"
    
    echo "$value"
}

# List all keys in encrypted environment
list_encrypted_keys() {
    local encrypted_file="${1:-$ENCRYPTED_ENV_FILE}"
    
    info "📋 Environment configuration keys:"
    
    # Decrypt environment
    local temp_env
    temp_env=$(decrypt_environment "$encrypted_file")
    
    # List keys (exclude comments and empty lines)
    grep -E "^[A-Za-z_][A-Za-z0-9_]*=" "$temp_env" | cut -d= -f1 | sort
    
    # Clean up
    secure_delete "$temp_env"
}

# Backup encrypted environment
backup_encrypted_environment() {
    local encrypted_file="${1:-$ENCRYPTED_ENV_FILE}"
    local backup_file="${2:-$SECRETS_DIR/environment_backup_$(date +%Y%m%d_%H%M%S).gpg}"
    
    if [[ ! -f "$encrypted_file" ]]; then
        error_exit "Encrypted environment file not found: $encrypted_file"
    fi
    
    info "💾 Creating backup of encrypted environment..."
    
    if cp "$encrypted_file" "$backup_file"; then
        chmod 600 "$backup_file"
        success "Backup created: $backup_file"
        echo "$backup_file"
    else
        error_exit "Failed to create backup"
    fi
}

# Restore encrypted environment from backup
restore_encrypted_environment() {
    local backup_file="$1"
    local target_file="${2:-$ENCRYPTED_ENV_FILE}"
    
    if [[ ! -f "$backup_file" ]]; then
        error_exit "Backup file not found: $backup_file"
    fi
    
    if [[ -f "$target_file" ]]; then
        if ! confirm "Overwrite existing environment file?" "n"; then
            info "Restore cancelled"
            return 0
        fi
    fi
    
    info "📦 Restoring encrypted environment from backup..."
    
    if cp "$backup_file" "$target_file"; then
        chmod 600 "$target_file"
        success "Environment restored from backup"
    else
        error_exit "Failed to restore from backup"
    fi
}

# Change master key (re-encrypt all data)
change_master_key() {
    local old_key_file="$MASTER_KEY_FILE"
    local new_key_file="${MASTER_KEY_FILE}.new"
    
    if [[ ! -f "$old_key_file" ]]; then
        error_exit "Master key file not found: $old_key_file"
    fi
    
    warning "Changing master key will re-encrypt all stored secrets"
    if ! confirm "Continue?" "n"; then
        info "Master key change cancelled"
        return 0
    fi
    
    info "🔑 Changing master key..."
    
    # Backup current encrypted environment
    local backup_file
    backup_file=$(backup_encrypted_environment)
    
    # Decrypt current environment
    local temp_env
    temp_env=$(decrypt_environment)
    
    # Generate new master key
    local new_master_key
    new_master_key=$(openssl rand -hex 32)
    echo "$new_master_key" > "$new_key_file"
    chmod 600 "$new_key_file"
    
    # Move new key to replace old key
    mv "$new_key_file" "$old_key_file"
    
    # Re-encrypt environment with new key
    encrypt_environment "$temp_env" "$ENCRYPTED_ENV_FILE"
    
    # Clean up
    secure_delete "$temp_env"
    
    success "Master key changed successfully"
    success "Backup created: $backup_file"
}

# Verify encrypted environment integrity
verify_encrypted_environment() {
    local encrypted_file="${1:-$ENCRYPTED_ENV_FILE}"
    
    info "🔍 Verifying encrypted environment integrity..."
    
    # Try to decrypt
    local temp_env
    if temp_env=$(decrypt_environment "$encrypted_file" 2>/dev/null); then
        # Verify it's a valid environment file
        if grep -q "^PUID=" "$temp_env" && grep -q "^PGID=" "$temp_env"; then
            success "Environment file integrity verified"
            secure_delete "$temp_env"
            return 0
        else
            error_exit "Decrypted file is not a valid environment file"
        fi
    else
        error_exit "Failed to decrypt environment file - possible corruption"
    fi
}

# Main function for command line usage
main() {
    local action="$1"
    shift
    
    case "$action" in
        "init")
            init_secrets
            ;;
        
        "create")
            create_encrypted_environment "$@"
            ;;
        
        "encrypt")
            if [[ $# -eq 0 ]]; then
                error_exit "Usage: $0 encrypt <env_file> [output_file]"
            fi
            encrypt_environment "$@"
            ;;
        
        "decrypt")
            decrypt_environment "$@"
            ;;
        
        "update")
            if [[ $# -lt 2 ]]; then
                error_exit "Usage: $0 update <key> <value> [file]"
            fi
            update_encrypted_environment "${3:-$ENCRYPTED_ENV_FILE}" "$1" "$2"
            ;;
        
        "get")
            if [[ $# -eq 0 ]]; then
                error_exit "Usage: $0 get <key> [file]"
            fi
            get_encrypted_value "${2:-$ENCRYPTED_ENV_FILE}" "$1"
            ;;
        
        "list")
            list_encrypted_keys "$@"
            ;;
        
        "backup")
            backup_encrypted_environment "$@"
            ;;
        
        "restore")
            if [[ $# -eq 0 ]]; then
                error_exit "Usage: $0 restore <backup_file> [target_file]"
            fi
            restore_encrypted_environment "$@"
            ;;
        
        "change-key")
            change_master_key
            ;;
        
        "verify")
            verify_encrypted_environment "$@"
            ;;
        
        "help"|"--help"|"-h")
            cat <<EOF
HOPS Secret Management System

Usage: $0 <action> [options]

Actions:
  init                           Initialize secrets management
  create                         Create new encrypted environment
  encrypt <env_file>             Encrypt environment file
  decrypt [encrypted_file]       Decrypt environment file
  update <key> <value>           Update environment value
  get <key>                      Get environment value
  list                           List all environment keys
  backup                         Backup encrypted environment
  restore <backup_file>          Restore from backup
  change-key                     Change master encryption key
  verify                         Verify environment integrity
  help                           Show this help message

Examples:
  $0 init
  $0 create
  $0 encrypt /path/to/.env
  $0 update DOMAIN example.com
  $0 get PUID
  $0 backup
  $0 verify

EOF
            ;;
        
        *)
            error_exit "Unknown action: $action. Use 'help' for usage information."
            ;;
    esac
}

# If script is run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Initialize logging
    setup_logging "secrets"
    
    # Require root for secrets management
    check_root
    
    main "$@"
fi