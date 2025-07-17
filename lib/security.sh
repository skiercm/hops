#!/bin/bash

# HOPS - Security Functions
# Password generation, validation, and security utilities
# Version: 3.1.0

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Password validation
validate_password() {
    local password="$1"
    local min_length="${2:-12}"
    
    # Check minimum length
    if [[ ${#password} -lt $min_length ]]; then
        debug "Password too short: ${#password} < $min_length"
        return 1
    fi
    
    # Check for uppercase letter
    if [[ ! "$password" =~ [A-Z] ]]; then
        debug "Password missing uppercase letter"
        return 2
    fi
    
    # Check for lowercase letter
    if [[ ! "$password" =~ [a-z] ]]; then
        debug "Password missing lowercase letter"
        return 2
    fi
    
    # Check for digit
    if [[ ! "$password" =~ [0-9] ]]; then
        debug "Password missing digit"
        return 2
    fi
    
    # Check for special character
    if [[ ! "$password" =~ [^A-Za-z0-9] ]]; then
        debug "Password missing special character"
        return 2
    fi
    
    return 0
}

# Generate secure password
generate_secure_password() {
    local length="${1:-16}"
    local max_attempts=10
    
    debug "Generating secure password of length $length"
    
    # Try OpenSSL method first
    for ((attempt=1; attempt<=max_attempts; attempt++)); do
        local password
        
        if command_exists openssl; then
            password=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-${length})
        else
            # Fallback to /dev/urandom
            password=$(tr -dc 'A-Za-z0-9!@#$%^&*' < /dev/urandom | head -c${length})
        fi
        
        if validate_password "$password" "$length"; then
            echo "$password"
            return 0
        fi
        
        debug "Password attempt $attempt failed validation"
    done
    
    # Fallback: construct guaranteed compliant password
    debug "Using fallback password generation method"
    
    local upper=$(tr -dc 'A-Z' < /dev/urandom | head -c2)
    local lower=$(tr -dc 'a-z' < /dev/urandom | head -c4)
    local digits=$(tr -dc '0-9' < /dev/urandom | head -c2)
    local symbols=$(tr -dc '!@#$%^&*' < /dev/urandom | head -c2)
    local remaining_length=$((length - 10))
    
    local password=""
    
    if [[ $remaining_length -gt 0 ]]; then
        local remaining=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c$remaining_length)
        password="${upper}${lower}${digits}${symbols}${remaining}"
    else
        password="${upper}${lower}${digits}${symbols}"
    fi
    
    # Shuffle the password
    password=$(echo "$password" | fold -w1 | shuf | tr -d '\n')
    
    echo "$password"
}

# Generate multiple passwords for services
generate_service_passwords() {
    local -A passwords
    
    info "🔐 Generating secure passwords for services..."
    
    # Admin password (16 chars)
    passwords["admin"]=$(generate_secure_password 16)
    
    # Database passwords (20 chars)
    passwords["mysql_root"]=$(generate_secure_password 20)
    passwords["postgres"]=$(generate_secure_password 20)
    
    # Service-specific passwords (16 chars)
    passwords["jellyfin"]=$(generate_secure_password 16)
    passwords["plex"]=$(generate_secure_password 16)
    passwords["traefik"]=$(generate_secure_password 16)
    passwords["authelia"]=$(generate_secure_password 16)
    
    # API keys (32 chars)
    passwords["api_key"]=$(generate_secure_password 32)
    
    # Return as key=value pairs
    for key in "${!passwords[@]}"; do
        echo "${key}=${passwords[$key]}"
    done
}

# Encrypt string using GPG
encrypt_string() {
    local plaintext="$1"
    local passphrase="$2"
    
    if [[ -z "$plaintext" || -z "$passphrase" ]]; then
        error_exit "encrypt_string requires plaintext and passphrase"
    fi
    
    if ! command_exists gpg; then
        error_exit "GPG not available for encryption"
    fi
    
    echo "$plaintext" | gpg --batch --yes --passphrase "$passphrase" --symmetric --cipher-algo AES256 --armor
}

# Decrypt string using GPG
decrypt_string() {
    local encrypted="$1"
    local passphrase="$2"
    
    if [[ -z "$encrypted" || -z "$passphrase" ]]; then
        error_exit "decrypt_string requires encrypted text and passphrase"
    fi
    
    if ! command_exists gpg; then
        error_exit "GPG not available for decryption"
    fi
    
    echo "$encrypted" | gpg --batch --yes --passphrase "$passphrase" --decrypt --quiet
}

# Create encrypted .env file
create_encrypted_env() {
    local env_file="$1"
    local master_password="$2"
    local encrypted_file="${env_file}.gpg"
    
    if [[ ! -f "$env_file" ]]; then
        error_exit "Environment file not found: $env_file"
    fi
    
    if [[ -z "$master_password" ]]; then
        error_exit "Master password required for encryption"
    fi
    
    info "🔐 Encrypting environment file..."
    
    if gpg --batch --yes --passphrase "$master_password" --symmetric --cipher-algo AES256 --armor --output "$encrypted_file" "$env_file"; then
        success "Environment file encrypted: $encrypted_file"
        
        # Securely remove original
        if confirm "Remove original plaintext file?" "y"; then
            shred -vfz -n 3 "$env_file" 2>/dev/null || rm -f "$env_file"
            success "Original file securely removed"
        fi
    else
        error_exit "Failed to encrypt environment file"
    fi
}

# Decrypt .env file
decrypt_env() {
    local encrypted_file="$1"
    local master_password="$2"
    local output_file="${encrypted_file%.gpg}"
    
    if [[ ! -f "$encrypted_file" ]]; then
        error_exit "Encrypted file not found: $encrypted_file"
    fi
    
    if [[ -z "$master_password" ]]; then
        error_exit "Master password required for decryption"
    fi
    
    info "🔓 Decrypting environment file..."
    
    if gpg --batch --yes --passphrase "$master_password" --decrypt --output "$output_file" "$encrypted_file"; then
        success "Environment file decrypted: $output_file"
        
        # Set secure permissions
        chmod 600 "$output_file"
    else
        error_exit "Failed to decrypt environment file"
    fi
}

# Setup file permissions
setup_file_permissions() {
    local target_dir="$1"
    
    if [[ ! -d "$target_dir" ]]; then
        error_exit "Target directory does not exist: $target_dir"
    fi
    
    info "🔒 Setting up secure file permissions..."
    
    # Set directory permissions
    chmod 750 "$target_dir"
    
    # Find and secure sensitive files
    local sensitive_patterns=("*.env" "*.key" "*.pem" "*.crt" "*.conf" "*.yml" "*.yaml")
    
    for pattern in "${sensitive_patterns[@]}"; do
        find "$target_dir" -name "$pattern" -type f -exec chmod 600 {} \; 2>/dev/null || true
    done
    
    # Set ownership if running as sudo
    if [[ -n "$SUDO_USER" ]]; then
        local user_info
        user_info=$(get_user_info)
        
        local uid=$(echo "$user_info" | grep "uid=" | cut -d= -f2)
        local gid=$(echo "$user_info" | grep "gid=" | cut -d= -f2)
        
        chown -R "$uid:$gid" "$target_dir"
    fi
    
    success "File permissions configured"
}

# Generate SSL certificate
generate_ssl_certificate() {
    local domain="$1"
    local cert_dir="$2"
    local key_file="$cert_dir/$domain.key"
    local cert_file="$cert_dir/$domain.crt"
    
    if [[ -z "$domain" || -z "$cert_dir" ]]; then
        error_exit "generate_ssl_certificate requires domain and cert_dir"
    fi
    
    if ! command_exists openssl; then
        error_exit "OpenSSL not available for certificate generation"
    fi
    
    mkdir -p "$cert_dir"
    
    info "🔐 Generating SSL certificate for $domain..."
    
    # Generate private key
    if openssl genrsa -out "$key_file" 2048 >/dev/null 2>&1; then
        chmod 600 "$key_file"
        success "Private key generated: $key_file"
    else
        error_exit "Failed to generate private key"
    fi
    
    # Generate certificate
    if openssl req -new -x509 -key "$key_file" -out "$cert_file" -days 365 -subj "/CN=$domain" >/dev/null 2>&1; then
        chmod 644 "$cert_file"
        success "Certificate generated: $cert_file"
    else
        error_exit "Failed to generate certificate"
    fi
}

# Validate input path (prevent path traversal)
validate_path() {
    local path="$1"
    local allow_relative="${2:-false}"
    
    if [[ -z "$path" ]]; then
        return 1
    fi
    
    # Check for path traversal attempts
    if [[ "$path" =~ \.\./|\.\.\\ ]]; then
        debug "Path traversal attempt detected: $path"
        return 1
    fi
    
    # Check for null bytes
    if [[ "$path" =~ $'\0' ]]; then
        debug "Null byte detected in path: $path"
        return 1
    fi
    
    # Check if relative paths are allowed
    if [[ "$allow_relative" != "true" && "$path" != /* ]]; then
        debug "Relative path not allowed: $path"
        return 1
    fi
    
    return 0
}

# Sanitize filename
sanitize_filename() {
    local filename="$1"
    
    # Remove path separators and dangerous characters
    filename=$(echo "$filename" | tr -d '/' | tr -d '\\' | tr -d '..' | tr -d '\0')
    
    # Remove leading/trailing whitespace
    filename=$(echo "$filename" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    # Limit length
    if [[ ${#filename} -gt 255 ]]; then
        filename="${filename:0:255}"
    fi
    
    echo "$filename"
}

# Validate service name
validate_service_name() {
    local service_name="$1"
    
    if [[ -z "$service_name" ]]; then
        return 1
    fi
    
    # Check for valid characters (alphanumeric, hyphens, underscores)
    if [[ ! "$service_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        return 1
    fi
    
    # Check length
    if [[ ${#service_name} -gt 63 ]]; then
        return 1
    fi
    
    return 0
}

# Check for common security issues
security_audit() {
    local target_dir="$1"
    local issues=()
    
    info "🔍 Performing security audit..."
    
    # Check for world-writable files
    if find "$target_dir" -type f -perm -002 2>/dev/null | head -n1 | read -r; then
        issues+=("World-writable files found")
    fi
    
    # Check for SUID/SGID files
    if find "$target_dir" -type f \( -perm -4000 -o -perm -2000 \) 2>/dev/null | head -n1 | read -r; then
        issues+=("SUID/SGID files found")
    fi
    
    # Check for empty passwords in .env files
    if find "$target_dir" -name "*.env" -type f -exec grep -l "PASSWORD=\|PASS=\|SECRET=" {} \; 2>/dev/null | head -n1 | read -r; then
        if find "$target_dir" -name "*.env" -type f -exec grep -l "PASSWORD=\s*$\|PASS=\s*$\|SECRET=\s*$" {} \; 2>/dev/null | head -n1 | read -r; then
            issues+=("Empty passwords found in .env files")
        fi
    fi
    
    # Check for default credentials
    local default_patterns=("password\|admin\|root\|123456\|password123")
    for pattern in "${default_patterns[@]}"; do
        if find "$target_dir" -name "*.env" -type f -exec grep -il "$pattern" {} \; 2>/dev/null | head -n1 | read -r; then
            issues+=("Potential default credentials found")
            break
        fi
    done
    
    # Report issues
    if [[ ${#issues[@]} -gt 0 ]]; then
        warning "Security issues found:"
        for issue in "${issues[@]}"; do
            warning "  • $issue"
        done
        return 1
    else
        success "No security issues detected"
        return 0
    fi
}

# Create backup with encryption
create_encrypted_backup() {
    local source_dir="$1"
    local backup_file="$2"
    local password="$3"
    
    if [[ ! -d "$source_dir" ]]; then
        error_exit "Source directory does not exist: $source_dir"
    fi
    
    if [[ -z "$password" ]]; then
        error_exit "Password required for encrypted backup"
    fi
    
    info "💾 Creating encrypted backup..."
    
    # Create tar archive and encrypt
    if tar -czf - "$source_dir" | gpg --batch --yes --passphrase "$password" --symmetric --cipher-algo AES256 --armor > "$backup_file"; then
        success "Encrypted backup created: $backup_file"
        
        # Set secure permissions
        chmod 600 "$backup_file"
    else
        error_exit "Failed to create encrypted backup"
    fi
}

# Restore from encrypted backup
restore_encrypted_backup() {
    local backup_file="$1"
    local restore_dir="$2"
    local password="$3"
    
    if [[ ! -f "$backup_file" ]]; then
        error_exit "Backup file does not exist: $backup_file"
    fi
    
    if [[ -z "$password" ]]; then
        error_exit "Password required for backup restoration"
    fi
    
    info "📦 Restoring from encrypted backup..."
    
    if gpg --batch --yes --passphrase "$password" --decrypt "$backup_file" | tar -xzf - -C "$restore_dir"; then
        success "Backup restored to: $restore_dir"
        
        # Set secure permissions
        setup_file_permissions "$restore_dir"
    else
        error_exit "Failed to restore encrypted backup"
    fi
}