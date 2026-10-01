-- Git worktree picker: each worktree opens in its own tab, with a tab-local cwd.
-- Inside a contrib workspace (clones in repos/<name>/ or repo/) it lists the
-- worktrees of every clone, so it also works from the workspace root.
local M = {}

function M.list()
  local cwd = vim.fn.getcwd()
  local root = vim.fs.root(cwd, { 'repos', 'repo' })
  local clones = root and vim.list_extend(vim.fn.glob(root .. '/repos/*', false, true),
    vim.fn.glob(root .. '/repo', false, true)) or {}
  if #clones == 0 then clones = { cwd } end

  local items = {}
  for _, clone in ipairs(clones) do
    for _, line in ipairs(vim.fn.systemlist({ 'git', '-C', clone, 'worktree', 'list', '--porcelain' })) do
      local path = line:match('^worktree (.+)')
      if path then table.insert(items, { path = path, branch = '(detached)' }) end
      local branch = line:match('^branch refs/heads/(.+)')
      if branch then items[#items].branch = branch end
    end
  end
  return items
end

-- Jump to the tab already in `path`, else reuse an empty tab not yet bound to
-- a worktree (no tab-local cwd), or open a new one; a new worktree tab starts
-- in the fugitive status view.
function M.open(path)
  for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
    if vim.fn.getcwd(-1, vim.api.nvim_tabpage_get_number(tab)) == path then
      return vim.api.nvim_set_current_tabpage(tab)
    end
  end
  local empty = vim.fn.haslocaldir(-1) == 0 and vim.fn.bufname() == '' and not vim.bo.modified
    and #vim.api.nvim_tabpage_list_wins(0) == 1
  vim.cmd((empty and '' or 'tabnew | ') .. 'tcd ' .. vim.fn.fnameescape(path) .. ' | Git | only')
end

function M.pick()
  local actions, state = require('telescope.actions'), require('telescope.actions.state')
  require('telescope.pickers').new({}, {
    prompt_title = 'Worktrees',
    finder = require('telescope.finders').new_table({
      results = M.list(),
      entry_maker = function(wt)
        local display = string.format('%-45s %s', wt.branch, vim.fn.fnamemodify(wt.path, ':~'))
        return { value = wt.path, display = display, ordinal = display }
      end,
    }),
    sorter = require('telescope.config').values.generic_sorter({}),
    attach_mappings = function(bufnr)
      actions.select_default:replace(function()
        actions.close(bufnr)
        M.open(state.get_selected_entry().value)
      end)
      return true
    end,
  }):find()
end

return M
