#!/bin/bash
# Setup external repositories (VS Code, Tailscale, etc.)

echo "Setting up external repositories"

# Get count of external repositories
count=$(get_array_length '.repositories.external')

if [[ "$count" -eq 0 ]]; then
    log_info "No external repositories configured"
    return 0
fi

# Process each external repository
for i in $(seq 0 $((count - 1))); do
    name=$(get_array_item '.repositories.external' "$i" 'name')
    type=$(get_array_item '.repositories.external' "$i" 'type')

    [[ -z "$name" ]] && continue

    repo_file="/etc/yum.repos.d/${name}.repo"

    if [[ -f "$repo_file" ]]; then
        log_info "External repository already exists: $name"
        continue
    fi

    log_info "Setting up external repository: $name"

    if [[ "$type" == "url" ]]; then
        # Download repo file from URL
        repo_url=$(get_array_item '.repositories.external' "$i" 'repo_url')

        if [[ -n "$repo_url" ]]; then
            sudo curl -Ls "$repo_url" -o "$repo_file"
            log_success "Downloaded repository: $name"
        fi
    elif [[ "$type" == "repo_file" ]]; then
        # Import GPG key if specified
        gpgkey=$(get_array_item '.repositories.external' "$i" 'gpgkey')

        if [[ -n "$gpgkey" ]]; then
            sudo rpm --import "$gpgkey"
            log_info "Imported GPG key for $name"
        fi

        # Write repo content
        content=$(get_array_item '.repositories.external' "$i" 'content')

        if [[ -n "$content" ]]; then
            echo "$content" | sudo tee "$repo_file" > /dev/null
            log_success "Created repository: $name"
        fi
    fi
done

log_success "External repositories configured"
