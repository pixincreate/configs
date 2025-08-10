"""
Task manager for coordinating all setup tasks.
"""

from typing import List, Dict, Any, Optional
from pathlib import Path

from ..utils.logger import Logger
from ..utils.platform import PlatformDetector
from ..utils.confirmation import ConfirmationManager
from ..utils.common import ShellExecutor, FileManager
from ..config import ConfigManager

from .installer import PackageInstaller
from .git_config import GitConfigurator
from .fonts import FontsInstaller
from .zsh import ZshConfigurator
from .stow import StowManager
from .misc import MiscSetup

logger = Logger()


class TaskManager:
    """Manages and coordinates all setup tasks."""

    def __init__(self, platform: str, config_manager: ConfigManager,
                 confirmation_manager: ConfirmationManager, dry_run: bool = False):
        self.platform = platform
        self.config_manager = config_manager
        self.confirmation_manager = confirmation_manager
        self.dry_run = dry_run

        # Initialize utilities
        self.shell = ShellExecutor(dry_run=dry_run)
        self.file_manager = FileManager(dry_run=dry_run)

        # Initialize task modules
        self.package_installer = PackageInstaller(
            platform=platform,
            config_manager=config_manager,
            shell=self.shell,
            confirmation_manager=confirmation_manager,
            dry_run=dry_run
        )

        self.git_configurator = GitConfigurator(
            config_manager=config_manager,
            shell=self.shell,
            file_manager=self.file_manager,
            confirmation_manager=confirmation_manager,
            dry_run=dry_run
        )

        self.fonts_installer = FontsInstaller(
            config_manager=config_manager,
            shell=self.shell,
            file_manager=self.file_manager,
            confirmation_manager=confirmation_manager,
            dry_run=dry_run
        )

        self.zsh_configurator = ZshConfigurator(
            platform=platform,
            config_manager=config_manager,
            shell=self.shell,
            file_manager=self.file_manager,
            confirmation_manager=confirmation_manager,
            dry_run=dry_run
        )

        self.stow_manager = StowManager(
            config_manager=config_manager,
            shell=self.shell,
            confirmation_manager=confirmation_manager,
            dry_run=dry_run
        )

        self.misc_setup = MiscSetup(
            platform=platform,
            config_manager=config_manager,
            shell=self.shell,
            file_manager=self.file_manager,
            confirmation_manager=confirmation_manager,
            dry_run=dry_run
        )

        # Track completed tasks
        self.completed_tasks: List[Dict[str, Any]] = []

    def run_full_setup(self) -> bool:
        """Run the complete setup process."""
        logger.step("Starting full setup process")

        tasks = [
            ("Setup directories", self._setup_directories),
            ("Install packages & applications", self.run_installer),
            ("Setup Git configuration", self.run_git_setup),
            ("Install fonts & wallpapers", self.run_fonts_setup),
            ("Setup Zsh configuration", self.run_zsh_setup),
            ("Stow configurations", self.run_stow_setup),
            ("Miscellaneous setup", self.run_misc_setup),
        ]

        success_count = 0
        for task_name, task_func in tasks:
            try:
                logger.step(f"Running: {task_name}")
                success = task_func()
                if success:
                    success_count += 1
                    self._record_task(task_name, True)
                    logger.success(f"Completed: {task_name}")
                else:
                    self._record_task(task_name, False, "Task returned False")
                    logger.warning(f"Failed: {task_name}")
            except Exception as e:
                self._record_task(task_name, False, str(e))
                logger.error(f"Error in {task_name}: {e}")

        logger.separator()
        if success_count == len(tasks):
            logger.success("🎉 Full setup completed successfully!")
        else:
            logger.warning(f"Setup completed with {len(tasks) - success_count} failures")

        self._show_summary()
        return success_count == len(tasks)

    def run_installer(self) -> bool:
        """Run package and application installation."""
        logger.step("Running package installer")
        try:
            return self.package_installer.install_all()
        except Exception as e:
            logger.error(f"Package installation failed: {e}")
            return False

    def run_git_setup(self) -> bool:
        """Run Git configuration setup."""
        logger.step("Running Git setup")
        try:
            return self.git_configurator.setup_git()
        except Exception as e:
            logger.error(f"Git setup failed: {e}")
            return False

    def run_fonts_setup(self) -> bool:
        """Run fonts and wallpapers installation."""
        logger.step("Running fonts setup")
        try:
            return self.fonts_installer.install_all()
        except Exception as e:
            logger.error(f"Fonts setup failed: {e}")
            return False

    def run_zsh_setup(self) -> bool:
        """Run Zsh configuration setup."""
        logger.step("Running Zsh setup")
        try:
            return self.zsh_configurator.setup_zsh()
        except Exception as e:
            logger.error(f"Zsh setup failed: {e}")
            return False

    def run_stow_setup(self) -> bool:
        """Run stow configuration management."""
        logger.step("Running stow setup")
        try:
            return self.stow_manager.stow_all()
        except Exception as e:
            logger.error(f"Stow setup failed: {e}")
            return False

    def run_misc_setup(self) -> bool:
        """Run miscellaneous setup tasks."""
        logger.step("Running miscellaneous setup")
        try:
            return self.misc_setup.run_all()
        except Exception as e:
            logger.error(f"Miscellaneous setup failed: {e}")
            return False

    def _setup_directories(self) -> bool:
        """Setup required directories."""
        try:
            settings = self.config_manager.get_settings_config()
            directories = settings.get("directories", {})

            # Get base directories to create
            base_dirs = directories.get("ensure_directories", [])
            dirs_to_create = [Path(d).expanduser() for d in base_dirs]

            # Add platform-specific directories
            if self.platform == "android":
                android_dirs = directories.get("android_directories", [])
                dirs_to_create.extend([Path(d).expanduser() for d in android_dirs])

            for directory in dirs_to_create:
                self.file_manager.ensure_directory(directory)

            return True
        except Exception as e:
            logger.error(f"Failed to setup directories: {e}")
            return False

    def _record_task(self, name: str, success: bool, details: str = "") -> None:
        """Record a completed task."""
        self.completed_tasks.append({
            "name": name,
            "success": success,
            "details": details
        })

    def _show_summary(self) -> None:
        """Show a summary of completed tasks."""
        if not self.completed_tasks:
            return

        from ..utils.confirmation import InteractiveMenu
        menu = InteractiveMenu()
        menu.show_summary_table(self.completed_tasks)

    def get_task_status(self) -> Dict[str, Any]:
        """Get the status of all tasks."""
        total_tasks = len(self.completed_tasks)
        successful_tasks = sum(1 for task in self.completed_tasks if task["success"])

        return {
            "total_tasks": total_tasks,
            "successful_tasks": successful_tasks,
            "failed_tasks": total_tasks - successful_tasks,
            "success_rate": (successful_tasks / total_tasks * 100) if total_tasks > 0 else 0,
            "tasks": self.completed_tasks
        }

    def cleanup_on_failure(self) -> None:
        """Cleanup operations in case of failure."""
        logger.warning("Performing cleanup operations...")

        # This could include:
        # - Removing partially installed packages
        # - Restoring backup files
        # - Cleaning up temporary files
        # For now, just log the intent

        logger.info("Cleanup completed")
