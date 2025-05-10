return function()
    -- Buffer specific
    vim.api.nvim_set_keymap("n", "<leader>bh", [[<cmd>bprev<cr>]], { desc = "Previous Buffer" })
    vim.api.nvim_set_keymap("n", "<leader>bl", [[<cmd>bnext<cr>]], { desc = "Next Buffer" })
    vim.api.nvim_set_keymap("n", "<leader>bd", [[<cmd>bdel<cr>]], { desc = "Delete Buffer" })
    vim.api.nvim_set_keymap("n", "<leader>bdf", [[<cmd>bdel<cr>]], { desc = "Force Delete Buffer" })
    vim.api.nvim_set_keymap("n", "<leader>bn", [[<cmd>tab new<cr>]], { desc = "New Buffer" })


    -- Buffer
    vim.api.nvim_set_keymap("n", "<S-l>", [[<cmd>bnext<cr>]], { desc = "Go to next Buffer" })
    vim.api.nvim_set_keymap("n", "<S-h>", [[<cmd>bprev<cr>]], { desc = "Go to prev Buffer" })

    -- Tab
    vim.api.nvim_set_keymap("n", "<leader><S-l>", [[<cmd>tabnext<cr>]], { desc = "Go to next Tab" })

    vim.api.nvim_set_keymap("n", "<leader>co", [[<cmd>copen<cr>]], { desc = "Open Quickfix List" })
    vim.api.nvim_set_keymap("n", "<leader>cc", [[<cmd>ccl<cr>]], { desc = "Close Quickfix List" })
    vim.api.nvim_set_keymap("n", "<leader>ct", [[<cmd>cw<cr>]], { desc = "Toggle List" })
    vim.api.nvim_set_keymap("n", "<leader>cn", [[<cmd>cn<cr>]], { desc = "Next Location" })
    vim.api.nvim_set_keymap("n", "<leader>cp", [[<cmd>cp<cr>]], { desc = "Previous Location" })


    -- Concealing
    vim.api.nvim_set_keymap("n", "<leader>ce", [[<cmd>set conceallevel=2<cr>]], { desc = "Enable Concealing" })
    vim.api.nvim_set_keymap("n", "<leader>cd", [[<cmd>set conceallevel=0<cr>]], { desc = "Disable Concealing" })

    -- Terminal
    vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', { desc = "Exit Terminal Mode" })
end
