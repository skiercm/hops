#!/bin/bash

# HOPS - Docker Service Management
# Functions for Docker service management and monitoring
# Version: 3.1.0-beta

# Source common functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

# Service definitions with pinned versions
declare -A HOPS_SERVICES=(
    # Media Management (*arr Stack)
    ["sonarr"]="8989:lscr.io/linuxserver/sonarr:4.0.10"
    ["radarr"]="7878:lscr.io/linuxserver/radarr:5.8.3"
    ["lidarr"]="8686:lscr.io/linuxserver/lidarr:2.5.3"
    ["readarr"]="8787:lscr.io/linuxserver/readarr:0.3.32-develop"
    ["bazarr"]="6767:lscr.io/linuxserver/bazarr:1.4.3"
    ["prowlarr"]="9696:lscr.io/linuxserver/prowlarr:1.24.3"
    ["tdarr"]="8265:ghcr.io/haveagitgat/tdarr:2.26.01"
    
    # Download Clients
    ["qbittorrent"]="8082:lscr.io/linuxserver/qbittorrent:4.6.7"
    ["transmission"]="9091:lscr.io/linuxserver/transmission:4.0.6"
    ["nzbget"]="6789:lscr.io/linuxserver/nzbget:24.3"
    ["sabnzbd"]="8080:lscr.io/linuxserver/sabnzbd:4.3.3"
    
    # Media Servers
    ["jellyfin"]="8096:lscr.io/linuxserver/jellyfin:10.9.11"
    ["plex"]="32400:lscr.io/linuxserver/plex:1.40.5"
    ["emby"]="8096:lscr.io/linuxserver/emby:4.8.8"
    ["jellystat"]="3000:cyfershepard/jellystat:1.1.0"
    
    # Request Management
    ["overseerr"]="5055:lscr.io/linuxserver/overseerr:1.33.2"
    ["jellyseerr"]="5056:fallenbagel/jellyseerr:1.9.2"
    ["ombi"]="3579:lscr.io/linuxserver/ombi:4.43.5"
    
    # Reverse Proxy & Security
    ["traefik"]="8080:traefik:v3.1.6"
    ["nginx-proxy-manager"]="81:jc21/nginx-proxy-manager:2.11.3"
    ["authelia"]="9091:authelia/authelia:4.38.16"
    
    # Monitoring & Management
    ["portainer"]="9000:portainer/portainer-ce:2.21.4"
    ["uptime-kuma"]="3001:louislam/uptime-kuma:1.23.15"
    ["watchtower"]="8080:containrrr/watchtower:1.7.1"
)

# Get service port and image
get_service_info() {
    local service_name="$1"
    local info="${HOPS_SERVICES[$service_name]}"
    
    if [[ -z "$info" ]]; then
        error_exit "Unknown service: $service_name"
    fi
    
    echo "$info"
}

# Get service port
get_service_port() {
    local service_name="$1"
    local info=$(get_service_info "$service_name")
    echo "${info%%:*}"
}

# Get service image
get_service_image() {
    local service_name="$1"
    local info=$(get_service_info "$service_name")
    echo "${info#*:}"
}

# List all available services
list_services() {
    echo "Available HOPS services:"
    echo
    
    local categories=(
        "Media Management:sonarr,radarr,lidarr,readarr,bazarr,prowlarr,tdarr"
        "Download Clients:qbittorrent,transmission,nzbget,sabnzbd"
        "Media Servers:jellyfin,plex,emby,jellystat"
        "Request Management:overseerr,jellyseerr,ombi"
        "Reverse Proxy & Security:traefik,nginx-proxy-manager,authelia"
        "Monitoring & Management:portainer,uptime-kuma,watchtower"
    )
    
    for category in "${categories[@]}"; do
        local category_name="${category%%:*}"
        local services="${category#*:}"
        
        echo -e "${CYAN}${category_name}:${NC}"
        IFS=',' read -ra service_list <<< "$services"
        
        for service in "${service_list[@]}"; do
            local port=$(get_service_port "$service")
            local image=$(get_service_image "$service")
            printf "  %-20s Port: %-6s Image: %s\n" "$service" "$port" "$image"
        done
        echo
    done
}

# Check if service is running
is_service_running() {
    local service_name="$1"
    
    if [[ -z "$service_name" ]]; then
        return 1
    fi
    
    docker ps --format "{{.Names}}" | grep -q "^${service_name}$"
}

# Check if service exists (running or stopped)
service_exists() {
    local service_name="$1"
    
    if [[ -z "$service_name" ]]; then
        return 1
    fi
    
    docker ps -a --format "{{.Names}}" | grep -q "^${service_name}$"
}

# Get service status with health information
get_service_status() {
    local service_name="$1"
    
    if [[ -z "$service_name" ]]; then
        echo "invalid"
        return 1
    fi
    
    if is_service_running "$service_name"; then
        local port=$(get_service_port "$service_name")
        
        # Check if service is accessible
        if curl -sSf --max-time 2 --connect-timeout 1 "http://localhost:${port}" >/dev/null 2>&1; then
            echo "running_accessible"
        else
            # Check if it's still starting up
            local container_uptime=$(docker ps --format "{{.Status}}" --filter "name=^${service_name}$" | grep -oE 'Up [0-9]+ (second|minute)s?')
            if [[ -n "$container_uptime" ]]; then
                echo "running_starting"
            else
                echo "running_error"
            fi
        fi
    elif service_exists "$service_name"; then
        echo "stopped"
    else
        echo "not_found"
    fi
}

# Get detailed service information
get_service_details() {
    local service_name="$1"
    
    if ! service_exists "$service_name"; then
        error_exit "Service $service_name not found"
    fi
    
    local port=$(get_service_port "$service_name")
    local image=$(get_service_image "$service_name")
    local status=$(get_service_status "$service_name")
    
    echo "Service: $service_name"
    echo "Port: $port"
    echo "Image: $image"
    echo "Status: $status"
    
    # Additional Docker info
    if service_exists "$service_name"; then
        echo "Container Info:"
        docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" --filter "name=^${service_name}$"
    fi
}

# Get all running HOPS services
get_running_services() {
    local running_services=()
    
    for service_name in "${!HOPS_SERVICES[@]}"; do
        if is_service_running "$service_name"; then
            running_services+=("$service_name")
        fi
    done
    
    echo "${running_services[@]}"
}

# Get all stopped HOPS services
get_stopped_services() {
    local stopped_services=()
    
    for service_name in "${!HOPS_SERVICES[@]}"; do
        if service_exists "$service_name" && ! is_service_running "$service_name"; then
            stopped_services+=("$service_name")
        fi
    done
    
    echo "${stopped_services[@]}"
}

# Check if Docker daemon is running
check_docker_daemon() {
    if ! docker info >/dev/null 2>&1; then
        error_exit "Docker daemon is not running. Please start Docker and try again."
    fi
}

# Check if Docker Compose is available
check_docker_compose() {
    if ! docker compose version >/dev/null 2>&1; then
        error_exit "Docker Compose not available. Please install Docker Compose v2+"
    fi
}

# Pull service images
pull_service_images() {
    local services=("$@")
    
    if [[ ${#services[@]} -eq 0 ]]; then
        error_exit "No services specified for image pull"
    fi
    
    info "🐳 Pulling Docker images for selected services..."
    
    local total=${#services[@]}
    local current=0
    
    for service in "${services[@]}"; do
        ((current++))
        local image=$(get_service_image "$service")
        
        show_progress "$current" "$total" "Pulling $service ($image)"
        
        if ! docker pull "$image" >/dev/null 2>&1; then
            error_exit "Failed to pull image: $image"
        fi
    done
    
    success "All images pulled successfully"
}

# Create Docker networks
create_docker_networks() {
    local networks=("homelab" "traefik" "database")
    
    info "🌐 Creating Docker networks..."
    
    for network in "${networks[@]}"; do
        if docker network ls --format "{{.Name}}" | grep -q "^${network}$"; then
            debug "Network $network already exists"
        else
            if docker network create "$network" >/dev/null 2>&1; then
                success "Created network: $network"
            else
                error_exit "Failed to create network: $network"
            fi
        fi
    done
}

# Remove Docker networks
remove_docker_networks() {
    local networks=("homelab" "traefik" "database")
    
    info "🗑️ Removing Docker networks..."
    
    for network in "${networks[@]}"; do
        if docker network ls --format "{{.Name}}" | grep -q "^${network}$"; then
            if docker network rm "$network" >/dev/null 2>&1; then
                success "Removed network: $network"
            else
                warning "Failed to remove network: $network (may have active containers)"
            fi
        fi
    done
}

# Check for port conflicts
check_port_conflicts() {
    local services=("$@")
    local conflicts=()
    
    info "🔍 Checking for port conflicts..."
    
    for service in "${services[@]}"; do
        local port=$(get_service_port "$service")
        
        if ! is_port_available "$port"; then
            local process=$(ss -tuln | grep ":$port " | head -n1)
            conflicts+=("$service:$port ($process)")
        fi
    done
    
    if [[ ${#conflicts[@]} -gt 0 ]]; then
        error_exit "Port conflicts detected:\n$(printf '  • %s\n' "${conflicts[@]}")"
    fi
    
    success "No port conflicts detected"
}

# Monitor service health
monitor_service_health() {
    local service_name="$1"
    local timeout="${2:-60}"
    local interval="${3:-5}"
    
    info "🏥 Monitoring health of $service_name..."
    
    local elapsed=0
    local port=$(get_service_port "$service_name")
    
    while [[ $elapsed -lt $timeout ]]; do
        if is_service_running "$service_name"; then
            if curl -sSf --max-time 2 --connect-timeout 1 "http://localhost:${port}" >/dev/null 2>&1; then
                success "$service_name is healthy and accessible"
                return 0
            fi
        else
            warning "$service_name is not running"
            return 1
        fi
        
        sleep "$interval"
        elapsed=$((elapsed + interval))
        
        printf "\r${BLUE}⏳ Waiting for $service_name to become healthy... (${elapsed}s/${timeout}s)${NC}"
    done
    
    echo
    error_exit "$service_name failed to become healthy within ${timeout}s"
}

# Get service logs
get_service_logs() {
    local service_name="$1"
    local lines="${2:-50}"
    
    if ! service_exists "$service_name"; then
        error_exit "Service $service_name not found"
    fi
    
    info "📋 Showing last $lines lines of logs for $service_name:"
    docker logs --tail "$lines" "$service_name" 2>&1
}

# Restart service
restart_service() {
    local service_name="$1"
    
    if ! service_exists "$service_name"; then
        error_exit "Service $service_name not found"
    fi
    
    info "🔄 Restarting $service_name..."
    
    if docker restart "$service_name" >/dev/null 2>&1; then
        success "$service_name restarted successfully"
        monitor_service_health "$service_name" 30
    else
        error_exit "Failed to restart $service_name"
    fi
}

# Stop service
stop_service() {
    local service_name="$1"
    
    if ! is_service_running "$service_name"; then
        warning "$service_name is not running"
        return 0
    fi
    
    info "🛑 Stopping $service_name..."
    
    if docker stop "$service_name" >/dev/null 2>&1; then
        success "$service_name stopped successfully"
    else
        error_exit "Failed to stop $service_name"
    fi
}

# Start service
start_service() {
    local service_name="$1"
    
    if is_service_running "$service_name"; then
        warning "$service_name is already running"
        return 0
    fi
    
    if ! service_exists "$service_name"; then
        error_exit "Service $service_name not found"
    fi
    
    info "▶️ Starting $service_name..."
    
    if docker start "$service_name" >/dev/null 2>&1; then
        success "$service_name started successfully"
        monitor_service_health "$service_name" 30
    else
        error_exit "Failed to start $service_name"
    fi
}

# Remove service
remove_service() {
    local service_name="$1"
    local remove_volumes="${2:-false}"
    
    if ! service_exists "$service_name"; then
        warning "$service_name does not exist"
        return 0
    fi
    
    info "🗑️ Removing $service_name..."
    
    # Stop if running
    if is_service_running "$service_name"; then
        stop_service "$service_name"
    fi
    
    # Remove container
    if docker rm "$service_name" >/dev/null 2>&1; then
        success "$service_name removed successfully"
    else
        error_exit "Failed to remove $service_name"
    fi
    
    # Remove volumes if requested
    if [[ "$remove_volumes" == "true" ]]; then
        info "🗑️ Removing volumes for $service_name..."
        docker volume ls -q | grep "$service_name" | xargs -r docker volume rm 2>/dev/null || true
    fi
}

# Update service image
update_service() {
    local service_name="$1"
    
    if ! service_exists "$service_name"; then
        error_exit "Service $service_name not found"
    fi
    
    local image=$(get_service_image "$service_name")
    
    info "🔄 Updating $service_name to latest image..."
    
    # Pull latest image
    if docker pull "$image" >/dev/null 2>&1; then
        success "Pulled latest image: $image"
    else
        error_exit "Failed to pull image: $image"
    fi
    
    # Restart service to use new image
    restart_service "$service_name"
}

# Clean up unused Docker resources
cleanup_docker() {
    info "🧹 Cleaning up unused Docker resources..."
    
    # Remove unused containers
    docker container prune -f >/dev/null 2>&1
    
    # Remove unused images
    docker image prune -f >/dev/null 2>&1
    
    # Remove unused volumes
    docker volume prune -f >/dev/null 2>&1
    
    # Remove unused networks
    docker network prune -f >/dev/null 2>&1
    
    success "Docker cleanup completed"
}