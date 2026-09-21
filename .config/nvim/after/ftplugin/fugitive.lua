-- Jump from the fugitive status buffer to the commit graph.
vim.keymap.set('n', '<leader>f', '<cmd>Flog<cr>',
  { buffer = true, desc = 'Flog: commit graph' })
