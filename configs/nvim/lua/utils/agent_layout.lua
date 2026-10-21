-- shared split ratios for the agent tui wrappers in lua/config
local M = {}

-- window split ratio (right pane width against the whole editor)
M.split_ratio = 0.5
-- terminal height ratio within the right split
M.terminal_height_ratio = 0.6

-- prompt height in fullscreen; the split height comes back with the split
M.full_prompt_height = 3

-- fullscreen is a tab page of its own that holds only the terminal and the prompt
-- (:h tab-page, :h :tab), so no editor window is left under it for <C-w> or pickers
local FULL = "agent_fullscreen"

-- true when the window sits in an agent's fullscreen tab
-- @param win: number|nil - window number
function M.is_full(win)
	return win ~= nil and vim.api.nvim_win_is_valid(win) and vim.t[vim.api.nvim_win_get_tabpage(win)][FULL] == true
end

-- before a wrapper closes its windows: when its fullscreen tab is the last tab
-- page, closing them would fail (E444), so open an empty tab to land in
-- @param windows: table - wrapper _windows
function M.before_close(windows)
	if M.is_full(windows.terminal_win) and #vim.api.nvim_list_tabpages() == 1 then
		vim.cmd("tabnew")
	end
end

-- true when both windows of the layout are on screen
local function visible(windows)
	return windows.terminal_win ~= nil
		and vim.api.nvim_win_is_valid(windows.terminal_win)
		and windows.prompt_win ~= nil
		and vim.api.nvim_win_is_valid(windows.prompt_win)
end

-- toggle fullscreen: a tab with the terminal on top and a thin prompt below
-- the prompt stays a normal buffer, so skkeleton input still works in it
-- @param owner: table - agent wrapper with _windows, _close_windows and _recreate_split_layout
-- @param show: function - the owner's toggle, which starts a closed layout (with the
-- CLI's own fullscreen renderer where it has one) and shows a hidden one
function M.toggle_full(owner, show)
	local windows = owner._windows
	if M.is_full(windows.terminal_win) then
		local tab = vim.api.nvim_win_get_tabpage(windows.terminal_win)
		-- one fullscreen tab per agent: Full from another tab goes back to it
		if tab ~= vim.api.nvim_get_current_tabpage() then
			vim.api.nvim_set_current_tabpage(tab)
			vim.api.nvim_set_current_win(windows.prompt_win)
			return
		end
		-- closing both windows closes the tab and returns to the editor window
		owner._close_windows()
		owner._recreate_split_layout()
		-- the split comes back at the size it had
		local size = windows.split_size
		if size then
			vim.api.nvim_win_set_width(windows.terminal_win, size[1])
			vim.api.nvim_win_set_height(windows.terminal_win, size[2])
			vim.api.nvim_win_set_height(windows.prompt_win, size[3])
		end
		vim.api.nvim_set_current_win(windows.prompt_win)
		return
	end
	if not visible(windows) then
		show()
	end
	-- opening replaces _windows, and a failed start leaves nothing to move
	windows = owner._windows
	if not visible(windows) then
		return
	end
	local winbars = { vim.wo[windows.terminal_win].winbar, vim.wo[windows.prompt_win].winbar }
	windows.split_size = {
		vim.api.nvim_win_get_width(windows.terminal_win),
		vim.api.nvim_win_get_height(windows.terminal_win),
		vim.api.nvim_win_get_height(windows.prompt_win),
	}
	-- keeps the split size for the way back, and lands in the editor window
	owner._close_windows()
	-- :tab split opens the current buffer in a new tab page, so no buffer is created
	vim.cmd("tab split")
	vim.t[FULL] = true
	local terminal_win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(terminal_win, windows.terminal_buf)
	vim.cmd("belowright split")
	local prompt_win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(prompt_win, windows.prompt_buf)
	vim.api.nvim_win_set_height(prompt_win, M.full_prompt_height)
	vim.wo[prompt_win].winfixheight = true
	vim.wo[terminal_win].winbar = winbars[1]
	vim.wo[prompt_win].winbar = winbars[2]
	windows.terminal_win, windows.prompt_win = terminal_win, prompt_win
end

-- keep a resize the user made (<C-w>< / <C-w>> or a mouse drag) across hide and show
-- a fullscreen layout is skipped: its size is the tab's size, not a choice
-- @param terminal_win: number|nil - terminal window number
-- @param prompt_win: number|nil - prompt window number
function M.remember(terminal_win, prompt_win)
	if M.is_full(terminal_win) then
		return
	end
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
