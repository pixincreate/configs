return function()
  -- Copilot mappings

  vim.api.nvim_set_keymap("n", "<leader>nce", [[<cmd>Copilot enable<cr>]], { desc = "Enable Copilot" })
  vim.api.nvim_set_keymap("n", "<leader>ncd", [[<cmd>Copilot disable<cr>]], { desc = "Disable Copilot" })
  vim.api.nvim_set_keymap("n", "<leader>ncs", [[<cmd>Copilot status<cr>]], { desc = "Copilot Status" })
  vim.api.nvim_set_keymap("n", "<leader>ncp", [[<cmd>Copilot panel<cr>]], { desc = "Copilot Panel" })
  vim.api.nvim_set_keymap("n", "<leader>ncr", [[<cmd>Copilot restart<cr>]], { desc = "Copilot Restart" })


  vim.keymap.set('i', '<C-J>', 'copilot#Accept("\\<CR>")', { expr = true, replace_keycodes = false })
end
