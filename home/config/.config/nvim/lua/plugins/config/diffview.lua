return function()
  require("diffview").setup {
    view = {
      merge_tool = {
        layout = "diff1_plain"
      }
    }
  }
end
