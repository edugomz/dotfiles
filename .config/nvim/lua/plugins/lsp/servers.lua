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

vim.lsp.config('pyright', {
  on_attach = on_attach,
  capabilities = capabilities,
  settings = {
    python = {
      analysis = {
        typeCheckingMode = "basic",
        ignore = { "conanfile.py" }
      }
    },
  }
})
vim.lsp.enable('pyright')

vim.lsp.config('rust_analyzer', {
  on_attach = on_attach,
  capabilities = capabilities,
})
vim.lsp.enable('rust_analyzer')

vim.lsp.config('gopls', {
  on_attach = on_attach,
  capabilities = capabilities,
})
vim.lsp.enable('gopls')
