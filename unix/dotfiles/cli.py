#!/usr/bin/env python3
"""
Main CLI interface for the dotfiles setup assistant.
"""

import click
from rich.console import Console
from rich.panel import Panel
from rich.text import Text
from pathlib import Path
import sys
import os

from .utils.logger import Logger
from .utils.platform import PlatformDetector
from .utils.confirmation import ConfirmationManager
from .config import ConfigManager
from .tasks import TaskManager

console = Console()
logger = Logger()


@click.command()
@click.option('--full-setup', is_flag=True, help='Run complete setup without prompts')
@click.option('--install-packages', is_flag=True, help='Install packages and applications')
@click.option('--setup-git', is_flag=True, help='Setup Git configuration')
@click.option('--setup-fonts', is_flag=True, help='Install fonts and wallpapers')
@click.option('--setup-zsh', is_flag=True, help='Setup Zsh configuration')
@click.option('--stow-configs', is_flag=True, help='Stow configuration files')
@click.option('--misc-setup', is_flag=True, help='Run miscellaneous setup tasks')
@click.option('--dry-run', is_flag=True, help='Show what would be done without executing')
@click.option('--force', is_flag=True, help='Run without confirmations')
@click.option('--platform', help='Override platform detection')
@click.option('--verbose', '-v', is_flag=True, help='Enable verbose logging')
@click.option('--debug', is_flag=True, help='Enable debug logging')
def main(full_setup, install_packages, setup_git, setup_fonts, setup_zsh,
         stow_configs, misc_setup, dry_run, force, platform, verbose, debug):
    """
    🚀 Dotfiles Setup Assistant

    A modern, interactive setup script for managing dotfiles across multiple platforms.

    Run without arguments for interactive mode.
    """

    # Initialize logger
    logger.set_level(debug=debug, verbose=verbose)

    # Display welcome banner
    show_welcome_banner()

    try:
        # Initialize components
        detector = PlatformDetector(platform_override=platform)
        current_platform = detector.get_platform()

        config_manager = ConfigManager()
        confirmation_manager = ConfirmationManager(force=force, dry_run=dry_run)
        task_manager = TaskManager(
            platform=current_platform,
            config_manager=config_manager,
            confirmation_manager=confirmation_manager,
            dry_run=dry_run
        )

        logger.info(f"Platform detected: [green]{current_platform}[/green]")

        # Check if any specific flags were passed
        if any([full_setup, install_packages, setup_git, setup_fonts,
                setup_zsh, stow_configs, misc_setup]):
            run_non_interactive(task_manager, full_setup, install_packages,
                              setup_git, setup_fonts, setup_zsh, stow_configs, misc_setup)
        else:
            run_interactive(task_manager)

    except KeyboardInterrupt:
        logger.info("\n[yellow]Setup cancelled by user[/yellow]")
        sys.exit(0)
    except Exception as e:
        logger.error(f"Setup failed: {e}")
        if debug:
            import traceback
            logger.error(traceback.format_exc())
        sys.exit(1)


def show_welcome_banner():
    """Display the welcome banner."""
    title = Text("🚀 Dotfiles Setup Assistant", style="bold blue")
    subtitle = Text("A modern, interactive setup script for managing dotfiles", style="dim")

    panel_content = Text.assemble(title, "\n", subtitle)
    panel = Panel(panel_content, border_style="blue", padding=(1, 2))

    console.print()
    console.print(panel)
    console.print()


def run_interactive(task_manager):
    """Run the setup in interactive mode."""
    from .utils.confirmation import InteractiveMenu

    menu = InteractiveMenu()

    while True:
        choice = menu.show_main_menu()

        if choice == "install":
            task_manager.run_installer()
        elif choice == "git":
            task_manager.run_git_setup()
        elif choice == "fonts":
            task_manager.run_fonts_setup()
        elif choice == "zsh":
            task_manager.run_zsh_setup()
        elif choice == "stow":
            task_manager.run_stow_setup()
        elif choice == "misc":
            task_manager.run_misc_setup()
        elif choice == "full":
            if menu.confirm_full_setup():
                task_manager.run_full_setup()
                break
        elif choice == "exit":
            logger.info("[yellow]Setup cancelled by user[/yellow]")
            break

        if not menu.continue_setup():
            break

    logger.info("[green]✅ Setup completed![/green]")


def run_non_interactive(task_manager, full_setup, install_packages, setup_git,
                       setup_fonts, setup_zsh, stow_configs, misc_setup):
    """Run the setup in non-interactive mode based on flags."""

    if full_setup:
        logger.info("Running full setup...")
        task_manager.run_full_setup()
    else:
        if install_packages:
            task_manager.run_installer()
        if setup_git:
            task_manager.run_git_setup()
        if setup_fonts:
            task_manager.run_fonts_setup()
        if setup_zsh:
            task_manager.run_zsh_setup()
        if stow_configs:
            task_manager.run_stow_setup()
        if misc_setup:
            task_manager.run_misc_setup()

    logger.info("[green]✅ Setup completed![/green]")


if __name__ == "__main__":
    main()
