# Config Refactor

## Requirements

Keep the code as simple as possible.
The code should be easy to read and understand.
It should be easy to extend and maintain.
When in doubt, prefer simplicity over complexity, search the internet for solutions, and use existing tools and libraries.
Check the `@/fedora/setup-fedora.sh` and `@/unix/setup.sh` script
Check [this](https://github.com/pixincreate/configs/pull/10/files) remote branch for the refactor that is already done. I'm asking you to refactor this because the previous one was not simpler, it was overcomplicated, felt like a mess.

## Directory Structure Change

`.configs` directory path has been changed `~/Dev/.configs` from `~/Dev/scripts/.configs`.

## Git Config Refactor

At present, `.gitconfig` being stowed. But, in this repo, it is being treated as a template with gitconfig name, email and path variables.
So, to address this, below is what needs to be done:

- Keep `.gitconfig` as in it is`. Use it for stowing. But, it should not contain user information.
- Create `.gitconfig.user` file. This file should contain user information like name, email, and path variables. This shouldn't be stowed but copied.

You can also involve the following snippet in the script to set up the Git identity and SSH key:

```sh
echo "🔧 Setting up Git identity and SSH key..."

# Prompt for git user.name if not set
if ! git config --global user.name &>/dev/null; then
  read -rp "👤 Enter your Git user.name: " GIT_NAME
  git config --global user.name "$GIT_NAME"
else
  echo "✅ Git user.name is already set to: $(git config --global user.name)"
fi

# Prompt for git user.email if not set
if ! git config --global user.email &>/dev/null; then
  read -rp "📧 Enter your Git user.email: " GIT_EMAIL
  git config --global user.email "$GIT_EMAIL"
else
  echo "✅ Git user.email is already set to: $(git config --global user.email)"
fi

echo "✅ Final Git identity:"
git config --global --get user.name
git config --global --get user.email

# Setup SSH key if not already present
SSH_KEY="$HOME/.ssh/id_ed25519"
if [ ! -f "$SSH_KEY" ]; then
  echo "🔐 SSH key not found. Generating..."
  mkdir -p "$HOME/.ssh"
  ssh-keygen -t ed25519 -C "$(git config --global user.email)" -f "$SSH_KEY" -N ""
  echo "✅ SSH key generated."
else
  echo "✅ SSH key already exists at $SSH_KEY"
fi

# Add to ssh-agent
echo "🔑 Adding SSH key to ssh-agent..."
eval "$(ssh-agent -s)" >/dev/null
ssh-add "$SSH_KEY"

# Show key for manual copy
echo ""
echo "📋 Your SSH public key (copy it to GitHub → Settings → SSH Keys):"
echo "-----------------------------------------------------------------"
cat "$SSH_KEY.pub"
echo "-----------------------------------------------------------------"
echo ""

# Optionally upload to GitHub via API
read -rp "🪪 Do you want to upload this key to GitHub automatically? (y/N): " upload_choice
if [[ "$upload_choice" =~ ^[Yy]$ ]]; then
  read -rp "🔑 Enter your GitHub personal access token (with 'admin:public_key' scope): " GITHUB_TOKEN
  read -rp "📝 Enter a title for this key (e.g., hangsai-nixos): " KEY_TITLE

  PUB_KEY_CONTENT=$(cat "$SSH_KEY.pub")

  curl -s -H "Authorization: token $GITHUB_TOKEN" \
       -H "Content-Type: application/json" \
       -d "{\"title\": \"$KEY_TITLE\", \"key\": \"$PUB_KEY_CONTENT\"}" \
       https://api.github.com/user/keys | jq '.'

  echo "✅ SSH key uploaded to GitHub."
else
  echo "🧷 Skipped GitHub key upload."
fi

# ----------------------------------------
# 7. Convert dotfiles repo remote from HTTPS to SSH
# ----------------------------------------
echo "🔄 Checking dotfiles remote URL..."

cd "$DOTFILES_DIR"

CURRENT_REMOTE=$(git remote get-url origin)

if [[ "$CURRENT_REMOTE" == https://github.com/* ]]; then
  SSH_REMOTE="${CURRENT_REMOTE/https:\/\/github.com\//git@github.com:}"

  git remote set-url origin "$SSH_REMOTE"
  echo "✅ Remote URL updated to SSH:"
  git remote -v
else
  echo "✅ Remote already uses SSH or a custom URL:"
  git remote -v
fi
# some extra github sanity commands
git config pull.rebase false
```

## Fonts and Wallpapers

Create a new directories within `~/Pictures` called `Wallpapers` and `Screenshots`. Stow the existing wallpapers.

Install the fonts in `~/Dev/.configs/fonts` to `~/.local/share/fonts`.

## Platforms

- Recently setup `Fedora KDE 42`
- A Macbook
- Used to have a Windows machine and I replaced that with Fedora.
  - WSL had Debian
- Android running Termux

## Apps and tools

- Installer:
  - Macbook:
    - Homebrew:
      - Tools
      - Casks
  - Fedora:
    - DNF
    - Flatpak (GUI apps)
  - Debian:
    - APT (System tools)
    - Homebrew (Terminal tools)
  - Android (Terminal tools):
    - Pkg
- Terminal tools:
  - Common (Macbook, Fedora, Debian, Android):
    - htop
    - btop
    - tealdeer
    - git
    - wget
    - curl
    - zsh
    - vim
    - neovim
    - micro
    - bat
    - direnv
    - fastfetch
    - fzf
    - git-delta
    - jq
    - pipx
    - ripgrep
    - tar
    - tmux
    - tree
    - xclip
    - zoxide
    - croc
    - openssh
    - atuin
    - topgrade
    - starship
    - gh
    - coreutils
    - binutils
    - protobuf
    - nextdns
    - gcc
    - node
    - python
    - rustup
    - sqlite
    - ollama
    - llvm
    - ffmpeg
    - parallel
  - Macbook specific:
    - gnu-sed
  - Fedora Specific:
    - java-latest-openjdk
    - postgresql-server
    - postgresql-devel
    - redis
    - docker
    - kubectl
    - code
    - dnf-plugins-core
    - btrfs-assistant
    - lm_sensors
    - pkg-config
    - dpkg
    - tlp
    - tlp-rdw
    - powertop
    - tailscale (requires: sudo dnf config-manager addrepo --from-repofile=https://pkgs.tailscale.com/stable/fedora/tailscale.repo)
    - asusctl
    - supergfxctl
  - Android Specific:
    - termux-api
    - termux-tools
    - tsu
- Apps:
  - Macbook:
    - alt-tab
    - android-studio
    - bitwarden
    - brave-browser@beta
    - zen-browser
    - localsend
    - maccy
    - obsidian
    - rectangle
    - signal@beta
    - visual-studio-code
    - zed@preview
    - onlyoffice
    - tailscale-app
    - wezterm
    - postman
    - orbstack
  - Fedora:
    - app.zen_browser.zen
    - com.brave.Browser
    - dev.zed.Zed
    - org.signal.Signal
    - md.obsidian.Obsidian
    - org.localsend.localsend_app
    - com.bitwarden.desktop
    - org.onlyoffice.desktopeditors
    - com.obsproject.Studio
    - org.mozilla.Thunderbird
    - org.davinci.DaVinciResolve
    - com.valvesoftware.Steam

## Fedora KDE 42

Check the setup script in @/fedora/setup-fedora.sh for more details. It does the following:

- Enable RPM Fusion repositories
- Enable Copr repo
- Install packages
- Enable services
- Sets up rust
- Sets up nextdns
- Sets up nvidia drivers
- Sets up Asus utilities
- Sets up TLP
- Sets up multimedia
- Updates the system

## Expectations

- Rewrite the setup script in a modular way.
  - It should be divided into multiple files.
  - Utils file should contain the common and utility functions like logger, confirmation prompts, etc.
  - Better to have a main script that calls the individual task scripts.
    - Installer script
      - Depending on the platform, it should install the required tools and apps.
    - Git config script
    - Fonts and wallpapers script
    - Zsh config script
    - Stow script
    - Miscellaneous script (for other tasks like setting up SSH, updating remote URLs, etc.)
- It should contain functions for each task.
- It should be easy to extend and maintain.
- It should be easy to read and understand.
- It should have option to run the full setup as well as individual tasks.
- It should have dry-run mode to see what will be done without actually doing it.
- Stow should ask user to override the existing files if there are any conflicts.
- zshrc updater should update the @/home/zsh/.zsh/.zshrc and not `~/.zsh/.zshrc`. When there exist an update, it should ask user if they want to update the file.
- `.rish` directory should only be created in android environment.
- Fedora should not have `homebrew`.
