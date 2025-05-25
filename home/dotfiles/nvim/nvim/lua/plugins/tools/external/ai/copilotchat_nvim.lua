-- github copilot chat for neovim
-- keymaps are set in lua/pulugins/tools/internal/which_key_nvim.lua (<LEADER>aC)
return {
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		branch = "main",
		dependencies = {
			"zbirenbaum/copilot.lua",
			"nvim-lua/plenary.nvim",
		},
		lazy = true,
		cmd = {
			"CopilotChatCommit",
			"CopilotChatDocs",
			"CopilotChatExplain",
			"CopilotChatFix",
			"CopilotChatLoad",
			"CopilotChatOptimize",
			"CopilotChatReview",
			"CopilotChatSave",
			"CopilotChatToggle",
			"CopilotChatTests",
		},
		-- CopilotChat.nvim config
		opts = {
			system_prompt = require("plugins.tools.external.ai.prompts.system_prompt").prompt,
			prompts = {
				Commit = {
					prompt = require("plugins.tools.external.ai.prompts.user_prompts.commit").prompt,
				},
				Docs = {
					prompt = require("plugins.tools.external.ai.prompts.user_prompts.docs").prompt,
				},
				Explain = {
					prompt = require("plugins.tools.external.ai.prompts.user_prompts.explain").prompt,
				},
				Fix = {
					prompt = require("plugins.tools.external.ai.prompts.user_prompts.fix").prompt,
				},
				FixDiagnostic = {
					prompt = require("plugins.tools.external.ai.prompts.user_prompts.fix_diagnostic").prompt,
				},
				Optimize = {
					prompt = require("plugins.tools.external.ai.prompts.user_prompts.optimize").prompt,
				},
				Review = {
					prompt = require("plugins.tools.external.ai.prompts.user_prompts.review").prompt,
				},
				Tests = {
					prompt = require("plugins.tools.external.ai.prompts.user_prompts.tests").prompt,
				},
			},
			model = "claude-3.7-sonnet",
			selection = function(source)
				return require("CopilotChat.select").visual(source) or require("CopilotChat.select").buffer(source)
			end,
			question_header = "## 👦 You: ",
			answer_header = "## 👧 Senpai: ",
			error_header = "## ❌ Error: ",
			window = {
				layout = "vertical", -- 'vertical', 'horizontal', 'float', 'replace'
				width = 0.5, -- fractional width of parent, or absolute width in columns when > 1
				height = 0.5, -- fractional height of parent, or absolute height in rows when > 1
				-- Options below only apply to floating windows
				relative = "editor", -- 'editor', 'win', 'cursor', 'mouse'
				border = "single", -- 'none', single', 'double', 'rounded', 'solid', 'shadow'
				row = nil, -- row position of the window, default is centered
				col = nil, -- column position of the window, default is centered
				title = "Copilot Chat", -- title of chat window
				footer = nil, -- footer of chat window
				zindex = 1, -- determines if window is on top or below other floating windows
			},
		},
	},
}
