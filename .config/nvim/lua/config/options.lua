local g = vim.g
local o = vim.o

g.mapleader = ' '
g.maplocalleader = ' '

-- Decrease update time
o.timeoutlen = 500
o.updatetime = 200

o.number = true
o.cursorline = true
o.scrolloff = 4
o.showmode = false
o.colorcolumn = '80'
o.clipboard = 'unnamedplus'

o.expandtab = true
o.wrap = true
o.breakindent = true
o.autoindent = true
o.tabstop = 2
o.shiftwidth = 2

-- Case insensitive searching UNLESS /C or capital in search
o.ignorecase = true
o.smartcase = true

o.backup = false
o.writebackup = false
o.undofile = true
o.swapfile = false

o.splitright = true
