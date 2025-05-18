-- netrw alternative
return {
	{
		"tamago324/lir.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		lazy = true,
		event = "User DirOpened",
		config = function()
			local colors = require("utils.colors").colors
			local icons = require("utils.icons").icons
			local actions = require("lir.actions")
			local clipboard_actions = require("lir.clipboard.actions")
			-- lir.nvim config
			local options = {
				show_hidden_files = true,
				ignore = {}, -- { ".DS_Store" "node_modules" } etc.
				devicons = {
					enable = true,
					highlight_dirname = true,
				},
				mappings = {
					["l"] = actions.edit,
					["<CR>"] = actions.edit,
					["<C-s>"] = actions.split,
					["v"] = actions.vsplit,
					["<C-t>"] = actions.tabedit,
					["h"] = actions.up,
					["q"] = actions.quit,
					["A"] = actions.mkdir,
					["a"] = actions.newfile,
					["r"] = actions.rename,
					["@"] = actions.cd,
					["Y"] = actions.yank_path,
					["i"] = actions.toggle_show_hidden,
					["d"] = actions.delete,
					["J"] = function()
						require("lir.mark.actions").toggle_mark("v")
						vim.cmd("normal! j")
					end,
					["c"] = clipboard_actions.copy,
					["x"] = clipboard_actions.cut,
					["p"] = clipboard_actions.paste,
				},
				float = {
					winblend = 0,
					curdir_window = {
						enable = false,
						highlight_dirname = true,
					},
					win_opts = function()
						local width = math.floor(vim.o.columns * 0.7)
						local height = math.floor(vim.o.lines * 0.7)
						return {
							border = "single",
							width = width,
							height = height,
						}
					end,
				},
				hide_cursor = false,
				on_init = function()
					-- use visual mode
					vim.api.nvim_buf_set_keymap(
						0,
						"x",
						"J",
						':<C-u>lua require"lir.mark.actions".toggle_mark("v")<CR>',
						{ desc = "lir toggle mark (visual mode)", silent = true, noremap = true }
					)
				end,
			}
			-- lir.nvim config
			require("lir").setup(options)
			-- define icons
			local function setup_icons()
				local devicons_ok, devicons = pcall(require, "nvim-web-devicons")
				if not devicons_ok then
					return
				end
				local function get_hl_by_name(name)
					local ret = vim.api.nvim_get_hl(0, { name = name.group })
					return string.format("#%06x", ret[name.property])
				end
				local folder_icon = icons.ui.Folder
				local found, icon_hl = pcall(get_hl_by_name, { group = "NvimTreeFolderIcon", property = "fg" })
				if not found then
					icon_hl = colors.Aqua
				end
				devicons.set_icon({
					lir_folder_icon = {
						icon = folder_icon,
						color = icon_hl,
						name = "LirFolderNode",
					},
				})
			end
			setup_icons()
		end,
	},
}
