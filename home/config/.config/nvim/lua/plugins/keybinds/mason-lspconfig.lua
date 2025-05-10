return function()
  vim.api.nvim_set_keymap(
    "n",
    "<c-.>",
    "<cmd>lua vim.lsp.buf.code_action()<cr>",
    { desc = "Lsp Code Action" }
  )
  vim.api.nvim_set_keymap(
    "v",
    "<c-.>",
    "<cmd>lua vim.lsp.buf.code_action()<cr>",
    { desc = "Lsp Code Action" }
  )
  vim.keymap.set("n", "<Leader>a", vim.lsp.buf.code_action, { desc = "Lsp Code Action" })
  vim.keymap.set("v", "<Leader>a", vim.lsp.buf.code_action, { desc = "Lsp Code Action" })
  vim.keymap.set("n", "<Leader>q", vim.lsp.buf.hover, { desc = "Hover Code Action" })
  vim.keymap.set("n", "<Leader>Q", vim.lsp.buf.implementation, { desc = "Lsp Implementation" })
  vim.keymap.set("n", "<Leader><c-r>", vim.lsp.buf.rename, { desc = "Lsp Rename" })
  vim.keymap.set("n", "<Leader>R", vim.lsp.buf.references, { desc = "Lsp References" })
end
