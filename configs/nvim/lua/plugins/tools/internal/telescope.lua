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
			local previewers = require("telescope.previewers")
			local from_entry = require("telescope.from_entry")
			local conf = require("telescope.config").values
			local Path = require("plenary.path")
			-- image preview in telescope's preview pane (image.nvim integration)
			-- see: https://github.com/3rd/image.nvim/issues/183
			local image_extensions = { "svg", "png", "jpg", "jpeg", "gif", "webp", "avif" }
			local current_image, current_image_path = nil, ""
			local clear_current_image = function()
				if not current_image then
					return
				end
				current_image:clear()
				current_image = nil
			end
			local buffer_previewer_maker = function(filepath, bufnr, opts)
				if current_image and current_image_path ~= filepath then
					clear_current_image()
				end
				current_image_path = filepath
				local ext = filepath:lower():match("%.([^.]+)$")
				if ext and vim.tbl_contains(image_extensions, ext) then
					current_image = require("image").hijack_buffer(filepath, opts.winid, bufnr)
				else
					previewers.buffer_previewer_maker(filepath, bufnr, opts)
				end
			end
			local image_aware_file_previewer = function(opts)
				opts = opts or {}
				opts.preview = type(opts.preview) ~= "table" and {} or opts.preview
				if type(conf.preview) == "table" then
					for k, v in pairs(conf.preview) do
						opts.preview[k] = vim.F.if_nil(opts.preview[k], v)
					end
				end
				local cwd = opts.cwd or vim.uv.cwd()
				return previewers.new_buffer_previewer({
					title = "File Preview",
					dyn_title = function(_, entry)
						return Path:new(from_entry.path(entry, false, false)):normalize(cwd)
					end,
					get_buffer_by_name = function(_, entry)
						return from_entry.path(entry, false, false)
					end,
					define_preview = function(self, entry)
						local p = from_entry.path(entry, true, false)
						if p == nil or p == "" then
							return
						end
						buffer_previewer_maker(p, self.state.bufnr, {
							bufname = self.state.bufname,
							winid = self.state.winid,
							preview = opts.preview,
						})
					end,
					teardown = clear_current_image,
				})
			end
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
					buffer_previewer_maker = buffer_previewer_maker,
					file_previewer = image_aware_file_previewer,
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
