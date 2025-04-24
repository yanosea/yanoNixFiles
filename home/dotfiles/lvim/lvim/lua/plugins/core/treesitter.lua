-- treesitter config
-- enable treesitter
lvim.builtin.treesitter.matchup.enable = true
-- install treesitter parsers
--
vim.list_extend(lvim.builtin.treesitter.ensure_installed, {
  -- common
  "comment",
  "diff",
  "regex",
  -- version control
  "git_config",
  "git_rebase",
  "gitattributes",
  "gitcommit",
  "gitignore",
  -- config files
  "dockerfile",
  "ini",
  "make",
  "toml",
  "yaml",
  -- web
  "astro",
  "css",
  "html",
  "javascript",
  "jsdoc",
  "json",
  "jsonc",
  "markdown",
  "markdown_inline",
  "scss",
  "tsx",
  "typescript",
  -- languages
  "bash",
  "go",
  "gomod",
  "gosum",
  "lua",
  "nix",
  "rust",
  "sql",
})
