# Supported Services

HOPS supports a comprehensive collection of homelab services across multiple categories. All services use LinuxServer.io containers for consistency and reliability.

## 📺 Media Management (*arr Stack)

### Sonarr - TV Series Management
**Purpose**: Automatic TV show downloading and management  
**Default Port**: 8989  
**Support**: [github.com/Sonarr/Sonarr](https://github.com/Sonarr/Sonarr)  
**Documentation**: [wiki.servarr.com/sonarr](https://wiki.servarr.com/sonarr)

### Radarr - Movie Management
**Purpose**: Automatic movie downloading and management  
**Default Port**: 7878  
**Support**: [github.com/Radarr/Radarr](https://github.com/Radarr/Radarr)  
**Documentation**: [wiki.servarr.com/radarr](https://wiki.servarr.com/radarr)

### Lidarr - Music Management
**Purpose**: Automatic music downloading and management  
**Default Port**: 8686  
**Support**: [github.com/Lidarr/Lidarr](https://github.com/Lidarr/Lidarr)  
**Documentation**: [wiki.servarr.com/lidarr](https://wiki.servarr.com/lidarr)

### Readarr - eBook Management
**Purpose**: Automatic eBook and audiobook downloading  
**Default Port**: 8787  
**Support**: [github.com/Readarr/Readarr](https://github.com/Readarr/Readarr)  
**Documentation**: [wiki.servarr.com/readarr](https://wiki.servarr.com/readarr)  
**Status**: ⚠️ Project retired, limited support

### Bazarr - Subtitle Management
**Purpose**: Automatic subtitle downloading for movies and TV  
**Default Port**: 6767  
**Support**: [github.com/morpheus65535/bazarr](https://github.com/morpheus65535/bazarr)  
**Documentation**: [wiki.bazarr.media](https://wiki.bazarr.media)

### Prowlarr - Indexer Management
**Purpose**: Centralized indexer management for *arr applications  
**Default Port**: 9696  
**Support**: [github.com/Prowlarr/Prowlarr](https://github.com/Prowlarr/Prowlarr)  
**Documentation**: [wiki.servarr.com/prowlarr](https://wiki.servarr.com/prowlarr)

### Tdarr - Media Transcoding
**Purpose**: Automated media transcoding and health checking  
**Default Port**: 8265  
**Support**: [github.com/HaveAGitGat/Tdarr](https://github.com/HaveAGitGat/Tdarr)  
**Documentation**: [docs.tdarr.io](https://docs.tdarr.io)

### Huntarr - Missing Media Discovery
**Purpose**: Automated discovery and addition of missing media  
**Default Port**: 7879  
**Support**: [github.com/plexguide/Huntarr.io](https://github.com/plexguide/Huntarr.io)  
**Documentation**: Community-driven

## ⬇️ Download Clients

### qBittorrent - BitTorrent Client
**Purpose**: Feature-rich BitTorrent client with web interface  
**Default Port**: 8080  
**Support**: [github.com/qbittorrent/qBittorrent](https://github.com/qbittorrent/qBittorrent)  
**Documentation**: [github.com/qbittorrent/qBittorrent/wiki](https://github.com/qbittorrent/qBittorrent/wiki)

### Transmission - Lightweight BitTorrent
**Purpose**: Simple, lightweight BitTorrent client  
**Default Port**: 9091  
**Support**: [github.com/transmission/transmission](https://github.com/transmission/transmission)  
**Documentation**: [transmissionbt.com](https://transmissionbt.com)

### NZBGet - Usenet Downloader
**Purpose**: Efficient Usenet binary newsreader  
**Default Port**: 6789  
**Support**: [github.com/nzbget/nzbget](https://github.com/nzbget/nzbget)  
**Documentation**: [nzbget.net/documentation](https://nzbget.net/documentation)

### SABnzbd - Usenet Client
**Purpose**: Popular web-based Usenet client  
**Default Port**: 8081  
**Support**: [github.com/sabnzbd/sabnzbd](https://github.com/sabnzbd/sabnzbd)  
**Documentation**: [sabnzbd.org/wiki](https://sabnzbd.org/wiki)

## 🎞️ Media Servers

### Jellyfin - Open Source Media Server
**Purpose**: Free, open-source media server and entertainment hub  
**Default Port**: 8096  
**Support**: [github.com/jellyfin/jellyfin](https://github.com/jellyfin/jellyfin)  
**Documentation**: [jellyfin.org/docs](https://jellyfin.org/docs)  
**Features**: No licensing fees, privacy-focused, extensive format support

### Plex - Media Server Platform
**Purpose**: Popular media server with premium features  
**Default Port**: 32400  
**Support**: [github.com/plexinc/pms-docker](https://github.com/plexinc/pms-docker)  
**Documentation**: [support.plex.tv](https://support.plex.tv)  
**Features**: Remote access, premium features with Plex Pass

### Emby - Personal Media Server
**Purpose**: Feature-rich personal media server  
**Default Port**: 8097  
**Support**: [github.com/MediaBrowser/Emby](https://github.com/MediaBrowser/Emby)  
**Documentation**: [emby.media/support](https://emby.media/support)  
**Features**: Premium features available, family-friendly

### Jellystat - Jellyfin Statistics
**Purpose**: Advanced statistics and monitoring for Jellyfin  
**Default Port**: 3000  
**Support**: [github.com/CyferShepard/Jellystat](https://github.com/CyferShepard/Jellystat)  
**Documentation**: GitHub repository  
**Requirements**: Requires Jellyfin server

## 🎛️ Request Management

### Overseerr - Plex Request Management
**Purpose**: Media discovery and request management for Plex  
**Default Port**: 5055  
**Support**: [github.com/sct/overseerr](https://github.com/sct/overseerr)  
**Documentation**: [docs.overseerr.dev](https://docs.overseerr.dev)  
**Integration**: Plex, Sonarr, Radarr

### Jellyseerr - Jellyfin Request Management
**Purpose**: Media requests for Jellyfin, Emby, and Plex  
**Default Port**: 5056  
**Support**: [github.com/fallenbagel/jellyseerr](https://github.com/fallenbagel/jellyseerr)  
**Documentation**: [docs.jellyseerr.dev](https://docs.jellyseerr.dev)  
**Integration**: Jellyfin, Emby, Plex, Sonarr, Radarr

### Ombi - Media Request Platform
**Purpose**: User-friendly media request and discovery platform  
**Default Port**: 3579  
**Support**: [github.com/Ombi-app/Ombi](https://github.com/Ombi-app/Ombi)  
**Documentation**: [docs.ombi.app](https://docs.ombi.app)  
**Integration**: Plex, Emby, Jellyfin

## 🔒 Reverse Proxy & Security

### Traefik - Modern Reverse Proxy
**Purpose**: Automatic reverse proxy with SSL certificate management  
**Default Ports**: 80, 443, 8080 (dashboard)  
**Support**: [github.com/traefik/traefik](https://github.com/traefik/traefik)  
**Documentation**: [doc.traefik.io/traefik](https://doc.traefik.io/traefik)  
**Features**: Automatic SSL, service discovery, load balancing

### Nginx Proxy Manager - Easy Reverse Proxy
**Purpose**: User-friendly web interface for Nginx reverse proxy  
**Default Ports**: 80, 443, 81 (admin)  
**Support**: [github.com/NginxProxyManager/nginx-proxy-manager](https://github.com/NginxProxyManager/nginx-proxy-manager)  
**Documentation**: [nginxproxymanager.com/guide](https://nginxproxymanager.com/guide)  
**Features**: Web GUI, SSL automation, access lists

### Caddy - Automatic HTTPS Web Server
**Purpose**: Modern web server with automatic HTTPS  
**Default Ports**: 80, 443, 2019 (admin)  
**Support**: [github.com/caddyserver/caddy](https://github.com/caddyserver/caddy)  
**Documentation**: [caddyserver.com/docs](https://caddyserver.com/docs)  
**Note**: ⚠️ **Configuration not included** - Users must provide their own Caddyfile

### Authelia - Authentication & Authorization
**Purpose**: Multi-factor authentication and single sign-on  
**Default Port**: 9091  
**Support**: [github.com/authelia/authelia](https://github.com/authelia/authelia)  
**Documentation**: [authelia.com/integration](https://www.authelia.com/integration)  
**Features**: 2FA, LDAP, OAuth2, OIDC

## 📈 Monitoring & Management

### Portainer - Container Management
**Purpose**: Web-based Docker container management interface  
**Default Port**: 9000  
**Support**: [github.com/portainer/portainer](https://github.com/portainer/portainer)  
**Documentation**: [docs.portainer.io](https://docs.portainer.io)  
**Features**: Container management, stack deployment, monitoring

### Uptime Kuma - Service Monitoring
**Purpose**: Self-hosted uptime monitoring tool  
**Default Port**: 3001  
**Support**: [github.com/louislam/uptime-kuma](https://github.com/louislam/uptime-kuma)  
**Documentation**: [github.com/louislam/uptime-kuma/wiki](https://github.com/louislam/uptime-kuma/wiki)  
**Features**: Multiple protocols, notifications, status pages

### Watchtower - Automatic Updates
**Purpose**: Automatic Docker container updating  
**Default Port**: None (background service)  
**Support**: [github.com/containrrr/watchtower](https://github.com/containrrr/watchtower)  
**Documentation**: [containrrr.dev/watchtower](https://containrrr.dev/watchtower)  
**Features**: Scheduled updates, notifications, selective updating

## 🔧 Service Dependencies

### Common Dependencies
Most services depend on:
- **Docker** and **Docker Compose**
- **Shared network** (`homelab` network)
- **Volume mounts** for configuration and data
- **Environment variables** (PUID, PGID, TZ)

### Integration Patterns

#### Media Management Workflow
1. **Prowlarr** → Manages indexers for all *arr services
2. **Sonarr/Radarr** → Monitors for new releases
3. **Download Client** (qBittorrent/Transmission) → Downloads content
4. **Media Server** (Jellyfin/Plex) → Serves content to users
5. **Request System** (Overseerr/Jellyseerr) → User requests interface

#### Security & Access
1. **Reverse Proxy** (Traefik/Nginx) → External access with SSL
2. **Authelia** → Authentication layer
3. **Firewall** → Network security (UFW on Linux)

#### Monitoring Stack
1. **Portainer** → Container management
2. **Uptime Kuma** → Service monitoring
3. **Watchtower** → Automatic updates

## ⚠️ Important Service Notes

### Caddy Configuration
HOPS provides the Caddy container but **does not include Caddyfile configuration**. Users must:
1. Create their own Caddyfile in `~/hops/config/caddy/`
2. Configure reverse proxy rules
3. Set up SSL certificates (automatic with proper domain configuration)

**Example minimal Caddyfile:**
```
example.com {
    reverse_proxy jellyfin:8096
}

radarr.example.com {
    reverse_proxy radarr:7878
}
```

### GPU Support
- **Linux**: Intel GPU support via `/dev/dri` passthrough
- **macOS**: No GPU acceleration available
- **Windows**: Limited GPU support in WSL2

### Service Health Checks
All web-based services include health checks for:
- Service startup verification
- Automatic restart on failure
- Status monitoring integration

## 🆘 Service-Specific Support

### When to Contact Service Developers

**Contact individual service developers for:**
- Service configuration help
- Feature requests
- Bugs within the service itself
- Service-specific documentation
- Advanced service setup

**Contact HOPS for:**
- Docker Compose generation issues
- Service deployment problems
- Cross-platform compatibility
- Installation and automation issues

### Getting Service Help

1. **Check service documentation** (links provided above)
2. **Review service GitHub issues** for known problems
3. **Check service community forums** (Reddit, Discord, etc.)
4. **Consult LinuxServer.io documentation** for container-specific issues
5. **Submit issues to appropriate repositories** with proper logs and details

### Common Service Issues

#### Permission Problems
```bash
# Fix ownership for Linux
sudo chown -R $USER:$USER /opt/appdata/[service-name]

# Fix ownership for macOS
sudo chown -R $USER:$USER ~/hops/config/[service-name]
```

#### Service Won't Start
```bash
# Check service logs
docker compose logs [service-name]

# Restart service
docker compose restart [service-name]
```

#### Configuration Issues
Most services store configuration in:
- **Linux**: `/opt/appdata/[service-name]/`
- **macOS**: `~/hops/config/[service-name]/`
- **Windows**: `/opt/appdata/[service-name]/` (in WSL2)

---

For installation help, see [INSTALLATION.md](INSTALLATION.md).  
For advanced configuration, see [ADVANCED.md](ADVANCED.md).