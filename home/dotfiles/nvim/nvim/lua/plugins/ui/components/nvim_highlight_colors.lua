-- show colors by name and tailwindcss colors and hex values
return {
	{
		"brenoprata10/nvim-highlight-colors",
		lazy = true,
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			-- nvim-highlight-colors config
			require("nvim-highlight-colors").setup({
				render = "background",
				enable_named_colors = true,
				enable_tailwind = true,
			})
		end,
	},
}
