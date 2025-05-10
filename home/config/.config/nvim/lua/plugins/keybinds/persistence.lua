return function()
  vim.keymap.set("n", "<leader>sc", require('persistence').load, { desc = "Load Session from Current Directory" })

  vim.keymap.set("n", "<leader>sl", function() require('persistence').load({ last = true }) end,
    { desc = "Load last session" })

  vim.keymap.set("n", "<leader>sq", require('persistence').stop, { desc = "Stop Session Recording" })
end
