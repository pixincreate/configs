return function()
  vim.cmd([[nnoremap <c-;> <Cmd>lua require("dapui").eval()<CR>]])
end
