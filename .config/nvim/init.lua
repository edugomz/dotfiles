require('configfiles.settings')
require('configfiles.plugins')
require('configfiles.keybinds')

vim.o.clipboard = 'unnamedplus'

pcall(vim.cmd, 'colorscheme everforest')
