vim.g.mapleader = " "

require("bootstrap")
require("theme")

require("lazy").setup(require("plugins"))

require("config")
require("mappings")
require("masking")
require("custom")

require("functions.up-to-date").check()
