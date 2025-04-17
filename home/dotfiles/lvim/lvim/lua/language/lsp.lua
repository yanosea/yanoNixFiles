-- lsp config
-- automatically install missing servers
table.insert(lvim.plugins, {
  "williamboman/mason-lspconfig.nvim",
  dependencies = {
    "williamboman/mason.nvim",
  },
  config = function()
    require("mason-lspconfig").setup({
      ensure_installed = {
        -- common
        "ast_grep",
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
      },
      automatic_installation = true,
    })
  end,
})
-- skip automatic installation of servers
vim.list_extend(lvim.lsp.installer.setup.automatic_installation.exclude, {
  -- common
  "snyk_ls",
})
-- skip automatic configuration of servers
vim.list_extend(lvim.lsp.automatic_configuration.skipped_servers, {
  -- languages
  "golangci_lint_ls",
})
-- skip automatic configuration of filetypes
vim.list_extend(lvim.lsp.automatic_configuration.skipped_filetypes, {
  -- languages
  "go",
})
-- explicitly configure servers
-- common
require("lvim.lsp.manager").setup("ast_grep") -- AST
require("lvim.lsp.manager").setup("diagnosticls") -- diagnostic
require("lvim.lsp.manager").setup("typos_lsp") -- typos
