-- obsidian.nvim never detects vaults itself (setup errors without a
-- workspace), so load it only when nvim starts inside a tree with `.obsidian/`
-- (or at a contrib workspace root, whose vault is `vault/`) and use that tree
-- as the single workspace.
local cwd = vim.uv.cwd()
local vault = vim.fs.root(cwd, '.obsidian')
  or (vim.uv.fs_stat(cwd .. '/vault/.obsidian') and cwd .. '/vault')

return {
  {
    'obsidian-nvim/obsidian.nvim',
    -- v3.16.8 moved cache mtime/size under `stat`; obsidian-query (2026-09-14)
    -- still reads the old keys, so file.mtime/file.size come out as 1970/0.
    -- Unpin once obsidian-query supports the new schema.
    version = '3.16.7',
    ft = 'markdown',
    cond = vault ~= nil,
    opts = {
      legacy_commands = false,
      workspaces = { { path = vault } },
      -- obsidian-query reads notes from this cache
      cache = { enabled = true },
      ui = { enable = false },
      -- default rewrites frontmatter on save (adds aliases/tags)
      frontmatter = { enabled = false },
      footer = { enabled = false },
      statusline = { enabled = false },
      templates = { enabled = false },
      daily_notes = { enabled = false },
      checkbox = { enabled = false },
      slides = { enabled = false },
    },
    config = function(_, opts)
      require('obsidian').setup(opts)
      -- obsidian-ls always starts in vault notes and duplicates marksman
      -- (gd, rename, completion, code actions). Keep it only for its file
      -- watcher, which refreshes the cache on external edits: that one is
      -- registered dynamically, so clearing the static capabilities keeps it.
      -- textDocumentSync must stay: change tracking already grouped the
      -- client by its sync kind and errors on the next edit if it vanishes.
      vim.api.nvim_create_autocmd('LspAttach', {
        callback = function(ev)
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if client and client.name == 'obsidian-ls' then
            client.server_capabilities = { textDocumentSync = client.server_capabilities.textDocumentSync }
          end
        end,
      })
      -- obsidian's includeexpr resolves every link to the current note (gf
      -- silently reloads it). Plain gf with .md suffix and a recursive path
      -- opens [[note]], [[note|alias]], [x](path) and [x](path-without-.md).
      vim.api.nvim_create_autocmd('User', {
        pattern = 'ObsidianNoteEnter',
        callback = function(ev)
          vim.bo[ev.buf].includeexpr = ''
          vim.bo[ev.buf].suffixesadd = '.md'
          -- ponytail: `**` walks the whole vault from cwd, fine for note trees
          vim.bo[ev.buf].path = '.,,**'
        end,
      })
    end,
  },

  {
    'dpezto/obsidian-query.nvim',
    ft = 'markdown',
    cond = vault ~= nil,
    dependencies = { 'obsidian-nvim/obsidian.nvim' },
    opts = {
      picker = { backend = 'telescope' },
    },
  },
}
