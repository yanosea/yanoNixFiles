-- common config
require("config.options")
require("config.keymaps")
require("config.autocmds")
-- load wsl config if running in WSL
if vim.env.WSL_DISTRO_NAME ~= nil then
	require("config.wsl")
end
-- plugin manager
require("config.plugin_manager")
-- neovim plugins
-- enable filetype detection
-- enable filetype plugin indent
vim.cmd("filetype plugin indent on")
-- enable syntax highlighting
vim.cmd("syntax on")
