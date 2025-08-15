#!/usr/bin/env python3
"""
Unified Setup Script for Multi-Platform Development Environment
Replaces fedora/setup-fedora.sh and unix/setup.sh with a clean Python implementation.
"""

import argparse
import hashlib
import json
import os
import platform
import shutil
import subprocess
import sys
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional


def install_dependencies():
    """Install required dependencies if missing."""
    try:
        import toml
        from rich.console import Console
        from rich.prompt import Confirm, Prompt
        from rich.tree import Tree

        return toml, Console, Confirm, Prompt, Tree
    except ImportError:
        print("Missing required dependencies. Installing...")

        install_commands = [
            [sys.executable, "-m", "pip", "install", "--user", "toml", "rich"],
            [
                sys.executable,
                "-m",
                "pip",
                "install",
                "--break-system-packages",
                "toml",
                "rich",
            ],
            ["pipx", "install", "toml", "rich"],
        ]

        for cmd in install_commands:
            try:
                subprocess.check_call(cmd)
                import toml
                from rich.console import Console
                from rich.prompt import Confirm, Prompt
                from rich.tree import Tree

                return toml, Console, Confirm, Prompt, Tree
            except (subprocess.CalledProcessError, FileNotFoundError):
                continue

        print("Failed to install dependencies automatically.")
        print("Please install manually: pip install --user toml rich")
        sys.exit(1)


# Install and import dependencies
toml, Console, Confirm, Prompt, Tree = install_dependencies()
console = Console()


@dataclass
class SetupConfig:
    """Configuration container for setup operations."""

    dry_run: bool = False
    verbose: bool = False
    platform: str = ""
    script_dir: Path = (
        Path(__file__).resolve().parent if "__file__" in globals() else Path.cwd()
    )
    repository_root: Path = (
        Path(__file__).resolve().parent.parent
        if "__file__" in globals()
        else Path.cwd().parent
    )
    config_path: Path = (
        Path(__file__).resolve().parent if "__file__" in globals() else Path.cwd()
    ) / "config.toml"
    _config_cache: Optional[Dict] = None

    @property
    def config(self) -> Dict:
        """Cached configuration loading."""
        if self._config_cache is None:
            self._config_cache = self._load_config()
        return self._config_cache

    def _load_config(self) -> Dict:
        """Load configuration from packages.toml."""
        if not self.config_path.exists():
            self._log_error(f"Configuration file not found: {self.config_path}")
            sys.exit(1)

        try:
            with open(self.config_path, "r") as f:
                config = toml.load(f)
            self._log_success(f"Loaded configuration from {self.config_path}")
            return config
        except Exception as e:
            self._log_error(f"Failed to load configuration: {e}")
            sys.exit(1)

    def _log_info(self, message: str, emoji: str = "ℹ️"):
        """Log info message with emoji."""
        console.print(f"{emoji} {message}", style="blue")

    def _log_success(self, message: str, emoji: str = "✅"):
        """Log success message."""
        console.print(f"{emoji} {message}", style="green")

    def _log_warning(self, message: str, emoji: str = "⚠️"):
        """Log warning message."""
        console.print(f"{emoji} {message}", style="yellow")

    def _log_error(self, message: str, emoji: str = "❌"):
        """Log error message."""
        console.print(f"{emoji} {message}", style="red")


# Global setup configuration
setup_config = SetupConfig()


# Convenience functions that delegate to setup_config
def log_info(message: str, emoji: str = "ℹ️"):
    """Log info message with emoji."""
    setup_config._log_info(message, emoji)


def log_success(message: str, emoji: str = "✅"):
    """Log success message."""
    setup_config._log_success(message, emoji)


def log_warning(message: str, emoji: str = "⚠️"):
    """Log warning message."""
    setup_config._log_warning(message, emoji)


def log_error(message: str, emoji: str = "❌"):
    """Log error message."""
    setup_config._log_error(message, emoji)


def run_command(
    cmd: str, check: bool = True, capture_output: bool = False
) -> subprocess.CompletedProcess:
    """Run shell command with optional dry-run mode."""
    if setup_config.verbose or setup_config.dry_run:
        log_info(f"Running: {cmd}", "🔧")

    if setup_config.dry_run:
        log_warning(f"DRY RUN: Would execute: {cmd}")
        return subprocess.CompletedProcess(cmd, 0, "", "")

    try:
        result = subprocess.run(
            cmd, shell=True, check=check, capture_output=capture_output, text=True
        )
        return result
    except subprocess.CalledProcessError as e:
        log_error(f"Command failed: {cmd}")
        log_error(f"Error: {e}")
        if check:
            raise
        return e


def detect_platform() -> str:
    """Detect the current platform."""
    if setup_config.platform:
        return setup_config.platform

    system = platform.system().lower()

    if system == "darwin":
        setup_config.platform = "macos"
    elif system == "linux":
        # Check for specific Linux distributions
        if Path("/etc/fedora-release").exists():
            setup_config.platform = "fedora"
        elif Path("/data/data/com.termux").exists():
            setup_config.platform = "android"
        else:
            setup_config.platform = "debian"  # Default to debian for other Linux
    else:
        log_error(f"Unsupported platform: {system}")
        sys.exit(1)

    return setup_config.platform


def load_config() -> Dict:
    """Load configuration from packages.toml."""
    return setup_config.config


def command_exists(command: str) -> bool:
    """Check if a command exists in PATH."""
    return shutil.which(command) is not None


def create_directories():
    """Create necessary directories."""
    log_info("Creating necessary directories...", "📁")

    config = load_config()
    directories_config = config.get("directories", {})

    # Use config.toml directories if available, otherwise use defaults
    directories = [
        Path.home() / ".config",
        Path.home() / ".ssh",
        Path.home() / ".zsh",
        Path.home() / ".zsh" / ".zgenom",
        Path(
            directories_config.get("wallpapers_dir", "~/Pictures/Wallpapers").replace(
                "~", str(Path.home())
            )
        ),
        Path(
            directories_config.get("screenshots_dir", "~/Pictures/Screenshots").replace(
                "~", str(Path.home())
            )
        ),
        Path.home() / ".local" / "share" / "fonts",
    ]

    # Add .rish directory only for Android
    platform_name = detect_platform()
    if platform_name == "android":
        directories.append(Path.home() / ".rish")

    for directory in directories:
        if not setup_config.dry_run:
            directory.mkdir(parents=True, exist_ok=True)
        log_success(f"Created directory: {directory}")


def setup_homebrew() -> bool:
    """Install Homebrew if not present."""
    if command_exists("brew"):
        log_success("Homebrew already installed")
        run_command("brew update")
        return True

    log_info("Installing Homebrew...", "🍺")

    # Install Homebrew
    install_cmd = '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    run_command(install_cmd)

    # Add to PATH
    platform_name = detect_platform()
    if platform_name == "macos":
        brew_path = "/opt/homebrew/bin/brew"
    else:
        brew_path = "/home/linuxbrew/.linuxbrew/bin/brew"

    if not setup_config.dry_run and Path(brew_path).exists():
        run_command(f'eval "$({brew_path} shellenv)"')

    # Turn off analytics
    run_command("brew analytics off")

    log_success("Homebrew installation completed")
    return True


def setup_fedora_repositories():
    """Setup Fedora-specific repositories."""
    log_info("Setting up Fedora repositories...", "📦")

    config = load_config()

    # Enable COPR repositories
    if "fedora_copr" in config.get("package_managers", {}):
        for repo in config["package_managers"]["fedora_copr"]["repos"]:
            # Check if COPR is already enabled
            try:
                result = run_command(
                    "dnf copr list --enabled", capture_output=True, check=False
                )
                if result.returncode == 0 and repo in result.stdout:
                    log_success(f"COPR already enabled: {repo}")
                    continue
            except Exception:
                pass

            log_info(f"Enabling COPR: {repo}")
            run_command(f"sudo dnf copr enable -y {repo}")

    # Add external repositories
    if "fedora_external" in config.get("package_managers", {}):
        for repo in config["package_managers"]["fedora_external"]["repos"]:
            name = repo["name"]
            repo_file_path = f"/etc/yum.repos.d/{name}.repo"

            # Check if repository file already exists
            if not setup_config.dry_run and Path(repo_file_path).exists():
                log_success(f"Repository already configured: {name}")
                continue

            log_info(f"Adding external repository: {name}")

            if "key" in repo:
                # Import GPG key first (safe to run multiple times)
                run_command(f"sudo rpm --import {repo['key']}")

            if "url" in repo:
                # Download repository file
                run_command(f"sudo curl -Ls {repo['url']} -o {repo_file_path}")
            elif "repo" in repo:
                # Write repository configuration
                repo_content = repo["repo"]
                if not setup_config.dry_run:
                    # Use sudo tee to write to system directory
                    run_command(
                        f"echo '{repo_content}' | sudo tee {repo_file_path} > /dev/null"
                    )

    # Install RPM Fusion (check if already installed)
    try:
        result = run_command(
            "rpm -q rpmfusion-free-release", capture_output=True, check=False
        )
        if result.returncode == 0:
            log_success("RPM Fusion repositories already installed")
        else:
            log_info("Installing RPM Fusion repositories...")
            rpm_fusion_cmd = (
                "sudo dnf install -y "
                "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm "
                "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
            )
            run_command(rpm_fusion_cmd)
    except Exception:
        log_warning(
            "Could not check RPM Fusion installation status, attempting to install..."
        )
        rpm_fusion_cmd = (
            "sudo dnf install -y "
            "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm "
            "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
        )
        run_command(rpm_fusion_cmd)

    # Install Terra repository (check if already installed)
    try:
        result = run_command("rpm -q terra-release", capture_output=True, check=False)
        if result.returncode == 0:
            log_success("Terra repository already installed")
        else:
            log_info("Installing Terra repository...")
            terra_cmd = (
                "sudo dnf install -y "
                "--nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release"
            )
            run_command(terra_cmd)
    except Exception:
        log_warning(
            "Could not check Terra installation status, attempting to install..."
        )
        terra_cmd = (
            "sudo dnf install -y "
            "--nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release"
        )
        run_command(terra_cmd)

    # Enable OpenH264 repository (safe to run multiple times)
    run_command("sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1")

    log_success("Fedora repositories setup completed")


def install_packages_for_platform(platform_name: str, category: str = "all"):
    """Install packages for specified platform and category."""
    config = load_config()
    platform_config = config["platforms"].get(platform_name, {})

    if not platform_config:
        log_error(f"No configuration found for platform: {platform_name}")
        return

    log_info(f"Installing packages for {platform_name}...", "📦")

    # Install terminal tools
    if category in ["all", "terminal"] and "terminal_tools" in platform_config:
        install_terminal_tools(platform_name, platform_config["terminal_tools"])

    # Install GUI apps
    if category in ["all", "gui"] and "gui_apps" in platform_config:
        install_gui_apps(platform_name, platform_config["gui_apps"])


def install_terminal_tools(platform_name: str, tools_config: Dict):
    """Install terminal tools based on platform."""
    log_info("Installing terminal tools...", "⚒️")

    # Load common tools and merge with platform-specific tools
    config = load_config()
    common_terminal_tools = config.get("common_tools", {}).get("terminal", [])

    for package_manager, packages in tools_config.items():
        # Merge common tools with platform-specific tools
        if package_manager in ["homebrew", "dnf", "pkg"]:
            # For these package managers, add common tools automatically
            merged_packages = list(common_terminal_tools) + list(packages)

            # Apply package mapping for platform-specific names
            mapped_packages = apply_package_mapping(merged_packages, platform_name)

            log_info(
                f"Installing packages with {package_manager}: {len(merged_packages)} packages "
                f"({len(common_terminal_tools)} common + {len(packages)} specific)"
            )
        elif package_manager == "apt":
            # APT gets only the packages specified (system packages only for Debian)
            mapped_packages = apply_package_mapping(packages, platform_name)
            log_info(
                f"Installing packages with {package_manager}: {len(packages)} packages"
            )
        else:
            mapped_packages = packages
            log_info(
                f"Installing packages with {package_manager}: {len(packages)} packages"
            )

        if package_manager == "dnf":
            install_with_dnf(mapped_packages)
        elif package_manager == "apt":
            install_with_apt(mapped_packages)
        elif package_manager == "pkg":
            install_with_pkg(mapped_packages)
        elif package_manager == "homebrew":
            if platform_name != "fedora":  # No homebrew on Fedora
                setup_homebrew()
                install_with_brew(mapped_packages)


def apply_package_mapping(packages: List[str], platform_name: str) -> List[str]:
    """Apply platform-specific package name mappings."""
    config = load_config()
    package_mapping = config.get("package_mapping", {})

    mapped_packages = []
    for package in packages:
        if package in package_mapping and platform_name in package_mapping[package]:
            # Use platform-specific package name
            mapped_packages.append(package_mapping[package][platform_name])
        else:
            # Use original package name
            mapped_packages.append(package)

    return mapped_packages


def install_gui_apps(platform_name: str, apps_config: Dict):
    """Install GUI applications based on platform."""
    log_info("Installing GUI applications...", "🖥️")

    for package_manager, packages in apps_config.items():
        if not packages:
            continue

        log_info(
            f"Installing GUI apps with {package_manager}: {len(packages)} packages"
        )

        if package_manager == "casks":
            setup_homebrew()
            install_with_brew_cask(packages)
        elif package_manager == "flatpak":
            install_with_flatpak(packages)


def install_with_dnf(packages: List[str]):
    """Install packages using DNF."""
    packages_str = " ".join(packages)
    run_command(f"sudo dnf install -y {packages_str}")


def install_with_apt(packages: List[str]):
    """Install packages using APT."""
    run_command("sudo apt-get update")
    packages_str = " ".join(packages)
    run_command(f"sudo apt-get install -y {packages_str}")


def install_with_pkg(packages: List[str]):
    """Install packages using pkg (Termux)."""
    packages_str = " ".join(packages)
    run_command(f"pkg install -y {packages_str}")


def install_with_brew(packages: List[str]):
    """Install packages using Homebrew."""
    for package in packages:
        run_command(f"brew install {package}")


def install_with_brew_cask(packages: List[str]):
    """Install GUI apps using Homebrew Cask."""
    for package in packages:
        run_command(f"brew install --cask {package}")


def install_with_flatpak(packages: List[str]):
    """Install packages using Flatpak."""
    # Enable Flathub repository
    run_command(
        "flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo"
    )

    for package in packages:
        run_command(f"flatpak install -y flathub {package}")


def setup_git_config():
    """Setup Git configuration with SSH keys."""
    log_info("Setting up Git configuration...", "🔧")

    config = load_config()
    git_config = config.get("git", {})

    # Get current values - only use capture_output in non-dry-run mode
    git_name = None
    git_email = None

    if not setup_config.dry_run:
        try:
            result = run_command(
                "git config --global user.name", capture_output=True, check=False
            )
            if result.returncode == 0 and result.stdout.strip():
                git_name = result.stdout.strip()
        except Exception:
            pass

        try:
            result = run_command(
                "git config --global user.email", capture_output=True, check=False
            )
            if result.returncode == 0 and result.stdout.strip():
                git_email = result.stdout.strip()
        except Exception:
            pass

    # Prompt for missing values only
    if not git_name:
        git_name = Prompt.ask(
            "👤 Enter your Git user.name", default=git_config.get("default_name", "")
        )
        if git_name and not setup_config.dry_run:
            run_command(f'git config --global user.name "{git_name}"')
        elif setup_config.dry_run:
            log_warning(f"DRY RUN: Would set git user.name to: {git_name}")
    else:
        log_success(f"Git user.name already set: {git_name}")

    if not git_email:
        git_email = Prompt.ask(
            "📧 Enter your Git user.email", default=git_config.get("default_email", "")
        )
        if git_email and not setup_config.dry_run:
            run_command(f'git config --global user.email "{git_email}"')
        elif setup_config.dry_run:
            log_warning(f"DRY RUN: Would set git user.email to: {git_email}")
    else:
        log_success(f"Git user.email already set: {git_email}")

    # Create .gitconfig.local file
    create_gitconfig_local(git_name, git_email)

    # Show final Git identity
    log_success("Final Git identity:")
    if not setup_config.dry_run:
        run_command("git config --global --get user.name")
        run_command("git config --global --get user.email")
    else:
        log_info(f"Name: {git_name}")
        log_info(f"Email: {git_email}")

    # Setup SSH key (only if not exists)
    ssh_key = Path.home() / ".ssh" / "id_ed25519"
    if ssh_key.exists():
        log_success(f"SSH key already exists at {ssh_key}")
    else:
        setup_ssh_key()

    # Convert remote URLs
    convert_remote_urls()


def create_gitconfig_local(git_name: str, git_email: str):
    """Create .gitconfig.local file with user configuration."""
    gitconfig_local = Path.home() / ".config" / "gitconfig" / ".gitconfig.local"
    signing_key = Path.home() / ".ssh" / "id_ed25519_sign.pub"

    log_info("Creating .gitconfig.local file...")

    if not setup_config.dry_run:
        # Create directory if it doesn't exist
        gitconfig_local.parent.mkdir(parents=True, exist_ok=True)

        # Create the gitconfig.local content
        gitconfig_content = f"""[user]
  name = "{git_name}"
  email = "{git_email}"
  signingkey = "{signing_key}"
"""

        with open(gitconfig_local, "w") as f:
            f.write(gitconfig_content)

        log_success(f"Git configuration file created: {gitconfig_local}")
    else:
        log_info(f"[DRY RUN] Would create: {gitconfig_local}")
        console.print(
            f"""[user]
  name = "{git_name}"
  email = "{git_email}"
  signingkey = "{signing_key}"
"""
        )


def setup_ssh_key():
    """Setup SSH key if not present."""
    ssh_key = Path.home() / ".ssh" / "id_ed25519"

    if ssh_key.exists():
        log_success(f"SSH key already exists at {ssh_key}")
    else:
        log_info("SSH key not found. Generating...", "🔐")
        email = run_command(
            "git config --global user.email", capture_output=True
        ).stdout.strip()

        if not setup_config.dry_run:
            Path.home().joinpath(".ssh").mkdir(exist_ok=True)

        run_command(f'ssh-keygen -t ed25519 -C "{email}" -f {ssh_key} -N ""')
        log_success("SSH key generated")

    # Add to ssh-agent
    log_info("Adding SSH key to ssh-agent...", "🔑")
    run_command('eval "$(ssh-agent -s)"')
    run_command(f"ssh-add {ssh_key}")

    # Show public key
    console.print("\n📋 Your SSH public key (copy it to GitHub → Settings → SSH Keys):")
    console.print("-" * 65)
    if not setup_config.dry_run:
        with open(f"{ssh_key}.pub", "r") as f:
            console.print(f.read().strip())
    console.print("-" * 65)
    console.print()

    # Optionally upload to GitHub
    if Confirm.ask("🪪 Do you want to upload this key to GitHub automatically?"):
        upload_ssh_key_to_github(ssh_key)


def upload_ssh_key_to_github(ssh_key_path: Path):
    """Upload SSH key to GitHub via API."""
    token = Prompt.ask(
        "🔑 Enter your GitHub personal access token (with 'admin:public_key' scope)"
    )
    key_title = Prompt.ask("📝 Enter a title for this key", default="Setup Script Key")

    if not setup_config.dry_run:
        with open(f"{ssh_key_path}.pub", "r") as f:
            pub_key_content = f.read().strip()

        data = {"title": key_title, "key": pub_key_content}

        req = urllib.request.Request(
            "https://api.github.com/user/keys",
            data=json.dumps(data).encode(),
            headers={
                "Authorization": f"token {token}",
                "Content-Type": "application/json",
            },
        )

        try:
            urllib.request.urlopen(req)
            log_success("SSH key uploaded to GitHub")
        except Exception as e:
            log_error(f"Failed to upload SSH key: {e}")
    else:
        log_warning("DRY RUN: Would upload SSH key to GitHub")


def convert_remote_urls():
    """Convert dotfiles repo remote from HTTPS to SSH."""
    log_info("Checking dotfiles remote URL...", "🔄")

    configs_dir = Path.home() / "Dev" / ".configs"
    if not configs_dir.exists():
        log_warning("Configs directory not found, skipping remote URL conversion")
        return

    try:
        os.chdir(configs_dir)
        current_remote = run_command(
            "git remote get-url origin", capture_output=True
        ).stdout.strip()

        if current_remote.startswith("https://github.com/"):
            ssh_remote = current_remote.replace(
                "https://github.com/", "git@github.com:"
            )
            run_command(f"git remote set-url origin {ssh_remote}")
            log_success("Remote URL updated to SSH")
            run_command("git remote -v")
        else:
            log_success("Remote already uses SSH or custom URL")
            run_command("git remote -v")

        # Set git config for better experience
        run_command("git config pull.rebase false")

    except Exception as e:
        log_warning(f"Could not convert remote URL: {e}")


def install_fonts():
    """Install fonts from fonts directory."""
    log_info("Installing fonts...", "🔤")

    config = load_config()
    fonts_source = Path(
        config["directories"]["fonts_source"].replace("~", str(Path.home()))
    )
    fonts_target = Path(
        config["directories"]["fonts_target"].replace("~", str(Path.home()))
    )

    if not fonts_source.exists():
        log_warning(f"Fonts source directory not found: {fonts_source}")
        return

    if not setup_config.dry_run:
        fonts_target.mkdir(parents=True, exist_ok=True)

    font_files = list(fonts_source.glob("*.*"))

    if not font_files:
        log_warning("No font files found")
        return

    for font_file in font_files:
        if font_file.suffix.lower() in [".ttf", ".otf", ".woff", ".woff2"]:
            target_file = fonts_target / font_file.name
            if not setup_config.dry_run:
                shutil.copy2(font_file, target_file)
            log_success(f"Installed font: {font_file.name}")

    # Refresh font cache
    if command_exists("fc-cache"):
        run_command("fc-cache -fv")

    log_success(f"Installed {len(font_files)} fonts")


def update_zshrc():
    """Update .zshrc file with checksum verification."""
    log_info("Checking for .zshrc updates...", "🐚")

    zshrc_path = Path.home() / ".zsh" / ".zshrc"
    source_zshrc = Path.home() / "Dev" / ".configs" / "home" / "zsh" / ".zsh" / ".zshrc"

    if not source_zshrc.exists():
        log_warning(f"Source .zshrc not found: {source_zshrc}")
        return

    if not zshrc_path.exists():
        log_info("No existing .zshrc found, copying new one")
        if not setup_config.dry_run:
            shutil.copy2(source_zshrc, zshrc_path)
        log_success("Copied new .zshrc")
        return

    # Calculate checksums
    def calculate_checksum(file_path: Path) -> str:
        if not file_path.exists():
            return ""
        with open(file_path, "rb") as f:
            return hashlib.sha1(f.read()).hexdigest()

    current_checksum = calculate_checksum(zshrc_path)
    new_checksum = calculate_checksum(source_zshrc)

    if current_checksum != new_checksum:
        if Confirm.ask("📝 .zshrc has updates available. Do you want to update it?"):
            if not setup_config.dry_run:
                # Backup current file
                backup_path = zshrc_path.with_suffix(".zshrc.bak")
                shutil.copy2(zshrc_path, backup_path)

                # Copy new file
                shutil.copy2(source_zshrc, zshrc_path)

            log_success(".zshrc updated successfully!")
        else:
            log_info("Skipped .zshrc update")
    else:
        log_success(".zshrc is up-to-date!")


def create_platform_specific_additionals():
    """Create platform-specific .additionals.zsh file."""
    log_info("Creating platform-specific .additionals.zsh...", "⚙️")

    platform_name = detect_platform()
    additionals_path = Path.home() / ".zsh" / ".additionals.zsh"

    # Create content based on platform
    content = "# Platform-specific configurations\n\n"

    if platform_name == "macos":
        content += """
# macOS specific configurations
typeset -U PATH path
path=(
    $path
    $HOME/.yarn/bin
    $HOME/.config/yarn/global/node_modules/.bin
    $(brew --prefix)/opt/coreutils/libexec/gnubin
    $(brew --prefix)/opt/findutils/libexec/gnubin
    $(brew --prefix)/opt/gnu-getopt/bin
    $(brew --prefix)/opt/gnu-indent/libexec/gnubin
    $(brew --prefix)/opt/gnu-tar/libexec/gnubin
    $(brew --prefix)/opt/binutils/bin
    $(brew --prefix)/opt/homebrew/opt/openjdk@21/bin
    $(brew --prefix)/opt/homebrew/opt/openjdk@17/bin
    $(brew --prefix)/opt/llvm/bin
)

# Disable NPM ads
export DISABLE_OPENCOLLECTIVE=1
export ADBLOCK=1

PQ_LIB_DIR="$(brew --prefix libpq)/lib"

export CPPFLAGS="-I/opt/homebrew/opt/llvm/include"
export LDFLAGS="-L/opt/homebrew/opt/llvm/lib"
export CC="$(brew --prefix)/opt/llvm/bin/clang"
export CONFIGS=${HOME}/Dev/.configs

alias zed=zed-preview
"""
    elif platform_name == "fedora":
        content += """
# Fedora specific configurations
export SYS_HEALTH="${HOME}/Dev/.configs/unix/fedora/health-check.sh"
alias cleanup="sudo dnf autoremove && flatpak uninstall --unused"
export CONFIGS=${HOME}/Dev/.configs
"""
    elif platform_name == "debian":
        content += """
# Debian specific configurations
export LDFLAGS="-L/$(brew --prefix)/opt/binutils/lib"
export CPPFLAGS="-I/$(brew --prefix)/opt/binutils/include"
export CONFIGS=${HOME}/Dev/.configs

# WSL configurations (if applicable)
if [[ -n "$WSL_DISTRO_NAME" ]]; then
    export WINHOME=$(wslpath "$(cd /mnt/c && cmd.exe /C 'echo %USERPROFILE%' | tr -d '\\r')")
    alias studio='/mnt/d/Program\\ Files/IDE/Android\\ Studio/bin/studio64.exe'
fi
"""
    elif platform_name == "android":
        content += """
# Android/Termux specific configurations
alias backup_termux='tar -zcf /sdcard/backups/termux/termux-backup.tar.gz -C /data/data/com.termux/files ./home ./usr'
alias restore_termux='tar -zxf /sdcard/backups/termux/termux-backup.tar.gz -C /data/data/com.termux/files --recursive-unlink --preserve-permissions'
export CONFIGS=${HOME}/Dev/.configs
"""

    if not setup_config.dry_run:
        with open(additionals_path, "w") as f:
            f.write(content)

    log_success(f"Created .additionals.zsh for {platform_name}")


def stow_dotfiles(package: Optional[str] = None):
    """Stow dotfiles using GNU Stow."""
    log_info("Managing dotfiles with Stow...", "🔗")

    config = load_config()
    configs_dir = Path.home() / "Dev" / ".configs"
    stow_dir = configs_dir / "home"

    if not stow_dir.exists():
        log_error(f"Stow directory not found: {stow_dir}")
        return

    packages = config["directories"]["stow_packages"]

    if package:
        if package in packages:
            packages = [package]
        else:
            log_error(f"Package '{package}' not found in stow packages list")
            return

    for pkg in packages:
        pkg_dir = stow_dir / pkg
        if not pkg_dir.exists():
            log_warning(f"Package directory not found: {pkg_dir}")
            continue

        log_info(f"Stowing package: {pkg}")

        # Use --no-folding to prevent stow from folding directories
        # Use --restow to handle existing links
        stow_cmd = (
            f"stow --no-folding --restow --dir={stow_dir} --target={Path.home()} {pkg}"
        )

        try:
            run_command(stow_cmd)
            log_success(f"Successfully stowed: {pkg}")
        except subprocess.CalledProcessError:
            if Confirm.ask(
                f"❓ Stow conflict detected for {pkg}. Override existing files?"
            ):
                run_command(
                    f"stow --no-folding --restow --adopt --dir={stow_dir} --target={Path.home()} {pkg}"
                )
                log_success(f"Successfully stowed with override: {pkg}")
            else:
                log_warning(f"Skipped stowing: {pkg}")


def setup_services():
    """Setup and enable system services."""
    log_info("Setting up system services...", "⚙️")

    platform_name = detect_platform()

    if platform_name == "fedora":
        # PostgreSQL setup
        if command_exists("postgresql-setup"):
            run_command("sudo postgresql-setup --initdb")
            run_command("sudo systemctl enable postgresql.service")
            run_command("sudo systemctl start postgresql.service")

        # Redis setup
        if command_exists("redis-server"):
            run_command("sudo systemctl enable redis.service")
            run_command("sudo systemctl start redis.service")

        # Docker setup
        if command_exists("docker"):
            run_command("sudo systemctl enable docker.service")
            run_command("sudo systemctl start docker.service")
            run_command(f"sudo usermod -aG docker {os.getenv('USER')}")
            log_info(
                "Added user to docker group. Please log out and back in for changes to take effect."
            )


def setup_fedora_system():
    """Run Fedora-specific system setup."""
    log_info("Running Fedora system setup...", "🎩")

    # Update system first
    run_command("sudo dnf update -y --refresh")

    # Setup repositories
    setup_fedora_repositories()

    # Setup hostname from config
    setup_hostname()

    # Update firmware
    update_firmware()

    # Setup AppImage support
    setup_appimage_support()

    # Optimize boot and performance
    optimize_system_performance()

    # Setup multimedia (based on official Fedora recommendations)
    setup_multimedia()

    # Check for NVIDIA hardware
    try:
        run_command("lspci | grep -i nvidia", capture_output=True)
        log_info("NVIDIA hardware detected, installing drivers...")
        run_command("sudo dnf install -y kernel-devel")
        run_command("sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda")
        run_command("sudo dnf install -y nvidia-settings")
        run_command("sudo dnf install -y xorg-x11-drv-nvidia-libs.i686")
        run_command("sudo akmods --force")
        run_command(
            "sudo systemctl enable nvidia-hibernate.service nvidia-suspend.service nvidia-resume.service nvidia-powerd.service"
        )
        run_command("sudo dnf install nvidia-vaapi-driver vdpauinfo")

        # Enable NVIDIA modeset
        run_command('sudo grubby --update-kernel=ALL --args="nvidia-drm.modeset=1"')

        log_success("NVIDIA drivers installed with modeset enabled. Reboot required.")
    except subprocess.CalledProcessError:
        log_info("No NVIDIA hardware detected, skipping NVIDIA setup")

    # Check for ASUS hardware
    try:
        run_command(
            "dmidecode -s system-manufacturer | grep -i asus", capture_output=True
        )
        log_info("ASUS system detected, installing ASUS utilities...")
        setup_asus_system()
        log_success("ASUS system setup completed")
    except subprocess.CalledProcessError:
        log_info("Not an ASUS system, skipping ASUS setup")


def setup_hostname():
    """Setup system hostname from config."""
    log_info("Setting up hostname...", "🏷️")

    config = load_config()
    hostname = config.get("system", {}).get("hostname")

    if hostname:
        run_command(f"sudo hostnamectl set-hostname {hostname}")
        log_success(f"Hostname set to: {hostname}")
    else:
        log_warning("No hostname specified in config, skipping hostname setup")


def update_firmware():
    """Update system firmware using fwupd."""
    log_info("Updating firmware...", "🔧")

    if not command_exists("fwupdmgr"):
        log_info("Installing fwupd...")
        run_command("sudo dnf install -y fwupd")

    # Refresh firmware metadata
    run_command("sudo fwupdmgr refresh --force")

    # Get list of devices
    try:
        result = run_command(
            "sudo fwupdmgr get-devices", capture_output=True, check=False
        )
        if result.returncode == 0:
            log_info("Available devices for firmware update:")
            if not setup_config.dry_run:
                console.print(result.stdout)

        # Check for available updates
        result = run_command(
            "sudo fwupdmgr get-updates", capture_output=True, check=False
        )
        if result.returncode == 0 and result.stdout.strip():
            log_info("Firmware updates available:")
            if not setup_config.dry_run:
                console.print(result.stdout)

            # Apply updates
            if Confirm.ask("🔄 Apply firmware updates?"):
                run_command("sudo fwupdmgr update")
                log_success("Firmware updates applied")
            else:
                log_info("Skipped firmware updates")
        else:
            log_success("No firmware updates available")
    except Exception as e:
        log_warning(f"Firmware update check failed: {e}")


def setup_appimage_support():
    """Setup AppImage support with FUSE."""
    log_info("Setting up AppImage support...", "📱")

    # Install FUSE for AppImage support
    run_command("sudo dnf install -y fuse")
    log_success("FUSE installed for AppImage support")


def setup_multimedia():
    """Setup multimedia support based on official Fedora recommendations."""
    log_info("Setting up multimedia support...", "🎵")

    # 1. Install multimedia group (official Fedora recommendation)
    log_info("Installing multimedia group...")
    run_command("sudo dnf group install -y multimedia")

    # 2. Swap to full FFmpeg (RPM Fusion version with all codecs)
    log_info("Swapping to full FFmpeg...")
    run_command("sudo dnf swap ffmpeg-free ffmpeg --allowerasing")

    # 3. Update multimedia group and install sound-and-video
    log_info("Updating multimedia packages...")
    run_command(
        'sudo dnf group update multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin'
    )
    run_command("sudo dnf group update sound-and-video")

    # 4. Install essential multimedia libraries
    log_info("Installing multimedia libraries...")
    run_command("sudo dnf install -y ffmpeg-libs libva libva-utils")

    # 5. Hardware acceleration setup
    setup_hardware_acceleration()

    # 6. Install additional codecs and plugins
    log_info("Installing additional codecs...")
    run_command(
        "sudo dnf install -y gstreamer1-plugins-{bad-*,good-*,base} gstreamer1-plugin-openh264 gstreamer1-libav"
    )
    run_command("sudo dnf install -y lame* --exclude=lame-devel")

    # 7. Enable OpenH264 for browsers
    log_info("Setting up OpenH264 for browsers...")
    run_command("sudo dnf config-manager --set-enabled fedora-cisco-openh264")
    run_command(
        "sudo dnf install -y openh264 gstreamer1-plugin-openh264 mozilla-openh264"
    )

    log_success("Multimedia setup completed")


def setup_hardware_acceleration():
    """Setup hardware acceleration based on detected hardware."""
    log_info("Setting up hardware acceleration...", "🚀")

    # Detect Intel graphics
    try:
        run_command("lspci | grep -i intel.*graphics", capture_output=True)
        log_info("Intel graphics detected, installing Intel media drivers...")
        run_command(
            "sudo dnf swap libva-intel-media-driver intel-media-driver --allowerasing"
        )
        # Note: libva-intel-driver is legacy and usually not needed with intel-media-driver
        log_success("Intel hardware acceleration configured")
    except subprocess.CalledProcessError:
        log_info("No Intel graphics detected, skipping Intel drivers")

    # Detect AMD graphics
    try:
        run_command("lspci | grep -i amd.*graphics", capture_output=True)
        log_info("AMD graphics detected, installing AMD drivers...")
        # AMD drivers are usually included in mesa packages
        run_command("sudo dnf install -y mesa-va-drivers mesa-vdpau-drivers")
        log_success("AMD hardware acceleration configured")
    except subprocess.CalledProcessError:
        log_info("No AMD graphics detected, skipping AMD drivers")

    # NVIDIA will be handled separately in the main NVIDIA detection section
    # but we can install the VAAPI driver here if NVIDIA is detected
    try:
        run_command("lspci | grep -i nvidia", capture_output=True)
        log_info("NVIDIA graphics detected, installing NVIDIA media drivers...")
        run_command("sudo dnf install -y libva-nvidia-driver.{i686,x86_64}")
        log_success("NVIDIA VAAPI driver installed")
    except subprocess.CalledProcessError:
        log_info("No NVIDIA graphics detected, skipping NVIDIA VAAPI drivers")


def setup_asus_system():
    """Setup ASUS system with CachyOS kernel for better driver support."""
    log_info("Setting up ASUS system optimizations...", "🎮")

    # Install basic ASUS utilities
    run_command("sudo dnf install -y asusctl supergfxctl")
    run_command("sudo systemctl enable supergfxd.service")
    run_command("sudo systemctl start asusd")

    # Check CPU architecture support for CachyOS kernel
    if check_cpu_architecture_support():
        install_cachyos_kernel()
    else:
        log_warning(
            "CPU doesn't support x86_64_v3, skipping CachyOS kernel installation"
        )


def check_cpu_architecture_support() -> bool:
    """Check if CPU supports x86_64_v3 architecture for CachyOS kernel."""
    log_info("Checking CPU architecture support...", "🔍")

    try:
        result = run_command("/lib64/ld-linux-x86-64.so.2 --help", capture_output=True)
        output = result.stdout

        if "x86_64_v3 (supported, searched)" in output:
            log_success("CPU supports x86_64_v3 - CachyOS kernel compatible")
            return True
        elif "x86_64_v2 (supported, searched)" in output:
            log_info("CPU supports x86_64_v2 - can use LTS kernel")
            return True
        else:
            log_warning("CPU doesn't support required architecture")
            return False
    except subprocess.CalledProcessError:
        log_warning("Could not determine CPU architecture support")
        return False


def install_cachyos_kernel():
    """Install CachyOS kernel for better ASUS driver compatibility."""
    log_info("Installing CachyOS kernel for better ASUS driver support...", "⚡")

    # Setup SELinux policy for kernel modules
    log_info("Configuring SELinux for kernel modules...")
    run_command("sudo setsebool -P domain_kernel_load_modules on")

    # Ask user for kernel preference
    kernel_choice = Prompt.ask(
        "Choose CachyOS kernel type",
        choices=["standard", "realtime", "skip"],
        default="standard",
    )

    if kernel_choice == "skip":
        log_info("Skipping CachyOS kernel installation")
        return

    # Install selected kernel
    if kernel_choice == "standard":
        log_info("Installing standard CachyOS kernel...")
        run_command("sudo dnf install -y kernel-cachyos kernel-cachyos-devel-matched")
    elif kernel_choice == "realtime":
        log_info("Installing realtime CachyOS kernel...")
        log_warning(
            "Realtime kernel provides lower latency but may be less stable for general use"
        )
        run_command(
            "sudo dnf install -y kernel-cachyos-rt kernel-cachyos-rt-devel-matched"
        )

    log_success("CachyOS kernel installed - reboot required to use new kernel")


def setup_kde_wallpaper_config():
    """Configure KDE to use custom wallpaper directory."""
    log_info("Configuring KDE wallpaper settings...", "🖼️")

    config = load_config()
    directories_config = config.get("directories", {})
    wallpapers_dir = directories_config.get("wallpapers_dir", "~/Pictures/Wallpapers")

    # Expand tilde to full path
    wallpapers_path = wallpapers_dir.replace("~", str(Path.home()))

    if not setup_config.dry_run:
        # Check if we're in a KDE environment
        if (
            not os.getenv("KDE_SESSION_VERSION")
            and not os.getenv("DESKTOP_SESSION") == "plasma"
        ):
            # Try to detect if KDE is available anyway
            if not command_exists("kwriteconfig6") and not command_exists(
                "kwriteconfig5"
            ):
                log_warning(
                    "KDE not detected and kwriteconfig not available, skipping KDE wallpaper configuration"
                )
                return

        # Use kwriteconfig6 (KDE 6) or kwriteconfig5 (KDE 5) to set wallpaper directory
        kwrite_cmd = (
            "kwriteconfig6" if command_exists("kwriteconfig6") else "kwriteconfig5"
        )

        if command_exists(kwrite_cmd):
            try:
                # Set the default wallpaper directory for the Image wallpaper plugin
                run_command(
                    f'{kwrite_cmd} --file plasmarc --group Wallpapers --key usersWallpapers "{wallpapers_path}"'
                )

                # Also set it for the desktop containment
                containment_cmd = (
                    f"{kwrite_cmd} --file plasma-org.kde.plasma.desktop-appletsrc "
                    f"--group Containments --group 1 --group Wallpaper "
                    f'--group org.kde.image --group General --key Image "file://{wallpapers_path}"'
                )
                run_command(containment_cmd)

                log_success(f"KDE wallpaper directory configured: {wallpapers_path}")

                # Restart plasmashell to apply changes
                if Confirm.ask("🔄 Restart Plasma shell to apply wallpaper settings?"):
                    run_command("killall plasmashell && plasmashell &", check=False)
                    log_success("Plasma shell restarted")
                else:
                    log_info(
                        "Please restart Plasma shell manually to apply wallpaper settings"
                    )

            except subprocess.CalledProcessError as e:
                log_warning(f"Failed to configure KDE wallpaper settings: {e}")
        else:
            log_warning(
                "kwriteconfig not available, cannot configure KDE wallpaper settings"
            )
    else:
        log_info(
            f"[DRY RUN] Would configure KDE wallpaper directory: {wallpapers_path}"
        )


def optimize_system_performance():
    """Optimize system performance and boot time."""
    log_info("Optimizing system performance...", "⚡")

    # Disable CPU mitigations for better performance
    if Confirm.ask(
        "🚀 Disable CPU mitigations for better performance? (Less secure but faster)"
    ):
        run_command('sudo grubby --update-kernel=ALL --args="mitigations=off"')
        log_success("CPU mitigations disabled for better performance")
    else:
        log_info("Keeping CPU mitigations enabled for security")

    # Disable NetworkManager-wait-online.service to improve boot time
    run_command("sudo systemctl disable NetworkManager-wait-online.service")
    log_success("NetworkManager-wait-online.service disabled (saves ~15-20s boot time)")


def show_dry_run_summary(platform_name: str, category: str):
    """Show what would be done in dry-run mode."""
    console.print("\n[bold blue]🔍 DRY RUN SUMMARY[/bold blue]")
    console.print(f"Platform: {platform_name}")
    console.print(f"Category: {category}")

    config = load_config()
    platform_config = config["platforms"].get(platform_name, {})
    common_terminal_tools = config.get("common_tools", {}).get("terminal", [])

    if not platform_config:
        console.print("[red]No configuration found for this platform[/red]")
        return

    tree = Tree(f"[bold]Packages for {platform_name}[/bold]")

    if category in ["all", "terminal"] and "terminal_tools" in platform_config:
        terminal_branch = tree.add("[bold green]Terminal Tools[/bold green]")
        for package_manager, packages in platform_config["terminal_tools"].items():
            # Show the same merged packages that would actually be installed
            if package_manager in ["homebrew", "dnf", "pkg"]:
                merged_packages = list(common_terminal_tools) + list(packages)
                mapped_packages = apply_package_mapping(merged_packages, platform_name)
                pkg_branch = terminal_branch.add(
                    f"{package_manager} ({len(mapped_packages)} packages)"
                )
                pkg_branch.add(f"[dim]Common tools: {len(common_terminal_tools)}[/dim]")
                pkg_branch.add(f"[dim]Platform-specific: {len(packages)}[/dim]")
                # Show first few packages
                for package in mapped_packages[:5]:
                    pkg_branch.add(f"[cyan]{package}[/cyan]")
                if len(mapped_packages) > 5:
                    pkg_branch.add(
                        f"[dim]... and {len(mapped_packages) - 5} more[/dim]"
                    )
            elif package_manager == "apt":
                mapped_packages = apply_package_mapping(packages, platform_name)
                pkg_branch = terminal_branch.add(
                    f"{package_manager} ({len(mapped_packages)} packages)"
                )
                pkg_branch.add("[dim]System packages only[/dim]")
                for package in mapped_packages[:5]:
                    pkg_branch.add(f"[cyan]{package}[/cyan]")
                if len(mapped_packages) > 5:
                    pkg_branch.add(
                        f"[dim]... and {len(mapped_packages) - 5} more[/dim]"
                    )

    if category in ["all", "gui"] and "gui_apps" in platform_config:
        gui_branch = tree.add("[bold magenta]GUI Applications[/bold magenta]")
        for package_manager, packages in platform_config["gui_apps"].items():
            if packages:
                app_branch = gui_branch.add(
                    f"{package_manager} ({len(packages)} packages)"
                )
                for package in packages[:5]:  # Show first 5 packages
                    app_branch.add(f"[cyan]{package}[/cyan]")
                if len(packages) > 5:
                    app_branch.add(f"[dim]... and {len(packages) - 5} more[/dim]")

    console.print(tree)


def ensure_working_directory():
    """Ensure we're running from the repository root directory."""
    current_dir = Path.cwd()

    # Check if we're already in a valid repository structure
    if (current_dir / "unix" / "setup.py").exists() or (
        current_dir.parent / "unix" / "setup.py"
    ).exists():
        # We're in a valid repository structure, adjust if needed
        if (
            current_dir.parent / "unix" / "setup.py"
        ).exists() and current_dir.name == "unix":
            # We're in the unix subdirectory, go up one level
            if not setup_config.dry_run:
                os.chdir(current_dir.parent)
            return
        # We're already in the right place
        return

    # Try the expected location for local development
    expected_configs_dir = Path.home() / "Dev" / ".configs"
    if (
        expected_configs_dir.exists()
        and (expected_configs_dir / "unix" / "setup.py").exists()
    ):
        log_info(f"Changing working directory to: {expected_configs_dir}")
        if not setup_config.dry_run:
            os.chdir(expected_configs_dir)
        return

    # If we can't find the repository structure, it's an error
    log_error("Cannot find repository structure with unix/setup.py")
    log_error(f"Current directory: {current_dir}")
    log_error(
        "Please run from repository root or ensure the repository is properly set up"
    )
    sys.exit(1)


def ensure_repository():
    """Ensure the configs repository is cloned with submodules."""
    current_dir = Path.cwd()

    # Check if we're already in a repository (like in CI)
    if (current_dir / "unix" / "setup.py").exists() or (current_dir / ".git").exists():
        log_success("Repository already exists")
        return

    # Try to clone to the expected location
    repo_url = "https://github.com/pixincreate/configs.git"
    configs_dir = Path.home() / "Dev" / ".configs"

    if not configs_dir.exists():
        log_info("Repository not found. Cloning with submodules...", "📥")
        parent_dir = configs_dir.parent

        if not setup_config.dry_run:
            parent_dir.mkdir(parents=True, exist_ok=True)

        clone_cmd = f"git clone --recurse-submodules {repo_url} {configs_dir}"
        run_command(clone_cmd)
        log_success("Repository cloned successfully!")

        # Change to the newly cloned directory
        if not setup_config.dry_run:
            os.chdir(configs_dir)
    else:
        log_success("Repository already exists")


def main():
    """Main entry point for the setup script."""
    parser = argparse.ArgumentParser(
        description="Unified Setup Script for Multi-Platform Development Environment",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  unix/setup.py --full-setup                      # Complete setup
  unix/setup.py install --category terminal       # Install terminal tools only
  unix/setup.py install --category gui            # Install GUI apps only
  unix/setup.py git-config                        # Setup Git configuration only
  unix/setup.py stow --package zsh                # Stow specific package
  unix/setup.py stow                              # Stow all packages
  unix/setup.py fonts                             # Install fonts only
  unix/setup.py --dry-run install                 # Preview what would be installed

Run from repository root (~/Dev/.configs/) or script will auto-clone if missing.
        """,
    )

    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be done without executing",
    )
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose output")
    parser.add_argument(
        "--full-setup", action="store_true", help="Run complete setup for the platform"
    )

    subparsers = parser.add_subparsers(dest="command", help="Available commands")

    # Install command
    install_parser = subparsers.add_parser("install", help="Install packages")
    install_parser.add_argument(
        "--category",
        choices=["all", "terminal", "gui"],
        default="all",
        help="Category of packages to install",
    )

    # Git config command
    subparsers.add_parser("git-config", help="Setup Git configuration and SSH keys")

    # Stow command
    stow_parser = subparsers.add_parser("stow", help="Manage dotfiles with Stow")
    stow_parser.add_argument("--package", help="Specific package to stow")

    # Fonts command
    subparsers.add_parser("fonts", help="Install fonts")

    # ZSH command
    subparsers.add_parser("zsh", help="Setup ZSH configuration")

    # Services command
    subparsers.add_parser("services", help="Setup system services (Fedora only)")

    args = parser.parse_args()

    # Configure setup_config with parsed arguments
    setup_config.dry_run = args.dry_run
    setup_config.verbose = args.verbose

    # Detect platform
    platform_name = detect_platform()

    if setup_config.dry_run:
        log_info("🔍 DRY RUN MODE - No changes will be made", "🧪")

    log_info(f"Detected platform: {platform_name}", "🎯")

    # Show help if no command provided
    if not args.command and not args.full_setup:
        parser.print_help()
        return

    try:
        # Ensure repository exists first
        ensure_repository()

        # Ensure we're in the correct working directory
        ensure_working_directory()

        if args.full_setup:
            # Create necessary directories for full setup
            create_directories()
            log_info("🚀 Starting full setup...", "🎪")

            # For Fedora, run system setup first
            if platform_name == "fedora":
                setup_fedora_system()

            # Install packages
            if setup_config.dry_run:
                show_dry_run_summary(platform_name, "all")
            else:
                install_packages_for_platform(platform_name, "all")

            # Setup Git configuration
            setup_git_config()

            # Install fonts and setup directories
            install_fonts()

            # Update ZSH configuration
            update_zshrc()
            create_platform_specific_additionals()

            # Stow dotfiles
            stow_dotfiles()

            # Configure KDE wallpaper directory (if KDE is available)
            if platform_name in [
                "fedora",
                "debian",
            ]:  # Linux platforms where KDE might be used
                setup_kde_wallpaper_config()

            # Setup services (Fedora only)
            if platform_name == "fedora":
                setup_services()

            log_success("🎉 Full setup completed!")

            if platform_name == "fedora":
                log_info(
                    "Please reboot your system to ensure all changes take effect.", "🔄"
                )

        elif args.command == "install":
            if setup_config.dry_run:
                show_dry_run_summary(platform_name, args.category)
            else:
                # For Fedora, setup repositories first if installing packages
                if platform_name == "fedora" and args.category in ["all", "terminal"]:
                    setup_fedora_repositories()

                install_packages_for_platform(platform_name, args.category)

        elif args.command == "git-config":
            setup_git_config()

        elif args.command == "stow":
            stow_dotfiles(args.package)

        elif args.command == "fonts":
            install_fonts()

        elif args.command == "zsh":
            update_zshrc()
            create_platform_specific_additionals()

        elif args.command == "services":
            if platform_name == "fedora":
                setup_services()
            else:
                log_warning("Services setup is only available on Fedora")

    except KeyboardInterrupt:
        log_warning("Setup interrupted by user")
        sys.exit(1)
    except Exception as e:
        log_error(f"Setup failed: {e}")
        if setup_config.verbose:
            import traceback

            console.print(traceback.format_exc())
        sys.exit(1)


if __name__ == "__main__":
    main()
