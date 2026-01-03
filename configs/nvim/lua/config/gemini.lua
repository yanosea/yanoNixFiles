-- gemini integration config
-- check if gemini command is available
local function is_gemini_available()
	local handle = io.popen("command -v gemini 2>/dev/null")
	if handle then
		local result = handle:read("*a")
		handle:close()
		return result and result ~= ""
	end
	return false
end
-- early return if gemini is not available
if not is_gemini_available() then
	return
end
-- define module
local M = {}
-- configuration
local config = {
	-- window split ratio
	split_ratio = 0.5,
	-- terminal height ratio within right split
	terminal_height_ratio = 0.6,
}
-- store window references and state
M._windows = {
	main_win = nil,
	terminal_win = nil,
	prompt_win = nil,
	terminal_buf = nil,
	prompt_buf = nil,
	gemini_job_id = nil,
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
	vim.api.nvim_win_set_option(right_win, "winbar", "  GEMINI")
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
	-- set winbar for gemini terminal
	vim.api.nvim_win_set_option(terminal_win, "winbar", "  GEMINI")
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

-- start gemini terminal
-- @param terminal_buf: number - terminal buffer number
-- @param terminal_win: number - terminal window number
-- @param command: string|nil - optional command to run (e.g., "-r")
-- @return boolean - success status
function M._start_gemini_terminal(terminal_buf, terminal_win, command)
	vim.api.nvim_set_current_win(terminal_win)
	-- construct gemini command
	local gemini_cmd = command and string.format("gemini %s", command) or "gemini"
	-- start terminal
	local job_id = vim.fn.termopen(gemini_cmd, {
		buffer = terminal_buf,
		on_exit = function()
			vim.notify("Gemini terminal closed", vim.log.levels.INFO)
			vim.defer_fn(function()
				M.close_layout()
			end, 100)
		end,
	})

	if job_id == 0 then
		vim.notify("Failed to start gemini", vim.log.levels.ERROR)
		return false
	end

	M._windows.gemini_job_id = job_id
	M._setup_terminal_keymaps(terminal_buf, terminal_win)
	return true
end

-- send prompt from buffer to gemini terminal
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
	M._send_to_gemini_terminal(table.concat(prompt_lines, "\n"))
end

-- send prompt to gemini terminal
-- @param prompt: string - prompt text
function M._send_to_gemini_terminal(prompt)
	if not M._windows.gemini_job_id then
		vim.notify("Gemini terminal not started", vim.log.levels.ERROR)
		return
	end
	-- send prompt to terminal
	vim.fn.chansend(M._windows.gemini_job_id, prompt)
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

-- hide the layout but keep gemini process running
function M.hide_layout()
	M._close_windows()
	-- clear window references but keep buffers and process
	M._windows.terminal_win = nil
	M._windows.prompt_win = nil
	M._windows.main_win = nil
	M._is_open = false
end

-- show the layout with existing gemini process
function M.show_layout()
	M._recreate_split_layout()
	vim.api.nvim_set_current_win(M._windows.prompt_win)
	M._is_open = true
end

-- completely close the layout and terminate gemini process
function M.close_layout()
	-- terminate gemini process
	if M._windows.gemini_job_id then
		vim.fn.jobstop(M._windows.gemini_job_id)
		vim.notify("Gemini process terminated", vim.log.levels.INFO)
	end
	M._close_windows()
	-- reset all references
	M._windows = {
		main_win = nil,
		terminal_win = nil,
		prompt_win = nil,
		terminal_buf = nil,
		prompt_buf = nil,
		gemini_job_id = nil,
	}
	M._is_open = false
end

-- open new gemini layout
function M.open_layout()
	local layout = M._create_split_layout()
	if not M._start_gemini_terminal(layout.terminal_buf, layout.terminal_win) then
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

-- resume gemini session with -r flag
function M.resume_session()
	-- close existing layout
	if M._is_open then
		M.close_layout()
	end
	local layout = M._create_split_layout()
	-- start with -r flag
	if not M._start_gemini_terminal(layout.terminal_buf, layout.terminal_win, "-r") then
		M.close_layout()
		return
	end
	vim.api.nvim_set_current_win(layout.prompt_win)
	M._setup_prompt_buffer(layout.prompt_buf, layout.prompt_win)
	M._is_open = true
	-- switch to terminal and enter insert mode
	vim.defer_fn(function()
		vim.api.nvim_set_current_win(layout.terminal_win)
		vim.cmd("startinsert")
	end, 100)
end

-- setup commands
function M.setup()
	vim.api.nvim_create_user_command("Gemini", M.toggle_layout, {
		desc = "Toggle Gemini terminal and prompt layout",
	})
end

-- auto-setup when module is loaded
M.setup()

return M
