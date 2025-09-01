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
