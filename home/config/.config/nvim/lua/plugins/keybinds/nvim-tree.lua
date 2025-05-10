return function()
  vim.keymap.set("n", "<c-e>", function() require("nvim-tree.api").tree.toggle({ focus = false }) end,
    { desc = "Toggle Nerd Tree" })
end
