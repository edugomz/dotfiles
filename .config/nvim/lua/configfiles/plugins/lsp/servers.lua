local utils = require('configfiles.plugins.lsp.utils')

local capabilities = utils.capabilities()

local on_attach = function(client, bufnr)
  utils.mappings(bufnr)
  if client.server_capabilities.signatureHelpProvider then
    require('lsp-overloads').setup(client, {})
  end
end

-- system-installed; custom flag needed for cross-compilation header resolution
vim.lsp.config('clangd', {
  on_attach = on_attach,
  capabilities = capabilities,
  cmd = { "clangd", "--query-driver=/usr/bin/g++-12" },
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

vim.lsp.config('cmake', {
  on_attach = on_attach,
  capabilities = capabilities,
})
vim.lsp.enable('cmake')

vim.lsp.config('gopls', {
  on_attach = on_attach,
  capabilities = capabilities,
})
vim.lsp.enable('gopls')
