# HOPS Troubleshooting Guide

This document provides solutions to common issues encountered when installing and running HOPS.

## Docker Repository Issues

### Linux Mint Docker Repository Error

**Symptoms:**
```
E: The repository 'https://download.docker.com/linux/ubuntu xia Release' does not have a Release file.
N: Updating from such a repository can't be done securely, and is therefore disabled by default.
```

**Root Cause:**
Linux Mint uses its own codenames (e.g., "xia", "vera", "vanessa") that don't exist in Docker's Ubuntu repositories. Docker only supports Ubuntu codenames like "noble", "jammy", "focal".

**Solution:**
This issue has been resolved in HOPS v3.3.0+. The system now automatically detects the correct Ubuntu codename for Linux Mint installations using `UBUNTU_CODENAME` from `/etc/os-release`.

**Manual Fix (if needed):**
1. **Clean existing Docker repositories:**
   ```bash
   sudo rm -f /etc/apt/sources.list.d/docker*
   sudo rm -f /etc/apt/sources.list.d/*docker*
   sudo rm -f /usr/share/keyrings/docker*
   sudo rm -f /etc/apt/keyrings/docker*
   sudo apt clean
   ```

2. **Verify Ubuntu codename detection:**
   ```bash
   grep '^UBUNTU_CODENAME=' /etc/os-release
   # Should return: UBUNTU_CODENAME=noble (for Linux Mint 22.x)
   ```

3. **Update HOPS to latest version:**
   ```bash
   cd ~/hops
   git pull
   sudo ./hops --update
   ```

### Docker Installation Fails

**Symptoms:**
- `Package 'docker-ce' has no installation candidate`
- `Cannot connect to the Docker daemon at unix:///var/run/docker.sock`

**Solutions:**

1. **Check Docker service status:**
   ```bash
   sudo systemctl status docker
   sudo systemctl status docker.socket
   ```

2. **Fix missing Docker group:**
   ```bash
   sudo groupadd docker
   sudo usermod -aG docker $USER
   sudo chown root:docker /var/run/docker.sock
   ```

3. **Start Docker services:**
   ```bash
   sudo systemctl start docker.socket
   sudo systemctl start docker
   sudo systemctl enable docker
   ```

4. **Verify Docker installation:**
   ```bash
   sudo docker --version
   sudo docker compose version
   sudo docker info
   ```

## Directory and Permission Issues

### Homelab Directory Not Found

**Symptoms:**
```
ERROR: Homelab directory not found: /root/hops
```

**Root Cause:**
When running with `sudo`, the script may look for files in `/root/hops` instead of the user's home directory.

**Solution:**
This issue has been resolved in HOPS v3.3.0+. The system now properly detects the original user's home directory when running with sudo.

**Manual Workaround:**
```bash
# Ensure you're in the correct directory
cd ~/hops
sudo ./hops
```

### Permission Denied Errors

**Symptoms:**
- Permission denied accessing Docker socket
- Cannot create directories in `/opt/appdata`

**Solutions:**

1. **Fix Docker permissions:**
   ```bash
   sudo usermod -aG docker $USER
   # Log out and log back in, or run:
   newgrp docker
   ```

2. **Fix directory permissions:**
   ```bash
   sudo chown -R $USER:$USER ~/hops
   sudo chmod -R 755 ~/hops
   ```

## Service Access Issues

### Cannot Access Service Web UI

**Symptoms:**
- Service shows as running but web UI is not accessible
- Connection refused errors

**Solutions:**

1. **Check container status:**
   ```bash
   cd ~/hops
   sudo docker compose ps
   sudo docker compose logs [service-name]
   ```

2. **Verify port availability:**
   ```bash
   sudo netstat -tlnp | grep :8989  # For Sonarr
   sudo ss -tlnp | grep :8989       # Alternative command
   ```

3. **Check firewall settings:**
   ```bash
   sudo ufw status
   # If needed, allow ports:
   sudo ufw allow 8989  # Example for Sonarr
   ```

4. **Restart services:**
   ```bash
   cd ~/hops
   sudo docker compose restart [service-name]
   ```

## Network Issues

### Docker Network Creation Fails

**Symptoms:**
- `Error response from daemon: network with name [network] already exists`
- Network connectivity issues between containers

**Solutions:**

1. **List existing networks:**
   ```bash
   sudo docker network ls
   ```

2. **Remove conflicting networks:**
   ```bash
   sudo docker network rm traefik homelab
   ```

3. **Recreate networks:**
   ```bash
   cd ~/hops
   sudo docker compose up -d
   ```

## System Requirements

### Insufficient Resources

**Symptoms:**
- Services randomly stopping
- Out of memory errors
- Slow performance

**Solutions:**

1. **Check system resources:**
   ```bash
   free -h    # Memory usage
   df -h      # Disk usage
   top        # CPU and memory usage
   ```

2. **Minimum requirements:**
   - RAM: 2GB minimum, 4GB+ recommended
   - Disk: 10GB minimum, 50GB+ recommended for media
   - CPU: 2 cores minimum

3. **Optimize services:**
   - Disable unnecessary services
   - Adjust container resource limits
   - Use external storage for media files

## Getting Help

### Log Files

Check HOPS log files for detailed error information:

**Linux:**
```bash
sudo tail -f /var/log/hops/hops-main-*.log
```

**macOS:**
```bash
sudo tail -f /usr/local/var/log/hops/hops-main-*.log
```

### Docker Compose Logs

```bash
cd ~/hops
sudo docker compose logs -f [service-name]
```

### System Information

When reporting issues, include:

```bash
# System information
lsb_release -a
uname -a
docker --version
docker compose version

# HOPS version
./hops --version

# Container status
cd ~/hops && sudo docker compose ps
```

### Reporting Issues

1. Check this troubleshooting guide first
2. Search existing [GitHub Issues](https://github.com/skiercm/hops/issues)
3. Create a new issue with:
   - Complete error messages
   - System information (above commands)
   - Steps to reproduce
   - Log file excerpts

## Recovery Commands

### Complete Reset

If HOPS installation is completely broken:

```bash
# Stop all containers
cd ~/hops && sudo docker compose down

# Remove containers and images (CAUTION: This removes all data)
sudo docker system prune -a --volumes

# Clean up repositories
sudo rm -f /etc/apt/sources.list.d/docker*
sudo apt clean

# Reinstall HOPS
cd ~/hops
git pull
sudo ./hops
```

### Partial Reset

To reset only HOPS configuration:

```bash
# Stop services
cd ~/hops && sudo docker compose down

# Remove generated files
rm -f ~/hops/docker-compose.yml ~/hops/.env

# Restart HOPS
sudo ./hops
```

---

## Version History

- **v3.3.0+**: Fixed Linux Mint Docker repository detection
- **v3.2.0+**: Added macOS support and improved error handling
- **v3.1.0+**: Initial multi-platform support

For the latest updates and fixes, always ensure you're running the latest version:

```bash
cd ~/hops
sudo ./hops --update
```