return function()
  require("notify").setup({
    render = "minimal",
    stages = "slide",
    fps = 60,
  })

  vim.notify = require("notify")

  -- require("functions").quoter()
end
