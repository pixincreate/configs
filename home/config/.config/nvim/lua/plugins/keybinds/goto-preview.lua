return function()
  vim.api.nvim_set_keymap("n", "gpd", [[<cmd>lua require('goto-preview').goto_preview_definition()<cr>]],
    { desc = "preview definition" })
  vim.api.nvim_set_keymap("n", "gpt", [[<cmd>lua require('goto-preview').goto_preview_type_definition()<cr>]],
    { desc = "preview type definition" })
  vim.api.nvim_set_keymap("n", "gpi", [[<cmd>lua require('goto-preview').goto_preview_implementation()<cr>]],
    { desc = "preview implementation" })
  vim.api.nvim_set_keymap("n", "gP", [[<cmd>lua require('goto-preview').close_all_win()<cr>]],
    { desc = "close all previews" })
  vim.api.nvim_set_keymap("n", "gpr", [[<cmd>lua require('goto-preview').goto_preview_references()<cr>]],
    { desc = "preview references" })
end
