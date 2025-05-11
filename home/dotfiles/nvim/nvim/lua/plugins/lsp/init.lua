-- lsp config
return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
    lazy = true,
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local ensure_installed = {
        "efm",
        "gopls",
        "lua_ls",
      }
      require("mason").setup()
      require("mason-lspconfig").setup({
        automatic_installation = true,
        ensure_installed = ensure_installed,
      })
      local colors = require("utils.colors").colors
      local icons = require("utils.icons").icons
      vim.diagnostic.config({
        virtual_text = true,
        update_in_insert = false,
        underline = true,
        severity_sort = true,
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = icons.diagnostics.BoldError,
            [vim.diagnostic.severity.WARN] = icons.diagnostics.BoldWarning,
            [vim.diagnostic.severity.INFO] = icons.diagnostics.BoldInformation,
            [vim.diagnostic.severity.HINT] = icons.diagnostics.BoldHint,
          },
          texthl = {
            [vim.diagnostic.severity.ERROR] = { fg = colors.Red },
            [vim.diagnostic.severity.WARN] = { fg = colors.Yellow },
            [vim.diagnostic.severity.INFO] = { fg = colors.Blue },
            [vim.diagnostic.severity.HINT] = { fg = colors.Green },
          },
        },
        float = {
          source = "always",
          border = "rounded",
          header = "",
          prefix = "",
        },
      })
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            diagnostics = {
              globals = {
                "nvim",
                "vim",
              },
            },
          },
        },
      })
      vim.lsp.enable(ensure_installed)
    end,
  },
}
