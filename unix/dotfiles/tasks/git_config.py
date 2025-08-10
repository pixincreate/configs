"""
Git configuration and SSH key setup.
"""

from typing import Dict, Any, Optional
from pathlib import Path
import subprocess
import requests
import json

from ..utils.logger import Logger
from ..utils.common import ShellExecutor, FileManager, validate_email
from ..utils.confirmation import ConfirmationManager, InteractiveMenu
from ..config import ConfigManager

logger = Logger()


class GitConfigurator:
    """Handles Git configuration and SSH key setup."""

    def __init__(self, config_manager: ConfigManager, shell: ShellExecutor,
                 file_manager: FileManager, confirmation_manager: ConfirmationManager,
                 dry_run: bool = False):
        self.config_manager = config_manager
        self.shell = shell
        self.file_manager = file_manager
        self.confirmation_manager = confirmation_manager
        self.dry_run = dry_run
        self.menu = InteractiveMenu()

    def setup_git(self) -> bool:
        """Setup Git configuration based on user choice."""
        logger.step("Setting up Git configuration")

        if not self.shell.command_exists("git"):
            logger.error("Git is not installed. Please install Git first.")
            return False

        # Show Git setup menu
        if not self.confirmation_manager.force:
            choice = self.menu.show_git_setup_menu()
        else:
            choice = "fresh"

        if choice == "skip":
            logger.info("Skipping Git setup")
            return True
        elif choice == "fresh":
            return self._fresh_git_setup()
        elif choice == "restore":
            return self._restore_git_setup()

        return False

    def _fresh_git_setup(self) -> bool:
        """Perform fresh Git setup with new SSH keys."""
        logger.substep("Performing fresh Git setup")

        try:
            # Get user information
            user_info = self._get_user_information()
            if not user_info:
                return False

            # Generate SSH keys
            if not self._generate_ssh_keys(user_info):
                return False

            # Setup Git configuration
            if not self._setup_git_config(user_info):
                return False

            # Setup GitHub integration
            if not self._setup_github_integration(user_info):
                logger.warning("GitHub integration setup failed, but Git is configured")

            # Convert repository remote to SSH
            if not self._convert_repo_to_ssh():
                logger.warning("Failed to convert repository remote to SSH")

            logger.success("Git setup completed successfully")
            return True

        except Exception as e:
            logger.error(f"Fresh Git setup failed: {e}")
            return False

    def _restore_git_setup(self) -> bool:
        """Restore existing Git configuration."""
        logger.substep("Restoring existing Git configuration")

        try:
            # Check if SSH keys exist
            ssh_dir = Path.home() / ".ssh"
            auth_key = ssh_dir / "id_ed25519_auth"
            sign_key = ssh_dir / "id_ed25519_sign"

            if not (auth_key.exists() and sign_key.exists()):
                logger.error("SSH keys not found. Please run fresh setup instead.")
                return False

            # Setup Git configuration with existing keys
            user_info = self._get_existing_git_config()
            if not user_info:
                logger.error("Unable to restore Git configuration")
                return False

            if not self._setup_git_config(user_info):
                return False

            # Ensure SSH keys have correct permissions
            self._fix_ssh_permissions()

            # Convert repository remote to SSH
            if not self._convert_repo_to_ssh():
                logger.warning("Failed to convert repository remote to SSH")

            logger.success("Git configuration restored successfully")
            return True

        except Exception as e:
            logger.error(f"Git restoration failed: {e}")
            return False

    def _get_user_information(self) -> Optional[Dict[str, str]]:
        """Get user information for Git setup."""
        logger.substep("Collecting user information")

        user_name = self.confirmation_manager.get_input(
            "Enter your Git user name:",
            validate_func=lambda x: len(x.strip()) > 0
        )

        user_email = self.confirmation_manager.get_input(
            "Enter your Git email:",
            validate_func=validate_email
        )

        github_email = self.confirmation_manager.get_input(
            "Enter your GitHub no-reply email:",
            default=f"{user_name.lower()}@users.noreply.github.com",
            validate_func=validate_email
        )

        if not all([user_name, user_email, github_email]):
            logger.error("All fields are required for Git setup")
            return None

        return {
            "name": user_name.strip(),
            "email": user_email.strip(),
            "github_email": github_email.strip()
        }

    def _get_existing_git_config(self) -> Optional[Dict[str, str]]:
        """Get existing Git configuration."""
        try:
            # Get name from global config
            result = self.shell.run(["git", "config", "--global", "user.name"], check=False)
            if result.returncode != 0:
                logger.error("No existing Git user.name found")
                return None
            name = result.stdout.strip()

            # Get email from global config
            result = self.shell.run(["git", "config", "--global", "user.email"], check=False)
            if result.returncode != 0:
                logger.error("No existing Git user.email found")
                return None
            email = result.stdout.strip()

            logger.info(f"Found existing Git configuration: {name} <{email}>")

            return {
                "name": name,
                "email": email,
                "github_email": email  # Use same email for GitHub
            }

        except Exception as e:
            logger.error(f"Failed to get existing Git configuration: {e}")
            return None

    def _generate_ssh_keys(self, user_info: Dict[str, str]) -> bool:
        """Generate SSH keys for authentication and signing."""
        logger.substep("Generating SSH keys")

        ssh_dir = Path.home() / ".ssh"
        self.file_manager.ensure_directory(ssh_dir)

        auth_key = ssh_dir / "id_ed25519_auth"
        sign_key = ssh_dir / "id_ed25519_sign"

        try:
            # Generate authentication key
            logger.verbose("Generating authentication key")
            auth_cmd = [
                "ssh-keygen", "-t", "ed25519",
                "-C", user_info["email"],
                "-f", str(auth_key),
                "-N", ""  # No passphrase
            ]
            self.shell.run_with_spinner(auth_cmd, "Generating authentication key")

            # Generate signing key
            logger.verbose("Generating signing key")
            sign_cmd = [
                "ssh-keygen", "-t", "ed25519",
                "-C", user_info["email"],
                "-f", str(sign_key),
                "-N", ""  # No passphrase
            ]
            self.shell.run_with_spinner(sign_cmd, "Generating signing key")

            # Set correct permissions
            self._fix_ssh_permissions()

            # Add keys to SSH agent
            self._add_keys_to_agent()

            logger.success("SSH keys generated successfully")
            return True

        except Exception as e:
            logger.error(f"Failed to generate SSH keys: {e}")
            return False

    def _fix_ssh_permissions(self):
        """Fix SSH key permissions."""
        ssh_dir = Path.home() / ".ssh"

        # Set directory permissions
        self.file_manager.set_permissions(ssh_dir, 0o700)

        # Set key permissions
        for key_file in ssh_dir.glob("id_ed25519*"):
            if key_file.suffix == ".pub":
                self.file_manager.set_permissions(key_file, 0o644)
            else:
                self.file_manager.set_permissions(key_file, 0o600)

    def _add_keys_to_agent(self):
        """Add SSH keys to the SSH agent."""
        logger.verbose("Adding SSH keys to agent")

        try:
            # Start SSH agent
            self.shell.run(["ssh-agent", "-s"], capture_output=False)

            # Add keys to agent
            ssh_dir = Path.home() / ".ssh"
            auth_key = ssh_dir / "id_ed25519_auth"
            sign_key = ssh_dir / "id_ed25519_sign"

            if auth_key.exists():
                self.shell.run(["ssh-add", str(auth_key)])
            if sign_key.exists():
                self.shell.run(["ssh-add", str(sign_key)])

        except Exception as e:
            logger.warning(f"Failed to add keys to SSH agent: {e}")

    def _setup_git_config(self, user_info: Dict[str, str]) -> bool:
        """Setup Git configuration files."""
        logger.substep("Setting up Git configuration")

        try:
            # Create .gitconfig.user file
            if not self._create_gitconfig_user(user_info):
                return False

            # Update main .gitconfig to include .gitconfig.user
            if not self._update_main_gitconfig():
                return False

            # Set global Git configuration
            self._set_global_git_config(user_info)

            return True

        except Exception as e:
            logger.error(f"Failed to setup Git configuration: {e}")
            return False

    def _create_gitconfig_user(self, user_info: Dict[str, str]) -> bool:
        """Create .gitconfig.user file with user-specific information."""
        gitconfig_user_path = Path.home() / ".gitconfig.user"

        ssh_dir = Path.home() / ".ssh"
        sign_key = ssh_dir / "id_ed25519_sign.pub"

        gitconfig_user_content = f"""[user]
name = {user_info['name']}
email = {user_info['github_email']}
signingkey = {sign_key}

[github]
user = {user_info['name']}
"""

        try:
            if self.dry_run:
                logger.dry_run(f"Would create .gitconfig.user with content:\n{gitconfig_user_content}")
            else:
                with open(gitconfig_user_path, 'w') as f:
                    f.write(gitconfig_user_content)
                logger.verbose(f"Created .gitconfig.user: {gitconfig_user_path}")

            return True

        except Exception as e:
            logger.error(f"Failed to create .gitconfig.user: {e}")
            return False

    def _update_main_gitconfig(self) -> bool:
        """Update main .gitconfig to include .gitconfig.user."""
        # The main .gitconfig should already be clean (from stow)
        # We just need to ensure it includes the user config

        gitconfig_path = Path.home() / ".gitconfig"

        if not gitconfig_path.exists():
            logger.warning(".gitconfig not found, it should be stowed first")
            return False

        # Check if include directive already exists
        try:
            with open(gitconfig_path, 'r') as f:
                content = f.read()

            include_line = "[include]\n\tpath = ~/.gitconfig.user"

            if "path = ~/.gitconfig.user" not in content:
                # Add include directive at the end
                updated_content = content.rstrip() + "\n\n" + include_line + "\n"

                if self.dry_run:
                    logger.dry_run(f"Would add include directive to .gitconfig")
                else:
                    with open(gitconfig_path, 'w') as f:
                        f.write(updated_content)
                    logger.verbose("Added include directive to .gitconfig")

            return True

        except Exception as e:
            logger.error(f"Failed to update .gitconfig: {e}")
            return False

    def _set_global_git_config(self, user_info: Dict[str, str]):
        """Set global Git configuration."""
        try:
            # Set user configuration
            self.shell.run(["git", "config", "--global", "user.name", user_info["name"]])
            self.shell.run(["git", "config", "--global", "user.email", user_info["github_email"]])

            # Set signing key
            ssh_dir = Path.home() / ".ssh"
            sign_key = ssh_dir / "id_ed25519_sign.pub"
            if sign_key.exists():
                self.shell.run(["git", "config", "--global", "user.signingkey", str(sign_key)])

            # Set additional Git configuration
            self.shell.run(["git", "config", "--global", "gpg.format", "ssh"])
            self.shell.run(["git", "config", "--global", "commit.gpgsign", "true"])
            self.shell.run(["git", "config", "--global", "pull.rebase", "false"])

            logger.success("Global Git configuration set")

        except Exception as e:
            logger.warning(f"Failed to set some global Git configuration: {e}")

    def _setup_github_integration(self, user_info: Dict[str, str]) -> bool:
        """Setup GitHub integration with SSH keys."""
        logger.substep("Setting up GitHub integration")

        # Show public keys to user
        self._show_ssh_public_keys()

        # Ask if user wants automatic upload
        if self.confirmation_manager.confirm("Upload SSH keys to GitHub automatically?", default=False):
            return self._upload_keys_to_github(user_info)
        else:
            logger.info("Manual key upload required - keys displayed above")
            return True

    def _show_ssh_public_keys(self):
        """Display SSH public keys for manual copying."""
        ssh_dir = Path.home() / ".ssh"
        auth_key_pub = ssh_dir / "id_ed25519_auth.pub"
        sign_key_pub = ssh_dir / "id_ed25519_sign.pub"

        logger.panel(
            "SSH Public Keys",
            "Copy these keys to GitHub → Settings → SSH and GPG keys",
            "yellow"
        )

        if auth_key_pub.exists():
            with open(auth_key_pub, 'r') as f:
                auth_content = f.read().strip()
            logger.info(f"Authentication Key:\n{auth_content}")

        if sign_key_pub.exists():
            with open(sign_key_pub, 'r') as f:
                sign_content = f.read().strip()
            logger.info(f"Signing Key:\n{sign_content}")

    def _upload_keys_to_github(self, user_info: Dict[str, str]) -> bool:
        """Upload SSH keys to GitHub via API."""
        try:
            token = self.confirmation_manager.get_password("Enter GitHub personal access token:")
            if not token:
                logger.warning("No token provided, skipping automatic upload")
                return False

            key_title = self.confirmation_manager.get_input(
                "Enter title for SSH keys:",
                default=f"{user_info['name']}-setup"
            )

            ssh_dir = Path.home() / ".ssh"
            auth_key_pub = ssh_dir / "id_ed25519_auth.pub"
            sign_key_pub = ssh_dir / "id_ed25519_sign.pub"

            success = True

            # Upload authentication key
            if auth_key_pub.exists():
                with open(auth_key_pub, 'r') as f:
                    auth_key_content = f.read().strip()

                if not self._upload_key_to_github(token, f"{key_title}-auth", auth_key_content):
                    success = False

            # Upload signing key
            if sign_key_pub.exists():
                with open(sign_key_pub, 'r') as f:
                    sign_key_content = f.read().strip()

                if not self._upload_key_to_github(token, f"{key_title}-sign", sign_key_content):
                    success = False

            if success:
                logger.success("SSH keys uploaded to GitHub successfully")
            else:
                logger.warning("Some keys failed to upload")

            return success

        except Exception as e:
            logger.error(f"Failed to upload keys to GitHub: {e}")
            return False

    def _upload_key_to_github(self, token: str, title: str, key_content: str) -> bool:
        """Upload a single SSH key to GitHub."""
        try:
            headers = {
                "Authorization": f"token {token}",
                "Accept": "application/vnd.github.v3+json"
            }

            data = {
                "title": title,
                "key": key_content
            }

            response = requests.post(
                "https://api.github.com/user/keys",
                headers=headers,
                json=data
            )

            if response.status_code == 201:
                logger.verbose(f"Uploaded key: {title}")
                return True
            else:
                logger.warning(f"Failed to upload key {title}: {response.status_code}")
                return False

        except Exception as e:
            logger.warning(f"Failed to upload key {title}: {e}")
            return False

    def _convert_repo_to_ssh(self) -> bool:
        """Convert the dotfiles repository remote from HTTPS to SSH."""
        logger.substep("Converting repository remote to SSH")

        try:
            config_root = Path.home() / "Dev" / ".configs"

            if not config_root.exists() or not (config_root / ".git").exists():
                logger.warning("Dotfiles repository not found")
                return False

            # Get current remote URL
            result = self.shell.run(
                ["git", "remote", "get-url", "origin"],
                cwd=config_root,
                check=False
            )

            if result.returncode != 0:
                logger.warning("No origin remote found")
                return False

            current_url = result.stdout.strip()
            logger.verbose(f"Current remote URL: {current_url}")

            # Convert HTTPS to SSH if needed
            if current_url.startswith("https://github.com/"):
                ssh_url = current_url.replace("https://github.com/", "git@github.com:")

                self.shell.run(
                    ["git", "remote", "set-url", "origin", ssh_url],
                    cwd=config_root
                )

                logger.success(f"Remote URL updated to SSH: {ssh_url}")
            else:
                logger.info("Remote URL already uses SSH or custom protocol")

            return True

        except Exception as e:
            logger.error(f"Failed to convert repository remote: {e}")
            return False
