#!/bin/bash
set -eEuo pipefail

# Configure and manage systemd services

echo "Configuring systemd services"

# Enable services
mapfile -t enable_services < <(get_config_array '.services.enable')

for service in "${enable_services[@]}"; do
    # Skip empty entries
    [[ -z "$service" ]] && continue

    # Check if service exists
    if ! systemctl list-unit-files "$service" &>/dev/null; then
        log_info "Service not available in this environment: $service"
        continue
    fi

    if systemctl is-enabled "$service" &>/dev/null; then
        log_info "Service already enabled: $service"
    else
        log_info "Enabling service: $service"
        if sudo systemctl enable "$service" 2>/dev/null; then
            log_success "Service enabled: $service"
        else
            log_warning "Failed to enable: $service"
        fi
    fi

    # Start service if not running
    if systemctl is-active "$service" &>/dev/null; then
        log_info "Service already running: $service"
    else
        log_info "Starting service: $service"
        if sudo systemctl start "$service" 2>/dev/null; then
            log_success "Service started: $service"
        else
            log_warning "Failed to start: $service"
        fi
    fi
done

# Disable services
mapfile -t disable_services < <(get_config_array '.services.disable')

for service in "${disable_services[@]}"; do
    # Skip empty entries
    [[ -z "$service" ]] && continue

    # Check if service exists
    if ! systemctl list-unit-files "$service" &>/dev/null; then
        log_info "Service not available: $service"
        continue
    fi

    if systemctl is-enabled "$service" &>/dev/null; then
        log_info "Disabling service: $service"
        if sudo systemctl disable "$service" 2>/dev/null; then
            log_success "Service disabled: $service"
        else
            log_warning "Failed to disable: $service"
        fi
    else
        log_info "Service already disabled: $service"
    fi
done

# Configure Docker
if systemctl list-unit-files docker.service &>/dev/null; then
    log_info "Configuring Docker"

    # Add user to docker group (skip if root)
    if [[ $EUID -ne 0 ]]; then
        if groups "$USER" | grep -q docker; then
            log_info "User already in docker group"
        else
            log_warning "Docker group grants root-equivalent privileges"
            log_warning "Alternative: Use 'sudo docker' or consider rootless Docker"

            if confirm "Add $USER to docker group? [y/N]" "N"; then
                log_info "Adding user to docker group"
                if sudo usermod -aG docker "$USER"; then
                    log_success "User added to docker group"
                    log_warning "Logout and login again for changes to take effect"
                else
                    log_error "Failed to add user to docker group"
                fi
            else
                log_info "Skipped docker group addition. Use 'sudo docker' instead."
            fi
        fi
    else
        log_info "Running as root, skipping docker group addition"
    fi

    # Configure Docker daemon
    sudo mkdir -p /etc/docker

    DOCKER_DAEMON_JSON="/etc/docker/daemon.json"

    # Only create if it doesn't exist or merge if it does
    if [[ ! -f "$DOCKER_DAEMON_JSON" ]]; then
        sudo tee "$DOCKER_DAEMON_JSON" > /dev/null <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "5"
  }
}
EOF
        log_success "Docker daemon.json created"
    else
        log_info "Docker daemon.json already exists, skipping modification"
        log_info "Manual configuration may be required"
    fi

    if systemctl is-active docker &>/dev/null; then
        if sudo systemctl restart docker 2>/dev/null; then
            log_success "Docker restarted"
        else
            log_warning "Docker restart failed, may require manual intervention"
        fi
    fi
    log_success "Docker configured"
fi

# Configure PostgreSQL
if systemctl list-unit-files postgresql.service &>/dev/null; then
    if [[ ! -f /var/lib/pgsql/data/PG_VERSION ]]; then
        log_info "Initializing PostgreSQL database"
        if sudo postgresql-setup --initdb 2>/dev/null; then
            log_success "PostgreSQL initialized"

            # Configure authentication to use md5 instead of ident
            pg_config_path="/var/lib/pgsql/data/pg_hba.conf"

            # Validate config exists and is writable
            if [[ ! -f "$pg_config_path" ]]; then
                log_error "PostgreSQL config not found: $pg_config_path"
                return 1
            fi

            log_info "Configuring PostgreSQL authentication"

            # Backup before modification
            sudo cp "$pg_config_path" "${pg_config_path}.omaforge-backup"

            # More precise sed with validation (only modify non-commented lines)
            if sudo sed -i.bak -E \
                -e '/^[^#]*host[[:space:]]+all[[:space:]]+all[[:space:]]+127\.0\.0\.1\/32.*ident[[:space:]]*$/s/ident/md5/' \
                -e '/^[^#]*host[[:space:]]+all[[:space:]]+all[[:space:]]+::1\/128.*ident[[:space:]]*$/s/ident/md5/' \
                "$pg_config_path"; then

                # Verify changes were applied
                if grep -qE '^[^#]*host[[:space:]]+all[[:space:]]+all[[:space:]]+(127\.0\.0\.1\/32|::1\/128).*md5' "$pg_config_path"; then
                    log_success "PostgreSQL authentication configured (ident -> md5)"
                else
                    log_warning "PostgreSQL config may not have changed (already configured or no matching lines)"
                fi
            else
                log_error "Failed to modify PostgreSQL config"
                # Restore from backup
                sudo mv "${pg_config_path}.bak" "$pg_config_path"
                return 1
            fi
        else
            log_warning "PostgreSQL initialization skipped or failed"
        fi
    else
        log_info "PostgreSQL already initialized"
    fi
fi

log_success "Services configured"
