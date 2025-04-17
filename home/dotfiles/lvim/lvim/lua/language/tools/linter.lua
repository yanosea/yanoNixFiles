-- linter config
-- automatically install missing linters
table.insert(lvim.plugins, {
  "WhoIsSethDaniel/mason-tool-installer.nvim",
  dependencies = {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
  },
  config = function()
    require("mason-tool-installer").setup({
      ensure_installed = {
        -- common
        "proselint",
        -- languages
        "shellcheck", -- shell
      },
    })
  end,
})
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
