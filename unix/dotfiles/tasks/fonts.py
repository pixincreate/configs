"""
Fonts and wallpapers installation.
"""

from typing import List, Dict, Any, Optional
from pathlib import Path
import shutil

from ..utils.logger import Logger
from ..utils.common import ShellExecutor, FileManager
from ..utils.confirmation import ConfirmationManager
from ..config import ConfigManager

logger = Logger()


class FontsInstaller:
    """Handles fonts and wallpapers installation."""

    def __init__(self, config_manager: ConfigManager, shell: ShellExecutor,
                 file_manager: FileManager, confirmation_manager: ConfirmationManager,
                 dry_run: bool = False):
        self.config_manager = config_manager
        self.shell = shell
        self.file_manager = file_manager
        self.confirmation_manager = confirmation_manager
        self.dry_run = dry_run

    def install_all(self) -> bool:
        """Install fonts and setup wallpapers."""
        logger.step("Installing fonts and setting up wallpapers")

        success = True

        # Install fonts
        if not self._install_fonts():
            success = False

        # Setup wallpapers
        if not self._setup_wallpapers():
            success = False

        return success

    def _install_fonts(self) -> bool:
        """Install fonts to the system."""
        logger.substep("Installing fonts")

        try:
            settings = self.config_manager.get_settings_config()
            fonts_config = settings.get("fonts", {})

            # Get source and destination paths
            config_root = Path.home() / "Dev" / ".configs"
            fonts_source = config_root / fonts_config.get("source_dir", "fonts")
            fonts_dest = Path(fonts_config.get("install_dir", "~/.local/share/fonts")).expanduser()

            if not fonts_source.exists():
                logger.warning(f"Fonts source directory not found: {fonts_source}")
                return True  # Not a failure, just no fonts to install

            # Ensure destination directory exists
            self.file_manager.ensure_directory(fonts_dest)

            # Get list of font files
            font_extensions = {".ttf", ".otf", ".woff", ".woff2"}
            font_files = [
                f for f in fonts_source.rglob("*")
                if f.is_file() and f.suffix.lower() in font_extensions
            ]

            if not font_files:
                logger.info("No font files found to install")
                return True

            logger.substep(f"Installing {len(font_files)} font files")

            # Copy fonts to destination
            installed_count = 0
            for font_file in font_files:
                try:
                    dest_file = fonts_dest / font_file.name

                    # Skip if already exists and identical
                    if dest_file.exists() and self._files_identical(font_file, dest_file):
                        logger.verbose(f"Font already installed: {font_file.name}")
                        continue

                    # Copy font file
                    if self.dry_run:
                        logger.dry_run(f"Would install font: {font_file.name}")
                    else:
                        shutil.copy2(font_file, dest_file)
                        logger.verbose(f"Installed font: {font_file.name}")

                    installed_count += 1

                except Exception as e:
                    logger.warning(f"Failed to install font {font_file.name}: {e}")

            if installed_count > 0:
                logger.success(f"Installed {installed_count} fonts")

                # Update font cache
                if fonts_config.get("update_font_cache", True):
                    self._update_font_cache()
            else:
                logger.info("All fonts are already installed")

            return True

        except Exception as e:
            logger.error(f"Font installation failed: {e}")
            return False

    def _files_identical(self, file1: Path, file2: Path) -> bool:
        """Check if two files are identical."""
        try:
            if file1.stat().st_size != file2.stat().st_size:
                return False

            # Compare file contents for small files
            if file1.stat().st_size < 1024 * 1024:  # 1MB
                return file1.read_bytes() == file2.read_bytes()

            # For larger files, just check size and modification time
            return file1.stat().st_mtime == file2.stat().st_mtime

        except Exception:
            return False

    def _update_font_cache(self):
        """Update the system font cache."""
        logger.substep("Updating font cache")

        try:
            if self.shell.command_exists("fc-cache"):
                self.shell.run_with_spinner(["fc-cache", "-f", "-v"], "Updating font cache")
                logger.success("Font cache updated")
            else:
                logger.verbose("fc-cache not available, skipping font cache update")

        except Exception as e:
            logger.warning(f"Failed to update font cache: {e}")

    def _setup_wallpapers(self) -> bool:
        """Setup wallpapers directory and copy wallpapers."""
        logger.substep("Setting up wallpapers")

        try:
            settings = self.config_manager.get_settings_config()
            wallpapers_config = settings.get("wallpapers", {})

            # Get source and destination paths
            config_root = Path.home() / "Dev" / ".configs"
            wallpapers_source = config_root / wallpapers_config.get("source_dir", "home/Wallpaper")
            wallpapers_dest = Path(wallpapers_config.get("install_dir", "~/Pictures/Wallpapers")).expanduser()
            screenshots_dir = Path(wallpapers_config.get("screenshots_dir", "~/Pictures/Screenshots")).expanduser()

            # Ensure directories exist
            self.file_manager.ensure_directory(wallpapers_dest)
            self.file_manager.ensure_directory(screenshots_dir)

            if not wallpapers_source.exists():
                logger.verbose(f"Wallpapers source directory not found: {wallpapers_source}")
                logger.info("Wallpapers directories created, but no wallpapers to copy")
                return True

            # Get list of wallpaper files
            image_extensions = {".jpg", ".jpeg", ".png", ".bmp", ".gif", ".webp", ".svg"}
            wallpaper_files = [
                f for f in wallpapers_source.rglob("*")
                if f.is_file() and f.suffix.lower() in image_extensions
            ]

            if not wallpaper_files:
                logger.info("No wallpaper files found to copy")
                return True

            logger.substep(f"Copying {len(wallpaper_files)} wallpaper files")

            # Copy wallpapers to destination
            copied_count = 0
            for wallpaper_file in wallpaper_files:
                try:
                    # Preserve relative directory structure
                    relative_path = wallpaper_file.relative_to(wallpapers_source)
                    dest_file = wallpapers_dest / relative_path

                    # Ensure destination subdirectory exists
                    self.file_manager.ensure_directory(dest_file.parent)

                    # Skip if already exists and identical
                    if dest_file.exists() and self._files_identical(wallpaper_file, dest_file):
                        logger.verbose(f"Wallpaper already copied: {relative_path}")
                        continue

                    # Copy wallpaper file
                    if self.dry_run:
                        logger.dry_run(f"Would copy wallpaper: {relative_path}")
                    else:
                        shutil.copy2(wallpaper_file, dest_file)
                        logger.verbose(f"Copied wallpaper: {relative_path}")

                    copied_count += 1

                except Exception as e:
                    logger.warning(f"Failed to copy wallpaper {wallpaper_file.name}: {e}")

            if copied_count > 0:
                logger.success(f"Copied {copied_count} wallpapers to {wallpapers_dest}")
            else:
                logger.info("All wallpapers are already in place")

            return True

        except Exception as e:
            logger.error(f"Wallpaper setup failed: {e}")
            return False

    def list_installed_fonts(self) -> List[str]:
        """List currently installed fonts."""
        try:
            settings = self.config_manager.get_settings_config()
            fonts_config = settings.get("fonts", {})
            fonts_dest = Path(fonts_config.get("install_dir", "~/.local/share/fonts")).expanduser()

            if not fonts_dest.exists():
                return []

            font_extensions = {".ttf", ".otf", ".woff", ".woff2"}
            font_files = [
                f.name for f in fonts_dest.rglob("*")
                if f.is_file() and f.suffix.lower() in font_extensions
            ]

            return sorted(font_files)

        except Exception as e:
            logger.error(f"Failed to list installed fonts: {e}")
            return []

    def list_available_wallpapers(self) -> List[str]:
        """List available wallpapers."""
        try:
            settings = self.config_manager.get_settings_config()
            wallpapers_config = settings.get("wallpapers", {})
            wallpapers_dest = Path(wallpapers_config.get("install_dir", "~/Pictures/Wallpapers")).expanduser()

            if not wallpapers_dest.exists():
                return []

            image_extensions = {".jpg", ".jpeg", ".png", ".bmp", ".gif", ".webp", ".svg"}
            wallpaper_files = [
                str(f.relative_to(wallpapers_dest)) for f in wallpapers_dest.rglob("*")
                if f.is_file() and f.suffix.lower() in image_extensions
            ]

            return sorted(wallpaper_files)

        except Exception as e:
            logger.error(f"Failed to list available wallpapers: {e}")
            return []

    def cleanup_old_fonts(self) -> bool:
        """Remove old or duplicate fonts."""
        logger.substep("Cleaning up old fonts")

        try:
            settings = self.config_manager.get_settings_config()
            fonts_config = settings.get("fonts", {})
            fonts_dest = Path(fonts_config.get("install_dir", "~/.local/share/fonts")).expanduser()

            if not fonts_dest.exists():
                logger.info("Fonts directory doesn't exist, nothing to clean")
                return True

            # This is a placeholder for more sophisticated cleanup logic
            # For now, we just remove broken symlinks and empty directories

            removed_count = 0

            # Remove broken symlinks
            for symlink in fonts_dest.rglob("*"):
                if symlink.is_symlink() and not symlink.exists():
                    if self.dry_run:
                        logger.dry_run(f"Would remove broken symlink: {symlink.name}")
                    else:
                        symlink.unlink()
                        logger.verbose(f"Removed broken symlink: {symlink.name}")
                    removed_count += 1

            # Remove empty directories
            for directory in fonts_dest.rglob("*"):
                if directory.is_dir() and not any(directory.iterdir()):
                    if self.dry_run:
                        logger.dry_run(f"Would remove empty directory: {directory.name}")
                    else:
                        directory.rmdir()
                        logger.verbose(f"Removed empty directory: {directory.name}")
                    removed_count += 1

            if removed_count > 0:
                logger.success(f"Cleaned up {removed_count} items")
                # Update font cache after cleanup
                if fonts_config.get("update_font_cache", True):
                    self._update_font_cache()
            else:
                logger.info("No cleanup needed")

            return True

        except Exception as e:
            logger.error(f"Font cleanup failed: {e}")
            return False
