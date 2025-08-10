"""
Configuration management for the dotfiles setup system.
"""

import yaml
from pathlib import Path
from typing import Dict, List, Any, Optional
from .utils.logger import Logger

logger = Logger()


class ConfigManager:
    """Manages configuration loading and validation."""

    def __init__(self, config_root: Optional[Path] = None):
        self.config_root = config_root or Path(__file__).parent / "configs"
        self._packages_config = None
        self._apps_config = None
        self._settings_config = None

    def get_packages_config(self) -> Dict[str, Any]:
        """Get packages configuration."""
        if self._packages_config is None:
            self._packages_config = self._load_config("packages.yaml")
        return self._packages_config

    def get_apps_config(self) -> Dict[str, Any]:
        """Get applications configuration."""
        if self._apps_config is None:
            self._apps_config = self._load_config("apps.yaml")
        return self._apps_config

    def get_settings_config(self) -> Dict[str, Any]:
        """Get settings configuration."""
        if self._settings_config is None:
            self._settings_config = self._load_config("settings.yaml")
        return self._settings_config

    def _load_config(self, filename: str) -> Dict[str, Any]:
        """Load a YAML configuration file."""
        config_path = self.config_root / filename

        if not config_path.exists():
            logger.warning(f"Configuration file not found: {config_path}")
            return {}

        try:
            with open(config_path, 'r', encoding='utf-8') as f:
                config = yaml.safe_load(f) or {}
            logger.verbose(f"Loaded configuration: {filename}")
            return config
        except yaml.YAMLError as e:
            logger.error(f"Failed to parse YAML file {filename}: {e}")
            return {}
        except Exception as e:
            logger.error(f"Failed to load configuration {filename}: {e}")
            return {}

    def get_packages_for_platform(self, platform: str, category: Optional[str] = None) -> List[str]:
        """Get packages for a specific platform and optional category."""
        config = self.get_packages_config()
        packages = []

        # Add common packages
        common_packages = config.get("common", {})
        if category:
            packages.extend(common_packages.get(category, []))
        else:
            for cat_packages in common_packages.values():
                if isinstance(cat_packages, list):
                    packages.extend(cat_packages)

        # Add platform-specific packages
        platform_config = config.get("platforms", {}).get(platform, {})
        platform_packages = platform_config.get("packages", {})

        if category:
            packages.extend(platform_packages.get(category, []))
        else:
            for cat_packages in platform_packages.values():
                if isinstance(cat_packages, list):
                    packages.extend(cat_packages)

        return list(set(packages))  # Remove duplicates

    def get_apps_for_platform(self, platform: str, category: Optional[str] = None) -> List[str]:
        """Get applications for a specific platform and optional category."""
        config = self.get_apps_config()
        apps = []

        # Add common apps
        common_apps = config.get("common", {})
        if category:
            apps.extend(common_apps.get(category, []))
        else:
            for cat_apps in common_apps.values():
                if isinstance(cat_apps, list):
                    apps.extend(cat_apps)

        # Add platform-specific apps
        platform_config = config.get("platforms", {}).get(platform, {})
        platform_apps = platform_config.get("apps", {})

        if category:
            apps.extend(platform_apps.get(category, []))
        else:
            for cat_apps in platform_apps.values():
                if isinstance(cat_apps, list):
                    apps.extend(cat_apps)

        return list(set(apps))  # Remove duplicates

    def get_package_managers_for_platform(self, platform: str) -> List[str]:
        """Get package managers for a platform."""
        config = self.get_packages_config()
        platform_config = config.get("platforms", {}).get(platform, {})

        # Handle both single package manager and list
        managers = platform_config.get("package_manager") or platform_config.get("package_managers", [])
        if isinstance(managers, str):
            return [managers]
        return managers

    def get_flatpak_apps_for_platform(self, platform: str) -> List[str]:
        """Get Flatpak applications for a platform."""
        config = self.get_apps_config()
        platform_config = config.get("platforms", {}).get(platform, {})
        return platform_config.get("flatpaks", [])

    def get_repositories_for_platform(self, platform: str) -> Dict[str, Any]:
        """Get repositories configuration for a platform."""
        config = self.get_packages_config()
        platform_config = config.get("platforms", {}).get(platform, {})
        return platform_config.get("repositories", {})

    def get_copr_repos_for_platform(self, platform: str) -> List[str]:
        """Get COPR repositories for a platform."""
        repos = self.get_repositories_for_platform(platform)
        return repos.get("copr", [])

    def get_external_repos_for_platform(self, platform: str) -> Dict[str, Any]:
        """Get external repositories for a platform."""
        repos = self.get_repositories_for_platform(platform)
        return repos.get("external", {})

    def get_git_config_template(self) -> Dict[str, Any]:
        """Get Git configuration template."""
        settings = self.get_settings_config()
        return settings.get("git_config", {})

    def get_ssh_config(self) -> Dict[str, Any]:
        """Get SSH configuration."""
        settings = self.get_settings_config()
        return settings.get("ssh_config", {})

    def get_fonts_config(self) -> Dict[str, Any]:
        """Get fonts configuration."""
        settings = self.get_settings_config()
        return settings.get("fonts", {})

    def get_stow_packages(self) -> List[str]:
        """Get list of stow packages."""
        settings = self.get_settings_config()
        return settings.get("stow_packages", [
            "config", "git", "ssh", "vscode", "zsh", "wallpaper"
        ])

    def validate_platform(self, platform: str) -> bool:
        """Validate if a platform is supported."""
        config = self.get_packages_config()
        supported_platforms = list(config.get("platforms", {}).keys())
        return platform in supported_platforms

    def get_supported_platforms(self) -> List[str]:
        """Get list of supported platforms."""
        config = self.get_packages_config()
        return list(config.get("platforms", {}).keys())

    def reload_configs(self) -> None:
        """Reload all configurations from disk."""
        self._packages_config = None
        self._apps_config = None
        self._settings_config = None
        logger.info("Configuration reloaded")
