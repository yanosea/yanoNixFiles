-- Run from the repository root: nvim --headless -u NONE -l configs/nvim/tests/goose_terminal.lua
local source = debug.getinfo(1, "S").source:sub(2)
vim.opt.runtimepath:prepend(vim.fn.fnamemodify(source, ":p:h:h"))
vim.o.lines = 60
vim.o.columns = 160
local fixture = vim.fn.tempname() .. " goose test"
vim.fn.mkdir(fixture, "p")
local notifications, selected, selections = {}, "claude", 0
local original_env = vim.fn.environ()
local original_select, original_notify = vim.ui.select, vim.notify
vim.notify = function(message)
	notifications[#notifications + 1] = message
end
vim.ui.select = function(items, _, callback)
	selections = selections + 1
	callback(selected and items[selected == "claude" and 1 or 2] or nil)
end
local function executable(name, lines)
	local path = fixture .. "/" .. name
	vim.fn.writefile(lines, path)
	vim.fn.setfperm(path, "rwx------")
	return path
end
local goose = executable("goose", {
	"#!/bin/sh",
	'printf "%s\\n" "$@" > "$NVIM_GOOSE_OUTPUT.args"',
	'printf "%s\\n" "$GOOSE_MODE" "${ANTHROPIC_API_KEY-unset}" "${OPENAI_API_KEY-unset}" "${CODEX_API_KEY-unset}" "${DEFAULT_AUTH_REQUEST-unset}" "${MODEL_PROVIDER-unset}" "$CLAUDE_CODE_EXECUTABLE" "$CODEX_PATH" > "$NVIM_GOOSE_OUTPUT.env"',
	"exec cat",
})
executable("claude-agent-acp", { "#!/bin/sh", "exit 0" })
executable("codex-acp", { "#!/bin/sh", "exit 0" })
executable("claude", { "#!/bin/sh", 'printf "%s\\n" "$NVIM_GOOSE_CLAUDE_AUTH"' })
executable("codex", { "#!/bin/sh", 'printf "%s\\n" "$NVIM_GOOSE_CODEX_AUTH" >&2' })
local function equal(actual, expected, message)
	assert(vim.deep_equal(actual, expected), message .. ": " .. vim.inspect(actual))
end
local function wait_for(predicate, message)
	assert(vim.wait(3000, predicate, 10), message)
end
local function reset()
	local module = package.loaded["config.remote_agents"]
	if module and module.goose then
		for _, client in pairs(module.goose) do
			client.close()
		end
	end
	vim.cmd("silent! only!")
	package.loaded["config.remote_agents"] = nil
	for _, command in ipairs({ "Happier", "Goose", "GooseClaude", "GooseCodex" }) do
		pcall(vim.api.nvim_del_user_command, command)
	end
	vim.env.PATH = fixture .. ":" .. original_env.PATH
	vim.env.NVIM_GOOSE_OUTPUT = fixture .. "/output"
	vim.env.NVIM_GOOSE_CLAUDE_AUTH =
		'{"loggedIn":true,"authMethod":"claude.ai","apiProvider":"firstParty","subscriptionType":"max"}'
	vim.env.NVIM_GOOSE_CODEX_AUTH = "Logged in using ChatGPT"
	vim.env.ANTHROPIC_API_KEY = "test-anthropic-api-key"
	vim.env.OPENAI_API_KEY = "test-openai-api-key"
	vim.env.CODEX_API_KEY = "test-codex-api-key"
	vim.env.DEFAULT_AUTH_REQUEST = '{"methodId":"api-key"}'
	vim.env.MODEL_PROVIDER = "custom-api-provider"
	vim.env.GOOSE_MODE = "auto"
	vim.fn.delete(vim.env.NVIM_GOOSE_OUTPUT .. ".args")
	vim.fn.delete(vim.env.NVIM_GOOSE_OUTPUT .. ".env")
	notifications, selected, selections = {}, "claude", 0
	return require("config.remote_agents")
end
local cases = {}
local function case(name, callback)
	cases[#cases + 1] = { name = name, run = callback }
end
for _, provider in ipairs({ "claude", "codex" }) do
	case(provider .. " Goose receives argv and an isolated subscription environment", function()
		local module = reset()
		vim.cmd(provider == "claude" and "GooseClaude" or "GooseCodex")
		wait_for(function()
			return vim.fn.filereadable(vim.env.NVIM_GOOSE_OUTPUT .. ".env") == 1
		end, "Goose fixture started")
		equal(vim.fn.readfile(vim.env.NVIM_GOOSE_OUTPUT .. ".args"), {
			"session",
			"--provider",
			provider .. "-acp",
			"--model",
			provider == "claude" and "default" or "current",
		}, "provider argv")
		local env = vim.fn.readfile(vim.env.NVIM_GOOSE_OUTPUT .. ".env")
		equal(
			{ env[1], env[2], env[3], env[4], env[5] },
			{ "smart_approve", "unset", "unset", "unset", "unset" },
			"child API credentials removed"
		)
		equal(env[6], provider == "codex" and "openai" or "unset", "custom model provider removed")
		equal(env[provider == "claude" and 7 or 8], fixture .. "/" .. provider, "authenticated CLI pinned")
		equal(vim.env.GOOSE_MODE, "auto", "parent permission mode preserved")
		equal(vim.env.ANTHROPIC_API_KEY, "test-anthropic-api-key", "parent API credentials preserved")
		assert(module.goose[provider]._windows.job_id > 0, "provider job retained")
	end)
end
case("Goose selects once and remembers the provider while preserving its job", function()
	local module = reset()
	selected = "codex"
	vim.cmd("Goose")
	local id = module.goose.codex._windows.job_id
	vim.cmd("Goose")
	equal(module.goose.codex._is_open, false, "second toggle hides")
	vim.cmd("Goose")
	equal(selections, 1, "provider picker shown once")
	equal(module.goose.codex._windows.job_id, id, "toggle reuses provider job")
end)
case("Goose picker cancellation leaves all terminals closed", function()
	local module = reset()
	selected = nil
	vim.cmd("Goose")
	equal(next(module.goose), nil, "cancel does not start provider")
	equal(#vim.api.nvim_list_wins(), 1, "cancel creates no windows")
end)
case("Claude and Codex toggle independently and close preserves the other process", function()
	local module = reset()
	vim.cmd("GooseClaude")
	local claude = module.goose.claude
	vim.cmd("GooseCodex")
	local codex = module.goose.codex
	assert(claude._windows.job_id ~= codex._windows.job_id, "separate provider processes")
	claude.close()
	equal(vim.fn.jobwait({ codex._windows.job_id }, 0)[1], -1, "Codex survives Claude close")
	equal(codex._is_open, true, "Codex layout remains visible")
end)
for _, status in ipairs({
	'{"loggedIn":false,"authMethod":"none","apiProvider":"firstParty"}',
	'{"loggedIn":true,"authMethod":"api_key","apiKeySource":"ANTHROPIC_API_KEY","apiProvider":"firstParty"}',
	'{"loggedIn":true,"authMethod":"claude.ai","subscriptionType":"max","apiKeySource":"apiKeyHelper","apiProvider":"firstParty"}',
	'{"loggedIn":true,"authMethod":"claude.ai","apiProvider":"bedrock"}',
	"invalid JSON",
}) do
	case("Claude refuses non-subscription status " .. status, function()
		reset()
		vim.env.NVIM_GOOSE_CLAUDE_AUTH = status
		vim.cmd("GooseClaude")
		equal(#vim.api.nvim_list_wins(), 1, "refused authentication creates no windows")
		equal(vim.fn.filereadable(vim.env.NVIM_GOOSE_OUTPUT .. ".args"), 0, "Goose not spawned")
		assert(#notifications > 0, "refusal reported")
	end)
end
for _, status in ipairs({ "Logged in using an API key", "Not logged in" }) do
	case("Codex refuses " .. status, function()
		reset()
		vim.env.NVIM_GOOSE_CODEX_AUTH = status
		vim.cmd("GooseCodex")
		equal(#vim.api.nvim_list_wins(), 1, "refused authentication creates no windows")
		equal(vim.fn.filereadable(vim.env.NVIM_GOOSE_OUTPUT .. ".args"), 0, "Goose not spawned")
	end)
end
case("Codex accepts its exact ChatGPT status line alongside CLI warnings", function()
	local module = reset()
	vim.env.NVIM_GOOSE_CODEX_AUTH =
		"WARNING: PATH aliases could not be created\nLogged in using ChatGPT\nWARNING: update available"
	vim.cmd("GooseCodex")
	assert(module.goose.codex._windows.job_id, "warning does not reject subscription login")
end)
case("Codex rejects a misleading status substring", function()
	reset()
	vim.env.NVIM_GOOSE_CODEX_AUTH = "Not Logged in using ChatGPT"
	vim.cmd("GooseCodex")
	equal(#vim.api.nvim_list_wins(), 1, "substring not accepted as authenticated")
end)
case("Codex rejects contradictory API and ChatGPT status lines", function()
	reset()
	vim.env.NVIM_GOOSE_CODEX_AUTH = "Logged in using ChatGPT\nLogged in using an API key"
	vim.cmd("GooseCodex")
	equal(#vim.api.nvim_list_wins(), 1, "API status prevents launch")
end)
for _, binary in ipairs({ "goose", "claude-agent-acp", "codex-acp", "claude", "codex" }) do
	case("missing " .. binary .. " is reported and creates no terminal", function()
		reset()
		vim.fn.setfperm(fixture .. "/" .. binary, "rw-------")
		-- Keep real host CLIs out of discovery while this fixture is unavailable.
		vim.env.PATH = fixture
		vim.cmd(binary:find("codex", 1, true) and "GooseCodex" or "GooseClaude")
		equal(#vim.api.nvim_list_wins(), 1, "missing CLI creates no windows")
		assert(table.concat(notifications, "\n"):find(binary, 1, true), "missing binary named")
		vim.fn.setfperm(fixture .. "/" .. binary, "rwx------")
	end)
end
case("a closed Goose terminal rechecks subscription auth before reopening", function()
	local module = reset()
	vim.cmd("GooseClaude")
	module.goose.claude.close()
	vim.env.NVIM_GOOSE_CLAUDE_AUTH = '{"loggedIn":false}'
	vim.cmd("GooseClaude")
	equal(module.goose.claude._windows.job_id, nil, "logged out provider not restarted")
	equal(#vim.api.nvim_list_wins(), 1, "rejected reopen creates no windows")
end)
case("generic argv handles a spaced executable and shell metacharacters literally", function()
	reset()
	local c = require("utils.remote_agent").new({
		command = { goose, "a b", "$(touch SHOULD_NOT_EXIST)", "日本語" },
		label = "ARGV",
		env = { GOOSE_MODE = "smart_approve" },
	})
	assert(c, "spaced executable discovered")
	c.open()
	wait_for(function()
		return vim.fn.filereadable(vim.env.NVIM_GOOSE_OUTPUT .. ".args") == 1
	end, "argv fixture starts")
	equal(
		vim.fn.readfile(vim.env.NVIM_GOOSE_OUTPUT .. ".args"),
		{ "a b", "$(touch SHOULD_NOT_EXIST)", "日本語" },
		"literal argv retained"
	)
	c.close()
end)
local failures = 0
for _, test in ipairs(cases) do
	local ok, err = pcall(test.run)
	if ok then
		print("PASS " .. test.name)
	else
		failures = failures + 1
		print("FAIL " .. test.name .. ": " .. tostring(err))
	end
end
reset()
for key in pairs(vim.fn.environ()) do
	vim.env[key] = original_env[key]
end
for key, value in pairs(original_env) do
	vim.env[key] = value
end
vim.ui.select, vim.notify = original_select, original_notify
vim.fn.delete(fixture, "rf")
print(string.format("%d Goose cases, %d failures", #cases, failures))
vim.cmd(failures == 0 and "qa!" or "cquit")
