-- go lsp config
-- gopls
require("lvim.lsp.manager").setup("gopls", {
  cmd = { "gopls" },
  filetypes = { "go", "gomod" },
  root_markers = {
    ".git",
    "go.mod",
    "go.work",
  },
  init_options = {
    usePlaceholders = true,
    analyses = {
      shadow = true,
    },
    staticcheck = true,
    hints = {
      assignVariableTypes = true,
      compositeLiteralFields = true,
      compositeLiteralTypes = true,
      constantValues = true,
      functionTypeParameters = true,
      parameterNames = true,
      rangeVariableTypes = true,
    },
  },
})
-- golangci_lint_ls
require("lvim.lsp.manager").setup("golangci_lint_ls", {
  cmd = { "golangci-lint-langserver" },
  filetypes = { "go", "gomod" },
  root_markers = {
    ".golangci.yml",
    ".golangci.yaml",
    ".golangci.toml",
    ".golangci.json",
    ".git",
    "go.mod",
    "go.work",
  },
  init_options = {
    command = {
      "golangci-lint",
      "run",
      "--output.json.path=stdout",
      "--show-stats=false",
      "--issues-exit-code=1",
    },
  },
})
