-- chatgpt for neovim
-- keymaps are set in lua/plugins/tools/internal/which_key_nvim.lua (<LEADER>ag)
return {
	{
		"robitx/gp.nvim",
		lazy = true,
		cmd = {
			"Gpchatrespond",
			"Gpchatstop",
			"Gpchatdelete",
			"Gpchatfinder",
			"Gpchatnew popup",
			"Gpchatnew split",
			"Gpchatnew tabnew",
			"GpChatNew vsplit",
		},
		config = function()
			vim.api.nvim_set_hl(0, "GpHandlerStandout", { link = "Normal" })
			vim.api.nvim_set_hl(0, "GpExplorerSearch", { link = "Normal" })
			-- gp.nvim config
			require("gp").setup({
				agents = {
					{
						name = "ChatGPT4",
						chat = true,
						command = false,
						model = { model = "gpt-4o", temperature = 1.1, top_p = 1 },
						system_prompt = require("plugins.tools.external.ai.prompts.system_prompt").prompt,
					},
					{
						name = "ChatGPT3-5",
						disable = true,
					},
				},
				state_dir = vim.env.XDG_STATE_HOME and (vim.env.XDG_STATE_HOME .. "/gp-nvim/persisted")
					or "~/.local/share/gp-nvim/persisted",
				chat_dir = vim.env.GOOGLE_DRIVE and (vim.env.GOOGLE_DRIVE .. "/gp-nvim/chats")
					or "~/.local/share/gp-nvim/chats",
			})
		end,
	},
}
