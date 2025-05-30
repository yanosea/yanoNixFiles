-- pretty list for showing diagnostics, references, telescope results, quickfix and location lists
-- keymaps are set in lua/plugins/tools/internal/which_key_nvim.lua (<LEADER>lt)
return {
	{
		"folke/trouble.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		lazy = true,
		cmd = { "Trouble", "TroubleToggle" },
		-- trouble.nvim config
		opts = {
			auto_close = false,
			auto_open = false,
			auto_preview = true,
			auto_refresh = true,
			auto_jump = false,
			focus = false,
			restore = true,
			follow = true,
			indent_guides = true,
			max_items = 200,
			multiline = true,
			pinned = false,
			warn_no_results = true,
			open_no_results = false,
			win = {},
			preview = {
				type = "main",
				scratch = true,
			},
			throttle = {
				refresh = 20,
				update = 10,
				render = 10,
				follow = 100,
				preview = { ms = 100, debounce = true },
			},
			keys = {
				["?"] = "help",
				r = "refresh",
				R = "toggle_refresh",
				q = "close",
				o = "jump_close",
				["<ESC>"] = "cancel",
				["<CR>"] = "jump",
				["<2-leftmouse>"] = "jump",
				["<c-s>"] = "jump_split",
				["<c-v>"] = "jump_vsplit",
				["}"] = "next",
				["]]"] = "next",
				["{"] = "prev",
				["[["] = "prev",
				i = "inspect",
				p = "preview",
				P = "toggle_preview",
				zo = "fold_open",
				zO = "fold_open_recursive",
				zc = "fold_close",
				zC = "fold_close_recursive",
				za = "fold_toggle",
				zA = "fold_toggle_recursive",
				zm = "fold_more",
				zM = "fold_close_all",
				zr = "fold_reduce",
				zR = "fold_open_all",
				zx = "fold_update",
				zX = "fold_update_all",
				zn = "fold_disable",
				zN = "fold_enable",
				zi = "fold_toggle_enable",
				gb = {
					action = function(view)
						view.state.filter_buffer = not view.state.filter_buffer
						view:filter(view.state.filter_buffer and { buf = 0 } or nil)
					end,
					desc = "Toggle Current Buffer Filter",
				},
			},
			modes = {
				symbols = {
					desc = "document symbols",
					mode = "lsp_document_symbols",
					focus = false,
					win = { position = "right" },
					filter = {
						["not"] = { ft = "lua", kind = "Package" },
						any = {
							ft = { "help", "markdown" },
							kind = {
								"Class",
								"Constructor",
								"Enum",
								"Field",
								"Function",
								"Interface",
								"Method",
								"Module",
								"Namespace",
								"Package",
								"Property",
								"Struct",
								"Trait",
							},
						},
					},
				},
			},
		},
	},
}
