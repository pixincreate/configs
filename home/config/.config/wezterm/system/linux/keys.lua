local wezterm = require('wezterm');
local action = wezterm.action

return {
  {
    key = "l",
    mods = 'OPT',
    action = action.SplitHorizontal {
      domain = "CurrentPaneDomain"
    }
  }
}
