"""
User confirmation and interactive menu utilities.
"""

import inquirer
from rich.console import Console
from rich.panel import Panel
from rich.table import Table
from rich.text import Text
from typing import List, Dict, Any, Optional
import sys

console = Console()


class ConfirmationManager:
    """Manages user confirmations and interactive prompts."""

    def __init__(self, force: bool = False, dry_run: bool = False):
        self.force = force
        self.dry_run = dry_run

    def confirm(self, message: str, default: bool = True) -> bool:
        """Ask for user confirmation."""
        if self.force:
            return True

        if self.dry_run:
            console.print(f"[yellow][DRY RUN][/yellow] Would ask: {message}")
            return True

        try:
            return inquirer.confirm(message, default=default)
        except KeyboardInterrupt:
            console.print("\n[yellow]Operation cancelled by user[/yellow]")
            sys.exit(0)

    def select_from_list(self, message: str, choices: List[str], default: Optional[str] = None) -> str:
        """Select from a list of choices."""
        if self.force and default:
            return default

        if self.dry_run:
            console.print(f"[yellow][DRY RUN][/yellow] Would ask: {message}")
            return default or choices[0]

        try:
            questions = [
                inquirer.List('choice',
                             message=message,
                             choices=choices,
                             default=default)
            ]
            answers = inquirer.prompt(questions)
            return answers['choice'] if answers else (default or choices[0])
        except KeyboardInterrupt:
            console.print("\n[yellow]Operation cancelled by user[/yellow]")
            sys.exit(0)

    def multi_select(self, message: str, choices: List[str], default: Optional[List[str]] = None) -> List[str]:
        """Select multiple items from a list."""
        if self.force and default:
            return default

        if self.dry_run:
            console.print(f"[yellow][DRY RUN][/yellow] Would ask: {message}")
            return default or []

        try:
            questions = [
                inquirer.Checkbox('choices',
                                 message=message,
                                 choices=choices,
                                 default=default or [])
            ]
            answers = inquirer.prompt(questions)
            return answers['choices'] if answers else (default or [])
        except KeyboardInterrupt:
            console.print("\n[yellow]Operation cancelled by user[/yellow]")
            sys.exit(0)

    def get_input(self, message: str, default: Optional[str] = None, validate_func=None) -> str:
        """Get text input from user."""
        if self.force and default:
            return default

        if self.dry_run:
            console.print(f"[yellow][DRY RUN][/yellow] Would ask: {message}")
            return default or "dummy_input"

        try:
            questions = [
                inquirer.Text('input',
                             message=message,
                             default=default or "",
                             validate=validate_func)
            ]
            answers = inquirer.prompt(questions)
            return answers['input'] if answers else (default or "")
        except KeyboardInterrupt:
            console.print("\n[yellow]Operation cancelled by user[/yellow]")
            sys.exit(0)

    def get_password(self, message: str) -> str:
        """Get password input from user."""
        if self.force:
            return "dummy_password"

        if self.dry_run:
            console.print(f"[yellow][DRY RUN][/yellow] Would ask: {message}")
            return "dummy_password"

        try:
            questions = [
                inquirer.Password('password', message=message)
            ]
            answers = inquirer.prompt(questions)
            return answers['password'] if answers else ""
        except KeyboardInterrupt:
            console.print("\n[yellow]Operation cancelled by user[/yellow]")
            sys.exit(0)


class InteractiveMenu:
    """Provides interactive menu interfaces."""

    def __init__(self):
        self.console = Console()

    def show_main_menu(self) -> str:
        """Show the main setup menu."""
        choices = [
            ("📦 Install packages & applications", "install"),
            ("⚙️ Setup Git configuration", "git"),
            ("🎨 Install fonts & wallpapers", "fonts"),
            ("🐚 Setup Zsh configuration", "zsh"),
            ("🔗 Stow configurations", "stow"),
            ("🔧 Miscellaneous setup", "misc"),
            ("🚀 Full setup (everything)", "full"),
            ("❌ Exit", "exit")
        ]

        try:
            questions = [
                inquirer.List('choice',
                             message="What would you like to do?",
                             choices=choices)
            ]
            answers = inquirer.prompt(questions)
            return answers['choice'] if answers else "exit"
        except KeyboardInterrupt:
            return "exit"

    def show_package_menu(self, platform: str) -> List[str]:
        """Show package selection menu."""
        base_choices = [
            ("Common terminal tools", "common_terminal"),
            ("Development tools", "development"),
            ("Media tools", "media"),
        ]

        platform_specific = {
            "macos": [("macOS applications", "macos_apps")],
            "fedora": [
                ("Fedora packages", "fedora_packages"),
                ("Flatpak applications", "flatpak_apps")
            ],
            "debian": [("Debian packages", "debian_packages")],
            "android": [("Android/Termux packages", "android_packages")]
        }

        choices = base_choices + platform_specific.get(platform, [])
        choices.append(("All packages", "all"))

        try:
            questions = [
                inquirer.Checkbox('packages',
                                 message="Select package categories to install:",
                                 choices=choices,
                                 default=["all"])
            ]
            answers = inquirer.prompt(questions)
            return answers['packages'] if answers else ["all"]
        except KeyboardInterrupt:
            return []

    def show_git_setup_menu(self) -> str:
        """Show Git setup options."""
        choices = [
            ("Fresh setup (new SSH keys, configure Git)", "fresh"),
            ("Restore existing (use existing SSH keys)", "restore"),
            ("Skip Git setup", "skip")
        ]

        try:
            questions = [
                inquirer.List('choice',
                             message="Git configuration options:",
                             choices=choices)
            ]
            answers = inquirer.prompt(questions)
            return answers['choice'] if answers else "skip"
        except KeyboardInterrupt:
            return "skip"

    def show_stow_menu(self) -> List[str]:
        """Show stow package selection menu."""
        choices = [
            ("Git configuration", "git"),
            ("SSH configuration", "ssh"),
            ("Zsh configuration", "zsh"),
            ("VS Code settings", "vscode"),
            ("General config files", "config"),
            ("Wallpapers", "wallpaper"),
            ("All configurations", "all")
        ]

        try:
            questions = [
                inquirer.Checkbox('packages',
                                 message="Select configurations to stow:",
                                 choices=choices,
                                 default=["all"])
            ]
            answers = inquirer.prompt(questions)
            return answers['packages'] if answers else ["all"]
        except KeyboardInterrupt:
            return []

    def confirm_full_setup(self) -> bool:
        """Confirm full setup execution."""
        panel_content = """This will run the complete setup process:

• Install packages and applications
• Setup Git configuration (with SSH keys)
• Install fonts and wallpapers
• Setup Zsh configuration
• Stow all configuration files
• Run miscellaneous setup tasks

This may take several minutes and will make changes to your system.
"""
        panel = Panel(panel_content, title="[bold red]⚠️ Full Setup Confirmation[/bold red]", border_style="red")
        console.print(panel)

        try:
            return inquirer.confirm("Are you sure you want to proceed with full setup?", default=False)
        except KeyboardInterrupt:
            return False

    def continue_setup(self) -> bool:
        """Ask if user wants to continue with more setup tasks."""
        try:
            return inquirer.confirm("Would you like to perform another setup task?", default=True)
        except KeyboardInterrupt:
            return False

    def show_summary_table(self, completed_tasks: List[Dict[str, Any]]):
        """Show a summary table of completed tasks."""
        table = Table(title="Setup Summary", show_header=True, header_style="bold blue")
        table.add_column("Task", style="cyan", width=25)
        table.add_column("Status", width=15)
        table.add_column("Details", style="dim")

        for task in completed_tasks:
            status_style = "green" if task["success"] else "red"
            status_text = "✅ Success" if task["success"] else "❌ Failed"
            table.add_row(
                task["name"],
                f"[{status_style}]{status_text}[/{status_style}]",
                task.get("details", "")
            )

        console.print()
        console.print(table)
        console.print()

    def show_platform_info(self, platform_info: Dict[str, Any]):
        """Display platform information in a formatted panel."""
        content_lines = [
            f"Platform: {platform_info['platform']}",
            f"System: {platform_info['system']}",
            f"Architecture: {platform_info['machine']}",
            f"Python: {platform_info['python_version']}",
        ]

        if platform_info.get('is_wsl'):
            content_lines.append("Environment: WSL")

        if 'homebrew_prefix' in platform_info:
            content_lines.append(f"Homebrew: {platform_info['homebrew_prefix']}")

        content = "\n".join(content_lines)
        panel = Panel(content, title="Platform Information", border_style="blue")
        console.print(panel)
