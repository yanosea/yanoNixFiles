-- linter config
require("lvim.lsp.null-ls.linters").setup({
  -- common
  {
    name = "proselint", -- prose
    filetypes = { "text", "markdown" },
  },
  -- languages
  {
    name = "shellcheck", -- shell
    args = { "--severity", "warning" },
  },
})
