-- ~/.config/nvim/lua/custom/autocmds.lua

vim.api.nvim_create_autocmd("VimEnter", {
  pattern = "*",
  callback = function()
    -- This will run after Nvim has fully started up.
    -- Reduce the delay to minimize visual flickering.
    vim.defer_fn(function()
      vim.cmd("highlight Normal guibg=NONE")
      vim.cmd("highlight EndOfBuffer guibg=NONE")
      vim.cmd("highlight NonText guibg=NONE")
      vim.cmd("highlight LineNr guibg=NONE")
      vim.cmd("highlight SignColumn guibg=NONE")
      vim.cmd("highlight FoldColumn guibg=NONE")
      vim.cmd("highlight NormalFloat guibg=NONE")
      vim.cmd("highlight CursorLine guibg=NONE")
      vim.cmd("highlight CursorColumn guibg=NONE")

      -- You can remove this print statement now if you wish
      -- print("Transparency highlights applied!")
    end, 0) -- Changed delay to 0 (or a very small number like 5 or 10)
  end,
})
