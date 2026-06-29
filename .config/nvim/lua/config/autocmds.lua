vim.api.nvim_create_autocmd('FileType', {
  pattern = '*',
  callback = function()
    vim.opt_local.formatoptions:remove({ 'r', 'o' })
  end,
})

vim.api.nvim_create_autocmd('BufWrite', {
  pattern = '*.tex',
  command = 'TexlabBuild',
})

vim.api.nvim_create_autocmd({ 'BufNewFile', 'BufRead' }, {
  pattern = { '*.vs', '*fs' },
  command = 'setf glsl',
})
