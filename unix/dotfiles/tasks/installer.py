"""
Package and application installer for different platforms.
"""

from typing import List, Dict, Any, Optional
from pathlib import Path
import subprocess

from ..utils.logger import Logger
from ..utils.common import ShellExecutor
from ..utils.confirmation import ConfirmationManager, InteractiveMenu
from ..config import ConfigManager

logger = Logger()


class PackageInstaller:
    """Handles package and application installation across platforms."""

    def __init__(self, platform: str, config_manager: ConfigManager,
                 shell: ShellExecutor, confirmation_manager: ConfirmationManager,
                 dry_run: bool = False):
        self.platform = platform
        self.config_manager = config_manager
        self.shell = shell
        self.confirmation_manager = confirmation_manager
        self.dry_run = dry_run
        self.menu = InteractiveMenu()

    def install_all(self) -> bool:
        """Install all packages and applications for the current platform."""
        logger.step(f"Installing packages and applications for {self.platform}")

        success = True

        try:
            # Setup repositories first
            if not self._setup_repositories():
                logger.warning("Repository setup failed, continuing anyway...")

            # Install packages
            if not self._install_packages():
                success = False

            # Install applications
            if not self._install_applications():
                success = False

            # Platform-specific post-installation
            if not self._platform_specific_setup():
                success = False

        except Exception as e:
            logger.error(f"Installation failed: {e}")
            return False

        return success

    def _setup_repositories(self) -> bool:
        """Setup repositories for the platform."""
        if self.platform == "fedora":
            return self._setup_fedora_repositories()
        elif self.platform == "debian":
            return self._setup_debian_repositories()
        return True

    def _setup_fedora_repositories(self) -> bool:
        """Setup Fedora-specific repositories."""
        logger.substep("Setting up Fedora repositories")

        try:
            # Enable RPM Fusion
            rpmfusion_config = self.config_manager.get_external_repos_for_platform("fedora").get("rpmfusion", {})
            if rpmfusion_config:
                logger.substep("Installing RPM Fusion repositories")
                free_url = rpmfusion_config.get("free", "")
                nonfree_url = rpmfusion_config.get("nonfree", "")

                if free_url and nonfree_url:
                    cmd = ["sudo", "dnf", "install", "-y", free_url, nonfree_url]
                    self.shell.run_with_spinner(cmd, "Installing RPM Fusion")

                # Enable Cisco OpenH264
                self.shell.run(["sudo", "dnf", "config-manager", "setopt", "fedora-cisco-openh264.enabled=1"])

            # Enable COPR repositories
            copr_repos = self.config_manager.get_copr_repos_for_platform("fedora")
            for repo in copr_repos:
                logger.substep(f"Enabling COPR: {repo}")
                cmd = ["sudo", "dnf", "copr", "enable", "-y", repo]
                try:
                    self.shell.run(cmd)
                except subprocess.CalledProcessError:
                    logger.warning(f"Failed to enable COPR: {repo}")

            # Add external repositories
            external_repos = self.config_manager.get_external_repos_for_platform("fedora")
            for repo_name, repo_config in external_repos.items():
                if repo_name in ["rpmfusion"]:  # Already handled above
                    continue

                logger.substep(f"Adding external repository: {repo_name}")
                if repo_name == "nextdns":
                    url = repo_config.get("url")
                    if url:
                        cmd = ["sudo", "curl", "-Ls", url, "-o", f"/etc/yum.repos.d/{repo_name}.repo"]
                        try:
                            self.shell.run(cmd)
                        except subprocess.CalledProcessError:
                            logger.warning(f"Failed to add {repo_name} repository")

                elif repo_name == "microsoft":
                    key_url = repo_config.get("key_url")
                    repo_content = repo_config.get("repo_content")
                    if key_url and repo_content:
                        # Import Microsoft key
                        cmd = ["sudo", "rpm", "--import", key_url]
                        try:
                            self.shell.run(cmd)
                            # Create repository file
                            with open("/tmp/vscode.repo", "w") as f:
                                f.write(repo_content)
                            self.shell.run(["sudo", "mv", "/tmp/vscode.repo", "/etc/yum.repos.d/vscode.repo"])
                        except (subprocess.CalledProcessError, IOError):
                            logger.warning(f"Failed to add {repo_name} repository")

            # Update package lists
            logger.substep("Updating package lists")
            self.shell.run_with_spinner(["sudo", "dnf", "update", "-y", "--refresh"], "Updating system")

            return True

        except Exception as e:
            logger.error(f"Failed to setup Fedora repositories: {e}")
            return False

    def _setup_debian_repositories(self) -> bool:
        """Setup Debian-specific repositories."""
        logger.substep("Setting up Debian repositories")

        try:
            # Update package lists
            self.shell.run_with_spinner(["sudo", "apt-get", "update", "-y"], "Updating package lists")
            return True
        except Exception as e:
            logger.error(f"Failed to setup Debian repositories: {e}")
            return False

    def _install_packages(self) -> bool:
        """Install packages based on user selection."""
        if not self.confirmation_manager.force:
            selected_categories = self.menu.show_package_menu(self.platform)
            if not selected_categories:
                logger.info("No packages selected for installation")
                return True
        else:
            selected_categories = ["all"]

        logger.substep("Installing packages")

        try:
            if "all" in selected_categories:
                # Install all package categories
                success = self._install_common_packages()
                success &= self._install_platform_packages()
            else:
                success = True
                if "common_terminal" in selected_categories:
                    success &= self._install_package_category("terminal_tools")
                if "development" in selected_categories:
                    success &= self._install_package_category("development")
                if f"{self.platform}_packages" in selected_categories:
                    success &= self._install_platform_packages()

            return success

        except Exception as e:
            logger.error(f"Package installation failed: {e}")
            return False

    def _install_common_packages(self) -> bool:
        """Install common packages for all platforms."""
        logger.substep("Installing common packages")

        # Get all common packages
        terminal_tools = self.config_manager.get_packages_for_platform("common", "terminal_tools")
        development = self.config_manager.get_packages_for_platform("common", "development")

        all_packages = terminal_tools + development

        return self._install_package_list(all_packages, "common packages")

    def _install_package_category(self, category: str) -> bool:
        """Install packages from a specific category."""
        packages = self.config_manager.get_packages_for_platform(self.platform, category)
        return self._install_package_list(packages, f"{category} packages")

    def _install_platform_packages(self) -> bool:
        """Install platform-specific packages."""
        logger.substep(f"Installing {self.platform}-specific packages")

        packages = self.config_manager.get_packages_for_platform(self.platform)
        return self._install_package_list(packages, f"{self.platform} packages")

    def _install_package_list(self, packages: List[str], description: str) -> bool:
        """Install a list of packages using the appropriate package manager."""
        if not packages:
            logger.verbose(f"No {description} to install")
            return True

        logger.substep(f"Installing {description}: {len(packages)} packages")

        package_managers = self.config_manager.get_package_managers_for_platform(self.platform)
        primary_manager = package_managers[0] if package_managers else None

        if not primary_manager:
            logger.error(f"No package manager configured for {self.platform}")
            return False

        if self.platform == "macos":
            return self._install_with_homebrew(packages, description)
        elif self.platform == "fedora":
            return self._install_with_dnf(packages, description)
        elif self.platform == "debian":
            return self._install_with_apt(packages, description)
        elif self.platform == "android":
            return self._install_with_pkg(packages, description)
        else:
            logger.error(f"Unsupported platform: {self.platform}")
            return False

    def _install_with_homebrew(self, packages: List[str], description: str) -> bool:
        """Install packages using Homebrew."""
        # First ensure Homebrew is installed
        if not self.shell.command_exists("brew"):
            logger.substep("Installing Homebrew")
            if not self._install_homebrew():
                return False

        # Install packages
        for package in packages:
            try:
                if self.shell.command_exists(package):
                    logger.verbose(f"Package already installed: {package}")
                    continue

                logger.verbose(f"Installing: {package}")
                cmd = ["brew", "install", package]
                self.shell.run_with_spinner(cmd, f"Installing {package}")

            except subprocess.CalledProcessError:
                logger.warning(f"Failed to install package: {package}")

        return True

    def _install_with_dnf(self, packages: List[str], description: str) -> bool:
        """Install packages using DNF (Fedora)."""
        # Filter out packages that are already installed
        packages_to_install = []
        for package in packages:
            try:
                # Check if package is installed
                result = self.shell.run(["rpm", "-q", package], capture_output=True, check=False)
                if result.returncode != 0:
                    packages_to_install.append(package)
                else:
                    logger.verbose(f"Package already installed: {package}")
            except:
                packages_to_install.append(package)

        if not packages_to_install:
            logger.info(f"All {description} already installed")
            return True

        # Install packages in batches
        batch_size = 10
        for i in range(0, len(packages_to_install), batch_size):
            batch = packages_to_install[i:i + batch_size]
            logger.verbose(f"Installing batch: {', '.join(batch)}")

            cmd = ["sudo", "dnf", "install", "-y"] + batch
            try:
                self.shell.run_with_spinner(cmd, f"Installing {len(batch)} packages")
            except subprocess.CalledProcessError:
                logger.warning(f"Some packages in batch failed to install: {', '.join(batch)}")

        return True

    def _install_with_apt(self, packages: List[str], description: str) -> bool:
        """Install packages using APT (Debian/Ubuntu)."""
        # Install packages in one command
        cmd = ["sudo", "apt-get", "install", "-y"] + packages
        try:
            self.shell.run_with_spinner(cmd, f"Installing {description}")
            return True
        except subprocess.CalledProcessError:
            logger.warning(f"Some packages failed to install: {description}")
            return False

    def _install_with_pkg(self, packages: List[str], description: str) -> bool:
        """Install packages using pkg (Android/Termux)."""
        for package in packages:
            try:
                if self.shell.command_exists(package):
                    logger.verbose(f"Package already installed: {package}")
                    continue

                logger.verbose(f"Installing: {package}")
                cmd = ["pkg", "install", "-y", package]
                self.shell.run_with_spinner(cmd, f"Installing {package}")

            except subprocess.CalledProcessError:
                logger.warning(f"Failed to install package: {package}")

        return True

    def _install_applications(self) -> bool:
        """Install applications (GUI apps, Flatpaks, etc.)."""
        logger.substep("Installing applications")

        if self.platform == "fedora":
            return self._install_flatpak_apps()
        elif self.platform == "macos":
            return self._install_macos_apps()

        # Other platforms don't have separate app installation currently
        return True

    def _install_flatpak_apps(self) -> bool:
        """Install Flatpak applications on Fedora."""
        flatpak_apps = self.config_manager.get_flatpak_apps_for_platform("fedora")

        if not flatpak_apps:
            logger.info("No Flatpak applications to install")
            return True

        # Ensure Flatpak is installed
        if not self.shell.command_exists("flatpak"):
            logger.substep("Installing Flatpak")
            try:
                self.shell.run(["sudo", "dnf", "install", "-y", "flatpak"])
            except subprocess.CalledProcessError:
                logger.error("Failed to install Flatpak")
                return False

        # Ensure Flathub is enabled
        logger.substep("Setting up Flathub repository")
        try:
            cmd = ["flatpak", "remote-add", "--if-not-exists", "flathub",
                   "https://flathub.org/repo/flathub.flatpakrepo"]
            self.shell.run(cmd)
        except subprocess.CalledProcessError:
            logger.warning("Failed to add Flathub repository")

        # Install Flatpak applications
        for app in flatpak_apps:
            try:
                logger.verbose(f"Installing Flatpak: {app}")
                cmd = ["flatpak", "install", "-y", "flathub", app]
                self.shell.run_with_spinner(cmd, f"Installing {app}")
            except subprocess.CalledProcessError:
                logger.warning(f"Failed to install Flatpak: {app}")

        return True

    def _install_macos_apps(self) -> bool:
        """Install macOS applications using Homebrew casks."""
        apps = self.config_manager.get_apps_for_platform("macos")

        if not apps:
            logger.info("No macOS applications to install")
            return True

        for app in apps:
            try:
                logger.verbose(f"Installing app: {app}")
                cmd = ["brew", "install", "--cask", app]
                self.shell.run_with_spinner(cmd, f"Installing {app}")
            except subprocess.CalledProcessError:
                logger.warning(f"Failed to install app: {app}")

        return True

    def _install_homebrew(self) -> bool:
        """Install Homebrew on macOS or Linux."""
        logger.substep("Installing Homebrew")

        try:
            # Download and run Homebrew installer
            install_script = '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
            self.shell.run_with_spinner(install_script, "Installing Homebrew")

            # Add Homebrew to PATH
            if self.platform == "macos":
                brew_path = "/opt/homebrew/bin/brew" if Path("/opt/homebrew/bin/brew").exists() else "/usr/local/bin/brew"
            else:
                brew_path = "/home/linuxbrew/.linuxbrew/bin/brew"

            if Path(brew_path).exists():
                # Initialize Homebrew environment
                self.shell.run([brew_path, "shellenv"])
                logger.success("Homebrew installed successfully")
                return True
            else:
                logger.error("Homebrew installation failed")
                return False

        except Exception as e:
            logger.error(f"Failed to install Homebrew: {e}")
            return False

    def _platform_specific_setup(self) -> bool:
        """Run platform-specific post-installation setup."""
        if self.platform == "fedora":
            return self._fedora_specific_setup()
        elif self.platform == "macos":
            return self._macos_specific_setup()
        elif self.platform == "android":
            return self._android_specific_setup()

        return True

    def _fedora_specific_setup(self) -> bool:
        """Fedora-specific setup tasks."""
        logger.substep("Running Fedora-specific setup")

        try:
            # Setup multimedia codecs
            logger.verbose("Setting up multimedia codecs")
            self.shell.run(["sudo", "dnf", "swap", "ffmpeg-free", "ffmpeg", "--allowerasing"])
            self.shell.run(["sudo", "dnf", "update", "@multimedia", "--setopt=install_weak_deps=False",
                           "--exclude=PackageKit-gstreamer-plugin"])

            # Install Intel media driver if on Intel hardware
            try:
                self.shell.run(["sudo", "dnf", "install", "-y", "intel-media-driver"])
                self.shell.run(["sudo", "dnf", "install", "-y", "libva-nvidia-driver.i686", "libva-nvidia-driver.x86_64"])
            except subprocess.CalledProcessError:
                pass  # Not critical if this fails

            # Setup NVIDIA drivers if NVIDIA hardware detected
            self._setup_nvidia_drivers()

            # Setup ASUS utilities if on ASUS hardware
            self._setup_asus_utilities()

            # Setup TLP for power management
            self._setup_tlp()

            # Setup NextDNS if requested
            self._setup_nextdns()

            return True

        except Exception as e:
            logger.warning(f"Some Fedora-specific setup failed: {e}")
            return False

    def _setup_nvidia_drivers(self) -> bool:
        """Setup NVIDIA drivers on Fedora."""
        try:
            # Check if NVIDIA hardware is present
            result = self.shell.run(["lspci"], capture_output=True, check=False)
            if "nvidia" not in result.stdout.lower():
                logger.verbose("No NVIDIA hardware detected, skipping NVIDIA setup")
                return True

            logger.substep("NVIDIA hardware detected, installing drivers")

            # Install kernel headers
            self.shell.run(["sudo", "dnf", "install", "-y", "kernel-devel"])

            # Install NVIDIA drivers
            self.shell.run(["sudo", "dnf", "install", "-y", "akmod-nvidia", "xorg-x11-drv-nvidia-cuda"])

            # Install NVIDIA settings GUI
            self.shell.run(["sudo", "dnf", "install", "-y", "nvidia-settings"])

            # Install 32-bit libraries for gaming
            self.shell.run(["sudo", "dnf", "install", "-y", "xorg-x11-drv-nvidia-libs.i686"])

            # Regenerate initramfs
            self.shell.run(["sudo", "akmods", "--force"])

            # Enable NVIDIA services
            services = ["nvidia-hibernate.service", "nvidia-suspend.service",
                       "nvidia-resume.service", "nvidia-powerd.service"]
            for service in services:
                try:
                    self.shell.run(["sudo", "systemctl", "enable", service])
                except subprocess.CalledProcessError:
                    logger.warning(f"Failed to enable {service}")

            logger.info("NVIDIA drivers installed. A reboot is required.")
            return True

        except Exception as e:
            logger.warning(f"NVIDIA setup failed: {e}")
            return False

    def _setup_asus_utilities(self) -> bool:
        """Setup ASUS utilities if on ASUS hardware."""
        try:
            # Check if this is an ASUS system
            result = self.shell.run(["sudo", "dmidecode", "-s", "system-manufacturer"],
                                  capture_output=True, check=False)
            if "asus" not in result.stdout.lower():
                logger.verbose("Not an ASUS system, skipping ASUS utilities setup")
                return True

            logger.substep("ASUS system detected, installing ASUS utilities")

            # Install ASUS utilities
            self.shell.run(["sudo", "dnf", "install", "-y", "asusctl", "supergfxctl", "asusctl-rog-gui"])

            # Enable services
            self.shell.run(["sudo", "systemctl", "enable", "supergfxd.service"])
            self.shell.run(["sudo", "systemctl", "start", "asusd"])

            # Set default aura lighting (white)
            try:
                self.shell.run(["asusctl", "aura", "static", "-c", "ffffff"])
            except subprocess.CalledProcessError:
                logger.warning("Failed to set aura lighting")

            logger.success("ASUS utilities installed successfully")
            return True

        except Exception as e:
            logger.warning(f"ASUS utilities setup failed: {e}")
            return False

    def _setup_tlp(self) -> bool:
        """Setup TLP for power management."""
        try:
            logger.substep("Setting up TLP for power management")

            # Install TLP
            self.shell.run(["sudo", "dnf", "install", "-y", "tlp", "tlp-rdw", "powertop"])

            # Enable and start TLP
            self.shell.run(["sudo", "systemctl", "enable", "tlp.service"])
            self.shell.run(["sudo", "systemctl", "start", "tlp.service"])

            # Mask conflicting power management services
            conflicting_services = ["power-profiles-daemon.service", "tuned.service"]
            for service in conflicting_services:
                try:
                    self.shell.run(["sudo", "systemctl", "mask", service])
                except subprocess.CalledProcessError:
                    pass  # Service might not exist

            logger.success("TLP setup completed")
            return True

        except Exception as e:
            logger.warning(f"TLP setup failed: {e}")
            return False

    def _setup_nextdns(self) -> bool:
        """Setup NextDNS if available and requested."""
        try:
            if not self.shell.command_exists("nextdns"):
                logger.verbose("NextDNS not installed, skipping setup")
                return True

            if not self.confirmation_manager.confirm("Configure NextDNS?", default=False):
                logger.info("Skipping NextDNS configuration")
                return True

            logger.substep("Setting up NextDNS")

            # Prompt for NextDNS config ID
            config_id = input("Enter your NextDNS config ID: ").strip()
            if not config_id:
                logger.warning("No NextDNS config ID provided, skipping")
                return True

            # Configure NextDNS
            self.shell.run(["sudo", "nextdns", "install", "-config", config_id,
                           "-setup-router=false", "-report-client-info=true", "-log-queries=false"])
            self.shell.run(["sudo", "nextdns", "activate"])

            logger.success("NextDNS configured successfully")
            return True

        except Exception as e:
            logger.warning(f"NextDNS setup failed: {e}")
            return False

    def _macos_specific_setup(self) -> bool:
        """macOS-specific setup tasks."""
        logger.substep("Running macOS-specific setup")

        try:
            # Turn off Homebrew analytics
            self.shell.run(["brew", "analytics", "off"])
            return True

        except Exception as e:
            logger.warning(f"macOS-specific setup failed: {e}")
            return False

    def _android_specific_setup(self) -> bool:
        """Android-specific setup tasks."""
        logger.substep("Running Android-specific setup")

        try:
            # Setup Termux storage
            if self.confirmation_manager.confirm("Setup Termux storage access?", default=True):
                self.shell.run(["termux-setup-storage"])

            return True

        except Exception as e:
            logger.warning(f"Android-specific setup failed: {e}")
            return False
