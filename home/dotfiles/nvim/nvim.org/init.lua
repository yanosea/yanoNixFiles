-- yanosea nvim initialize
-- fast loader
if vim.loader then
  vim.loader.enable()
end
-- preferences
require("config.options")
-- keymaps
require("config.keymaps")
-- auto commands
require("config.autocmds")
-- plugins
require("config.lazy")
