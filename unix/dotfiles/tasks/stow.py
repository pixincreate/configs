"""
Stow configuration management.
"""

from typing import List, Dict, Any, Optional
from pathlib import Path
import subprocess

from ..utils.logger import Logger
from ..utils.common import ShellExecutor
from ..utils.confirmation import ConfirmationManager, InteractiveMenu
from ..config import ConfigManager

logger = Logger()


class StowManager:
    """Handles GNU Stow operations for dotfiles management."""

    def __init__(self, config_manager: ConfigManager, shell: ShellExecutor,
                 confirmation_manager: ConfirmationManager, dry_run: bool = False):
        self.config_manager = config_manager
        self.shell = shell
        self.confirmation_manager = confirmation_manager
        self.dry_run = dry_run
        self.menu = InteractiveMenu()

    def stow_all(self) -> bool:
        """Stow all configured packages."""
        logger.step("Stowing configuration files")

        if not self.shell.command_exists("stow"):
            logger.error("GNU Stow is not installed. Please install stow first.")
            return False

        try:
            # Get packages to stow
            if not self.confirmation_manager.force:
                selected_packages = self.menu.show_stow_menu()
                if not selected_packages:
                    logger.info("No packages selected for stowing")
                    return True
            else:
                selected_packages = ["all"]

            # Get stow packages list
            stow_packages = self.config_manager.get_stow_packages()

            if "all" in selected_packages:
                packages_to_stow = stow_packages
            else:
                packages_to_stow = [pkg for pkg in selected_packages if pkg in stow_packages]

            # Confirm conflicts handling
            if not self._handle_stow_conflicts(packages_to_stow):
                return False

            # Stow each package
            success = True
            for package in packages_to_stow:
                if not self._stow_package(package):
                    success = False

            if success:
                logger.success("All configurations stowed successfully")
            else:
                logger.warning("Some packages failed to stow")

            return success

        except Exception as e:
            logger.error(f"Stow operation failed: {e}")
            return False

    def _handle_stow_conflicts(self, packages: List[str]) -> bool:
        """Handle potential stow conflicts."""
        logger.substep("Checking for stow conflicts")

        config_root = Path.home() / "Dev" / ".configs"
        home_dir = Path.home()
        conflicts = []

        try:
            for package in packages:
                package_dir = config_root / "home" / package
                if not package_dir.exists():
                    logger.warning(f"Package directory not found: {package}")
                    continue

                # Check for conflicts
                package_conflicts = self._check_package_conflicts(package_dir, home_dir)
                if package_conflicts:
                    conflicts.extend([(package, conflict) for conflict in package_conflicts])

            if conflicts:
                logger.warning(f"Found {len(conflicts)} potential conflicts:")
                for package, conflict in conflicts[:10]:  # Show first 10
                    logger.warning(f"  {package}: {conflict}")

                if len(conflicts) > 10:
                    logger.warning(f"  ... and {len(conflicts) - 10} more")

                if not self.confirmation_manager.confirm("Continue with stowing? (conflicts will be backed up)", default=True):
                    return False

            return True

        except Exception as e:
            logger.error(f"Failed to check conflicts: {e}")
            return False

    def _check_package_conflicts(self, package_dir: Path, target_dir: Path) -> List[str]:
        """Check for conflicts when stowing a package."""
        conflicts = []

        try:
            for item in package_dir.rglob("*"):
                if item.is_file():
                    # Calculate relative path from package dir
                    relative_path = item.relative_to(package_dir)
                    target_path = target_dir / relative_path

                    # Check if target exists and is not a symlink
                    if target_path.exists() and not target_path.is_symlink():
                        conflicts.append(str(relative_path))

        except Exception as e:
            logger.error(f"Error checking conflicts for {package_dir}: {e}")

        return conflicts

    def _stow_package(self, package: str) -> bool:
        """Stow a single package."""
        logger.substep(f"Stowing {package}")

        try:
            config_root = Path.home() / "Dev" / ".configs"
            package_dir = config_root / "home" / package

            if not package_dir.exists():
                logger.warning(f"Package directory not found: {package}")
                return False

            # Build stow command
            stow_cmd = [
                "stow",
                "--dir", str(config_root / "home"),
                "--target", str(Path.home()),
                "--restow",  # Re-stow to handle existing links
                "--verbose",
                package
            ]

            if self.dry_run:
                stow_cmd.append("--simulate")

            # Execute stow command
            try:
                result = self.shell.run(stow_cmd, capture_output=True)

                if result.stdout:
                    logger.verbose(f"Stow output: {result.stdout}")

                logger.success(f"Successfully stowed {package}")
                return True

            except subprocess.CalledProcessError as e:
                if e.stderr:
                    logger.error(f"Stow error for {package}: {e.stderr}")
                else:
                    logger.error(f"Stow failed for {package}")
                return False

        except Exception as e:
            logger.error(f"Failed to stow {package}: {e}")
            return False

    def unstow_package(self, package: str) -> bool:
        """Unstow a single package."""
        logger.substep(f"Unstowing {package}")

        try:
            config_root = Path.home() / "Dev" / ".configs"
            package_dir = config_root / "home" / package

            if not package_dir.exists():
                logger.warning(f"Package directory not found: {package}")
                return True  # Not an error if it doesn't exist

            # Build unstow command
            stow_cmd = [
                "stow",
                "--dir", str(config_root / "home"),
                "--target", str(Path.home()),
                "--delete",  # Remove symlinks
                "--verbose",
                package
            ]

            if self.dry_run:
                stow_cmd.append("--simulate")

            # Execute unstow command
            try:
                result = self.shell.run(stow_cmd, capture_output=True)

                if result.stdout:
                    logger.verbose(f"Unstow output: {result.stdout}")

                logger.success(f"Successfully unstowed {package}")
                return True

            except subprocess.CalledProcessError as e:
                if e.stderr:
                    logger.error(f"Unstow error for {package}: {e.stderr}")
                else:
                    logger.error(f"Unstow failed for {package}")
                return False

        except Exception as e:
            logger.error(f"Failed to unstow {package}: {e}")
            return False

    def unstow_all(self) -> bool:
        """Unstow all configured packages."""
        logger.step("Unstowing all configuration files")

        stow_packages = self.config_manager.get_stow_packages()
        success = True

        for package in stow_packages:
            if not self.unstow_package(package):
                success = False

        if success:
            logger.success("All configurations unstowed successfully")
        else:
            logger.warning("Some packages failed to unstow")

        return success

    def check_stow_status(self) -> Dict[str, Any]:
        """Check the status of stowed packages."""
        status = {
            "stow_installed": self.shell.command_exists("stow"),
            "config_root_exists": False,
            "packages": {}
        }

        try:
            config_root = Path.home() / "Dev" / ".configs"
            status["config_root_exists"] = config_root.exists()

            if not status["config_root_exists"]:
                return status

            stow_packages = self.config_manager.get_stow_packages()
            home_dir = Path.home()

            for package in stow_packages:
                package_dir = config_root / "home" / package
                package_status = {
                    "exists": package_dir.exists(),
                    "stowed": False,
                    "conflicts": []
                }

                if package_status["exists"]:
                    # Check if package is stowed by examining symlinks
                    package_status["stowed"] = self._is_package_stowed(package_dir, home_dir)

                    # Check for conflicts
                    package_status["conflicts"] = self._check_package_conflicts(package_dir, home_dir)

                status["packages"][package] = package_status

        except Exception as e:
            logger.error(f"Failed to check stow status: {e}")

        return status

    def _is_package_stowed(self, package_dir: Path, target_dir: Path) -> bool:
        """Check if a package is currently stowed."""
        try:
            for item in package_dir.rglob("*"):
                if item.is_file():
                    relative_path = item.relative_to(package_dir)
                    target_path = target_dir / relative_path

                    # If target exists and is a symlink pointing to our file, it's stowed
                    if (target_path.exists() and
                        target_path.is_symlink() and
                        target_path.resolve() == item.resolve()):
                        return True

            return False

        except Exception:
            return False

    def list_stowable_packages(self) -> List[str]:
        """List all packages that can be stowed."""
        try:
            config_root = Path.home() / "Dev" / ".configs"
            home_dir = config_root / "home"

            if not home_dir.exists():
                return []

            packages = [
                item.name for item in home_dir.iterdir()
                if item.is_dir() and not item.name.startswith('.')
            ]

            return sorted(packages)

        except Exception as e:
            logger.error(f"Failed to list stowable packages: {e}")
            return []

    def backup_conflicts(self, packages: List[str]) -> bool:
        """Backup files that would conflict with stowing."""
        logger.substep("Backing up conflicting files")

        try:
            config_root = Path.home() / "Dev" / ".configs"
            home_dir = Path.home()
            backup_dir = home_dir / ".dotfiles-backup"

            # Ensure backup directory exists
            backup_dir.mkdir(exist_ok=True)

            backed_up_count = 0

            for package in packages:
                package_dir = config_root / "home" / package
                if not package_dir.exists():
                    continue

                conflicts = self._check_package_conflicts(package_dir, home_dir)

                for conflict_path in conflicts:
                    source_path = home_dir / conflict_path
                    backup_path = backup_dir / conflict_path

                    # Ensure backup subdirectory exists
                    backup_path.parent.mkdir(parents=True, exist_ok=True)

                    if self.dry_run:
                        logger.dry_run(f"Would backup {source_path} to {backup_path}")
                    else:
                        # Move the conflicting file to backup
                        source_path.rename(backup_path)
                        logger.verbose(f"Backed up {conflict_path}")

                    backed_up_count += 1

            if backed_up_count > 0:
                logger.success(f"Backed up {backed_up_count} conflicting files to {backup_dir}")
            else:
                logger.info("No files needed backing up")

            return True

        except Exception as e:
            logger.error(f"Failed to backup conflicts: {e}")
            return False

    def restore_backups(self) -> bool:
        """Restore files from backup directory."""
        logger.substep("Restoring backed up files")

        try:
            home_dir = Path.home()
            backup_dir = home_dir / ".dotfiles-backup"

            if not backup_dir.exists():
                logger.info("No backup directory found")
                return True

            restored_count = 0

            for backup_file in backup_dir.rglob("*"):
                if backup_file.is_file():
                    relative_path = backup_file.relative_to(backup_dir)
                    target_path = home_dir / relative_path

                    if self.dry_run:
                        logger.dry_run(f"Would restore {backup_file} to {target_path}")
                    else:
                        # Ensure target directory exists
                        target_path.parent.mkdir(parents=True, exist_ok=True)

                        # Move backup file back
                        backup_file.rename(target_path)
                        logger.verbose(f"Restored {relative_path}")

                    restored_count += 1

            # Remove empty backup directory
            if not self.dry_run and backup_dir.exists():
                try:
                    backup_dir.rmdir()
                except OSError:
                    pass  # Directory not empty

            if restored_count > 0:
                logger.success(f"Restored {restored_count} files from backup")
            else:
                logger.info("No files to restore")

            return True

        except Exception as e:
            logger.error(f"Failed to restore backups: {e}")
            return False
