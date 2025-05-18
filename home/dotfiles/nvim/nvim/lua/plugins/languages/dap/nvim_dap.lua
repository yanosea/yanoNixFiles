-- dap config
return {
	{
		"mfussenegger/nvim-dap",
		lazy = true,
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			local icons = require("utils.icons").icons
			vim.fn.sign_define("DapBreakpoint", {
				text = icons.ui.Bug,
				texthl = "DiagnosticSignError",
				linehl = "",
				numhl = "",
			})
			vim.fn.sign_define("DapBreakpointRejected", {
				text = icons.ui.Bug,
				texthl = "DiagnosticSignError",
				linehl = "",
				numhl = "",
			})
			vim.fn.sign_define("DapStopped", {
				text = icons.ui.BoldArrowRight,
				texthl = "DiagnosticSignWarn",
				linehl = "Visual",
				numhl = "DiagnosticSignWarn",
			})
			require("dap").set_log_level("info")
			-- keymaps
			vim.keymap.set(
				"n",
				"<F5>",
				":lua require('dap').continue()<CR>",
				{ desc = "continue", silent = true, noremap = true }
			)
			vim.keymap.set(
				"n",
				"<F10>",
				":lua require('dap').step_over()<CR>",
				{ desc = "step over", silent = true, noremap = true }
			)
			vim.keymap.set(
				"n",
				"<F11>",
				":lua require('dap').step_into()<CR>",
				{ desc = "step into", silent = true, noremap = true }
			)
			vim.keymap.set(
				"n",
				"<F12>",
				":lua require('dap').step_out()<CR>",
				{ desc = "step out", silent = true, noremap = true }
			)
		end,
	},
}
