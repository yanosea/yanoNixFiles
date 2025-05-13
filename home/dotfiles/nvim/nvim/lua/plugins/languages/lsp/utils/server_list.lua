local M = {}
-- lsp servers
M.servers = {
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
-- tools
M.tools = {
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
return M
