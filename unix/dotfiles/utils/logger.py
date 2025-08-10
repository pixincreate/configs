"""
Logging utilities with rich formatting and different log levels.
"""

from rich.console import Console
from rich.text import Text
from rich.panel import Panel
from rich.progress import Progress, SpinnerColumn, TextColumn
from typing import Optional
import sys

console = Console()


class Logger:
    """Rich-formatted logger with different log levels."""

    def __init__(self):
        self.debug_enabled = False
        self.verbose_enabled = False

    def set_level(self, debug: bool = False, verbose: bool = False):
        """Set logging levels."""
        self.debug_enabled = debug
        self.verbose_enabled = verbose or debug

    def info(self, message: str):
        """Log info message."""
        console.print(f"[green]ℹ[/green] {message}")

    def success(self, message: str):
        """Log success message."""
        console.print(f"[green]✅[/green] {message}")

    def warning(self, message: str):
        """Log warning message."""
        console.print(f"[yellow]⚠️[/yellow] {message}")

    def error(self, message: str):
        """Log error message."""
        console.print(f"[red]❌[/red] {message}", file=sys.stderr)

    def debug(self, message: str):
        """Log debug message (only if debug enabled)."""
        if self.debug_enabled:
            console.print(f"[dim][DEBUG][/dim] {message}")

    def verbose(self, message: str):
        """Log verbose message (only if verbose enabled)."""
        if self.verbose_enabled:
            console.print(f"[dim]{message}[/dim]")

    def step(self, message: str):
        """Log step message with special formatting."""
        console.print(f"\n[bold blue]🔧 {message}[/bold blue]")

    def substep(self, message: str):
        """Log substep message with indentation."""
        console.print(f"  [blue]→[/blue] {message}")

    def dry_run(self, message: str):
        """Log dry run message."""
        console.print(f"[yellow][DRY RUN][/yellow] {message}")

    def panel(self, title: str, content: str, style: str = "blue"):
        """Display content in a panel."""
        panel = Panel(content, title=title, border_style=style)
        console.print(panel)

    def confirm_panel(self, title: str, items: list, style: str = "green"):
        """Display confirmation panel with list items."""
        content = "\n".join([f"• {item}" for item in items])
        self.panel(title, content, style)

    @staticmethod
    def progress_spinner(description: str = "Working..."):
        """Create a progress spinner context manager."""
        return Progress(
            SpinnerColumn(),
            TextColumn("[progress.description]{task.description}"),
            console=console,
            transient=True
        )

    def table_header(self, title: str):
        """Print a table header."""
        console.print(f"\n[bold]{title}[/bold]")
        console.print("─" * len(title))

    def table_row(self, name: str, status: str, status_style: str = "green"):
        """Print a table row."""
        console.print(f"{name:<30} [{status_style}]{status}[/{status_style}]")

    def separator(self):
        """Print a separator line."""
        console.print("─" * 60)

    def newline(self):
        """Print a newline."""
        console.print()
