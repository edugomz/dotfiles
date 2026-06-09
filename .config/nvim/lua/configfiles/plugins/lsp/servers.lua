local utils = require('configfiles.plugins.lsp.utils')

local lsp_flags = {
  debounce_text_changes = 150,
  allow_incremental_sync = true,
}

local capabilities = utils.capabilities()


-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  utils.mappings(bufnr)
  if client.server_capabilities.signatureHelpProvider then
    require('lsp-overloads').setup(client, { })
  end
end

local default_attach = function(name) 
  vim.lsp.config(name, {
    on_attach = on_attach,
    flags = lsp_flags,
    capabilities = capabilities,
  })
  vim.lsp.enable(name)
end

-- require('lspconfig')['clangd'].setup{
vim.lsp.config('clangd', {
  on_attach = on_attach,
  flags = lsp_flags,
  capabilities = capabilities,
  -- cmd = { "clangd", "--completion-style=detailed"},
  cmd = { "clangd",  "--query-driver=/usr/bin/g++-12" },
})
vim.lsp.enable('clangd')


-- require('lspconfig')['pyright'].setup{
vim.lsp.config('pyright', {
  cmd = {
    vim.fn.expand("~/.local/share/nvim/lsp_servers/pyright/node_modules/.bin/pyright-langserver"),
    "--stdio"
  },

  on_attach = on_attach,
  flags = lsp_flags,
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

-- https://luals.github.io/#neovim-install
-- require('lspconfig')['lua_ls'].setup{
--   on_attach = on_attach,
--   flags = lsp_flags,
--   capabilities = capabilities,
--   settings = {
--     Lua = {
--       completion = {
--         enable = true,
--       },
--       diagnostics = { globals = { 'vim' }}
--     }
--   }
-- }
-- require('lspconfig')['rust_analyzer'].setup{
--   on_attach = on_attach,
--   flags = lsp_flags,
--   capabilities = capabilities,
--   settings = {
--     ["rust-analyzer"] = {}
--   }
-- }

vim.lsp.config('rust_analyzer', {
  cmd = {
    vim.fn.expand("~/.local/share/nvim/lsp_servers/rust_analyzer/rust-analyzer"),
    -- "--stdio"
  },
  on_attach = on_attach,
  flags = lsp_flags,
  capabilities = capabilities,
})
vim.lsp.enable('rust_analyzer')



-- require('lspconfig')['texlab'].setup{
--   on_attach = on_attach,
--   flags = lsp_flags,
--   capabilities = capabilities,
-- }
--
-- require('lspconfig')['gopls'].setup{
--   on_attach = on_attach,
--   flags = lsp_flags,
--   capabilities = capabilities,
-- }

-- default_attach('bashls')
-- default_attach('cmake')

vim.lsp.config('cmake', {
    cmd = {
    vim.fn.expand("~/.local/share/nvim/lsp_servers/cmake/venv/bin/cmake-language-server")
  },
  on_attach = on_attach,
  flags = lsp_flags,
  capabilities = capabilities,
})
vim.lsp.enable('cmake')

vim.lsp.config('gopls', {
    cmd = {
    vim.fn.expand("~/.local/share/nvim/lsp_servers/gopls/gopls")
  },
  on_attach = on_attach,
  flags = lsp_flags,
  capabilities = capabilities,
})
vim.lsp.enable('gopls')

-- require('lspconfig')['cmake'].setup{
--   on_attach = on_attach,
--   flags = lsp_flags,
--   capabilities = capabilities,
-- }
-- require('lspconfig')['asm_lsp'].setup{
--   on_attach = on_attach,
--   flags = lsp_flags,
--   capabilities = capabilities,
-- }
-- require('lspconfig')['omnisharp'].setup{
--   on_attach = on_attach,
--   flags = lsp_flags,
--   capabilities = capabilities,
-- }
--
-- require('lspconfig')['yamlls'].setup{
--   on_attach = on_attach,
--   flags = lsp_flags,
--   capabilities = capabilities,
-- }
