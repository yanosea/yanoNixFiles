-- formatter config
-- automatically install missing formatter
table.insert(lvim.plugins, {
  "WhoIsSethDaniel/mason-tool-installer.nvim",
  dependencies = {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
  },
  config = function()
    require("mason-tool-installer").setup({
      ensure_installed = {
        -- web
        "prettier",
        "nixfmt", -- nix
        "shfmt", -- shell
        "stylua", -- lua
      },
    })
  end,
})
require("lvim.lsp.null-ls.formatters").setup({
  -- web
  {
    name = "prettier",
    filetypes = {
      "astro",
      "css",
      "html",
      "javascript",
      "json",
      "markdown",
      "scss",
      "typescript",
    },
  },
  -- languages
  {
    name = "nixfmt", -- nix
    filetypes = { "nix" },
  },
  {
    name = "shfmt", -- shell
    filetypes = { "sh" },
  },
  {
    name = "stylua", -- lua
    filetypes = { "lua" },
  },
})
