#!/bin/bash

# Fedora Linux KDE Setup Script
# Based on requirements from fedora.md and unix/fedora_install.md

set -euo pipefail

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Directories
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PACKAGES_DIR="${SCRIPT_DIR}/packages"

# Logging functions
log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $*"; }

# Error handling
error_exit() {
    log_error "$1"
    exit 1
}

# Check if running on Fedora
check_fedora() {
    if [[ ! -f /etc/fedora-release ]]; then
        error_exit "This script is designed for Fedora Linux only!"
    fi

    local fedora_version
    fedora_version=$(grep -oP 'release \K\d+' /etc/fedora-release)
    log_info "Detected Fedora ${fedora_version}"
}

# Function to enable COPR repositories
enable_copr_repos() {
    log_step "Enabling COPR repositories..."

    local copr_repos=(
        "lilay/topgrade"
        "wezfurlong/wezterm-nightly"
        "lukenukem/asus-linux"
    )

    for repo in "${copr_repos[@]}"; do
        log_info "Enabling COPR: ${repo}"
        sudo dnf copr enable -y "${repo}" || log_warn "Failed to enable COPR: ${repo}"
    done
}

# Function to add external repositories
add_external_repos() {
    log_step "Adding external repositories..."

    # NextDNS repository
    log_info "Adding NextDNS repository..."
    sudo curl -Ls https://repo.nextdns.io/nextdns.repo -o /etc/yum.repos.d/nextdns.repo || log_warn "Failed to add NextDNS repo"

    # Microsoft repository for VS Code
    log_info "Adding Microsoft repository..."
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc || log_warn "Failed to import Microsoft key"
    echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null || log_warn "Failed to add VS Code repo"

    # RPM Fusion repositories
    log_info "Installing RPM Fusion repositories..."
    sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm || log_warn "Failed to install RPM Fusion"
}

# Function to update system
update_system() {
    log_step "Updating system packages..."
    sudo dnf update -y --refresh
}

# Function to install packages from a file
install_packages_from_file() {
    local package_file="$1"
    local description="$2"

    if [[ ! -f "$package_file" ]]; then
        log_warn "Package file not found: $package_file"
        return 1
    fi

    log_step "Installing ${description}..."

    # Read packages from file, excluding comments and empty lines
    local packages
    packages=$(grep -v '^#' "$package_file" | grep -v '^$' | tr '\n' ' ')

    if [[ -n "$packages" ]]; then
        log_info "Installing packages: $packages"
        sudo dnf install -y $packages || log_warn "Some packages failed to install"
    else
        log_warn "No packages found in $package_file"
    fi
}

# Function to setup Rust
setup_rust() {
    log_step "Setting up Rust..."

    if command -v rustup &> /dev/null; then
        log_info "Rust is already installed, updating..."
        rustup update
    else
        log_info "Installing Rust..."
        sudo dnf install -y rustup || log_warn "Failed to install rustup"
        source ~/.cargo/env
    fi

    # Install stable and nightly toolchains
    rustup toolchain install stable
    rustup toolchain install nightly
    rustup default stable

    # Install common Rust tools
    log_info "Installing Rust tools..."
    local rust_tools=(
        "cargo-wipe"
        "eza"
        "just"
        "cargo-audit"
        "cargo-deny"
        "cargo-fuzz"
        "rustlings"
        "wasm-pack"

    )

    for tool in "${rust_tools[@]}"; do
        cargo install "$tool" || log_warn "Failed to install $tool"
    done

    # Install diesel_cli with PostgreSQL support
    cargo install diesel_cli --no-default-features --features postgres || log_warn "Failed to install diesel_cli"
}

# Function to install Flatpak applications
install_flatpaks() {
    local flatpak_file="${PACKAGES_DIR}/flatpaks.txt"

    if [[ ! -f "$flatpak_file" ]]; then
        log_warn "Flatpak file not found: $flatpak_file"
        return 1
    fi

    log_step "Installing Flatpak applications..."

    # Enable Flathub repository
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

    # Install Flatpak applications
    while IFS= read -r app; do
        if [[ -n "$app" && ! "$app" =~ ^# ]]; then
            log_info "Installing Flatpak: $app"
            flatpak install -y flathub "$app" || log_warn "Failed to install $app"
        fi
    done < "$flatpak_file"
}

# Function to setup system services
setup_services() {
    log_step "Setting up system services..."

    # PostgreSQL
    if command -v postgresql-setup &> /dev/null; then
        log_info "Setting up PostgreSQL..."
        sudo postgresql-setup --initdb || log_warn "PostgreSQL setup failed"
        sudo systemctl enable postgresql.service
        sudo systemctl start postgresql.service
    fi

    # Redis
    if systemctl list-unit-files | grep -q redis.service; then
        log_info "Starting Redis service..."
        sudo systemctl enable redis.service
        sudo systemctl start redis.service
    fi

    # Docker
    if command -v docker &> /dev/null; then
        log_info "Setting up Docker..."
        sudo systemctl enable docker.service
        sudo systemctl start docker.service
        sudo usermod -aG docker "$USER"
        log_info "Added $USER to docker group. Please log out and back in for changes to take effect."
    fi
}

# Function to setup NextDNS
setup_nextdns() {
    log_step "Setting up NextDNS..."

    if command -v nextdns &> /dev/null; then
        log_info "Configuring NextDNS..."
        # Note: Replace 1dff8f with your actual NextDNS config ID
        read -p "Enter your NextDNS config ID (or press Enter to skip): " nextdns_config

        if [[ -n "$nextdns_config" ]]; then
            sudo nextdns install -config "$nextdns_config" -setup-router=false -report-client-info=true -log-queries=false
            sudo nextdns activate
            log_info "NextDNS configured successfully"
        else
            log_warn "Skipping NextDNS configuration"
        fi
    else
        log_warn "NextDNS not installed"
    fi
}

# Function to setup NVIDIA drivers
setup_nvidia() {
    log_step "Setting up NVIDIA drivers..."

    # Check if NVIDIA hardware is present
    if ! lspci | grep -i nvidia &> /dev/null; then
        log_info "No NVIDIA hardware detected, skipping NVIDIA setup"
        return 0
    fi

    log_info "NVIDIA hardware detected, installing drivers..."

    # Install kernel headers
    sudo dnf install -y kernel-devel

    # Install NVIDIA drivers
    sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda

    # Install NVIDIA settings GUI
    sudo dnf install -y nvidia-settings

    # Install 32-bit libraries for gaming
    sudo dnf install -y xorg-x11-drv-nvidia-libs.i686

# Regenerate initramfs
sudo akmods --force
    # Enable NVIDIA services
    sudo systemctl enable nvidia-hibernate.service nvidia-suspend.service nvidia-resume.service nvidia-powerd.service

    log_info "NVIDIA drivers installed. A reboot is required."
    log_info "After reboot, run: sudo cat /sys/module/nvidia_drm/parameters/modeset"
    log_info "It should return 'Y' if the drivers are working correctly."
}

# Function to setup ASUS utilities
setup_asusctl() {
    log_step "Setting up ASUS utilities..."

    # Check if this is an ASUS system
    if ! dmidecode -s system-manufacturer 2>/dev/null | grep -i asus &> /dev/null; then
        log_info "Not an ASUS system, skipping ASUS utilities setup"
        return 0
    fi

    log_info "ASUS system detected, installing ASUS utilities..."

    # Install ASUS utilities
    sudo dnf install -y asusctl supergfxctl asusctl-rog-gui

    # Update system
    sudo dnf update --refresh

    # Enable services
    sudo systemctl enable supergfxd.service
    sudo systemctl start asusd

    # Set default aura lighting (white)
    asusctl aura static -c ffffff || log_warn "Failed to set aura lighting"

    log_info "ASUS utilities installed successfully"
}

# Function to setup KDE theming (Kanagawa Dragon theme)
setup_kde_theming() {
    log_step "Setting up KDE theming..."

    # Create color schemes directory
    mkdir -p ~/.local/share/color-schemes

    # Just create a placeholder
    log_info "KDE theming setup placeholder - manual theme installation required"
    log_info "Please install Kanagawa Dragon theme manually from KDE Store"
}

# Function to configure development environment
setup_dev_environment() {
    log_step "Setting up development environment..."

    # Setup Node.js with version manager (if not already installed)
    if ! command -v node &> /dev/null; then
        log_info "Node.js not found via package manager"
    fi

    # Setup Python development
    if command -v python3 &> /dev/null; then
        log_info "Setting up Python development tools..."
        python3 -m pip install --user --upgrade pip
    fi

    # Setup Java environment
    if command -v java &> /dev/null; then
        log_info "Java environment detected"
        # Set JAVA_HOME if not already set
        if [[ -z "${JAVA_HOME:-}" ]]; then
            echo 'export JAVA_HOME=/usr/lib/jvm/java-openjdk' >> ~/.bashrc
            echo 'export JAVA_HOME=/usr/lib/jvm/java-openjdk' >> ~/.zshrc
        fi
    fi
}

# Function to create package files if they don't exist
create_package_files() {
    mkdir -p "$PACKAGES_DIR"

    # Base system packages
    if [[ ! -f "${PACKAGES_DIR}/base-system.txt" ]]; then
        cat > "${PACKAGES_DIR}/base-system.txt" << 'EOF'
# Base system utilities
htop
btop
tealdeer
git
wget
curl
zsh
vim
neovim
micro
bat
direnv
fastfetch
fzf
git-delta
jq
pipx
ripgrep
tar
tmux
tree
xclip
zoxide
croc
openssh
stow
pkg-config
coreutils
binutils
atuin
gh
protobuf
topgrade
btrfs-assistant
lm_sensors
dnf-plugins-core
dpkg
EOF
    fi

    # Development packages
    if [[ ! -f "${PACKAGES_DIR}/development.txt" ]]; then
        cat > "${PACKAGES_DIR}/development.txt" << 'EOF'
# Development tools and languages
gcc
node
python
rustup
java-latest-openjdk
postgresql-server
postgresql-devel
redis
sqlite
docker
kubectl
code
EOF
    fi

    # Media packages
    if [[ ! -f "${PACKAGES_DIR}/media.txt" ]]; then
        cat > "${PACKAGES_DIR}/media.txt" << 'EOF'
# Media and multimedia packages
vlc
EOF
    fi

    # Gaming packages
    if [[ ! -f "${PACKAGES_DIR}/gaming.txt" ]]; then
        cat > "${PACKAGES_DIR}/gaming.txt" << 'EOF'
# Gaming packages
steam
EOF
    fi

    # Flatpak applications
    if [[ ! -f "${PACKAGES_DIR}/flatpaks.txt" ]]; then
        cat > "${PACKAGES_DIR}/flatpaks.txt" << 'EOF'
# Flatpak applications
app.zen_browser.zen
com.brave.Browser
dev.zed.Zed
org.signal.Signal
md.obsidian.Obsidian
org.localsend.localsend_app
com.bitwarden.desktop
org.onlyoffice.desktopeditors
com.obsproject.Studio
org.mozilla.Thunderbird
org.davinci.DaVinciResolve
EOF
    fi
}

# Main function
main() {
    log_info "Starting Fedora Linux KDE setup..."

    # Check if running on Fedora
    check_fedora

    # Create package files if they don't exist
    create_package_files

    # Enable COPR repositories
    enable_copr_repos

    # Add external repositories
    add_external_repos

    # Update system
    update_system

    # Install base system packages
    install_packages_from_file "${PACKAGES_DIR}/base-system.txt" "base system packages"

    # Install development packages
    install_packages_from_file "${PACKAGES_DIR}/development.txt" "development packages"

    # Install media packages
    install_packages_from_file "${PACKAGES_DIR}/media.txt" "media packages"

    # Install gaming packages
    install_packages_from_file "${PACKAGES_DIR}/gaming.txt" "gaming packages"

    # Setup Rust
    setup_rust

    # Install Flatpak applications
    install_flatpaks

    # Setup system services
    setup_services

    # Setup NextDNS
    setup_nextdns

    # Setup NVIDIA drivers
    setup_nvidia

    # Setup ASUS utilities
    setup_asusctl

    # Setup KDE theming
    setup_kde_theming

    # Setup development environment
    setup_dev_environment

    log_info "Fedora setup completed successfully!"
    log_warn "Please reboot your system to ensure all changes take effect."
    log_info "After reboot, you may want to:"
    log_info "  1. Verify NVIDIA drivers with: sudo cat /sys/module/nvidia_drm/parameters/modeset"
    log_info "  2. Configure KDE themes manually"
    log_info "  3. Set up your development environments"
    log_info "  4. Install additional Flatpak applications as needed"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
EOF
