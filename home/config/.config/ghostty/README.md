# Ghostty Terminal Configuration

Clean, modular configuration for [Ghostty](https://ghostty.org/) terminal emulator with OS-specific optimizations and custom cursor effects.

## Quick Start

1. **Clone/symlink this config:**

   ```bash
   # macOS
   ln -s ~/.config/ghostty ~/Library/Application\ Support/com.mitchellh.ghostty

   # Linux
   # Already in ~/.config/ghostty
   ```

2. **Set up OS-specific config:**

   ```bash
   cd ~/.config/ghostty/os

   # macOS
   ln -sf macos.conf current.conf

   # Linux
   ln -sf linux.conf current.conf
   ```

3. **Reload Ghostty** - `Ctrl+Cmd+R` (macOS) or restart

## Configuration Structure

```
ghostty/
├── config                  # Main entry point
├── theme.conf             # Kanagawa Dragon colors
├── appearance.conf        # Visual settings
├── keybinds.conf          # Keyboard shortcuts
├── quick-terminal.conf    # Dropdown terminal
├── os/
│   ├── current.conf      # Symlink (gitignored) → macos.conf or linux.conf
│   ├── macos.conf        # macOS-only settings
│   └── linux.conf        # Linux-only settings
└── shaders/
    └── cursor-warp.glsl  # Cursor trail effect
```

## Theme

**Kanagawa Dragon** - Dark, muted color scheme inspired by Japanese art

| Element    | Color         | Hex       |
| ---------- | ------------- | --------- |
| Background | Deep charcoal | `#181616` |
| Foreground | Warm gray     | `#c8c093` |
| Cursor     | Light gray    | `#c5c9c5` |
| Selection  | Deep blue     | `#2d4f67` |

**16 ANSI Colors:**

- **Normal:** Black, Red, Green, Yellow, Blue, Magenta, Cyan, White
- **Bright:** Enhanced versions for bold text
- Optimized with `minimum-contrast = 1.1` for readability
- Bold text uses bright palette colors

## Visual Features

### Background

- **Opacity:** 88% transparency
- **Blur:** 20px radius for depth
- **Padding:** 4px comfortable spacing

### Cursor Trail Shader

Smooth motion trail when cursor moves:

- **Duration:** 0.2s animation
- **Easing:** EaseOutCirc for natural motion
- **Threshold:** Activates on movements > 1.5 cursor heights
- **Customizable:** Edit `TRAIL_SIZE`, `TRAIL_THICKNESS` in shader

**Disable shader:**

```ini
# appearance.conf
# custom-shader = shaders/cursor-warp.glsl
```

### Split Appearance

- Unfocused splits dimmed to 80% opacity
- Subtle divider color `#2a2a2a`

## Keybindings

### Window & Tabs

```
Cmd+N              New window
Cmd+W              Close window
Cmd+T              New tab
Cmd+1-9            Jump to tab 1-9
Ctrl+Tab           Next tab
Ctrl+Shift+Tab     Previous tab
```

### Splits (Vim-style)

```
Cmd+D              Split right
Cmd+Shift+D        Split down
Cmd+H/J/K/L        Navigate left/down/up/right
Cmd+Shift+Z        Toggle zoom
Ctrl+Cmd+E         Equalize all splits
```

### Terminal

```
Cmd+K              Clear screen
Cmd+A              Select all
Cmd+Plus/Minus     Font size
Cmd+0              Reset font size
```

### Navigation

```
Cmd+Up/Down        Scroll to top/bottom
Ctrl+Shift+P       Previous prompt (shell integration)
Ctrl+Shift+N       Next prompt (shell integration)
```

### System

```
Cmd+P              Command palette
Cmd+,              Open config
Ctrl+Cmd+R         Reload config
Cmd+`              Toggle quick terminal
```

## Quick Terminal

Dropdown terminal overlay - press **Cmd+`** from anywhere (requires Accessibility permissions on macOS).

**Behavior:**

- Appears from top of screen
- 55% width, 600px max height
- Auto-hides when clicking outside
- Follows mouse to correct display
- 0.18s smooth animation (macOS)

**Use cases:**

- Quick git commands while in browser
- Run tests without switching windows
- Temporary command execution

## OS-Specific Settings

### macOS (`os/macos.conf`)

- Native tabs titlebar style
- Blueprint app icon
- Window shadows enabled
- Step resize (by cell increments)
- Auto secure input for passwords
- Option key as Alt
- Auto-update checking
- Quick terminal animations
- Undo timeout: 8 seconds

### Linux (`os/linux.conf`)

- GTK titlebar with top tabs
- Single instance detection
- Window quit delay: 2 seconds
- CGroup process isolation
- Wayland overlay quick terminal
- On-demand keyboard interactivity

### Cross-Platform (`config`)

- Shell integration with SSH terminfo auto-install
- Quit behavior (configurable per OS preference)
- Undo support
- Quick terminal screen following

## Shell Integration

Enabled features:

- **cursor** - Blinking cursor at prompt
- **title** - Auto-update window title
- **sudo** - Preserve terminfo in sudo
- **ssh-terminfo** - Auto-install terminfo on remote hosts
- **path** - Add Ghostty to PATH

**Benefits:**

- Jump between prompts with Ctrl+Shift+P/N
- Smart close confirmations
- Directory inheritance for new tabs/splits

## Clipboard & Selection

- Copy on select enabled
- Selection clears after copy
- Paste protection for unsafe content
- Ask before clipboard read access
- Mouse hides while typing
- Precision scroll: 0.9x, Discrete: 3x

## Customization

### Change Theme Colors

Edit `theme.conf`:

```ini
background = #181616
foreground = #c8c093
palette = 0=#0d0c0c  # ANSI black
palette = 1=#c4746e  # ANSI red
# ... etc
```

### Adjust Transparency

Edit `appearance.conf`:

```ini
background-opacity = 0.88  # 0.0 = invisible, 1.0 = solid
background-blur-radius = 20
```

### Modify Cursor Trail

Edit `shaders/cursor-warp.glsl`:

```glsl
const float DURATION = 0.2;        // Animation length
const float TRAIL_SIZE = 0.8;      // 0.0-1.0, smear amount
const float TRAIL_THICKNESS = 1.0; // Height multiplier
const float FADE_ENABLED = 0.0;    // 1.0 for fade gradient
```

### Add Keybinds

Edit `keybinds.conf`:

```ini
keybind = trigger=action
# Example:
keybind = ctrl+shift+x=new_window
```

See [Ghostty keybind reference](https://ghostty.org/docs/config/keybind/reference) for actions.

## Git Workflow

The `os/current.conf` symlink is **gitignored** to prevent conflicts:

1. **Both configs tracked:** `os/macos.conf` and `os/linux.conf`
2. **Symlink ignored:** `os/current.conf` (machine-specific)
3. **First setup:** Create symlink pointing to your OS config
4. **Pull/push:** No conflicts, configs sync across machines

## Requirements

- **Ghostty:** Version 1.2.0+
- **macOS:** Accessibility permissions for global quick terminal
- **Compositor:** For transparency/blur (macOS built-in, Linux needs compositor)

## Troubleshooting

**Shaders not working?**

- Check GPU support
- Try commenting out shader in `appearance.conf`

**Quick terminal not appearing?**

- macOS: Grant Accessibility permissions in System Settings
- Linux: Ensure compositor running for overlay

**Keybinds not working?**

- Check for conflicts with system shortcuts
- Try alternative modifiers (ctrl vs super)

**Colors look wrong?**

- Verify `theme.conf` loaded
- Check terminal $TERM value (`xterm-ghostty`)

## Documentation

- [Ghostty Docs](https://ghostty.org/docs)
- [Config Reference](https://ghostty.org/docs/config/reference)
- [Keybind Reference](https://ghostty.org/docs/config/keybind/reference)
- [Shell Integration](https://ghostty.org/docs/features/shell-integration)
- [Linux Setup](https://ghostty.org/docs/linux)

## License

Free to use and modify.
