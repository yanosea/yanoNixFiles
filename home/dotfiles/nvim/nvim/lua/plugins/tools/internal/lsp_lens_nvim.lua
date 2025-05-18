-- displaying reference and definition info upon functions
return {
	{
		"VidocqH/lsp-lens.nvim",
		lazy = true,
		event = { "LspAttach" },
		config = function()
			-- lsp-lens.nvim config
			require("lsp-lens").setup({
				enable = true,
				include_declaration = true,
				sections = {
					definition = true,
					references = true,
					implements = true,
				},
				ignore_filetype = {
					"prisma",
				},
			})
		end,
	},
}
