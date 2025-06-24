-- japanese input method
return {
	{
		"vim-skk/skkeleton",
		dependencies = { "vim-denops/denops.vim" },
		lazy = true,
		event = "VeryLazy",
		config = function()
			-- load local skk dictionaries
			local dictionaries = {}
			local handle = io.popen("ls ~/.local/share/skk/*")
			if handle then
				for file in handle:lines() do
					table.insert(dictionaries, file)
				end
				handle:close()
			end
			local src = { "skk_dictionary", "google_japanese_input" }
			-- skeeleton config
			vim.api.nvim_create_autocmd("User", {
				pattern = "skkeleton-initialize-pre",
				callback = function()
					vim.fn["skkeleton#config"]({
						eggLikeNewline = true,
						globalDictionaries = dictionaries,
						immediatelyCancel = false,
						registerConvertResult = true,
						showCandidatesCount = 1,
						sources = src,
						userDictionary = "~/.local/state/skk/.skkeleton",
					})
					vim.fn["skkeleton#register_keymap"]("henkan", "<Esc>", "cancel")
				end,
			})
			-- keymaps
			vim.keymap.set("i", "<C-j>", "<Plug>(skkeleton-toggle)", { desc = "toggle skkeleton", silent = true })
			vim.keymap.set("c", "<C-j>", "<Plug>(skkeleton-toggle)", { desc = "toggle skkeleton", silent = true })
		end,
	},
}
