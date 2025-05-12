-- syntax highlighting and code folding
return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = true,
    cmd = {
      "TSInstall",
      "TSUninstall",
      "TSUpdate",
      "TSUpdateSync",
      "TSInstallInfo",
      "TSInstallSync",
      "TSInstallFromGrammar",
    },
    event = "BufRead",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
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
        },
      })
    end,
  },
}
