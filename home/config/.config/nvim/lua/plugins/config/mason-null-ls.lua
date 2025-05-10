-- return function()
--   require("mason-null-ls").setup({
--     automatic_setup = true,
--     automatic_installation = true,
--   })
-- end

return function()
  local null_ls = require("null-ls")

  require("mason-null-ls").setup({
    ensure_installed = {
      -- Opt to list sources here, when available in mason.
    },
    automatic_installation = false,
    handlers = {
      -- unnamed function is the default handlers
      -- custom handlers can be setup using their name as server name
    },
  })
  null_ls.setup({
    sources = {
      -- Anything not supported by mason.
    },
  })
end
