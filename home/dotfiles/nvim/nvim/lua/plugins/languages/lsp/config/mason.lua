-- lsp config
return {
	{
		"williamboman/mason.nvim",
		dependencies = {
			"williamboman/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
		},
		lazy = true,
		event = { "BufReadPost", "BufNewFile" },
		cmd = {
			"Mason",
			"MasonUpdate",
			"MasonLog",
			"MasonInstall",
			"MasonUninstall",
			"MasonToolsClean",
			"MasonToolsUpdate",
			"MasonToolsInstall",
			"MasonUninstallAll",
			"MasonToolsUpdateSync",
			"MasonToolsInstallSync",
		},
		config = function()
			-- setup mason
			require("mason").setup()
			-- install lsp servers
			local ensure_installed_server = require("plugins.languages.lsp.utils.server_list").servers
			require("mason-lspconfig").setup({
				ensure_installed = ensure_installed_server,
			})
			-- install tools
			local ensure_installed_tools = require("plugins.languages.lsp.utils.server_list").tools
			require("mason-tool-installer").setup({
				ensure_installed = ensure_installed_tools,
			})
		end,
	},
}
