return function()
  local bufferline = require('bufferline')
  bufferline.setup({
    options = {
      style_preset = {
        bufferline.style_preset.minimal,
        bufferline.style_preset.no_italic
      },
      diagnostics = "nvim_lsp",
      color_icons = true,
    }
  })
end
