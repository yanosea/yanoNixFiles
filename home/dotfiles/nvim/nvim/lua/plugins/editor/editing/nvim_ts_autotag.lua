-- automatically close and rename HTML/XML tags
return {
	{
		"windwp/nvim-ts-autotag",
		lazy = true,
		ft = { "html", "xml", "jsx", "tsx", "vue", "svelte", "php", "rescript", "astro" },
		config = function()
			-- nvim-ts-autotag config
			require("nvim-ts-autotag").setup({
				opts = {
					enable_close = true,
					enable_rename = true,
					enable_close_on_slash = true,
				},
			})
		end,
	},
}
