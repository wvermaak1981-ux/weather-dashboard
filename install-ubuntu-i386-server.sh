#!/bin/bash

# Weather Dashboard i386 (32-bit) Installer for Ubuntu
# This script installs the Weather Dashboard server on Ubuntu i386 systems

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
APP_NAME="Weather Dashboard Server i386"
APP_VERSION="1.0.0"
INSTALL_DIR="/opt/weather-dashboard-server"
BIN_DIR="/usr/local/bin"
SYSTEMD_USER="weather-dash"

print_header() {
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${BLUE}  $APP_NAME Installer${NC}"
    echo -e "${BLUE}  Version: $APP_VERSION${NC}"
    echo -e "${BLUE}  Architecture: i386 (32-bit)${NC}"
    echo -e "${BLUE}=================================================${NC}\n"
}

print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "This installer must be run with sudo"
        echo "Usage: sudo ./install-ubuntu-i386-server.sh"
        exit 1
    fi
}

check_i386_architecture() {
    ARCH=$(uname -m)
    if [ "$ARCH" != "i686" ] && [ "$ARCH" != "i386" ]; then
        print_error "This installer is for i386 (32-bit) systems only"
        print_info "Detected architecture: $ARCH"
        print_info "For 64-bit systems, use: sudo ./install-ubuntu.sh"
        exit 1
    fi
    print_status "i386 architecture verified"
}

check_ubuntu() {
    if [ ! -f /etc/os-release ]; then
        print_error "Could not determine Linux distribution"
        exit 1
    fi

    . /etc/os-release
    
    if [[ "$ID" != "ubuntu" ]]; then
        print_warning "This installer is designed for Ubuntu, but you are running $PRETTY_NAME"
        read -p "Continue anyway? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    print_status "Distribution: $PRETTY_NAME"
}

install_32bit_dependencies() {
    print_info "Installing 32-bit dependencies..."
    
    # Enable i386 architecture if not already enabled
    if ! dpkg --print-foreign-architectures | grep -q i386; then
        print_info "Enabling i386 architecture..."
        dpkg --add-architecture i386
        apt-get update -qq
    fi
    
    # Core build tools
    print_info "Installing build tools..."
    apt-get install -y \
        build-essential:i386 \
        cmake \
        git \
        curl \
        wget
    
    # Development libraries for i386
    print_info "Installing development libraries (i386)..."
    apt-get install -y \
        libstdc++6:i386 \
        libgcc1:i386 \
        libc6:i386 \
        libsqlite3-dev:i386 \
        libcurl4-openssl-dev:i386 \
        libssl-dev:i386 \
        zlib1g-dev:i386
    
    # JSON library
    print_info "Installing JSON library..."
    apt-get install -y nlohmann-json3-dev
    
    print_status "All 32-bit dependencies installed"
}

download_and_extract() {
    print_info "Downloading Weather Dashboard Server source..."
    
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    if ! git clone https://github.com/yourusername/weather-dashboard.git; then
        print_error "Failed to download source code"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    cd weather-dashboard
    print_status "Source code downloaded"
    echo "$TEMP_DIR/weather-dashboard"
}

build_i386_server() {
    local source_dir="$1"
    
    print_info "Building Weather Dashboard Server (i386)..."
    
    cd "$source_dir"
    
    # Create build directory
    if [ -d build ]; then
        rm -rf build
    fi
    mkdir -p build
    cd build
    
    # Configure for i386 with server-only build
    print_info "Configuring build system for i386..."
    
    # Set 32-bit compilation flags
    export CFLAGS="-m32 -march=i686"
    export CXXFLAGS="-m32 -march=i686"
    export LDFLAGS="-m32"
    
    if ! cmake -DCMAKE_BUILD_TYPE=Release \
              -DCMAKE_C_FLAGS="-m32" \
              -DCMAKE_CXX_FLAGS="-m32" \
              -DBUILD_GUI=OFF \
              ..; then
        print_error "CMake configuration failed"
        exit 1
    fi
    
    # Build
    print_info "Compiling server application (this may take several minutes)..."
    if ! make -j$(nproc); then
        print_error "Build failed"
        exit 1
    fi
    
    # Verify it's 32-bit
    print_info "Verifying build is 32-bit..."
    if file weather_dashboard_server | grep -q "ELF 32-bit"; then
        print_status "Build verified as 32-bit executable"
    else
        print_warning "Build verification inconclusive, but build completed"
    fi
    
    print_status "Build completed successfully"
}

create_systemd_user() {
    print_info "Creating systemd user account..."
    
    if ! id "$SYSTEMD_USER" &>/dev/null; then
        useradd -r -s /bin/false -m -d /var/lib/weather-dashboard "$SYSTEMD_USER"
        print_status "User account created: $SYSTEMD_USER"
    else
        print_status "User account already exists: $SYSTEMD_USER"
    fi
}

create_directories() {
    print_info "Creating installation directories..."
    
    mkdir -p "$INSTALL_DIR"
    mkdir -p "/var/lib/weather-dashboard"
    mkdir -p "/etc/weather-dashboard"
    mkdir -p "/var/log/weather-dashboard"
    mkdir -p "/var/run/weather-dashboard"
    
    print_status "Directories created"
}

install_server_files() {
    local source_dir="$1"
    
    print_info "Installing server files..."
    
    # Copy binary
    if [ ! -f "$source_dir/build/weather_dashboard_server" ]; then
        print_error "Binary not found"
        exit 1
    fi
    
    cp "$source_dir/build/weather_dashboard_server" "$INSTALL_DIR/"
    chmod 755 "$INSTALL_DIR/weather_dashboard_server"
    
    # Create symlink
    ln -sf "$INSTALL_DIR/weather_dashboard_server" "$BIN_DIR/weather-dashboard-server"
    
    # Copy config
    if [ -f "$source_dir/config.json" ]; then
        cp "$source_dir/config.json" "/etc/weather-dashboard/config.default.json"
        if [ ! -f "/etc/weather-dashboard/config.json" ]; then
            cp "/etc/weather-dashboard/config.default.json" "/etc/weather-dashboard/config.json"
        fi
    fi
    
    # Copy documentation
    if [ -d "$source_dir/docs" ]; then
        cp -r "$source_dir/docs" "$INSTALL_DIR/"
    fi
    
    print_status "Server files installed"
}

setup_permissions() {
    print_info "Setting up permissions..."
    
    chown -R "$SYSTEMD_USER:$SYSTEMD_USER" "/var/lib/weather-dashboard"
    chown -R "$SYSTEMD_USER:$SYSTEMD_USER" "/var/log/weather-dashboard"
    chown -R "$SYSTEMD_USER:$SYSTEMD_USER" "/var/run/weather-dashboard"
    
    chmod 750 "/var/lib/weather-dashboard"
    chmod 750 "/var/log/weather-dashboard"
    chmod 750 "/var/run/weather-dashboard"
    
    chmod 644 "/etc/weather-dashboard/config.json"
    chmod 755 "$INSTALL_DIR"
    
    print_status "Permissions configured"
}

setup_systemd_service() {
    print_info "Setting up systemd service..."
    
    cat > "/etc/systemd/system/weather-dashboard-server.service" << EOF
[Unit]
Description=Weather Dashboard Server (i386)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=$SYSTEMD_USER
Group=$SYSTEMD_USER
ExecStart=$INSTALL_DIR/weather_dashboard_server
Restart=always
RestartSec=10
StartLimitInterval=60
StartLimitBurst=3
StandardOutput=journal
StandardError=journal
SyslogIdentifier=weather-dashboard

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/var/lib/weather-dashboard /var/log/weather-dashboard /var/run/weather-dashboard

[Install]
WantedBy=multi-user.target
EOF

    chmod 644 "/etc/systemd/system/weather-dashboard-server.service"
    systemctl daemon-reload
    
    print_status "Systemd service configured"
}

setup_logrotate() {
    print_info "Setting up log rotation..."
    
    cat > "/etc/logrotate.d/weather-dashboard-server" << 'EOF'
/var/log/weather-dashboard/*.log {
    daily
    rotate 7
    compress
    delaycompress
    notifempty
    create 0640 weather-dash weather-dash
    sharedscripts
    postrotate
        systemctl reload-or-restart weather-dashboard-server >/dev/null 2>&1 || true
    endscript
}
EOF

    chmod 644 "/etc/logrotate.d/weather-dashboard-server"
    print_status "Log rotation configured"
}

create_uninstaller() {
    print_info "Creating uninstaller script..."
    
    cat > "$INSTALL_DIR/uninstall.sh" << 'EOFUNINSTALL'
#!/bin/bash

echo "Uninstalling Weather Dashboard Server..."

sudo systemctl stop weather-dashboard-server 2>/dev/null || true
sudo systemctl disable weather-dashboard-server 2>/dev/null || true

sudo rm -f /etc/systemd/system/weather-dashboard-server.service
sudo rm -f /etc/logrotate.d/weather-dashboard-server
sudo rm -f /usr/local/bin/weather-dashboard-server
sudo rm -rf /opt/weather-dashboard-server

echo "Removing user account..."
sudo userdel -r weather-dash 2>/dev/null || true

echo "Would you like to remove data directories? (y/n)"
read -r response
if [ "$response" = "y" ]; then
    sudo rm -rf /var/lib/weather-dashboard
    sudo rm -rf /var/log/weather-dashboard
    sudo rm -rf /var/run/weather-dashboard
    sudo rm -rf /etc/weather-dashboard
fi

sudo systemctl daemon-reload

echo "Weather Dashboard Server uninstalled"
EOFUNINSTALL

    chmod +x "$INSTALL_DIR/uninstall.sh"
    print_status "Uninstaller created"
}

verify_installation() {
    print_info "Verifying installation..."
    
    if [ ! -f "$INSTALL_DIR/weather_dashboard_server" ]; then
        print_error "Binary verification failed"
        exit 1
    fi
    
    if ! file "$INSTALL_DIR/weather_dashboard_server" | grep -q "32-bit"; then
        print_warning "Could not confirm 32-bit binary, but file exists"
    fi
    
    if [ ! -f "/etc/systemd/system/weather-dashboard-server.service" ]; then
        print_error "Service file verification failed"
        exit 1
    fi
    
    print_status "Installation verified"
}

print_summary() {
    echo ""
    echo -e "${GREEN}=================================================${NC}"
    echo -e "${GREEN}  Installation Complete!${NC}"
    echo -e "${GREEN}  Weather Dashboard Server i386${NC}"
    echo -e "${GREEN}=================================================${NC}\n"
    
    echo -e "${BLUE}Installation Details:${NC}"
    print_info "Binary: $INSTALL_DIR/weather_dashboard_server"
    print_info "Configuration: /etc/weather-dashboard/config.json"
    print_info "Logs: /var/log/weather-dashboard/"
    print_info "User: $SYSTEMD_USER"
    print_info "Architecture: 32-bit (i386)\n"
    
    echo -e "${BLUE}Initial Setup:${NC}"
    echo "  1. Edit config: sudo nano /etc/weather-dashboard/config.json"
    echo "  2. Add your OpenWeatherMap API key"
    echo "  3. Start service: sudo systemctl start weather-dashboard-server\n"
    
    echo -e "${BLUE}Service Commands:${NC}"
    echo "  Start:      sudo systemctl start weather-dashboard-server"
    echo "  Stop:       sudo systemctl stop weather-dashboard-server"
    echo "  Restart:    sudo systemctl restart weather-dashboard-server"
    echo "  Enable:     sudo systemctl enable weather-dashboard-server"
    echo "  Disable:    sudo systemctl disable weather-dashboard-server"
    echo "  Status:     sudo systemctl status weather-dashboard-server"
    echo "  Logs:       sudo journalctl -u weather-dashboard-server -f\n"
    
    echo -e "${BLUE}Testing:${NC}"
    echo "  Check logs: sudo tail -f /var/log/weather-dashboard/server.log"
    echo "  Direct run: sudo -u $SYSTEMD_USER $INSTALL_DIR/weather_dashboard_server\n"
    
    echo -e "${BLUE}Uninstall:${NC}"
    echo "  sudo $INSTALL_DIR/uninstall.sh\n"
}

cleanup() {
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        print_info "Cleaning up..."
        rm -rf "$TEMP_DIR"
    fi
}

main() {
    trap cleanup EXIT
    
    print_header
    check_root
    check_i386_architecture
    check_ubuntu
    
    print_info "Starting i386 server installation...\n"
    
    install_32bit_dependencies
    echo ""
    
    SOURCE_DIR=$(download_and_extract)
    echo ""
    
    build_i386_server "$SOURCE_DIR"
    echo ""
    
    create_systemd_user
    echo ""
    
    create_directories
    echo ""
    
    install_server_files "$SOURCE_DIR"
    echo ""
    
    setup_permissions
    echo ""
    
    setup_systemd_service
    echo ""
    
    setup_logrotate
    echo ""
    
    create_uninstaller
    echo ""
    
    verify_installation
    echo ""
    
    print_summary
}

main "$@"
