-- neovim org-mode
-- keymaps are set in lua/plugins/tools/internal/which_key_nvim.lua (<LEADER>o, for grouping)
return {
	{
		"nvim-orgmode/orgmode",
		lazy = true,
		event = "VeryLazy",
		ft = { "org" },
		config = function()
			local orgfiles_path = vim.env.GOOGLE_DRIVE and vim.env.GOOGLE_DRIVE .. "/orgfiles"
				or "~/.local/share/nvim/orgfiles"
			-- orgmode config
			require("orgmode").setup({
				org_agenda_files = orgfiles_path .. "/**/*",
				org_default_notes_file = orgfiles_path .. "/refile.org",
			})
		end,
	},
}
