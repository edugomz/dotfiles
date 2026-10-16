require('config.options')
require('config.autocmds')
require('plugins')
require('config.ssh_files') -- ssh:// buffers, also when a session restores them
require('config.keymaps')

pcall(vim.cmd, 'colorscheme everforest')
