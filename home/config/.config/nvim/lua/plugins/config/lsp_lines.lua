return function()
      require("lsp_lines").setup()
      vim.diagnostic.config({ virtual_lines = false })
    end
