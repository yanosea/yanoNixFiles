-- go lsp config
-- gopls
require("lvim.lsp.manager").setup("gopls", {
  cmd = { "gopls" },
  filetypes = { "go", "gomod" },
  root_markers = {
    ".git",
    "go.work",
    "go.mod",
  },
  init_options = {
    usePlaceholders = true,
    completeUnimported = true,
    staticcheck = true,
    analyses = {
      unusedparams = true,
      nilness = true,
      shadow = true,
      unusedwrite = true,
      fieldalignment = true,
      unreachable = true,
      useany = true,
      useanytypeassertion = true,
      useanytypeassertiontypeparams = true,
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
    "go.work",
    "go.mod",
    ".git",
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
