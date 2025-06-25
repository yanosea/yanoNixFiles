-- dap ui config
return {
	{
		"rcarriga/nvim-dap-ui",
		dependencies = {
			"mfussenegger/nvim-dap",
			"nvim-neotest/nvim-nio",
			{ "theHamsta/nvim-dap-virtual-text", opts = {} },
		},
		lazy = true,
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			local icons = require("utils.icons").icons
			local dap = require("dap")
			local dapui = require("dapui")
			-- nvim-dap-ui config
			dapui.setup({
				icons = {
					expanded = icons.ui.TriangleShortArrowDown,
					collapsed = icons.ui.TriangleShortArrowRight,
					circular = icons.ui.Circular,
				},
				mappings = {
					expand = { "<CR>" },
					open = "o",
					remove = "d",
					edit = "e",
					repl = "r",
					toggle = "t",
				},
				element_mappings = {},
				expand_lines = true,
				layouts = {
					{
						elements = {
							{ id = "scopes", size = 0.33 },
							{ id = "breakpoints", size = 0.17 },
							{ id = "stacks", size = 0.25 },
							{ id = "watches", size = 0.25 },
						},
						size = 0.33,
						position = "right",
					},
					{
						elements = {
							{ id = "repl", size = 0.45 },
							{ id = "console", size = 0.55 },
						},
						size = 0.27,
						position = "bottom",
					},
				},
				controls = {
					enabled = true,
					element = "repl",
					icons = {
						pause = icons.ui.Pause,
						play = icons.ui.Play,
						step_into = icons.ui.StepInto,
						step_over = icons.ui.StepOver,
						step_out = icons.ui.StepOut,
						step_back = icons.ui.StepBack,
						run_last = icons.ui.RunLast,
						terminate = icons.ui.Terminate,
					},
				},
				floating = {
					max_height = 0.9,
					max_width = 0.5,
					border = "single",
					mappings = {
						close = { "q", "<Esc>" },
					},
				},
				windows = { indent = 1 },
				render = {
					max_type_length = nil,
					max_value_lines = 100,
				},
			})
			dap.listeners.after.event_initialized["dapui_config"] = dapui.open
			local function notify_handler(msg, level, opts)
				opts = vim.tbl_extend("keep", opts or {}, {
					title = "dap-ui",
					icon = "",
					on_open = function(win)
						vim.api.nvim_set_option_value("filetype", "markdown", { buf = vim.api.nvim_win_get_buf(win) })
					end,
				})
				if level == nil then
					level = vim.log.levels.INFO
				elseif type(level) == "string" then
					level = ({
						TRACE = vim.log.levels.TRACE,
						DEBUG = vim.log.levels.DEBUG,
						INFO = vim.log.levels.INFO,
						WARN = vim.log.levels.WARN,
						ERROR = vim.log.levels.ERROR,
					})[(level):upper()] or vim.log.levels.INFO
				end
				msg = string.format("%s: %s", opts.title, msg)
				vim.notify(msg, level, opts)
			end
			pcall(function()
				require("dapui.util").notify = notify_handler
			end)
		end,
	},
}
