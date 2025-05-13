-- lsp config
return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      "folke/neodev.nvim",
    },
    lazy = true,
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      -- overwrite LspInfo command
      require("plugins.languages.lsp.utils.lsp_info").setup()
      -- define lsp servers
      local ensure_installed_server = {
        -- common
        "ast_grep",
        "efm",
        "diagnosticls",
        "typos_lsp",
        -- config files
        "docker_compose_language_service",
        "dockerls",
        "taplo", -- toml
        "yamlls",
        -- web
        "astro",
        "cssls",
        "html",
        "jsonls",
        "marksman", -- markdown
        "tailwindcss",
        -- languages
        "bashls",
        "golangci_lint_ls",
        "gopls",
        "lua_ls",
        "nil_ls", -- nix
        "rust_analyzer",
        "sqlls",
      }
      local ensure_installed_tools = {
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
      }
      require("mason").setup()
      require("mason-lspconfig").setup({
        automatic_installation = true,
        ensure_installed = ensure_installed_server,
      })
      require("mason-tool-installer").setup({
        automatic_installation = true,
        ensure_installed = ensure_installed_tools,
      })
      -- diagnostics config
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
      require("lspconfig.ui.windows").default_options = {
        border = "single",
      }
      vim.lsp.enable(ensure_installed_server)
    end,
  },
}
