local function map(m, k, v)
  vim.keymap.set(m, k, v, { silent = true })
end

local function setToggleMap(m, k, commands)
  vim.keymap.set(m, k, (function()
    local active = false
    return function()
      if not active then
        vim.cmd(commands[1])
      else
        vim.cmd(commands[2])
      end
      active = not active
    end
  end)(), { silent = true })
end

map('i', 'jk', '<ESC>')
map('i', 'JK', '<ESC>')

-- Search and replace in visual mode
map('v', '<C-r>', '"hy:.,$s/<C-r>h//gc<left><left><left>')

-- Store large j/k jumps in jumplist
vim.keymap.set('n', 'k', function()
  return (vim.v.count > 5 and 'm`' .. vim.v.count or '') .. 'k'
end, { noremap = true, expr = true, silent = true })
vim.keymap.set('n', 'j', function()
  return (vim.v.count > 5 and 'm`' .. vim.v.count or '') .. 'j'
end, { noremap = true, expr = true, silent = true })

-- Search exact word
map('n', '<leader>/', '/\\<\\><left><left>')

-- Exit terminal
map('t', 'jk', '<C-\\><C-n>')
map('t', 'JK', '<C-\\><C-n>')
map('t', '<Esc>', '<C-\\><C-n>')

map('n', '<leader>w', '<cmd>w!<cr>')
map('n', '<leader>tn', '<cmd>tabedit %<cr>')
map('n', '<leader>tc', '<cmd>tabclose<cr>')
map('n', '<leader>to', '<cmd>tabonly<cr>')

-- File tree
map('n', '<leader>e', '<cmd>NvimTreeFindFileToggle<cr>')
map('n', '<leader>c', '<cmd>NvimTreeCollapse<cr>')

-- Telescope
map('n', '<C-J>', '<cmd>Telescope frecency workspace=CWD<cr>')
map('n', '<C-p>', '<cmd>Telescope oldfiles<cr>')
map('n', '<C-h>', '<cmd>Telescope lsp_document_symbols<cr>')
map('n', '<C-n>', '<cmd>Telescope lsp_dynamic_workspace_symbols<cr>')
map('n', '<leader>gy', '<cmd>Telescope registers<cr>')
map('n', '<leader>gl', '<cmd>Telescope live_grep<cr>')
map('n', '<leader>gg', '<cmd>Telescope grep_string<cr>')

-- Terminal
map('n', '<leader>;', '<cmd>FloatermToggle<cr>')

-- Spectre
map('n', '<leader>s',  function() require('spectre').open() end)
map('n', '<leader>sw', function() require('spectre').open_visual({ select_word = true }) end)

-- Git
map('n', '<leader>gs', '<cmd>tab Git<cr>')
map('n', '<leader>gz', '<cmd>Git add %<cr>')

-- LSP
map('n', '<leader>ca', vim.lsp.buf.code_action)
map('n', '<leader>ld', '<cmd>Lspsaga show_cursor_diagnostics<cr>')
map('n', '<leader>hh', function()
  require('lspconfig')['clangd'].commands.ClangdSwitchSourceHeader[1]()
end)

-- Replace word under cursor from current line to end of file
map('n', '<leader>r', ':.,$s/\\v(<C-r><C-w>)/<C-r><C-w>/g<Left><Left>')

-- Undotree toggle
setToggleMap('n', 'U', {
  'tabedit % | UndotreeToggle',
  'UndotreeToggle | tabclose',
})
