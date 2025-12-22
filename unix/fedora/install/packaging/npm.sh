#!/bin/bash
# Install NPM global packages

echo "Installing NPM global packages"

# Ensure npm is available
if ! cmd_exists npm; then
    log_warning "npm not found. Skipping NPM package installation"
    log_info "Install Node.js/npm first (e.g., via dnf install nodejs npm)"
    return 0
fi

# Configure npm global prefix
npm_global_dir=$(expand_path "$(get_config '.directories.npm_global')")

if [[ -d "$npm_global_dir" ]]; then
    log_info "Configuring npm global prefix: $npm_global_dir"
    npm config set prefix "$npm_global_dir"
    export PATH="$npm_global_dir/bin:$PATH"
    log_success "npm prefix configured"
else
    log_warning "npm-global directory not found: $npm_global_dir"
    log_info "Run directories setup first or create it manually"
fi

# Read NPM packages from package file
pkg_file="$OMAFORGE_PATH/packages/npm.packages"

if [[ ! -f "$pkg_file" ]]; then
    log_info "No NPM packages configured"
    return 0
fi

mapfile -t packages < <(grep -v '^#' "$pkg_file" | grep -v '^$')

if [[ ${#packages[@]} -eq 0 ]]; then
    log_info "No NPM packages configured"
    return 0
fi


npm config set prefix '~/.npm-global'
export PATH=$HOME/.npm-global/bin:$PATH

log_info "Installing ${#packages[@]} NPM global packages"

local installed=0
local skipped=0
local failed=0

for package in "${packages[@]}"; do
    # Check if package is already installed globally
    if npm list -g "$package" &>/dev/null; then
        log_info "Already installed: $package"
        skipped=$((skipped + 1))
    else
        log_info "Installing: $package"
        if npm install -g "$package"; then
            log_success "Installed: $package"
            installed=$((installed + 1))
        else
            log_error "Failed to install: $package"
            failed=$((failed + 1))
        fi
    fi
done

echo ""
echo "========================================="
echo "NPM Package Installation Summary"
echo "========================================="
echo "Installed: $installed"
echo "Skipped: $skipped"
echo "Failed: $failed"
echo "========================================="

log_success "NPM global packages installed"
