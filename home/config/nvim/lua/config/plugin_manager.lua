-- plugin manager config (lazy.nvim)
-- clone lazy.nvim if not cloned yet in $XDG_DATA_HOME/nvim/lazy/lazy.nvim
-- keymaps are set in lua/plugins/tools/internal/which_key_nvim.lua (<LEADER>p : plugins)
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
-- get plugin spec with IS_FLOATING_VIM env var
local function get_plugin_spec()
	-- path from `$XDG_CONFIG_HOME/nvim/lua/init.lua`
	if vim.env.IS_FLOATING_VIM == "1" then
		-- load only a plugin for floating vim (ime use)
		return { { import = "plugins.ime" } }
	else
		-- load all plugins
		return {
			{ import = "plugins.editor" },
			{ import = "plugins.ime" },
			{ import = "plugins.tools" },
			{ import = "plugins.ui" },
			{ import = "plugins.languages" },
		}
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
		-- always use the latest version of the plugin
		version = false,
	},
	-- load plugins
	spec = get_plugin_spec(),
	-- plugin installation behavior
	install = {
		-- habamax is the default theme
		colorscheme = { "everforest", "habamax" },
	},
	-- lazy.nvim ui config
	ui = {
		-- set border to single line
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
		cache = {
			-- enable lazy.nvim cache
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
				-- study vim (:Tutor)
				"tutor",
				-- be able to edit files under zip
				"zipPlugin",
			},
		},
	},
})
