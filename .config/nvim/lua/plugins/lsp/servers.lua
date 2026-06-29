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

-- Mason-managed servers. The default handler applies on_attach + capabilities
-- to every installed server. Add a named handler only for servers that need
-- custom settings. To add a new server: add it to ensure_installed; no other
-- change needed unless it requires custom settings.
require('mason-lspconfig').setup({
  ensure_installed = { 'pyright', 'rust_analyzer', 'gopls' },
  handlers = {
    function(server_name)
      require('lspconfig')[server_name].setup({
        on_attach = on_attach,
        capabilities = capabilities,
      })
    end,
    ['pyright'] = function()
      require('lspconfig').pyright.setup({
        on_attach = on_attach,
        capabilities = capabilities,
        settings = {
          python = {
            analysis = {
              typeCheckingMode = "basic",
              ignore = { "conanfile.py" },
            },
          },
        },
      })
    end,
  },
})
