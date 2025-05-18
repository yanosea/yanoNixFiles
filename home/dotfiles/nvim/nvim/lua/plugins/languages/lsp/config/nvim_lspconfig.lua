-- lsp config
-- keymaps are set in lua/pulugins/tools/internal/which_key_nvim.lua (<LEADER><SPACE>)
return {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			"creativenull/efmls-configs-nvim",
			"b0o/schemastore.nvim",
		},
		lazy = true,
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			-- keymaps
			require("plugins.languages.lsp.utils.keymaps").setup()
			-- overwrite :LspInfo command
			require("plugins.languages.lsp.utils.lsp_info").setup()
			-- load lsp servers
			local servers = require("plugins.languages.lsp.utils.server_list").servers
			require("mason").setup()
			-- diagnostics config
			local colors = require("utils.colors").colors
			local icons = require("utils.icons").icons
			vim.diagnostic.config({
				virtual_text = true,
				update_in_insert = false,
				underline = true,
				severity_sort = true,
				signs = {
					text = {
						[vim.diagnostic.severity.ERROR] = icons.diagnostics.BoldError,
						[vim.diagnostic.severity.WARN] = icons.diagnostics.BoldWarning,
						[vim.diagnostic.severity.INFO] = icons.diagnostics.BoldInformation,
						[vim.diagnostic.severity.HINT] = icons.diagnostics.BoldHint,
					},
					texthl = {
						[vim.diagnostic.severity.ERROR] = { fg = colors.Red },
						[vim.diagnostic.severity.WARN] = { fg = colors.Yellow },
						[vim.diagnostic.severity.INFO] = { fg = colors.Blue },
						[vim.diagnostic.severity.HINT] = { fg = colors.Green },
					},
				},
				float = {
					source = true,
					border = "single",
					header = "",
					prefix = "",
				},
			})
			-- lsp ui config
			require("lspconfig.ui.windows").default_options = {
				-- set border to single line
				border = "single",
			}
			-- set up lsp servers
			require("plugins.languages.lsp.utils.setup_servers").setup(servers)
		end,
	},
}
