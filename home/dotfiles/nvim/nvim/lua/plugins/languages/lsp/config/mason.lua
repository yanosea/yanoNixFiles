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
			local registry = require("mason-registry")
			local ensure_installed_tools = require("plugins.languages.lsp.utils.server_list").tools
			require("mason-tool-installer").setup({
				ensure_installed = ensure_installed_tools,
			})
			registry.refresh(function()
				for _, name in pairs(ensure_installed_tools) do
					local package = registry.get_package(name)
					if not registry.is_installed(name) then
						package:install()
					end
				end
			end)
		end,
	},
}
