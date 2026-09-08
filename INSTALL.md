# Installation Guide

## Quick Installation

### For Ubuntu (Desktop/Server - All Architectures)

```bash
# Download installer
wget https://github.com/yourusername/weather-dashboard/raw/main/install-ubuntu.sh

# Make executable
chmod +x install-ubuntu.sh

# Run installer
sudo ./install-ubuntu.sh
```

### For Ubuntu i386 (32-bit Server)

```bash
# Download installer
wget https://github.com/yourusername/weather-dashboard/raw/main/install-ubuntu-i386-server.sh

# Make executable
chmod +x install-ubuntu-i386-server.sh

# Run installer
sudo ./install-ubuntu-i386-server.sh
```

## What the Installers Do

### General Ubuntu Installer (install-ubuntu.sh)

**Features:**
- Auto-detects system architecture (32-bit/64-bit)
- Installs all dependencies (Qt6, SQLite, Curl, OpenSSL, JSON)
- Downloads and compiles from source
- Creates desktop entry for application menu
- Sets up systemd service for daemon mode
- Creates user-friendly uninstaller
- Verifies installation
- Provides quick start guide

**Supported Architectures:**
- x86_64 (64-bit) - amd64
- i386 (32-bit)

**Installation Paths:**
- Binary: `/opt/weather-dashboard/weather_dashboard`
- Symlink: `/usr/local/bin/weather-dashboard`
- Config: `/etc/weather-dashboard/config.json`
- Logs: `/var/log/weather-dashboard/`
- Data: `/var/lib/weather-dashboard/`

### i386 Server Installer (install-ubuntu-i386-server.sh)

**Features:**
- 32-bit specific compilation with optimization
- Adds i386 architecture support if needed
- Server-only build (no GUI)
- Creates dedicated system user
- Comprehensive systemd service with security settings
- Log rotation configuration
- System hardening options
- Detailed service management

**Supported Architectures:**
- i386 (32-bit) only

**Installation Paths:**
- Binary: `/opt/weather-dashboard-server/weather_dashboard_server`
- Symlink: `/usr/local/bin/weather-dashboard-server`
- Config: `/etc/weather-dashboard/config.json`
- Logs: `/var/log/weather-dashboard/`
- Data: `/var/lib/weather-dashboard/`
- User: `weather-dash` (system user)

## Requirements

### System Requirements

**Ubuntu Versions:**
- Ubuntu 20.04 LTS or newer
- Other Debian-based distributions (may require adjustments)

**Internet Connection:**
- Required for downloading dependencies
- Required for downloading source code

**Disk Space:**
- ~1-2 GB for dependencies
- ~200 MB for application
- ~500 MB for build files (removed after installation)

**RAM:**
- Minimum 512 MB for compilation
- 2+ GB recommended for faster builds

### OpenWeatherMap API Key

1. Visit [openweathermap.org](https://openweathermap.org)
2. Create free account
3. Generate API key
4. Keep key ready for configuration

## Installation Steps

### Step 1: Download Installer

**Option A: Using wget**
```bash
wget https://github.com/yourusername/weather-dashboard/raw/main/install-ubuntu.sh
```

**Option B: Clone repository**
```bash
git clone https://github.com/yourusername/weather-dashboard.git
cd weather-dashboard
```

### Step 2: Make Executable

```bash
chmod +x install-ubuntu.sh
```

### Step 3: Run Installer

**With sudo (required):**
```bash
sudo ./install-ubuntu.sh
```

**Interactive prompts:**
- Confirms your Ubuntu distribution
- Shows detected architecture
- Installs dependencies (may take 5-10 minutes)
- Downloads source code
- Compiles application (may take 10-20 minutes depending on specs)
- Verifies installation

### Step 4: Configure Application

**Edit configuration:**
```bash
sudo nano /etc/weather-dashboard/config.json
```

**Add your API key:**
```json
{
  "api_key": "your_openweathermap_api_key_here",
  "units": "metric",
  "default_location": "New York"
}
```

### Step 5: Start Application

**GUI mode:**
```bash
weather-dashboard
```

**Service mode:**
```bash
sudo systemctl start weather-dashboard
```

## Post-Installation

### Configuration

**Edit config:**
```bash
sudo nano /etc/weather-dashboard/config.json
```

**Key settings:**
- `api_key`: OpenWeatherMap API key (required)
- `units`: "metric", "imperial", or "standard"
- `default_location`: Default city name
- `auto_refresh_minutes`: Refresh interval
- `cache_duration_minutes`: Cache validity
- `theme`: "light" or "dark"

### Service Management

**Start service:**
```bash
sudo systemctl start weather-dashboard
```

**Enable on boot:**
```bash
sudo systemctl enable weather-dashboard
```

**View status:**
```bash
sudo systemctl status weather-dashboard
```

**View logs:**
```bash
sudo journalctl -u weather-dashboard -f
```

**Stop service:**
```bash
sudo systemctl stop weather-dashboard
```

### Troubleshooting

**Application won't start:**
```bash
# Check logs
sudo journalctl -u weather-dashboard -f

# Verify config
sudo cat /etc/weather-dashboard/config.json

# Test manually
sudo -u weather-dash weather-dashboard-server
```

**API key not working:**
- Verify key in `/etc/weather-dashboard/config.json`
- Check key on OpenWeatherMap dashboard
- Ensure internet connectivity

**Permission denied:**
```bash
# Fix permissions
sudo chown -R weather-dash:weather-dash /var/lib/weather-dashboard
sudo chmod 755 /opt/weather-dashboard/weather_dashboard
```

## Uninstallation

### Option 1: Using Uninstaller Script

```bash
sudo /opt/weather-dashboard/uninstall.sh
```

The script will:
- Stop running service
- Remove systemd service file
- Remove desktop entry
- Remove binaries
- Prompt to remove data

### Option 2: Manual Uninstallation

```bash
# Stop service
sudo systemctl stop weather-dashboard
sudo systemctl disable weather-dashboard

# Remove files
sudo rm -rf /opt/weather-dashboard
sudo rm -f /usr/local/bin/weather-dashboard
sudo rm -f /etc/systemd/system/weather-dashboard.service
sudo rm -f /usr/share/applications/weather-dashboard.desktop

# Remove data (optional)
sudo rm -rf /var/lib/weather-dashboard
sudo rm -rf /var/log/weather-dashboard
sudo rm -rf /etc/weather-dashboard

# Reload systemd
sudo systemctl daemon-reload
```

## Upgrading

### Update Application

```bash
# Stop running instance
sudo systemctl stop weather-dashboard

# Download new installer
wget https://github.com/yourusername/weather-dashboard/raw/main/install-ubuntu.sh
chmod +x install-ubuntu.sh

# Run installer (will update installation)
sudo ./install-ubuntu.sh

# Start updated application
sudo systemctl start weather-dashboard
```

### Keep Configuration

The installer preserves `/etc/weather-dashboard/config.json` during upgrades.

## i386 Server Specific Instructions

### Check Architecture

```bash
# Verify 32-bit system
uname -m
# Should output: i686 or i386

# Verify installation is 32-bit
file /opt/weather-dashboard-server/weather_dashboard_server
# Should show: ELF 32-bit
```

### Enable 32-bit Support (if needed)

```bash
# Add i386 architecture
sudo dpkg --add-architecture i386
sudo apt-get update
```

### Service User

The i386 installer creates a dedicated user: `weather-dash`

```bash
# Verify user created
id weather-dash

# View user details
getent passwd weather-dash
```

### Logs

```bash
# View service logs
sudo journalctl -u weather-dashboard-server -f

# View application logs
sudo tail -f /var/log/weather-dashboard/server.log
```

## Performance Optimization

### For Low-End Systems

**Adjust cache settings:**
```json
{
  "cache_duration_minutes": 30,
  "auto_refresh_minutes": 60
}
```

**Run with limited resources:**
```bash
# Limit memory usage
sudo systemctl set-property weather-dashboard MemoryLimit=256M
```

### For i386 Systems

**Optimization flags:**
- Compiler: `-m32 -march=i686 -O3`
- Memory footprint: ~50-100 MB
- CPU usage: Minimal (mostly I/O waiting)

## Security Considerations

### API Key Protection

**Secure configuration:**
```bash
# Restrict config file permissions
sudo chmod 600 /etc/weather-dashboard/config.json

# Only root can read
sudo chown root:root /etc/weather-dashboard/config.json
```

### Service Hardening

The installer includes:
- Dedicated non-root user
- Restricted file access
- Service isolation
- Resource limits
- Security options in systemd service

### Firewall (if applicable)

```bash
# If running on network:
sudo ufw allow 8080/tcp  # Example port
```

## Support

For issues:
1. Check logs: `sudo journalctl -u weather-dashboard -f`
2. Review config: `cat /etc/weather-dashboard/config.json`
3. Test connectivity: `curl https://api.openweathermap.org`
4. Report issues on GitHub

## Additional Resources

- [README.md](README.md) - Project overview
- [BUILD.md](BUILD.md) - Manual build instructions
- [API.md](API.md) - API documentation
- [docs/USER_GUIDE.md](docs/USER_GUIDE.md) - User guide
