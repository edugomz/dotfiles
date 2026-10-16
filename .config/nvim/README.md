# Nvim config

![dashboard of config](nvim_capture.png)

## Requirements

| Dependency | Purpose | Notes |
|---|---|---|
| **Neovim 0.12+** | nvim-treesitter `main` branch, native LSP API (`vim.lsp.config`) | |
| **Git** | lazy.nvim clones plugins on first launch | |
| **C compiler** (gcc / clang) + **tree-sitter CLI 0.26.1+** | nvim-treesitter (`main` branch) builds parsers | |
| **Node.js + npm** | pyright (LSP) | |
| **Go** | Mason builds gopls | |
| **curl, unzip, tar, gzip** | Mason downloads, vim-doge binary | |
| **ripgrep** (`rg`), **fd** | Telescope live grep and file pickers, Spectre | |
| **clangd** | C/C++ LSP, system-installed | |
| **xxd** | hex.nvim | |
| **ImageMagick** (`magick`, or `convert` + `identify`) | image.nvim | |

`install.sh nvim` at the dotfiles root installs the missing ones (pacman or apt, with nvim and tree-sitter from the package manager or their GitHub releases, see `install.sh --help`).

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
