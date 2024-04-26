-- plugins
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
    { import = "plugins.git" },
    { import = "plugins.gui" },
    { import = "plugins.lsp" },
    { import = "plugins.style" },
    { import = "plugins.util" },
  },
  concurrency = 10,
  install = { colorscheme = { "nord" } },
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
