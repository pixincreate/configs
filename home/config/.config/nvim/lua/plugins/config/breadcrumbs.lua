return function()
  require("nvim-navic").setup {
    lsp = {
      auto_attach = true,
    },
  }

  require("breadcrumbs").setup()
end
