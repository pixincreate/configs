#!/bin/bash
# Homebrew package installation

echo "Installing Homebrew packages"

package_file="$MACOS_PATH/packages/brew.packages"

if [[ ! -f "$package_file" ]]; then
    log_error "Package file not found: $package_file"
    return 1
fi

# Ensure Homebrew is installed
if ! command -v brew &>/dev/null; then
    log_error "Homebrew is not installed"
    return 1
fi

# Read packages (skip comments and empty lines)
mapfile -t packages < <(grep -v '^#' "$package_file" | grep -v '^$')

if [[ ${#packages[@]} -eq 0 ]]; then
    log_info "No Homebrew packages to install"
    return 0
fi

log_info "Installing ${#packages[@]} Homebrew packages"

local installed=0
local skipped=0
local failed=0

for package in "${packages[@]}"; do
    if brew list "$package" &>/dev/null; then
        log_info "Already installed: $package"
        skipped=$((skipped + 1))
    else
        log_info "Installing: $package"
        if brew install "$package"; then
            log_success "Installed: $package"
            installed=$((installed + 1))
        else
            log_error "Failed to install: $package"
            failed=$((failed + 1))
        fi
    fi
done

log_info "Installed: $installed, Skipped: $skipped, Failed: $failed"
log_success "Homebrew package installation completed"
