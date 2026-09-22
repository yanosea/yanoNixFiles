-- toad integration config
-- check if toad command is available
local function is_toad_available()
	local handle = io.popen("command -v toad 2>/dev/null")
	if handle then
		local result = handle:read("*a")
		handle:close()
		return result and result ~= ""
	end
	return false
end
-- early return if toad is not available
if not is_toad_available() then
	return
end
-- define module
local M = {}
-- layout ratios, shared with the other agent tui wrappers
local config = require("utils.agent_layout")
-- store window references and state
M._windows = {
	main_win = nil,
	terminal_win = nil,
	prompt_win = nil,
	terminal_buf = nil,
	prompt_buf = nil,
	toad_job_id = nil,
}
M._is_open = false

-- create vertical split layout with terminal and prompt
-- @return table - layout with buffer and window references
function M._create_split_layout()
	-- store current window
	M._windows.main_win = vim.api.nvim_get_current_win()
	-- create vertical split to the right
	vim.cmd("vsplit")
	local right_win = vim.api.nvim_get_current_win()
	-- set right window width
	local total_columns = vim.o.columns
	local right_width = math.floor(total_columns * config.split_ratio)
	vim.api.nvim_win_set_width(right_win, right_width)
	-- create terminal buffer and bind to right window
	local terminal_buf = vim.api.nvim_create_buf(false, true)
	M._windows.terminal_buf = terminal_buf
	M._windows.terminal_win = right_win
	vim.api.nvim_win_set_buf(right_win, terminal_buf)
	-- create horizontal split for prompt
	vim.cmd("split")
	local prompt_win = vim.api.nvim_get_current_win()
	M._windows.prompt_win = prompt_win
	-- set window heights
	local total_height = vim.api.nvim_win_get_height(0)
	local terminal_height = math.floor(total_height * config.terminal_height_ratio)
	vim.api.nvim_win_set_height(M._windows.terminal_win, terminal_height)
	vim.api.nvim_win_set_height(prompt_win, total_height - terminal_height)
	-- create prompt buffer
	local prompt_buf = vim.api.nvim_create_buf(false, true)
	M._windows.prompt_buf = prompt_buf
	vim.api.nvim_win_set_buf(prompt_win, prompt_buf)
	return {
		terminal_buf = terminal_buf,
		terminal_win = M._windows.terminal_win,
		prompt_buf = prompt_buf,
		prompt_win = prompt_win,
	}
end

-- recreate split layout using existing buffers
function M._recreate_split_layout()
	-- store current window
	M._windows.main_win = vim.api.nvim_get_current_win()
	-- create vertical split
	vim.cmd("vsplit")
	local right_win = vim.api.nvim_get_current_win()
	-- set dimensions
	local total_columns = vim.o.columns
	vim.api.nvim_win_set_width(right_win, math.floor(total_columns * config.split_ratio))
	-- bind existing terminal buffer
	M._windows.terminal_win = right_win
	vim.api.nvim_win_set_buf(right_win, M._windows.terminal_buf)
	-- set winbar for terminal
	vim.api.nvim_win_set_option(right_win, "winbar", "  TOAD")
	-- create horizontal split for prompt
	vim.cmd("split")
	local prompt_win = vim.api.nvim_get_current_win()
	M._windows.prompt_win = prompt_win
	-- set heights
	local total_height = vim.api.nvim_win_get_height(0)
	local terminal_height = math.floor(total_height * config.terminal_height_ratio)
	vim.api.nvim_win_set_height(M._windows.terminal_win, terminal_height)
	vim.api.nvim_win_set_height(prompt_win, total_height - terminal_height)
	-- bind existing prompt buffer
	vim.api.nvim_win_set_buf(prompt_win, M._windows.prompt_buf)
	-- set winbar for prompt
	vim.api.nvim_win_set_option(prompt_win, "winbar", "  PROMPT")
end

-- close windows but keep buffers and process
function M._close_windows()
	-- keep a manual resize for the next open
	config.remember(M._windows.terminal_win, M._windows.prompt_win)
	-- close prompt window
	if M._windows.prompt_win and vim.api.nvim_win_is_valid(M._windows.prompt_win) then
		vim.api.nvim_win_close(M._windows.prompt_win, true)
	end
	-- close terminal window
	if M._windows.terminal_win and vim.api.nvim_win_is_valid(M._windows.terminal_win) then
		vim.api.nvim_win_close(M._windows.terminal_win, true)
	end
	-- return to main window
	if M._windows.main_win and vim.api.nvim_win_is_valid(M._windows.main_win) then
		vim.api.nvim_set_current_win(M._windows.main_win)
	end
end

-- setup terminal buffer keymaps
-- @param terminal_buf: number - terminal buffer number
-- @param terminal_win: number - terminal window number
function M._setup_terminal_keymaps(terminal_buf, terminal_win)
	-- set winbar for toad terminal
	vim.api.nvim_win_set_option(terminal_win, "winbar", "  TOAD")
	-- hide layout with double Esc in normal mode
	vim.api.nvim_buf_set_keymap(terminal_buf, "n", "<Esc><Esc>", "", {
		callback = M.hide_layout,
		noremap = true,
		silent = true,
	})
	-- close layout with :q
	vim.api.nvim_buf_set_keymap(terminal_buf, "n", ":q<CR>", "", {
		callback = M.close_layout,
		noremap = true,
		silent = true,
	})
	-- exit terminal mode with double Esc
	vim.api.nvim_buf_set_keymap(terminal_buf, "t", "<Esc><Esc>", "<C-\\><C-n>", {
		noremap = true,
		silent = true,
	})
end

-- setup prompt buffer
-- @param prompt_buf: number - prompt buffer number
-- @param prompt_win: number - prompt window number
function M._setup_prompt_buffer(prompt_buf, prompt_win)
	-- set buffer options
	vim.api.nvim_buf_set_option(prompt_buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(prompt_buf, "filetype", "markdown")
	-- set winbar for prompt buffer
	vim.api.nvim_win_set_option(prompt_win, "winbar", "  PROMPT")
	-- clear buffer content
	vim.api.nvim_buf_set_lines(prompt_buf, 0, -1, false, {})
	-- position cursor
	vim.api.nvim_win_set_cursor(prompt_win, { 1, 0 })
	-- send prompt with Enter
	vim.api.nvim_buf_set_keymap(prompt_buf, "n", "<CR>", "", {
		callback = function()
			M._send_prompt_from_buffer(prompt_buf)
		end,
		noremap = true,
		silent = true,
	})
	-- hide layout with double Esc
	vim.api.nvim_buf_set_keymap(prompt_buf, "n", "<Esc><Esc>", "", {
		callback = M.hide_layout,
		noremap = true,
		silent = true,
	})
	-- close layout with :q
	vim.api.nvim_buf_set_keymap(prompt_buf, "n", ":q<CR>", "", {
		callback = M.close_layout,
		noremap = true,
		silent = true,
	})
end

-- start toad terminal
-- @param terminal_buf: number - terminal buffer number
-- @param terminal_win: number - terminal window number
-- @return boolean - success status
function M._start_toad_terminal(terminal_buf, terminal_win)
	vim.api.nvim_set_current_win(terminal_win)
	-- start terminal
	local job_id = vim.fn.termopen("toad", {
		buffer = terminal_buf,
		on_exit = function()
			vim.notify("Toad terminal closed", vim.log.levels.INFO)
			vim.defer_fn(function()
				M.close_layout()
			end, 100)
		end,
	})

	if job_id == 0 then
		vim.notify("Failed to start toad", vim.log.levels.ERROR)
		return false
	end

	M._windows.toad_job_id = job_id
	M._setup_terminal_keymaps(terminal_buf, terminal_win)
	return true
end

-- send prompt from buffer to toad terminal
-- @param prompt_buf: number - prompt buffer number
function M._send_prompt_from_buffer(prompt_buf)
	local lines = vim.api.nvim_buf_get_lines(prompt_buf, 0, -1, false)
	-- collect non-empty lines
	local prompt_lines = {}
	for i = 1, #lines do
		if lines[i] ~= "" or #prompt_lines > 0 then
			table.insert(prompt_lines, lines[i])
		end
	end
	if #prompt_lines == 0 then
		vim.notify("Empty prompt", vim.log.levels.WARN)
		return
	end
	M._send_to_toad_terminal(table.concat(prompt_lines, "\n"))
end

-- send prompt to toad terminal
-- @param prompt: string - prompt text
function M._send_to_toad_terminal(prompt)
	if not M._windows.toad_job_id then
		vim.notify("Toad terminal not started", vim.log.levels.ERROR)
		return
	end
	-- send prompt to terminal
	vim.fn.chansend(M._windows.toad_job_id, prompt)
	-- switch to terminal and press enter to submit
	vim.api.nvim_set_current_win(M._windows.terminal_win)
	vim.defer_fn(function()
		vim.cmd("startinsert")
		vim.defer_fn(function()
			vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "i", false)
			vim.defer_fn(function()
				vim.api.nvim_set_current_win(M._windows.prompt_win)
			end, 50)
		end, 50)
	end, 50)
	-- clear prompt buffer
	vim.api.nvim_buf_set_lines(M._windows.prompt_buf, 0, -1, false, { "" })
	vim.api.nvim_win_set_cursor(M._windows.prompt_win, { 1, 0 })
end

-- hide the layout but keep toad process running
function M.hide_layout()
	M._close_windows()
	-- clear window references but keep buffers and process
	M._windows.terminal_win = nil
	M._windows.prompt_win = nil
	M._windows.main_win = nil
	M._is_open = false
end

-- show the layout with existing toad process
function M.show_layout()
	M._recreate_split_layout()
	vim.api.nvim_set_current_win(M._windows.prompt_win)
	M._is_open = true
end

-- completely close the layout and terminate toad process
function M.close_layout()
	-- terminate toad process
	if M._windows.toad_job_id then
		vim.fn.jobstop(M._windows.toad_job_id)
		vim.notify("Toad process terminated", vim.log.levels.INFO)
	end
	M._close_windows()
	-- reset all references
	M._windows = {
		main_win = nil,
		terminal_win = nil,
		prompt_win = nil,
		terminal_buf = nil,
		prompt_buf = nil,
		toad_job_id = nil,
	}
	M._is_open = false
end

-- open new toad layout
function M.open_layout()
	local layout = M._create_split_layout()
	if not M._start_toad_terminal(layout.terminal_buf, layout.terminal_win) then
		M.close_layout()
		return
	end
	vim.api.nvim_set_current_win(layout.prompt_win)
	M._setup_prompt_buffer(layout.prompt_buf, layout.prompt_win)
	M._is_open = true
end

-- toggle layout visibility
function M.toggle_layout()
	if M._is_open then
		M.hide_layout()
	else
		-- check if we have existing buffers (hidden state)
		if M._windows.terminal_buf and M._windows.prompt_buf then
			M.show_layout()
		else
			M.open_layout()
		end
	end
end

-- setup commands
function M.setup()
	vim.api.nvim_create_user_command("Toad", M.toggle_layout, {
		desc = "Toggle Toad terminal and prompt layout",
	})
end

-- auto-setup when module is loaded
M.setup()

return M
