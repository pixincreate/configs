return function()
  vim.keymap.set("n", "<leader>l", function() require("lsp_lines").toggle() end, { desc = "Toggle lsp_lines" })
end
