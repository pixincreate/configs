return function()
  vim.api.nvim_set_keymap("n", "<c-h>", ":FocusSplitLeft<CR>", { silent = true, desc = "Focus Left" })
  vim.api.nvim_set_keymap("n", "<c-j>", ":FocusSplitDown<CR>", { silent = true, desc = "Focus Down" })
  vim.api.nvim_set_keymap("n", "<c-k>", ":FocusSplitUp<CR>", { silent = true, desc = "Focus Up" })
  vim.api.nvim_set_keymap("n", "<c-l>", ":FocusSplitRight<CR>", { silent = true, desc = "Focus Right" })

  vim.api.nvim_set_keymap("n", "<leader>wp", ":FocusSplitNicely<CR>", { silent = true, desc = "Split Nicely" })
  vim.api.nvim_set_keymap("n", "<leader>wo", ":FocusMaxOrEqual<CR>", { silent = true, desc = "Focus Max/Equal" })
end
