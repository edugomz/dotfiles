local utils = require('plugins.lsp.utils')

local capabilities = utils.capabilities()

local on_attach = function(client, bufnr)
  utils.mappings(bufnr)
  if client.server_capabilities.signatureHelpProvider then
    require('lsp-overloads').setup(client, {})
  end
end

-- clangd is system-installed (not Mason-managed); compiler flags go in
-- a per-project .clangd file or ~/.config/clangd/config.yaml
vim.lsp.config('clangd', {
  on_attach = on_attach,
  capabilities = capabilities,
})
vim.lsp.enable('clangd')

-- Mason-managed servers. `vim.lsp.config('*', ...)` applies on_attach +
-- capabilities to every server (mason-lspconfig's `automatic_enable` calls
-- `vim.lsp.enable` for whatever's installed, merging in this base config).
-- Add a named `vim.lsp.config(name, ...)` override only for servers that
-- need custom settings. To add a new server: add it to ensure_installed; no
-- other change needed unless it requires custom settings.
vim.lsp.config('*', {
  on_attach = on_attach,
  capabilities = capabilities,
})

vim.lsp.config('pyright', {
  settings = {
    python = {
      analysis = {
        typeCheckingMode = "basic",
        ignore = { "conanfile.py" },
      },
    },
  },
})

require('mason-lspconfig').setup({
  ensure_installed = { 'pyright', 'rust_analyzer', 'gopls', 'marksman' },
})
