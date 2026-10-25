-- Run from the repository root: nvim --headless -u NONE -l configs/nvim/tests/agent_lifecycle_pty.lua
local source = debug.getinfo(1, "S").source:sub(2)
vim.opt.runtimepath:prepend(vim.fn.fnamemodify(source, ":p:h:h"))
vim.o.lines = 60
vim.o.columns = 160
vim.notify = function() end
local fixture = vim.fn.tempname()
vim.fn.mkdir(fixture, "p")
-- the tui wrappers find the same fixture under each cli's name
for _, name in ipairs({ "opencode", "grok", "claude", "codex", "kiro-cli", "agy" }) do
	vim.fn.writefile({
		"#!/bin/sh",
		'if test -n "$NVIM_AGENT_PTY_ARGS"; then printf "%s|%s%s\\n" "$*" "${CLAUDE_CODE_NO_FLICKER:+F}" "${CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN:+S}" >"$NVIM_AGENT_PTY_ARGS"; fi',
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
	local c = require("config." .. kind)
	local job_key = ({ claude_code = "claude_job_id" })[kind] or kind .. "_job_id"
	return {
		object = c,
		open = c.open_layout,
		close = c.close_layout,
		hide = c.hide_layout,
		show = c.show_layout,
		resume = c.resume_session,
		full = c.toggle_full,
		toggle = c.toggle_layout,
		job = function()
			return c._windows[job_key]
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
local layout = require("utils.agent_layout")
-- fullscreen: the window is in the agent's own tab, with no other window there
local function in_full_tab(win)
	return layout.is_full(win) and #vim.api.nvim_tabpage_list_wins(vim.api.nvim_win_get_tabpage(win)) == 2
end
-- fullscreen on a real PTY: same job and buffers, prompt input still reaches it
for _, kind in ipairs({ "claude_code", "codex", "kiro", "antigravity", "opencode", "grok" }) do
	cases[#cases + 1] = {
		name = kind .. " PTY fullscreen prompt reaches the job",
		run = function()
			local payload = "日本語の依頼\n\n次の行も保持する"
			vim.env.NVIM_AGENT_PTY_BYTES = tostring(#payload)
			vim.env.NVIM_AGENT_PTY_OUTPUT = fixture .. "/" .. kind .. "-full"
			local c = adapter(kind)
			c.open()
			local windows = vim.deepcopy(c.object._windows)
			wait_for(function()
				return table
					.concat(vim.api.nvim_buf_get_lines(windows.terminal_buf, 0, -1, false), "\n")
					:find("READY", 1, true) ~= nil
			end, "fixture entered raw input mode")
			c.full()
			equal(in_full_tab(c.object._windows.terminal_win), true, "terminal is fullscreen")
			equal(vim.api.nvim_win_get_buf(c.object._windows.prompt_win), windows.prompt_buf, "prompt buffer kept")
			vim.api.nvim_buf_set_lines(
				windows.prompt_buf,
				0,
				-1,
				false,
				{ "日本語の依頼", "", "次の行も保持する" }
			)
			submit(c)
			wait_for(function()
				return read_output() == payload
			end, "fullscreen prompt reaches the real PTY")
			c.close()
			equal(#vim.api.nvim_list_wins(), 1, "close removes the floats")
		end,
	}
	cases[#cases + 1] = {
		name = kind .. " PTY fullscreen round trip keeps the job",
		run = function()
			vim.env.NVIM_AGENT_PTY_BYTES = ""
			local c = adapter(kind)
			c.open()
			local old = c.job()
			c.full()
			equal(vim.fn.jobwait({ old }, 0)[1], -1, "job alive in fullscreen")
			c.full()
			equal(in_full_tab(c.object._windows.terminal_win), false, "back to the split")
			equal(c.job(), old, "same real PTY")
			equal(vim.fn.jobwait({ old }, 0)[1], -1, "job alive after the round trip")
			c.close()
			wait_for(function()
				return vim.fn.jobwait({ old }, 0)[1] ~= -1
			end, "close stops the PTY")
		end,
	}
	cases[#cases + 1] = {
		name = kind .. " PTY split and full starts pass each renderer",
		run = function()
			-- "<args>|<renderer env>" as the real PTY child sees them
			local expected = ({
				claude_code = { "|S", "|F" },
				codex = { "--no-alt-screen|", "|" },
				kiro = { "|", "|" },
				antigravity = { "|", "|" },
				opencode = { "mini|", "|" },
				grok = { "--no-alt-screen|", "|" },
			})[kind]
			-- only the wrapper may set these, not the shell running the tests
			vim.env.CLAUDE_CODE_NO_FLICKER = nil
			vim.env.CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN = nil
			for index, start in ipairs({ "toggle", "full" }) do
				vim.env.NVIM_AGENT_PTY_BYTES = ""
				vim.env.NVIM_AGENT_PTY_ARGS = fixture .. "/" .. kind .. "-args-" .. start
				local c = adapter(kind)
				c[start]()
				wait_for(function()
					local file = io.open(vim.env.NVIM_AGENT_PTY_ARGS, "r")
					local line = file and file:read("*l")
					if file then
						file:close()
					end
					return line ~= nil
				end, start .. " start reached the fixture")
				local file = assert(io.open(vim.env.NVIM_AGENT_PTY_ARGS, "r"))
				local seen = vim.trim(file:read("*a"))
				file:close()
				equal(seen, expected[index], start .. " start renderer")
				c.close()
				vim.env.NVIM_AGENT_PTY_ARGS = nil
			end
		end,
	}
	cases[#cases + 1] = {
		name = kind .. " PTY fullscreen from closed and from hidden",
		run = function()
			vim.env.NVIM_AGENT_PTY_BYTES = ""
			local c = adapter(kind)
			c.full()
			local job = c.job()
			assert(job and job > 0, "full from closed starts a real PTY")
			equal(in_full_tab(c.object._windows.terminal_win), true, "started fullscreen")
			equal(vim.fn.jobwait({ job }, 0)[1], -1, "job alive")
			c.hide()
			c.full()
			equal(in_full_tab(c.object._windows.terminal_win), true, "hidden comes back fullscreen")
			equal(c.job(), job, "same real PTY")
			equal(vim.fn.jobwait({ job }, 0)[1], -1, "job alive after show")
			c.close()
			wait_for(function()
				return vim.fn.jobwait({ job }, 0)[1] ~= -1
			end, "close stops the PTY")
		end,
	}
end
for _, kind in ipairs({ "antigravity", "kiro", "opencode", "grok" }) do
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
for _, kind in ipairs({ "antigravity", "kiro", "opencode", "grok" }) do
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
	vim.cmd("silent! tabnew")
	vim.cmd("silent! tabonly!")
	vim.cmd("silent! only!")
end
vim.env.PATH = old_path
vim.env.NVIM_AGENT_PTY_BYTES = old_bytes
vim.env.NVIM_AGENT_PTY_OUTPUT = old_output
vim.fn.delete(fixture, "rf")
print(string.format("%d PTY cases, %d failures", #cases, failures))
vim.cmd(failures == 0 and "qa!" or "cquit")
