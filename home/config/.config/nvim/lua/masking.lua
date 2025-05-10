local get_listed_buffers = function()
  local buffers = vim.api.nvim_list_bufs()
  local output = {}
  for _, bufnr in ipairs(buffers) do
    if
        vim.api.nvim_buf_is_loaded(bufnr)
        and vim.api.nvim_buf_is_valid(bufnr)
        and vim.api.nvim_buf_get_option(bufnr, "buflisted")
    then
      table.insert(output, bufnr)
    end
  end
  return output
end

local map_buffer = function(buffers, ops)
  for _, bufnr in ipairs(buffers) do
    ops(bufnr)
  end
end

local mark_buffer_modifiable = function(buffer)
  require("disabler").enable()
  vim.api.nvim_set_keymap("n", "<leader><c-d>", '<cmd>lua require("masking").immutable()<cr>', {})

  map_buffer(buffer, function(bufnr)
    vim.api.nvim_buf_set_option(bufnr, "modifiable", true)
    vim.api.nvim_buf_set_option(bufnr, "readonly", false)
    vim.cmd([[nnoremap : :]])
    vim.cmd([[vnoremap : :]])
    vim.cmd([[inoremap : :]])
    vim.o.cmdheight = 1
  end)
end

local unmark_buffer_modifiable = function(buffer)
  require("disabler").disable()
  vim.api.nvim_set_keymap("n", "<leader><c-a>", '<cmd>lua require("masking").mutable()<cr>', {})

  map_buffer(buffer, function(bufnr)
    vim.api.nvim_buf_set_option(bufnr, "modifiable", false)
    vim.api.nvim_buf_set_option(bufnr, "readonly", true)
    vim.cmd([[nnoremap : <Nop>]])
    vim.cmd([[vnoremap : <Nop>]])
    vim.cmd([[inoremap : <Nop>]])
    vim.o.cmdheight = 0
  end)
end

local mark_listed_bufs_m = function()
  mark_buffer_modifiable(get_listed_buffers())
end

local unmark_listed_bufs_m = function()
  unmark_buffer_modifiable(get_listed_buffers())
end

vim.keymap.set("n", "<leader><c-d>", unmark_listed_bufs_m, {})
vim.keymap.set("n", "<leader><c-a>", mark_listed_bufs_m, {})

return {
  get_buffers = get_listed_buffers,
  mutable = mark_listed_bufs_m,
  immutable = unmark_listed_bufs_m,
}
