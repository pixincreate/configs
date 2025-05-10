local custom = function()
  local gruvbox = function()
    local colors = {
      darkgray = "#282828",
      gray = "#928374",
      innerbg = nil,
      outerbg = "#1d2021",
      normal = "#548687",
      -- insert = "#7A7FA8",
      insert = "#CC7C5E",
      visual = "#7371fc",
      replace = "#d69821",
      command = "#bc3908",
    }


    return {
      inactive = {
        a = { fg = colors.gray, bg = colors.outerbg, gui = "bold" },
        b = { fg = colors.gray, bg = colors.outerbg },
        c = { fg = colors.gray, bg = colors.innerbg },
      },
      visual = {
        a = { fg = colors.darkgray, bg = colors.visual, gui = "bold" },
        b = { fg = colors.gray, bg = colors.outerbg },
        c = { fg = colors.gray, bg = colors.innerbg },
      },
      replace = {
        a = { fg = colors.darkgray, bg = colors.replace, gui = "bold" },
        b = { fg = colors.gray, bg = colors.outerbg },
        c = { fg = colors.gray, bg = colors.innerbg },
      },
      normal = {
        a = { fg = colors.darkgray, bg = colors.normal, gui = "bold" },
        b = { fg = colors.gray, bg = colors.outerbg },
        c = { fg = colors.gray, bg = colors.innerbg },
      },
      insert = {
        a = { fg = colors.darkgray, bg = colors.insert, gui = "bold" },
        b = { fg = colors.gray, bg = colors.outerbg },
        c = { fg = colors.gray, bg = colors.innerbg },
      },
      command = {
        a = { fg = colors.darkgray, bg = colors.command, gui = "bold" },
        b = { fg = colors.gray, bg = colors.outerbg },
        c = { fg = colors.gray, bg = colors.innerbg },
      },
    }
  end

  local symbols = {
    ["left"] = {
      left = "",
      right = "",
    },
    ["right"] = {
      left = "",
      right = "",
    },
    ["bubble"] = {
      left = "",
      right = "",
    },
    ["arrow"] = {
      left = "",
      right = "",
    },
    ["rect"] = {
      left = "▐",
      right = "▌",
    }
  }

  local current = symbols.rect;

  local left = current.left;
  local right = current.right;



  local unix = '';
  local dos = '';
  local mac = '';



  local lsp_info = {
    function()
      local msg = ""
      local buf_ft = vim.api.nvim_buf_get_option(0, "filetype")
      local clients = vim.lsp.get_active_clients()
      if next(clients) == nil then
        return msg
      end
      for _, client in ipairs(clients) do
        local filetypes = client.config.filetypes
        if filetypes and vim.fn.index(filetypes, buf_ft) ~= -1 then
          return client.name
        end
      end
      return msg
    end,
    color = { fg = '#ffffff', gui = 'bold' },
    separator = "",
  }

  local symbol_maker = function()
    if lsp_info[1]() == "" then
      return ""
    else
      return ''
    end
  end

  local os_icon = function()
    local os = vim.loop.os_uname().sysname
    if os == 'Linux' then
      return unix
    elseif os == 'Darwin' then
      return mac
    elseif os == 'Windows' then
      return dos
    end
  end


  require('lualine').setup({
    extensions = { 'oil', 'fzf', 'mason', 'lazy' },
    options = {
      icons_enabled = true,
      theme = gruvbox(),
      component_separators = { left = '', right = '' },
      section_separators = {
        left = right,
        right = left,
      },
      disabled_filetypes = {
        statusline = {
          'packer',
          'NvimTree',
        },
        winbar = {
          'packer',
          'NvimTree',
        },
      },
      globalstatus = true,
    },
    sections = {
      lualine_a = {
        {
          'mode',
          separator = {
            left = left,
            right = right,
          },
          right_padding = 0
        },
        { 'searchcount', maxcount = 999 },
      },
      lualine_b = { { os_icon }, 'branch', 'diff' },
      lualine_c = {
        'filetype',
        'filesize',
        {
          'diagnostics',
          sources = { 'nvim_diagnostic', 'nvim_lsp' },
          sections = { 'error', 'warn' },
        },
      },

      lualine_x = { 'encoding' },
      lualine_y = { 'progress',
        'selectioncount',
        {
          'filename',
          path = 1
        },
        { symbol_maker },
      },
      lualine_z = {
        lsp_info,
        {
          'location',
          separator = {
            left = left,
            right = right,
          },
          left_padding = 0
        },
      }
    },
  })
end

return custom;
