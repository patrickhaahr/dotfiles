-- Load NvChad mappings first
require "nvchad.mappings"

-- Override the diagnostic mapping and add debug mappings
local map = vim.keymap.set

-- Basic mappings
map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

-- Defer debug mappings until after lazy/which-key are initialized
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  callback = function()
    local ok_wk, wk = pcall(require, "which-key")
    if ok_wk then
      wk.add({ { "<leader>d", group = "debug" } })
    end

    -- Override the default <leader>ds mapping from NvChad
    map("n", "<leader>ds", vim.diagnostic.setloclist, { desc = "LSP diagnostic loclist" })

    -- Debug mappings are provided via plugin specs (which ensures proper lazy/which-key integration)

    map("n", "<leader>dt", function()
      vim.cmd("RustLsp testables")
    end, { desc = "debug rust testables" })
  end,
})
