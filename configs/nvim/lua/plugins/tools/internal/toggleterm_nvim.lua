-- terminal in neovim
-- keymaps are set in lua/plugins/tools/internal/which_key_nvim.lua (<LEADER>t)

-- global toggle functions (defined outside config so they're available before plugin loads)
function ToggleLazyGit()
	require("lazy").load({ plugins = { "toggleterm.nvim" } })
	vim.defer_fn(function()
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
	end, 0)
end

function ToggleJjui()
	require("lazy").load({ plugins = { "toggleterm.nvim" } })
	vim.defer_fn(function()
		local Terminal = require("toggleterm.terminal").Terminal
		local jjui = Terminal:new({
			cmd = "jjui",
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
			count = 98,
		})
		jjui:toggle()
	end, 0)
end

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
		keys = {
			{ "<LEADER>gg", "<CMD>lua ToggleLazyGit()<CR>", desc = "git: lazygit" },
			{ "<LEADER>jj", "<CMD>lua ToggleJjui()<CR>", desc = "jj: jjui" },
			{ "<LEADER>ts", "<CMD>ToggleTerm direction=horizontal<CR>", desc = "terminal: horizontal" },
			{ "<LEADER>tv", "<CMD>ToggleTerm direction=vertical<CR>", desc = "terminal: vertical" },
		},
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
				highlights = {
					Normal = { link = "TerminalNormal" },
					NormalNC = { link = "TerminalNormal" },
				},
			})
			-- terminal mode keymaps
			vim.keymap.set("t", "<ESC><ESC>", [[<C-\><C-n>]], { noremap = true })
			vim.keymap.set("t", "<C-h>", [[<C-\><C-n><C-w>h]], { noremap = true, silent = true })
			vim.keymap.set("t", "<C-j>", [[<C-\><C-n><C-w>j]], { noremap = true, silent = true })
			vim.keymap.set("t", "<C-k>", [[<C-\><C-n><C-w>k]], { noremap = true, silent = true })
			vim.keymap.set("t", "<C-l>", [[<C-\><C-n><C-w>l]], { noremap = true, silent = true })
		end,
	},
}
