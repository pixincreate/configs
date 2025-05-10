return function()
  vim.keymap.set('n', '<C-u>', vim.cmd.UndotreeToggle, { desc = "Toggle Undo tree" })
end
