-- cli ai assistant for neovim plugin
-- keymaps are set in lua/plugins/tools/internal/which_key_nvim.lua (<LEADER>a)
return {
	{
		"lambdalisue/nvim-aibo",
		lazy = true,
		cmd = {
			"Aibo",
			"AiboSend",
		},
		config = function()
			-- aibo-nvim config
			require("aibo").setup({
				console = {
					on_attach = function(bufnr)
						local function open_prompt()
							local winid = vim.api.nvim_get_current_win()
							local bufname = string.format("aiboprompt://%d", winid)
							local prompt_winid = vim.fn.bufwinid(bufname)
							if prompt_winid == -1 then
								local config = require("aibo").get_config()
								vim.cmd(
									string.format(
										"rightbelow %dsplit %s",
										config.prompt_height,
										vim.fn.fnameescape(bufname)
									)
								)
							else
								vim.api.nvim_set_current_win(prompt_winid)
							end
						end
						-- keymaps
						vim.keymap.set(
							"n",
							"i",
							open_prompt,
							{ buffer = bufnr, desc = "Open prompt window", silent = true }
						)
						vim.keymap.set(
							"n",
							"I",
							open_prompt,
							{ buffer = bufnr, desc = "Open prompt window", silent = true }
						)
						vim.keymap.set(
							"n",
							"a",
							open_prompt,
							{ buffer = bufnr, desc = "Open prompt window", silent = true }
						)
						vim.keymap.set(
							"n",
							"A",
							open_prompt,
							{ buffer = bufnr, desc = "Open prompt window", silent = true }
						)
						vim.keymap.set(
							"n",
							"o",
							open_prompt,
							{ buffer = bufnr, desc = "Open prompt window", silent = true }
						)
						vim.keymap.set(
							"n",
							"O",
							open_prompt,
							{ buffer = bufnr, desc = "Open prompt window", silent = true }
						)
					end,
				},
			})
		end,
	},
}
