return function()
  local ascii = require("ascii")

  require("dashboard").setup({
    theme = "hyper",
    config = {
      -- header = ascii.art.text.neovim.dos_rebel,
      header = ascii.art.misc.hydra.hydra,
      shortcut = {
        { desc = '󰊳 Update', group = '@property', action = 'Lazy update', key = 'u' },
        { icon = ' Find Files', icon_hl = '@variable', desc = '', group = 'Label', action = 'Telescope find_files', key = 'f', },
        { desc = 'Change Branch', group = 'DiagnosticHint', action = 'Telescope git_branches', key = 'a', },
        { desc = 'View Man Pages', group = 'DiagnosticHint', action = 'Telescope man_pages', key = 'm', },
      },
      project = { enable = true, limit = 8, icon = '', label = 'Projects', action = 'cd ' },
      packages = { enable = true }, -- show how many plugins neovim loaded
      mru = { limit = 1, icon = '', label = 'Files Opened', cwd_only = true },
      footer = {
        "",
        require("functions").dashboard_footer(),
      },
    },
  })
end
