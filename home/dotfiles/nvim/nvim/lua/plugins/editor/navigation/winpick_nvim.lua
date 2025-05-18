-- window selection
return {
	{
		"gbrlsnchs/winpick.nvim",
		lazy = true,
		keys = { "<C-w><C-w>" },
		config = function()
			-- winpick.nvim config
			require("winpick").setup({
				border = "single",
				chars = { "A", "S", "D", "F", "J", "K", "L", ";" },
				filter = function(winid)
					-- filter out excluded windows
					local is_excluded = false
					local bufnr = vim.api.nvim_win_get_buf(winid)
					local filetype = vim.bo[bufnr].filetype
					local excluded_filetypes = {
						"noice",
						"notify",
					}
					if vim.tbl_contains(excluded_filetypes, filetype) then
						is_excluded = true
					end
					return not is_excluded
				end,
			})
			-- define the function to pick windows
			_G.WinPick = function()
				-- check if there are enough windows to pick from
				local all_win_ids = vim.api.nvim_tabpage_list_wins(0)
				local excluded_win_count = 0
				for _, winid in ipairs(all_win_ids) do
					local bufnr = vim.api.nvim_win_get_buf(winid)
					local filetype = vim.bo[bufnr].filetype
					if filetype == "noice" then
						excluded_win_count = excluded_win_count + 1
					end
				end
				-- if there are not enough windows, use the default behavior
				local total_win_count = #all_win_ids
				local eligible_win_count = total_win_count - excluded_win_count
				if eligible_win_count < 3 then
					-- if there are not enough windows, use the default behavior
					vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-w><C-w>", true, false, true), "n", true)
				else
					-- if there are enough windows, use winpick
					local success, winid = pcall(require("winpick").select)
					if success and winid then
						vim.api.nvim_set_current_win(winid)
					end
				end
			end
			-- keymaps
			vim.api.nvim_set_keymap(
				"n",
				"<C-w><C-w>",
				"<CMD>lua WinPick()<CR>",
				{ desc = "pick windows", silent = true, noremap = true }
			)
		end,
	},
}
