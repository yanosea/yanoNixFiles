-- render markdown
-- keymaps are set in lua/plugins/tools/internal/which_key_nvim.lua (<LEADER>mt)
return {
	{
		"MeanderingProgrammer/render-markdown.nvim",
		lazy = true,
		ft = { "markdown", "Avante" },
		-- render-markdown.nvim config
		opts = {
			file_types = { "markdown", "Avante" },
			render_modes = { "n", "c", "t" },
			heading = {
				border = true,
				border_virtual = true,
				width = "block",
				min_width = 30,
			},
			code = {
				width = "block",
				right_pad = 2,
			},
		},
	},
}
