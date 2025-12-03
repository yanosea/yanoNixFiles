-- highlight and search for todo comments
-- keymaps are set in lua/plugins/tools/internal/which_key_nvim.lua (<LEADER>lT)
return {
	{
		"folke/todo-comments.nvim",
		lazy = true,
		event = { "BufReadPost", "BufNewFile" },
		dependencies = { "nvim-lua/plenary.nvim" },
		-- todo-comments.nvim config
		opts = {
			signs = true,
			sign_priority = 8,
			keywords = {
				FIX = {
					icon = require("utils.icons").icons.ui.Bug,
					color = "error",
					alt = { "FIXME", "BUG", "FIXIT", "ISSUE" },
				},
				TODO = { icon = require("utils.icons").icons.ui.Check, color = "info" },
				HACK = { icon = require("utils.icons").icons.ui.Fire, color = "warning" },
				WARN = { icon = require("utils.icons").icons.ui.Warning, color = "warning", alt = { "WARNING", "XXX" } },
				PERF = { icon = require("utils.icons").icons.ui.Clock, alt = { "OPTIM", "PERFORMANCE", "OPTIMIZE" } },
				NOTE = { icon = require("utils.icons").icons.ui.Info, color = "hint", alt = { "INFO" } },
				TEST = {
					icon = require("utils.icons").icons.ui.Stopwatch,
					color = "test",
					alt = { "TESTING", "PASSED", "FAILED" },
				},
			},
			gui_style = {
				fg = "NONE",
				bg = "BOLD",
			},
			merge_keywords = true,
			highlight = {
				multiline = true,
				multiline_pattern = "^.",
				multiline_context = 10,
				before = "",
				keyword = "wide",
				after = "fg",
				pattern = [[.*<(KEYWORDS)\s*:]],
				comments_only = true,
				max_line_len = 400,
				exclude = {},
			},
			colors = {
				error = { "DiagnosticError", "ErrorMsg", require("utils.colors").colors.Red },
				warning = { "DiagnosticWarn", "WarningMsg", require("utils.colors").colors.Yellow },
				info = { "DiagnosticInfo", require("utils.colors").colors.Blue },
				hint = { "DiagnosticHint", require("utils.colors").colors.Green },
				default = { "Identifier", require("utils.colors").colors.Purple },
				test = { "Identifier", require("utils.colors").colors.Orange },
			},
			search = {
				command = "rg",
				args = {
					"--color=never",
					"--no-heading",
					"--with-filename",
					"--line-number",
					"--column",
				},
				pattern = [[\b(KEYWORDS):]],
			},
		},
	},
}
