local wezterm = require 'wezterm'

local function tab_title(tab_info)
  local title = tab_info.tab_title
  if title and #title > 0 then
    return title
  end
  return tab_info.active_pane.title
end

local symbol_map = {
  right = "▐",
  left = "▌",
}

local language_map = {
  ["lua"] = {
    icon = wezterm.nerdfonts.seti_lua,
    name = "Lua"
  },
  ["rs"] = {
    icon = wezterm.nerdfonts.seti_rust,
    name = "Rust"
  },
  ["sh"] = {
    icon = wezterm.nerdfonts.seti_bash,
    name = "Bash"
  },
  ["zsh"] = {
    icon = wezterm.nerdfonts.seti_bash,
    name = "Zsh"
  },
  ["bash"] = {
    icon = wezterm.nerdfonts.seti_bash,
    name = "Bash"
  },
  ["fish"] = {
    icon = wezterm.nerdfonts.seti_fish,
    name = "Fish"
  },
  ["py"] = {
    icon = wezterm.nerdfonts.seti_python,
    name = "Python"
  },
  ["js"] = {
    icon = wezterm.nerdfonts.seti_javascript,
    name = "JavaScript"
  },
  ["ts"] = {
    icon = wezterm.nerdfonts.seti_typescript,
    name = "TypeScript"
  },
  ["tsx"] = {
    icon = wezterm.nerdfonts.seti_typescript,
    name = "TypeScript"
  },
  ["go"] = {
    icon = wezterm.nerdfonts.seti_go,
    name = "Go"
  },
  ["c"] = {
    icon = wezterm.nerdfonts.seti_c,
    name = "C"
  },
  ["cpp"] = {
    icon = wezterm.nerdfonts.seti_cpp,
    name = "C++"
  },
  ["h"] = {
    icon = wezterm.nerdfonts.seti_c,
    name = "C"
  },
  ["md"] = {
    icon = wezterm.nerdfonts.seti_markdown,
    name = "Markdown"
  },
  ["zig"] = {
    icon = wezterm.nerdfonts.seti_zig,
    name = "Zig"
  },
  ["yaml"] = {
    icon = wezterm.nerdfonts.seti_yaml,
    name = "Yaml"
  }

}

--- Join two tables
--- @param left table|nil
--- @param right table|nil
--- @return table
local function join(left, right)
  if (left == nil and right == nil) then
    return {}
  end
  if (left == nil and right ~= nil) then
    return right
  end
  if (right == nil and left ~= nil) then
    return left
  end

  local result = {}
  for k, v in pairs(left) do result[k] = v end
  for k, v in pairs(right) do result[k] = v end
  return result
end

return {
  tab_title = tab_title,
  symbol_map = symbol_map,
  join = join,
  language_map = language_map
}
