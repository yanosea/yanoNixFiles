-- open github url under cursor (owner/repo)
-- keymaps are set in lua/pulugins/tools/internal/which_key_nvim.lua (<LEADER>gU)
return {
	{
		"tetzng/open-github-url.nvim",
		lazy = true,
		cmd = "OpenGitHubUrlUnderCursor",
		config = true,
	},
}
