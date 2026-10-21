-- Happier terminal integration.
local remote_agent = require("utils.remote_agent")

local M = {}

M.happier = remote_agent.new({
	command = "happier",
	label = "HAPPIER",
	-- happier runs claude code here: a start from fullscreen gets its fullscreen renderer
	full_env = { CLAUDE_CODE_NO_FLICKER = "1" },
})

if M.happier then
	vim.api.nvim_create_user_command("Happier", M.happier.toggle, {
		desc = "Toggle Happier terminal and prompt layout",
	})
	vim.api.nvim_create_user_command("HappierFull", M.happier.toggle_full, {
		desc = "Toggle Happier fullscreen",
	})
end

return M
