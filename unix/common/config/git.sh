#!/bin/bash

set -e

setup_git() {
    local git_name="$1"
    local git_email="$2"
    local ssh_dir="${3:-$HOME/.ssh}"
    local gitconfig_local="${4:-$HOME/.config/gitconfig/.gitconfig.local}"

    echo "Configuring Git and SSH"

    # Use env vars if available
    if [[ -z "$git_name" ]] && [[ -n "${OMAFORGE_GIT_NAME:-}" ]]; then
        git_name="$OMAFORGE_GIT_NAME"
        echo "[INFO] Using Git name from OMAFORGE_GIT_NAME"
    fi

    if [[ -z "$git_email" ]] && [[ -n "${OMAFORGE_GIT_EMAIL:-}" ]]; then
        git_email="$OMAFORGE_GIT_EMAIL"
        echo "[INFO] Using Git email from OMAFORGE_GIT_EMAIL"
    fi

    # Check if .gitconfig.local already exists
    if [[ -f "$gitconfig_local" ]]; then
        echo "[INFO] Git local config already exists: $gitconfig_local"

        # Read existing values using git config
        current_name=$(git config -f "$gitconfig_local" user.name 2>/dev/null || echo "")
        current_email=$(git config -f "$gitconfig_local" user.email 2>/dev/null || echo "")

        if [[ -n "$current_name" ]] && [[ -n "$current_email" ]]; then
            echo "[INFO] Current Git user: $current_name <$current_email>"

            # If we don't have values from env vars or params, keep existing
            if [[ -z "$git_name" ]] && [[ -z "$git_email" ]]; then
                read -p "Update Git user config? [y/N] " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    git_name="$current_name"
                    git_email="$current_email"
                    echo "[INFO] Keeping existing Git user config"
                fi
            fi
        fi
    fi

    # Prompt for missing values
    if [[ -z "$git_name" ]]; then
        read -p "Enter your Git name: " git_name
    fi

    if [[ -z "$git_email" ]]; then
        read -p "Enter your Git email: " git_email
    fi

    # Validate we have required values
    if [[ -z "$git_name" ]] || [[ -z "$git_email" ]]; then
        echo "[ERROR] Git name and email are required"
        return 1
    fi

    # Backup existing .gitconfig.local if it exists and we're updating
    if [[ -f "$gitconfig_local" ]] && [[ "$git_name" != "$current_name" || "$git_email" != "$current_email" ]]; then
        local backup_file="${gitconfig_local}.bak"
        cp "$gitconfig_local" "$backup_file"
        echo "[INFO] Backed up existing Git config to: $backup_file"
    fi

    # Create .gitconfig.local directory
    mkdir -p "$(dirname "$gitconfig_local")"

    # Setup SSH directory
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"

    # Check for existing SSH key
    local ssh_key="$ssh_dir/id_ed25519"
    local ssh_sign_key="$ssh_dir/id_ed25519_sign"

    if [[ -f "$ssh_key" ]]; then
        echo "[INFO] SSH key already exists: $ssh_key"
    else
        echo "[INFO] Generating SSH key"
        ssh-keygen -t ed25519 -C "$git_email" -f "$ssh_key" -N ""
        echo "[SUCCESS] SSH key generated: $ssh_key"
    fi

    # Check for existing signing key
    if [[ -f "$ssh_sign_key" ]]; then
        echo "[INFO] SSH signing key already exists: $ssh_sign_key"
    else
        echo "[INFO] Generating SSH signing key"
        ssh-keygen -t ed25519 -C "$git_email" -f "$ssh_sign_key" -N ""
        echo "[SUCCESS] SSH signing key generated: $ssh_sign_key"
    fi

    echo "[INFO] Creating .gitconfig.local"
    cat > "$gitconfig_local" <<EOF
[user]
  name = $git_name
  email = $git_email
  signingkey = $ssh_sign_key.pub
EOF

    echo "[SUCCESS] Git local config created: $git_name <$git_email>"

    # Set SSH permissions
    chmod 700 "$ssh_dir"
    for file in "$ssh_dir"/*; do
        [[ ! -f "$file" ]] && continue

        if [[ "$file" == *.pub ]]; then
            chmod 644 "$file"
        else
            chmod 600 "$file"
        fi
    done

    echo "[SUCCESS] SSH permissions configured"

    if [[ -f "${ssh_key}.pub" ]]; then
        echo ""
        echo "[INFO] Your SSH public key:"
        echo "-------------------------------------------------------------------"
        cat "${ssh_key}.pub"
        echo "-------------------------------------------------------------------"
        echo "[INFO] Add this key to GitHub: https://github.com/settings/keys"
        echo ""
    fi

    echo "[SUCCESS] Git and SSH configuration completed"
}

# If script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    setup_git "$@"
fi
