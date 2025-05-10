require("utils").gate("win32", function()
  vim.o.shell = "powershell"
  vim.o.shellcmdflag = "-c"
  vim.o.shellquote = '"'
  vim.o.shellxquote = ""
  require("toggleterm").setup({
    shell = vim.o.shell,
  })
  if vim.g.neovide then
    vim.g.neovide_scale_factor = 0.65
    vim.g.neovide_fullscreen = true
  end
end)
