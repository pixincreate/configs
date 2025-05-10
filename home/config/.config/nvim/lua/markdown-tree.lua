---@return string, table, table
local function get_text()
  local s_start = vim.fn.getpos("'<")
  local s_end = vim.fn.getpos("'>")
  local n_lines = math.abs(s_end[2] - s_start[2]) + 1
  local lines = vim.api.nvim_buf_get_lines(vim.api.nvim_get_current_buf(), s_start[2] - 1, s_end[2], false)
  lines[1] = string.sub(lines[1], s_start[3], -1)
  if n_lines == 1 then
    lines[n_lines] = string.sub(lines[n_lines], 1, s_end[3] - s_start[3] + 1)
  else
    lines[n_lines] = string.sub(lines[n_lines], 1, s_end[3])
  end
  return table.concat(lines, '\n'), s_start, s_end
end

local function tick_this()
  local current_line = vim.api.nvim_get_current_line()

  local pattern = "^(%s*)%-%s*%[%s*(x?)%](.*)$"

  local space, xs, msg = string.match(current_line, pattern)

  if (space) then
    local check = xs == "x" and " " or "x"
    local new_line = space .. "- [" .. check .. "]" .. msg
    vim.api.nvim_set_current_line(new_line)
  end
end


---@param ids string[]
---@param spaces number
---@param registry table<string, NuiTree.Node>
---@return string[]
function convert_lines(ids, spaces, registry)
  local output = {}

  for _, node_id in pairs(ids) do
    local node = registry[node_id]
    local space = string.rep(" ", spaces * (node:get_depth() - 1))
    local check = node.is_done and "x" or " "
    table.insert(output, space .. "- [" .. check .. "]" .. node.text)
    if #node:get_child_ids() > 0 then
      local children = convert_lines(node:get_child_ids(), spaces, registry)
      for _, child in pairs(children) do
        table.insert(output, child)
      end
    end
  end
  return output
end

---@param nodes { by_id: table<string, NuiTree.Node>, root_ids: string[] }
local function set_text(nodes, spaces, bufnr, s_start, s_end)
  local lines = convert_lines(nodes.root_ids, spaces, nodes.by_id)
  vim.api.nvim_buf_set_lines(bufnr, s_start[2] - 1, s_end[2], false, lines)
end

---@param nodes table
function make_children(nodes)
  if (#nodes == 0) then
    return {}
  end
  local current_space = nodes[1].depth
  local this_level = {}
  local children = {}

  while #nodes > 0 do
    local node = table.remove(nodes, 1)
    if node.depth == current_space then
      if #this_level > 0 then
        this_level[#this_level].children = make_children(children)
        children = {}
      end
      table.insert(this_level, { text = node.text, is_done = node.is_done })
    else
      table.insert(children, node)
    end
  end


  if #this_level > 0 then
    this_level[#this_level].children = make_children(children)
    children = {}
  end

  return this_level
end

---@param content string
function convert_checklist(content)
  local pattern = "^(%s*)%-%s*%[%s*(x?)%](.*)$"

  local lines = vim.split(content, "\n")
  local nodes = {}
  for i, line in ipairs(lines) do
    local space, xs, msg = string.match(line, pattern)
    if (space) then
      table.insert(nodes, {
        text = msg,
        is_done = xs == "x",
        depth = #space
      })
    end
  end

  if #nodes == 0 then
    return {}
  end

  local tree = make_children(nodes)

  return tree
end

function apply_children(nodes, func)
  local output = {}
  for i, node in ipairs(nodes) do
    if #node.children > 0 then
      node.children = apply_children(node.children, func)
    end
    table.insert(output, func(node))
  end
  return output
end

function checklist_visualize()
  local NuiTree = require("nui.tree")
  local NuiLine = require("nui.line")

  local data, s_start, s_end = get_text()
  local parent_bufnr = vim.api.nvim_get_current_buf()

  local nodes = apply_children(convert_checklist(data), function(node)
    return NuiTree.Node({
      text = node.text,
      is_done = node.is_done,
    }, node.children)
  end
  )

  local Popup = require("nui.popup")
  local event = require("nui.utils.autocmd").event

  local name = "Checklist"

  local popup = Popup({
    enter = true,
    focusable = true,
    border = {
      style = "rounded",
      text = {
        bottom = name,
        bottom_align = "center",
      },
      padding = { 1, 1 },
    },
    position = {
      row = "50%",
      col = "50%",
    },
    size = {
      width = "70%",
      height = "40%",
    },
  })

  local ntree = NuiTree({
    bufnr = popup.bufnr,
    nodes = nodes,
    prepare_node = function(node)
      local line = NuiLine()
      line:append(string.rep(" ", node:get_depth() - 1))
      if node:has_children() then
        line:append(node:is_expanded() and " " or " ")
      else
        line:append("  ")
      end

      line:append(node.is_done and "✔" or "⬚")

      if (node.is_done) then
        line:append(node.text, "Comment")
      else
        line:append(node.text)
      end


      return line
    end
  })

  popup:mount()
  ntree:render()

  local changes = false

  local exit_action = function()
    popup:unmount()
    if changes then
      set_text(ntree.nodes, 2, parent_bufnr, s_start, s_end)
    end
  end



  popup:on(event.BufLeave, exit_action)

  popup:map("n", "<esc>", exit_action)
  popup:map("n", ":", exit_action)

  popup:map("n", { "l", "<right>" }, function()
    local node = ntree:get_node()
    if node and node:expand() then
      ntree:render()
    end
  end)

  popup:map("n", { "h", "<left>" }, function()
    local node = ntree:get_node()
    if node and node:collapse() then
      ntree:render()
    end
  end)

  popup:map("n", "H", function()
    local updated = false
    for _, node in pairs(ntree.nodes.by_id) do
      updated = node:collapse() or updated
    end
    if updated then
      ntree:render()
    end
  end)

  popup:map("n", "L", function()
    local updated = false
    for _, node in pairs(ntree.nodes.by_id) do
      updated = node:expand() or updated
    end
    if updated then
      ntree:render()
    end
  end)

  popup:map("n", { "<cr>", "<leader>" }, function()
    local node = ntree:get_node()
    if node then
      node.is_done = not node.is_done
      changes = true
      ntree:render()
    end
  end)
end

local function tick_create()
  local line = vim.api.nvim_get_current_line()
  local prefix = "- [ ] "
  local new_line = prefix .. line
  vim.api.nvim_set_current_line(new_line)
end

return {
  checklist_visualize = checklist_visualize,
  checklist_toggle = tick_this,
  checklist_create = tick_create,
}
