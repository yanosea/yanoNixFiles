-- Run from the repository root: nvim --headless -u NONE -l configs/nvim/tests/agent_lifecycle_pty.lua
local source = debug.getinfo(1, "S").source:sub(2)
vim.opt.runtimepath:prepend(vim.fn.fnamemodify(source, ":p:h:h"))
vim.o.lines = 60
vim.o.columns = 160
vim.notify = function() end
local fixture = vim.fn.tempname()
vim.fn.mkdir(fixture, "p")
local command = fixture .. "/opencode"
-- the tui wrappers find the same fixture under each cli's name
for _, name in ipairs({ "opencode", "grok" }) do
	vim.fn.writefile({
		"#!/bin/sh",
		'if test "$NVIM_AGENT_PTY_BYTES" = ""; then exec cat; fi',
		"stty -echo -icanon min 1 time 0",
		"printf READY",
		'exec dd bs=1 count="$NVIM_AGENT_PTY_BYTES" of="$NVIM_AGENT_PTY_OUTPUT" 2>/dev/null',
	}, fixture .. "/" .. name)
	vim.fn.setfperm(fixture .. "/" .. name, "rwx------")
end
local old_path = vim.env.PATH
vim.env.PATH = fixture .. ":" .. old_path
local old_bytes, old_output = vim.env.NVIM_AGENT_PTY_BYTES, vim.env.NVIM_AGENT_PTY_OUTPUT
local function equal(actual, expected, message)
	assert(actual == expected, message .. ": expected " .. tostring(expected) .. ", got " .. tostring(actual))
end
local function wait_for(predicate, message)
	assert(vim.wait(2000, predicate, 10), message)
end
local function read_output()
	local file = io.open(vim.env.NVIM_AGENT_PTY_OUTPUT, "rb")
	if not file then
		return nil
	end
	local content = file:read("*a")
	file:close()
	return content
end
local function adapter(kind)
	if kind == "remote" or kind == "remote_argv" then
		local c = require("utils.remote_agent").new({
			command = kind == "remote_argv" and { command } or command,
			label = "PTY",
			env = kind == "remote_argv" and { GOOSE_MODE = "smart_approve", ANTHROPIC_API_KEY = false } or nil,
		})
		return {
			object = c,
			open = c.open,
			close = c.close,
			hide = c.hide,
			show = c.show,
			job = function()
				return c._windows.job_id
			end,
		}
	end
	local c = require("config." .. kind)
	return {
		object = c,
		open = c.open_layout,
		close = c.close_layout,
		hide = c.hide_layout,
		show = c.show_layout,
		resume = c.resume_session,
		job = function()
			return c._windows[kind .. "_job_id"]
		end,
	}
end
local function submit(c)
	for _, mapping in ipairs(vim.api.nvim_buf_get_keymap(c.object._windows.prompt_buf, "n")) do
		if mapping.lhs == "<CR>" then
			mapping.callback()
			return
		end
	end
	error("prompt mapping missing")
end
local cases = {}
for _, kind in ipairs({ "remote", "remote_argv", "opencode", "grok" }) do
	for _, hidden in ipairs({ false, true }) do
		cases[#cases + 1] = {
			name = kind .. " PTY multiline and " .. (hidden and "hidden" or "visible") .. " natural exit",
			run = function()
				local payload = "日本語の依頼\n\n次の行も保持する"
				vim.env.NVIM_AGENT_PTY_BYTES = tostring(#payload)
				vim.env.NVIM_AGENT_PTY_OUTPUT = fixture .. "/" .. kind .. tostring(hidden)
				local c = adapter(kind)
				c.open()
				local windows = vim.deepcopy(c.object._windows)
				assert(c.job() and c.job() > 0, "real PTY started")
				wait_for(function()
					return table
						.concat(vim.api.nvim_buf_get_lines(windows.terminal_buf, 0, -1, false), "\n")
						:find("READY", 1, true) ~= nil
				end, "fixture entered raw input mode")
				vim.api.nvim_buf_set_lines(
					windows.prompt_buf,
					0,
					-1,
					false,
					{ "日本語の依頼", "", "次の行も保持する" }
				)
				submit(c)
				if hidden then
					c.hide()
				end
				wait_for(function()
					return not c.object._is_open and not c.job() and not vim.api.nvim_buf_is_valid(windows.terminal_buf)
				end, "natural exit cleaned layout")
				equal(read_output(), payload, "real PTY preserves Japanese multiline bytes")
				equal(vim.api.nvim_buf_is_valid(windows.prompt_buf), false, "natural exit deletes prompt")
				equal(#vim.api.nvim_list_wins(), 1, "natural exit closes windows")
			end,
		}
	end
	cases[#cases + 1] = {
		name = kind .. " PTY hide/show and close/reopen",
		run = function()
			vim.env.NVIM_AGENT_PTY_BYTES = ""
			local c = adapter(kind)
			c.open()
			local old = c.job()
			local windows = vim.deepcopy(c.object._windows)
			c.hide()
			equal(vim.fn.jobwait({ old }, 0)[1], -1, "hidden job alive")
			c.show()
			equal(c.job(), old, "show keeps real PTY")
			equal(c.object._windows.terminal_buf, windows.terminal_buf, "show keeps terminal")
			c.close()
			c.open()
			local current = c.job()
			wait_for(function()
				return vim.fn.jobwait({ old }, 0)[1] ~= -1
			end, "old PTY stops")
			vim.wait(150)
			equal(vim.fn.jobwait({ current }, 0)[1], -1, "reopened PTY survives old exit")
			equal(c.object._is_open, true, "new layout stays open")
			c.close()
			equal(vim.api.nvim_buf_is_valid(windows.terminal_buf), false, "close deletes old terminal")
			equal(vim.api.nvim_buf_is_valid(windows.prompt_buf), false, "close deletes old prompt")
		end,
	}
end
for _, kind in ipairs({ "opencode", "grok" }) do
	cases[#cases + 1] = {
		name = kind .. " PTY hidden resume terminates old process",
		run = function()
			vim.env.NVIM_AGENT_PTY_BYTES = ""
			local c = adapter(kind)
			c.open()
			local old = c.job()
			c.hide()
			c.resume()
			local current = c.job()
			wait_for(function()
				return vim.fn.jobwait({ old }, 0)[1] ~= -1
			end, "hidden old PTY stops")
			vim.wait(150)
			equal(vim.fn.jobwait({ current }, 0)[1], -1, "resumed PTY stays alive")
			equal(c.object._is_open, true, "resumed layout stays open")
			c.close()
		end,
	}
end
local failures = 0
for _, test in ipairs(cases) do
	local ok, err = pcall(test.run)
	if ok then
		print("PASS " .. test.name)
	else
		failures = failures + 1
		print("FAIL " .. test.name .. ": " .. tostring(err))
	end
	for _, name in ipairs({ "config.opencode", "config.grok" }) do
		if package.loaded[name] then
			package.loaded[name].close_layout()
		end
	end
	vim.cmd("silent! only!")
end
vim.env.PATH = old_path
vim.env.NVIM_AGENT_PTY_BYTES = old_bytes
vim.env.NVIM_AGENT_PTY_OUTPUT = old_output
vim.fn.delete(fixture, "rf")
print(string.format("%d PTY cases, %d failures", #cases, failures))
vim.cmd(failures == 0 and "qa!" or "cquit")
