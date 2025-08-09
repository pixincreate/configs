#!/bin/bash

# Git Setup Module
# Handles Git configuration and SSH key management

# Source common functions
if [[ -z "${GIT_SCRIPT_DIR:-}" ]]; then
    GIT_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi
source "${GIT_SCRIPT_DIR}/common.sh"

# Configuration
readonly DEFAULT_SSH_PERMS=0600
readonly GITCONFIG_EMAIL="${GITCONFIG_EMAIL:-69745008+pixincreate@users.noreply.github.com}"
readonly GITCONFIG_USERNAME="${GITCONFIG_USERNAME:-PiX}"
readonly GITCONFIG_SIGNGING_KEY="${GITCONFIG_SIGNGING_KEY:-$HOME/.ssh/id_ed25519_sign.pub}"

# Git checkup for platform-specific setup
git_checkup() {
  case "$OSTYPE" in
  linux-gnu)
    # Check if running in WSL, if yes, copy the keys
    if [[ "$WSL_DISTRO_NAME" == "Debian" ]]; then
      print "Setting up git for WSL..." true
      WINHOME=$(wslpath "$(cd /mnt/c && cmd.exe /C 'echo %USERPROFILE%' | tr -d '\r')")

      files="id_ed25519_auth id_ed25519_auth.pub id_ed25519_sign id_ed25519_sign.pub"
      for file in $files; do
        src="$WINHOME/.ssh/$file"
        dest="$HOME/.ssh/$file"

        if [ -f "$src" ]; then
          cp "$src" "$dest"
        else
          print "File not found: $src"
        fi
      done
      chmod $DEFAULT_SSH_PERMS .ssh/*

      print "WSL setup completed!"
    fi
    ;;
  linux-android)
    print "Setting up git for Android..." true
    cp -a /storage/emulated/0/Documents/Dev/.ssh/. $HOME/.ssh/
    chmod $DEFAULT_SSH_PERMS .ssh/*
    print "Android setup completed!"
    ;;
  *)
    print "Platform: $OSTYPE - using standard setup"
    ;;
  esac
}

# Update gitconfig with user data
update_gitconfig_data() {
  git_checkup

  if [[ -f ~/.gitconfig ]]; then
    log_info "Updating Git configuration..."
    sed -i.bak "s/email = example@email.com/email = ${GITCONFIG_EMAIL}/" ~/.gitconfig
    sed -i.bak "s/name = username/name = ${GITCONFIG_USERNAME}/" ~/.gitconfig
    sed -i.bak "s|signingkey = ~/.ssh/signingkey|signingkey = ${GITCONFIG_SIGNGING_KEY}|" ~/.gitconfig
    log_info "Git configuration updated successfully"
  else
    log_warn "Git configuration file not found. Make sure to stow the git package first."
  fi
}

# Function to generate SSH keys
generate_ssh_keys() {
  local email="$1"
  local auth_path="$HOME/.ssh/id_ed25519_auth"
  local sign_path="$HOME/.ssh/id_ed25519_sign"

  if [[ -z "$email" ]]; then
    log_error "Email is required for SSH key generation"
    return 1
  fi

  log_info "Generating SSH keys..."
  print "Path to authentication file: ${auth_path}"
  print "Path to signature file: ${sign_path}"

  # Create .ssh directory if it doesn't exist
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"

  # Generate authentication key
  if [[ ! -f "$auth_path" ]]; then
    ssh-keygen -t ed25519 -C "$email" -f "$auth_path" -N ""
    log_info "Generated authentication key: $auth_path"
  else
    log_warn "Authentication key already exists: $auth_path"
  fi

  # Generate signing key
  if [[ ! -f "$sign_path" ]]; then
    ssh-keygen -t ed25519 -C "$email" -f "$sign_path" -N ""
    log_info "Generated signing key: $sign_path"
  else
    log_warn "Signing key already exists: $sign_path"
  fi

  # Set proper permissions
  chmod $DEFAULT_SSH_PERMS "$auth_path" "$sign_path"
  chmod 644 "${auth_path}.pub" "${sign_path}.pub"

  # Start SSH agent and add keys
  eval "$(ssh-agent -s)"
  ssh-add "$auth_path"
  ssh-add "$sign_path"

  log_info "SSH keys generated and added to agent successfully"
}

# Function to copy keys and prompt for GitHub setup
copy_and_update_keys() {
  local auth_path="$HOME/.ssh/id_ed25519_auth.pub"
  local sign_path="$HOME/.ssh/id_ed25519_sign.pub"

  if [[ ! -f "$auth_path" || ! -f "$sign_path" ]]; then
    log_error "SSH keys not found. Please generate keys first."
    return 1
  fi

  print "You have 3 minutes each to visit https://github.com/settings/keys and update keys on GitHub." true
  sleep 4

  if command_exists pbcopy; then
    # macOS
    pbcopy < "$auth_path"
    print "Authentication key copied to clipboard" true
  elif command_exists xclip; then
    # Linux
    xclip -selection clipboard < "$auth_path"
    print "Authentication key copied to clipboard" true
  else
    print "Please manually copy the authentication key:"
    cat "$auth_path"
  fi

  print "Update the Authentication key on GitHub" true
  sleep 180

  if command_exists pbcopy; then
    pbcopy < "$sign_path"
    print "Signing key copied to clipboard" true
  elif command_exists xclip; then
    xclip -selection clipboard < "$sign_path"
    print "Signing key copied to clipboard" true
  else
    print "Please manually copy the signing key:"
    cat "$sign_path"
  fi

  echo "Update the Signature key on GitHub" true
  sleep 180

  # Test SSH connection to GitHub
  log_info "Testing SSH connection to GitHub..."
  ssh -T git@github.com
}

# Main git setup function
git_setup() {
  print "Fresh setup Git or restore existing configuration?"
  select confirm in "Fresh setup" "Restore existing" "exit"; do
    case $confirm in
    "Fresh setup")
      # Fresh setup (if selected)
      print "Performing fresh Git setup..." true

      local user_name=""
      local user_email=""
      local private_email=""

      # Prompt for user details (single loop)
      while [[ -z "$user_name" || -z "$user_email" || -z "$private_email" ]]; do
        if [[ -z "$user_name" || "$user_name" =~ ^[[:space:]]*$ ]]; then
          read -p "Enter your user name for configuring git: " user_name
          if [[ -z "$user_name" || "$user_name" =~ ^[[:space:]]*$ ]]; then
            print "Username cannot be empty or whitespace." true
            user_name=""
            continue
          fi
        fi

        if [[ -z "$user_email" || "$user_email" =~ ^[[:space:]]*$ ]]; then
          read -p "Enter your email for configuring git: " user_email
          if [[ -z "$user_email" || "$user_email" =~ ^[[:space:]]*$ ]]; then
            print "Email cannot be empty or whitespace." true
            user_email=""
            continue
          fi
        fi

        if [[ -z "$private_email" || "$private_email" =~ ^[[:space:]]*$ ]]; then
          read -p "Enter your no-reply email for configuring git: " private_email
          if [[ -z "$private_email" || "$private_email" =~ ^[[:space:]]*$ ]]; then
            print "No-reply email cannot be empty or whitespace." true
            private_email=""
            continue
          fi
        fi
      done

      # Update global configuration variables
      GITCONFIG_USERNAME="$user_name"
      GITCONFIG_EMAIL="$private_email"

      update_gitconfig_data
      generate_ssh_keys "$user_email"
      copy_and_update_keys
      break
      ;;
    "Restore existing")
      # Restore existing configuration
      print "Restoring existing Git configuration..." true
      update_gitconfig_data
      print "Existing Git configuration restored!"
      break
      ;;
    "exit")
      break
      ;;
    *)
      print "Invalid selection. Please choose '1' for fresh setup or '2' to restore existing git configuration."
      ;;
    esac
  done
}

# Function to verify git configuration
verify_git_config() {
  log_step "Verifying Git configuration..."

  if git config --global user.name >/dev/null 2>&1; then
    log_info "Git username: $(git config --global user.name)"
  else
    log_warn "Git username not configured"
  fi

  if git config --global user.email >/dev/null 2>&1; then
    log_info "Git email: $(git config --global user.email)"
  else
    log_warn "Git email not configured"
  fi

  if git config --global user.signingkey >/dev/null 2>&1; then
    log_info "Git signing key: $(git config --global user.signingkey)"
  else
    log_warn "Git signing key not configured"
  fi

  # Check if SSH keys exist
  if [[ -f "$HOME/.ssh/id_ed25519_auth" ]]; then
    log_info "SSH authentication key exists"
  else
    log_warn "SSH authentication key not found"
  fi

  if [[ -f "$HOME/.ssh/id_ed25519_sign" ]]; then
    log_info "SSH signing key exists"
  else
    log_warn "SSH signing key not found"
  fi
}

# Function to test Git/SSH setup
test_git_setup() {
  log_step "Testing Git setup..."

  # Test SSH connection to GitHub
  if ssh -T git@github.com -o ConnectTimeout=10 -o BatchMode=yes 2>/dev/null; then
    log_info "SSH connection to GitHub successful"
  else
    log_warn "SSH connection to GitHub failed or requires authentication"
  fi

  # Test Git configuration
  if git config --global user.name >/dev/null && git config --global user.email >/dev/null; then
    log_info "Git configuration is complete"
  else
    log_warn "Git configuration is incomplete"
  fi
}

# Export functions for use in other modules
export -f git_checkup update_gitconfig_data generate_ssh_keys copy_and_update_keys
export -f git_setup verify_git_config test_git_setup
