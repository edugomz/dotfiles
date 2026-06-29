require('nvim-treesitter').setup()

-- Enable treesitter highlighting for any filetype that has a parser installed
vim.api.nvim_create_autocmd('FileType', {
  callback = function()
    pcall(vim.treesitter.start)
  end,
})
