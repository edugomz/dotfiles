-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({{ "Failed to clone lazy.nvim:\n" .. out, "ErrorMsg" }}, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require('lazy').setup({

  -- Colorschemes
  { 'habamax/vim-alchemist' },
  { 'sainnhe/everforest', lazy = false, priority = 1000 },
  { 'embark-theme/vim', name = 'embark-theme' },

  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    config = function()
      require('plugins.treesitter')
    end
  },

  {
    'nvim-tree/nvim-tree.lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('plugins.nvim-tree')
    end,
  },

  {
    'nvim-lualine/lualine.nvim',
    config = function()
      require('plugins.lualine')
    end
  },

  -- Telescope
  {
    'nvim-telescope/telescope.nvim',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      require("telescope").setup({
        defaults = {
          layout_config = {
            horizontal = { width = 0.95 }
          }
        },
        pickers = {
          live_grep = {
            file_ignore_patterns = { 'node_modules', '.git', '.venv' },
            additional_args = function(_)
              return { "--hidden" }
            end
          },
          find_files = {
            file_ignore_patterns = { 'node_modules', '.git', '.venv' },
            hidden = true
          }
        },
      })
    end,
  },

  {
    "nvim-telescope/telescope-frecency.nvim",
    opts = {
      db_safe_mode = false,
      -- the CWD column prefixes each path with the workspace tail ("repo/"),
      -- which reads like a path from the parent dir after a :tcd
      show_filter_column = false,
    },
    config = function(_, opts)
      require("telescope").setup { extensions = { frecency = opts } }
      require("telescope").load_extension "frecency"
    end,
  },

  -- LSP
  {
    'neovim/nvim-lspconfig',
    dependencies = { 'williamboman/mason.nvim', 'williamboman/mason-lspconfig.nvim' },
    config = function()
      require('plugins.lsp.servers')
    end
  },

  { 'p00f/clangd_extensions.nvim' },

  {
    'williamboman/mason.nvim',
    config = function()
      require('mason').setup()
    end,
  },

  {
    'williamboman/mason-lspconfig.nvim',
    dependencies = { 'williamboman/mason.nvim' },
  },

  { 'Issafalcon/lsp-overloads.nvim' },

  {
    'nvimdev/lspsaga.nvim',
    dependencies = { 'neovim/nvim-lspconfig' },
    config = function()
      require('lspsaga').setup({
        symbol_in_winbar = {
          enable = true,
          separator = ' › ',
          hide_keyword = false,
          ignore_patterns = nil,
          show_file = true,
          folder_level = 2,
          color_mode = true,
          dely = 300,
        },
      })
    end,
  },

  {
    'hrsh7th/nvim-cmp',
    dependencies = {
      'hrsh7th/cmp-nvim-lsp',
      'saadparwaiz1/cmp_luasnip',
      {
        'L3MON4D3/LuaSnip',
        dependencies = { 'edugomez102/vim-snippets' },
        config = function()
          require('luasnip.loaders.from_snipmate').lazy_load()
        end,
      }
    },
    config = function()
      require('plugins.lsp.nvim-cmp')
    end,
  },

  {
    'nvim-pack/nvim-spectre',
    config = function()
      require('spectre').setup()
    end
  },

  -- Editing utilities
  { 'sickill/vim-pasta' },
  { 'tpope/vim-surround' },
  { 'junegunn/vim-easy-align' },
  { 'AndrewRadev/splitjoin.vim' },
  { 'myusuf3/numbers.vim' },
  { 'tpope/vim-eunuch' },

  {
    'mbbill/undotree',
    init = function()
      vim.g.undotree_WindowLayout = 2
    end,
  },

  -- Git
  { 'tpope/vim-fugitive' },
  { 'rhysd/git-messenger.vim' },

  {
    'akinsho/git-conflict.nvim',
    config = function()
      require('git-conflict').setup({
        default_mappings = true,
        disable_diagnostics = true,
        highlights = {
          incoming = 'DiffText',
          current = 'DiffAdd',
        }
      })
    end
  },

  { 'rbong/vim-flog' },

  {
    'lewis6991/gitsigns.nvim',
    config = function()
      require('gitsigns').setup({
        signs = {
          change = { text = '~' },
        },
        on_attach = function(bufnr)
          local gs = require('gitsigns')
          local map = function(k, v)
            vim.keymap.set('n', k, v, { silent = true, buffer = bufnr })
          end
          map('<leader>gh', gs.preview_hunk)
          map('<leader>gd', gs.diffthis)
          map('<leader>gu', gs.reset_hunk)
          map(']c', function() gs.nav_hunk('next') end)
          map('[c', function() gs.nav_hunk('prev') end)
        end,
      })
    end,
  },

  {
    'voldikss/vim-floaterm',
    init = function()
      vim.g.floaterm_wintype = 'split'
      vim.g.floaterm_height = 0.3
    end
  },

  {
    'echasnovski/mini.nvim',
    config = function()
      require('plugins.mini')
    end
  },

  {
    'kkoomen/vim-doge',
    build = ':call doge#install()',
    init = function()
      vim.g.doge_comment_interactive = 0
    end
  },

  {
    'RaafatTurki/hex.nvim',
    config = function()
      require("hex").setup({})
    end
  },

  { "sindrets/diffview.nvim" },

  {
    "3rd/image.nvim",
    build = false,
    opts = {
      -- WezTerm's kitty graphics support is partial (off by default, and redraws
      -- erase image cells); sixel works in WezTerm and passes through tmux >= 3.4.
      backend = "sixel",
      processor = "magick_cli",
      hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" },
      max_width_window_percentage = 100,
      max_height_window_percentage = 100,
      window_overlap_clear_enabled = true,
      tmux_show_only_in_active_window = true,
      integrations = {
        markdown = {
          -- markdown-table-wrap shows table-bearing docs in a derived Reader buffer
          -- named markdown-table-wrap://reader/<bufnr>/<file>, so relative image
          -- paths would resolve against that fake name. Use the Source file's path.
          resolve_image_path = function(document_path, image_path, fallback)
            local reader = document_path:match("^markdown%-table%-wrap://reader/(%d+)/")
            if reader then
              local ok, mtw = pcall(require, "markdown-table-wrap")
              local source = ok and mtw.resolve_source_buffer(tonumber(reader))
              if source then document_path = vim.api.nvim_buf_get_name(source) end
            end
            return fallback(document_path, image_path)
          end,
        },
      },
    },
    config = function(_, opts)
      local image = require("image")
      image.setup(opts)
      -- A full redraw wipes sixel images, but image.nvim only repaints when an image's
      -- geometry changes. Keep the default <C-l> and queue every visible image again.
      vim.keymap.set("n", "<C-l>", function()
        vim.cmd("nohlsearch|diffupdate|normal! \12")
        for _, img in ipairs(image.get_images()) do
          if img.is_rendered then
            img:clear(true)
            img:render()
          end
        end
      end, { desc = "Redraw screen and repaint images" })
    end,
  },

  {
    'MeanderingProgrammer/render-markdown.nvim',
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
    ft = { 'markdown' },
    config = function()
      -- obsidian-query renders dataview/query fences through these handlers
      local has_oq, oq = pcall(require, 'obsidian-query')
      require('render-markdown').setup({
        pipe_table = { enabled = false },
        -- Markers of the agent-*-planning skills; `todo` replaces the default [-] clock
        checkbox = {
          -- stylua: ignore
          custom = {
            todo     = { raw = '[-]', rendered = '󰅘 ', highlight = 'RenderMarkdownError', scope_highlight = '@markup.strikethrough' },
            progress = { raw = '[/]', rendered = '󰐋 ', highlight = 'RenderMarkdownWarn' },
            parked   = { raw = '[~]', rendered = '󰏤 ', highlight = 'Comment' },
          },
        },
        custom_handlers = has_oq and {
          markdown = oq.handler,
          markdown_inline = require('obsidian-query.inline').handler,
        } or nil,
      })
    end,
  },

  {
    'hat0uma/csvview.nvim',
    ft = { 'csv', 'tsv' },
    config = function()
      require('csvview').setup({})
    end,
  },

  {
    'ice345/markdown-table-wrap.nvim',
    ft = { 'markdown', 'quarto', 'rmd', 'rmarkdown' },
    config = function()
      -- table-wrap's virtual-text cells re-render code spans with its own
      -- highlight group instead of the buffer's real syntax highlighting, and
      -- strips any linked background by default to avoid filled rectangles.
      -- Pull both the real code fg (treesitter/colorscheme) and render-markdown's
      -- background chip back in explicitly so cells match the rest of the buffer.
      local code_fg = vim.api.nvim_get_hl(0, { name = '@markup.raw.markdown_inline', link = false })
      local code_bg = vim.api.nvim_get_hl(0, { name = 'ColorColumn', link = false })
      require('markdown-table-wrap').setup({
        max_col_width = 220,
        highlight_preset = 'render_markdown',
        highlights = {
          code = {
            fg = code_fg.fg,
            ctermfg = code_fg.ctermfg,
            bg = code_bg.bg,
            ctermbg = code_bg.ctermbg,
          },
        },
      })
    end,
  },

  require('plugins.claudecode'),

  require('plugins.obsidian'),

})
