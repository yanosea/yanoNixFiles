-- file explorer
-- keymaps are set in lua/plugins/tools/internal/which_key_nvim.lua (<LEADER>e)
return {
	{
		"nvim-tree/nvim-tree.lua",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
		},
		lazy = true,
		cmd = { "NvimTreeToggle", "NvimTreeOpen", "NvimTreeFocus", "NvimTreeFindFileToggle" },
		config = function()
			-- disable netrw
			vim.loaded_netrw = 1
			vim.loaded_netrwPlugin = 1
			-- nvim-tree config
			require("nvim-tree").setup({
				sync_root_with_cwd = true,
				respect_buf_cwd = true,
				view = {
					side = "right",
					width = {
						min = 40,
						max = -1,
						padding = 1,
					},
				},
				update_focused_file = {
					enable = true,
					update_root = {
						enable = true,
					},
				},
				diagnostics = {
					enable = true,
					show_on_dirs = true,
					show_on_open_dirs = true,
				},
				modified = {
					enable = true,
					show_on_dirs = true,
					show_on_open_dirs = true,
				},
			})
		end,
	},
}
