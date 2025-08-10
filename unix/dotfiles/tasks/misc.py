"""
Miscellaneous setup tasks.
"""

from typing import List, Dict, Any, Optional
from pathlib import Path
import subprocess
import os

from ..utils.logger import Logger
from ..utils.common import ShellExecutor, FileManager
from ..utils.confirmation import ConfirmationManager
from ..config import ConfigManager

logger = Logger()


class MiscSetup:
    """Handles miscellaneous setup tasks."""

    def __init__(self, platform: str, config_manager: ConfigManager,
                 shell: ShellExecutor, file_manager: FileManager,
                 confirmation_manager: ConfirmationManager, dry_run: bool = False):
        self.platform = platform
        self.config_manager = config_manager
        self.shell = shell
        self.file_manager = file_manager
        self.confirmation_manager = confirmation_manager
        self.dry_run = dry_run

    def run_all(self) -> bool:
        """Run all miscellaneous setup tasks."""
        logger.step("Running miscellaneous setup tasks")

        success = True

        try:
            # Setup platform-specific tasks
            if not self._setup_platform_specific():
                success = False

            # Setup development tools
            if not self._setup_development_tools():
                success = False

            # Setup trash-cli with cron
            if not self._setup_trash_cli():
                success = False

            # Setup system optimizations
            if not self._setup_system_optimizations():
                success = False

            return success

        except Exception as e:
            logger.error(f"Miscellaneous setup failed: {e}")
            return False

    def _setup_platform_specific(self) -> bool:
        """Setup platform-specific miscellaneous tasks."""
        logger.substep(f"Setting up {self.platform}-specific tasks")

        try:
            if self.platform == "android":
                return self._setup_android_specific()
            elif self.platform == "macos":
                return self._setup_macos_specific()
            elif self.platform == "fedora":
                return self._setup_fedora_specific()
            elif self.platform == "debian":
                return self._setup_debian_specific()

            return True

        except Exception as e:
            logger.error(f"Platform-specific setup failed: {e}")
            return False

    def _setup_android_specific(self) -> bool:
        """Setup Android/Termux specific tasks."""
        logger.substep("Setting up Android-specific tasks")

        try:
            # Setup rish if available
            if not self._setup_rish():
                logger.warning("Failed to setup rish, but continuing")

            # Setup Termux storage access
            if self.confirmation_manager.confirm("Setup Termux storage access?", default=True):
                try:
                    self.shell.run(["termux-setup-storage"])
                    logger.success("Termux storage access configured")
                except subprocess.CalledProcessError:
                    logger.warning("Failed to setup Termux storage")

            return True

        except Exception as e:
            logger.error(f"Android-specific setup failed: {e}")
            return False

    def _setup_rish(self) -> bool:
        """Setup rish (Shizuku) integration for Android."""
        logger.substep("Setting up rish (Shizuku)")

        try:
            settings = self.config_manager.get_settings_config()
            platform_settings = settings.get("platform_settings", {}).get("android", {})
            rish_source = platform_settings.get("rish_source", "/storage/emulated/0/Documents/Dev/Shizuku")

            rish_source_path = Path(rish_source)
            rish_dest = Path.home() / ".rish"

            if not rish_source_path.exists():
                logger.verbose("Rish source directory not found, skipping")
                return True

            # Ensure rish directory exists
            self.file_manager.ensure_directory(rish_dest)

            # Copy rish files
            if self.dry_run:
                logger.dry_run(f"Would copy rish files from {rish_source_path} to {rish_dest}")
            else:
                for item in rish_source_path.rglob("*"):
                    if item.is_file():
                        relative_path = item.relative_to(rish_source_path)
                        dest_path = rish_dest / relative_path
                        self.file_manager.ensure_directory(dest_path.parent)
                        self.file_manager.copy_file(item, dest_path, backup=False)

                # Create symlinks for easy access
                rish_script = rish_dest / "rish"
                if rish_script.exists():
                    # Add to PATH by creating symlink
                    path_dir = Path.home() / ".local" / "bin"
                    self.file_manager.ensure_directory(path_dir)

                    rish_link = path_dir / "rish"
                    rish_dex_link = path_dir / "rish_shizuku.dex"

                    if not rish_link.exists():
                        self.file_manager.create_symlink(rish_script, rish_link)

                    rish_dex = rish_dest / "rish_shizuku.dex"
                    if rish_dex.exists() and not rish_dex_link.exists():
                        self.file_manager.create_symlink(rish_dex, rish_dex_link)

            logger.success("Rish setup completed")
            return True

        except Exception as e:
            logger.error(f"Failed to setup rish: {e}")
            return False

    def _setup_macos_specific(self) -> bool:
        """Setup macOS specific tasks."""
        logger.substep("Setting up macOS-specific tasks")

        try:
            # Move VS Code directory if it exists in the old location
            old_code_dir = Path.home() / "Code"
            new_code_dir = Path.home() / "Library" / "Application Support" / "Code"

            if old_code_dir.exists() and not new_code_dir.exists():
                if self.confirmation_manager.confirm(f"Move VS Code directory from {old_code_dir} to {new_code_dir}?", default=True):
                    if self.dry_run:
                        logger.dry_run(f"Would move {old_code_dir} to {new_code_dir}")
                    else:
                        self.file_manager.move_file(old_code_dir, new_code_dir)
                        logger.success("VS Code directory moved")

            return True

        except Exception as e:
            logger.error(f"macOS-specific setup failed: {e}")
            return False

    def _setup_fedora_specific(self) -> bool:
        """Setup Fedora specific tasks."""
        logger.substep("Setting up Fedora-specific tasks")

        try:
            # Move VS Code directory if it exists in the old location
            old_code_dir = Path.home() / "Code"
            new_code_dir = Path.home() / ".config" / "Code"

            if old_code_dir.exists() and not new_code_dir.exists():
                if self.confirmation_manager.confirm(f"Move VS Code directory from {old_code_dir} to {new_code_dir}?", default=True):
                    if self.dry_run:
                        logger.dry_run(f"Would move {old_code_dir} to {new_code_dir}")
                    else:
                        self.file_manager.move_file(old_code_dir, new_code_dir)
                        logger.success("VS Code directory moved")

            # Setup system health check script alias
            settings = self.config_manager.get_settings_config()
            platform_settings = settings.get("platform_settings", {}).get("fedora", {})
            health_script = platform_settings.get("health_check_script")

            if health_script:
                health_script_path = Path(health_script).expanduser()
                if health_script_path.exists():
                    # Make it executable
                    self.file_manager.set_permissions(health_script_path, 0o755)
                    logger.verbose("Health check script permissions set")

            return True

        except Exception as e:
            logger.error(f"Fedora-specific setup failed: {e}")
            return False

    def _setup_debian_specific(self) -> bool:
        """Setup Debian/WSL specific tasks."""
        logger.substep("Setting up Debian-specific tasks")

        try:
            # Move VS Code directory if it exists in the old location
            old_code_dir = Path.home() / "Code"
            new_code_dir = Path.home() / ".config" / "Code"

            if old_code_dir.exists() and not new_code_dir.exists():
                if self.confirmation_manager.confirm(f"Move VS Code directory from {old_code_dir} to {new_code_dir}?", default=True):
                    if self.dry_run:
                        logger.dry_run(f"Would move {old_code_dir} to {new_code_dir}")
                    else:
                        self.file_manager.move_file(old_code_dir, new_code_dir)
                        logger.success("VS Code directory moved")

            # WSL-specific setup
            if self._is_wsl():
                logger.substep("Setting up WSL-specific configurations")
                # Additional WSL setup could go here
                logger.verbose("WSL environment detected")

            return True

        except Exception as e:
            logger.error(f"Debian-specific setup failed: {e}")
            return False

    def _setup_development_tools(self) -> bool:
        """Setup development environment tools."""
        logger.substep("Setting up development tools")

        try:
            # Setup Python development tools
            if not self._setup_python_tools():
                logger.warning("Failed to setup Python tools")

            # Setup Node.js development tools
            if not self._setup_nodejs_tools():
                logger.warning("Failed to setup Node.js tools")

            # Setup Rust development tools
            if not self._setup_rust_tools():
                logger.warning("Failed to setup Rust tools")

            return True

        except Exception as e:
            logger.error(f"Development tools setup failed: {e}")
            return False

    def _setup_python_tools(self) -> bool:
        """Setup Python development tools."""
        if not self.shell.command_exists("python3"):
            logger.verbose("Python3 not found, skipping Python tools setup")
            return True

        try:
            # Ensure pipx is available and up to date
            if self.shell.command_exists("pipx"):
                logger.verbose("Setting up pipx environment")
                self.shell.run(["pipx", "ensurepath"], check=False)

            logger.verbose("Python tools setup completed")
            return True

        except Exception as e:
            logger.warning(f"Python tools setup failed: {e}")
            return False

    def _setup_nodejs_tools(self) -> bool:
        """Setup Node.js development tools."""
        if not self.shell.command_exists("node"):
            logger.verbose("Node.js not found, skipping Node.js tools setup")
            return True

        try:
            # Set NPM configuration to disable ads
            npm_config = [
                ("DISABLE_OPENCOLLECTIVE", "1"),
                ("ADBLOCK", "1")
            ]

            for var, value in npm_config:
                self.shell.run(["npm", "config", "set", var.lower(), value], check=False)

            logger.verbose("Node.js tools setup completed")
            return True

        except Exception as e:
            logger.warning(f"Node.js tools setup failed: {e}")
            return False

    def _setup_rust_tools(self) -> bool:
        """Setup Rust development tools."""
        if not self.shell.command_exists("rustup"):
            logger.verbose("Rustup not found, skipping Rust tools setup")
            return True

        try:
            # Ensure stable toolchain is installed and set as default
            self.shell.run(["rustup", "toolchain", "install", "stable"], check=False)
            self.shell.run(["rustup", "default", "stable"], check=False)

            logger.verbose("Rust tools setup completed")
            return True

        except Exception as e:
            logger.warning(f"Rust tools setup failed: {e}")
            return False

    def _setup_trash_cli(self) -> bool:
        """Setup trash-cli with automatic cleanup cron job."""
        logger.substep("Setting up trash-cli")

        try:
            # Install trash-cli if pipx is available
            if self.shell.command_exists("pipx"):
                if not self.shell.command_exists("trash"):
                    if self.dry_run:
                        logger.dry_run("Would install trash-cli via pipx")
                    else:
                        try:
                            self.shell.run_with_spinner(["pipx", "install", "trash-cli"], "Installing trash-cli")
                            logger.success("trash-cli installed via pipx")
                        except subprocess.CalledProcessError:
                            logger.warning("Failed to install trash-cli")
                            return False

                # Setup cron job for automatic trash cleanup
                if self._setup_trash_cron():
                    logger.success("Trash cleanup cron job configured")

            else:
                logger.verbose("pipx not available, skipping trash-cli setup")

            return True

        except Exception as e:
            logger.error(f"trash-cli setup failed: {e}")
            return False

    def _setup_trash_cron(self) -> bool:
        """Setup cron job for automatic trash cleanup."""
        try:
            if not self.shell.command_exists("crontab"):
                logger.verbose("crontab not available, skipping trash cleanup cron")
                return True

            # Check if cron job already exists
            try:
                result = self.shell.run(["crontab", "-l"], capture_output=True, check=False)
                existing_crontab = result.stdout if result.returncode == 0 else ""
            except:
                existing_crontab = ""

            trash_cron_line = "@daily $(which trash-empty) 60"

            if trash_cron_line in existing_crontab:
                logger.verbose("Trash cleanup cron job already exists")
                return True

            if self.confirmation_manager.confirm("Setup automatic trash cleanup (empty trash after 60 days)?", default=True):
                if self.dry_run:
                    logger.dry_run("Would add trash cleanup cron job")
                else:
                    # Add cron job
                    new_crontab = existing_crontab.rstrip()
                    if new_crontab:
                        new_crontab += "\n"
                    new_crontab += trash_cron_line + "\n"

                    # Install new crontab
                    process = subprocess.Popen(["crontab", "-"], stdin=subprocess.PIPE, text=True)
                    process.communicate(input=new_crontab)

                    if process.returncode == 0:
                        logger.success("Trash cleanup cron job added")
                        # List crontab for verification
                        self.shell.run(["crontab", "-l"], capture_output=False)
                    else:
                        logger.warning("Failed to add cron job")
                        return False

            return True

        except Exception as e:
            logger.warning(f"Failed to setup trash cron: {e}")
            return False

    def _setup_system_optimizations(self) -> bool:
        """Setup system optimizations."""
        logger.substep("Setting up system optimizations")

        try:
            # Platform-specific optimizations
            if self.platform == "fedora":
                return self._setup_fedora_optimizations()
            elif self.platform == "debian":
                return self._setup_debian_optimizations()

            return True

        except Exception as e:
            logger.error(f"System optimizations setup failed: {e}")
            return False

    def _setup_fedora_optimizations(self) -> bool:
        """Setup Fedora-specific system optimizations."""
        try:
            # Setup TLP for better power management if not already configured
            if self.shell.command_exists("tlp"):
                logger.verbose("TLP is available for power management")

                if self.confirmation_manager.confirm("Enable TLP service for power management?", default=True):
                    if self.dry_run:
                        logger.dry_run("Would enable TLP service")
                    else:
                        try:
                            self.shell.run(["sudo", "systemctl", "enable", "tlp.service"])
                            self.shell.run(["sudo", "systemctl", "start", "tlp.service"])
                            logger.success("TLP service enabled")
                        except subprocess.CalledProcessError:
                            logger.warning("Failed to enable TLP service")

            return True

        except Exception as e:
            logger.warning(f"Fedora optimizations failed: {e}")
            return False

    def _setup_debian_optimizations(self) -> bool:
        """Setup Debian-specific system optimizations."""
        try:
            # Debian-specific optimizations could go here
            logger.verbose("Debian optimizations setup completed")
            return True

        except Exception as e:
            logger.warning(f"Debian optimizations failed: {e}")
            return False

    def _is_wsl(self) -> bool:
        """Check if running in Windows Subsystem for Linux."""
        try:
            # Check for WSL environment variables
            if "WSL_DISTRO_NAME" in os.environ:
                return True

            # Check for microsoft in kernel version
            try:
                with open("/proc/version", "r") as f:
                    version = f.read().lower()
                    return "microsoft" in version
            except:
                pass

            return False

        except Exception:
            return False

    def check_misc_status(self) -> Dict[str, Any]:
        """Check the status of miscellaneous setup items."""
        status = {
            "platform": self.platform,
            "trash_cli_installed": self.shell.command_exists("trash"),
            "pipx_available": self.shell.command_exists("pipx"),
            "development_tools": {
                "python": self.shell.command_exists("python3"),
                "node": self.shell.command_exists("node"),
                "rust": self.shell.command_exists("rustup")
            }
        }

        # Platform-specific status
        if self.platform == "android":
            status["rish_available"] = (Path.home() / ".rish").exists()
            status["termux_storage"] = Path("/storage/emulated/0").exists()

        elif self.platform in ["fedora", "debian"]:
            old_code_dir = Path.home() / "Code"
            new_code_dir = Path.home() / ".config" / "Code"
            status["vscode_dir_migrated"] = not old_code_dir.exists() or new_code_dir.exists()

        elif self.platform == "macos":
            old_code_dir = Path.home() / "Code"
            new_code_dir = Path.home() / "Library" / "Application Support" / "Code"
            status["vscode_dir_migrated"] = not old_code_dir.exists() or new_code_dir.exists()

        return status
