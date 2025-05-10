return function()
  -- local trouble = require("trouble.sources.telescope")



  require("telescope").setup({

    defaults = {
      -- file_sorter = require("telescope.sorters").get_substr_matcher,
    },

    extensions = {
      fzf = {
        fuzzy = true,                   -- false will only do exact matching
        override_generic_sorter = true, -- override the generic sorter
        override_file_sorter = true,    -- override the file sorter
      }
    }
  })
end
