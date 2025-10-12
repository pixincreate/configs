#!/bin/bash
# Configure and manage systemd services

echo "Configuring systemd services"

# Enable services
mapfile -t enable_services < <(get_config_array '.services.enable')

for service in "${enable_services[@]}"; do
    # Check if service exists
    if ! systemctl list-unit-files 2>/dev/null | grep -q "^${service}"; then
        log_info "Service not available in this environment: $service"
        continue
    fi

    if systemctl is-enabled "$service" &>/dev/null; then
        log_info "Service already enabled: $service"
    else
        log_info "Enabling service: $service"
        sudo systemctl enable "$service" 2>/dev/null || log_warning "Failed to enable: $service"
    fi

    # Start service if not running
    if systemctl is-active "$service" &>/dev/null; then
        log_info "Service already running: $service"
    else
        log_info "Starting service: $service"
        if ! sudo systemctl start "$service" 2>/dev/null; then
            log_warning "Failed to start: $service"
        fi
    fi
done

# Disable services
mapfile -t disable_services < <(get_config_array '.services.disable')

for service in "${disable_services[@]}"; do
    # Check if service exists
    if ! systemctl list-unit-files 2>/dev/null | grep -q "^${service}"; then
        log_info "Service not available: $service"
        continue
    fi

    if systemctl is-enabled "$service" &>/dev/null; then
        log_info "Disabling service: $service"
        sudo systemctl disable "$service" 2>/dev/null || log_warning "Failed to disable: $service"
    else
        log_info "Service already disabled: $service"
    fi
done

# Configure Docker
if systemctl list-unit-files 2>/dev/null | grep -q "^docker.service"; then
    log_info "Configuring Docker"

    # Add user to docker group (skip if root)
    if [[ $EUID -ne 0 ]]; then
        if groups "$USER" | grep -q docker; then
            log_info "User already in docker group"
        else
            log_info "Adding user to docker group"
            sudo usermod -aG docker "$USER"
            log_success "User added to docker group (logout required)"
        fi
    else
        log_info "Running as root, skipping docker group addition"
    fi

    # Configure Docker daemon
    sudo mkdir -p /etc/docker

    sudo tee /etc/docker/daemon.json > /dev/null <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "5"
  }
}
EOF

    if systemctl is-active docker &>/dev/null; then
        sudo systemctl restart docker 2>/dev/null || log_info "Docker restart skipped"
    fi
    log_success "Docker configured"
fi

# Configure PostgreSQL
if systemctl list-unit-files 2>/dev/null | grep -q "postgresql"; then
    if [[ ! -f /var/lib/pgsql/data/PG_VERSION ]]; then
        log_info "Initializing PostgreSQL database"
        if sudo postgresql-setup --initdb 2>/dev/null; then
            log_success "PostgreSQL initialized"

            # Configure authentication to use md5 instead of ident
            local pg_config_path="/var/lib/pgsql/data/pg_hba.conf"
            log_info "Configuring PostgreSQL authentication"
            sudo sed -i -r 's/(host.*all.*all.*127\.0\.0\.1\/32.*)ident/\1md5/' "$pg_config_path"
            sudo sed -i -r 's/(host.*all.*all.*::1\/128.*)ident/\1md5/' "$pg_config_path"
            log_success "PostgreSQL authentication configured"
        else
            log_info "PostgreSQL init skipped"
        fi
    else
        log_info "PostgreSQL already initialized"
    fi
fi

log_success "Services configured"
