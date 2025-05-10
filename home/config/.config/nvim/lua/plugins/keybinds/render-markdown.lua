return function()
    vim.api.nvim_set_keymap("n", "<leader>rm", [[<cmd>RenderMarkdown toggle<cr>]], { desc = "Toggle Markdown Rendering" })
end
