local unmanaged_handlers = function()
    -- Zig
    vim.g.zig_fmt_autosave = 0
    vim.g.zig_fmt_parse_errors = 0

    require("lspconfig").zls.setup({})
end





return function()
    require("mason-lspconfig").setup()
    local capabilities = require("cmp_nvim_lsp").default_capabilities()


    unmanaged_handlers()

    -- managed handlers
    require("mason-lspconfig").setup_handlers({
        -- default handler
        function(server_name)
            require("lspconfig")[server_name].setup({
                capabilities = capabilities,
            })
        end,

        -- dedicated handlers
        ["rust_analyzer"] = function()
            vim.g.rustaceanvim = require("opts")["rust-analyzer"]

            require("quickfix").rust_quickfix()
        end,
        ["hls"] = function()
            -- this requires haskell-tools.nvim, hls, hlint
        end,
        ["lua_ls"] = function()
            require("lspconfig").lua_ls.setup({
                settings = {
                    Lua = {
                        completion = {
                            callSnippet = "Replace",
                        },
                    },
                },
            })
        end,
    })
end
