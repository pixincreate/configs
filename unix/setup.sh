#!/bin/bash

# Wrapper setup script that ensures essential dependencies are installed
# before calling the main Python setup script

set -euo pipefail

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Logging functions
log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# Detect platform
detect_platform() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ -f /etc/fedora-release ]]; then
        echo "fedora"
    elif [[ -d /data/data/com.termux ]]; then
        echo "android"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "debian"
    else
        log_error "Unsupported platform: $OSTYPE"
        exit 1
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install packages based on platform
install_packages() {
    local platform="$1"
    shift
    local packages=("$@")

    log_info "Installing missing packages: ${packages[*]}"

    case "$platform" in
        "macos")
            # Install Homebrew if not present
            if ! command_exists brew; then
                log_info "Installing Homebrew..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

                # Add Homebrew to PATH
                if [[ -f /opt/homebrew/bin/brew ]]; then
                    eval "$(/opt/homebrew/bin/brew shellenv)"
                elif [[ -f /usr/local/bin/brew ]]; then
                    eval "$(/usr/local/bin/brew shellenv)"
                fi
            fi

            # Install packages
            for package in "${packages[@]}"; do
                if ! command_exists "$package"; then
                    brew install "$package"
                fi
            done
            ;;

        "fedora")
            # Update package cache
            sudo dnf check-update || true

            # Install packages
            local dnf_packages=()
            for package in "${packages[@]}"; do
                if ! command_exists "$package"; then
                    case "$package" in
                        "python") dnf_packages+=("python3") ;;
                        *) dnf_packages+=("$package") ;;
                    esac
                fi
            done

            if [[ ${#dnf_packages[@]} -gt 0 ]]; then
                sudo dnf install -y "${dnf_packages[@]}"
            fi
            ;;

        "debian")
            # Update package cache
            sudo apt-get update

            # Install packages
            local apt_packages=()
            for package in "${packages[@]}"; do
                if ! command_exists "$package"; then
                    case "$package" in
                        "python") apt_packages+=("python3") ;;
                        *) apt_packages+=("$package") ;;
                    esac
                fi
            done

            if [[ ${#apt_packages[@]} -gt 0 ]]; then
                sudo apt-get install -y "${apt_packages[@]}"
            fi
            ;;

        "android")
            # Update package cache
            pkg update

            # Install packages
            local pkg_packages=()
            for package in "${packages[@]}"; do
                if ! command_exists "$package"; then
                    pkg_packages+=("$package")
                fi
            done

            if [[ ${#pkg_packages[@]} -gt 0 ]]; then
                pkg install -y "${pkg_packages[@]}"
            fi
            ;;

        *)
            log_error "Unknown platform: $platform"
            exit 1
            ;;
    esac
}

# Check and install essential dependencies
check_dependencies() {
    local platform="$1"
    local required_tools=("python" "wget" "zsh" "git" "curl")
    local missing_tools=()

    log_info "Checking for essential dependencies..."

    # Check each required tool
    for tool in "${required_tools[@]}"; do
        if ! command_exists "$tool"; then
            missing_tools+=("$tool")
            log_warning "Missing: $tool"
        else
            log_success "Found: $tool"
        fi
    done

    # Install missing tools
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_info "Installing missing dependencies..."
        install_packages "$platform" "${missing_tools[@]}"

        # Verify installation
        for tool in "${missing_tools[@]}"; do
            if command_exists "$tool"; then
                log_success "Successfully installed: $tool"
            else
                log_error "Failed to install: $tool"
                exit 1
            fi
        done
    else
        log_success "All essential dependencies are already installed"
    fi
}

# Main function
main() {
    log_info "Starting setup wrapper script..."

    # Detect platform
    platform=$(detect_platform)
    log_info "Detected platform: $platform"

    # Check and install dependencies
    check_dependencies "$platform"

    # Check if we need to clone the repository first
    if [[ ! -d "unix" ]]; then
        log_info "Repository not found, cloning..."
        if ! command_exists git; then
            log_error "Git is required but not installed"
            exit 1
        fi

        # Clone to expected location
        target_dir="$HOME/Dev/.configs"
        log_info "Cloning repository to $target_dir"
        mkdir -p "$(dirname "$target_dir")"
        git clone --recurse-submodules https://github.com/pixincreate/configs.git "$target_dir"
        cd "$target_dir"
    fi

    # Find the setup.py script
    script_dir="$(pwd)"
    setup_py="$script_dir/unix/setup.py"

    if [[ ! -f "$setup_py" ]]; then
        log_error "setup.py not found at: $setup_py"
        exit 1
    fi

    # Make setup.py executable
    chmod +x "$setup_py"

    # Prepare arguments - add --yes if stdin is not a tty (piped input)
    local args=("$@")
    if [[ ! -t 0 ]]; then
        log_info "Detected piped input, enabling auto-confirm mode"
        args=(--yes "${args[@]}")
    fi

    # Call setup.py with all arguments
    log_info "Calling setup.py with arguments: ${args[*]}"
    log_success "Essential dependencies verified. Starting main setup..."

    # Use python3 explicitly if python points to python2
    if command_exists python3; then
        python3 "$setup_py" "${args[@]}"
    elif command_exists python; then
        python "$setup_py" "${args[@]}"
    else
        log_error "No Python interpreter found"
        exit 1
    fi
}

# Handle Ctrl+C gracefully
trap 'log_warning "Setup interrupted by user"; exit 1' INT

# Run main function with all arguments
main "$@"
