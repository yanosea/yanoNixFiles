-- plugin manager config (lazy.nvim)
-- clone lazy.nvim if not clone yet in $XDG_DATA_HOME/lazy/lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
-- add lazy.nvim to runtimepath
vim.opt.rtp:prepend(lazypath)
-- lazy.nvim plugin manager config
require("lazy").setup({
  -- load plugins lazily by default
  defaults = {
    -- not lazy load by default
    lazy = false,
    version = false,
  },
  -- load plugins
  spec = {
    { import = "plugins" },
  },
  -- limit the maximum number of concurrent tasks
  concurrency = vim.uv.available_parallelism() * 2,
  -- plugin installation behavior
  install = {
    colorscheme = { "everforest" },
  },
  -- lazy.nvim ui config
  ui = {
    border = "single",
  },
  -- config file change detection
  change_detection = {
    -- disable because $XDG_CONFIG_HOME is managed by nix
    enabled = false,
    notify = false,
  },
  -- performance settings
  performance = {
    -- enable lazy.nvim cache
    cache = {
      enabled = true,
    },
    rtp = {
      disabled_plugins = {
        -- be able to edit files under gzip
        "gzip",
        -- file explorer
        "netrwPlugin",
        -- remote plugins to use vim plugins written in python, ruby, etc
        "rplugin",
        -- save and load vim sessions
        "shada",
        -- be able to edit files under tar
        "tarPlugin",
        -- convert current buffer to html(:TOhtml)
        "tohtml",
        "2html_plugin",
        -- study vim (:Tutor)
        "tutor",
        -- be able to edit files under zip
        "zipPlugin",
      },
    },
  },
})
