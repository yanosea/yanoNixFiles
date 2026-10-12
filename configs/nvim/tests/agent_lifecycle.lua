-- Run from the repository root: nvim --headless -u NONE -l configs/nvim/tests/agent_lifecycle.lua
local source = debug.getinfo(1, "S").source:sub(2)
local runtime = vim.fn.fnamemodify(source, ":p:h:h")
if vim.env.NVIM_AGENT_TEST_RUNTIME then
	runtime = vim.env.NVIM_AGENT_TEST_RUNTIME
end
vim.opt.runtimepath:prepend(runtime)
vim.o.lines = 60
vim.o.columns = 160
vim.notify = function() end

local real = {
	termopen = vim.fn.termopen,
	jobstop = vim.fn.jobstop,
	chansend = vim.fn.chansend,
	defer_fn = vim.defer_fn,
	feedkeys = vim.api.nvim_feedkeys,
	popen = io.popen,
}
local jobs, stopped, pending, sent, fed, spawn_result, spawn_error, sequence
local function equal(actual, expected, message)
	assert(actual == expected, message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local function drain_one()
	local callback = table.remove(pending, 1)
	if callback then
		callback()
	end
end
local function drain()
	while #pending > 0 do
		drain_one()
	end
end
local function clean()
	vim.cmd("stopinsert")
	vim.cmd("silent! only!")
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_valid(buf) and buf ~= vim.api.nvim_get_current_buf() then
			vim.api.nvim_buf_delete(buf, { force = true })
		end
	end
end
local function reset()
	clean()
	jobs, stopped, pending, sent, fed, sequence = {}, {}, {}, {}, {}, 0
	spawn_result = nil
	spawn_error = false
	vim.fn.termopen = function(command, opts)
		if spawn_error then
			error("fixture executable missing")
		end
		sequence = sequence + 1
		local result = spawn_result or sequence
		jobs[result] = { command = command, opts = opts, buf = vim.api.nvim_get_current_buf() }
		return result
	end
	vim.fn.jobstop = function(id)
		stopped[id] = true
		return 1
	end
	vim.fn.chansend = function(id, text)
		sent[#sent + 1] = { id = id, text = text }
		return #text
	end
	vim.defer_fn = function(callback)
		pending[#pending + 1] = callback
	end
	vim.api.nvim_feedkeys = function(keys)
		fed[#fed + 1] = { keys = keys, win = vim.api.nvim_get_current_win() }
	end
	-- Mock CLI discovery without requiring installed agent binaries.
	-- selene: allow(incorrect_standard_library_use)
	io.popen = function()
		return {
			read = function()
				return "available\n"
			end,
			close = function() end,
		}
	end
end
-- tui wrappers under lua/config, with the command each resume launches
local tuis = {
	opencode = { user_command = "Opencode", resume = "opencode mini --continue" },
	grok = { user_command = "Grok", resume = "grok --no-alt-screen /resume" },
}
local function adapter(kind)
	if kind == "remote" or kind == "remote_argv" then
		package.loaded["utils.remote_agent"] = nil
		local client = require("utils.remote_agent").new({
			command = kind == "remote_argv" and { "sh" } or "sh",
			label = "Test",
			env = kind == "remote_argv" and { GOOSE_MODE = "smart_approve", ANTHROPIC_API_KEY = false } or nil,
		})
		return {
			object = client,
			open = client.open,
			close = client.close,
			hide = client.hide,
			show = client.show,
			job = function()
				return client._windows.job_id
			end,
		}
	end
	local tui = tuis[kind]
	package.loaded["config." .. kind] = nil
	pcall(vim.api.nvim_del_user_command, tui.user_command)
	local client = require("config." .. kind)
	return {
		object = client,
		open = client.open_layout,
		close = client.close_layout,
		hide = client.hide_layout,
		show = client.show_layout,
		resume = client.resume_session,
		job = function()
			return client._windows[kind .. "_job_id"]
		end,
	}
end
local function submit(client)
	local buf = client.object._windows.prompt_buf
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "日本語の依頼", "", "次の行も保持する" })
	for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(buf, "n")) do
		if mapping.lhs == "<CR>" then
			mapping.callback()
			return
		end
	end
	error("prompt mapping missing")
end
local function deleted(windows)
	equal(vim.api.nvim_buf_is_valid(windows.terminal_buf), false, "terminal buffer removed")
	equal(vim.api.nvim_buf_is_valid(windows.prompt_buf), false, "prompt buffer removed")
end
local cases = {}
local function case(name, callback)
	cases[#cases + 1] = { name = name, callback = callback }
end
for _, kind in ipairs({ "remote", "remote_argv", "opencode", "grok" }) do
	case(kind .. " stale exit cannot close a reopened job", function()
		local c = adapter(kind)
		c.open()
		local old = c.job()
		c.close()
		c.open()
		local current = c.job()
		jobs[old].opts.on_exit(old, 0, "exit")
		drain()
		equal(stopped[current], nil, "new job remains running")
		equal(c.object._is_open, true, "new layout stays visible")
	end)
	case(kind .. " deferred exit checks its owner at execution", function()
		local c = adapter(kind)
		c.open()
		local old = c.job()
		jobs[old].opts.on_exit(old, 0, "exit")
		c.close()
		c.open()
		local current = c.job()
		drain()
		equal(stopped[current], nil, "new job survives queued old exit")
		equal(c.object._is_open, true, "new layout survives queued old exit")
	end)
	for _, hidden in ipairs({ false, true }) do
		case(kind .. " natural exit cleans " .. (hidden and "hidden" or "visible") .. " resources", function()
			local c = adapter(kind)
			c.open()
			local old = c.job()
			local windows = vim.deepcopy(c.object._windows)
			if hidden then
				c.hide()
			end
			jobs[old].opts.on_exit(old, 0, "exit")
			drain()
			equal(c.job(), nil, "exited job no longer available")
			equal(c.object._is_open, false, "layout closed on natural exit")
			deleted(windows)
			equal(#vim.api.nvim_list_wins(), 1, "layout windows removed")
		end)
	end
	for _, result in ipairs({ 0, -1 }) do
		case(kind .. " failed spawn " .. result .. " cleans resources", function()
			local c = adapter(kind)
			local before = #vim.api.nvim_list_bufs()
			spawn_result = result
			c.open()
			equal(c.job(), nil, "invalid job is not retained")
			equal(c.object._is_open, false, "failed layout is not open")
			equal(#vim.api.nvim_list_wins(), 1, "failed layout windows removed")
			equal(#vim.api.nvim_list_bufs(), before, "failed layout buffers removed")
		end)
	end
	case(kind .. " hide/show preserves buffers and job", function()
		local c = adapter(kind)
		c.open()
		local old = c.job()
		local windows = vim.deepcopy(c.object._windows)
		c.hide()
		equal(stopped[old], nil, "hide keeps process")
		c.show()
		equal(c.job(), old, "show reuses process")
		equal(c.object._windows.prompt_buf, windows.prompt_buf, "show reuses prompt")
		equal(c.object._windows.terminal_buf, windows.terminal_buf, "show reuses terminal")
		c.close()
		deleted(windows)
	end)
	case(kind .. " hide/show keeps prompt submission usable", function()
		local c = adapter(kind)
		c.open()
		c.hide()
		c.show()
		submit(c)
		drain()
		equal(#sent, 1, "shown prompt sends to existing job")
		equal(#fed, 1, "shown prompt submits Enter")
		equal(vim.api.nvim_get_current_win(), c.object._windows.prompt_win, "focus returns to shown prompt")
	end)
	case(kind .. " exit cancels pending and new prompt submission", function()
		local c = adapter(kind)
		c.open()
		local id = c.job()
		submit(c)
		jobs[id].opts.on_exit(id, 0, "exit")
		submit(c)
		drain()
		equal(#sent, 1, "no send after natural exit")
		equal(#fed, 0, "no Enter after natural exit")
	end)
	case(kind .. " delayed submission does not steal user focus", function()
		local c = adapter(kind)
		c.open()
		submit(c)
		vim.api.nvim_set_current_win(c.object._windows.main_win)
		local focus = vim.api.nvim_get_current_win()
		drain()
		equal(#fed, 0, "Enter not injected into user's window")
		equal(vim.api.nvim_get_current_win(), focus, "user focus preserved")
	end)
	case(kind .. " Japanese multiline submission preserves payload", function()
		local c = adapter(kind)
		c.open()
		local id = c.job()
		submit(c)
		drain()
		equal(sent[1].id, id, "prompt sent to current job")
		equal(sent[1].text, "日本語の依頼\n\n次の行も保持する", "multiline payload retained")
		equal(#fed, 1, "Enter submitted once")
		equal(vim.api.nvim_get_current_win(), c.object._windows.prompt_win, "focus returned to prompt")
	end)
	for _, stage in ipairs({ 0, 1, 2 }) do
		for _, action in ipairs({ "hide", "close", "reopen", "hide_show" }) do
			case(kind .. " delayed submission stage " .. stage .. " cancelled by " .. action, function()
				local c = adapter(kind)
				c.open()
				submit(c)
				for _ = 1, stage do
					drain_one()
				end
				local feed_count = #fed
				if action == "hide" then
					c.hide()
				elseif action == "close" then
					c.close()
				elseif action == "reopen" then
					c.close()
					c.open()
				else
					c.hide()
					c.show()
				end
				local focus = vim.api.nvim_get_current_win()
				drain()
				equal(#fed, feed_count, "no stale Enter")
				equal(vim.api.nvim_get_current_win(), focus, "no stale focus change")
			end)
		end
	end
end
case("remote argv thrown spawn failure cleans resources", function()
	local c = adapter("remote_argv")
	local before = #vim.api.nvim_list_bufs()
	spawn_error = true
	c.open()
	equal(c.job(), nil, "failed job not retained")
	equal(c.object._is_open, false, "failed layout not open")
	equal(#vim.api.nvim_list_wins(), 1, "failed layout windows removed")
	equal(#vim.api.nvim_list_bufs(), before, "failed layout buffers removed")
end)
for _, kind in ipairs({ "opencode", "grok" }) do
	case(kind .. " resume stops the hidden old job", function()
		local c = adapter(kind)
		c.open()
		local old = c.job()
		local windows = vim.deepcopy(c.object._windows)
		c.hide()
		c.resume()
		equal(stopped[old], true, "hidden old process stopped")
		deleted(windows)
		equal(jobs[c.job()].command, tuis[kind].resume, "resume command preserved")
	end)
	case(kind .. " stale exit cannot close the resumed job", function()
		local c = adapter(kind)
		c.open()
		local old = c.job()
		c.resume()
		local current = c.job()
		jobs[old].opts.on_exit(old, 0, "exit")
		drain()
		equal(stopped[current], nil, "resumed job remains running")
		equal(c.object._is_open, true, "resumed layout remains open")
	end)
	for _, action in ipairs({ "hide", "close", "reopen", "hide_show" }) do
		case(kind .. " delayed resume cancelled by " .. action, function()
			local c = adapter(kind)
			c.resume()
			if action == "hide" then
				c.hide()
			elseif action == "close" then
				c.close()
			elseif action == "reopen" then
				c.close()
				c.open()
			else
				c.hide()
				c.show()
			end
			local focus = vim.api.nvim_get_current_win()
			drain()
			equal(vim.api.nvim_get_current_win(), focus, "resume does not refocus an old window")
		end)
	end
end
local failures = 0
for _, test in ipairs(cases) do
	reset()
	local ok, err = pcall(test.callback)
	if ok then
		print("PASS " .. test.name)
	else
		failures = failures + 1
		print("FAIL " .. test.name .. ": " .. tostring(err))
	end
end
-- selene: allow(incorrect_standard_library_use)
io.popen = real.popen
vim.fn.termopen = real.termopen
vim.fn.jobstop = real.jobstop
vim.fn.chansend = real.chansend
vim.defer_fn = real.defer_fn
vim.api.nvim_feedkeys = real.feedkeys
clean()
print(string.format("%d cases, %d failures", #cases, failures))
vim.cmd(failures == 0 and "qa!" or "cquit")
