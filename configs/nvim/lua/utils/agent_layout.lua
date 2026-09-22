-- shared split ratios for the agent tui wrappers in lua/config
local M = {}

-- window split ratio (right pane width against the whole editor)
M.split_ratio = 0.5
-- terminal height ratio within the right split
M.terminal_height_ratio = 0.6

-- keep a resize the user made (<C-w>< / <C-w>> or a mouse drag) across hide and show
-- @param terminal_win: number|nil - terminal window number
-- @param prompt_win: number|nil - prompt window number
function M.remember(terminal_win, prompt_win)
	if terminal_win and vim.api.nvim_win_is_valid(terminal_win) then
		local ratio = vim.api.nvim_win_get_width(terminal_win) / vim.o.columns
		M.split_ratio = math.min(math.max(ratio, 0.2), 0.8)
		if prompt_win and vim.api.nvim_win_is_valid(prompt_win) then
			local terminal_height = vim.api.nvim_win_get_height(terminal_win)
			local total = terminal_height + vim.api.nvim_win_get_height(prompt_win)
			if total > 0 then
				M.terminal_height_ratio = math.min(math.max(terminal_height / total, 0.2), 0.9)
			end
		end
	end
end

return M
