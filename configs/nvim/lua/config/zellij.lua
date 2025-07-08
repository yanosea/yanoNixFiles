-- zellij integration config only when zellij is available
-- check if zellij is available
local function is_zellij_available()
	-- check if running in zellij session
	if not os.getenv("ZELLIJ") then
		return false
	end
	-- check if zellij command is available
	local handle = io.popen("command -v zellij 2>/dev/null")
	if handle then
		local result = handle:read("*a")
		handle:close()
		return result and result ~= ""
	end
	return false
end
-- early return if zellij is not available
if not is_zellij_available() then
	return
end
-- define module
local M = {}
-- configuration
local config = {
	-- maximum buffer size in characters
	buffer_size_limit = 5000,
}
-- send text to zellij pane in specified direction
-- @param text: string - text to send
-- @param direction: string - direction to move focus ("up", "down", "left", "right")
function M.send_to_pane(text, direction)
	-- double-check zellij availability
	if not os.getenv("ZELLIJ") then
		vim.notify("Not running in a zellij session", vim.log.levels.ERROR)
		return false
	end
	-- default to "up" if direction is empty or nil
	direction = direction and direction ~= "" and direction or "up"
	-- validate direction
	local valid_directions = { up = true, down = true, left = true, right = true }
	if not valid_directions[direction] then
		vim.notify("Invalid direction: " .. direction .. ". Use: up, down, left, right", vim.log.levels.ERROR)
		return false
	end
	-- escape text for shell (minimal escaping for single quotes)
	local escaped_text = text:gsub("'", "'\"'\"'")
	-- create script to send text
	local script = string.format(
		[[
		zellij action move-focus %s
		sleep 0.1
		zellij action write-chars '%s'
		sleep 0.1
		zellij action write-chars $'\r'
		sleep 0.1
		zellij action move-focus %s
		]],
		direction,
		escaped_text,
		M._get_opposite_direction(direction)
	)
	-- send text to zellij pane and check for success
	local success = os.execute(script)
	if success then
		vim.notify("Text sent to " .. direction .. " pane", vim.log.levels.INFO)
		return true
	else
		vim.notify("Failed to send text to pane", vim.log.levels.ERROR)
		return false
	end
end
-- get opposite direction to return focus
-- @param direction: string - original direction
-- @return string - opposite direction
function M._get_opposite_direction(direction)
	local opposites = {
		up = "down",
		down = "up",
		left = "right",
		right = "left",
	}
	return opposites[direction] or "down"
end
-- delete sent text based on the last operation
function M._delete_sent_text()
	if M._last_operation == "line" then
		-- delete current line
		local current_line = vim.fn.line(".")
		vim.api.nvim_buf_set_lines(0, current_line - 1, current_line, false, {})
		vim.notify("Line deleted", vim.log.levels.INFO)
	elseif M._last_operation == "buffer" then
		-- clear entire buffer
		vim.api.nvim_buf_set_lines(0, 0, -1, false, {})
		vim.notify("Buffer cleared", vim.log.levels.INFO)
	end
end
-- prompt user for direction using hjkl keys
-- @param text: string - text to send
-- @param delete_after: boolean - whether to delete text after sending
function M.send_with_prompt(text, delete_after)
	delete_after = delete_after or false
	-- show prompt message
	vim.api.nvim_echo({
		{ "Direction: ", "Normal" },
		{ "h", "WarningMsg" },
		{ "(left) ", "Normal" },
		{ "j", "WarningMsg" },
		{ "(down) ", "Normal" },
		{ "k", "WarningMsg" },
		{ "(up) ", "Normal" },
		{ "l", "WarningMsg" },
		{ "(right) ", "Normal" },
		{ "ESC", "ErrorMsg" },
		{ "(cancel)", "Normal" },
	}, false, {})
	-- get single character input
	local char = vim.fn.getchar()
	local key = vim.fn.nr2char(char)
	-- clear the prompt
	vim.api.nvim_echo({}, false, {})
	-- map hjkl to directions
	local direction_map = {
		h = "left",
		j = "down",
		k = "up",
		l = "right",
	}
	-- handle esc key (char code 27)
	if char == 27 then
		return false
	end
	local direction = direction_map[key]
	if not direction then
		-- default to up for any other key
		direction = "up"
	end
	-- send text to zellij pane
	local success = M.send_to_pane(text, direction)
	-- delete text after successful send if requested
	if success and delete_after then
		M._delete_sent_text()
	end
	return success
end
-- send current line to zellij pane
function M.send_current_line()
	local line = vim.fn.getline(".")
	M._last_operation = "line"
	M.send_with_prompt(line, true)
end
-- send buffer content to zellij pane (with size limit)
function M.send_buffer()
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local text = table.concat(lines, "\n")
	-- check buffer size (limit to reasonable size)
	if #text > config.buffer_size_limit then
		vim.notify(
			"Buffer too large (" .. #text .. " chars). Max " .. config.buffer_size_limit .. " chars.",
			vim.log.levels.WARN
		)
		return
	end
	M._last_operation = "buffer"
	M.send_with_prompt(text, true)
end
-- send current line without deleting
function M.send_current_line_keep()
	local line = vim.fn.getline(".")
	M._last_operation = "line"
	M.send_with_prompt(line, false)
end
-- send buffer without deleting
function M.send_buffer_keep()
	local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local text = table.concat(lines, "\n")
	-- check buffer size (limit to reasonable size)
	if #text > config.buffer_size_limit then
		vim.notify(
			"Buffer too large (" .. #text .. " chars). Max " .. config.buffer_size_limit .. " chars.",
			vim.log.levels.WARN
		)
		return
	end
	M._last_operation = "buffer"
	M.send_with_prompt(text, false)
end
-- setup function to create commands
function M.setup()
	-- create user commands (delete after send)
	vim.api.nvim_create_user_command("ZellijSendLine", M.send_current_line, {
		desc = "Send current line to zellij pane (delete after send)",
	})
	vim.api.nvim_create_user_command("ZellijSendBuffer", M.send_buffer, {
		desc = "Send buffer content to zellij pane (delete after send)",
	})
	-- create user commands (keep after send)
	vim.api.nvim_create_user_command("ZellijSendLineKeep", M.send_current_line_keep, {
		desc = "Send current line to zellij pane (keep text)",
	})
	vim.api.nvim_create_user_command("ZellijSendBufferKeep", M.send_buffer_keep, {
		desc = "Send buffer content to zellij pane (keep text)",
	})
end
-- auto-setup when module is loaded only if zellij is available
M.setup()

return M
