-- initialize lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  defaults = { lazy = true },
  spec = {
    {
      "neanias/everforest-nvim",
      init = function()
        vim.cmd("colorscheme everforest")
      end,
    },
    { import = "plugin" },
  },
  concurrency = 10,
  install = { colorscheme = { "everforest" } },
  performance = {
    cache = { enabled = true },
    disable_events = { "VimEnter", "BufReadPre" },
    rtp = {
      disabled_plugins = {
        "2html_plugin",
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
        "shada",
        "rplugin",
        "man",
      },
    },
  },
  ui = {
    border = "single",
  },
})
