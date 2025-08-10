"""
Common utility functions shared across the dotfiles setup system.
"""

import os
import shutil
import subprocess
from pathlib import Path
from typing import List, Dict, Any, Optional, Union
import sys

from .logger import Logger

logger = Logger()


class ShellExecutor:
    """Executes shell commands with proper error handling and logging."""

    def __init__(self, dry_run: bool = False):
        self.dry_run = dry_run

    def run(self, cmd: Union[str, List[str]],
            capture_output: bool = True,
            check: bool = True,
            cwd: Optional[Path] = None,
            env: Optional[Dict[str, str]] = None) -> subprocess.CompletedProcess:
        """Execute a shell command."""

        if isinstance(cmd, str):
            cmd_str = cmd
            cmd_list = cmd.split()
        else:
            cmd_str = " ".join(cmd)
            cmd_list = cmd

        logger.verbose(f"Executing: {cmd_str}")

        if self.dry_run:
            logger.dry_run(f"Would execute: {cmd_str}")
            # Return a mock result for dry run
            return subprocess.CompletedProcess(
                args=cmd_list,
                returncode=0,
                stdout="dry_run_output",
                stderr=""
            )

        try:
            result = subprocess.run(
                cmd_list,
                capture_output=capture_output,
                text=True,
                check=check,
                cwd=cwd,
                env=env
            )

            if result.stdout and logger.verbose_enabled:
                logger.verbose(f"Output: {result.stdout.strip()}")

            return result

        except subprocess.CalledProcessError as e:
            logger.error(f"Command failed: {cmd_str}")
            logger.error(f"Return code: {e.returncode}")
            if e.stderr:
                logger.error(f"Error output: {e.stderr}")
            raise
        except FileNotFoundError:
            logger.error(f"Command not found: {cmd_list[0]}")
            raise

    def run_with_spinner(self, cmd: Union[str, List[str]],
                        description: str = "Working...",
                        **kwargs) -> subprocess.CompletedProcess:
        """Execute a command with a spinner progress indicator."""

        if self.dry_run:
            return self.run(cmd, **kwargs)

        with logger.progress_spinner(description) as progress:
            task = progress.add_task(description, total=None)
            try:
                result = self.run(cmd, **kwargs)
                progress.update(task, description=f"✅ {description}")
                return result
            except Exception as e:
                progress.update(task, description=f"❌ {description}")
                raise

    def command_exists(self, command: str) -> bool:
        """Check if a command exists in the system PATH."""
        return shutil.which(command) is not None

    def get_command_path(self, command: str) -> Optional[str]:
        """Get the full path to a command."""
        return shutil.which(command)


class FileManager:
    """Manages file and directory operations."""

    def __init__(self, dry_run: bool = False):
        self.dry_run = dry_run

    def ensure_directory(self, path: Path) -> None:
        """Ensure a directory exists, creating it if necessary."""
        if self.dry_run:
            logger.dry_run(f"Would create directory: {path}")
            return

        try:
            path.mkdir(parents=True, exist_ok=True)
            logger.verbose(f"Directory ensured: {path}")
        except Exception as e:
            logger.error(f"Failed to create directory {path}: {e}")
            raise

    def copy_file(self, src: Path, dst: Path, backup: bool = True) -> None:
        """Copy a file, optionally creating a backup."""
        if self.dry_run:
            logger.dry_run(f"Would copy: {src} -> {dst}")
            return

        # Ensure destination directory exists
        self.ensure_directory(dst.parent)

        # Create backup if requested and destination exists
        if backup and dst.exists():
            backup_path = dst.with_suffix(dst.suffix + ".backup")
            logger.verbose(f"Creating backup: {dst} -> {backup_path}")
            shutil.copy2(dst, backup_path)

        try:
            shutil.copy2(src, dst)
            logger.verbose(f"File copied: {src} -> {dst}")
        except Exception as e:
            logger.error(f"Failed to copy file {src} to {dst}: {e}")
            raise

    def move_file(self, src: Path, dst: Path) -> None:
        """Move a file."""
        if self.dry_run:
            logger.dry_run(f"Would move: {src} -> {dst}")
            return

        # Ensure destination directory exists
        self.ensure_directory(dst.parent)

        try:
            shutil.move(str(src), str(dst))
            logger.verbose(f"File moved: {src} -> {dst}")
        except Exception as e:
            logger.error(f"Failed to move file {src} to {dst}: {e}")
            raise

    def delete_file(self, path: Path) -> None:
        """Delete a file."""
        if self.dry_run:
            logger.dry_run(f"Would delete: {path}")
            return

        try:
            if path.exists():
                path.unlink()
                logger.verbose(f"File deleted: {path}")
        except Exception as e:
            logger.error(f"Failed to delete file {path}: {e}")
            raise

    def set_permissions(self, path: Path, mode: int) -> None:
        """Set file permissions."""
        if self.dry_run:
            logger.dry_run(f"Would set permissions {oct(mode)} on: {path}")
            return

        try:
            path.chmod(mode)
            logger.verbose(f"Permissions set: {path} -> {oct(mode)}")
        except Exception as e:
            logger.error(f"Failed to set permissions on {path}: {e}")
            raise

    def create_symlink(self, target: Path, link: Path, force: bool = False) -> None:
        """Create a symbolic link."""
        if self.dry_run:
            logger.dry_run(f"Would create symlink: {link} -> {target}")
            return

        # Remove existing link if force is True
        if force and link.exists():
            self.delete_file(link)

        try:
            link.symlink_to(target)
            logger.verbose(f"Symlink created: {link} -> {target}")
        except Exception as e:
            logger.error(f"Failed to create symlink {link} -> {target}: {e}")
            raise


class GitHelper:
    """Git-related utility functions."""

    def __init__(self, shell_executor: ShellExecutor):
        self.shell = shell_executor

    def is_git_repo(self, path: Path) -> bool:
        """Check if a directory is a git repository."""
        return (path / ".git").exists()

    def clone_repo(self, url: str, destination: Path, branch: Optional[str] = None) -> None:
        """Clone a git repository."""
        cmd = ["git", "clone"]
        if branch:
            cmd.extend(["--branch", branch])
        cmd.extend(["--recurse-submodules", url, str(destination)])

        self.shell.run_with_spinner(cmd, f"Cloning repository {url}")

    def pull_repo(self, repo_path: Path) -> None:
        """Pull latest changes from a git repository."""
        cmd = ["git", "pull"]
        self.shell.run_with_spinner(cmd, "Pulling latest changes", cwd=repo_path)

    def update_submodules(self, repo_path: Path) -> None:
        """Update git submodules."""
        cmd = ["git", "submodule", "update", "--init", "--recursive"]
        self.shell.run_with_spinner(cmd, "Updating submodules", cwd=repo_path)

    def get_remote_url(self, repo_path: Path) -> str:
        """Get the remote URL of a git repository."""
        cmd = ["git", "remote", "get-url", "origin"]
        result = self.shell.run(cmd, cwd=repo_path)
        return result.stdout.strip()

    def set_remote_url(self, repo_path: Path, url: str) -> None:
        """Set the remote URL of a git repository."""
        cmd = ["git", "remote", "set-url", "origin", url]
        self.shell.run(cmd, cwd=repo_path)

    def is_repo_clean(self, repo_path: Path) -> bool:
        """Check if a git repository has no uncommitted changes."""
        cmd = ["git", "diff-index", "--quiet", "HEAD", "--"]
        try:
            self.shell.run(cmd, cwd=repo_path)
            return True
        except subprocess.CalledProcessError:
            return False


def validate_email(email: str) -> bool:
    """Validate email address format."""
    import re
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    return re.match(pattern, email) is not None


def get_home_directory() -> Path:
    """Get the user's home directory."""
    return Path.home()


def get_config_directory() -> Path:
    """Get the dotfiles configuration directory."""
    return get_home_directory() / "Dev" / ".configs"


def expand_path(path: str) -> Path:
    """Expand a path string to a full Path object."""
    return Path(path).expanduser().resolve()


def format_file_size(size_bytes: int) -> str:
    """Format file size in human-readable format."""
    for unit in ['B', 'KB', 'MB', 'GB']:
        if size_bytes < 1024.0:
            return f"{size_bytes:.1f} {unit}"
        size_bytes /= 1024.0
    return f"{size_bytes:.1f} TB"


def is_root() -> bool:
    """Check if running as root user."""
    return os.geteuid() == 0


def get_env_var(name: str, default: Optional[str] = None) -> Optional[str]:
    """Get environment variable with optional default."""
    return os.environ.get(name, default)


def set_env_var(name: str, value: str) -> None:
    """Set environment variable."""
    os.environ[name] = value
