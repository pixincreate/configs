vim.lsp.handlers["textDocument/publishDiagnostics"] =
    vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, { update_in_insert = true })

vim.cmd([[set nofoldenable]])
vim.o.updatetime = 300

vim.o.undodir = vim.fn.stdpath("cache") .. "/undodir"
vim.o.undofile = true

vim.o.cursorline = true

vim.o.scrolloff = 4

vim.cmd([[highlight IndentBlanklineChar guifg=#202020 gui=nocombine]])
vim.cmd([[highlight IndentBlanklineContextChar guifg=#505050 gui=nocombine]])
-- vim.cmd([[highlight Cursorline gui=underline cterm=underline guisp=gray guibg=NONE]])

vim.o.list = true
vim.o.listchars = require("utils").join({ trail = "·", tab = "▸ " })

vim.cmd([[autocmd BufRead,BufNewFile *.Jenkinsfile setfiletype groovy]])


vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client.server_capabilities.inlayHintProvider then
      vim.lsp.inlay_hint.enable(true, {
        bufnr = args.buf
      })
    end
  end
})


vim.api.nvim_create_user_command('LuaToBuffer', function(opts)
  local output = vim.fn.execute('lua ' .. opts.args)
  vim.api.nvim_buf_set_lines(0, -1, -1, false, vim.split(output, '\n'))
end, { nargs = '+' })
