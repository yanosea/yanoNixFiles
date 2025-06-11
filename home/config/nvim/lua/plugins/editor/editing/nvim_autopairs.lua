-- automatically close brackets, quotes, etc.
return {
	{
		"windwp/nvim-autopairs",
		lazy = true,
		event = "InsertEnter",
		dependencies = { "nvim-treesitter/nvim-treesitter", "hrsh7th/nvim-cmp" },
		config = function()
			-- nvim-autopairs config
			require("nvim-autopairs").setup()
		end,
	},
}
