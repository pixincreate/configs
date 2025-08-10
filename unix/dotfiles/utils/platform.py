"""
Platform detection utilities for cross-platform compatibility.
"""

import platform
import sys
import os
from pathlib import Path
from typing import Optional, Dict, Any


class PlatformDetector:
    """Detects the current platform and provides platform-specific information."""

    def __init__(self, platform_override: Optional[str] = None):
        self.platform_override = platform_override
        self._platform_info = None

    def get_platform(self) -> str:
        """Get the current platform identifier."""
        if self.platform_override:
            return self.platform_override.lower()

        system = platform.system().lower()

        if system == "darwin":
            return "macos"
        elif system == "linux":
            return self._detect_linux_distribution()
        else:
            raise ValueError(f"Unsupported platform: {system}")

    def _detect_linux_distribution(self) -> str:
        """Detect the specific Linux distribution."""
        # Check for Android (Termux)
        if "com.termux" in os.environ.get("PREFIX", ""):
            return "android"

        # Check for WSL
        wsl_distro = os.environ.get("WSL_DISTRO_NAME", "").lower()
        if wsl_distro:
            if "debian" in wsl_distro:
                return "debian"
            elif "fedora" in wsl_distro:
                return "fedora"

        # Check release files
        if Path("/etc/fedora-release").exists():
            return "fedora"
        elif Path("/etc/debian_version").exists():
            return "debian"
        elif Path("/etc/arch-release").exists():
            return "arch"
        elif Path("/etc/alpine-release").exists():
            return "alpine"
        else:
            # Default to debian for unknown Linux distributions
            return "debian"

    def get_platform_info(self) -> Dict[str, Any]:
        """Get detailed platform information."""
        if self._platform_info is None:
            self._platform_info = self._gather_platform_info()
        return self._platform_info

    def _gather_platform_info(self) -> Dict[str, Any]:
        """Gather detailed platform information."""
        current_platform = self.get_platform()

        info = {
            "platform": current_platform,
            "system": platform.system(),
            "machine": platform.machine(),
            "python_version": platform.python_version(),
            "home_dir": Path.home(),
            "config_dir": self._get_config_dir(),
            "is_wsl": self._is_wsl(),
            "package_managers": self._get_package_managers(current_platform),
            "shell": self._get_default_shell(),
        }

        # Platform-specific information
        if current_platform == "macos":
            info.update(self._get_macos_info())
        elif current_platform == "fedora":
            info.update(self._get_fedora_info())
        elif current_platform == "debian":
            info.update(self._get_debian_info())
        elif current_platform == "android":
            info.update(self._get_android_info())

        return info

    def _get_config_dir(self) -> Path:
        """Get the configuration directory for the current platform."""
        if self.get_platform() == "macos":
            return Path.home() / "Library" / "Application Support"
        else:
            return Path.home() / ".config"

    def _is_wsl(self) -> bool:
        """Check if running in Windows Subsystem for Linux."""
        return "WSL" in os.environ or "microsoft" in platform.release().lower()

    def _get_package_managers(self, platform: str) -> list:
        """Get available package managers for the platform."""
        managers = {
            "macos": ["brew"],
            "fedora": ["dnf", "flatpak", "rpm"],
            "debian": ["apt", "dpkg"],
            "android": ["pkg"],
            "arch": ["pacman", "yay"],
            "alpine": ["apk"]
        }
        return managers.get(platform, [])

    def _get_default_shell(self) -> str:
        """Get the default shell for the current user."""
        return os.environ.get("SHELL", "/bin/bash")

    def _get_macos_info(self) -> Dict[str, Any]:
        """Get macOS-specific information."""
        return {
            "macos_version": platform.mac_ver()[0],
            "homebrew_prefix": self._get_homebrew_prefix(),
            "code_dir": Path.home() / "Library" / "Application Support" / "Code",
        }

    def _get_fedora_info(self) -> Dict[str, Any]:
        """Get Fedora-specific information."""
        info = {"code_dir": Path.home() / ".config" / "Code"}

        try:
            with open("/etc/fedora-release", "r") as f:
                release = f.read().strip()
                info["fedora_version"] = release
        except FileNotFoundError:
            pass

        return info

    def _get_debian_info(self) -> Dict[str, Any]:
        """Get Debian-specific information."""
        info = {"code_dir": Path.home() / ".config" / "Code"}

        try:
            with open("/etc/debian_version", "r") as f:
                version = f.read().strip()
                info["debian_version"] = version
        except FileNotFoundError:
            pass

        return info

    def _get_android_info(self) -> Dict[str, Any]:
        """Get Android (Termux) specific information."""
        return {
            "termux_prefix": os.environ.get("PREFIX", "/data/data/com.termux/files/usr"),
            "storage_setup_required": not Path("/storage/emulated/0").exists(),
            "rish_dir": Path.home() / ".rish",
        }

    def _get_homebrew_prefix(self) -> Optional[str]:
        """Get Homebrew prefix path."""
        if self.get_platform() == "macos":
            if platform.machine() == "arm64":
                return "/opt/homebrew"
            else:
                return "/usr/local"
        elif self.get_platform() in ["debian", "fedora"]:
            return "/home/linuxbrew/.linuxbrew"
        return None

    def is_supported_platform(self) -> bool:
        """Check if the current platform is supported."""
        supported = ["macos", "fedora", "debian", "android", "arch"]
        return self.get_platform() in supported

    def get_paths(self) -> Dict[str, Path]:
        """Get important paths for the current platform."""
        home = Path.home()
        platform_name = self.get_platform()

        paths = {
            "home": home,
            "config_root": home / "Dev" / ".configs",
            "fonts_dir": home / ".local" / "share" / "fonts",
            "wallpapers_dir": home / "Pictures" / "Wallpapers",
            "screenshots_dir": home / "Pictures" / "Screenshots",
            "ssh_dir": home / ".ssh",
            "zsh_dir": home / ".zsh",
        }

        # Platform-specific paths
        if platform_name == "android":
            paths["rish_dir"] = home / ".rish"
            paths["storage_root"] = Path("/storage/emulated/0")
            paths["termux_storage"] = paths["storage_root"] / "Documents" / "Dev"

        return paths

    def __str__(self) -> str:
        """String representation of platform info."""
        return f"Platform: {self.get_platform()}"

    def __repr__(self) -> str:
        """Detailed string representation."""
        info = self.get_platform_info()
        return f"PlatformDetector(platform='{info['platform']}', system='{info['system']}')"
