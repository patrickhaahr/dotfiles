return {
  formatters_by_ft = {
    lua = { "stylua" },
    c = { "clang_format" },
    cpp = { "clang_format" },
  },
  format_on_save = {
    timeout_ms = 500,
    lsp_fallback = true,
  },
}
