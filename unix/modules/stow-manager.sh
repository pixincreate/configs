#!/bin/bash

# Stow Manager Module
# Handles all stow operations with enhanced symlink awareness

# Source common functions
if [[ -z "${STOW_SCRIPT_DIR:-}" ]]; then
    STOW_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
source "${STOW_SCRIPT_DIR}/common.sh"

# Configuration
readonly STOW_PACKAGES=("config" "git" "ssh" "vscode" "zsh" "wallpaper")

# Function to handle stowing packages
stow_package() {
  local package="$1"
  local target="${2:-$HOME}"
  local stow_dir="${3:-${LOCAL_PATH}/home}"

  if [ ! -d "$stow_dir/$package" ]; then
    log_error "Package directory not found: $stow_dir/$package"
    return 1
  fi

  log_info "Stowing $package to $target..."

  # Special handling for wallpaper package
  if [[ "$package" == "wallpaper" ]]; then
    target="$HOME/Pictures/Wallpapers"
    mkdir -p "$target"
  fi

  # Use --no-folding to ensure stow doesn't try to fold directories
  # Use --restow to handle any existing links
  if stow --no-folding --restow --dir="$stow_dir" --target="$target" "$package"; then
    log_info "Successfully stowed $package"
  else
    log_error "Failed to stow $package"
    return 1
  fi
}

# Function to handle unstowing packages
unstow_package() {
  local package="$1"
  local target="${2:-$HOME}"
  local stow_dir="${3:-${LOCAL_PATH}/home}"

  if [ ! -d "$stow_dir/$package" ]; then
    log_error "Package directory not found: $stow_dir/$package"
    return 1
  fi

  log_info "Unstowing $package from $target..."

  # Special handling for wallpaper package
  if [[ "$package" == "wallpaper" ]]; then
    target="$HOME/Pictures/Wallpapers"
  fi

  if stow --delete --dir="$stow_dir" --target="$target" "$package"; then
    log_info "Successfully unstowed $package"
  else
    log_error "Failed to unstow $package"
    return 1
  fi
}

# Function to handle stowing all packages
stow_all_packages() {
  local target="${1:-$HOME}"
  local stow_dir="${2:-${LOCAL_PATH}/home}"

  log_info "Stowing all packages to $target..."

  for package in "${STOW_PACKAGES[@]}"; do
    stow_package "$package" "$target" "$stow_dir"
  done
}

# Function to handle unstowing all packages
unstow_all_packages() {
  local target="${1:-$HOME}"
  local stow_dir="${2:-${LOCAL_PATH}/home}"

  log_info "Unstowing all packages from $target..."

  for package in "${STOW_PACKAGES[@]}"; do
    unstow_package "$package" "$target" "$stow_dir"
  done
}

# Function to check if a file is stow-managed (symlink)
is_stow_managed() {
  local file_path="$1"
  [[ -L "$file_path" ]]
}

# Function to get the target of a symlink
get_symlink_target() {
  local file_path="$1"
  if [[ -L "$file_path" ]]; then
    readlink "$file_path"
  else
    return 1
  fi
}

# Enhanced stow status checker
check_stow_status() {
  local package="$1"
  local target="${2:-$HOME}"
  local stow_dir="${3:-${LOCAL_PATH}/home}"

  log_info "Checking stow status for $package..."

  if [[ ! -d "$stow_dir/$package" ]]; then
    log_warn "Package directory not found: $stow_dir/$package"
    return 1
  fi

  # Use stow's dry-run to check status
  if stow --no --dir="$stow_dir" --target="$target" "$package" 2>/dev/null; then
    log_info "$package: Not stowed"
    return 1
  else
    log_info "$package: Already stowed"
    return 0
  fi
}

# Function to restow packages (useful for updates)
restow_package() {
  local package="$1"
  local target="${2:-$HOME}"
  local stow_dir="${3:-${LOCAL_PATH}/home}"

  log_info "Restowing $package..."

  # Special handling for wallpaper package
  if [[ "$package" == "wallpaper" ]]; then
    target="$HOME/Pictures/Wallpapers"
    mkdir -p "$target"
  fi

  if stow --restow --dir="$stow_dir" --target="$target" "$package"; then
    log_info "Successfully restowed $package"
  else
    log_error "Failed to restow $package"
    return 1
  fi
}

# Function to safely update stow-managed configurations
safe_config_update() {
  local config_dir="${LOCAL_PATH}"

  if [[ ! -d "$config_dir" ]]; then
    log_error "Configuration directory not found: $config_dir"
    return 1
  fi

  log_step "Updating configurations safely..."

  # Check if git repo has uncommitted changes
  if ! git -C "$config_dir" diff-index --quiet HEAD --; then
    log_warn "Configuration repository has uncommitted changes."
    log_warn "Please commit or stash your changes first."
    return 1
  fi

  # Pull latest changes
  log_info "Pulling latest configuration changes..."
  if git -C "$config_dir" pull; then
    log_info "Successfully updated configuration repository"

    # Update submodules
    git -C "$config_dir" submodule update --init --recursive

    # Restow all packages to apply updates
    log_info "Applying configuration updates..."
    stow_all_packages "$HOME" "${config_dir}/home"

    log_info "Configuration update completed successfully!"
  else
    log_error "Failed to update configuration repository"
    return 1
  fi
}

# Export functions for use in other modules
export -f stow_package unstow_package stow_all_packages unstow_all_packages
export -f is_stow_managed get_symlink_target check_stow_status restow_package
export -f safe_config_update
