-- neovim config entry point
-- lazy loading
if vim.loader then
	vim.loader.enable()
end
-- load config
require("config")
