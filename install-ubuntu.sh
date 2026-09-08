#!/bin/bash

# Weather Dashboard Installer for Ubuntu
# This script installs the Weather Dashboard application on Ubuntu systems
# Supports both amd64 and i386 architectures

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="Weather Dashboard"
APP_VERSION="1.0.0"
INSTALL_DIR="/opt/weather-dashboard"
BIN_DIR="/usr/local/bin"
DATa_DIR="/var/lib/weather-dashboard"
CONFIG_DIR="/etc/weather-dashboard"
LOG_DIR="/var/log/weather-dashboard"

# Functions
print_header() {
    echo -e "${BLUE}=================================================${NC}"
    echo -e "${BLUE}  Weather Dashboard Installer${NC}"
    echo -e "${BLUE}  Version: $APP_VERSION${NC}"
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
        echo "Usage: sudo ./install-ubuntu.sh"
        exit 1
    fi
}

check_architecture() {
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            ARCH_TYPE="amd64"
            print_status "Architecture detected: AMD64 (64-bit)"
            ;;
        i686|i386)
            ARCH_TYPE="i386"
            print_status "Architecture detected: i386 (32-bit)"
            ;;
        *)
            print_error "Unsupported architecture: $ARCH"
            print_info "Supported architectures: amd64 (x86_64), i386 (i686)"
            exit 1
            ;;
    esac
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
    
    print_status "Ubuntu distribution detected: $PRETTY_NAME"
}

install_dependencies() {
    print_info "Installing dependencies..."
    
    # Update package list
    print_info "Updating package list..."
    apt-get update -qq
    
    # Core dependencies
    print_info "Installing core dependencies..."
    apt-get install -y \
        build-essential \
        cmake \
        git \
        curl \
        wget \
        ca-certificates
    
    # Qt6 dependencies
    print_info "Installing Qt6 libraries..."
    apt-get install -y \
        qt6-base-dev \
        qt6-tools-dev \
        libqt6core6 \
        libqt6gui6 \
        libqt6widgets6 \
        libqt6network6
    
    # Development libraries
    print_info "Installing development libraries..."
    apt-get install -y \
        libsqlite3-dev \
        libcurl4-openssl-dev \
        libssl-dev \
        nlohmann-json3-dev
    
    print_status "All dependencies installed successfully"
}

download_source() {
    print_info "Downloading Weather Dashboard source..."
    
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    if ! git clone https://github.com/yourusername/weather-dashboard.git; then
        print_error "Failed to download source code"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
    
    cd weather-dashboard
    print_status "Source code downloaded to: $TEMP_DIR/weather-dashboard"
    
    echo "$TEMP_DIR/weather-dashboard"
}

build_application() {
    local source_dir="$1"
    
    print_info "Building Weather Dashboard..."
    
    cd "$source_dir"
    
    # Create build directory
    if [ -d build ]; then
        rm -rf build
    fi
    mkdir -p build
    cd build
    
    # Configure with CMake
    print_info "Configuring build system..."
    if ! cmake -DCMAKE_BUILD_TYPE=Release ..; then
        print_error "CMake configuration failed"
        exit 1
    fi
    
    # Build
    print_info "Compiling application (this may take a few minutes)..."
    if ! make -j$(nproc); then
        print_error "Build failed"
        exit 1
    fi
    
    print_status "Build completed successfully"
}

create_directories() {
    print_info "Creating installation directories..."
    
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$DATA_DIR"
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$LOG_DIR"
    mkdir -p "$(dirname $BIN_DIR)/weather-dashboard-data"
    
    print_status "Directories created"
}

install_application() {
    local source_dir="$1"
    
    print_info "Installing application files..."
    
    # Copy binary
    if [ ! -f "$source_dir/build/weather_dashboard" ]; then
        print_error "Binary not found at $source_dir/build/weather_dashboard"
        exit 1
    fi
    
    cp "$source_dir/build/weather_dashboard" "$INSTALL_DIR/"
    chmod +x "$INSTALL_DIR/weather_dashboard"
    
    # Create symlink in /usr/local/bin
    ln -sf "$INSTALL_DIR/weather_dashboard" "$BIN_DIR/weather-dashboard"
    
    # Copy configuration
    if [ -f "$source_dir/config.json" ]; then
        cp "$source_dir/config.json" "$CONFIG_DIR/config.default.json"
        
        # Create user config if it doesn't exist
        if [ ! -f "$CONFIG_DIR/config.json" ]; then
            cp "$CONFIG_DIR/config.default.json" "$CONFIG_DIR/config.json"
        fi
    fi
    
    # Copy resources
    if [ -d "$source_dir/resources" ]; then
        cp -r "$source_dir/resources" "$INSTALL_DIR/"
    fi
    
    # Copy documentation
    if [ -d "$source_dir/docs" ]; then
        cp -r "$source_dir/docs" "$INSTALL_DIR/"
    fi
    
    print_status "Application files installed"
}

setup_permissions() {
    print_info "Setting up permissions..."
    
    # Make directories writable for application
    chmod 755 "$INSTALL_DIR"
    chmod 755 "$DATA_DIR"
    chmod 755 "$CONFIG_DIR"
    chmod 755 "$LOG_DIR"
    
    # Make config readable by all
    chmod 644 "$CONFIG_DIR/config.json"
    chmod 644 "$CONFIG_DIR/config.default.json"
    
    print_status "Permissions configured"
}

create_desktop_entry() {
    print_info "Creating desktop entry..."
    
    DESKTOP_FILE="/usr/share/applications/weather-dashboard.desktop"
    
    cat > "$DESKTOP_FILE" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Weather Dashboard
Comment=Real-time weather information from OpenWeatherMap
Icon=weather-dashboard
Exec=weather-dashboard
Categories=Utility;Weather;
Terminal=false
StartupNotify=true
EOF

    chmod 644 "$DESKTOP_FILE"
    print_status "Desktop entry created"
}

setup_systemd_service() {
    print_info "Setting up systemd service..."
    
    SYSTEMD_FILE="/etc/systemd/system/weather-dashboard.service"
    
    cat > "$SYSTEMD_FILE" << EOF
[Unit]
Description=Weather Dashboard Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=$INSTALL_DIR/weather_dashboard
Restart=on-failure
RestartSec=10
StandardOutput=journal
StandardError=journal
Environment="QT_QPA_PLATFORM=offscreen"

[Install]
WantedBy=multi-user.target
EOF

    chmod 644 "$SYSTEMD_FILE"
    systemctl daemon-reload
    print_status "Systemd service created"
}

create_uninstaller() {
    print_info "Creating uninstaller..."
    
    UNINSTALL_SCRIPT="$INSTALL_DIR/uninstall.sh"
    
    cat > "$UNINSTALL_SCRIPT" << 'EOFUNINSTALL'
#!/bin/bash

echo "Uninstalling Weather Dashboard..."

# Stop service if running
if systemctl is-active --quiet weather-dashboard; then
    systemctl stop weather-dashboard
fi

# Remove service file
rm -f /etc/systemd/system/weather-dashboard.service
systemctl daemon-reload

# Remove desktop entry
rm -f /usr/share/applications/weather-dashboard.desktop

# Remove symlink
rm -f /usr/local/bin/weather-dashboard

# Remove installation directory
rm -rf /opt/weather-dashboard

# Ask about removing data
read -p "Remove application data? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    rm -rf /var/lib/weather-dashboard
    rm -rf /var/log/weather-dashboard
fi

echo "Weather Dashboard uninstalled successfully"
EOFUNINSTALL

    chmod +x "$UNINSTALL_SCRIPT"
    print_status "Uninstaller created at: $UNINSTALL_SCRIPT"
}

verify_installation() {
    print_info "Verifying installation..."
    
    if [ ! -f "$INSTALL_DIR/weather_dashboard" ]; then
        print_error "Installation verification failed: Binary not found"
        exit 1
    fi
    
    if [ ! -L "$BIN_DIR/weather-dashboard" ]; then
        print_error "Installation verification failed: Symlink not created"
        exit 1
    fi
    
    # Test binary
    if ! "$INSTALL_DIR/weather_dashboard" --version &>/dev/null; then
        print_warning "Could not verify binary version, but installation appears successful"
    fi
    
    print_status "Installation verified successfully"
}

print_summary() {
    echo ""
    echo -e "${GREEN}=================================================${NC}"
    echo -e "${GREEN}  Installation Complete!${NC}"
    echo -e "${GREEN}=================================================${NC}\n"
    
    print_info "Installation Directory: $INSTALL_DIR"
    print_info "Configuration: $CONFIG_DIR/config.json"
    print_info "Logs: $LOG_DIR"
    print_info "Data: $DATA_DIR\n"
    
    echo -e "${BLUE}Quick Start:${NC}"
    echo "  1. Edit configuration: sudo nano $CONFIG_DIR/config.json"
    echo "  2. Add your OpenWeatherMap API key"
    echo "  3. Run the application: weather-dashboard\n"
    
    echo -e "${BLUE}Service Management:${NC}"
    echo "  Start service:   sudo systemctl start weather-dashboard"
    echo "  Stop service:    sudo systemctl stop weather-dashboard"
    echo "  Enable on boot:  sudo systemctl enable weather-dashboard"
    echo "  View logs:       sudo journalctl -u weather-dashboard -f\n"
    
    echo -e "${BLUE}Uninstallation:${NC}"
    echo "  Run: sudo $INSTALL_DIR/uninstall.sh\n"
}

cleanup() {
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        print_info "Cleaning up temporary files..."
        rm -rf "$TEMP_DIR"
    fi
}

# Main installation flow
main() {
    trap cleanup EXIT
    
    print_header
    check_root
    check_architecture
    check_ubuntu
    
    print_info "Starting installation for $ARCH_TYPE architecture...\n"
    
    install_dependencies
    echo ""
    
    SOURCE_DIR=$(download_source)
    echo ""
    
    build_application "$SOURCE_DIR"
    echo ""
    
    create_directories
    echo ""
    
    install_application "$SOURCE_DIR"
    echo ""
    
    setup_permissions
    echo ""
    
    create_desktop_entry
    echo ""
    
    setup_systemd_service
    echo ""
    
    create_uninstaller
    echo ""
    
    verify_installation
    echo ""
    
    print_summary
}

# Run main function
main "$@"
