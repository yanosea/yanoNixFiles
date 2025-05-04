-- define tools to be installed with mason
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
        -- actions
        -- common
        "proselint",

        --formatters
        -- web
        "prettier",
        -- languages
        "nixfmt", -- nix
        "shfmt", -- shell
        "stylua", -- lua

        -- linters
        -- languages
        "golangci-lint", -- go
        "shellcheck", -- shell
      },
    })
  end,
})
