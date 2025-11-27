-- discordo integration config
-- check if discordo command is available
local function is_discordo_available()
	local handle = io.popen("command -v discordo 2>/dev/null")
	if handle then
		local result = handle:read("*a")
		handle:close()
		return result and result ~= ""
	end
	return false
end
-- early return if discordo is not available
if not is_discordo_available() then
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
	discordo_win = nil,
	input_win = nil,
	discordo_buf = nil,
	input_buf = nil,
	discordo_job_id = nil,
}
M._is_open = false

-- create vertical split layout with terminal and input
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
	local discordo_buf = vim.api.nvim_create_buf(false, true)
	M._windows.discordo_buf = discordo_buf
	M._windows.discordo_win = right_win
	vim.api.nvim_win_set_buf(right_win, discordo_buf)
	-- create horizontal split for input
	vim.cmd("split")
	local input_win = vim.api.nvim_get_current_win()
	M._windows.input_win = input_win
	-- set window heights
	local total_height = vim.api.nvim_win_get_height(0)
	local discordo_height = math.floor(total_height * config.terminal_height_ratio)
	vim.api.nvim_win_set_height(M._windows.discordo_win, discordo_height)
	vim.api.nvim_win_set_height(input_win, total_height - discordo_height)
	-- create input buffer
	local input_buf = vim.api.nvim_create_buf(false, true)
	M._windows.input_buf = input_buf
	vim.api.nvim_win_set_buf(input_win, input_buf)
	return {
		discordo_buf = discordo_buf,
		discordo_win = M._windows.discordo_win,
		input_buf = input_buf,
		input_win = input_win,
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
	-- bind existing discordo buffer
	M._windows.discordo_win = right_win
	vim.api.nvim_win_set_buf(right_win, M._windows.discordo_buf)
	-- set winbar for discordo
	vim.api.nvim_win_set_option(right_win, "winbar", "  DISCORDO")
	-- create horizontal split for input
	vim.cmd("split")
	local input_win = vim.api.nvim_get_current_win()
	M._windows.input_win = input_win
	-- set heights
	local total_height = vim.api.nvim_win_get_height(0)
	local discordo_height = math.floor(total_height * config.terminal_height_ratio)
	vim.api.nvim_win_set_height(M._windows.discordo_win, discordo_height)
	vim.api.nvim_win_set_height(input_win, total_height - discordo_height)
	-- bind existing input buffer
	vim.api.nvim_win_set_buf(input_win, M._windows.input_buf)
	-- set winbar for input
	vim.api.nvim_win_set_option(input_win, "winbar", "  INPUT")
end

-- close windows but keep buffers and process
function M._close_windows()
	-- close input window
	if M._windows.input_win and vim.api.nvim_win_is_valid(M._windows.input_win) then
		vim.api.nvim_win_close(M._windows.input_win, true)
	end
	-- close discordo window
	if M._windows.discordo_win and vim.api.nvim_win_is_valid(M._windows.discordo_win) then
		vim.api.nvim_win_close(M._windows.discordo_win, true)
	end
	-- return to main window
	if M._windows.main_win and vim.api.nvim_win_is_valid(M._windows.main_win) then
		vim.api.nvim_set_current_win(M._windows.main_win)
	end
end

-- setup terminal buffer keymaps
-- @param discordo_buf: number - terminal buffer number
-- @param discordo_win: number - terminal window number
function M._setup_terminal_keymaps(discordo_buf, discordo_win)
	-- set winbar for discordo terminal
	vim.api.nvim_win_set_option(discordo_win, "winbar", "  DISCORDO")
	-- hide layout with double Esc in normal mode
	vim.api.nvim_buf_set_keymap(discordo_buf, "n", "<Esc><Esc>", "", {
		callback = M.hide_layout,
		noremap = true,
		silent = true,
	})
	-- close layout with :q
	vim.api.nvim_buf_set_keymap(discordo_buf, "n", ":q<CR>", "", {
		callback = M.close_layout,
		noremap = true,
		silent = true,
	})
	-- exit terminal mode with double Esc
	vim.api.nvim_buf_set_keymap(discordo_buf, "t", "<Esc><Esc>", "<C-\\><C-n>", {
		noremap = true,
		silent = true,
	})
end

-- setup input buffer
-- @param input_buf: number - input buffer number
-- @param input_win: number - input window number
function M._setup_input_buffer(input_buf, input_win)
	-- set buffer options
	vim.api.nvim_buf_set_option(input_buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(input_buf, "filetype", "markdown")
	-- set winbar for input buffer
	vim.api.nvim_win_set_option(input_win, "winbar", "  INPUT")
	-- clear buffer content
	vim.api.nvim_buf_set_lines(input_buf, 0, -1, false, {})
	-- position cursor
	vim.api.nvim_win_set_cursor(input_win, { 1, 0 })
	-- send input with Enter
	vim.api.nvim_buf_set_keymap(input_buf, "n", "<CR>", "", {
		callback = function()
			M._send_input_from_buffer(input_buf)
		end,
		noremap = true,
		silent = true,
	})
	-- hide layout with double Esc
	vim.api.nvim_buf_set_keymap(input_buf, "n", "<Esc><Esc>", "", {
		callback = M.hide_layout,
		noremap = true,
		silent = true,
	})
	-- close layout with :q
	vim.api.nvim_buf_set_keymap(input_buf, "n", ":q<CR>", "", {
		callback = M.close_layout,
		noremap = true,
		silent = true,
	})
end

-- send input from buffer to discordo terminal
-- @param input_buf: number - input buffer number
function M._send_input_from_buffer(input_buf)
	local lines = vim.api.nvim_buf_get_lines(input_buf, 0, -1, false)
	-- collect non-empty lines
	local input_lines = {}
	for i = 1, #lines do
		if lines[i] ~= "" or #input_lines > 0 then
			table.insert(input_lines, lines[i])
		end
	end
	if #input_lines == 0 then
		vim.notify("Empty input", vim.log.levels.WARN)
		return
	end
	M._send_to_discordo_terminal(table.concat(input_lines, "\n"))
end

-- send input to discordo terminal
-- @param input: string - input text
function M._send_to_discordo_terminal(input)
	if not M._windows.discordo_job_id then
		vim.notify("Discordo terminal not started", vim.log.levels.ERROR)
		return
	end
	-- send input to terminal
	vim.fn.chansend(M._windows.discordo_job_id, input)
	-- switch to terminal and press enter to submit
	vim.api.nvim_set_current_win(M._windows.discordo_win)
	vim.defer_fn(function()
		vim.cmd("startinsert")
		vim.defer_fn(function()
			vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "i", false)
			vim.defer_fn(function()
				vim.api.nvim_set_current_win(M._windows.input_win)
			end, 50)
		end, 50)
	end, 50)
	-- clear input buffer
	vim.api.nvim_buf_set_lines(M._windows.input_buf, 0, -1, false, { "" })
	vim.api.nvim_win_set_cursor(M._windows.input_win, { 1, 0 })
end

-- start discordo terminal
-- @param discordo_buf: number - terminal buffer number
-- @param discordo_win: number - terminal window number
-- @return boolean - success status
function M._start_discordo_terminal(discordo_buf, discordo_win)
	vim.api.nvim_set_current_win(discordo_win)
	-- start terminal
	local job_id = vim.fn.termopen("discordo", {
		buffer = discordo_buf,
		on_exit = function()
			vim.notify("Discordo terminal closed", vim.log.levels.INFO)
			vim.defer_fn(function()
				M.close_layout()
			end, 100)
		end,
	})

	if job_id == 0 then
		vim.notify("Failed to start discordo", vim.log.levels.ERROR)
		return false
	end

	M._windows.discordo_job_id = job_id
	M._setup_terminal_keymaps(discordo_buf, discordo_win)
	return true
end

-- hide the layout but keep discordo process running
function M.hide_layout()
	M._close_windows()
	-- clear window references but keep buffers and process
	M._windows.discordo_win = nil
	M._windows.input_win = nil
	M._windows.main_win = nil
	M._is_open = false
end

-- show the layout with existing discordo process
function M.show_layout()
	M._recreate_split_layout()
	vim.api.nvim_set_current_win(M._windows.input_win)
	M._is_open = true
end

-- completely close the layout and terminate discordo process
function M.close_layout()
	-- terminate discordo process
	if M._windows.discordo_job_id then
		vim.fn.jobstop(M._windows.discordo_job_id)
		vim.notify("Discordo process terminated", vim.log.levels.INFO)
	end
	M._close_windows()
	-- reset all references
	M._windows = {
		main_win = nil,
		discordo_win = nil,
		input_win = nil,
		discordo_buf = nil,
		input_buf = nil,
		discordo_job_id = nil,
	}
	M._is_open = false
end

-- open new discordo layout
function M.open_layout()
	local layout = M._create_split_layout()
	if not M._start_discordo_terminal(layout.discordo_buf, layout.discordo_win) then
		M.close_layout()
		return
	end
	vim.api.nvim_set_current_win(layout.input_win)
	M._setup_input_buffer(layout.input_buf, layout.input_win)
	M._is_open = true
end

-- toggle layout visibility
function M.toggle_layout()
	if M._is_open then
		M.hide_layout()
	else
		-- check if we have existing buffers (hidden state)
		if M._windows.discordo_buf and M._windows.input_buf then
			M.show_layout()
		else
			M.open_layout()
		end
	end
end

-- setup commands
function M.setup()
	vim.api.nvim_create_user_command("Discordo", M.toggle_layout, {
		desc = "Toggle Discordo terminal and input layout",
	})
end

-- auto-setup when module is loaded
M.setup()

return M
