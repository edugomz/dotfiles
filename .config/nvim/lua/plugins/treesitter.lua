require('nvim-treesitter').setup()
require('nvim-treesitter').install({ 'markdown', 'markdown_inline' })

-- Enable treesitter highlighting for any filetype that has a parser installed
vim.api.nvim_create_autocmd('FileType', {
  callback = function()
    pcall(vim.treesitter.start)
  end,
})
