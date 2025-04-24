-- action config
-- automatically install missing tools
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
      },
    })
  end,
})
require("lvim.lsp.null-ls.code_actions").setup({
  -- common
  {
    name = "proselint",
  },
})
