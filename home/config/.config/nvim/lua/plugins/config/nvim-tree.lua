return function()
  require("nvim-tree").setup({
    open_on_tab = false,
    view = {
      side = "right",
      width = 50,
    },
  })
end
