-- terminal in neovim
-- keymaps are set in lua/plugins/tools/internal/which_key_nvim.lua (<LEADER>t)
return {
	{
		"akinsho/toggleterm.nvim",
		lazy = true,
		cmd = {
			"ToggleTerm",
			"TermExec",
			"ToggleTermToggleAll",
			"ToggleTermSendCurrentLine",
			"ToggleTermSendVisualLines",
			"ToggleTermSendVisualSelection",
		},
		keys = { "g", "<LEADER>gg", "<LEADER>ts", "<LEADER>tv" },
		init = function()
			-- define the function to toggle lazygit
			_G.ToggleLazyGit = function()
				local Terminal = require("toggleterm.terminal").Terminal
				local lazygit = Terminal:new({
					cmd = "lazygit",
					hidden = true,
					direction = "float",
					float_opts = {
						border = "none",
						width = 100000,
						height = 100000,
						zindex = 200,
					},
					on_open = function(_)
						vim.cmd("startinsert!")
					end,
					on_close = function(_) end,
					count = 99,
				})
				lazygit:toggle()
			end
		end,
		config = function()
			-- toggleterm.nvim config
			require("toggleterm").setup({
				open_mapping = nil,
				shading_factor = 2,
				persist_size = false,
				direction = "horizontal",
				size = function(term)
					if term.direction == "horizontal" then
						return 15
					elseif term.direction == "vertical" then
						return vim.o.columns * 0.5
					end
				end,
			})
			-- keymaps
			-- to avoid not opening terminal after opened and exited, set keymaps here again
			vim.keymap.set(
				"n",
				"<LEADER>gg",
				"<CMD>lua ToggleLazyGit()<CR>",
				{ desc = "lazygit", silent = true, noremap = true }
			)
			vim.keymap.set(
				"n",
				"<LEADER>ts",
				"<CMD>ToggleTerm direction=horizontal<CR>",
				{ desc = "terminal: horizontal", silent = true, noremap = true }
			)
			vim.keymap.set(
				"n",
				"<LEADER>tv",
				"<CMD>ToggleTerm direction=vertical<CR>",
				{ desc = "terminal: vertical", silent = true, noremap = true }
			)
			vim.keymap.set("t", "<ESC><ESC>", [[<C-\><C-n>]], { noremap = true })
			vim.keymap.set("t", "<C-h>", [[<C-\><C-n><C-w>h]], { noremap = true, silent = true })
			vim.keymap.set("t", "<C-j>", [[<C-\><C-n><C-w>j]], { noremap = true, silent = true })
			vim.keymap.set("t", "<C-k>", [[<C-\><C-n><C-w>k]], { noremap = true, silent = true })
			vim.keymap.set("t", "<C-l>", [[<C-\><C-n><C-w>l]], { noremap = true, silent = true })
		end,
	},
}
