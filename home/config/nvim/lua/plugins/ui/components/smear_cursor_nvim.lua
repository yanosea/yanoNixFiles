-- cursor animation like Neovide
-- keymaps are set in lua/pulugins/tools/internal/which_key_nvim.lua (<LEADER>S)
return {
	{
		"sphamba/smear-cursor.nvim",
		lazy = true,
		event = "VeryLazy",
		opts = {
			smear_between_buffers = true,
			smear_between_neighbor_lines = true,
			scroll_buffer_space = true,
			legacy_computing_symbols_support = true,
			smear_insert_mode = true,
			stiffness = 0.8,
			trailing_stiffness = 0.5,
			stiffness_insert_mode = 0.6,
			trailing_stiffness_insert_mode = 0.6,
			distance_stop_animating = 0.5,
			time_interval = 7,
		},
	},
}
