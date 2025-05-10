---Check if the system is disabled
---
---@param systems string[]
---@return boolean
local disabled_on = function(systems)
  for _, val in ipairs(systems) do
    if vim.fn.has(val) == 1 then
      return true
    end
  end
  return false
end

---Get a random quote - and display it in a vim.notify
---
local quoter = function()
  vim.fn.jobstart("curl -s https://zenquotes.io/api/random | jq '.[0][\"q\"]'", {
    stdout_buffered = true,
    on_stdout = function(a, b, c)
      -- print(vim.inspect(b))
      vim.notify(b[1], "info", { hide_from_history = true })
    end,
  })
end
vim.g.quote_me = quoter

---Get a random footer for the dashboard
---
---@return string
local random_footer = function()
  local footers = {
    "🚀 Sharp tools make good work.",
    "🥛 Boost is the secret of my energy.",
    "🥛 I am a complan boy",
    "⛰  Washing powder nirma",
    "📜 Luck is the planning, that you don't see.",
    "💣 Every problem is a business opportunity.",
  }
  math.randomseed(os.time())
  return footers[math.random(1, #footers)]
end

local get_newline = function()
  if vim.fn.has("win32") == 1 then
    return "\r\n"
  else
    return "\n"
  end
end

local theme_choicer = function()
  local Menu = require("nui.menu")
  local event = require("nui.utils.autocmd").event

  local lines = {}

  for i in pairs(vim.g.theme_choices) do
    table.insert(lines, Menu.item(vim.g.theme_choices[i]))
  end

  local menu = Menu({
    position = "50%",
    size = {
      width = 40,
    },
    border = {
      style = "rounded",
      text = {
        top = "[theme select]",
        top_align = "center",
      },
    },
    win_options = {
      winhighlight = "Normal:Normal,FloatBorder:Normal",
    },
  }, {
    lines = lines,
    on_close = function() end,
    on_submit = function(item)
      vim.cmd(item.text)
    end
  });

  menu:on(event.BufLeave, function()
    menu:unmount()
  end)

  menu:map("n", "<esc>", function()
    menu:unmount()
  end)

  menu:mount()
end

local point_search_inner = function(data)
  local regex = "%s*([A-Za-z0-9/._-]+):?(%d*):?(%d*)%s*$"

  local file_path, line_no, col_no = string.match(data, regex)

  local file_exists = vim.fn.filereadable(file_path) > 0

  if file_exists == false then
    return
  end

  vim.cmd("edit " .. file_path)

  if line_no == "" then
    line_no = "0"
  end

  if col_no == "" then
    col_no = "0"
  end

  vim.cmd("cal cursor(" .. line_no .. ", " .. col_no .. ")")
end

local point_search = function()
  local Input = require("nui.input")
  local event = require("nui.utils.autocmd").event

  local input = Input({
    position = { row = "20%", col = "50%" },
    -- position = "50%",
    size = {
      width = 80,
    },
    border = {
      style = "rounded",
      text = {
        top = "[point search]",
        top_align = "center",
      },
    },
    win_options = {
      winhighlight = "Normal:Normal,FloatBorder:Normal",
    },
  }, {
    prompt = "% ",
    on_close = function() end,
    on_submit = function(value)
      point_search_inner(value)
    end,
  })

  input:mount()

  input:on(event.BufLeave, function()
    input:unmount()
  end)

  input:map("n", "<esc>", function()
    input:unmount()
  end)
end

vim.g.copy_pad_open = {}
vim.g.scratch_pad_content = {}
local nui_copy_pad = function(name, callback, init) -- callback gets the content from the copy_pad
  if init ~= nil and vim.g.scratch_pad_content[name] == nil then
    vim.g.scratch_pad_content[name] = init()
  end

  if vim.g.copy_pad_open[name] == 1 then
    return
  end

  local Popup = require("nui.popup")
  local event = require("nui.utils.autocmd").event

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
      col = "100%",
    },
    size = "40%",
    -- size = {
    --   width = "40%",
    --   height = "70%",
    -- },
  })

  -- mount/open the component
  popup:mount()

  local global_insert = function(old, key, value)
    old[key] = value
    return old
  end

  if vim.g.scratch_pad_content[name] then
    vim.api.nvim_buf_set_lines(popup.bufnr, 0, -1, false, vim.g.scratch_pad_content[name])
  end

  vim.cmd([[set syntax=markdown]])
  vim.g.copy_pad_open = global_insert(vim.g.copy_pad_open, name, 1)

  -- print(vim.inspect(vim.g.copy_pad_open))

  local exit_action = function()
    local popup_buffer = popup.bufnr
    local lines = vim.api.nvim_buf_get_lines(popup_buffer, 0, -1, false)
    vim.g.scratch_pad_content = global_insert(vim.g.scratch_pad_content, name, lines)
    local content = table.concat(lines, get_newline())

    callback(content, name, lines)
    -- vim.fn.setreg("+", content)

    popup:unmount()
    vim.g.copy_pad_open = global_insert(vim.g.copy_pad_open, name, 0)
  end

  -- unmount component when cursor leaves buffer
  popup:on(event.BufLeave, exit_action)

  popup:map("n", "<esc>", exit_action)
  popup:map("n", ":", exit_action)
end

local get_current_location = function(callback)
  local filename = vim.fn.expand("%:.")
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))

  callback(filename .. ":" .. row .. ":" .. col)
end


local telescope_theme = function(opts)
  return require("telescope.themes").get_ivy(opts)
  -- return opts
end


local glob_search = function()
  local Input = require("nui.input")
  local event = require("nui.utils.autocmd").event

  local input = Input({
    position = { row = "90%", col = "50%" },
    size = {
      width = 40,
    },
    border = {
      style = "rounded",
      text = {
        top = "[glob_search]",
        top_align = "center",
      },
    },
    win_options = {
      winhighlight = "Normal:Normal,FloatBorder:Normal",
    },
  }, {
    prompt = "% ",
    on_close = function() end,
    on_submit = function(value)
      require("telescope.builtin").live_grep(telescope_theme({
        glob_pattern = value,
      }))
    end,
  })

  input:mount()

  local exit_action = function()
    input:unmount()
  end

  input:on(event.BufLeave, exit_action)
  input:map("n", "<esc>", exit_action)
end

return {
  disabled_on = disabled_on,
  quoter = quoter,
  dashboard_footer = random_footer,
  copy_pad = nui_copy_pad,
  point_search = point_search,
  get_current_location = get_current_location,
  glob_search = glob_search,
  telescope_theme = telescope_theme,
  theme_choicer = theme_choicer
}
