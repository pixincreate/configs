return function()
  vim.keymap.set("n", "<leader>K", vim.lsp.buf.implementation,
    { desc = "View implementations" })
  vim.keymap.set("n", "<leader>D", vim.lsp.buf.definition, { desc = "View Definition" })

  vim.api.nvim_set_keymap("n", "<c-s>", [[<cmd>lua vim.lsp.buf.format { async = true }<cr>]], { desc = "format file" })

  vim.api.nvim_set_keymap("n", "<leader>re", [[<cmd>RustLsp expandMacro<cr>]], { desc = "Expand Macro" })

  vim.g.lsp_hidden = false

  vim.keymap.set("n", "<leader>hl", function()
    if vim.g.lsp_hidden then
      vim.diagnostic.config({ virtual_text = true })
      vim.g.lsp_hidden = false
    else
      vim.diagnostic.config({ virtual_text = false })
      vim.g.lsp_hidden = true
    end
  end, { desc = "Toggle Hiding Lsp Hints" })
end
