-- show indent lines
return {
	{
		"shellRaining/hlchunk.nvim",
		lazy = true,
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			-- hlchunk.nvim config
			local icons = require("utils.icons").icons
			local colors = require("utils.colors").colors
			require("hlchunk").setup({
				chunk = {
					enable = true,
					notify = true,
					use_treesitter = true,
					support_filetypes = "",
					exclude_filetypes = {
						aerial = true,
						dashboard = true,
						help = true,
						lspinfo = true,
						lspsagafinder = true,
						packer = true,
						checkhealth = true,
						man = true,
						mason = true,
						NvimTree = true,
						["neo-tree"] = true,
						plugin = true,
						lazy = true,
						TelescopePrompt = true,
						[""] = true,
						alpha = true,
						toggleterm = true,
						sagafinder = true,
						sagaoutline = true,
						better_term = true,
						fugitiveblame = true,
						Trouble = true,
						qf = true,
						Outline = true,
						starter = true,
						NeogitPopup = true,
						NeogitStatus = true,
						DiffviewFiles = true,
						DiffviewFileHistory = true,
						DressingInput = true,
						spectre_panel = true,
						zsh = true,
						registers = true,
						startuptime = true,
						OverseerList = true,
						Navbuddy = true,
						noice = true,
						notify = true,
						["dap-repl"] = true,
						saga_codeaction = true,
						sagarename = true,
						cmp_menu = true,
						["null-ls-info"] = true,
					},
					chars = {
						horizontal_line = icons.ui.LineHorizontal,
						vertical_line = icons.ui.LineMiddle,
						left_top = icons.ui.LineLeftTop,
						left_bottom = icons.ui.LineLeftBottom,
						right_arrow = icons.ui.LineRightArrow,
					},
					style = {
						{ fg = colors.Blue },
						{ fg = colors.Red },
					},
					textobject = "",
					max_file_size = 1024 * 1024,
					error_sign = true,
				},
				indent = {
					enable = false,
					use_treesitter = true,
					chars = {
						icons.ui.LineMiddle,
					},
					style = {
						{ fg = vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID("Whitespace")), "fg", "gui") },
					},
				},
				line_num = {
					enable = true,
					use_treesitter = true,
					style = colors.Blue,
				},
				blank = {
					enable = true,
					chars = {
						icons.ui.Blank,
					},
					style = {
						vim.fn.synIDattr(vim.fn.synIDtrans(vim.fn.hlID("Whitespace")), "fg", "gui"),
					},
				},
			})
		end,
	},
}
