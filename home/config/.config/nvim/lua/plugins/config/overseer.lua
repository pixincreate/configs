return function()
  require("overseer").setup({
    task_list = {
      direction = "bottom",
      max_height = { 100, 0.5 }
    }
  })
end
