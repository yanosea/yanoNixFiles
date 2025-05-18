-- codecompanion config
-- keymaps are set in lua/plugins/tools/internal/which_key_nvim.lua (<LEADER>ac)
return {
	{
		"olimorris/codecompanion.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
			"ravitemer/mcphub.nvim",
		},
		lazy = true,
		cmd = {
			"CodeCompanionActions",
			"CodeCompanionChat",
			"CodeCompanionCmd",
		},
		config = function()
			-- companion.nvim config
			require("codecompanion").setup({
				display = {
					action_palette = {
						width = 95,
						height = 10,
						provider = "default",
						opts = {
							show_default_actions = true,
							show_default_prompt_library = true,
						},
					},
				},
				strategies = {
					chat = {
						adapter = "copilot",
						keymaps = {
							send = {
								modes = { n = "<CR>" },
							},
						},
					},
					inline = {
						adapter = "copilot",
						keymaps = {
							accept_change = {
								modes = { n = "<LEADER>acA" },
								description = { "codecompanion: accept the suggested change" },
							},
							reject_change = {
								modes = { n = "<LEADER>acR" },
								description = { "codecompanion: reject the suggested change" },
							},
						},
					},
					cmd = {
						adapter = "copilot",
					},
					adapters = {
						copilot = function()
							return require("codecompanion.adapters").extend("copilot", {
								schema = {
									model = {
										default = "claude-3.7-sonnet",
									},
								},
							})
						end,
					},
				},
				extensions = {
					mcphub = {
						callback = "mcphub.extensions.codecompanion",
						opts = {
							make_vars = true,
							make_slash_commands = true,
							show_result_in_chat = true,
						},
					},
				},
				opts = {
					language = "Japanese",
					log_level = "DEBUG",
					system_prompt = function(_)
						return require("plugins.tools.external.ai.prompts.system_prompt").prompt
					end,
				},
			})
		end,
	},
}
