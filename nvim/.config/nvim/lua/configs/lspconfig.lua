-- configs/lspconfig.lua
local nvlsp = require "nvchad.configs.lspconfig"

-- Load NvChad defaults (on_attach, capabilities, etc.)
nvlsp.defaults()

local lspconfig = require "lspconfig"

-- Setup clangd
lspconfig.clangd.setup {
  on_attach = nvlsp.on_attach,
  capabilities = nvlsp.capabilities,
  cmd = { "clangd", "--background-index", "--clang-tidy" },
}

lspconfig.csharp_ls.setup({})

local null_ls = require("null-ls")
null_ls.setup({
  sources = {
    null_ls.builtins.formatting.csharpier,
  },
})
