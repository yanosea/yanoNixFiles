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
        "rnix",
        "rust_analyzer",
        "spectral",
        "sqlls",
        "tailwindcss",
        "taplo",
        "terraformls",
        "tsserver",
        "typos_lsp",
        "volar",
        "lemminx",
        "yamlls",
      },
      automatic_installation = true,
    })
  end,
})
-- lsp
-- go
require("lvim.lsp.manager").setup("gopls")
-- nix
require("lvim.lsp.manager").setup("rnix")
-- lua
require("lvim.lsp.manager").setup("lua_ls")
-- rust
require("lvim.lsp.manager").setup("rust_analyzer")
-- typo
require("lvim.lsp.manager").setup("typos_lsp")
-- null-ls
-- formatters
require("lvim.lsp.null-ls.formatters").setup({
  -- css
  {
    name = "prettier",
    filetypes = { "css" },
  },
  -- lua
  {
    name = "stylua",
    filetypes = { "lua" },
  },
  -- nix
  {
    name = "nixfmt",
    filetypes = { "nix" },
  },
  -- shell
  {
    name = "shfmt",
    filetypes = { "sh", "zsh" },
  },
  --rust
  {
    name = "rustfmt",
    filetypes = { "rs" },
  },
  -- typescript
  {
    name = "prettier",
    filetypes = { "typescript", "typescriptreact" },
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
