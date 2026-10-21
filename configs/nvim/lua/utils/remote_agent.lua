-- Split terminal UI for coding clients such as Happier.
local layout = require("utils.agent_layout")

local M = {}

local function available(command)
	local executable = type(command) == "table" and command[1] or command
	return type(executable) == "string" and vim.fn.executable(executable) == 1
end

local function environment(overrides)
	if not overrides then
		return nil
	end
	local env = vim.fn.environ()
	for key, value in pairs(overrides) do
		-- false removes a variable from this child without changing vim.env.
		if value == false then
			env[key] = nil
		else
			env[key] = value
		end
	end
	return env
end

function M.new(options)
	if not available(options.command) then
		return nil
	end

	local client = {
		_windows = {
			main_win = nil,
			terminal_win = nil,
			prompt_win = nil,
			terminal_buf = nil,
			prompt_buf = nil,
			job_id = nil,
		},
		_is_open = false,
	}

	function client._create_split_layout()
		client._windows.main_win = vim.api.nvim_get_current_win()
		vim.cmd("vsplit")
		local terminal_win = vim.api.nvim_get_current_win()
		vim.api.nvim_win_set_width(terminal_win, math.floor(vim.o.columns * layout.split_ratio))
		local terminal_buf = vim.api.nvim_create_buf(false, true)
		client._windows.terminal_buf = terminal_buf
		client._windows.terminal_win = terminal_win
		vim.api.nvim_win_set_buf(terminal_win, terminal_buf)
		vim.cmd("split")
		local prompt_win = vim.api.nvim_get_current_win()
		client._windows.prompt_win = prompt_win
		local total_height = vim.api.nvim_win_get_height(0)
		local terminal_height = math.floor(total_height * layout.terminal_height_ratio)
		vim.api.nvim_win_set_height(terminal_win, terminal_height)
		vim.api.nvim_win_set_height(prompt_win, total_height - terminal_height)
		local prompt_buf = vim.api.nvim_create_buf(false, true)
		client._windows.prompt_buf = prompt_buf
		vim.api.nvim_win_set_buf(prompt_win, prompt_buf)
		return {
			terminal_buf = terminal_buf,
			terminal_win = terminal_win,
			prompt_buf = prompt_buf,
			prompt_win = prompt_win,
		}
	end

	function client._recreate_split_layout()
		client._windows.main_win = vim.api.nvim_get_current_win()
		vim.cmd("vsplit")
		local terminal_win = vim.api.nvim_get_current_win()
		vim.api.nvim_win_set_width(terminal_win, math.floor(vim.o.columns * layout.split_ratio))
		client._windows.terminal_win = terminal_win
		vim.api.nvim_win_set_buf(terminal_win, client._windows.terminal_buf)
		vim.api.nvim_win_set_option(terminal_win, "winbar", "  " .. options.label)
		vim.cmd("split")
		local prompt_win = vim.api.nvim_get_current_win()
		client._windows.prompt_win = prompt_win
		local total_height = vim.api.nvim_win_get_height(0)
		local terminal_height = math.floor(total_height * layout.terminal_height_ratio)
		vim.api.nvim_win_set_height(terminal_win, terminal_height)
		vim.api.nvim_win_set_height(prompt_win, total_height - terminal_height)
		vim.api.nvim_win_set_buf(prompt_win, client._windows.prompt_buf)
		vim.api.nvim_win_set_option(prompt_win, "winbar", "  PROMPT")
	end

	function client._close_windows()
		layout.before_close(client._windows)
		layout.remember(client._windows.terminal_win, client._windows.prompt_win)
		if client._windows.prompt_win and vim.api.nvim_win_is_valid(client._windows.prompt_win) then
			vim.api.nvim_win_close(client._windows.prompt_win, true)
		end
		if client._windows.terminal_win and vim.api.nvim_win_is_valid(client._windows.terminal_win) then
			vim.api.nvim_win_close(client._windows.terminal_win, true)
		end
		if client._windows.main_win and vim.api.nvim_win_is_valid(client._windows.main_win) then
			vim.api.nvim_set_current_win(client._windows.main_win)
		end
	end

	function client._setup_terminal_keymaps(terminal_buf, terminal_win)
		vim.api.nvim_win_set_option(terminal_win, "winbar", "  " .. options.label)
		vim.api.nvim_buf_set_keymap(terminal_buf, "n", "<Esc><Esc>", "", {
			callback = client.hide,
			noremap = true,
			silent = true,
		})
		vim.api.nvim_buf_set_keymap(terminal_buf, "n", ":q<CR>", "", {
			callback = client.close,
			noremap = true,
			silent = true,
		})
		vim.api.nvim_buf_set_keymap(terminal_buf, "t", "<Esc><Esc>", "<C-\\><C-n>", {
			noremap = true,
			silent = true,
		})
	end

	function client._is_active(windows, job_id, terminal_win, prompt_win)
		return client._windows == windows
			and client._is_open
			and windows.job_id == job_id
			and job_id ~= nil
			and windows.terminal_win == terminal_win
			and windows.prompt_win == prompt_win
			and terminal_win ~= nil
			and prompt_win ~= nil
			and vim.api.nvim_win_is_valid(terminal_win)
			and vim.api.nvim_win_is_valid(prompt_win)
	end

	function client._setup_prompt_buffer(prompt_buf, prompt_win)
		vim.api.nvim_buf_set_option(prompt_buf, "buftype", "nofile")
		vim.api.nvim_buf_set_option(prompt_buf, "filetype", "markdown")
		vim.api.nvim_win_set_option(prompt_win, "winbar", "  PROMPT")
		vim.api.nvim_buf_set_lines(prompt_buf, 0, -1, false, { "" })
		vim.api.nvim_win_set_cursor(prompt_win, { 1, 0 })
		vim.api.nvim_buf_set_keymap(prompt_buf, "n", "<CR>", "", {
			callback = function()
				local windows = client._windows
				local job_id, terminal_win = windows.job_id, windows.terminal_win
				local active_prompt_win = windows.prompt_win
				if
					windows.prompt_buf ~= prompt_buf
					or not client._is_active(windows, job_id, terminal_win, active_prompt_win)
				then
					return
				end
				local lines = vim.api.nvim_buf_get_lines(prompt_buf, 0, -1, false)
				local prompt = table.concat(lines, "\n"):gsub("^%s+", ""):gsub("%s+$", "")
				if prompt == "" then
					vim.notify("Empty prompt", vim.log.levels.WARN)
					return
				end
				if not client._windows.job_id then
					vim.notify(options.label .. " terminal not started", vim.log.levels.ERROR)
					return
				end
				local function active()
					return client._is_active(windows, job_id, terminal_win, active_prompt_win)
						and vim.api.nvim_get_current_win() == terminal_win
				end
				vim.fn.chansend(job_id, prompt)
				vim.api.nvim_set_current_win(terminal_win)
				vim.defer_fn(function()
					if not active() then
						return
					end
					vim.cmd("startinsert")
					vim.defer_fn(function()
						if not active() then
							return
						end
						vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<CR>", true, false, true), "i", false)
						vim.defer_fn(function()
							if active() then
								vim.api.nvim_set_current_win(active_prompt_win)
							end
						end, 50)
					end, 50)
				end, 50)
				vim.api.nvim_buf_set_lines(prompt_buf, 0, -1, false, { "" })
				vim.api.nvim_win_set_cursor(active_prompt_win, { 1, 0 })
			end,
			noremap = true,
			silent = true,
		})
		vim.api.nvim_buf_set_keymap(prompt_buf, "n", "<Esc><Esc>", "", {
			callback = client.hide,
			noremap = true,
			silent = true,
		})
		vim.api.nvim_buf_set_keymap(prompt_buf, "n", ":q<CR>", "", {
			callback = client.close,
			noremap = true,
			silent = true,
		})
	end

	function client._start(layout_info, env)
		vim.api.nvim_set_current_win(layout_info.terminal_win)
		local windows = client._windows
		local started, job_id = pcall(vim.fn.termopen, options.command, {
			buffer = layout_info.terminal_buf,
			env = env,
			clear_env = env ~= nil,
			on_exit = function(exited_job)
				if client._windows ~= windows or windows.job_id ~= exited_job then
					return
				end
				windows.job_id = nil
				vim.notify(options.label .. " terminal closed", vim.log.levels.INFO)
				vim.defer_fn(function()
					if client._windows == windows and windows.job_id == nil then
						client.close()
					end
				end, 100)
			end,
		})
		if not started or job_id <= 0 then
			vim.notify("Failed to start " .. options.label, vim.log.levels.ERROR)
			return false
		end
		client._windows.job_id = job_id
		client._setup_terminal_keymaps(layout_info.terminal_buf, layout_info.terminal_win)
		return true
	end

	function client.hide()
		client._close_windows()
		client._windows.terminal_win = nil
		client._windows.prompt_win = nil
		client._windows.main_win = nil
		client._is_open = false
	end

	function client.show()
		client._recreate_split_layout()
		vim.api.nvim_set_current_win(client._windows.prompt_win)
		client._is_open = true
	end

	function client.close()
		local windows = client._windows
		local job_id = windows.job_id
		windows.job_id = nil
		client._is_open = false
		if job_id then
			vim.fn.jobstop(job_id)
			vim.notify(options.label .. " process terminated", vim.log.levels.INFO)
		end
		client._close_windows()
		for _, buf in ipairs({ windows.terminal_buf, windows.prompt_buf }) do
			if vim.api.nvim_buf_is_valid(buf) then
				vim.api.nvim_buf_delete(buf, { force = true })
			end
		end
		client._windows = {
			main_win = nil,
			terminal_win = nil,
			prompt_win = nil,
			terminal_buf = nil,
			prompt_buf = nil,
			job_id = nil,
		}
		client._is_open = false
	end

	function client.open()
		local env = environment(
			client._full_renderer and vim.tbl_extend("force", options.env or {}, options.full_env or {}) or options.env
		)
		if options.before_open and not options.before_open(env) then
			return
		end
		local layout_info = client._create_split_layout()
		if not client._start(layout_info, env) then
			client.close()
			return
		end
		vim.api.nvim_set_current_win(layout_info.prompt_win)
		client._setup_prompt_buffer(layout_info.prompt_buf, layout_info.prompt_win)
		client._is_open = true
	end

	-- @param full: boolean|nil - a start from closed adds options.full_env
	function client.toggle(full)
		if client._is_open then
			client.hide()
		elseif client._windows.terminal_buf and client._windows.prompt_buf then
			client.show()
		else
			client._full_renderer = full == true
			client.open()
		end
	end

	function client.toggle_full()
		layout.toggle_full(client, function()
			client.toggle(true)
		end)
	end

	return client
end

return M
