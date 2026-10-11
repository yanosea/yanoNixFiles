-- Happier and Goose terminal integrations.
local remote_agent = require("utils.remote_agent")

local M = {}

M.goose = {}
local selected_provider
local providers = {
	claude = { adapter = "claude-agent-acp", model = "default", command = "GooseClaude" },
	codex = { adapter = "codex-acp", model = "current", command = "GooseCodex" },
}

local function subscription_auth(provider, env)
	local argv = provider == "claude" and { env.CLAUDE_CODE_EXECUTABLE, "auth", "status", "--json" }
		or { env.CODEX_PATH, "login", "status" }
	local ok, process = pcall(vim.system, argv, { env = env, clear_env = true, text = true })
	if not ok then
		return false
	end
	local result = process:wait(5000)
	if result.code ~= 0 then
		return false
	end
	if provider == "codex" then
		local authenticated = false
		for line in ((result.stdout or "") .. "\n" .. (result.stderr or "")):gmatch("[^\r\n]+") do
			if line:match("^%s*Logged in using ChatGPT%s*$") then
				authenticated = true
			elseif line:match("^%s*Logged in using ") or line:match("^%s*Not logged in%s*$") then
				return false
			end
		end
		return authenticated
	end
	local decoded, status = pcall(vim.json.decode, result.stdout or "")
	return decoded
		and type(status) == "table"
		and status.loggedIn == true
		and status.authMethod == "claude.ai"
		and status.apiProvider == "firstParty"
		and (status.apiKeySource == nil or status.apiKeySource == vim.NIL or status.apiKeySource == "")
		and type(status.subscriptionType) == "string"
		and status.subscriptionType ~= ""
end

local function goose_environment(provider)
	-- Subscription entrypoints must not inherit API/gateway billing routes.
	-- Goose 1.49.0 serializes GooseMode with snake_case, including env values.
	local env = { GOOSE_MODE = "smart_approve" }
	for _, key in ipairs({
		"ANTHROPIC_API_KEY",
		"ANTHROPIC_AUTH_TOKEN",
		"ANTHROPIC_BASE_URL",
		"ANTHROPIC_CUSTOM_HEADERS",
		"ANTHROPIC_BEDROCK_BASE_URL",
		"ANTHROPIC_VERTEX_BASE_URL",
		"CLAUDE_CODE_USE_BEDROCK",
		"CLAUDE_CODE_USE_VERTEX",
		"CLAUDE_CODE_USE_FOUNDRY",
		"OPENAI_API_KEY",
		"OPENAI_BASE_URL",
		"CODEX_API_KEY",
		"CODEX_CONFIG",
		"DEFAULT_AUTH_REQUEST",
		"MODEL_PROVIDER",
	}) do
		env[key] = false
	end
	if provider == "claude" then
		env.CLAUDE_CODE_EXECUTABLE = vim.fn.exepath("claude")
	else
		env.CODEX_PATH = vim.fn.exepath("codex")
		env.MODEL_PROVIDER = "openai"
		env.CODEX_CONFIG = vim.json.encode({ forced_login_method = "chatgpt", model_provider = "openai" })
	end
	return env
end

local function toggle_goose(provider)
	local spec = providers[provider]
	if not M.goose[provider] then
		for _, binary in ipairs({ "goose", spec.adapter, provider }) do
			if vim.fn.executable(binary) ~= 1 then
				vim.notify("Goose requires " .. binary .. " in PATH", vim.log.levels.ERROR)
				return
			end
		end
		M.goose[provider] = remote_agent.new({
			command = { "goose", "session", "--provider", provider .. "-acp", "--model", spec.model },
			label = "GOOSE " .. provider:upper(),
			env = goose_environment(provider),
			before_open = function(env)
				if not subscription_auth(provider, env) then
					local status_command = provider == "claude" and "claude auth status --json" or "codex login status"
					vim.notify(
						"Goose "
							.. provider
							.. " subscription authentication could not be confirmed; check "
							.. status_command,
						vim.log.levels.ERROR
					)
					return false
				end
				return true
			end,
		})
	end
	selected_provider = provider
	M.goose[provider].toggle()
end

vim.api.nvim_create_user_command("Goose", function()
	if selected_provider then
		toggle_goose(selected_provider)
		return
	end
	vim.ui.select({ "claude", "codex" }, { prompt = "Goose subscription provider:" }, function(provider)
		if provider then
			toggle_goose(provider)
		end
	end)
end, { desc = "Toggle Goose with the selected subscription provider" })

for provider, spec in pairs(providers) do
	vim.api.nvim_create_user_command(spec.command, function()
		toggle_goose(provider)
	end, { desc = "Toggle Goose " .. provider .. " subscription terminal" })
end

M.happier = remote_agent.new({
	command = "happier",
	label = "HAPPIER",
})

if M.happier then
	vim.api.nvim_create_user_command("Happier", M.happier.toggle, {
		desc = "Toggle Happier terminal and prompt layout",
	})
end

return M
