-- define common functions
local M = {}
-- buffer_kill function closes buffers with confirmation
-- keymaps are set in lua/plugins/tools/internal/which_key_nvim.lua (<LEADER>c, <LEADER>bc : close current buffer)
M.buffer_kill = function(kill_command, bufnr, force)
	-- set default kill command to bd
	local kc = kill_command or "bd"
	-- if no buffer number is provided, use the current buffer
	if bufnr == 0 or bufnr == nil then
		bufnr = vim.api.nvim_get_current_buf()
	end
	-- check if buffer is valid
	local bufname = vim.api.nvim_buf_get_name(bufnr)
	if not force then
		local choice
		if vim.bo[bufnr].modified then
			-- check if buffer is unnamed
			local is_unnamed = bufname == ""
			local message = is_unnamed and "Save changes to unnamed buffer?"
				or string.format([[Save changes to "%s"?]], bufname)
			choice = vim.fn.confirm(message, "&Yes\n&No\n&Cancel")
			if choice == 1 then
				if is_unnamed then
					-- for unnamed buffers, switch to the buffer before saving
					-- to properly show the filename prompt
					local current_buf = vim.api.nvim_get_current_buf()
					-- only switch if not already on the target buffer
					if current_buf ~= bufnr then
						vim.api.nvim_set_current_buf(bufnr)
					end
					-- execute the interactive save command
					local ok, err = pcall(function()
						vim.cmd("w")
					end)
					-- if saving failed due to no filename, prompt for filename
					if not ok and string.match(err or "", "E32: No file name") then
						vim.cmd("redraw")
						local filename = vim.fn.input("Please enter filename to save: ")
						if filename and filename ~= "" then
							local dir = vim.fn.fnamemodify(filename, ":h")
							if dir ~= "." and vim.fn.isdirectory(dir) == 0 then
								choice = vim.fn.confirm(
									string.format("Directory '%s' doesn't exist. Create it?", dir),
									"&Yes\n&No",
									1
								)
								if choice == 1 then
									vim.fn.mkdir(dir, "p")
								end
							end
							vim.cmd("write " .. vim.fn.fnameescape(filename))
						end
					end
					-- restore previous buffer if needed
					if current_buf ~= bufnr then
						vim.api.nvim_set_current_buf(current_buf)
					end
				else
					-- for named buffers, use the original approach
					vim.vim.api.nvim_buf_call(bufnr, function()
						vim.cmd("w")
					end)
				end
			elseif choice == 2 then
				force = true
			else
				return
			end
		elseif vim.api.nvim_get_option_value("buftype", { buf = bufnr }) == "terminal" then
			choice = vim.fn.confirm(string.format([[Close "%s"?]], bufname), "&Yes\n&No\n&Cancel")
			if choice == 1 then
				force = true
			else
				return
			end
		end
	end
	-- get list of windows IDs with the buffer to close
	local windows = vim.tbl_filter(function(win)
		return vim.api.nvim_win_get_buf(win) == bufnr
	end, vim.api.nvim_list_wins())
	-- if there are no windows with the buffer, just delete it
	if force then
		kc = kc .. "!"
	end
	-- get list of active buffers
	local buffers = vim.tbl_filter(function(buf)
		return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted
	end, vim.api.nvim_list_bufs())
	-- if there is only one buffer (which has to be the current one), vim will
	-- create a new buffer on :bd.
	-- for more than one buffer, pick the previous buffer (wrapping around if necessary)
	if #buffers > 1 and #windows > 0 then
		for i, v in ipairs(buffers) do
			if v == bufnr then
				local prev_buf_idx = i == 1 and #buffers or (i - 1)
				local prev_buffer = buffers[prev_buf_idx]
				for _, win in ipairs(windows) do
					vim.api.nvim_win_set_buf(win, prev_buffer)
				end
			end
		end
	end
	-- check if buffer still exists, to ensure the target buffer wasn't killed
	-- due to options like bufhidden=wipe.
	if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].buflisted then
		vim.cmd(string.format("%s %d", kc, bufnr))
	end
end
-- yank_buffer_path function yanks the current buffer's path to clipboard
-- keymaps are set in lua/plugins/tools/internal/which_key_nvim.lua (<LEADER>by* : yank buffer paths)
M.yank_buffer_full_path = function()
	local bufname = vim.api.nvim_buf_get_name(0)
	if bufname == "" then
		vim.notify("Error: Cannot yank path from unnamed buffer", vim.log.levels.ERROR)
		return
	end
	local path = vim.fn.expand("%:p")
	vim.fn.setreg("+", path)
	vim.notify("Yanked full path: " .. path, vim.log.levels.INFO)
end
M.yank_buffer_filename = function()
	local bufname = vim.api.nvim_buf_get_name(0)
	if bufname == "" then
		vim.notify("Error: Cannot yank filename from unnamed buffer", vim.log.levels.ERROR)
		return
	end
	local filename = vim.fn.expand("%:t")
	vim.fn.setreg("+", filename)
	vim.notify("Yanked filename: " .. filename, vim.log.levels.INFO)
end
M.yank_buffer_directory = function()
	local bufname = vim.api.nvim_buf_get_name(0)
	if bufname == "" then
		vim.notify("Error: Cannot yank directory path from unnamed buffer", vim.log.levels.ERROR)
		return
	end
	local dirpath = vim.fn.expand("%:p:h")
	vim.fn.setreg("+", dirpath)
	vim.notify("Yanked directory path: " .. dirpath, vim.log.levels.INFO)
end
return M
