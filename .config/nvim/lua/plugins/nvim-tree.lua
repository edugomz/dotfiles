vim.g.loaded = 1
vim.g.loaded_netrwPlugin = 1

require('nvim-tree').setup({
  -- follow :tcd, so a worktree tab (<leader>gw) gets its own root
  sync_root_with_cwd = true,
  view = {
    adaptive_size = true
  },
  filters = {
    dotfiles = true,
  },
})
