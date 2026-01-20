-- ui for selecting files, searching, and more
-- keymaps are set in lua/plugins/tools/internal/which_key_nvim.lua (<LEADER>s)
return {
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			{
				"nvim-lua/plenary.nvim",
				"nvim-tree/nvim-web-devicons",
				"MunifTanjim/nui.nvim",
				-- extensions
				"nvim-telescope/telescope-file-browser.nvim",
				{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
				{ "2kabhishek/nerdy.nvim", dependencies = { "folke/snacks.nvim" } },
				"nvim-telescope/telescope-ui-select.nvim",
				"debugloop/telescope-undo.nvim",
				"zschreur/telescope-jj.nvim",
			},
		},
		lazy = true,
		cmd = "Telescope",
		config = function()
			local actions = require("telescope.actions")
			-- telescope.nvim config
			require("telescope").setup({
				theme = "cursor",
				defaults = {
					prompt_prefix = " ",
					selection_caret = " ",
					entry_prefix = "  ",
					initial_mode = "insert",
					selection_strategy = "reset",
					path_display = { "smart" },
					winblend = 0,
					border = {},
					color_devicons = true,
					set_env = { ["COLORTERM"] = "truecolor" },
					vimgrep_arguments = {
						"rg",
						"--color=never",
						"--no-heading",
						"--with-filename",
						"--line-number",
						"--column",
						"--smart-case",
						"--hidden",
						"--glob=!.git/",
					},
					mappings = {
						i = {
							["<C-n>"] = actions.move_selection_next,
							["<C-p>"] = actions.move_selection_previous,
							["<C-c>"] = actions.close,
							["<C-j>"] = actions.cycle_history_next,
							["<C-k>"] = actions.cycle_history_prev,
							["<C-q>"] = function(...)
								actions.smart_send_to_qflist(...)
								actions.open_qflist(...)
							end,
							["<CR>"] = actions.select_default,
						},
						n = {
							["<C-n>"] = actions.move_selection_next,
							["<C-p>"] = actions.move_selection_previous,
							["<C-q>"] = function(...)
								actions.smart_send_to_qflist(...)
								actions.open_qflist(...)
							end,
						},
					},
				},
				pickers = {
					find_files = {
						hidden = true,
					},
					live_grep = {
						only_sort_text = true,
					},
					grep_string = {
						only_sort_text = true,
					},
					buffers = {
						initial_mode = "normal",
						mappings = {
							i = {
								["<C-d>"] = actions.delete_buffer,
							},
							n = {
								["dd"] = actions.delete_buffer,
							},
						},
					},
					planets = {
						show_pluto = true,
						show_moon = true,
					},
					git_files = {
						hidden = true,
						show_untracked = true,
					},
					colorscheme = {
						enable_preview = true,
					},
				},
				extensions = {
					fzf = {
						fuzzy = true,
						override_generic_sorter = true,
						override_file_sorter = true,
						case_mode = "smart_case",
					},
					undo = {
						use_delta = true,
						side_by_side = true,
					},
				},
			})
			-- load extensions
			require("telescope").load_extension("file_browser")
			require("telescope").load_extension("fzf")
			require("telescope").load_extension("jj")
			require("telescope").load_extension("nerdy")
			require("telescope").load_extension("ui-select")
			require("telescope").load_extension("undo")
		end,
	},
}
