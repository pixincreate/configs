#!/usr/bin/env python3
"""
Configuration validation script for CI.
"""

import sys
import os
import yaml

# Add the dotfiles package to Python path
project_root = os.path.dirname(os.path.dirname(__file__))
sys.path.insert(0, os.path.join(project_root, 'unix'))

from dotfiles.config import ConfigManager

def main():
    try:
        config = ConfigManager()
        print('✅ ConfigManager initialized successfully')

        # Test loading all configuration files
        packages = config.get_packages_config()
        apps = config.get_apps_config()
        settings = config.get_settings_config()

        print(f'✅ Loaded {len(packages)} package categories')
        print(f'✅ Loaded {len(apps)} app platforms')
        print(f'✅ Loaded {len(settings)} settings')

        return 0
    except Exception as e:
        print(f'❌ Configuration validation failed: {e}')
        return 1

if __name__ == '__main__':
    sys.exit(main())
