#!/bin/bash

echo "Installing base packages"

# Collect all DNF packages from package files
declare -a all_packages=()

# Read package files
for pkg_file in "$FEDORA_PATH/packages"/{base,development,tools,system}.packages; do
    if [[ ! -f "$pkg_file" ]]; then
        log_warning "Package file not found: $pkg_file"
        continue
    fi

    category=$(basename "$pkg_file" .packages)

    # Read packages (skip comments and empty lines)
    mapfile -t packages < <(grep -v '^#' "$pkg_file" | grep -v '^$')

    if [[ ${#packages[@]} -gt 0 ]]; then
        log_info "Found ${#packages[@]} packages in: $category"
        all_packages+=("${packages[@]}")
    fi
done

if [[ ${#all_packages[@]} -eq 0 ]]; then
    log_warning "No DNF packages configured"
    return 0
fi

log_info "Installing ${#all_packages[@]} DNF packages"

# Install packages with conflict resolution
sudo dnf install -y --best --allowerasing "${all_packages[@]}" || {
    log_warning "Some packages failed to install, retrying with --skip-broken only"
    sudo dnf install -y --skip-broken "${all_packages[@]}"
}

log_success "Base packages installed"
