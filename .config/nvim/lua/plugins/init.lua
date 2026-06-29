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
    'kyazdani42/nvim-tree.lua',
    dependencies = { 'kyazdani42/nvim-web-devicons' },
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
    config = function()
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
    config = function()
      require('mason-lspconfig').setup({
        ensure_installed = { 'pyright', 'rust_analyzer', 'gopls' },
      })
    end,
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
  { 'tomtom/tcomment_vim' },
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
    'mhinz/vim-signify',
    init = function()
      vim.g.signify_sign_change = '~'
    end,
    config = function()
      vim.cmd "highlight SignifySignChange ctermfg=yellow guifg=#ffff00 cterm=NONE gui=NONE"
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

})
