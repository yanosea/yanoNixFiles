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
	vim.cmd("silent! tabnew")
	vim.cmd("silent! tabonly!")
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
	antigravity = { user_command = "Antigravity", job = "antigravity_job_id", resume = "agy -i /resume" },
	kiro = { user_command = "Kiro", job = "kiro_job_id", resume = "kiro-cli --resume-picker" },
}
local function adapter(kind)
	if kind == "remote" or kind == "remote_argv" then
		package.loaded["utils.remote_agent"] = nil
		local client = require("utils.remote_agent").new({
			command = kind == "remote_argv" and { "sh" } or "sh",
			label = "Test",
			env = kind == "remote_argv" and { AGENT_TEST_MODE = "1", ANTHROPIC_API_KEY = false } or nil,
			full_env = { AGENT_FULL_RENDERER = "1" },
		})
		return {
			object = client,
			open = client.open,
			close = client.close,
			hide = client.hide,
			show = client.show,
			full = client.toggle_full,
			job = function()
				return client._windows.job_id
			end,
		}
	end
	local tui = tuis[kind]
	local job_key = tui.job or kind .. "_job_id"
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
		full = client.toggle_full,
		job = function()
			return client._windows[job_key]
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
for _, kind in ipairs({ "remote", "remote_argv", "antigravity", "kiro", "opencode", "grok" }) do
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
for _, kind in ipairs({ "antigravity", "kiro", "opencode", "grok" }) do
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
-- fullscreen: every CLI wrapper and the Happier client share the same behavior
local layout = require("utils.agent_layout")
-- the command and the env key of each kind's split and fullscreen renderers
local renderers = {
	remote = { split = "sh", full = "sh", full_env = "AGENT_FULL_RENDERER" },
	remote_argv = { split = '{ "sh" }', full = '{ "sh" }', full_env = "AGENT_FULL_RENDERER" },
	antigravity = { split = "agy", full = "agy" },
	kiro = { split = "kiro-cli", full = "kiro-cli" },
	opencode = { split = "opencode mini", full = "opencode" },
	grok = { split = "grok --no-alt-screen", full = "grok" },
}
local function launched(c)
	local job = jobs[c.job()]
	return type(job.command) == "table" and vim.inspect(job.command) or job.command, job.opts.env or {}
end
-- in its own tab page that holds exactly the terminal and the prompt
local function full_windows(c)
	local windows = c.object._windows
	if not (layout.is_full(windows.terminal_win) and layout.is_full(windows.prompt_win)) then
		return false
	end
	local wins = vim.api.nvim_tabpage_list_wins(vim.api.nvim_win_get_tabpage(windows.terminal_win))
	return #wins == 2 and vim.tbl_contains(wins, windows.terminal_win) and vim.tbl_contains(wins, windows.prompt_win)
end
for _, kind in ipairs({ "remote", "remote_argv", "antigravity", "kiro", "opencode", "grok" }) do
	case(kind .. " fullscreen covers the editor and keeps the prompt", function()
		local c = adapter(kind)
		c.open()
		local windows = c.object._windows
		local prompt_height = vim.api.nvim_win_get_height(windows.prompt_win)
		local prompt_buf = windows.prompt_buf
		c.full()
		equal(full_windows(c), true, "a tab with only the terminal and the prompt")
		equal(#vim.api.nvim_tabpage_list_wins(0), 2, "no covered window in the current tab")
		equal(vim.api.nvim_win_get_width(windows.terminal_win), vim.o.columns, "terminal spans the editor width")
		equal(vim.api.nvim_win_get_height(windows.prompt_win), layout.full_prompt_height, "prompt is thin")
		equal(
			vim.api.nvim_win_get_position(windows.terminal_win)[1]
				< vim.api.nvim_win_get_position(windows.prompt_win)[1],
			true,
			"terminal above the prompt"
		)
		equal(vim.api.nvim_get_current_win(), windows.prompt_win, "fullscreen prompt has focus")
		c.full()
		equal(#vim.api.nvim_list_tabpages(), 1, "leaving closes the fullscreen tab")
		equal(vim.api.nvim_win_get_height(windows.prompt_win), prompt_height, "split prompt height comes back")
		equal(vim.api.nvim_get_current_win(), windows.prompt_win, "prompt has focus for input")
		equal(vim.api.nvim_win_get_buf(windows.prompt_win), prompt_buf, "prompt buffer is kept")
		equal(c.job() ~= nil, true, "process keeps running")
	end)
	case(kind .. " fullscreen round trip restores the split and the process", function()
		local c = adapter(kind)
		c.open()
		local old = c.job()
		local terminal_width = vim.api.nvim_win_get_width(c.object._windows.terminal_win)
		c.full()
		c.full()
		equal(full_windows(c), false, "back to the split layout")
		equal(c.object._is_open, true, "layout stays open")
		equal(c.job(), old, "same process")
		equal(stopped[old], nil, "process not stopped")
		equal(vim.api.nvim_win_get_width(c.object._windows.terminal_win), terminal_width, "split width kept")
	end)
	case(kind .. " fullscreen hide then show returns to the split", function()
		local c = adapter(kind)
		c.open()
		c.full()
		c.hide()
		equal(c.object._is_open, false, "hidden from fullscreen")
		c.show()
		equal(full_windows(c), false, "show restores the split, not fullscreen")
	end)
	case(kind .. " fullscreen close terminates the process", function()
		local c = adapter(kind)
		c.open()
		local old = c.job()
		c.full()
		c.close()
		equal(stopped[old], true, "process stopped from fullscreen")
		equal(#vim.api.nvim_list_wins(), 1, "floats removed")
	end)
	case(kind .. " split start launches the split renderer", function()
		local c = adapter(kind)
		c.open()
		local command, env = launched(c)
		local renderer = renderers[kind]
		equal(command, renderer.split, "split command")
		if renderer.split_env then
			equal(env[renderer.split_env], "1", "split env")
		end
		if renderer.full_env then
			equal(env[renderer.full_env], nil, "no fullscreen env")
		end
		c.full()
		equal(c.job() ~= nil and launched(c), renderer.split, "toggling keeps the running renderer")
	end)
	case(kind .. " full start launches the fullscreen renderer, kept by toggles and resume", function()
		local c = adapter(kind)
		c.full()
		local command, env = launched(c)
		local renderer = renderers[kind]
		equal(command, renderer.full, "fullscreen command")
		if renderer.full_env then
			equal(env[renderer.full_env], "1", "fullscreen env")
		end
		if renderer.split_env then
			equal(env[renderer.split_env], nil, "no split env")
		end
		local job = c.job()
		c.full()
		c.full()
		equal(c.job(), job, "toggles keep the process")
		if c.resume then
			c.resume()
			local resumed, resumed_env = launched(c)
			equal(vim.startswith(resumed, renderer.full), true, "resume keeps the fullscreen command")
			if renderer.split ~= renderer.full then
				equal(vim.startswith(resumed, renderer.split), false, "resume is not the split command")
			end
			if renderer.full_env then
				equal(resumed_env[renderer.full_env], "1", "resume keeps the fullscreen env")
			end
		end
	end)
	case(kind .. " fullscreen from closed starts the tool fullscreen", function()
		local c = adapter(kind)
		c.full()
		local windows = c.object._windows
		equal(c.object._is_open, true, "layout opened")
		equal(c.job() ~= nil, true, "process started")
		equal(full_windows(c), true, "opened fullscreen")
		equal(vim.api.nvim_win_get_width(windows.terminal_win), vim.o.columns, "terminal spans the editor width")
		equal(
			vim.api.nvim_win_get_position(windows.prompt_win)[1]
				> vim.api.nvim_win_get_position(windows.terminal_win)[1],
			true,
			"prompt sits below the terminal"
		)
		equal(#vim.api.nvim_tabpage_list_wins(0), 2, "only the terminal and the prompt in the tab")
		equal(vim.api.nvim_get_current_win(), windows.prompt_win, "prompt has focus for input")
		c.full()
		equal(full_windows(c), false, "second toggle returns to the split")
	end)
	case(kind .. " fullscreen from hidden reuses the process", function()
		local c = adapter(kind)
		c.open()
		local old = c.job()
		local terminal_buf = c.object._windows.terminal_buf
		c.hide()
		c.full()
		equal(c.object._is_open, true, "shown again")
		equal(full_windows(c), true, "shown fullscreen")
		equal(c.job(), old, "same process")
		equal(c.object._windows.terminal_buf, terminal_buf, "same terminal buffer")
		equal(stopped[old], nil, "process not stopped")
	end)
	case(kind .. " fullscreen prompt stays thin when windows are equalized", function()
		local c = adapter(kind)
		c.open()
		c.full()
		local windows = c.object._windows
		-- nvim lays out the tab's splits on resize itself; winfixheight keeps the prompt
		vim.cmd("wincmd =")
		equal(vim.api.nvim_win_get_height(windows.prompt_win), layout.full_prompt_height, "prompt stays thin")
		equal(vim.api.nvim_win_get_width(windows.terminal_win), vim.o.columns, "terminal keeps the full width")
	end)
	case(kind .. " fullscreen from another tab returns to its own tab", function()
		local c = adapter(kind)
		c.full()
		local tab = vim.api.nvim_get_current_tabpage()
		vim.cmd("tabnew")
		local tabs = #vim.api.nvim_list_tabpages()
		c.full()
		equal(vim.api.nvim_get_current_tabpage(), tab, "back in the fullscreen tab")
		equal(#vim.api.nvim_list_tabpages(), tabs, "no second fullscreen tab")
		equal(full_windows(c), true, "still fullscreen")
	end)
	case(kind .. " hide, close and natural exit leave no fullscreen tab", function()
		local c = adapter(kind)
		c.full()
		c.hide()
		equal(#vim.api.nvim_list_tabpages(), 1, "hide closes the fullscreen tab")
		c.full()
		local job = c.job()
		c.close()
		equal(#vim.api.nvim_list_tabpages(), 1, "close closes the fullscreen tab")
		equal(stopped[job], true, "close stops the process")
		c.full()
		jobs[c.job()].opts.on_exit(c.job(), 0, "exit")
		drain()
		equal(#vim.api.nvim_list_tabpages(), 1, "natural exit closes the fullscreen tab")
		equal(#vim.api.nvim_list_wins(), 1, "no window left behind")
	end)
	case(kind .. " fullscreen tab left as the last tab still hides", function()
		local c = adapter(kind)
		c.full()
		vim.cmd("tabonly")
		c.hide()
		equal(c.object._is_open, false, "hidden")
		equal(#vim.api.nvim_tabpage_list_wins(0), 1, "an empty tab remains")
	end)
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
