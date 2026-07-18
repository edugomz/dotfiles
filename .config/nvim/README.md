# Nvim config

![dashboard of config](nvim_capture.png)

## Requirements

| Dependency | Purpose | Notes |
|---|---|---|
| **Neovim 0.11+** | Native LSP API (`vim.lsp.config`) | |
| **Git** | lazy.nvim clones plugins on first launch | |
| **C compiler** (gcc / clang) | nvim-treesitter compiles parsers | |
| **Node.js + npm** | pyright (LSP) and vim-doge | |
| **ripgrep** (`rg`) | Telescope live grep, Spectre | |
| **SQLite** (`libsqlite3`) | telescope-frecency database | |

## First launch

lazy.nvim bootstraps itself automatically. On the first open, run:

```
:Lazy sync        " install all plugins
:TSInstall all    " compile treesitter parsers
```

Mason auto-installs `pyright`, `rust-analyzer`, and `gopls` on startup.

## Structure

```
lua/
  config/
    options.lua    - vim options
    keymaps.lua    - keybindings
    autocmds.lua   - autocommands
  plugins/
    init.lua       - lazy.nvim bootstrap + plugin specs
    lsp/
      servers.lua  - LSP server configuration
      nvim-cmp.lua - completion setup
      utils.lua    - shared LSP helpers
```
