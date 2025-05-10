return function()
  require("dressing").setup({
    select = {
      backend = { "builtin", "telescope", "nui" }
    },
  })
end
