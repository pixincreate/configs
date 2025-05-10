-- Key Binding Disabler
--

local function write_to_file(filename, content)
  local file = io.open(filename, "w")
  file:write(content)
  file:close()
end

local enable_all_keybinds = function()
  for _, data in ipairs(vim.g.keybind_store) do
    -- print(vim.inspect(data))
    if data.rhs == nil then
      vim.keymap.set(data.mode, data.lhs, data.callback, data.extra)
    else
      vim.api.nvim_set_keymap(data.mode, data.lhs, data.rhs, data.extra)
    end
  end
end

local disable_all_keybinds = function()
  local keybinds = {}
  local modes = { "n", "v" }
  local registry_set = {}
  for _, mode in ipairs(modes) do
    registry_set[mode] = {}
    for _, data in ipairs(vim.api.nvim_get_keymap(mode)) do
      local lhs = data.lhs

      local keys = {
        mode = mode,
        lhs = data.lhs,
        rhs = data.rhs,
        extra = {
          noremap = data.noremap,
          nowait = data.nowait,
          silent = data.silent,
          script = data.script,
          -- expr = data.expr,
        },
        callback = data.callback,
      }

      table.insert(keybinds, keys)

      if not registry_set[mode][lhs] then
        vim.api.nvim_del_keymap(mode, lhs)
        registry_set[mode][lhs] = true
      end
    end
  end

  vim.g.keybind_store = keybinds
end

return {
  disable = disable_all_keybinds,
  enable = enable_all_keybinds,
  write_to_file = write_to_file,
}
