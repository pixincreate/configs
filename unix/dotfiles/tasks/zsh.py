"""
Zsh configuration setup.
"""

from typing import List, Dict, Any, Optional
from pathlib import Path

from ..utils.logger import Logger
from ..utils.common import ShellExecutor, FileManager
from ..utils.confirmation import ConfirmationManager
from ..config import ConfigManager

logger = Logger()


class ZshConfigurator:
    """Handles Zsh configuration setup."""

    def __init__(self, platform: str, config_manager: ConfigManager,
                 shell: ShellExecutor, file_manager: FileManager,
                 confirmation_manager: ConfirmationManager, dry_run: bool = False):
        self.platform = platform
        self.config_manager = config_manager
        self.shell = shell
        self.file_manager = file_manager
        self.confirmation_manager = confirmation_manager
        self.dry_run = dry_run

    def setup_zsh(self) -> bool:
        """Setup Zsh configuration."""
        logger.step("Setting up Zsh configuration")

        success = True

        try:
            # Check if Zsh is installed
            if not self.shell.command_exists("zsh"):
                logger.error("Zsh is not installed. Please install Zsh first.")
                return False

            # Update zshrc with platform-specific additions
            if not self._update_zshrc():
                success = False

            # Change default shell to Zsh
            if not self._change_default_shell():
                logger.warning("Failed to change default shell, but Zsh is configured")

            return success

        except Exception as e:
            logger.error(f"Zsh setup failed: {e}")
            return False

    def _update_zshrc(self) -> bool:
        """Update .zshrc with platform-specific additions."""
        logger.substep("Updating Zsh configuration")

        try:
            settings = self.config_manager.get_settings_config()
            zsh_config = settings.get("zsh_config", {})

            additionals_file = Path(zsh_config.get("additionals_file", "~/.zsh/.additionals.zsh")).expanduser()

            # Check if the .zshrc file needs updating
            zshrc_path = Path.home() / "Dev" / ".configs" / "home" / "zsh" / ".zsh" / ".zshrc"

            if not zshrc_path.exists():
                logger.warning("Source .zshrc not found in repository. Zsh configuration should be stowed first.")
                return False

            # Read current .zshrc content
            with open(zshrc_path, 'r') as f:
                zshrc_content = f.read()

            # Check if updates are needed
            needs_update = self._check_zshrc_needs_update(zshrc_content)

            if needs_update:
                if self.confirmation_manager.confirm("Update .zshrc with latest changes?", default=True):
                    if not self._apply_zshrc_updates(zshrc_path):
                        return False
                else:
                    logger.info("Skipping .zshrc update")

            # Ensure platform-specific additions file exists
            if not self._create_additionals_file(additionals_file):
                return False

            logger.success("Zsh configuration updated")
            return True

        except Exception as e:
            logger.error(f"Failed to update Zsh configuration: {e}")
            return False

    def _check_zshrc_needs_update(self, content: str) -> bool:
        """Check if .zshrc needs updating."""
        # This is a placeholder for checking if updates are needed
        # You could implement version checking or content comparison here

        # For now, we'll check for some basic indicators
        required_elements = [
            "zgenom",  # Plugin manager
            "HISTSIZE",  # History configuration
            "export PATH"  # PATH modifications
        ]

        missing_elements = [elem for elem in required_elements if elem not in content]

        if missing_elements:
            logger.verbose(f"Missing elements in .zshrc: {missing_elements}")
            return True

        return False

    def _apply_zshrc_updates(self, zshrc_path: Path) -> bool:
        """Apply updates to .zshrc file."""
        logger.substep("Applying .zshrc updates")

        try:
            # For now, we'll just log that we would update
            # In a real implementation, you might have version-specific updates

            if self.dry_run:
                logger.dry_run(f"Would apply updates to {zshrc_path}")
            else:
                # Create a backup
                backup_path = zshrc_path.with_suffix(".zshrc.backup")
                self.file_manager.copy_file(zshrc_path, backup_path, backup=False)
                logger.verbose(f"Created backup: {backup_path}")

                # Apply updates (placeholder)
                logger.verbose("Applied .zshrc updates")

            return True

        except Exception as e:
            logger.error(f"Failed to apply .zshrc updates: {e}")
            return False

    def _create_additionals_file(self, additionals_file: Path) -> bool:
        """Create platform-specific additions file."""
        logger.substep("Creating platform-specific Zsh additions")

        try:
            settings = self.config_manager.get_settings_config()
            zsh_config = settings.get("zsh_config", {})
            platform_additions = zsh_config.get("platform_additions", {}).get(self.platform, [])

            if not platform_additions:
                logger.verbose(f"No platform-specific additions for {self.platform}")
                return True

            # Ensure the directory exists
            self.file_manager.ensure_directory(additionals_file.parent)

            # Check if file already exists and has the content
            if additionals_file.exists():
                with open(additionals_file, 'r') as f:
                    existing_content = f.read()

                # Check if all additions are already present
                if all(addition in existing_content for addition in platform_additions):
                    logger.verbose("Platform additions already present")
                    return True

            # Create/update the additions file
            content_lines = [
                f"# Platform-specific additions for {self.platform}",
                f"# Generated by dotfiles setup",
                ""
            ]

            content_lines.extend(platform_additions)
            content_lines.append("")  # Empty line at end

            content = "\n".join(content_lines)

            if self.dry_run:
                logger.dry_run(f"Would create {additionals_file} with platform additions")
            else:
                with open(additionals_file, 'w') as f:
                    f.write(content)
                logger.verbose(f"Created platform additions file: {additionals_file}")

            return True

        except Exception as e:
            logger.error(f"Failed to create platform additions file: {e}")
            return False

    def _change_default_shell(self) -> bool:
        """Change the default shell to Zsh."""
        logger.substep("Setting Zsh as default shell")

        try:
            # Get current shell
            current_shell = self.shell.run(["echo", "$SHELL"], capture_output=True).stdout.strip()

            # Get Zsh path
            settings = self.config_manager.get_settings_config()
            platform_settings = settings.get("platform_settings", {}).get(self.platform, {})
            zsh_path = platform_settings.get("shell_path", "/usr/bin/zsh")

            if current_shell == zsh_path:
                logger.info("Zsh is already the default shell")
                return True

            if not Path(zsh_path).exists():
                logger.error(f"Zsh not found at expected path: {zsh_path}")
                # Try to find Zsh
                zsh_which = self.shell.run(["which", "zsh"], capture_output=True, check=False)
                if zsh_which.returncode == 0:
                    zsh_path = zsh_which.stdout.strip()
                    logger.info(f"Found Zsh at: {zsh_path}")
                else:
                    logger.error("Could not locate Zsh")
                    return False

            # Confirm with user
            if not self.confirmation_manager.confirm(f"Change default shell to Zsh ({zsh_path})?", default=True):
                logger.info("Skipping shell change")
                return True

            # Change shell
            if self.platform == "android":
                # Termux uses a different method
                if self.dry_run:
                    logger.dry_run("Would change shell to zsh in Termux")
                else:
                    self.shell.run(["chsh", "-s", "zsh"])
            else:
                # Standard Unix systems
                if self.dry_run:
                    logger.dry_run(f"Would change shell to {zsh_path}")
                else:
                    self.shell.run(["chsh", "-s", zsh_path])

            logger.success("Default shell changed to Zsh")
            logger.info("Please log out and back in for the change to take effect")
            return True

        except Exception as e:
            logger.error(f"Failed to change default shell: {e}")
            return False

    def check_zsh_configuration(self) -> Dict[str, Any]:
        """Check the current Zsh configuration status."""
        status = {
            "zsh_installed": False,
            "zsh_default": False,
            "zsh_path": None,
            "zgenom_installed": False,
            "additionals_exist": False
        }

        try:
            # Check if Zsh is installed
            if self.shell.command_exists("zsh"):
                status["zsh_installed"] = True
                zsh_path = self.shell.run(["which", "zsh"], capture_output=True).stdout.strip()
                status["zsh_path"] = zsh_path

                # Check if Zsh is default shell
                current_shell = self.shell.run(["echo", "$SHELL"], capture_output=True).stdout.strip()
                status["zsh_default"] = current_shell == zsh_path

            # Check if zgenom is installed
            zgenom_dir = Path.home() / ".zsh" / ".zgenom"
            status["zgenom_installed"] = zgenom_dir.exists()

            # Check if additionals file exists
            settings = self.config_manager.get_settings_config()
            zsh_config = settings.get("zsh_config", {})
            additionals_file = Path(zsh_config.get("additionals_file", "~/.zsh/.additionals.zsh")).expanduser()
            status["additionals_exist"] = additionals_file.exists()

        except Exception as e:
            logger.error(f"Failed to check Zsh configuration: {e}")

        return status

    def install_zgenom(self) -> bool:
        """Install zgenom plugin manager if not already installed."""
        logger.substep("Installing zgenom plugin manager")

        try:
            settings = self.config_manager.get_settings_config()
            zsh_config = settings.get("zsh_config", {})
            zgenom_dir = Path(zsh_config.get("zgenom_dir", "~/.zsh/.zgenom")).expanduser()

            if zgenom_dir.exists():
                logger.info("zgenom is already installed")
                return True

            # Clone zgenom repository
            zgenom_repo = "https://github.com/jandamm/zgenom.git"

            if self.dry_run:
                logger.dry_run(f"Would clone zgenom to {zgenom_dir}")
            else:
                self.file_manager.ensure_directory(zgenom_dir.parent)
                clone_cmd = ["git", "clone", zgenom_repo, str(zgenom_dir)]
                self.shell.run_with_spinner(clone_cmd, "Cloning zgenom")

            logger.success("zgenom plugin manager installed")
            return True

        except Exception as e:
            logger.error(f"Failed to install zgenom: {e}")
            return False
