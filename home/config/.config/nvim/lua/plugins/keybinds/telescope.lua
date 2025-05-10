return function()
  local telescope_theme = require("functions").telescope_theme;

  vim.keymap.set("n", "<leader>ff", function()
      require("telescope.builtin").find_files(telescope_theme({
      }))
    end,
    { desc = "Find Files" })

  vim.keymap.set("n", "<leader>fg", function() require('telescope.builtin').live_grep(telescope_theme({})) end,
    { desc = "Live Grep" })

  vim.keymap.set("n", "<leader>fb", function() require('telescope.builtin').buffers(telescope_theme({})) end,
    { desc = "Buffers" })

  vim.keymap.set("n", "<leader>fh", function() require('telescope.builtin').help_tags(telescope_theme({})) end,
    { desc = "Help Tags" })

  vim.keymap.set("n", "<leader>fa",
    function() require('telescope.builtin').lsp_dynamic_workspace_symbols(telescope_theme({})) end,
    { desc = "LSP Search" })

  vim.keymap.set("n", "<leader>fb", function() require('telescope.builtin').builtin(telescope_theme({})) end,
    { desc = "Search Builtin" })


  vim.keymap.set("n", "<leader>fs", function() require('telescope.builtin').spell_suggest(telescope_theme({})) end,
    { desc = "Suggest Spellings" })
end
