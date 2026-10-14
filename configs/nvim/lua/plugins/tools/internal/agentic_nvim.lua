-- acp (agent client protocol) chat client for ai agents
-- keymaps are set in lua/plugins/tools/internal/which_key_nvim.lua (<LEADER>aa : agentic)
return {
	{
		"carlos-algms/agentic.nvim",
		lazy = true,
		config = function()
			require("agentic").setup({
				-- grok carries the subscriptions; claude stays a switch_provider away
				provider = "grok-acp",
				acp_providers = {
					-- google ships the acp server as a separate binary (nix: agy-acp-server)
					["antigravity-acp"] = {
						name = "Antigravity ACP",
						command = "agy_acp_server",
					},
					-- xai ships acp natively as a subcommand
					["grok-acp"] = {
						name = "Grok ACP",
						command = "grok",
						args = { "agent", "stdio" },
					},
				},
				windows = {
					position = "right",
					width = "40%",
				},
			})
		end,
	},
}
