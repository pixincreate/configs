#!/bin/bash

# Common functions shared across setup scripts
# Extracted from setup-fedora.sh and setup.sh

# Color codes for output (only define if not already set)
if [[ -z "${RED:-}" ]]; then
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m'
    readonly NC='\033[0m' # No Color
fi

# Logging functions
log_info() { echo -e "${GREEN}[INFO]${NC} $*"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }
log_step() { echo -e "${BLUE}[STEP]${NC} $*"; }
log_debug() { [[ $DEBUG ]] && echo "[DEBUG] $*"; }

# Error handling
error_exit() {
    log_error "$1"
    exit 1
}

# Print function (from original setup.sh)
print() {
  local data="$1"
  local cr_flag="${2:-false}"

  if [[ "$cr_flag" == true ]]; then
    echo -ne "${data}\r"
  else
    echo -e "${data}"
  fi
}

# A function to check if a command exists
command_exists() {
  command -v "$1" > /dev/null 2>&1
}

# Check requirements function
check_requirements() {
  local -a required_cmds=("curl" "git" "ssh-keygen" "wget" "zsh")
  for cmd in "${required_cmds[@]}"; do
    command -v "$cmd" >/dev/null 2>&1 || {
      log_error "Required command not found: $cmd"
      return 1
    }
  done

  # Check for stow and install if not present
  if ! command -v stow &>/dev/null; then
    log_info "GNU Stow not found. Installing..."
    case "$OSTYPE" in
      darwin*)
        if command -v brew &>/dev/null; then
          brew install stow
        else
          log_error "Homebrew not found. Please install stow manually."
          return 1
        fi
        ;;
      linux-gnu*)
        if command -v apt-get &>/dev/null; then
          sudo apt-get update && sudo apt-get install -y stow
        elif command -v dnf &>/dev/null; then
          sudo dnf install -y stow
        elif command -v pacman &>/dev/null; then
          sudo pacman -S --noconfirm stow
        else
          log_error "Could not install stow. Please install it manually."
          return 1
        fi
        ;;
      linux-android)
        pkg install stow
        ;;
      *)
        log_error "Unsupported platform for stow installation: $OSTYPE"
        return 1
        ;;
    esac
  fi
}

# Validate configuration
validate_config() {
  [[ -z "$REPO_URL" ]] && return 1
  [[ -z "$LOCAL_PATH" ]] && return 1
  return 0
}

# Directory setup function
dir_setup() {
  print "Setting up directories..." true

  # Create the necessary directories
  mkdir -p \
    "${HOME}/.config" \
    "${HOME}/.rish" \
    "${HOME}/.ssh" \
    "${HOME}/.zsh" \
    "${HOME}/.zsh/.zgenom" \
    "${HOME}/Pictures/Wallpapers" \
    "${HOME}/Pictures/Screenshots"

  print "Directories setup completed!"
}

# Change shell options (from original setup.sh)
change_shopt() {
  local flag="$1"

  if [[ "$flag" == true ]]; then
    # Allow dotglob to include dot files and folders
    shopt -s dotglob
    # Allow loops over empty directory
    shopt -s nullglob
  else
    # Deny dotglob to include dot files and folders
    shopt -u dotglob
    # Deny loops over empty directory
    shopt -u nullglob
  fi
}

# Platform detection
detect_platform() {
  case "$OSTYPE" in
    darwin*)
      echo "darwin"
      ;;
    linux-gnu)
      # Check if it's Fedora
      if [[ -f /etc/fedora-release ]]; then
        echo "fedora"
      else
        echo "gnu"
      fi
      ;;
    linux-android)
      echo "android"
      ;;
    *)
      echo "unknown"
      ;;
  esac
}

# Function to install packages from a file (from setup-fedora.sh)
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

# Function to check if running on Fedora (from setup-fedora.sh)
check_fedora() {
    if [[ ! -f /etc/fedora-release ]]; then
        error_exit "This script is designed for Fedora Linux only!"
    fi

    local fedora_version
    fedora_version=$(grep -oP 'release \K\d+' /etc/fedora-release)
    log_info "Detected Fedora ${fedora_version}"
}

# Export functions for use in other modules
export -f log_info log_warn log_error log_step log_debug error_exit print
export -f command_exists check_requirements validate_config dir_setup change_shopt
export -f detect_platform install_packages_from_file check_fedora
