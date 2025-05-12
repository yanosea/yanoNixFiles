-- lsp config
return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "folke/neodev.nvim",
    },
    lazy = true,
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      -- LspInfo コマンドの実装をインポート
      require("plugins.languages.lsp.utils.lsp_info").setup()

      -- Mason セットアップ
      require("mason").setup()
      require("mason-lspconfig").setup({
        automatic_installation = true,
        ensure_installed = {
          "efm",
          "gopls",
          "lua_ls",
        },
      })

      -- 診断表示の設定
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
          source = true,
          border = "single",
          header = "",
          prefix = "",
        },
      })

      -- Neodev セットアップ
      require("neodev").setup({
        library = {
          enabled = true,
          runtime = true,
          types = true,
          plugins = true,
        },
        setup_jsonls = true,
        lspconfig = true,
        pathStrict = true,
      })

      -- LSPウィンドウの設定
      require("lspconfig.ui.windows").default_options = {
        border = "single",
      }

      -- サーバー設定を適用
      local ensure_installed = {
        "efm",
        "gopls",
        "lua_ls",
      }
      vim.lsp.enable(ensure_installed)
    end,
  },
}
