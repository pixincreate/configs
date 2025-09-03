#!/usr/bin/env python3
"""
Unified Setup Script for Multi-Platform Development Environment
Replaces fedora/setup-fedora.sh and unix/setup.sh with a clean Python implementation.
"""

import argparse
import hashlib
import json
import logging
import os
import platform
import shutil
import subprocess
import sys
import urllib.request
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional

import toml
from rich.console import Console
from rich.prompt import Confirm, Prompt
from rich.tree import Tree

console = Console()


def expand_path(path_str: str) -> Path:
    """Expand ~ and convert string path to Path object."""
    return Path(path_str.replace("~", str(Path.home())))


def get_path(key: str) -> Path:
    """Get a path from config.toml and expand it."""
    config = load_config()
    path_str = config["directories"][key]
    return expand_path(path_str)


def setup_file_logger():
    """Setup file logger for the setup script."""
    # Load config first to get log file path
    config_path = Path(__file__).resolve().parent / "config.toml"
    with open(config_path, "r") as f:
        temp_config = toml.load(f)

    log_file = expand_path(temp_config["logging"]["log_file"])

    # Create log directory if it doesn't exist
    log_file.parent.mkdir(parents=True, exist_ok=True)

    # Configure logging
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s - %(levelname)s - %(message)s",
        handlers=[
            logging.FileHandler(log_file, mode="a"),  # Append mode
            logging.StreamHandler(),  # Also log to console for debugging
        ],
    )

    logger = logging.getLogger(__name__)
    logger.info("=" * 60)
    logger.info("Setup script started")
    logger.info("=" * 60)

    return logger


# Initialize file logger
file_logger = setup_file_logger()


@dataclass
class SetupConfig:
    """Configuration container for setup operations."""

    dry_run: bool = False
    verbose: bool = False
    auto_confirm: bool = False
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
    file_logger.info(f"{message}")


def log_success(message: str, emoji: str = "✅"):
    """Log success message."""
    setup_config._log_success(message, emoji)
    file_logger.info(f"SUCCESS: {message}")


def log_warning(message: str, emoji: str = "⚠️"):
    """Log warning message."""
    setup_config._log_warning(message, emoji)
    file_logger.warning(f"{message}")


def log_error(message: str, emoji: str = "❌"):
    """Log error message."""
    setup_config._log_error(message, emoji)
    file_logger.error(f"{message}")


def confirm_action(message: str, default: bool = False) -> bool:
    """Ask for confirmation with auto-confirm support."""
    if setup_config.auto_confirm:
        log_info(f"Auto-confirming: {message}")
        return True
    return Confirm.ask(message, default=default)


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

    # Use paths from config.toml
    directories = [
        get_path("config_dir"),
        get_path("ssh_dir"),
        get_path("zsh_dir"),
        get_path("zgenom_dir"),
        get_path("wallpapers_dir"),
        get_path("screenshots_dir"),
        get_path("local_fonts_dir"),
        get_path("local_bin_dir"),
    ]

    # Add .rish directory only for Android
    platform_name = detect_platform()
    if platform_name == "android":
        directories.append(get_path("rish_dir"))

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
            # Build DNF COPR command with appropriate flags
            dnf_flags = "-y"
            if setup_config.auto_confirm:
                dnf_flags += " --assumeyes"
            run_command(f"sudo dnf copr enable {dnf_flags} {repo}")

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
            # Build DNF command with appropriate flags
            dnf_flags = "-y"
            if setup_config.auto_confirm:
                dnf_flags += " --assumeyes"
            rpm_fusion_cmd = (
                f"sudo dnf install {dnf_flags} "
                "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm "
                "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
            )
            run_command(rpm_fusion_cmd)
    except Exception:
        log_warning(
            "Could not check RPM Fusion installation status, attempting to install..."
        )
        # Build DNF command with appropriate flags
        dnf_flags = "-y"
        if setup_config.auto_confirm:
            dnf_flags += " --assumeyes"
        rpm_fusion_cmd = (
            f"sudo dnf install {dnf_flags} "
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
            # Build DNF command with appropriate flags
            dnf_flags = "-y"
            if setup_config.auto_confirm:
                dnf_flags += " --assumeyes"
            terra_cmd = (
                f"sudo dnf install {dnf_flags} "
                "--nogpgcheck --repofrompath 'terra,https://repos.fyralabs.com/terra$releasever' terra-release"
            )
            run_command(terra_cmd)
    except Exception:
        log_warning(
            "Could not check Terra installation status, attempting to install..."
        )
        # Build DNF command with appropriate flags
        dnf_flags = "-y"
        if setup_config.auto_confirm:
            dnf_flags += " --assumeyes"
        terra_cmd = (
            f"sudo dnf install {dnf_flags} "
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

    setup_rust()


def setup_rust():
    """Install Rust with Rustup"""

    # ToDo: Fix this
    if shutil.which("rustup"):
        log_info("Rust is already installed, updating...")
        run_command("rustup update")
    else:
        try:
            log_info("Installing Rust with rustup-init...")

            run_command("rustup-init -y --default-toolchain stable")
            run_command("rustup toolchain install nightly")
            run_command("source ~/.cargo/env")

            install_rust_tools()
        except subprocess.CalledProcessError:
            log_warning("Failed to install RustLang")


def install_rust_tools():
    """Installs rust tools"""

    log_info("Installing Rust tools with cargo...")

    config = load_config()
    tools = config["rust"].get("rust_tools", {})

    if not tools:
        log_error(f"No configuration found for rust tools: {tools}")
        return

    log_info(f"Installing {len(tools)} tools with Cargo...")

    failed_tools = []

    for tool in tools:
        try:
            log_info(f"Installing tool: {tool}")
            run_command(f"cargo install {tool}")

        except subprocess.CalledProcessError:
            log_warning(f"Failed to install: {tool}")
            failed_tools.append(tool)
            continue

    if failed_tools:
        log_warning(
            f"Failed to install {len(failed_tools)} tools: {', '.join(failed_tools)}"
        )

    try:
        if confirm_action(
            "🦀 Do you want to install diesel_cli with PostgreSQL support?"
        ):
            log_info("Installing diesel_cli with PostgreSQL support...")
            run_command(
                "cargo install diesel_cli --no-default-features --features postgres"
            )
    except subprocess.CalledProcessError:
        log_warning("Failed to install Diesel CLI")


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
    if not packages:
        return

    log_info(f"Installing {len(packages)} packages with DNF...")

    # Build DNF command with appropriate flags
    dnf_flags = "-y"
    if setup_config.auto_confirm:
        dnf_flags += " --assumeyes"

    failed_packages = []

    for package in packages:
        try:
            log_info(f"Installing package: {package}")
            run_command(f"sudo dnf install {dnf_flags} {package}")
        except subprocess.CalledProcessError:
            log_warning(f"Failed to install package: {package}")
            failed_packages.append(package)
            continue

    if failed_packages:
        log_warning(
            f"Failed to install {len(failed_packages)} packages: {', '.join(failed_packages)}"
        )


def install_with_apt(packages: List[str]):
    """Install packages using APT."""
    run_command("sudo apt-get update")
    packages_str = " ".join(packages)

    # Build APT command with appropriate flags
    apt_flags = "-y"
    if setup_config.auto_confirm:
        apt_flags += " --assume-yes"

    run_command(f"sudo apt-get install {apt_flags} {packages_str}")


def install_with_pkg(packages: List[str]):
    """Install packages using pkg (Termux)."""
    packages_str = " ".join(packages)

    # Build pkg command with appropriate flags
    pkg_flags = "-y"

    run_command(f"pkg install {pkg_flags} {packages_str}")


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


def backup_existing_gitconfig():
    """Backup existing .gitconfig file if it contains user configuration."""
    gitconfig_path = Path.home() / ".gitconfig"

    if not gitconfig_path.exists():
        log_info("No existing .gitconfig found")
        return

    if setup_config.dry_run:
        log_warning("DRY RUN: Would backup existing .gitconfig")
        return

    try:
        # Read existing .gitconfig to check if it has user configuration
        with open(gitconfig_path, "r") as f:
            content = f.read()

        # Check if it contains user configuration
        if (
            "[user]" in content.lower()
            or "user.name" in content.lower()
            or "user.email" in content.lower()
        ):
            backup_path = gitconfig_path.with_suffix(".gitconfig.backup")
            shutil.copy2(gitconfig_path, backup_path)
            log_success(
                f"Backed up existing .gitconfig with user config to: {backup_path}"
            )
        else:
            log_info("Existing .gitconfig has no user configuration, no backup needed")

    except Exception as e:
        log_warning(f"Failed to backup .gitconfig: {e}")


def setup_git_config():
    """Setup Git configuration with SSH keys."""
    log_info("Setting up Git configuration...", "🔧")

    config = load_config()
    git_config = config.get("git", {})

    # Backup existing .gitconfig if it has user configuration
    backup_existing_gitconfig()

    # Get current git values
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

    # Use config.toml defaults if git config is not set and defaults exist
    if not git_name and "default_name" in git_config:
        git_name = git_config["default_name"]
        log_info(f"Using git name from config.toml: {git_name}")

    if not git_email and "default_email" in git_config:
        git_email = git_config["default_email"]
        log_info(f"Using git email from config.toml: {git_email}")

    # Only prompt if still missing values
    if not git_name:
        git_name = Prompt.ask(
            "👤 Enter your Git user.name", default=git_config.get("default_name", "")
        )
    else:
        log_success(f"Git user.name already configured: {git_name}")

    if not git_email:
        git_email = Prompt.ask(
            "📧 Enter your Git user.email", default=git_config.get("default_email", "")
        )
    else:
        log_success(f"Git user.email already configured: {git_email}")

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
    gitconfig_local = get_path("gitconfig_local")
    signing_key = get_path("ssh_signing_key")

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


def setup_ssh_permissions():
    """Set proper SSH permissions for security."""
    log_info("Setting SSH permissions...", "🔒")

    ssh_dir = get_path("ssh_dir")

    if not ssh_dir.exists():
        log_info("SSH directory doesn't exist, skipping permissions setup")
        return

    if setup_config.dry_run:
        log_warning("DRY RUN: Would set SSH permissions")
        return

    try:
        # Set SSH directory permissions (700) - required for SSH to work
        ssh_dir.chmod(0o700)
        log_success(f"Set SSH directory permissions: {ssh_dir}")

        # Set permissions for all SSH files
        for ssh_file in ssh_dir.iterdir():
            if ssh_file.is_file():
                if ssh_file.name == "config":
                    # SSH config file: 600 (rw-------)
                    ssh_file.chmod(0o600)
                    log_success(f"Set config permissions: {ssh_file.name}")
                elif ssh_file.name == "known_hosts":
                    # Known hosts file: 644 (rw-r--r--)
                    ssh_file.chmod(0o644)
                    log_success(f"Set known_hosts permissions: {ssh_file.name}")
                elif ssh_file.suffix == ".pub":
                    # Public keys: 644 (rw-r--r--)
                    ssh_file.chmod(0o644)
                    log_success(f"Set public key permissions: {ssh_file.name}")
                elif ssh_file.name.startswith("id_") and ssh_file.suffix == "":
                    # Private keys: 600 (rw-------)
                    ssh_file.chmod(0o600)
                    log_success(f"Set private key permissions: {ssh_file.name}")
                elif ssh_file.name.startswith("id_") and ssh_file.suffix in [
                    ".pem",
                    ".key",
                ]:
                    # Other private key formats: 600 (rw-------)
                    ssh_file.chmod(0o600)
                    log_success(f"Set private key permissions: {ssh_file.name}")
                else:
                    # Default for other SSH files: 600 (rw-------)
                    ssh_file.chmod(0o600)
                    log_success(f"Set default permissions: {ssh_file.name}")

        log_success("All SSH permissions set correctly")

    except Exception as e:
        log_warning(f"Failed to set SSH permissions: {e}")


def setup_ssh_key():
    """Setup SSH key if not present."""
    ssh_key = get_path("ssh_key")
    ssh_dir = get_path("ssh_dir")

    if ssh_key.exists():
        log_success(f"SSH key already exists at {ssh_key}")
    else:
        log_info("SSH key not found. Generating...", "🔐")
        email = run_command(
            "git config --global user.email", capture_output=True
        ).stdout.strip()

        if not setup_config.dry_run:
            ssh_dir.mkdir(exist_ok=True)

        run_command(f'ssh-keygen -t ed25519 -C "{email}" -f {ssh_key} -N ""')
        log_success("SSH key generated")

    # Set proper SSH permissions for security
    setup_ssh_permissions()

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
    if confirm_action("🪪 Do you want to upload this key to GitHub automatically?"):
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

    fonts_source = get_path("fonts_source")

    # Get platform-specific font target directory
    config = load_config()
    platform_name = detect_platform()
    fonts_target_config = config["directories"]["fonts_target"]
    fonts_target_path = fonts_target_config.get(
        platform_name, fonts_target_config.get("fedora")
    )
    fonts_target = expand_path(fonts_target_path)

    if not fonts_source.exists():
        log_warning(f"Fonts source directory not found: {fonts_source}")
        return

    if not setup_config.dry_run:
        fonts_target.mkdir(parents=True, exist_ok=True)

    font_files = list(fonts_source.glob("*.*"))

    if not font_files:
        log_warning("No font files found")
        return

    log_info(f"Installing fonts to platform-specific directory: {fonts_target}")

    for font_file in font_files:
        if font_file.suffix.lower() in [".ttf", ".otf", ".woff", ".woff2"]:
            target_file = fonts_target / font_file.name
            if not setup_config.dry_run:
                shutil.copy2(font_file, target_file)
            log_success(f"Installed font: {font_file.name}")

    # Refresh font cache (only on Linux systems)
    if command_exists("fc-cache") and platform_name in ["fedora", "debian"]:
        run_command("fc-cache -fv")

    log_success(f"Installed {len(font_files)} fonts to {fonts_target}")


def change_default_shell():
    """Change the default shell to zsh."""
    log_info("Setting zsh as default shell...", "🐚")

    # Check if zsh is installed
    if not command_exists("zsh"):
        log_error("zsh is not installed. Cannot set as default shell.")
        return

    # Get the path to zsh
    zsh_path = shutil.which("zsh")
    if not zsh_path:
        log_error("Could not find zsh executable path")
        return

    # Get current shell
    current_shell = os.environ.get("SHELL", "")

    if current_shell == zsh_path:
        log_success(f"zsh is already the default shell: {zsh_path}")
        return

    # Change default shell
    log_info(f"Changing default shell to: {zsh_path}")
    if not setup_config.dry_run:
        try:
            run_command(f"chsh -s {zsh_path}")
            log_success("Default shell changed to zsh")
            log_info("Please log out and back in for the shell change to take effect")
        except subprocess.CalledProcessError as e:
            log_warning(f"Failed to change shell: {e}")
            log_info(
                f"You can manually change your shell by running: chsh -s {zsh_path}"
            )
    else:
        log_warning(f"DRY RUN: Would change default shell to: {zsh_path}")


def update_zshrc():
    """Update .zshrc file by downloading latest and restowing via stow."""
    log_info("Checking for .zshrc updates...", "🐚")

    source_zshrc = get_path("zsh_source")
    zshrc_path = get_path("zshrc_file")

    if not source_zshrc.exists():
        log_warning(f"Source .zshrc not found: {source_zshrc}")
        return

    # Check if an update is available from the remote repository
    log_info("Checking for .zshrc updates from remote repository...")

    # Define the remote URL for the .zshrc file
    remote_zshrc_url = (
        "https://github.com/pixincreate/configs/raw/main/home/zsh/.zsh/.zshrc"
    )

    if not setup_config.dry_run:
        try:
            # Download the latest .zshrc from remote
            log_info("Downloading latest .zshrc from remote...")

            import urllib.request

            temp_file = source_zshrc.with_suffix(".zshrc.temp")

            urllib.request.urlretrieve(remote_zshrc_url, temp_file)

            # Calculate checksums to check if update is needed
            def calculate_checksum(file_path: Path) -> str:
                if not file_path.exists():
                    return ""
                with open(file_path, "rb") as f:
                    return hashlib.sha1(f.read()).hexdigest()

            current_checksum = calculate_checksum(source_zshrc)
            new_checksum = calculate_checksum(temp_file)

            if current_checksum != new_checksum:
                if confirm_action(
                    "📝 .zshrc has updates available. Do you want to update it?"
                ):
                    # Backup current source file
                    backup_path = source_zshrc.with_suffix(".zshrc.bak")
                    if source_zshrc.exists():
                        shutil.copy2(source_zshrc, backup_path)

                    # Replace source file with updated version
                    shutil.move(temp_file, source_zshrc)
                    log_success("Source .zshrc updated successfully!")

                    # Restow the zsh package to apply changes
                    log_info("Restowing zsh package to apply changes...")
                    stow_dotfiles("zsh")
                    log_success(".zshrc updated and restowed successfully!")
                else:
                    # Clean up temp file if user skips update
                    temp_file.unlink(missing_ok=True)
                    log_info("Skipped .zshrc update")
            else:
                # Clean up temp file if no updates
                temp_file.unlink(missing_ok=True)
                log_success(".zshrc is up-to-date!")

        except Exception as e:
            log_warning(f"Failed to check for .zshrc updates: {e}")
            log_info("Using existing .zshrc file")
    else:
        log_warning("DRY RUN: Would check for .zshrc updates and restow if needed")

    # If no existing .zshrc, stow it for the first time
    if not zshrc_path.exists():
        log_info("No existing .zshrc found, stowing zsh package...")
        stow_dotfiles("zsh")
        log_success("ZSH package stowed successfully!")


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

alias zed=zed-preview
"""
    elif platform_name == "fedora":
        content += """
# Fedora specific configurations
export SYS_HEALTH="${HOME}/Dev/.configs/unix/fedora/health-check.sh"
alias cleanup="sudo dnf autoremove && flatpak uninstall --unused"
alias secure_boot_retrigger='sudo kmodgenca -a && sudo mokutil --import /etc/pki/akmods/certs/public_key.der'
"""
    elif platform_name == "debian":
        content += """
# Debian specific configurations
export LDFLAGS="-L/$(brew --prefix)/opt/binutils/lib"
export CPPFLAGS="-I/$(brew --prefix)/opt/binutils/include"

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

    ssh_packages_stowed = []

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

            # Track SSH-related packages
            if pkg in ["ssh", "git"] or "ssh" in pkg.lower():
                ssh_packages_stowed.append(pkg)

        except subprocess.CalledProcessError:
            if confirm_action(
                f"❓ Stow conflict detected for {pkg}. Override existing files?"
            ):
                run_command(
                    f"stow --no-folding --restow --adopt --dir={stow_dir} --target={Path.home()} {pkg}"
                )
                log_success(f"Successfully stowed with override: {pkg}")

                # Track SSH-related packages even when overridden
                if pkg in ["ssh", "git"] or "ssh" in pkg.lower():
                    ssh_packages_stowed.append(pkg)
            else:
                log_warning(f"Skipped stowing: {pkg}")

    # Set SSH permissions after stowing SSH-related packages
    if ssh_packages_stowed:
        log_info(f"SSH-related packages were stowed: {', '.join(ssh_packages_stowed)}")
        setup_ssh_permissions()


def setup_services():
    """Setup and enable system services."""
    log_info("Setting up system services...", "⚙️")

    platform_name = detect_platform()

    if platform_name == "fedora":
        # PostgreSQL setup
        if command_exists("postgresql-setup"):
            # Check if PostgreSQL is already initialized
            result = run_command(
                "sudo test -f /var/lib/pgsql/data/PG_VERSION",
                capture_output=True,
                check=False,
            )
            if result.returncode == 0:
                log_success("PostgreSQL database already initialized")
            else:
                log_info("Initializing PostgreSQL database...")
                try:
                    pg_config_path = "/var/lib/pgsql/data/pg_hba.conf"

                    run_command("sudo postgresql-setup --initdb")
                    run_command(
                        f"sudo sed -i r's/(host.*all.*all.*127.0.0.1/32.*)ident/\\1md5/' {pg_config_path}"
                    )
                    run_command(
                        f"sudo sed -i r's/(host.*all.*all.*::1/128.*)ident/\\1md5/' {pg_config_path}"
                    )

                except subprocess.CalledProcessError as e:
                    if "is not empty" in str(e) or "already exists" in str(e):
                        log_success("PostgreSQL database already initialized")
                    else:
                        raise

            # Enable and start PostgreSQL service
            run_command("sudo systemctl enable postgresql.service")

            # Check if service is already running
            try:
                result = run_command(
                    "sudo systemctl is-active postgresql.service",
                    capture_output=True,
                    check=False,
                )
                if result.stdout.strip() == "active":
                    log_success("PostgreSQL service is already running")
                else:
                    run_command("sudo systemctl start postgresql.service")
                    log_success("PostgreSQL service started")
            except Exception:
                run_command("sudo systemctl start postgresql.service")
                log_success("PostgreSQL service started")

        # Redis setup
        if command_exists("redis-server"):
            run_command("sudo systemctl enable redis.service")

            # Check if Redis service is already running
            try:
                result = run_command(
                    "sudo systemctl is-active redis.service",
                    capture_output=True,
                    check=False,
                )
                if result.stdout.strip() == "active":
                    log_success("Redis service is already running")
                else:
                    run_command("sudo systemctl start redis.service")
                    log_success("Redis service started")
            except Exception:
                run_command("sudo systemctl start redis.service")
                log_success("Redis service started")

        # Docker setup
        if command_exists("docker"):
            run_command("sudo systemctl enable docker.service")

            # Check if Docker service is already running
            try:
                result = run_command(
                    "sudo systemctl is-active docker.service",
                    capture_output=True,
                    check=False,
                )
                if result.stdout.strip() == "active":
                    log_success("Docker service is already running")
                else:
                    run_command("sudo systemctl start docker.service")
                    log_success("Docker service started")
            except Exception:
                run_command("sudo systemctl start docker.service")
                log_success("Docker service started")

            # Check if user is already in docker group
            try:
                current_user = os.getenv("USER")
                result = run_command(
                    f"groups {current_user}", capture_output=True, check=False
                )
                if "docker" in result.stdout:
                    log_success(f"User {current_user} is already in docker group")
                else:
                    run_command(f"sudo usermod -aG docker {current_user}")
                    log_info(
                        "Added user to docker group. Please log out and back in for changes to take effect."
                    )
            except Exception:
                run_command(f"sudo usermod -aG docker {os.getenv('USER')}")
                log_info(
                    "Added user to docker group. Please log out and back in for changes to take effect."
                )


def remove_bloatware():
    """Remove bloatware packages from Fedora KDE installation."""
    log_info("Removing bloatware packages...", "🗑️")

    config = load_config()
    bloatware_config = (
        config.get("platforms", {}).get("fedora", {}).get("bloatware_removal", {})
    )

    if not bloatware_config:
        log_warning("No bloatware removal configuration found")
        return

    # Build DNF command with appropriate flags
    dnf_flags = "-y"
    if setup_config.auto_confirm:
        dnf_flags += " --assumeyes"

    removed_packages = []
    failed_packages = []

    # Remove KDE packages
    kde_packages = bloatware_config.get("kde_packages", [])
    if kde_packages:
        log_info(f"Removing KDE bloatware packages: {len(kde_packages)} packages")
        for package in kde_packages:
            try:
                result = run_command(
                    f"rpm -q {package}", capture_output=True, check=False
                )
                if result.returncode == 0:
                    run_command(f"sudo dnf remove {dnf_flags} {package}")
                    removed_packages.append(package)
                    log_success(f"Removed: {package}")
                else:
                    log_info(f"Not installed: {package}")
            except subprocess.CalledProcessError:
                log_warning(f"Failed to remove: {package}")
                failed_packages.append(package)

    # Remove LibreOffice packages
    libreoffice_packages = bloatware_config.get("libreoffice_packages", [])
    if libreoffice_packages:
        log_info(f"Removing LibreOffice packages: {len(libreoffice_packages)} packages")
        for package in libreoffice_packages:
            try:
                result = run_command(
                    f"rpm -q {package}", capture_output=True, check=False
                )
                if result.returncode == 0:
                    run_command(f"sudo dnf remove {dnf_flags} {package}")
                    removed_packages.append(package)
                    log_success(f"Removed: {package}")
                else:
                    log_info(f"Not installed: {package}")
            except subprocess.CalledProcessError:
                log_warning(f"Failed to remove: {package}")
                failed_packages.append(package)

    # Remove PIM packages
    pim_packages = bloatware_config.get("pim_packages", [])
    if pim_packages:
        log_info(f"Removing PIM packages: {len(pim_packages)} packages")
        for package in pim_packages:
            try:
                result = run_command(
                    f"rpm -q {package}", capture_output=True, check=False
                )
                if result.returncode == 0:
                    run_command(f"sudo dnf remove {dnf_flags} {package}")
                    removed_packages.append(package)
                    log_success(f"Removed: {package}")
                else:
                    log_info(f"Not installed: {package}")
            except subprocess.CalledProcessError:
                log_warning(f"Failed to remove: {package}")
                failed_packages.append(package)

    # Clean up orphaned packages
    log_info("Cleaning up orphaned packages...")
    run_command(f"sudo dnf autoremove {dnf_flags}")

    # Summary
    if removed_packages:
        log_success(f"Successfully removed {len(removed_packages)} bloatware packages")
    if failed_packages:
        log_warning(
            f"Failed to remove {len(failed_packages)} packages: {', '.join(failed_packages)}"
        )

    log_success("Bloatware removal completed")


def setup_fedora_system():
    """Run Fedora-specific system setup."""
    log_info("Running Fedora system setup...", "🎩")

    # Build DNF command with appropriate flags
    dnf_flags = "-y"
    if setup_config.auto_confirm:
        dnf_flags += " --assumeyes"

    # Update system first
    run_command(f"sudo dnf update {dnf_flags} --refresh")

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

    # Setup NVIDIA drivers (if hardware detected)
    setup_nvidia_drivers()

    # Setup ASUS system optimizations (if ASUS hardware detected)
    setup_asus_system()

    # Remove bloatware packages at the end
    remove_bloatware()

    # Setup NextDNS
    setup_nextdns()

    # Setup secure boot
    setup_secure_boot()


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
        # Build DNF command with appropriate flags
        dnf_flags = "-y"
        if setup_config.auto_confirm:
            dnf_flags += " --assumeyes"
        run_command(f"sudo dnf install {dnf_flags} fwupd")

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
            if confirm_action("🔄 Apply firmware updates?"):
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
    # Build DNF command with appropriate flags
    dnf_flags = "-y"
    if setup_config.auto_confirm:
        dnf_flags += " --assumeyes"
    run_command(f"sudo dnf install {dnf_flags} fuse")
    log_success("FUSE installed for AppImage support")


def setup_multimedia():
    """Setup multimedia support based on official Fedora recommendations."""
    log_info("Setting up multimedia support...", "🎵")

    # Build DNF command with appropriate flags
    dnf_flags = "-y"
    if setup_config.auto_confirm:
        dnf_flags += " --assumeyes"

    # 1. Install multimedia group (official Fedora recommendation)
    log_info("Installing multimedia group...")
    run_command(f"sudo dnf group install {dnf_flags} multimedia")

    # 2. Swap to full FFmpeg (RPM Fusion version with all codecs)
    log_info("Swapping to full FFmpeg...")
    run_command(f"sudo dnf swap {dnf_flags} ffmpeg-free ffmpeg --allowerasing")

    # 3. Update multimedia group and install sound-and-video
    log_info("Updating multimedia packages...")
    run_command(
        f'sudo dnf group upgrade {dnf_flags} multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin'
    )

    # 4. Install essential multimedia libraries
    log_info("Installing multimedia libraries...")
    run_command(f"sudo dnf install {dnf_flags} ffmpeg-libs libva libva-utils")

    # 5. Hardware acceleration setup
    setup_hardware_acceleration()

    # 6. Install additional codecs and plugins
    log_info("Installing additional codecs...")
    run_command(
        f"sudo dnf install {dnf_flags} gstreamer1-plugins-{{bad-*,good-*,base}} gstreamer1-plugin-openh264 gstreamer1-libav"
    )
    run_command(f"sudo dnf install {dnf_flags} lame* --exclude=lame-devel")

    # 7. Enable OpenH264 for browsers
    log_info("Setting up OpenH264 for browsers...")
    run_command("sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1")
    run_command(
        f"sudo dnf install {dnf_flags} openh264 gstreamer1-plugin-openh264 mozilla-openh264"
    )

    log_success("Multimedia setup completed")


def setup_hardware_acceleration():
    """Setup hardware acceleration based on detected hardware."""
    log_info("Setting up hardware acceleration...", "🚀")

    # Detect Intel graphics
    try:
        run_command("lspci | grep -i intel.*graphics", capture_output=True)
        log_info("Intel graphics detected, installing Intel media drivers...")
        # Build DNF command with appropriate flags
        dnf_flags = "-y"
        if setup_config.auto_confirm:
            dnf_flags += " --assumeyes"
        run_command(
            f"sudo dnf swap {dnf_flags} libva-intel-media-driver intel-media-driver --allowerasing"
        )
        # Note: libva-intel-driver is legacy and usually not needed with intel-media-driver
        log_success("Intel hardware acceleration configured")
    except subprocess.CalledProcessError:
        log_info("No Intel graphics detected, skipping Intel drivers")

    # Detect AMD graphics
    try:
        run_command("lspci | grep -i amd.*graphics", capture_output=True)
        log_info("AMD graphics detected, installing AMD drivers...")
        # Build DNF command with appropriate flags
        dnf_flags = "-y"
        if setup_config.auto_confirm:
            dnf_flags += " --assumeyes"
        # AMD drivers are usually included in mesa packages
        run_command(f"sudo dnf install {dnf_flags} mesa-va-drivers mesa-vdpau-drivers")
        log_success("AMD hardware acceleration configured")
    except subprocess.CalledProcessError:
        log_info("No AMD graphics detected, skipping AMD drivers")


def setup_nvidia_drivers():
    """Setup NVIDIA drivers and related packages."""
    log_info("Setting up NVIDIA drivers...", "🖥️")

    # Check for NVIDIA hardware first
    try:
        run_command("lspci | grep -i nvidia", capture_output=True)
        log_info("NVIDIA hardware detected, installing drivers...")
    except subprocess.CalledProcessError:
        log_info("No NVIDIA hardware detected, skipping NVIDIA setup")
        return

    # Build DNF command with appropriate flags
    dnf_flags = "-y"
    if setup_config.auto_confirm:
        dnf_flags += " --assumeyes"

    # Install kernel development headers
    run_command(f"sudo dnf install {dnf_flags} kernel-devel")

    # Install NVIDIA drivers and CUDA support
    run_command(f"sudo dnf install {dnf_flags} akmod-nvidia xorg-x11-drv-nvidia-cuda")
    run_command(f"sudo dnf install {dnf_flags} nvidia-settings")

    # Install only x86_64 versions to avoid architecture conflicts
    run_command(f"sudo dnf install {dnf_flags} xorg-x11-drv-nvidia-libs.x86_64")

    # Build NVIDIA kernel modules
    run_command("sudo akmods --force")

    # Enable NVIDIA services
    run_command(
        "sudo systemctl enable nvidia-hibernate.service nvidia-suspend.service nvidia-resume.service nvidia-powerd.service"
    )

    # Handle libva-nvidia-driver separately to avoid conflicts
    try:
        # First remove any existing libva-nvidia-driver packages to avoid conflicts
        run_command(f"sudo dnf remove {dnf_flags} libva-nvidia-driver", check=False)
        log_info("Removed existing libva-nvidia-driver packages")
    except subprocess.CalledProcessError:
        pass  # Package might not be installed, that's fine

    # Install NVIDIA VAAPI driver and tools (x86_64 only)
    run_command(f"sudo dnf install {dnf_flags} libva-nvidia-driver.x86_64 vdpauinfo")

    # Enable NVIDIA modeset
    run_command(
        r"""
sudo tee /etc/modprobe.d/blacklist.conf <<EOF > /dev/null
blacklist nouveau
options nouveau modeset=0
EOF

sudo tee /etc/modprobe.d/nvidia.conf <<EOF > /dev/null
options nvidia-drm modeset=1
options nvidia NVreg_PreserveVideoMemoryAllocations=1
EOF
    """
    )

    log_info("Re-building system components...")
    run_command(
        """
        sudo akmods --force
        sudo dracut --force
    """
    )

    log_success("NVIDIA drivers installed with modeset enabled. Reboot required.")


def setup_asus_system():
    """Setup ASUS system for better driver support."""
    log_info("Setting up ASUS system optimizations...", "🎮")

    # Check for ASUS hardware first
    try:
        run_command(
            "sudo dmidecode -s system-manufacturer | grep -i asus", capture_output=True
        )
        log_info("ASUS system detected, installing ASUS utilities...")
    except subprocess.CalledProcessError:
        log_info("Not an ASUS system, skipping ASUS setup")
        return

    # Install basic ASUS utilities
    # Build DNF command with appropriate flags
    dnf_flags = "-y"
    if setup_config.auto_confirm:
        dnf_flags += " --assumeyes"

    run_command(f"sudo dnf install {dnf_flags} asusctl supergfxctl")
    run_command("sudo systemctl enable supergfxd.service")
    run_command("sudo systemctl start asusd")

    log_info("Setting up toast message for Asus profile changes...")
    run_command(
        r"""
    sudo tee /etc/udev/rules.d/99-asus-profile-toast.rules << 'EOF'
    KERNEL=="platform-profile-*", \
        SUBSYSTEM=="platform-profile", \
        ACTION=="change", \
        RUN+="/bin/bash -c ' \
            DISPLAY=:0 \
            XDG_RUNTIME_DIR=/run/user/1000 \
            /usr/bin/sudo -u $(who | awk \"{print \$1}\" | head -1) \
            /home/$(who | awk \"{print \$1}\" | head -1)/.local/bin/asus-profile-notify.sh \
        '"
    EOF
    """
    )
    run_command("sudo udevadm control --reload-rules")


def setup_secure_boot():
    """Setup secure boot for NVIDIA drivers and other kernel modules."""
    log_info("Setting up Secure Boot support...", "🔐")

    # Ask user if they want to setup secure boot
    if not confirm_action(
        "🔐 Do you want to setup Secure Boot support? (Required for NVIDIA drivers with Secure Boot enabled)"
    ):
        log_info("Skipped Secure Boot setup")
        return

    # Build DNF command with appropriate flags
    dnf_flags = "-y"
    if setup_config.auto_confirm:
        dnf_flags += " --assumeyes"

    # Install required packages for secure boot
    log_info("Installing Secure Boot packages...")
    try:
        run_command(f"sudo dnf install {dnf_flags} kmodtool akmods mokutil openssl")
        log_success("Secure Boot packages installed")
    except subprocess.CalledProcessError as e:
        log_error(f"Failed to install Secure Boot packages: {e}")
        return

    # Generate kernel module certificate
    log_info("Generating kernel module certificate...")
    try:
        run_command("sudo kmodgenca -a")
        log_success("Kernel module certificate generated")
    except subprocess.CalledProcessError as e:
        log_error(f"Failed to generate kernel module certificate: {e}")
        return

    # Import the public key into MOK (Machine Owner Key)
    log_info("Importing public key into MOK (Machine Owner Key)...")
    try:
        run_command("sudo mokutil --import /etc/pki/akmods/certs/public_key.der")
        log_success("Public key imported into MOK")

        console.print(
            "\n[bold yellow]⚠️  IMPORTANT SECURE BOOT SETUP INFORMATION[/bold yellow]"
        )
        console.print("─" * 60)
        console.print(
            "🔐 The public key has been imported into MOK (Machine Owner Key)"
        )
        console.print("🔄 You will need to enroll the key on next boot:")
        console.print("   1. The system will present a MOK management screen")
        console.print("   2. Select 'Enroll MOK'")
        console.print("   3. Select 'Continue'")
        console.print("   4. Enter the password you'll be prompted for")
        console.print("   5. Select 'Reboot'")
        console.print("─" * 60)
        console.print(
            "[bold red]Without enrolling the MOK, NVIDIA drivers will NOT work with Secure Boot![/bold red]"
        )
        console.print()

    except subprocess.CalledProcessError as e:
        log_error(f"Failed to import public key: {e}")
        return

    # Ask user if they want to reboot now
    if confirm_action(
        "🔄 Secure Boot setup completed. Do you want to reboot now to enroll the MOK?"
    ):
        log_info("Rebooting system to enroll MOK...")
        if not setup_config.dry_run:
            run_command("sudo systemctl reboot")
        else:
            log_warning("DRY RUN: Would reboot system")
    else:
        log_warning("Please reboot manually to complete Secure Boot setup")
        log_info("Run 'sudo systemctl reboot' when ready")

    log_success("Secure Boot setup completed")


def setup_nextdns():
    """Setup NextDNS with user input configuration."""
    log_info("Setting up NextDNS...", "🌐")

    if not command_exists("nextdns"):
        log_warning("NextDNS not installed, skipping NextDNS configuration")
        return

    # Check if NextDNS is already installed/configured
    try:
        result = run_command("sudo nextdns status", capture_output=True, check=False)
        if result.returncode == 0 and "running" in result.stdout.lower():
            log_success("NextDNS is already running")
            if not confirm_action("🔄 NextDNS is already configured. Reconfigure?"):
                log_info("Skipped NextDNS reconfiguration")
                return
    except Exception:
        pass

    # Get NextDNS config ID from user
    config_id = Prompt.ask("🌐 Enter your NextDNS config ID")
    if not config_id:
        log_warning("No NextDNS config ID provided, skipping NextDNS setup")
        return

    log_info(f"Configuring NextDNS with config ID: {config_id}")

    # Install NextDNS with specified configuration
    install_cmd = (
        f"sudo nextdns install -config {config_id} "
        "-setup-router=false -report-client-info=true -log-queries=false"
    )

    try:
        run_command(install_cmd)
        log_success("NextDNS installed and configured successfully")

        # Activate NextDNS
        run_command("sudo nextdns activate")
        log_success("NextDNS activated")

        # Show status
        if not setup_config.dry_run:
            result = run_command(
                "sudo nextdns status", capture_output=True, check=False
            )
            if result.returncode == 0:
                log_info("NextDNS status:")
                console.print(result.stdout)

    except subprocess.CalledProcessError as e:
        log_error(f"Failed to configure NextDNS: {e}")
        return

    log_success("NextDNS setup completed")


def optimize_system_performance():
    """Optimize system performance and boot time."""

    log_info("Optimizing system performance...", "⚡")

    # Disable CPU mitigations for better performance
    if confirm_action(
        "🚀 Disable CPU mitigations for better performance? (Less secure but faster)"
    ):
        run_command('sudo grubby --update-kernel=ALL --args="mitigations=off"')
        log_success("CPU mitigations disabled for better performance")
    else:
        log_info("Keeping CPU mitigations enabled for security")

    log_info("Enabling systemd-oomd (Out-of-Memory Daemon)...")
    run_command("sudo systemctl enable --now systemd-oomd")

    log_info("Enabling automatic SSD TRIM for storage optimization...")
    run_command("sudo systemctl enable --now fstrim.timer")

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
        "-y",
        "--yes",
        action="store_true",
        help="Automatically answer yes to all prompts",
    )
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

    # Shell command
    subparsers.add_parser("shell", help="Change default shell to zsh")

    # SSH permissions command
    subparsers.add_parser("ssh-perms", help="Fix SSH file permissions")

    args = parser.parse_args()

    # Configure setup_config with parsed arguments
    setup_config.dry_run = args.dry_run
    setup_config.verbose = args.verbose
    setup_config.auto_confirm = args.yes

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

            # Stow dotfiles
            stow_dotfiles()

            # Update ZSH configuration
            update_zshrc()

            create_platform_specific_additionals()

            # Setup services (Fedora only)
            if platform_name == "fedora":
                setup_services()

            # Change default shell to zsh
            change_default_shell()

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

        elif args.command == "shell":
            change_default_shell()

        elif args.command == "ssh-perms":
            setup_ssh_permissions()

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
