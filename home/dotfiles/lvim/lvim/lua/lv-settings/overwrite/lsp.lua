-- lsp config
table.insert(lvim.plugins, {
  "williamboman/mason-lspconfig.nvim",
  dependencies = { "williamboman/mason.nvim" },
  event = { "BufRead", "BufEnter" },
  init = function()
    require("mason-lspconfig").setup({
      -- install lsp servers
      ensure_installed = {
        "angularls",
        "arduino_language_server",
        "astro",
        "bashls",
        "clangd",
        "cssls",
        "denols",
        "diagnosticls",
        "docker_compose_language_service",
        "dockerls",
        "efm",
        "elmls",
        "eslint",
        "gopls",
        "gradle_ls",
        "html",
        "intelephense",
        "jedi_language_server",
        "jsonls",
        "jdtls",
        "kotlin_language_server",
        "lua_ls",
        "marksman",
        "omnisharp_mono",
        "perlnavigator",
        "powershell_es",
        "pyright",
        "rust_analyzer",
        "spectral",
        "sqlls",
        "tailwindcss",
        "taplo",
        "terraformls",
        "tsserver",
        "volar",
        "lemminx",
        "yamlls",
      },
      automatic_installation = true,
    })
  end,
})
-- null-ls
-- formatters
require("lvim.lsp.null-ls.formatters").setup({
  -- lua
  {
    name = "stylua",
    filetypes = { "lua" },
  },
  -- typescript
  {
    name = "prettier",
    args = { "--print-width", "100" },
    filetypes = { "typescript", "typescriptreact" },
  },
  -- shell
  {
    name = "shfmt",
    filetypes = { "sh", "zsh" },
  },
})
-- linters
require("lvim.lsp.null-ls.linters").setup({
  -- shell
  {
    name = "shellcheck",
    args = { "--severity", "warning" },
    filetypes = { "sh" },
  },
})
-- code actions
require("lvim.lsp.null-ls.code_actions").setup({
  -- proselint
  {
    name = "proselint",
  },
})
