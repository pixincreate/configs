require("utils").gate("mac", function()
  if vim.g.neovide then
    vim.g.neovide_fullscreen = 1
  end
end)
