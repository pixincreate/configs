# NVIM Configuration

<div align="center">
    <a href="https://dotfyle.com/NishantJoshi00/nvim-config"><img src="https://dotfyle.com/NishantJoshi00/nvim-config/badges/plugins?style=for-the-badge" /></a>
    <a href="https://dotfyle.com/NishantJoshi00/nvim-config"><img src="https://dotfyle.com/NishantJoshi00/nvim-config/badges/leaderkey?style=for-the-badge" /></a>
    <a href="https://dotfyle.com/NishantJoshi00/nvim-config"><img src="https://dotfyle.com/NishantJoshi00/nvim-config/badges/plugin-manager?style=for-the-badge" /></a>
</div>

## Description

A modern, feature-rich Neovim configuration focused on providing a powerful and efficient development environment. This configuration combines carefully selected plugins with custom configurations to enhance your editing experience while maintaining good performance.

Key aspects:

- Built with Lua for better performance and maintainability
- Modular architecture for easy customization
- Extensive LSP integration for powerful development features
- Carefully tuned for both functionality and aesthetics
- Supports multiple platforms (Linux, MacOS, Windows)

## Installation

1. Ensure you have Neovim 0.10+ installed on your system
2. Back up your existing Neovim configuration if needed:

   ```bash
   mv ~/.config/nvim ~/.config/nvim.bak
   ```

3. Clone this repository to your Neovim configuration directory:

   ```bash
   # Linux/MacOS
   git clone https://github.com/NishantJoshi00/nvim-config.git ~/.config/nvim

   # Windows (PowerShell)
   git clone https://github.com/NishantJoshi00/nvim-config.git $env:LOCALAPPDATA\nvim
   ```

4. Install required dependencies:

   - Git (for plugin management)
   - A C compiler (for certain plugins)
   - Node.js (for LSP features)
   - Ripgrep (for telescope search)
   - A Nerd Font (for icons)

5. Launch Neovim. The configuration will automatically:
   - Install the lazy.nvim plugin manager
   - Download and configure all plugins
   - Set up LSP servers and tools

## Features

### Core Features

- **Advanced LSP Integration**: Full language server support with auto-completion, diagnostics, and code actions
- **Smart Code Navigation**: Telescope-powered fuzzy finding for files, symbols, and references
- **Git Integration**: Built-in git management with Gitsigns and Fugitive
- **Terminal Integration**: Integrated terminal with toggleterm.nvim
- **Enhanced Syntax**: Treesitter-based syntax highlighting and code folding
- **Intelligent Completion**: Context-aware suggestions using nvim-cmp and Copilot
- **Customizable UI**: Beautiful and functional interface with adaptive themes

### Development Tools

- **Debug Adapter Protocol**: Full debugging support for multiple languages
- **Task Runner**: Integrated task management with Overseer
- **Project Management**: Enhanced project navigation and session management
- **Document Symbols**: Code outline and breadcrumbs navigation
- **Format on Save**: Automatic code formatting with LSP and null-ls

### Quality of Life Features

- **File Explorer**: Enhanced file browsing with nvim-tree and oil.nvim
- **Status Line**: Informative and customizable status line with lualine
- **Tab Management**: Intuitive buffer and tab management
- **Markdown Preview**: Live preview for markdown files
- **Undo History**: Visual undo tree navigation

## Contributing Guidelines

1. Fork the repository and create your feature branch:

   ```bash
   git checkout -b feature/amazing-feature
   ```

2. Follow these guidelines when contributing:

   - Tag issues appropriately ([BUG], [FEATURE], [ENHANCEMENT])
   - Don't work on already assigned issues
   - Ensure your code follows the existing style
   - Include comments for complex code sections
   - Test your changes thoroughly

3. Submit a pull request with a clear description of your changes

## Acknowledgments

- Built with the powerful Neovim editor
- Inspired by various community configurations
- Made possible by the amazing Neovim plugin ecosystem

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
