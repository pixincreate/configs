#!/bin/bash
# Remove bloatware packages

echo "Removing bloatware packages"

# Read bloatware packages from package file
pkg_file="$OMAFORGE_PATH/packages/bloatware.packages"

if [[ ! -f "$pkg_file" ]]; then
    log_info "No bloatware packages configured for removal"
    return 0
fi

mapfile -t packages < <(grep -v '^#' "$pkg_file" | grep -v '^$')

if [[ ${#packages[@]} -eq 0 ]]; then
    log_info "No bloatware packages configured for removal"
    return 0
fi

log_info "Removing ${#packages[@]} bloatware packages"

declare -a to_remove=()

for package in "${packages[@]}"; do
    # Handle wildcards by expanding them
    if [[ "$package" == *"*"* ]]; then
        # Get matching packages
        mapfile -t matches < <(rpm -qa "$package" 2>/dev/null)

        if [[ ${#matches[@]} -gt 0 ]]; then
            to_remove+=("${matches[@]}")
        fi
    else
        # Check if single package is installed
        if pkg_installed "$package"; then
            to_remove+=("$package")
        fi
    fi
done

if [[ ${#to_remove[@]} -eq 0 ]]; then
    log_info "No bloatware packages found to remove"
    return 0
fi

log_info "Removing ${#to_remove[@]} packages"

sudo dnf remove -y "${to_remove[@]}"

# Clean up orphaned packages
log_info "Cleaning up orphaned packages"
sudo dnf autoremove -y

log_success "Bloatware removal completed"
