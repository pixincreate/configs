return function()
  vim.keymap.set("n", "<leader>oo", require("overseer").toggle, { desc = "Toggle Overseer" })
  vim.keymap.set("n", "<leader>oa", require("overseer").run_template, { desc = "Run task from templates" })
end
