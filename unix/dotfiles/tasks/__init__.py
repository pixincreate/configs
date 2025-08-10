"""
Task modules for the dotfiles setup system.

This module contains all the individual setup tasks that can be executed
as part of the dotfiles configuration process.
"""

from .task_manager import TaskManager

__all__ = ['TaskManager']
