return function()
  vim.api.nvim_set_keymap("n", "<leader>tm", [[<cmd>ToggleTerm<cr>]], { desc = "Toggle Main Terminal" })
  vim.api.nvim_set_keymap("n", "<leader>ta", [[<cmd>ToggleTermToggleAll<cr>]], { desc = "Toggle All Terminals" })

  vim.api.nvim_set_keymap("i", "<c-t>", "<cmd>ToggleTerm<cr>", { silent = true, desc = "toggle terminal" })
  vim.api.nvim_set_keymap("t", "<c-t>", "<cmd>ToggleTerm<cr>", { silent = true, desc = "toggle terminal" })
  vim.api.nvim_set_keymap("n", "<c-t>", "<cmd>ToggleTerm<cr>", { desc = "toggle terminal" })
end
