-- action config
require("lvim.lsp.null-ls.code_actions").setup({
  -- common
  {
    name = "proselint", -- prose
    filetypes = { "text", "markdown" },
  },
})
