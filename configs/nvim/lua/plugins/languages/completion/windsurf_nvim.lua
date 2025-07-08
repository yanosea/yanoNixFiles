-- windsurf (codeium) config
return {
	{
		"Exafunction/windsurf.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"hrsh7th/nvim-cmp",
		},
		lazy = true,
		cmd = "Codeium",
		config = function()
			-- codeium config
			require("codeium").setup({
				enable_chat = false,
				enable_local_search = true,
				enable_index_service = true,
				enable_cmp_source = true,
				virtual_text = {
					enabled = false,
				},
			})
		end,
	},
}
