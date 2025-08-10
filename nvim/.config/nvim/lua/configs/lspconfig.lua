require("nvchad.configs.lspconfig").defaults()

local lspconfig = require "lspconfig"

-- Only configure rust-analyzer since you're using rustaceanvim
-- No need to configure servers that aren't installed
