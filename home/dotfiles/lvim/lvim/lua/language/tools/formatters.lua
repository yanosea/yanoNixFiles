-- formatter config
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
