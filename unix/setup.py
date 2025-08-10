#!/usr/bin/env python3
"""
Dotfiles Setup Assistant
A modern, interactive setup script for managing dotfiles across multiple platforms.
"""

import sys
import os
from pathlib import Path

# Add the dotfiles package to Python path
project_root = os.path.dirname(os.path.dirname(__file__))
sys.path.insert(0, os.path.join(project_root, 'unix'))

from dotfiles.cli import main

if __name__ == "__main__":
    main()
